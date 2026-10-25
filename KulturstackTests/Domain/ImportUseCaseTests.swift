import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct ImportUseCaseTests {
    private struct Atelier {
        let container: ModelContainer
        let media: SwiftDataMediaRepository
        let episodes: SwiftDataEpisodeRepository
        let export: ExportUseCase
        let importer: ImportUseCase
    }

    private func atelier() throws -> Atelier {
        let container = try ModelContainerFactory.inMemory()
        let media = SwiftDataMediaRepository(context: container.mainContext)
        let episodes = SwiftDataEpisodeRepository(context: container.mainContext)
        return Atelier(container: container, media: media, episodes: episodes,
                       export: ExportUseCase(repository: media),
                       importer: ImportUseCase(media: media, episodes: episodes))
    }

    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    // LE test de cette PR : une base perdue se reconstruit à l'identique depuis son fichier.
    // C'est ce que le 18/10 n'a pas pu faire — dix jours de logs partis avec l'app.
    @Test func aWipedBaseComesBackIdenticalFromItsFile() throws {
        let a = try atelier()
        try DemoSeed(context: a.container.mainContext).fill()
        let avant = try inventaire(a)
        let fichier = try a.export.json(now: date, appVersion: "1.0")

        try WipeUseCase(repository: a.media).wipe()
        #expect(try a.media.allItems().isEmpty)
        let bilan = try a.importer.restore(from: fichier)

        let après = try inventaire(a)
        #expect(après == avant)
        #expect(bilan.itemsAdded == avant.œuvres)
        #expect(bilan.itemsMerged == 0)
        withExtendedLifetime(a.container) {}
    }

    // Deux fois le même fichier n'ajoute rien : sinon restaurer deux fois doublerait tout.
    @Test func restoringTwiceAddsNothingTheSecondTime() throws {
        let a = try atelier()
        try DemoSeed(context: a.container.mainContext).fill()
        let fichier = try a.export.json(now: date, appVersion: "1.0")
        try WipeUseCase(repository: a.media).wipe()

        _ = try a.importer.restore(from: fichier)
        let après1 = try inventaire(a)
        let bilan2 = try a.importer.restore(from: fichier)
        let après2 = try inventaire(a)

        #expect(après1 == après2)
        #expect(bilan2.itemsAdded == 0)
        #expect(bilan2.logsAdded == 0)
        #expect(bilan2.episodesAdded == 0)
        withExtendedLifetime(a.container) {}
    }

    // Restaurer **fusionne**, n'écrase jamais : une œuvre déjà là est reconnue par sa clé
    // externe, et ce qui manque lui est ajouté. C'est ce qui permet de restaurer par-dessus
    // une base qui a déjà repris du service.
    @Test func anExistingWorkIsMergedNotDuplicated() throws {
        let a = try atelier()
        let dune = MediaItem(kind: .film, title: "Dune", year: 2021)
        try a.media.add(dune, refs: [ExternalRef(provider: "tmdb", value: "movie:438631")])
        try a.media.add(try LogEntry.make(item: dune, status: .done, date: date, rating: 9))
        let fichier = try a.export.json(now: date, appVersion: "1.0")

        // La base repart de zéro mais l'œuvre y est déjà remise à la main, sans son log.
        try WipeUseCase(repository: a.media).wipe()
        let remise = MediaItem(kind: .film, title: "Dune", year: 2021)
        try a.media.add(remise, refs: [ExternalRef(provider: "tmdb", value: "movie:438631")])

        let bilan = try a.importer.restore(from: fichier)

        #expect(try a.media.allItems().count == 1)
        #expect(bilan.itemsAdded == 0)
        #expect(bilan.itemsMerged == 1)
        #expect(bilan.logsAdded == 1)
        #expect(remise.logs.count == 1)
        #expect(remise.logs.first?.rating == 9)
        withExtendedLifetime(a.container) {}
    }

    // Les coches retombent sur les bons épisodes : c'est la clé qui fait foi, pas la position.
    @Test func checkedEpisodesLandBackOnTheRightEpisode() throws {
        let a = try atelier()
        let podcast = MediaItem(kind: .podcast, title: "Transfert")
        try a.media.add(podcast, refs: [ExternalRef(provider: "itunes", value: "1")])
        let saison = try Season.make(number: 1, item: podcast)
        try a.episodes.add(saison)
        let écouté = Episode(number: 2, title: "Deux", externalID: "guid-2", season: saison)
        try a.episodes.add([Episode(number: 1, title: "Un", externalID: "guid-1", season: saison), écouté])
        try a.media.add(try LogEntry.make(item: podcast, status: .done, date: date, episode: écouté))
        let fichier = try a.export.json(now: date, appVersion: "1.0")
        let cléÉcoutée = écouté.key

        try WipeUseCase(repository: a.media).wipe()
        _ = try a.importer.restore(from: fichier)

        let revenu = try #require(try a.media.allItems().first)
        let épisodes = revenu.orderedSeasons.flatMap(\.orderedEpisodes)
        #expect(épisodes.map(\.externalID) == ["guid-1", "guid-2"])
        let cochés = épisodes.filter(\.isWatched)
        #expect(cochés.map(\.key) == [cléÉcoutée])
        withExtendedLifetime(a.container) {}
    }

    @Test func whatIsOwnedComesBackOwned() throws {
        let a = try atelier()
        let disque = MediaItem(kind: .album, title: "Discovery")
        try a.media.add(disque, refs: [ExternalRef(provider: "itunes", value: "album:1")])
        try a.media.add(try OwnedCopy.make(item: disque, format: "vinyl"))
        let fichier = try a.export.json(now: date, appVersion: "1.0")

        try WipeUseCase(repository: a.media).wipe()
        let bilan = try a.importer.restore(from: fichier)

        let revenu = try #require(try a.media.allItems().first)
        #expect(revenu.isOwned)
        #expect(revenu.ownedCopies.first?.format == "vinyl")
        #expect(bilan.ownedCopiesAdded == 1)
        withExtendedLifetime(a.container) {}
    }

    @Test func detailsComeBackSoTheSheetIsNotEmpty() throws {
        let a = try atelier()
        let disque = MediaItem(kind: .album, title: "Random Access Memories")
        try disque.setDetails(AlbumDetails(trackCount: 14, genre: "Pop"))
        try a.media.add(disque, refs: [])
        let fichier = try a.export.json(now: date, appVersion: "1.0")

        try WipeUseCase(repository: a.media).wipe()
        _ = try a.importer.restore(from: fichier)

        let revenu = try #require(try a.media.allItems().first)
        let details = try #require(revenu.details as? AlbumDetails)
        #expect(details.trackCount == 14)
        #expect(details.genre == "Pop")
        withExtendedLifetime(a.container) {}
    }

    // Un fichier d'une version future se refuse **par son nom**, au lieu d'écrire n'importe
    // quoi dans la base de la founder.
    @Test func aFileFromAFutureVersionIsRefused() throws {
        let a = try atelier()
        let futur = Data(#"{"formatVersion":99,"exportedAt":"2027-01-15T08:00:00Z","app":"9","items":[]}"#.utf8)

        #expect(throws: ImportError.unsupportedFormat(99)) { try a.importer.restore(from: futur) }
        withExtendedLifetime(a.container) {}
    }

    @Test func anUnreadableFileIsRefused() throws {
        let a = try atelier()

        #expect(throws: ImportError.unreadable) { try a.importer.restore(from: Data("pas du json".utf8)) }
        withExtendedLifetime(a.container) {}
    }

    private struct Inventaire: Equatable {
        let œuvres: Int
        let logs: Int
        let épisodes: Int
        let cochés: Int
        let saisons: Int
        let clés: Int
        let possédés: Int
        let titresNotés: [String]
    }

    private func inventaire(_ a: Atelier) throws -> Inventaire {
        let context = a.container.mainContext
        let logs = try context.fetch(FetchDescriptor<LogEntry>())
        return Inventaire(
            œuvres: try context.fetchCount(FetchDescriptor<MediaItem>()),
            logs: logs.count,
            épisodes: try context.fetchCount(FetchDescriptor<Episode>()),
            cochés: logs.filter { $0.episode != nil }.count,
            saisons: try context.fetchCount(FetchDescriptor<Season>()),
            clés: try context.fetchCount(FetchDescriptor<ExternalRef>()),
            possédés: try context.fetchCount(FetchDescriptor<OwnedCopy>()),
            // Pas seulement des totaux : sept œuvres avant et sept après peut cacher un
            // échange (leçon de la migration du 24/09).
            titresNotés: logs.compactMap { log in log.rating.map { "\(log.item?.title ?? "?")|\($0)" } }.sorted()
        )
    }
}
