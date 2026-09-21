#if DEBUG
import SwiftData
import SwiftUI

struct DebugMenu: View {
    @Environment(\.modelContext) private var context
    @State private var showsSearch = false
    let onChange: () async -> Void

    var body: some View {
        Menu {
            Button(String(localized: "debug.seed.fill"), systemImage: "tray.full") {
                run { try DemoSeed(context: context).fill() }
            }
            Button(String(localized: "debug.seed.wipe"), systemImage: "trash", role: .destructive) {
                run { try DemoSeed(context: context).wipe() }
            }
            Divider()
            Button(String(localized: "debug.search.open"), systemImage: "magnifyingglass") {
                showsSearch = true
            }
        } label: {
            Label(String(localized: "debug.menu"), systemImage: "ladybug")
        }
        .sheet(isPresented: $showsSearch) { DebugSearchView() }
    }

    private func run(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            assertionFailure("Seed DEBUG : \(error)")
        }
        Task { await onChange() }
    }
}
#endif
