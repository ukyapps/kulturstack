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
        #expect(content.total == 23)

        viewModel.period = .week
        viewModel.selectedKind = .podcast
        host.view.layoutIfNeeded()
        #expect(viewModel.presentation == .edge(period: .week, kind: .podcast))

    }
}
