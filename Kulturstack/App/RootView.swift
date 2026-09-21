import SwiftData
import SwiftUI

struct RootView: View {
    enum Tab: Hashable { case journal, search }

    @Environment(\.modelContext) private var context
    @State private var selectedTab = Tab.journal

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                JournalView(repository: SwiftDataLogRepository(context: context)) { selectedTab = .search }
                    #if DEBUG
                    .safeAreaInset(edge: .bottom) { StorageBadge() }
                    #endif
            }
            .tabItem { Label(String(localized: "tab.journal"), systemImage: "books.vertical") }
            .tag(Tab.journal)

            NavigationStack {
                SearchView(useCase: SearchUseCase(providers: providers), logNow: { try logUseCase.logNow($0).id },
                           editUseCase: EditLogUseCase(repository: SwiftDataLogRepository(context: context)))
            }
            .tabItem { Label(String(localized: "tab.search"), systemImage: "magnifyingglass") }
            .tag(Tab.search)
        }
    }

    private var logUseCase: LogUseCase {
        let repository = SwiftDataMediaRepository(context: context)
        return LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository))
    }

    private var providers: [any MetadataProvider] {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        return ProviderRegistry.live(secrets: BundleSecrets(), client: URLSessionHTTPClient(), appVersion: version).providers
    }
}

#if DEBUG
private struct StorageBadge: View {
    @Query private var items: [MediaItem]
    @Query private var logs: [LogEntry]

    var body: some View {
        let version = Int(KulturstackMigrationPlan.current.versionIdentifier.major)
        Text(String(localized: "debug.storage.badge \(version) \(items.count) \(logs.count)"))
            .font(.caption.monospaced())
            .foregroundStyle(Color.textSecondary)
            .padding(.vertical, Spacing.s)
            .frame(maxWidth: .infinity)
            .background(.bar)
    }
}
#endif

#Preview {
    RootView().modelContainer(try! ModelContainerFactory.inMemory())
}
