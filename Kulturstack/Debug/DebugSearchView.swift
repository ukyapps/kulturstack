#if DEBUG
import SwiftUI

struct DebugSearchView: View {
    private let provider: any MetadataProvider
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var searched = false
    @State private var results: [MediaCandidate] = []
    @State private var failure: String?

    init(provider: any MetadataProvider = TMDBProvider(secrets: BundleSecrets(), client: URLSessionHTTPClient())) {
        self.provider = provider
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    TextField(String(localized: "debug.search.placeholder"), text: $query)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .onSubmit { Task { await search() } }
                    Button(String(localized: "debug.search.run")) { Task { await search() } }
                        .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
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
        if let failure {
            EmptyState(
                icon: "exclamationmark.triangle",
                title: String(localized: "debug.search.error.title"),
                message: failure,
                action: .init(title: String(localized: "common.retry")) { Task { await search() } }
            )
        } else if !searched {
            EmptyState(
                icon: "magnifyingglass",
                title: String(localized: "debug.search.initial.title"),
                message: String(localized: "debug.search.initial.message")
            )
        } else if results.isEmpty {
            EmptyState(
                icon: "questionmark.circle",
                title: String(localized: "debug.search.empty.title"),
                message: String(localized: "debug.search.empty.message \(query)")
            )
        } else {
            List(results) { candidate in
                HStack(spacing: Spacing.m) {
                    CoverThumbnail(url: candidate.coverURL, placeholderSymbol: candidate.kind.symbol, width: 32)
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(candidate.title).font(.body)
                        Text(String(localized: "journal.row.subtitle \(candidate.kind.label) \(candidate.year.map(String.init) ?? "—")"))
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        failure = nil
        do {
            results = try await provider.search(text)
        } catch {
            results = []
            failure = error.localizedDescription
        }
        searched = true
    }
}

#Preview {
    DebugSearchView()
}
#endif
