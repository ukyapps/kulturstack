import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            JournalView(repository: SwiftDataLogRepository(context: context))
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
            .frame(maxWidth: .infinity)
            .background(.bar)
    }
}
#endif

#Preview {
    RootView().modelContainer(try! ModelContainerFactory.inMemory())
}
