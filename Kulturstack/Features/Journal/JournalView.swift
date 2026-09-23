import SwiftData
import SwiftUI

struct JournalView: View {
    @State private var viewModel: JournalViewModel
    @State private var editing: LogReference?
    @State private var deleting: LogReference?
    @State private var showingItem: ItemReference?
    private let services: AppServices
    private let onSearch: () -> Void

    init(services: AppServices, onSearch: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: JournalViewModel(repository: services.logRepository))
        self.services = services
        self.onSearch = onSearch
    }

    #if DEBUG
    var viewModelForTesting: JournalViewModel { viewModel }
    #endif

    var body: some View {
        content
            .navigationTitle(String(localized: "app.name"))
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
            .toolbar {
                NavigationLink {
                    SettingsView(services: services)
                } label: {
                    Label(String(localized: "settings.title"), systemImage: "gearshape")
                }
            }
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
        switch viewModel.presentation {
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
        case .edge(let period, let kind):
            VStack(spacing: 0) {
                filters(total: 0)
                EmptyState(
                    icon: "line.3.horizontal.decrease.circle",
                    title: String(localized: "journal.edge.title"),
                    message: edgeMessage(period: period, kind: kind),
                    action: .init(title: String(localized: "journal.edge.showAll")) { viewModel.showAll() }
                )
            }
        case .loaded(let content):
            VStack(spacing: 0) {
                filters(total: content.total)
                list(content.sections)
            }
        }
    }

    private func filters(total: Int) -> some View {
        let kinds = viewModel.kindCounts
        return VStack(spacing: Spacing.s) {
            Picker(String(localized: "journal.period"), selection: $viewModel.period) {
                ForEach(Period.allCases, id: \.self) { period in
                    Text(period == viewModel.period ? String(localized: "journal.segment \(period.label) \(total)") : period.label)
                        .tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, Spacing.m)
            if !kinds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.s) {
                        Chip(title: String(localized: "chip.all"), isSelected: viewModel.selectedKind == nil) {
                            viewModel.selectedKind = nil
                        }
                        ForEach(kinds, id: \.kind) { entry in
                            Chip(title: String(localized: "journal.chip \(entry.kind.pluralLabel) \(entry.count)"),
                                 isSelected: viewModel.selectedKind == entry.kind) {
                                viewModel.selectedKind = entry.kind
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.m)
                }
            }
        }
        .padding(.vertical, Spacing.s)
    }

    private func edgeMessage(period: Period, kind: MediaKind?) -> String {
        if let kind {
            return String(localized: "journal.edge.message \(kind.pluralLabel.lowercased()) \(period.phrase)")
        }
        return String(localized: "journal.edge.message.all \(period.phrase)")
    }

    private func list(_ sections: [JournalDaySection]) -> some View {
        List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        Button {
                            open(row.tapAction)
                        } label: {
                            JournalRow(model: row)
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
                } header: {
                    SectionHeader(title: section.title)
                        .listRowInsets(EdgeInsets())
                }
            }
        }
        .listStyle(.plain)
        .refreshable { await viewModel.load() }
    }
}
