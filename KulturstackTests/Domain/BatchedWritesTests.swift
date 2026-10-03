import Foundation
import SwiftData
import Testing
@testable import Kulturstack

// « Ça lag quand je veux enregistrer les podcasts tout d'un coup » et « ça a mis beaucoup de
// temps pour tout décocher » (founder, 03/10). La cause n'était pas la quantité de données
// mais le nombre d'**écritures** : une par épisode. Ces tests comptent les écritures.
@MainActor
struct BatchedWritesTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func make(episodes count: Int) throws -> (MediaItem, Season, EpisodeUseCase, CountingWrites) {
        let context = container.mainContext
        let counter = CountingWrites()
        let media = CountingMediaRepository(wrapped: SwiftDataMediaRepository(context: context), counter: counter)
        let logs = CountingLogRepository(wrapped: SwiftDataLogRepository(context: context), counter: counter)
        let item = MediaItem(kind: .podcast, title: "Le code a changé")
        try media.add(item, refs: [ExternalRef(provider: "feed", value: "https://exemple.fr/flux.xml")])
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        for number in 1...count {
            context.insert(Episode(number: number, externalID: "guid-\(number)", season: season))
        }
        try context.save()
        counter.reset()
        let useCase = EpisodeUseCase(repository: SwiftDataEpisodeRepository(context: context),
                                     providers: [],
                                     log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
                                     edit: EditLogUseCase(repository: logs))
        return (item, season, useCase, counter)
    }

    @Test func checkingAWholeSeasonIsASingleWrite() throws {
        let (item, season, useCase, counter) = try make(episodes: 30)

        try useCase.checkAll(season, of: item)

        #expect(season.orderedEpisodes.allSatisfy { $0.isWatched })
        #expect(counter.writes == 1)
    }

    @Test func uncheckingAWholeSeasonIsASingleWrite() throws {
        let (item, season, useCase, counter) = try make(episodes: 30)
        try useCase.checkAll(season, of: item)
        counter.reset()

        try useCase.uncheckAll(season, of: item)

        #expect(season.orderedEpisodes.allSatisfy { !$0.isWatched })
        #expect(counter.writes == 1)
    }

    @Test func checkingAYearIsASingleWrite() throws {
        let (item, season, useCase, counter) = try make(episodes: 30)

        try useCase.check(Array(season.orderedEpisodes.prefix(12)), of: item)

        #expect(counter.writes == 1)
    }

    // Rien à écrire n'écrit rien : recocher une saison déjà complète ne touche pas la base.
    @Test func checkingWhatIsAlreadyCheckedWritesNothing() throws {
        let (item, season, useCase, counter) = try make(episodes: 10)
        try useCase.checkAll(season, of: item)
        counter.reset()

        try useCase.checkAll(season, of: item)

        #expect(counter.writes == 0)
    }
}

@MainActor
private final class CountingWrites {
    private(set) var writes = 0
    func count() { writes += 1 }
    func reset() { writes = 0 }
}

// Les dépôts réels, avec un compteur sur chaque écriture : ce qu'on mesure, c'est le nombre
// d'allers-retours en base, pas le nombre de lignes.
@MainActor
private struct CountingMediaRepository: MediaRepository {
    let wrapped: SwiftDataMediaRepository
    let counter: CountingWrites

    func findItem(withAnyKey keys: [String]) throws -> MediaItem? { try wrapped.findItem(withAnyKey: keys) }
    func find(itemID: UUID) throws -> MediaItem? { try wrapped.find(itemID: itemID) }
    func add(_ item: MediaItem, refs: [ExternalRef]) throws { try wrapped.add(item, refs: refs) }
    func add(_ refs: [ExternalRef], to item: MediaItem) throws { try wrapped.add(refs, to: item) }
    func add(_ log: LogEntry) throws {
        counter.count()
        try wrapped.add(log)
    }

    func add(_ logs: [LogEntry]) throws {
        guard !logs.isEmpty else { return }
        counter.count()
        try wrapped.add(logs)
    }

    func save() throws { try wrapped.save() }
    func deleteAll() throws { try wrapped.deleteAll() }
}

@MainActor
private struct CountingLogRepository: LogRepository {
    let wrapped: SwiftDataLogRepository
    let counter: CountingWrites

    func fetchAll() async throws -> [LogEntry] { try await wrapped.fetchAll() }
    func find(id: UUID) throws -> LogEntry? { try wrapped.find(id: id) }
    func save() throws { try wrapped.save() }
    func delete(_ log: LogEntry) throws {
        counter.count()
        try wrapped.delete(log)
    }

    func delete(_ logs: [LogEntry]) throws {
        guard !logs.isEmpty else { return }
        counter.count()
        try wrapped.delete(logs)
    }
}
