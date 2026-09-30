import Foundation
import SwiftData
import Testing
@testable import Kulturstack

// Le ✓ de « En cours » et celui du Journal passent par ici : une seule façon d'avancer.
@MainActor
struct AdvanceUseCaseTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func make(providers: [any EpisodeProvider] = []) -> (AdvanceUseCase, any MediaRepository) {
        let context = container.mainContext
        let media = SwiftDataMediaRepository(context: context)
        let log = LogUseCase(repository: media, dedup: DedupUseCase(repository: media))
        let edit = EditLogUseCase(repository: SwiftDataLogRepository(context: context))
        let episodes = EpisodeUseCase(repository: SwiftDataEpisodeRepository(context: context),
                                      providers: providers, log: log, edit: edit)
        return (AdvanceUseCase(media: media, episodes: episodes,
                               status: WatchStatusUseCase(log: log, edit: edit)), media)
    }

    private func series(episodes count: Int, watched: [Int]) throws -> MediaItem {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        for number in 1...count { context.insert(Episode(number: number, season: season)) }
        try context.save()
        for episode in season.orderedEpisodes where watched.contains(episode.number) {
            context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        try context.save()
        return item
    }

    @Test func advancingChecksTheNextEpisodeAndStartsTheSeries() async throws {
        let (advance, _) = make()
        let item = try series(episodes: 3, watched: [])

        #expect(try await advance.advance(itemID: item.id))

        #expect(InProgressUseCase.lastWatched(of: item)?.number == 1)
        #expect(WatchStatusUseCase.status(of: item) == .inProgress)
    }

    @Test func advancingTwiceChecksTwoEpisodesInARow() async throws {
        let (advance, _) = make()
        let item = try series(episodes: 3, watched: [])

        try await advance.advance(itemID: item.id)
        try await advance.advance(itemID: item.id)

        #expect(try container.mainContext.fetch(FetchDescriptor<LogEntry>())
            .filter { $0.episode != nil }.count == 2)
        #expect(InProgressUseCase.next(for: item)?.number == 3)
    }

    // Une série vue jusqu'au bout n'a pas de suite : ce n'est pas une erreur, rien ne s'écrit.
    @Test func advancingAtTheEndChangesNothing() async throws {
        let (advance, _) = make()
        let item = try series(episodes: 2, watched: [1, 2])
        let before = try container.mainContext.fetch(FetchDescriptor<LogEntry>()).count

        #expect(try await advance.advance(itemID: item.id) == false)
        #expect(try container.mainContext.fetch(FetchDescriptor<LogEntry>()).count == before)
    }

    @Test func advancingAnUnknownWorkChangesNothing() async throws {
        let (advance, _) = make()

        #expect(try await advance.advance(itemID: UUID()) == false)
    }

    // Le ✓ sur une série dont la saison suivante n'a jamais été ouverte : c'est le seul moment
    // où avancer va chercher quelque chose à la source, et il ne le fait qu'à ce moment-là.
    @Test func advancingIntoASeasonNeverOpenedLoadsItAndChecksItsFirstEpisode() async throws {
        let provider = StubEpisodeProvider(
            seasons: .success([StubEpisodeProvider.season(1, episodes: 2),
                               StubEpisodeProvider.season(2, episodes: 4)]),
            episodes: [2: .success([StubEpisodeProvider.episode(1, title: "Hello, Ms. Cobel"),
                                    StubEpisodeProvider.episode(2)])])
        let (advance, _) = make(providers: [provider])
        let item = try series(episodes: 2, watched: [1, 2])
        try item.setDetails(SeriesDetails(seasonCount: 2))
        item.externalRefs.append(ExternalRef(provider: "tmdb", value: "tv:95396", item: item))
        try container.mainContext.save()

        #expect(try await advance.advance(itemID: item.id))

        let watched = try #require(InProgressUseCase.lastWatched(of: item))
        #expect(watched.season?.number == 2)
        #expect(watched.number == 1)
        #expect(provider.episodeCalls.map(\.season) == [2])
    }

    // La saison suivante n'existe pas chez la source : rien ne s'écrit, et ça ne lève pas.
    @Test func advancingIntoASeasonTheSourceDoesNotHaveChangesNothing() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 2)]))
        let (advance, _) = make(providers: [provider])
        let item = try series(episodes: 2, watched: [1, 2])
        try item.setDetails(SeriesDetails(seasonCount: 2))
        item.externalRefs.append(ExternalRef(provider: "tmdb", value: "tv:95396", item: item))
        try container.mainContext.save()
        let before = try container.mainContext.fetch(FetchDescriptor<LogEntry>()).count

        #expect(try await advance.advance(itemID: item.id) == false)
        #expect(try container.mainContext.fetch(FetchDescriptor<LogEntry>()).count == before)
    }
}
