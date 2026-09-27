import SwiftData
import SwiftUI

struct InProgressView: View {
    @State private var viewModel: InProgressViewModel
    @State private var showingItem: ItemReference?
    private let services: AppServices
    private let onSearch: () -> Void

    init(services: AppServices, onSearch: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: InProgressViewModel(
            useCase: services.inProgressUseCase, repository: services.mediaRepository,
            episodes: services.episodeUseCase, status: services.watchStatusUseCase))
        self.services = services
        self.onSearch = onSearch
    }

    var body: some View {
        content
            .navigationTitle(String(localized: "tab.inProgress"))
            .task { await viewModel.load() }
            .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
                Task { await viewModel.load() }
            }
            .navigationDestination(item: $showingItem) { ItemDetailView(itemID: $0.id, services: services) }
            .alert(String(localized: "inprogress.advance.failed"), isPresented: $viewModel.didFailToAdvance) {}
    }

    // Cet onglet sera vu vide souvent : son état vide est un écran d'accueil, pas un trou.
    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            EmptyState(
                icon: "play.circle",
                title: String(localized: "inprogress.empty.title"),
                message: String(localized: "inprogress.empty.message"),
                action: .init(title: String(localized: "journal.empty.cta"), handler: onSearch)
            )
        case .failed:
            EmptyState(
                icon: "exclamationmark.triangle",
                title: String(localized: "inprogress.error.title"),
                message: String(localized: "journal.error.message"),
                action: .init(title: String(localized: "common.retry")) { Task { await viewModel.load() } }
            )
        case .loaded(let rows):
            List(rows) { row in
                Button {
                    showingItem = ItemReference(id: row.itemID)
                } label: {
                    InProgressRow(model: row,
                                  onAdvance: { Task { await viewModel.advance(row) } },
                                  onFinish: { Task { await viewModel.finish(row) } })
                }
                .buttonStyle(.plain)
                .accessibilityHint(String(localized: "inprogress.row.hint"))
            }
            .listStyle(.plain)
            .refreshable { await viewModel.load() }
        }
    }
}
