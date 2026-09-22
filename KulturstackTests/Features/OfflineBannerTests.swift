import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct OfflineBannerTests {
    @Test func searchShowsTheOfflineBannerOnlyWhenOffline() async throws {
        let container = try ModelContainerFactory.inMemory()
        let services = AppServices(context: container.mainContext)
        let monitor = StubConnectivity(isOnline: false)
        let view = SearchView(useCase: SearchUseCase(providers: []), services: services, connectivity: monitor, debounce: .zero)
        let host = UIHostingController(rootView: NavigationStack { view })
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        #expect(view.viewModelForTesting.isOffline)

        monitor.isOnline = true
        host.view.layoutIfNeeded()
        #expect(view.viewModelForTesting.isOffline == false)
    }
}

@MainActor @Observable
final class StubConnectivity: ConnectivityMonitoring {
    var isOnline: Bool
    init(isOnline: Bool) { self.isOnline = isOnline }
}
