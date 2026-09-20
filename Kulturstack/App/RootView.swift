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
        }
    }
}

#Preview {
    RootView()
}
