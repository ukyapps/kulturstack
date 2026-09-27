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
