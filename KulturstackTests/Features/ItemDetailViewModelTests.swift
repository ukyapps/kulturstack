import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct ItemDetailViewModelTests {
    private func make() throws -> (ModelContainer, MediaItem, ItemDetailViewModel) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let item = MediaItem(kind: .film, title: "Dune", year: 2021)
        try repository.add(item, refs: [ExternalRef(provider: "tmdb", value: "movie:438631")])
        try repository.add(try LogEntry.make(item: item, status: .done, rating: 8))
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        return (container, item, ItemDetailViewModel(itemID: item.id, repository: repository, logUseCase: logUseCase))
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
        let viewModel = ItemDetailViewModel(itemID: UUID(), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        #expect(viewModel.state == .missing)
        withExtendedLifetime(container) {}
    }

    @Test func aRepositoryFailureGivesTheFailedState() {
        let repository = FailingMediaRepository()
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        let viewModel = ItemDetailViewModel(itemID: UUID(), repository: repository, logUseCase: logUseCase)

        viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test func logAgainAddsALogAndRefreshesTheList() throws {
        let (container, item, viewModel) = try make()
        viewModel.load()

        viewModel.logAgain()

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
