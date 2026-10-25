import Foundation

@MainActor
struct ExportUseCase {
    let repository: any MediaRepository

    func snapshot(now: Date = .now, appVersion: String) throws -> KulturstackExport {
        KulturstackExport(
            formatVersion: KulturstackExport.currentFormatVersion,
            exportedAt: now,
            app: appVersion,
            items: try repository.allItems()
                .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
                .map(Self.item(from:))
        )
    }

    func json(now: Date = .now, appVersion: String) throws -> Data {
        try JSONEncoder.kulturstackExport.encode(try snapshot(now: now, appVersion: appVersion))
    }

    static func fileName(now: Date = .now) -> String {
        let jour = Date.FormatStyle(date: .numeric, time: .omitted)
            .year(.defaultDigits).month(.twoDigits).day(.twoDigits)
            .locale(Locale(identifier: "en_US_POSIX"))
        // « 2027-01-15 » et pas « 15/01/2027 » : un nom de fichier qui se trie tout seul.
        let parts = now.formatted(jour).split(separator: "/")
        let iso = parts.count == 3 ? "\(parts[2])-\(parts[0])-\(parts[1])" : "export"
        return "kulturstack-\(iso).json"
    }

    private static func item(from item: MediaItem) -> KulturstackExport.Item {
        KulturstackExport.Item(
            id: item.id,
            kind: item.kind.rawValue,
            title: item.title,
            originalTitle: item.originalTitle,
            year: item.year,
            creators: item.creators,
            summary: item.summary,
            coverURL: item.coverURL,
            detailsJSON: item.detailsData.flatMap { String(data: $0, encoding: .utf8) },
            externalKeys: item.externalRefs.map(\.key).sorted(),
            logs: item.logs
                .sorted { ($0.date, $0.createdAt) < ($1.date, $1.createdAt) }
                .map { log in
                    KulturstackExport.Log(id: log.id, date: log.date, status: log.statusRaw,
                                          rating: log.rating, note: log.note, source: log.source,
                                          episodeKey: log.episode?.key)
                },
            seasons: item.orderedSeasons.map { season in
                KulturstackExport.Season(key: season.key, number: season.number, title: season.title,
                                         episodes: season.orderedEpisodes.map { episode in
                                             KulturstackExport.Episode(key: episode.key, number: episode.number,
                                                                       title: episode.title, airDate: episode.airDate,
                                                                       runtimeMinutes: episode.runtimeMinutes,
                                                                       externalID: episode.externalID)
                                         })
            },
            ownedCopies: item.ownedCopies
                .sorted { $0.createdAt < $1.createdAt }
                .map { copy in
                    KulturstackExport.OwnedCopy(id: copy.id, format: copy.format, editionRef: copy.editionRef,
                                                acquiredAt: copy.acquiredAt, notes: copy.notes,
                                                createdAt: copy.createdAt)
                }
        )
    }
}
