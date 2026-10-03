import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct JournalViewRenderingTests {
    @Test func rendersTheGroupedListAndTheEdgeState() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context).fill()
        let view = JournalView(services: AppServices(context: context))
        let host = UIHostingController(rootView: NavigationStack { view })
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        let viewModel = view.viewModelForTesting
        for _ in 0..<200 where viewModel.state == .loading {
            try await Task.sleep(for: .milliseconds(10))
        }
        viewModel.period = .all
        host.view.layoutIfNeeded()
        guard case .loaded(let content) = viewModel.presentation else {
            Issue.record("présentation attendue : loaded")
            return
        }
        #expect(content.sections.count > 1)
        // Le seed pose 24 logs hors envies pour 22 œuvres : deux d'entre elles en portent
        // deux (un film revu, une série notée puis reprise), et le podcast en porte un.
        // Une œuvre = une ligne — les épisodes cochés n'en sont pas.
        #expect(content.total == 22)
        // Sur l'identité, pas sur le titre : le seed contient un film et un livre qui
        // s'appellent tous les deux « Dune », et ce sont bien deux œuvres.
        let items = content.sections.flatMap(\.rows).compactMap(\.itemID)
        #expect(items.count == 22)
        #expect(Set(items).count == items.count)

        // L'état « filtre sans résultat », qui doit se distinguer du vide et de l'erreur.
        // Les films : le plus récent du seed date de 12 jours, donc jamais dans la semaine
        // en cours quel que soit le jour où le test tourne. (Ce filtre portait sur les
        // podcasts tant que le seed n'en contenait aucun — il est devenu vert pour la
        // mauvaise raison le jour où on en a ajouté un.)
        viewModel.period = .week
        viewModel.selectedKind = .film
        host.view.layoutIfNeeded()
        #expect(viewModel.presentation == .edge(period: .week, kind: .film))

    }
}
