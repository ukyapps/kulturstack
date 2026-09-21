import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @State private var editing: LogReference?
    @FocusState private var isSearchFocused: Bool
    private let editUseCase: EditLogUseCase

    init(useCase: SearchUseCase, logNow: @escaping (MediaCandidate) throws -> UUID, editUseCase: EditLogUseCase,
         debounce: Duration = .milliseconds(300)) {
        _viewModel = State(initialValue: SearchViewModel(useCase: useCase, logNow: logNow, debounce: debounce))
        self.editUseCase = editUseCase
    }

    #if DEBUG
    var viewModelForTesting: SearchViewModel { viewModel }
    #endif

    var body: some View {
        content
            .navigationTitle(String(localized: "tab.search"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: String(localized: "search.placeholder"))
            .searchFocused($isSearchFocused)
            .autocorrectionDisabled()
            .onAppear { isSearchFocused = true }
            .overlay(alignment: .bottom) {
                if let toast = viewModel.toast {
                    Toast(text: toast.title, isError: toast.isError, action: editAction(for: toast))
                        .padding(Spacing.m)
                        .transition(.opacity)
                }
            }
            .animation(.default, value: viewModel.toast)
            .sheet(item: $editing) { LogEditView(logID: $0.id, useCase: editUseCase) }
    }

    private func editAction(for toast: SearchViewModel.Toast) -> Toast.Action? {
        guard let logID = toast.logID else { return nil }
        return .init(title: String(localized: "common.edit")) { editing = LogReference(id: logID) }
    }

    @ViewBuilder private var content: some View {
        switch viewModel.presentation {
        case .idle:
            EmptyState(
                icon: "magnifyingglass",
                title: String(localized: "search.initial.title"),
                message: String(localized: "search.initial.message")
            )
        case .noResults(let query):
            EmptyState(
                icon: "questionmark.circle",
                title: String(localized: "search.noResults.title"),
                message: String(localized: "search.noResults.message \(query)")
            )
        case .noResultsForKind(let kind):
            VStack(spacing: 0) {
                KindChips(kinds: viewModel.availableKinds, selection: $viewModel.selectedKind)
                EmptyState(
                    icon: "line.3.horizontal.decrease.circle",
                    title: String(localized: "search.filter.noResults.title"),
                    message: String(localized: "search.filter.noResults.message \(kind.pluralLabel)"),
                    action: .init(title: String(localized: "search.filter.showAll")) { viewModel.selectedKind = nil }
                )
            }
        case .sections(let sections):
            VStack(spacing: 0) {
                KindChips(kinds: viewModel.availableKinds, selection: $viewModel.selectedKind)
                List {
                    ForEach(sections) { section in
                        Section {
                            sectionBody(section)
                        } header: {
                            SectionHeader(title: section.family.label, isLoading: section.state == .loading)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.immediately)
            }
        }
    }

    @ViewBuilder private func sectionBody(_ section: SearchSection) -> some View {
        switch section.state {
        case .loading:
            EmptyView()
        case .empty:
            Text(String(localized: "search.section.empty"))
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        case .failed:
            HStack {
                Text(String(localized: "search.section.failed \(section.family.label)"))
                    .font(.subheadline)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Button(String(localized: "common.retry")) { viewModel.retry(section.family) }
                    .font(.subheadline.weight(.semibold))
            }
        case .loaded(let candidates):
            ForEach(candidates) { candidate in
                Button {
                    viewModel.log(candidate)
                } label: {
                    SearchResultRow(model: SearchResultRowModel(candidate: candidate))
                }
                .buttonStyle(.plain)
                .accessibilityHint(String(localized: "search.row.hint"))
            }
        }
    }
}
