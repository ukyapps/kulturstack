import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct SearchViewRenderingTests {
    @Test func rendersEveryPresentation() async throws {
        let film = MockProvider.candidate("tmdb:movie:1", kind: .film, title: "Dune")
        let useCase = SearchUseCase(providers: [
            MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([film])),
            MockProvider(id: "openlibrary", kinds: [.book], result: .failure(HTTPError.status(503))),
        ])
        let container = try ModelContainerFactory.inMemory()
        let searchView = SearchView(useCase: useCase, services: AppServices(context: container.mainContext), debounce: .zero)
        let host = UIHostingController(rootView: NavigationStack { searchView })
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        let viewModel = searchView.viewModelForTesting
        #expect(viewModel.presentation == .idle)

        viewModel.query = "dune"
        for _ in 0..<200 where !(viewModel.sections.count == 2 && viewModel.sections.allSatisfy { $0.state != .loading }) {
            try await Task.sleep(for: .milliseconds(10))
        }
        host.view.layoutIfNeeded()
        guard case .sections = viewModel.presentation else {
            Issue.record("sections attendues")
            return
        }

        viewModel.selectedKind = .series
        host.view.layoutIfNeeded()
        #expect(viewModel.presentation == .noResultsForKind(.series))

        viewModel.selectedKind = nil
        viewModel.query = ""
        try await Task.sleep(for: .milliseconds(30))
        host.view.layoutIfNeeded()
        #expect(viewModel.presentation == .idle)
    }

    // Le bouton d'une série mène à ses épisodes, celui d'un film logge : deux lignes différentes.
    @Test func aSeriesRowAndAFilmRowDoNotOfferTheSameButton() throws {
        var shots: [Data] = []
        for kind in [MediaKind.series, .film] {
            let row = SearchResultRow(model: SearchResultRowModel(
                candidate: MockProvider.candidate("x:1", kind: kind, title: "Severance")), onLog: {}, onWish: {})
            let host = UIHostingController(rootView: row.frame(width: 390))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 120))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.frame = window.bounds
            host.view.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            shots.append(renderer.image { context in window.layer.render(in: context.cgContext) }.pngData() ?? Data())
        }

        #expect(Set(shots).count == 2)
    }

    // La section Disques n'a pas une ligne de code d'écran : elle naît du provider déclaré.
    // Ce qui doit rester vrai, c'est que ses trois rendus ne se confondent pas — rien loggé,
    // chargement raté, et la liste. Comparés image contre image : un `height > 0` passerait
    // même si les trois étaient blanches.
    @Test func theAlbumSectionHasThreeDistinctRenders() async throws {
        var shots: [Data] = []
        let album = MockProvider.candidate("itunes:album:617154241", kind: .album, title: "Random Access Memories")
        for result in [Result<[MediaCandidate], any Error>.success([album]), .success([]),
                       .failure(HTTPError.status(503))] {
            let useCase = SearchUseCase(providers: [MockProvider(id: "apple-music", kinds: [.album], result: result)])
            let container = try ModelContainerFactory.inMemory()
            let searchView = SearchView(useCase: useCase, services: AppServices(context: container.mainContext),
                                        debounce: .zero)
            let host = UIHostingController(rootView: searchView)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()

            let viewModel = searchView.viewModelForTesting
            viewModel.query = "random access memories"
            for _ in 0..<200 where !(viewModel.sections.count == 1 && viewModel.sections[0].state != .loading) {
                try await Task.sleep(for: .milliseconds(10))
            }
            host.view.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            shots.append(renderer.image { context in window.layer.render(in: context.cgContext) }.pngData() ?? Data())
        }

        #expect(shots.count == 3)
        #expect(Set(shots).count == 3)
    }

    // Un disque est le seul type cherchable qui n'a pas de « en cours » : sa ligne ne propose
    // que de logger et de garder pour plus tard.
    @Test func anAlbumRowDiffersFromASeriesRow() throws {
        var shots: [Data] = []
        for kind in [MediaKind.album, .series] {
            let row = SearchResultRow(model: SearchResultRowModel(
                candidate: MockProvider.candidate("x:1", kind: kind, title: "Random Access Memories")),
                                      onLog: {}, onWish: {})
            let host = UIHostingController(rootView: row.frame(width: 390))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 120))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.frame = window.bounds
            host.view.layoutIfNeeded()
            let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
            shots.append(renderer.image { context in window.layer.render(in: context.cgContext) }.pngData() ?? Data())
        }

        #expect(Set(shots).count == 2)
    }

    @Test func chipsAndRowsRender() throws {
        let row = SearchResultRowModel(candidate: MockProvider.candidate("ol:work:1", kind: .book, title: "Dune"))
        let view = VStack {
            KindChips(kinds: [.film, .series, .book], selection: .constant(.book))
            SectionHeader(title: "Livres", isLoading: true)
            SearchResultRow(model: row)
        }
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 400))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        #expect(host.sizeThatFits(in: CGSize(width: 390, height: CGFloat.greatestFiniteMagnitude)).height > 100)
    }
}
