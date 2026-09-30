import Foundation
import SwiftData
import Testing
@testable import Kulturstack

// Le ✓ de « En cours » et celui du Journal passent par ici : une seule façon d'avancer.
@MainActor
struct AdvanceUseCaseTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func make() -> (AdvanceUseCase, any MediaRepository) {
        let context = container.mainContext
        let media = SwiftDataMediaRepository(context: context)
        let log = LogUseCase(repository: media, dedup: DedupUseCase(repository: media))
        let edit = EditLogUseCase(repository: SwiftDataLogRepository(context: context))
        let episodes = EpisodeUseCase(repository: SwiftDataEpisodeRepository(context: context),
                                      providers: [], log: log, edit: edit)
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

    @Test func advancingChecksTheNextEpisodeAndStartsTheSeries() throws {
        let (advance, _) = make()
        let item = try series(episodes: 3, watched: [])

        #expect(try advance.advance(itemID: item.id))

        #expect(InProgressUseCase.lastWatched(of: item)?.number == 1)
        #expect(WatchStatusUseCase.status(of: item) == .inProgress)
    }

    @Test func advancingTwiceChecksTwoEpisodesInARow() throws {
        let (advance, _) = make()
        let item = try series(episodes: 3, watched: [])

        try advance.advance(itemID: item.id)
        try advance.advance(itemID: item.id)

        #expect(try container.mainContext.fetch(FetchDescriptor<LogEntry>())
            .filter { $0.episode != nil }.count == 2)
        #expect(InProgressUseCase.next(for: item)?.number == 3)
    }

    // Une série vue jusqu'au bout n'a pas de suite : ce n'est pas une erreur, rien ne s'écrit.
    @Test func advancingAtTheEndChangesNothing() throws {
        let (advance, _) = make()
        let item = try series(episodes: 2, watched: [1, 2])
        let before = try container.mainContext.fetch(FetchDescriptor<LogEntry>()).count

        #expect(try advance.advance(itemID: item.id) == false)
        #expect(try container.mainContext.fetch(FetchDescriptor<LogEntry>()).count == before)
    }

    @Test func advancingAnUnknownWorkChangesNothing() throws {
        let (advance, _) = make()

        #expect(try advance.advance(itemID: UUID()) == false)
    }
}
