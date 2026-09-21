import SwiftUI

struct LogEditView: View {
    @State private var viewModel: LogEditViewModel
    @State private var isConfirmingDelete = false
    @Environment(\.dismiss) private var dismiss

    init(logID: UUID, useCase: EditLogUseCase) {
        _viewModel = State(initialValue: LogEditViewModel(logID: logID, useCase: useCase))
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
                Text(viewModel.title)
                    .font(.headline)
            }
            Section {
                DatePicker(String(localized: "log.edit.date"), selection: $viewModel.date)
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
            Section {
                Button(String(localized: "log.edit.delete"), role: .destructive) { isConfirmingDelete = true }
                    .frame(maxWidth: .infinity)
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
