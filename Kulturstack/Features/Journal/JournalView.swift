import SwiftUI

struct JournalView: View {
    @State private var viewModel: JournalViewModel

    init(repository: any LogRepository) {
        _viewModel = State(initialValue: JournalViewModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle(String(localized: "app.name"))
            .task { await viewModel.load() }
            #if DEBUG
            .toolbar { DebugMenu { await viewModel.load() } }
            #endif
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .empty:
            EmptyState(
                icon: "books.vertical",
                title: String(localized: "journal.empty.title"),
                message: String(localized: "journal.empty.message")
            )
        case .failed:
            EmptyState(
                icon: "exclamationmark.triangle",
                title: String(localized: "journal.error.title"),
                message: String(localized: "journal.error.message"),
                action: .init(title: String(localized: "common.retry")) {
                    Task { await viewModel.load() }
                }
            )
        case .loaded(let rows):
            List(rows) { JournalRow(model: $0) }
                .listStyle(.plain)
                .refreshable { await viewModel.load() }
        }
    }
}
