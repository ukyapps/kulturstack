import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct WishlistViewRenderingTests {
    @Test func rendersTheListAndTheEmptyState() async throws {
        for seeded in [true, false] {
            let container = try ModelContainerFactory.inMemory()
            let context = container.mainContext
            if seeded { try DemoSeed(context: context).fill() }
            let view = WishlistView(services: AppServices(context: context))
            let host = UIHostingController(rootView: NavigationStack { view })
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()

            let viewModel = view.viewModelForTesting
            for _ in 0..<200 where viewModel.state == .loading {
                try await Task.sleep(for: .milliseconds(10))
            }
            host.view.layoutIfNeeded()
            if seeded {
                guard case .loaded(let rows) = viewModel.state else {
                    Issue.record("état attendu : loaded")
                    return
                }
                #expect(rows.count == 2)
            } else {
                #expect(viewModel.state == .empty)
            }
        }
    }
}
