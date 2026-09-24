#if DEBUG
import SwiftData
import SwiftUI

// Le menu DEBUG vit dans Réglages, compilé hors Release ; le seed reste idempotent.
struct DebugSection: View {
    @Environment(\.modelContext) private var context
    @Query private var items: [MediaItem]
    @Query private var logs: [LogEntry]
    @Query private var episodes: [Episode]
    @State private var showsSearch = false

    var body: some View {
        Section {
            Button(String(localized: "debug.seed.fill"), systemImage: "tray.full") {
                run { try DemoSeed(context: context).fill() }
            }
            Button(String(localized: "debug.seed.wipe"), systemImage: "trash", role: .destructive) {
                run { try DemoSeed(context: context).wipe() }
            }
            Button(String(localized: "debug.search.open"), systemImage: "magnifyingglass") { showsSearch = true }
        } header: {
            Text(String(localized: "debug.menu"))
        } footer: {
            let version = Int(KulturstackMigrationPlan.current.versionIdentifier.major)
            Text(String(localized: "debug.storage.badge \(version) \(items.count) \(logs.count) \(episodes.count)"))
                .font(.caption.monospaced())
        }
        .sheet(isPresented: $showsSearch) { DebugSearchView() }
    }

    private func run(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            assertionFailure("Seed DEBUG : \(error)")
        }
    }
}
#endif
