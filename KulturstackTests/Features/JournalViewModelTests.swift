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
        let arrival = MediaItem(kind: .film, title: "Premier Contact")
        let book = MediaItem(kind: .book, title: "Dune")
        for item in [dune, arrival, book] { context.insert(item) }
        // Dune est vu deux fois : depuis le 30/09 ça fait une ligne, pas deux.
        context.insert(try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 22)))
        context.insert(try LogEntry.make(item: dune, status: .done, date: date(2026, 9, 20)))
        context.insert(try LogEntry.make(item: arrival, status: .done, date: date(2026, 9, 21)))
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
        // Les deux visionnages de Dune tiennent sur la ligne du 22, pas sur deux jours.
        #expect(content.sections[0].rows.map(\.title) == ["Dune"])
        #expect(content.sections[0].rows[0].timesSeen == 2)
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
    func delete(_ logs: [LogEntry]) throws { throw StubError() }
}

@MainActor
private final class StubLogRepository: LogRepository {
    var result: Result<[LogEntry], Error>

    init(result: Result<[LogEntry], Error>) { self.result = result }

    func fetchAll() async throws -> [LogEntry] { try result.get() }
    func find(id: UUID) throws -> LogEntry? { try result.get().first { $0.id == id } }
    func save() throws {}
    func delete(_ log: LogEntry) throws { throw StubError() }
    func delete(_ logs: [LogEntry]) throws { throw StubError() }
}

