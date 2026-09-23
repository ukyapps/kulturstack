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

    @Test @MainActor func deletingALogRemovesItAndReloads() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .film, title: "Dune")
        context.insert(item)
        let log = try LogEntry.make(item: item, status: .done)
        context.insert(log)
        try context.save()
        let viewModel = JournalViewModel(repository: SwiftDataLogRepository(context: context))
        await viewModel.load()

        await viewModel.delete(id: log.id)

        #expect(viewModel.state == .empty)
        #expect(viewModel.didFailToDelete == false)
        #expect(try context.fetchCount(FetchDescriptor<LogEntry>()) == 0)
    }

    @Test @MainActor func aFailedDeletionIsReported() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .film, title: "Dune")
        context.insert(item)
        let log = try LogEntry.make(item: item, status: .done)
        context.insert(log)
        let viewModel = JournalViewModel(repository: StubLogRepository(result: .success([log])))
        await viewModel.load()

        await viewModel.delete(id: log.id)

        #expect(viewModel.didFailToDelete)
        #expect(viewModel.state == .loaded([JournalRowModel(log: log)]))
    }
}

private struct StubError: Error {}

@MainActor
struct JournalFilterTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeViewModel() throws -> (ModelContainer, JournalViewModel) {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        let book = MediaItem(kind: .book, title: "Dune")
        for item in [dune, book] { context.insert(item) }
        context.insert(try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 22)))
        context.insert(try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 21)))
        context.insert(try LogEntry.make(item: book, status: .done, date: date(2026, 9, 2)))
        context.insert(try LogEntry.make(item: book, status: .wishlist, date: date(2026, 9, 22)))
        try context.save()
        let viewModel = JournalViewModel(repository: SwiftDataLogRepository(context: context),
                                         now: { self.date(2026, 9, 22) }, calendar: calendar)
        return (container, viewModel)
    }

    @Test func wishesStayOutOfTheJournalAndItsCounts() async throws {
        let (container, viewModel) = try makeViewModel()
        await viewModel.load()

        #expect(viewModel.kindCounts.map(\.count) == [2, 1])
        guard case .loaded(let content) = viewModel.presentation else {
            Issue.record("présentation attendue : loaded")
            return
        }
        #expect(content.total == 3)
        withExtendedLifetime(container) {}
    }

    @Test func onlyWishesMeansAnEmptyJournal() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .film, title: "Dune")
        context.insert(item)
        context.insert(try LogEntry.make(item: item, status: .wishlist))
        try context.save()
        let viewModel = JournalViewModel(repository: SwiftDataLogRepository(context: context))
        await viewModel.load()

        #expect(viewModel.presentation == .empty)
    }


    // Un journal s'ouvre sur tout ce qu'on a loggé : filtrer est un geste, pas un défaut.
    @Test func opensOnEverythingGroupedByDayWithCounts() async throws {
        let (container, viewModel) = try makeViewModel()
        await viewModel.load()

        #expect(viewModel.period == .all)
        guard case .loaded(let content) = viewModel.presentation else {
            Issue.record("présentation attendue : loaded")
            return
        }
        #expect(content.total == 3)
        #expect(Array(content.sections.map(\.title).prefix(2)) == [String(localized: "journal.day.today"), String(localized: "journal.day.yesterday")])
        #expect(content.sections.count == 3)
        #expect(viewModel.kindCounts.map(\.kind) == [.film, .book])
        #expect(viewModel.kindCounts.map(\.count) == [2, 1])
        withExtendedLifetime(container) {}
    }

    // Le retour du 23/09 : un log daté hors de la semaine courante avait l'air perdu.
    @Test func aLogDatedBeforeThisWeekShowsUpWhenTheJournalOpens() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .film, title: "La Planète sauvage")
        context.insert(item)
        context.insert(try LogEntry.make(item: item, status: .done, date: date(2026, 8, 30)))
        try context.save()
        let viewModel = JournalViewModel(repository: SwiftDataLogRepository(context: context),
                                         now: { self.date(2026, 9, 22) }, calendar: calendar)

        await viewModel.load()

        guard case .loaded(let content) = viewModel.presentation else {
            Issue.record("présentation attendue : loaded")
            return
        }
        #expect(content.total == 1)
        withExtendedLifetime(container) {}
    }

    @Test func periodAndKindCombine() async throws {
        let (container, viewModel) = try makeViewModel()
        await viewModel.load()

        viewModel.period = .month
        viewModel.selectedKind = .book

        guard case .loaded(let content) = viewModel.presentation else {
            Issue.record("présentation attendue : loaded")
            return
        }
        #expect(content.total == 1)
        #expect(content.sections.flatMap(\.rows).map(\.date) == [date(2026, 9, 2)])
        withExtendedLifetime(container) {}
    }

    @Test func aFilterWithoutResultIsAnEdgeNotAnEmptyJournal() async throws {
        let (container, viewModel) = try makeViewModel()
        await viewModel.load()

        viewModel.period = .week
        viewModel.selectedKind = .book

        #expect(viewModel.presentation == .edge(period: .week, kind: .book))
        #expect(viewModel.kindCounts.map(\.kind) == [.film, .book])

        viewModel.showAll()

        #expect(viewModel.period == .all)
        #expect(viewModel.selectedKind == nil)
        guard case .loaded(let content) = viewModel.presentation else {
            Issue.record("présentation attendue : loaded")
            return
        }
        #expect(content.total == 3)
        withExtendedLifetime(container) {}
    }

    @Test func noLogsAtAllIsEmptyWhateverTheFilter() async throws {
        let container = try ModelContainerFactory.inMemory()
        let viewModel = JournalViewModel(repository: SwiftDataLogRepository(context: container.mainContext))
        await viewModel.load()
        viewModel.selectedKind = .book

        #expect(viewModel.presentation == .empty)
    }

    @Test func aFailureStaysAFailure() async {
        let viewModel = JournalViewModel(repository: FailingLogRepository())
        await viewModel.load()
        viewModel.period = .all

        #expect(viewModel.presentation == .failed)
    }
}

@MainActor
private struct FailingLogRepository: LogRepository {
    func fetchAll() async throws -> [LogEntry] { throw StubError() }
    func find(id: UUID) throws -> LogEntry? { throw StubError() }
    func save() throws { throw StubError() }
    func delete(_ log: LogEntry) throws { throw StubError() }
}

@MainActor
private final class StubLogRepository: LogRepository {
    var result: Result<[LogEntry], Error>

    init(result: Result<[LogEntry], Error>) { self.result = result }

    func fetchAll() async throws -> [LogEntry] { try result.get() }
    func find(id: UUID) throws -> LogEntry? { try result.get().first { $0.id == id } }
    func save() throws {}
    func delete(_ log: LogEntry) throws { throw StubError() }
}
