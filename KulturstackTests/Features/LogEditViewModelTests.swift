import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct LogEditViewModelTests {
    private func makeLog(kind: MediaKind = .film, year: Int? = 2021) throws -> (ModelContainer, LogEntry, EditLogUseCase) {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: kind, title: "Dune", year: year)
        context.insert(item)
        let log = try LogEntry.make(item: item, status: .done, rating: 8, note: "Bien")
        context.insert(log)
        try context.save()
        return (container, log, EditLogUseCase(repository: SwiftDataLogRepository(context: context)))
    }

    @Test func loadFillsTheFormFromTheLog() throws {
        let (container, log, useCase) = try makeLog()
        let viewModel = LogEditViewModel(logID: log.id, useCase: useCase)
        #expect(viewModel.state == .loading)

        viewModel.load()

        #expect(viewModel.state == .ready)
        #expect(viewModel.title == "Dune (2021)")
        #expect(viewModel.itemID == log.item?.id)
        #expect(viewModel.date == log.date)
        #expect(viewModel.status == .done)
        #expect(viewModel.rating == 8)
        #expect(viewModel.note == "Bien")
        #expect(try container.mainContext.fetchCount(FetchDescriptor<LogEntry>()) == 1)
    }

    @Test func titleWithoutYearIsJustTheTitle() throws {
        let (container, log, useCase) = try makeLog(year: nil)
        let viewModel = LogEditViewModel(logID: log.id, useCase: useCase)
        viewModel.load()
        #expect(viewModel.title == "Dune")
        withExtendedLifetime(container) {}
    }

    @Test(arguments: [
        (MediaKind.film, [LogStatus.wishlist, .done]),
        (MediaKind.book, [LogStatus.wishlist, .inProgress, .done, .dropped]),
    ])
    func statusesOfferedAreThoseOfTheKind(kind: MediaKind, expected: [LogStatus]) throws {
        let (container, log, useCase) = try makeLog(kind: kind)
        let viewModel = LogEditViewModel(logID: log.id, useCase: useCase)
        viewModel.load()
        #expect(viewModel.allowedStatuses == expected)
        withExtendedLifetime(container) {}
    }

    @Test func aMissingLogGivesTheMissingState() throws {
        let (container, _, useCase) = try makeLog()
        let viewModel = LogEditViewModel(logID: UUID(), useCase: useCase)
        viewModel.load()
        #expect(viewModel.state == .missing)
        withExtendedLifetime(container) {}
    }

    @Test func aRepositoryFailureGivesTheFailedState() {
        let viewModel = LogEditViewModel(logID: UUID(), useCase: EditLogUseCase(repository: FailingLogRepository()))
        viewModel.load()
        #expect(viewModel.state == .failed)
    }

    @Test func saveWritesTheFormBack() throws {
        let (container, log, useCase) = try makeLog()
        let viewModel = LogEditViewModel(logID: log.id, useCase: useCase)
        viewModel.load()
        let yesterday = Date.now.addingTimeInterval(-86_400)
        viewModel.date = yesterday
        viewModel.status = .wishlist
        viewModel.rating = 3
        viewModel.note = "  Revu  "

        #expect(viewModel.save())

        #expect(log.date == yesterday)
        #expect(log.status == .wishlist)
        #expect(log.rating == 3)
        #expect(log.note == "Revu")
        #expect(viewModel.didFail == false)
        withExtendedLifetime(container) {}
    }

    @Test func saveFailureIsReportedAndNothingChanges() throws {
        let (container, log, useCase) = try makeLog()
        let viewModel = LogEditViewModel(logID: log.id, useCase: useCase)
        viewModel.load()
        viewModel.rating = 42

        #expect(viewModel.save() == false)

        #expect(viewModel.didFail)
        #expect(log.rating == 8)
        withExtendedLifetime(container) {}
    }

    @Test func deleteRemovesTheLog() throws {
        let (container, log, useCase) = try makeLog()
        let viewModel = LogEditViewModel(logID: log.id, useCase: useCase)
        viewModel.load()

        #expect(viewModel.delete())

        #expect(try container.mainContext.fetchCount(FetchDescriptor<LogEntry>()) == 0)
    }

    @Test func shortcutsMoveTheDate() throws {
        let (container, log, useCase) = try makeLog()
        let viewModel = LogEditViewModel(logID: log.id, useCase: useCase)
        viewModel.load()
        let now = Date.now

        viewModel.apply(.yesterday, now: now)

        #expect(viewModel.date == Calendar.current.date(byAdding: .day, value: -1, to: now))
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