// Cocher des épisodes ne doit pas noyer le journal : une saison cochée, c'est une ligne
// « en cours » sur l'œuvre, pas dix lignes identiques.
@MainActor
struct JournalEpisodeLogsTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func severance() throws -> (MediaItem, [LogEntry]) {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        var logs: [LogEntry] = []
        for number in 1...3 {
            let episode = Episode(number: number, season: season)
            context.insert(episode)
            let log = try LogEntry.make(item: item, status: .done, episode: episode)
            context.insert(log)
            logs.append(log)
        }
        let status = try LogEntry.make(item: item, status: .inProgress,
                                       source: WatchStatusUseCase.automaticSource)
        context.insert(status)
        try context.save()
        return (item, logs + [status])
    }

    @Test func theJournalShowsTheStatusNotEachCheckedEpisode() async throws {
        let (_, logs) = try severance()
        let viewModel = JournalViewModel(repository: StubLogRepository(result: .success(logs)))

        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(rows.count == 1)
        #expect(rows.first?.status == .inProgress)
    }

    @Test func aSeriesOnlyTickedEpisodeByEpisodeIsNotAnEmptyJournal() async throws {
        let (_, logs) = try severance()
        let episodesOnly = logs.filter { $0.episode != nil }
        let viewModel = JournalViewModel(repository: StubLogRepository(result: .success(episodesOnly)))

        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    // La fiche montre les épisodes juste au-dessus, cochés : les relister en bas est du bruit.
    @Test func theItemDetailDoesNotListEachCheckedEpisode() throws {
        let (item, _) = try severance()

        let model = ItemDetailModel(item: item)

        #expect(model.logs.count == 1)
        #expect(model.logs.first?.status == .inProgress)
    }

    // MARK: - Le prochain épisode depuis le Journal (retour du 27/09)

    @Test @MainActor func advancingFromTheJournalChecksTheNextEpisodeAndMovesTheLine() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let services = AppServices(context: context)
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: 2, item: item)
        context.insert(season)
        for number in 1...5 { context.insert(Episode(number: number, season: season)) }
        try context.save()
        context.insert(try LogEntry.make(item: item, status: .done, episode: season.orderedEpisodes[0]))
        context.insert(try LogEntry.make(item: item, status: .inProgress,
                                         source: WatchStatusUseCase.automaticSource))
        try context.save()
        let viewModel = JournalViewModel(repository: services.logRepository, advance: services.advanceUseCase)
        await viewModel.load()
        let row = try #require(rows(of: viewModel).first { $0.watch != nil })
        #expect(row.watch?.next?.number == 2)

        await viewModel.advance(row)

        let after = try #require(rows(of: viewModel).first { $0.watch != nil })
        #expect(after.watch?.position?.position == 2)
        #expect(after.watch?.next?.number == 3)
        #expect(viewModel.didFailToAdvance == false)
        withExtendedLifetime(container) {}
    }

    // Sans de quoi avancer, le Journal ne propose pas le bouton plutôt que de mentir.
    @Test @MainActor func aJournalWithoutTheMeansToAdvanceDoesNotOfferIt() async throws {
        let viewModel = JournalViewModel(repository: StubLogRepository(result: .success([])))

        #expect(viewModel.canAdvance == false)
    }


    // « Dans journal, tout est toujours dupliqué… une œuvre = une seule fiche » (founder, 30/09).
    @Test @MainActor func theJournalShowsOneLinePerWorkNotPerLog() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        let severance = MediaItem(kind: .series, title: "Severance")
        for item in [dune, severance] { context.insert(item) }
        let logs = [
            try LogEntry.make(item: dune, status: .done, date: Self.day(22), rating: 8),
            try LogEntry.make(item: dune, status: .done, date: Self.day(12)),
            try LogEntry.make(item: severance, status: .done, date: Self.day(20), note: "Parfaite"),
            try LogEntry.make(item: severance, status: .inProgress, date: Self.day(21),
                              source: WatchStatusUseCase.automaticSource),
        ]
        for log in logs { context.insert(log) }
        let viewModel = Self.viewModel(logs: logs)

        await viewModel.load()

        let rows = self.rows(of: viewModel)
        #expect(rows.count == 2)
        #expect(rows.map(\.title) == ["Dune", "Severance"])
        // La note et le commentaire survivent au regroupement, quel que soit le log qui les porte.
        #expect(rows[0].rating == 8)
        #expect(rows[1].note == "Parfaite")
        #expect(rows[1].status == .inProgress)
        withExtendedLifetime(container) {}
    }

    // Les compteurs comptent ce que la liste montre : des œuvres. C'est l'inverse de la règle
    // T-16 d'origine, et c'est la founder qui l'a tranché le 30/09.
    @Test @MainActor func theCountersCountWorksNotLogs() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        context.insert(dune)
        let logs = [
            try LogEntry.make(item: dune, status: .done, date: Self.day(22)),
            try LogEntry.make(item: dune, status: .done, date: Self.day(21)),
            try LogEntry.make(item: dune, status: .done, date: Self.day(20)),
        ]
        for log in logs { context.insert(log) }
        let viewModel = Self.viewModel(logs: logs)

        await viewModel.load()

        guard case .loaded(let content) = viewModel.presentation else {
            Issue.record("état attendu : loaded")
            return
        }
        #expect(content.total == 1)
        #expect(viewModel.kindCounts == [JournalContent.KindCount(kind: .film, count: 1)])
        withExtendedLifetime(container) {}
    }

    // Le filtre s'applique aux logs, le regroupement à ce qui reste : une œuvre vue cette
    // semaine et l'an dernier appartient bien à « Semaine », datée de cette semaine.
    @Test @MainActor func aWorkSeenTwiceBelongsToThePeriodOfItsLatestLog() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        context.insert(dune)
        let logs = [
            try LogEntry.make(item: dune, status: .done, date: Self.day(22)),
            try LogEntry.make(item: dune, status: .done, date: Self.calendar.date(from: DateComponents(year: 2025, month: 4, day: 3, hour: 12))!),
        ]
        for log in logs { context.insert(log) }
        let viewModel = Self.viewModel(logs: logs)
        await viewModel.load()

        viewModel.period = .week
        let week = self.rows(of: viewModel)
        #expect(week.map(\.date) == [Self.day(22)])

        viewModel.period = .all
        let all = self.rows(of: viewModel)
        #expect(all.map(\.date) == [Self.day(22)])
        #expect(all[0].timesSeen == 2)
        withExtendedLifetime(container) {}
    }

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }

    private static func day(_ day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 12))!
    }

    @MainActor
    private static func viewModel(logs: [LogEntry]) -> JournalViewModel {
        JournalViewModel(repository: StubLogRepository(result: .success(logs)),
                         now: { day(23) }, calendar: calendar)
    }

    @MainActor
    private func rows(of viewModel: JournalViewModel) -> [JournalRowModel] {
        guard case .loaded(let content) = viewModel.presentation else { return [] }
        return content.sections.flatMap(\.rows)
    }
}
