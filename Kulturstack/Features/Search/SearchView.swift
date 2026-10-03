import SwiftData
import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @State private var editing: LogReference?
    @State private var openingEpisodes: MediaCandidate?
    @FocusState private var isSearchFocused: Bool
    private let services: AppServices

    init(useCase: SearchUseCase, services: AppServices, connectivity: (any ConnectivityMonitoring)? = nil,
         debounce: Duration = .milliseconds(300)) {
        let logUseCase = services.logUseCase
        let history = services.logHistory
        _viewModel = State(initialValue: SearchViewModel(
            useCase: useCase,
            logNow: { try logUseCase.logNow($0).id },
            wish: { try logUseCase.wish($0).id },
            lastLogDate: { try history.lastLogDate(for: $0) },
            connectivity: connectivity ?? services.connectivity,
            debounce: debounce))
        self.services = services
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
            .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
                viewModel.refreshLogDates()
            }
            .navigationDestination(for: MediaCandidate.self) { ItemDetailView(subject: .candidate($0), services: services) }
            .navigationDestination(item: $openingEpisodes) { ItemDetailView(subject: .candidate($0), services: services) }
            .safeAreaInset(edge: .top, spacing: 0) {
                if viewModel.isOffline {
                    OfflineBanner()
                }
            }
            .overlay(alignment: .bottom) {
                if let toast = viewModel.toast {
                    Toast(text: toast.title, isError: toast.isError, action: editAction(for: toast))
                        .padding(Spacing.m)
                        .transition(.opacity)
                }
            }
            .animation(.default, value: viewModel.toast)
            // Le + et le ♡ d'un résultat se sentent comme une coche d'épisode : même geste
            // pour la main, même retour (founder, 03/10).
            .sensoryFeedback(.success, trigger: viewModel.feedback)
            .sheet(item: $editing) { LogEditView(logID: $0.id, services: services) }
            .confirmationDialog(String(localized: "search.duplicate.title"), isPresented: isWarningOfDuplicate,
                                titleVisibility: .visible, presenting: viewModel.duplicate) { _ in
                Button(String(localized: "detail.logAgain")) { viewModel.confirmDuplicate() }
                Button(String(localized: "common.cancel"), role: .cancel) { viewModel.cancelDuplicate() }
            } message: { duplicate in
                Text(String(localized: "search.duplicate.message \(duplicate.title) \(duplicate.loggedLabel)"))
            }
    }

    private var isWarningOfDuplicate: Binding<Bool> {
        Binding(get: { viewModel.duplicate != nil }, set: { if !$0 { viewModel.cancelDuplicate() } })
    }

    // Une série ne se logge pas d'un bloc : son bouton mène à sa fiche, qui s'ouvre sur
    // « où j'en suis » et sur ses saisons. Le reste se logge toujours en un geste.
    private func log(_ candidate: MediaCandidate) {
        if candidate.kind.hasEpisodes {
            openingEpisodes = candidate
        } else {
            viewModel.log(candidate)
        }
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
                NavigationLink(value: candidate) {
                    SearchResultRow(model: viewModel.row(for: candidate),
                                    onLog: { log(candidate) },
                                    onWish: { viewModel.wish(candidate) })
                }
                .accessibilityHint(String(localized: "search.row.hint"))
            }
        }
    }
}
