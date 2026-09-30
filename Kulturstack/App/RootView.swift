import SwiftData
import SwiftUI

struct RootView: View {
    enum Tab: Hashable { case journal, wishlist, inProgress, search }

    @Environment(\.modelContext) private var context
    @State private var selectedTab = Tab.journal

    var body: some View {
        let registry = providerRegistry
        let services = AppServices(context: context, detailsProviders: registry.detailsProviders,
                                   episodeProviders: registry.episodeProviders)
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
                InProgressView(services: services) { selectedTab = .search }
            }
            .tabItem { Label(String(localized: "tab.inProgress"), systemImage: "play.circle") }
            .tag(Tab.inProgress)

            NavigationStack {
                SearchView(useCase: SearchUseCase(providers: registry.providers), services: services)
            }
            .tabItem { Label(String(localized: "tab.search"), systemImage: "magnifyingglass") }
            .tag(Tab.search)
        }
        // Au lancement, on redemande à la source combien de saisons comptent les séries
        // suivies : c'est ce qui fait revenir dans « En cours » celle dont une saison est
        // sortie, sans avoir à ouvrir sa fiche. Une fois par jour, en tâche de fond, et une
        // panne ne se voit pas — l'app s'ouvre pareil.
        .task { await services.refreshSeasonsUseCase.run() }
    }

    private var providerRegistry: ProviderRegistry {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        return ProviderRegistry.live(secrets: BundleSecrets(), client: URLSessionHTTPClient(), appVersion: version)
    }
}

#Preview {
    RootView().modelContainer(try! ModelContainerFactory.inMemory())
}
