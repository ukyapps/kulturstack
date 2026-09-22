import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct ItemDetailViewModelTests {
    private let dune = MediaCandidate(
        id: "tmdb:movie:438631", kind: .film, title: "Dune", originalTitle: "Dune", year: 2021, creators: ["Denis Villeneuve"],
        coverURL: nil, summary: "Paul…", externalKeys: ["tmdb:movie:438631"], details: FilmDetails(), providerID: "tmdb")

    private func make() throws -> (ModelContainer, MediaItem, ItemDetailViewModel) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let item = MediaItem(kind: .film, title: "Dune", year: 2021)
        try repository.add(item, refs: [ExternalRef(provider: "tmdb", value: "movie:438631")])
        try repository.add(try LogEntry.make(item: item, status: .done, rating: 8))
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        return (container, item, ItemDetailViewModel(subject: .stored(item.id), repository: repository, logUseCase: logUseCase))
    }

    private func makeEmpty() throws -> (ModelContainer, SwiftDataMediaRepository, LogUseCase) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        return (container, repository, LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository)))
    }

    @Test func aCandidateNotYetStoredIsPreviewedWithoutLogs() throws {
        let (container, repository, logUseCase) = try makeEmpty()
        let viewModel = ItemDetailViewModel(subject: .candidate(dune), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.title == "Dune")
        #expect(model.logs.isEmpty)
        #expect(model.source == "TMDB")
        #expect(try container.mainContext.fetchCount(FetchDescriptor<MediaItem>()) == 0)
    }

    @Test func aCandidateAlreadyStoredShowsTheStoredItemAndItsLogs() throws {
        let (container, item, _) = try make()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        let viewModel = ItemDetailViewModel(subject: .candidate(dune), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.id == item.id)
        #expect(model.logs.count == 1)
    }

    @Test func loggingACandidateCreatesTheItemOnceAndListsItsLogs() throws {
        let (container, repository, logUseCase) = try makeEmpty()
        let viewModel = ItemDetailViewModel(subject: .candidate(dune), repository: repository, logUseCase: logUseCase)
        viewModel.load()

        viewModel.log()
        viewModel.log()

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.logs.count == 2)
        #expect(model.logs.allSatisfy { $0.status == .done })
        #expect(try container.mainContext.fetchCount(FetchDescriptor<MediaItem>()) == 1)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<LogEntry>()) == 2)
    }

    @Test func loadGivesASnapshotOfTheItem() throws {
        let (container, _, viewModel) = try make()
        #expect(viewModel.state == .loading)

        viewModel.load()

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.title == "Dune")
        #expect(model.logs.count == 1)
        #expect(model.source == "TMDB")
        withExtendedLifetime(container) {}
    }

    @Test func anUnknownItemGivesTheMissingState() throws {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        let viewModel = ItemDetailViewModel(subject: .stored(UUID()), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        #expect(viewModel.state == .missing)
        withExtendedLifetime(container) {}
    }

    @Test func aRepositoryFailureGivesTheFailedState() {
        let repository = FailingMediaRepository()
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        let viewModel = ItemDetailViewModel(subject: .stored(UUID()), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test func logAgainAddsALogAndRefreshesTheList() throws {
        let (container, item, viewModel) = try make()
        viewModel.load()

        viewModel.log()

        guard case .loaded(let model) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(model.logs.count == 2)
        #expect(model.logs[0].status == .done)
        #expect(item.logs.count == 2)
        #expect(viewModel.didFailToLog == false)
        withExtendedLifetime(container) {}
    }
}

private struct FailingError: Error {}

@MainActor
private struct FailingMediaRepository: MediaRepository {
    func findItem(withAnyKey keys: [String]) throws -> MediaItem? { throw FailingError() }
    func find(itemID: UUID) throws -> MediaItem? { throw FailingError() }
    func add(_ item: MediaItem, refs: [ExternalRef]) throws { throw FailingError() }
    func add(_ refs: [ExternalRef], to item: MediaItem) throws { throw FailingError() }
    func add(_ log: LogEntry) throws { throw FailingError() }
}
