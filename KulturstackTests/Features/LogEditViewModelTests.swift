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

    // « Logger » depuis la fiche ouvre ce formulaire : rien n'est écrit avant « Enregistrer ».
    @Test func creatingForAStoredItemFillsTheFormWithoutWritingAnything() throws {
        let (container, item, viewModel) = try makeCreation()

        viewModel.load()

        #expect(viewModel.state == .ready)
        #expect(viewModel.isCreating)
        #expect(viewModel.title == "Dune (2021)")
        #expect(viewModel.status == .done)
        #expect(viewModel.rating == nil)
        #expect(viewModel.note == "")
        #expect(viewModel.allowedStatuses == item.kind.allowedStatuses)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<LogEntry>()) == 0)
        withExtendedLifetime(container) {}
    }

    @Test func savingANewLogWritesItOnceWithTheFormValues() throws {
        let (container, item, viewModel) = try makeCreation()
        viewModel.load()
        let seen = Date.now.addingTimeInterval(-86_400)
        viewModel.date = seen
        viewModel.rating = 9
        viewModel.note = "  La copie restaurée  "

        #expect(viewModel.save())

        let logs = try container.mainContext.fetch(FetchDescriptor<LogEntry>())
        #expect(logs.count == 1)
        #expect(logs.first?.item?.id == item.id)
        #expect(logs.first?.date == seen)
        #expect(logs.first?.rating == 9)
        #expect(logs.first?.note == "La copie restaurée")
        #expect(viewModel.didFail == false)
        withExtendedLifetime(container) {}
    }

    @Test func creatingForACandidateStoresTheWorkOnlyOnSaveAndNeverTwice() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let candidate = MediaCandidate(
            id: "tmdb:movie:16337", kind: .film, title: "La Planète sauvage", originalTitle: nil, year: 1973,
            creators: [], coverURL: nil, summary: nil, externalKeys: ["tmdb:movie:16337"],
            details: FilmDetails(), providerID: "tmdb")

        for _ in 0..<2 {
            let viewModel = makeCreation(context: context, target: .candidate(candidate))
            viewModel.load()
            #expect(viewModel.title == "La Planète sauvage (1973)")
            #expect(viewModel.save())
        }

        #expect(try context.fetchCount(FetchDescriptor<MediaItem>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<LogEntry>()) == 2)
        withExtendedLifetime(container) {}
    }

    @Test func creatingForAWorkThatNoLongerExistsIsMissing() throws {
        let container = try ModelContainerFactory.inMemory()
        let viewModel = makeCreation(context: container.mainContext, target: .item(UUID()))

        viewModel.load()

        #expect(viewModel.state == .missing)
        withExtendedLifetime(container) {}
    }

    private func makeCreation() throws -> (ModelContainer, MediaItem, LogEditViewModel) {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .film, title: "Dune", year: 2021)
        context.insert(item)
        try context.save()
        return (container, item, makeCreation(context: context, target: .item(item.id)))
    }

    private func makeCreation(context: ModelContext, target: LogTarget) -> LogEditViewModel {
        let repository = SwiftDataMediaRepository(context: context)
        return LogEditViewModel(target: target,
                                useCase: EditLogUseCase(repository: SwiftDataLogRepository(context: context)),
                                repository: repository,
                                logUseCase: LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository)))
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
