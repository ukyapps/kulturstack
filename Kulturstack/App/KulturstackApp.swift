import SwiftData
import SwiftUI

@main
struct KulturstackApp: App {
    private let store: Result<ModelContainer, Error> = Result { try ModelContainerFactory.production() }

    var body: some Scene {
        WindowGroup {
            switch store {
            case .success(let container):
                RootView().modelContainer(container)
            case .failure:
                EmptyState(
                    icon: "externaldrive.badge.exclamationmark",
                    title: String(localized: "storage.error.title"),
                    message: String(localized: "storage.error.message")
                )
            }
        }
    }
}
