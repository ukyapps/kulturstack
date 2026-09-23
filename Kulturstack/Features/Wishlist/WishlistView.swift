import SwiftData
import SwiftUI

struct WishlistView: View {
    @State private var viewModel: WishlistViewModel
    @State private var editing: LogReference?
    @State private var deleting: LogReference?
    @State private var showingItem: ItemReference?
    private let services: AppServices
    private let onSearch: () -> Void

    init(services: AppServices, onSearch: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: WishlistViewModel(repository: services.logRepository, logUseCase: services.logUseCase))
        self.services = services
        self.onSearch = onSearch
    }

    #if DEBUG
    var viewModelForTesting: WishlistViewModel { viewModel }
    #endif

    var body: some View {
        content
            .navigationTitle(String(localized: "tab.wishlist"))
            .task { await viewModel.load() }
            .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
                Task { await viewModel.load() }
            }
            .sheet(item: $editing) { LogEditView(logID: $0.id, services: services) }
            .navigationDestination(item: $showingItem) { ItemDetailView(itemID: $0.id, services: services) }
            .confirmationDialog(String(localized: "log.edit.delete.confirm.title"), isPresented: isDeleting,
                                titleVisibility: .visible, presenting: deleting) { reference in
                Button(String(localized: "common.delete"), role: .destructive) {
                    Task { await viewModel.delete(id: reference.id) }
                }
            } message: { _ in
                Text(String(localized: "log.edit.delete.confirm.message"))
            }
            .alert(String(localized: "journal.delete.failed"), isPresented: $viewModel.didFailToDelete) {}
            .alert(String(localized: "wishlist.seen.failed"), isPresented: $viewModel.didFailToMarkSeen) {}
    }

    private func open(_ action: JournalRowTap) {
        switch action {
        case .showItem(let itemID): showingItem = ItemReference(id: itemID)
        case .edit(let logID): editing = LogReference(id: logID)
        }
    }

    private var isDeleting: Binding<Bool> {
        Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            EmptyState(
                icon: "heart",
                title: String(localized: "wishlist.empty.title"),
                message: String(localized: "wishlist.empty.message"),
                action: .init(title: String(localized: "journal.empty.cta"), handler: onSearch)
            )
        case .failed:
            EmptyState(
                icon: "exclamationmark.triangle",
                title: String(localized: "wishlist.error.title"),
                message: String(localized: "journal.error.message"),
                action: .init(title: String(localized: "common.retry")) {
                    Task { await viewModel.load() }
                }
            )
        case .loaded(let rows):
            List(rows) { row in
                Button {
                    open(row.tapAction)
                } label: {
                    WishRow(model: row) { Task { await viewModel.markSeen(id: row.id) } }
                }
                .buttonStyle(.plain)
                .accessibilityHint(row.tapAction.hint)
                .contextMenu {
                    Button(String(localized: "common.edit"), systemImage: "pencil") {
                        editing = LogReference(id: row.id)
                    }
                    Button(String(localized: "common.delete"), systemImage: "trash", role: .destructive) {
                        deleting = LogReference(id: row.id)
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await viewModel.load() }
        }
    }
}
