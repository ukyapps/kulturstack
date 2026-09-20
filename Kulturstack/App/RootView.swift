import SwiftData
import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            EmptyState(
                icon: "books.vertical",
                title: String(localized: "root.empty.title"),
                message: String(localized: "root.empty.message")
            )
            .navigationTitle(String(localized: "app.name"))
            #if DEBUG
            .safeAreaInset(edge: .bottom) { StorageBadge() }
            #endif
        }
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
    }
}
#endif

#Preview {
    RootView().modelContainer(try! ModelContainerFactory.inMemory())
}
