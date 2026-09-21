import SwiftData
import SwiftUI

struct JournalView: View {
    @State private var viewModel: JournalViewModel
    @State private var editing: LogReference?
    @State private var deleting: LogReference?
    private let editUseCase: EditLogUseCase
    private let onSearch: () -> Void

    init(repository: any LogRepository, onSearch: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: JournalViewModel(repository: repository))
        editUseCase = EditLogUseCase(repository: repository)
        self.onSearch = onSearch
    }

    var body: some View {
        content
            .navigationTitle(String(localized: "app.name"))
            .task { await viewModel.load() }
            .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
                Task { await viewModel.load() }
            }
            .sheet(item: $editing) { LogEditView(logID: $0.id, useCase: editUseCase) }
            .confirmationDialog(String(localized: "log.edit.delete.confirm.title"), isPresented: isDeleting,
                                titleVisibility: .visible, presenting: deleting) { reference in
                Button(String(localized: "common.delete"), role: .destructive) {
                    Task { await viewModel.delete(id: reference.id) }
                }
            } message: { _ in
                Text(String(localized: "log.edit.delete.confirm.message"))
            }
            .alert(String(localized: "journal.delete.failed"), isPresented: $viewModel.didFailToDelete) {}
            #if DEBUG
            .toolbar { DebugMenu { await viewModel.load() } }
            #endif
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
                icon: "books.vertical",
                title: String(localized: "journal.empty.title"),
                message: String(localized: "journal.empty.message"),
                action: .init(title: String(localized: "journal.empty.cta"), handler: onSearch)
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
            List(rows) { row in
                JournalRow(model: row)
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
