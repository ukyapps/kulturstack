import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct WishlistViewModelTests {
    private func make(withWish: Bool = true) throws -> (ModelContainer, MediaItem, WishlistViewModel) {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let repository = SwiftDataMediaRepository(context: context)
        let item = MediaItem(kind: .book, title: "Dune", creators: ["Frank Herbert"])
        try repository.add(item, refs: [])
        try repository.add(try LogEntry.make(item: item, status: .done, date: .now.addingTimeInterval(-86_400)))
        if withWish { try repository.add(try LogEntry.make(item: item, status: .wishlist)) }
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        return (container, item, WishlistViewModel(repository: SwiftDataLogRepository(context: context), logUseCase: logUseCase))
    }

    @Test func listsOnlyWishes() async throws {
        let (container, _, viewModel) = try make()
        #expect(viewModel.state == .loading)

        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(rows.count == 1)
        #expect(rows[0].status == .wishlist)
        #expect(rows[0].kind == .book)
        withExtendedLifetime(container) {}
    }

    @Test func noWishGivesTheEmptyState() async throws {
        let (container, _, viewModel) = try make(withWish: false)
        await viewModel.load()
        #expect(viewModel.state == .empty)
        withExtendedLifetime(container) {}
    }

    @Test func markingSeenAddsADoneLogKeepsTheWishInHistoryAndRemovesItFromTheList() async throws {
        let (container, item, viewModel) = try make()
        await viewModel.load()
        guard case .loaded(let rows) = viewModel.state, let wish = rows.first else {
            Issue.record("état attendu : loaded")
            return
        }

        await viewModel.markSeen(id: wish.id)

        #expect(item.logs.count == 3)
        #expect(item.logs.filter { $0.status == .done }.count == 2)
        #expect(item.logs.filter { $0.status == .wishlist }.count == 1)
        #expect(viewModel.didFailToMarkSeen == false)
        #expect(viewModel.state == .empty)
        withExtendedLifetime(container) {}
    }

    @Test func deletingAWishRemovesIt() async throws {
        let (container, item, viewModel) = try make()
        await viewModel.load()
        guard case .loaded(let rows) = viewModel.state, let wish = rows.first else {
            Issue.record("état attendu : loaded")
            return
        }

        await viewModel.delete(id: wish.id)

        #expect(viewModel.state == .empty)
        #expect(item.logs.count == 1)
        withExtendedLifetime(container) {}
    }

    @Test func aRepositoryFailureGivesTheFailedState() async throws {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let logUseCase = LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
        let viewModel = WishlistViewModel(repository: FailingLogRepository(), logUseCase: logUseCase)

        await viewModel.load()

        #expect(viewModel.state == .failed)
        withExtendedLifetime(container) {}
    }
}

private struct FailingError: Error {}

@MainActor
private struct FailingLogRepository: LogRepository {
    func fetchAll() async throws -> [LogEntry] { throw FailingError() }
    func find(id: UUID) throws -> LogEntry? { throw FailingError() }
    func save() throws { throw FailingError() }
    func delete(_ log: LogEntry) throws { throw FailingError() }
}
