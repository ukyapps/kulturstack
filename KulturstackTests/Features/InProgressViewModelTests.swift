import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct InProgressViewModelTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private var context: ModelContext { container.mainContext }

    private func make() -> (AppServices, InProgressViewModel) {
        let services = AppServices(context: context)
        return (services, InProgressViewModel(useCase: services.inProgressUseCase,
                                              repository: services.mediaRepository,
                                              episodes: services.episodeUseCase,
                                              status: services.watchStatusUseCase))
    }

    @discardableResult
    private func series(_ title: String, episodes: Int, watched: [Int]) throws -> MediaItem {
        let item = MediaItem(kind: .series, title: title)
        context.insert(item)
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        for number in 1...episodes { context.insert(Episode(number: number, season: season)) }
        try context.save()
        for episode in season.orderedEpisodes where watched.contains(episode.number) {
            context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        context.insert(try LogEntry.make(item: item, status: .inProgress,
                                         source: WatchStatusUseCase.automaticSource))
        try context.save()
        return item
    }

    private func rows(_ viewModel: InProgressViewModel) throws -> [InProgressRowModel] {
        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("état attendu : loaded, reçu \(viewModel.state)")
            return []
        }
        return rows
    }

    @Test func nothingInProgressGivesTheEmptyState() async throws {
        let (_, viewModel) = make()

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test func aSeriesInProgressShowsWhereItStandsAndWhatIsNext() async throws {
        try series("Severance", episodes: 10, watched: [1, 2, 3, 4])
        let (_, viewModel) = make()

        await viewModel.load()

        let row = try #require(try rows(viewModel).first)
        #expect(row.title == "Severance")
        #expect(row.detail == String(localized: "inprogress.progress \(1) \(4) \(10)"))
        #expect(row.next?.number == 5)
        #expect(row.next?.label == String(localized: "inprogress.next \(5)"))
    }

    @Test func advancingChecksTheNextEpisodeAndMovesOn() async throws {
        try series("Severance", episodes: 10, watched: [1, 2, 3, 4])
        let (_, viewModel) = make()
        await viewModel.load()

        await viewModel.advance(try #require(try rows(viewModel).first))

        let row = try #require(try rows(viewModel).first)
        #expect(row.detail == String(localized: "inprogress.progress \(1) \(5) \(10)"))
        #expect(row.next?.number == 6)
    }

    // Avancer coche la suite, une par une : ça ne comble pas les trous derrière.
    @Test func advancingFillsOneHoleAtATime() async throws {
        try series("Severance", episodes: 5, watched: [1, 3])
        let (_, viewModel) = make()
        await viewModel.load()

        await viewModel.advance(try #require(try rows(viewModel).first))

        let logs = try context.fetch(FetchDescriptor<LogEntry>()).filter { $0.episode != nil }
        #expect(Set(logs.compactMap(\.episode?.number)) == [1, 2, 3])
        #expect(try rows(viewModel).first?.next?.number == 4)
    }

    @Test func theLastEpisodeLeavesNothingNext() async throws {
        try series("Severance", episodes: 2, watched: [1])
        let (_, viewModel) = make()
        await viewModel.load()

        await viewModel.advance(try #require(try rows(viewModel).first))

        let row = try #require(try rows(viewModel).first)
        #expect(row.next == nil)
    }

    @Test func finishingTakesItOutOfTheList() async throws {
        try series("Severance", episodes: 2, watched: [1, 2])
        let (_, viewModel) = make()
        await viewModel.load()

        await viewModel.finish(try #require(try rows(viewModel).first))

        #expect(viewModel.state == .empty)
    }

    // Un livre en cours n'a pas d'épisode : il se termine en un tap, c'est tout ce qu'on lui demande.
    @Test func aBookHasNoNextEpisodeAndCanBeFinished() async throws {
        let book = MediaItem(kind: .book, title: "Piranesi")
        context.insert(book)
        context.insert(try LogEntry.make(item: book, status: .inProgress))
        try context.save()
        let (_, viewModel) = make()
        await viewModel.load()

        let row = try #require(try rows(viewModel).first)
        #expect(row.next == nil)
        #expect(row.detail == MediaKind.book.label)

        await viewModel.finish(row)
        #expect(viewModel.state == .empty)
    }

    // Vide (rien en cours) ≠ erreur (la liste n'a pas pu se lire).
    @Test func aRepositoryFailureGivesTheFailedState() async throws {
        let services = AppServices(context: context)
        let viewModel = InProgressViewModel(useCase: InProgressUseCase(repository: UnreadableLogRepository()),
                                            repository: services.mediaRepository,
                                            episodes: services.episodeUseCase,
                                            status: services.watchStatusUseCase)

        await viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test func aWorkDeletedInTheMeantimeDoesNotCrashTheScreen() async throws {
        let item = try series("Severance", episodes: 2, watched: [1])
        let (_, viewModel) = make()
        await viewModel.load()
        let row = try #require(try rows(viewModel).first)

        for log in item.logs { context.delete(log) }
        context.delete(item)
        try context.save()

        await viewModel.advance(row)

        #expect(viewModel.state == .empty)
    }
}

// Un dépôt qui ne répond jamais : c'est ce qui distingue « rien en cours » de « ça n'a pas chargé ».
@MainActor
private struct UnreadableLogRepository: LogRepository {
    struct Failure: Error {}

    func fetchAll() async throws -> [LogEntry] { throw Failure() }
    func find(id: UUID) throws -> LogEntry? { throw Failure() }
    func save() throws { throw Failure() }
    func delete(_ log: LogEntry) throws { throw Failure() }
}
