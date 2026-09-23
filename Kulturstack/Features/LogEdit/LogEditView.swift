import SwiftUI

struct LogEditView: View {
    @State private var viewModel: LogEditViewModel
    @State private var isConfirmingDelete = false
    @Environment(\.dismiss) private var dismiss
    private let services: AppServices
    private let showsItemLink: Bool

    // showsItemLink = false quand la feuille est déjà ouverte depuis la fiche : pas de fiche dans la fiche.
    init(logID: UUID, services: AppServices, showsItemLink: Bool = true) {
        _viewModel = State(initialValue: LogEditViewModel(logID: logID, useCase: services.editUseCase))
        self.services = services
        self.showsItemLink = showsItemLink
    }

    // Un nouveau log : le formulaire s'ouvre vierge, rien n'est écrit avant « Enregistrer ».
    init(target: LogTarget, services: AppServices) {
        _viewModel = State(initialValue: LogEditViewModel(target: target, useCase: services.editUseCase,
                                                          repository: services.mediaRepository,
                                                          logUseCase: services.logUseCase))
        self.services = services
        showsItemLink = false
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(String(localized: "log.edit.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(String(localized: "common.cancel")) { dismiss() }
                    }
                    if viewModel.state == .ready {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "common.save")) {
                                if viewModel.save() { dismiss() }
                            }
                        }
                    }
                }
                .navigationDestination(for: ItemReference.self) { ItemDetailView(itemID: $0.id, services: services) }
        }
        .onAppear { viewModel.load() }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .missing:
            EmptyState(
                icon: "trash.slash",
                title: String(localized: "log.edit.missing.title"),
                message: String(localized: "log.edit.missing.message"),
                action: .init(title: String(localized: "common.close")) { dismiss() }
            )
        case .failed:
            EmptyState(
                icon: "exclamationmark.triangle",
                title: String(localized: "log.edit.error.title"),
                message: String(localized: "log.edit.error.message"),
                action: .init(title: String(localized: "common.retry")) { viewModel.load() }
            )
        case .ready:
            form
        }
    }

    private var form: some View {
        Form {
            Section {
                if showsItemLink, let itemID = viewModel.itemID {
                    NavigationLink(value: ItemReference(id: itemID)) {
                        Text(viewModel.title)
                            .font(.headline)
                    }
                    .accessibilityHint(String(localized: "log.edit.item.hint"))
                } else {
                    Text(viewModel.title)
                        .font(.headline)
                }
            }
            Section {
                DatePicker(String(localized: "log.edit.date"), selection: $viewModel.date, displayedComponents: .date)
                HStack(spacing: Spacing.s) {
                    ForEach(DateShortcut.allCases, id: \.self) { shortcut in
                        Button(shortcut.label) { viewModel.apply(shortcut) }
                            .buttonStyle(.bordered)
                            .font(.subheadline)
                    }
                }
            }
            Section {
                HStack {
                    Text(String(localized: "log.edit.rating"))
                    Spacer()
                    StarRatingPicker(rating: $viewModel.rating)
                }
                Picker(String(localized: "log.edit.status"), selection: $viewModel.status) {
                    ForEach(viewModel.allowedStatuses, id: \.self) { status in
                        Text(status.label).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }
            Section(String(localized: "log.edit.note")) {
                TextField(String(localized: "log.edit.note.placeholder"), text: $viewModel.note, axis: .vertical)
                    .lineLimit(3...8)
            }
            if viewModel.didFail {
                Section {
                    Label(String(localized: "log.edit.failed"), systemImage: "exclamationmark.circle")
                        .foregroundStyle(Color.red)
                }
            }
            if !viewModel.isCreating {
                Section {
                    Button(String(localized: "log.edit.delete"), role: .destructive) { isConfirmingDelete = true }
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .confirmationDialog(String(localized: "log.edit.delete.confirm.title"), isPresented: $isConfirmingDelete,
                            titleVisibility: .visible) {
            Button(String(localized: "common.delete"), role: .destructive) {
                if viewModel.delete() { dismiss() }
            }
        } message: {
            Text(String(localized: "log.edit.delete.confirm.message"))
        }
    }
}
