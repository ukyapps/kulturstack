import Foundation
import Testing
@testable import Kulturstack

@MainActor
struct SearchViewModelTests {
    private let film = MockProvider.candidate("tmdb:movie:1", kind: .film, title: "Dune")
    private let series = MockProvider.candidate("tmdb:tv:1", kind: .series, title: "Dune : Prophecy")
    private let book = MockProvider.candidate("ol:work:1", kind: .book, title: "Dune")

    private func makeViewModel(tmdb: MockProvider? = nil, openLibrary: MockProvider? = nil,
                               debounce: Duration = .zero) -> (SearchViewModel, MockProvider, MockProvider) {
        let tmdb = tmdb ?? MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([film, series]))
        let openLibrary = openLibrary ?? MockProvider(id: "openlibrary", kinds: [.book], result: .success([book]))
        let useCase = SearchUseCase(providers: [tmdb, openLibrary])
        return (SearchViewModel(useCase: useCase, debounce: debounce), tmdb, openLibrary)
    }

    @Test func aCandidateAlreadyLoggedShowsWhenAndARefreshPicksUpNewLogs() async throws {
        let yesterday = Date.now.addingTimeInterval(-86_400)
        let dates = Dates(byID: ["tmdb:movie:1": yesterday])
        let tmdb = MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([film, series]))
        let viewModel = SearchViewModel(useCase: SearchUseCase(providers: [tmdb]),
                                        lastLogDate: { dates.byID[$0.id] }, debounce: .zero)

        viewModel.query = "dune"
        try await settle(viewModel)

        #expect(viewModel.row(for: film).lastLoggedAt == yesterday)
        #expect(viewModel.row(for: film).loggedLabel?.isEmpty == false)
        #expect(viewModel.row(for: series).lastLoggedAt == nil)
        #expect(viewModel.row(for: series).loggedLabel == nil)

        dates.byID["tmdb:tv:1"] = .now
        viewModel.refreshLogDates()

        #expect(viewModel.row(for: series).lastLoggedAt != nil)
    }

    @Test func thePlusButtonLogsMarksTheRowAndShowsAToastWithTheLogThatFadesOut() async throws {
        let logged = Logged()
        let logID = UUID()
        let tmdb = MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([film]))
        let viewModel = SearchViewModel(useCase: SearchUseCase(providers: [tmdb]),
                                        logNow: { logged.ids.append($0.id); return logID },
                                        debounce: .zero, toastDuration: .milliseconds(60))
        viewModel.query = "dune"
        try await settle(viewModel)
        #expect(viewModel.row(for: film).lastLoggedAt == nil)

        viewModel.log(film)

        #expect(logged.ids == ["tmdb:movie:1"])
        #expect(viewModel.row(for: film).lastLoggedAt != nil)
        #expect(viewModel.toast?.title.isEmpty == false)
        #expect(viewModel.toast?.isError == false)
        #expect(viewModel.toast?.logID == logID)
        try await Task.sleep(for: .milliseconds(150))
        #expect(viewModel.toast == nil)
    }

    // Retour du 23/09 : « on peut enregistrer les trucs en double, on devrait pas ».
    @Test func thePlusOnAnAlreadyLoggedWorkAsksBeforeAddingASecondLog() async throws {
        let logged = Logged()
        let yesterday = Date.now.addingTimeInterval(-86_400)
        let dates = Dates(byID: ["tmdb:movie:1": yesterday])
        let tmdb = MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([film]))
        let viewModel = SearchViewModel(useCase: SearchUseCase(providers: [tmdb]),
                                        logNow: { logged.ids.append($0.id); return UUID() },
                                        lastLogDate: { dates.byID[$0.id] }, debounce: .zero)
        viewModel.query = "dune"
        try await settle(viewModel)

        viewModel.log(film)

        #expect(logged.ids.isEmpty)
        #expect(viewModel.toast == nil)
        let warning = try #require(viewModel.duplicate)
        #expect(warning.title == film.title)
        #expect(warning.loggedLabel == film.kind.loggedLabel(on: yesterday))

        viewModel.confirmDuplicate()

        #expect(logged.ids == ["tmdb:movie:1"])
        #expect(viewModel.duplicate == nil)
        #expect(viewModel.toast?.isError == false)
    }

    @Test func refusingTheSecondLogWritesNothing() async throws {
        let logged = Logged()
        let dates = Dates(byID: ["tmdb:movie:1": .now])
        let tmdb = MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([film]))
        let viewModel = SearchViewModel(useCase: SearchUseCase(providers: [tmdb]),
                                        logNow: { logged.ids.append($0.id); return UUID() },
                                        lastLogDate: { dates.byID[$0.id] }, debounce: .zero)
        viewModel.query = "dune"
        try await settle(viewModel)
        viewModel.log(film)

        viewModel.cancelDuplicate()

        #expect(logged.ids.isEmpty)
        #expect(viewModel.duplicate == nil)
        #expect(viewModel.toast == nil)
    }

    // Deux fois de suite sur le +, sans quitter l'écran : la deuxième fois demande aussi.
    @Test func aSecondTapInTheSameSessionAlsoAsks() {
        let logged = Logged()
        let viewModel = SearchViewModel(useCase: SearchUseCase(providers: []),
                                        logNow: { logged.ids.append($0.id); return UUID() }, debounce: .zero)

        viewModel.log(film)
        viewModel.log(film)

        #expect(logged.ids == ["tmdb:movie:1"])
        #expect(viewModel.duplicate != nil)
    }

    @Test func aFailedQuickLogShowsAnErrorToastAndLeavesTheRowUntouched() {
        let viewModel = SearchViewModel(useCase: SearchUseCase(providers: []),
                                        logNow: { _ in throw HTTPError.status(500) }, debounce: .zero)

        viewModel.log(film)

        #expect(viewModel.toast?.isError == true)
        #expect(viewModel.toast?.logID == nil)
        #expect(viewModel.row(for: film).lastLoggedAt == nil)
    }

    @Test func keepingForLaterWishesAndShowsAToastWithTheLog() {
        let wished = Logged()
        let logID = UUID()
        let viewModel = SearchViewModel(useCase: SearchUseCase(providers: []),
                                        wish: { wished.ids.append($0.id); return logID }, debounce: .zero)

        viewModel.wish(film)

        #expect(wished.ids == ["tmdb:movie:1"])
        #expect(viewModel.toast?.isError == false)
        #expect(viewModel.toast?.logID == logID)
        #expect(viewModel.row(for: film).lastLoggedAt == nil)
    }

    private final class Logged { var ids: [String] = [] }
    private final class Dates { var byID: [String: Date]; init(byID: [String: Date]) { self.byID = byID } }

    private func settle(_ viewModel: SearchViewModel) async throws {
        for _ in 0..<200 {
            if !viewModel.sections.isEmpty, viewModel.sections.allSatisfy({ $0.state != .loading }) { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("la recherche ne s'est pas stabilisée")
    }

    @Test func startsIdleAndStaysIdleUnderTwoCharacters() async throws {
        let (viewModel, tmdb, _) = makeViewModel()
        #expect(viewModel.presentation == .idle)

        viewModel.query = "d"
        try await Task.sleep(for: .milliseconds(30))

        #expect(viewModel.presentation == .idle)
        #expect(tmdb.calls.isEmpty)
    }

    @Test func aQueryProducesOneSectionPerFamily() async throws {
        let (viewModel, _, _) = makeViewModel()

        viewModel.query = "dune"
        try await settle(viewModel)

        #expect(viewModel.presentation == .sections([
            SearchSection(family: .screen, state: .loaded([film, series])),
            SearchSection(family: .books, state: .loaded([book])),
        ]))
    }

    @Test func typingIsDebouncedToTheLastQuery() async throws {
        let (viewModel, tmdb, openLibrary) = makeViewModel(debounce: .milliseconds(80))

        viewModel.query = "du"
        try await Task.sleep(for: .milliseconds(20))
        viewModel.query = "dun"
        try await Task.sleep(for: .milliseconds(20))
        viewModel.query = "dune"
        try await settle(viewModel)

        #expect(tmdb.calls == ["dune"])
        #expect(openLibrary.calls == ["dune"])
    }

    @Test func clearingTheQueryGoesBackToIdle() async throws {
        let (viewModel, _, _) = makeViewModel()
        viewModel.query = "dune"
        try await settle(viewModel)

        viewModel.query = ""
        try await Task.sleep(for: .milliseconds(30))

        #expect(viewModel.presentation == .idle)
        #expect(viewModel.sections.isEmpty)
    }

    @Test func kindFilterKeepsOnlyMatchingCandidatesAndHidesOtherFamilies() async throws {
        let (viewModel, _, _) = makeViewModel()
        viewModel.query = "dune"
        try await settle(viewModel)

        viewModel.selectedKind = .series
        #expect(viewModel.presentation == .sections([SearchSection(family: .screen, state: .loaded([series]))]))

        viewModel.selectedKind = .book
        #expect(viewModel.presentation == .sections([SearchSection(family: .books, state: .loaded([book]))]))

        viewModel.selectedKind = nil
        #expect(viewModel.presentation == .sections(viewModel.sections))
    }

    @Test func filterWithNothingLeftIsAnEdgeState() async throws {
        let tmdb = MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([film]))
        let (viewModel, _, _) = makeViewModel(tmdb: tmdb)
        viewModel.query = "dune"
        try await settle(viewModel)

        viewModel.selectedKind = .series

        #expect(viewModel.presentation == .noResultsForKind(.series))
    }

    @Test func nothingAnywhereIsANoResultsState() async throws {
        let tmdb = MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([]))
        let openLibrary = MockProvider(id: "openlibrary", kinds: [.book], result: .success([]))
        let (viewModel, _, _) = makeViewModel(tmdb: tmdb, openLibrary: openLibrary)

        viewModel.query = "zzzz"
        try await settle(viewModel)

        #expect(viewModel.presentation == .noResults(query: "zzzz"))
    }

    @Test func aFailedSectionStaysVisibleNextToResults() async throws {
        let openLibrary = MockProvider(id: "openlibrary", kinds: [.book], result: .failure(HTTPError.status(503)))
        let (viewModel, _, _) = makeViewModel(openLibrary: openLibrary)

        viewModel.query = "dune"
        try await settle(viewModel)

        guard case .sections(let sections) = viewModel.presentation else {
            Issue.record("sections attendues")
            return
        }
        #expect(sections.map(\.family) == [.screen, .books])
        guard case .failed = sections[1].state else {
            Issue.record("Livres devrait être en erreur")
            return
        }
    }

    @Test func retryOnlyRequeriesThatFamily() async throws {
        let (viewModel, tmdb, openLibrary) = makeViewModel()
        viewModel.query = "dune"
        try await settle(viewModel)

        viewModel.retry(.books)
        try await Task.sleep(for: .milliseconds(30))
        try await settle(viewModel)

        #expect(tmdb.calls == ["dune"])
        #expect(openLibrary.calls == ["dune", "dune"])
    }

    @Test func chipsListTheKindsOfTheRegisteredFamilies() {
        let (viewModel, _, _) = makeViewModel()
        #expect(viewModel.availableKinds == [.film, .series, .book])
    }

    @Test func candidatesKeepTheirProviderSubtitle() {
        let row = SearchResultRowModel(candidate: MediaCandidate(
            id: "tmdb:movie:1", kind: .film, title: "Dune", originalTitle: nil, year: 2021,
            creators: ["Denis Villeneuve"], coverURL: nil, summary: nil, externalKeys: [], details: FilmDetails(), providerID: "tmdb"))
        #expect(row.title == "Dune")
        #expect(row.subtitle.contains("2021"))
        #expect(row.subtitle.contains("Denis Villeneuve"))
        #expect(row.subtitle.contains(MediaKind.film.label))
    }
}
