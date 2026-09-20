import Foundation
import SwiftData
import Testing
@testable import Kulturstack

struct JournalViewModelTests {
    @Test @MainActor func startsLoading() {
        let viewModel = JournalViewModel(repository: StubLogRepository(result: .success([])))
        #expect(viewModel.state == .loading)
    }

    @Test @MainActor func noLogsGivesEmptyState() async {
        let viewModel = JournalViewModel(repository: StubLogRepository(result: .success([])))
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test @MainActor func logsGiveLoadedStateInRepositoryOrder() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .book, title: "Dune")
        context.insert(item)
        let recent = try LogEntry.make(item: item, status: .done)
        let older = try LogEntry.make(item: item, status: .done, date: .now.addingTimeInterval(-86_400))
        context.insert(recent)
        context.insert(older)

        let viewModel = JournalViewModel(repository: StubLogRepository(result: .success([recent, older])))
        await viewModel.load()

        #expect(viewModel.state == .loaded([recent, older].map(JournalRowModel.init)))
    }

    @Test @MainActor func repositoryFailureGivesFailedState() async {
        let viewModel = JournalViewModel(repository: StubLogRepository(result: .failure(StubError())))
        await viewModel.load()
        #expect(viewModel.state == .failed)
    }

    @Test @MainActor func reloadAfterFailureRecovers() async {
        let repository = StubLogRepository(result: .failure(StubError()))
        let viewModel = JournalViewModel(repository: repository)
        await viewModel.load()
        repository.result = .success([])
        await viewModel.load()
        #expect(viewModel.state == .empty)
    }

    @Test @MainActor func loadedStateSurvivesDeletionOfTheUnderlyingLogs() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context).fill()
        let viewModel = JournalViewModel(repository: SwiftDataLogRepository(context: context))
        await viewModel.load()

        try DemoSeed(context: context).wipe()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(rows.allSatisfy { !$0.title.isEmpty })
    }
}

private struct StubError: Error {}

@MainActor
private final class StubLogRepository: LogRepository {
    var result: Result<[LogEntry], Error>

    init(result: Result<[LogEntry], Error>) { self.result = result }

    func fetchAll() async throws -> [LogEntry] { try result.get() }
}
