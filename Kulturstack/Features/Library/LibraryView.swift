import SwiftData
import SwiftUI

struct LibraryView: View {
    @State private var viewModel: LibraryViewModel
    @State private var showingItem: ItemReference?
    private let services: AppServices
    private let onSearch: () -> Void

    init(services: AppServices, onSearch: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: LibraryViewModel(repository: services.mediaRepository))
        self.services = services
        self.onSearch = onSearch
    }

    #if DEBUG
    var viewModelForTesting: LibraryViewModel { viewModel }
    #endif

    var body: some View {
        content
            .navigationTitle(String(localized: "tab.library"))
            .task { await viewModel.load() }
            .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
                Task { await viewModel.load() }
            }
            .navigationDestination(item: $showingItem) { ItemDetailView(itemID: $0.id, services: services) }
            .alert(String(localized: "library.remove.failed"), isPresented: $viewModel.didFailToRemove) {}
            .sensoryFeedback(.success, trigger: viewModel.feedback)
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            EmptyState(
                icon: "books.vertical",
                title: String(localized: "library.empty.title"),
                message: String(localized: "library.empty.message"),
                action: .init(title: String(localized: "journal.empty.cta"), handler: onSearch)
            )
        case .failed:
            EmptyState(
                icon: "exclamationmark.triangle",
                title: String(localized: "library.error.title"),
                message: String(localized: "journal.error.message"),
                action: .init(title: String(localized: "common.retry")) {
                    Task { await viewModel.load() }
                }
            )
        case .loaded(let rows):
            List(rows) { row in
                Button { showingItem = ItemReference(id: row.id) } label: {
                    LibraryRow(model: row)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing) {
                    Button(String(localized: "library.remove"), systemImage: "books.vertical.slash", role: .destructive) {
                        Task { await viewModel.remove(itemID: row.id) }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.load() }
        }
    }
}
