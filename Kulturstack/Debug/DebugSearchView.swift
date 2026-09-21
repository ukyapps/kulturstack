#if DEBUG
import SwiftUI

struct DebugSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var simulateOutage = false
    @State private var sections: [SearchSection] = []
    @State private var searchTask: Task<Void, Never>?

    private var useCase: SearchUseCase {
        let client = URLSessionHTTPClient()
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        var providers = ProviderRegistry.live(secrets: BundleSecrets(), client: client, appVersion: version).providers
        if simulateOutage {
            providers = providers.map { $0.id == "openlibrary" ? FailingProvider(id: $0.id, supportedKinds: $0.supportedKinds) : $0 }
        }
        return SearchUseCase(providers: providers)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: Spacing.s) {
                    HStack {
                        TextField(String(localized: "debug.search.placeholder"), text: $query)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .onSubmit(search)
                        Button(String(localized: "debug.search.run"), action: search)
                            .disabled(trimmedQuery.isEmpty)
                    }
                    Toggle(String(localized: "debug.search.outage"), isOn: $simulateOutage)
                        .font(.caption)
                        .onChange(of: simulateOutage) { search() }
                }
                .padding(Spacing.m)
                content
            }
            .navigationTitle(String(localized: "debug.search.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.close")) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder private var content: some View {
        if sections.isEmpty {
            EmptyState(
                icon: "magnifyingglass",
                title: String(localized: "debug.search.initial.title"),
                message: String(localized: "debug.search.initial.message")
            )
        } else {
            List {
                ForEach(sections) { section in
                    Section(section.family.label) {
                        sectionBody(section)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    @ViewBuilder private func sectionBody(_ section: SearchSection) -> some View {
        switch section.state {
        case .loading:
            ProgressView()
        case .empty:
            Text(String(localized: "debug.search.empty.title"))
                .foregroundStyle(Color.textSecondary)
        case .failed(let reason):
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(String(localized: "search.section.failed \(section.family.label)"))
                Text(reason).font(.caption).foregroundStyle(Color.textSecondary)
                Button(String(localized: "common.retry")) { retry(section.family) }
            }
        case .loaded(let candidates):
            ForEach(candidates.prefix(5)) { candidate in
                HStack(spacing: Spacing.m) {
                    CoverThumbnail(url: candidate.coverURL, placeholderSymbol: candidate.kind.symbol, width: 32)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(candidate.title).font(.body)
                        Text(String(localized: "journal.row.subtitle \(candidate.kind.label) \(candidate.year.map(String.init) ?? candidate.creators.first ?? "—")"))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
        }
    }

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespaces) }

    private func search() {
        guard !trimmedQuery.isEmpty else { return }
        run(useCase.search(trimmedQuery))
    }

    private func retry(_ family: SearchFamily) {
        run(useCase.retry(trimmedQuery, family: family))
    }

    private func run(_ stream: AsyncStream<SearchSection>) {
        searchTask?.cancel()
        searchTask = Task {
            for await section in stream {
                if let index = sections.firstIndex(where: { $0.family == section.family }) {
                    sections[index] = section
                } else {
                    sections.append(section)
                    sections.sort { SearchFamily.allCases.firstIndex(of: $0.family)! < SearchFamily.allCases.firstIndex(of: $1.family)! }
                }
            }
        }
    }
}

private struct FailingProvider: MetadataProvider {
    let id: String
    let supportedKinds: Set<MediaKind>

    func search(_ query: String) async throws -> [MediaCandidate] {
        try await Task.sleep(for: .milliseconds(400))
        throw HTTPError.status(503)
    }
}

#Preview {
    DebugSearchView()
}
#endif
