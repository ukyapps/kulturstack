import Foundation

struct SearchUseCase: Sendable {
    let providers: [any MetadataProvider]
    let timeout: Duration
    let families: [SearchFamily]

    init(providers: [any MetadataProvider], timeout: Duration = .seconds(8)) {
        self.providers = providers
        self.timeout = timeout
        let covered = Set(providers.map(Self.family(of:)))
        families = SearchFamily.allCases.filter(covered.contains)
    }

    func search(_ query: String) -> AsyncStream<SearchSection> {
        AsyncStream { continuation in
            let task = Task {
                for family in families {
                    continuation.yield(SearchSection(family: family, state: .loading))
                }
                await withTaskGroup(of: SearchSection.self) { group in
                    for provider in providers {
                        group.addTask { await Self.section(from: provider, query: query, timeout: timeout) }
                    }
                    for await section in group where !Task.isCancelled {
                        continuation.yield(section)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func retry(_ query: String, family: SearchFamily) -> AsyncStream<SearchSection> {
        SearchUseCase(providers: providers.filter { Self.family(of: $0) == family }, timeout: timeout).search(query)
    }

    // Un provider couvre une seule famille en T1 (TMDB → écran, OpenLibrary → livres).
    static func family(of provider: any MetadataProvider) -> SearchFamily {
        SearchFamily.allCases.first { family in provider.supportedKinds.contains { $0.searchFamily == family } } ?? .screen
    }

    private static func section(from provider: any MetadataProvider, query: String, timeout: Duration) async -> SearchSection {
        let family = family(of: provider)
        do {
            let candidates = try await withTimeout(timeout) { try await provider.search(query) }
            return SearchSection(family: family, state: candidates.isEmpty ? .empty : .loaded(candidates))
        } catch {
            return SearchSection(family: family, state: .failed(reason: error.localizedDescription))
        }
    }

    private static func withTimeout<T: Sendable>(_ timeout: Duration,
                                                 _ operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw SearchError.timeout
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }
}
