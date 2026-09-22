import SwiftData
import SwiftUI

struct RootView: View {
    enum Tab: Hashable { case journal, wishlist, search }

    @Environment(\.modelContext) private var context
    @State private var selectedTab = Tab.journal

    var body: some View {
        let registry = providerRegistry
        let services = AppServices(context: context, detailsProviders: registry.detailsProviders)
        TabView(selection: $selectedTab) {
            NavigationStack {
                JournalView(services: services) { selectedTab = .search }
            }
            .tabItem { Label(String(localized: "tab.journal"), systemImage: "books.vertical") }
            .tag(Tab.journal)

            NavigationStack {
                WishlistView(services: services) { selectedTab = .search }
            }
            .tabItem { Label(String(localized: "tab.wishlist"), systemImage: "heart") }
            .tag(Tab.wishlist)

            NavigationStack {
                SearchView(useCase: SearchUseCase(providers: registry.providers), services: services)
            }
            .tabItem { Label(String(localized: "tab.search"), systemImage: "magnifyingglass") }
            .tag(Tab.search)
        }
    }

    private var providerRegistry: ProviderRegistry {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        return ProviderRegistry.live(secrets: BundleSecrets(), client: URLSessionHTTPClient(), appVersion: version)
    }
}

#Preview {
    RootView().modelContainer(try! ModelContainerFactory.inMemory())
}
