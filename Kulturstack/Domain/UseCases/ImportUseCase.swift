import Foundation

enum ImportError: Error, Equatable {
    case unreadable
    case unsupportedFormat(Int)
}

// Relit un fichier produit par `ExportUseCase` et remet son contenu en base.
//
// **Il fusionne, il n'écrase jamais.** Une œuvre déjà présente est reconnue par sa clé
// externe et complétée ; rien n'est supprimé. C'est ce qui permet de restaurer par-dessus
// une base qui a déjà repris du service, sans avoir à choisir entre les deux.
@MainActor
struct ImportUseCase {
    let media: any MediaRepository
    let episodes: any EpisodeRepository

    struct Result: Equatable {
        var itemsAdded = 0
        var itemsMerged = 0
        var logsAdded = 0
        var episodesAdded = 0
        var seasonsAdded = 0
        var ownedCopiesAdded = 0
    }

    @discardableResult
    func restore(from data: Data) throws -> Result {
        let export: KulturstackExport
        do {
            export = try JSONDecoder.kulturstackExport.decode(KulturstackExport.self, from: data)
        } catch {
            throw ImportError.unreadable
        }
        guard export.formatVersion <= KulturstackExport.currentFormatVersion else {
            throw ImportError.unsupportedFormat(export.formatVersion)
        }

        var result = Result()
        for exported in export.items {
            let item = try existing(exported) ?? create(exported, into: &result)
            try merge(exported, into: item, result: &result)
        }
        try media.save()
        return result
    }

    // Par la clé externe d'abord — c'est elle qui dit « c'est la même œuvre », même si le
    // titre a changé de source entre-temps. L'identifiant interne sert de repli.
    private func existing(_ exported: KulturstackExport.Item) throws -> MediaItem? {
        if let found = try media.findItem(withAnyKey: exported.externalKeys) { return found }
        return try media.find(itemID: exported.id)
    }

    private func create(_ exported: KulturstackExport.Item, into result: inout Result) -> MediaItem {
        let item = MediaItem(kind: MediaKind(rawValue: exported.kind) ?? .film, title: exported.title,
                             originalTitle: exported.originalTitle, year: exported.year,
                             creators: exported.creators, summary: exported.summary,
                             coverURL: exported.coverURL)
        // L'identifiant d'origine, et pas un neuf : les clés des saisons et des épisodes s'en
        // déduisent. Avec un id neuf, les coches ne retombent sur aucun épisode et le même
        // fichier réimporté crée tout en double.
        item.id = exported.id
        result.itemsAdded += 1
        return item
    }

    private func merge(_ exported: KulturstackExport.Item, into item: MediaItem, result: inout Result) throws {
        let neuf = item.modelContext == nil
        if !neuf { result.itemsMerged += 1 }
        // La poche de détails revient telle qu'elle est partie : la relire ne demande pas de
        // savoir de quel type elle est.
        if item.detailsData == nil, let json = exported.detailsJSON {
            item.detailsData = Data(json.utf8)
        }
        let refs = exported.externalKeys.compactMap(Self.ref(from:))
        if neuf {
            try media.add(item, refs: refs)
        } else {
            let connues = Set(item.externalRefs.map(\.key))
            let manquantes = refs.filter { !connues.contains($0.key) }
            if !manquantes.isEmpty { try media.add(manquantes, to: item) }
        }

        let épisodesParClé = try restore(exported.seasons, of: item, result: &result)
        try restore(exported.logs, of: item, episodes: épisodesParClé, result: &result)
        try restore(exported.ownedCopies, of: item, result: &result)
    }

    private func restore(_ seasons: [KulturstackExport.Season], of item: MediaItem,
                         result: inout Result) throws -> [String: Episode] {
        var parClé: [String: Episode] = [:]
        for season in item.seasons {
            for episode in season.episodes { parClé[episode.key] = episode }
        }
        for exported in seasons {
            let saison: Season
            if let connue = item.seasons.first(where: { $0.key == exported.key }) {
                saison = connue
            } else {
                saison = try Season.make(number: exported.number, title: exported.title, item: item)
                try episodes.add(saison)
                result.seasonsAdded += 1
            }
            let neufs = exported.episodes.filter { parClé[$0.key] == nil }
            guard !neufs.isEmpty else { continue }
            let créés = neufs.map { exported in
                Episode(number: exported.number, title: exported.title, airDate: exported.airDate,
                        runtimeMinutes: exported.runtimeMinutes, externalID: exported.externalID,
                        season: saison)
            }
            try episodes.add(créés)
            result.episodesAdded += créés.count
            // Rangés sous leur clé d'origine **et** sous celle qu'ils viennent de se donner :
            // si jamais les deux divergeaient, un log d'épisode retomberait quand même juste.
            for (exportéÉpisode, épisode) in zip(neufs, créés) {
                parClé[exportéÉpisode.key] = épisode
                parClé[épisode.key] = épisode
            }
        }
        return parClé
    }

    private func restore(_ logs: [KulturstackExport.Log], of item: MediaItem,
                         episodes épisodesParClé: [String: Episode], result: inout Result) throws {
        let connus = Set(item.logs.map(\.id))
        var neufs: [LogEntry] = []
        for exported in logs where !connus.contains(exported.id) {
            guard let status = LogStatus(rawValue: exported.status) else { continue }
            let épisode = exported.episodeKey.flatMap { épisodesParClé[$0] }
            // Un log d'épisode dont l'épisode n'est pas revenu serait orphelin : on le laisse
            // tomber plutôt que de l'accrocher au hasard.
            if exported.episodeKey != nil, épisode == nil { continue }
            let log = try LogEntry.make(item: item, status: status, date: exported.date,
                                        rating: exported.rating, note: exported.note,
                                        source: exported.source, episode: épisode)
            // Son identifiant d'origine : c'est lui qui dit « ce log est déjà revenu ».
            log.id = exported.id
            neufs.append(log)
        }
        guard !neufs.isEmpty else { return }
        try media.add(neufs)
        result.logsAdded += neufs.count
    }

    private func restore(_ copies: [KulturstackExport.OwnedCopy], of item: MediaItem,
                         result: inout Result) throws {
        let connus = Set(item.ownedCopies.map(\.id))
        for exported in copies where !connus.contains(exported.id) {
            guard item.kind.canBeOwned else { continue }
            let copy = try OwnedCopy.make(item: item, format: exported.format,
                                          editionRef: exported.editionRef,
                                          acquiredAt: exported.acquiredAt, notes: exported.notes)
            copy.id = exported.id
            try media.add(copy)
            result.ownedCopiesAdded += 1
        }
    }

    private static func ref(from key: String) -> ExternalRef? {
        guard let separator = key.firstIndex(of: ":") else { return nil }
        let provider = String(key[..<separator])
        let value = String(key[key.index(after: separator)...])
        guard !provider.isEmpty, !value.isEmpty else { return nil }
        return ExternalRef(provider: provider, value: value)
    }
}
