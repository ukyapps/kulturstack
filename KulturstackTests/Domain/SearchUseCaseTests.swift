import Foundation
import Testing
@testable import Kulturstack

struct SearchUseCaseTests {
    private let film = MockProvider.candidate("tmdb:movie:1", kind: .film, title: "Dune")
    private let book = MockProvider.candidate("ol:work:1", kind: .book, title: "Dune")

    private func collect(_ stream: AsyncStream<SearchSection>) async -> [SearchSection] {
        var sections: [SearchSection] = []
        for await section in stream { sections.append(section) }
        return sections
    }

    @Test func startsWithEveryFamilyLoadingThenSettles() async {
        let useCase = SearchUseCase(providers: [
            MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([film])),
            MockProvider(id: "openlibrary", kinds: [.book], result: .success([book])),
        ])

        let sections = await collect(useCase.search("dune"))

        #expect(sections.prefix(2).map(\.state) == [.loading, .loading])
        #expect(sections.prefix(2).map(\.family) == [.screen, .books])
        #expect(sections.count == 4)
        #expect(sections.last(where: { $0.family == .screen })?.state == .loaded([film]))
        #expect(sections.last(where: { $0.family == .books })?.state == .loaded([book]))
    }

    @Test func aFailingProviderOnlyFailsItsOwnSection() async {
        let useCase = SearchUseCase(providers: [
            MockProvider(id: "tmdb", kinds: [.film], result: .success([film])),
            MockProvider(id: "openlibrary", kinds: [.book], result: .failure(HTTPError.status(503))),
        ])

        let sections = await collect(useCase.search("dune"))

        #expect(sections.last(where: { $0.family == .screen })?.state == .loaded([film]))
        guard case .failed = sections.last(where: { $0.family == .books })?.state else {
            Issue.record("la section Livres devrait être en erreur")
            return
        }
    }

    @Test func sectionsArriveIndependentlyFastestFirst() async {
        let useCase = SearchUseCase(providers: [
            MockProvider(id: "slow", kinds: [.book], delay: .milliseconds(300), result: .success([book])),
            MockProvider(id: "fast", kinds: [.film], delay: .zero, result: .success([film])),
        ])

        let settled = await collect(useCase.search("dune")).filter { $0.state != .loading }

        #expect(settled.map(\.family) == [.screen, .books])
    }

    @Test func cancellingTheConsumerCancelsProvidersAndYieldsNothingStale() async throws {
        let slow = MockProvider(id: "slow", kinds: [.film], delay: .seconds(2), result: .success([film]))
        let useCase = SearchUseCase(providers: [slow])

        let consumer = Task { await collect(useCase.search("du")) }
        try await Task.sleep(for: .milliseconds(50))
        consumer.cancel()
        let sections = await consumer.value

        #expect(sections.allSatisfy { $0.state == .loading })
        try await Task.sleep(for: .milliseconds(50))
        #expect(slow.wasCancelled)
    }

    @Test func aProviderSlowerThanTheTimeoutFails() async {
        let slow = MockProvider(id: "slow", kinds: [.film], delay: .seconds(2), result: .success([film]))
        let useCase = SearchUseCase(providers: [slow], timeout: .milliseconds(50))

        let sections = await collect(useCase.search("dune"))

        #expect(sections.last?.state == .failed(reason: SearchError.timeout.localizedDescription))
    }

    @Test func noResultsGivesAnEmptySection() async {
        let useCase = SearchUseCase(providers: [MockProvider(id: "tmdb", kinds: [.film], result: .success([]))])

        let sections = await collect(useCase.search("zzz"))

        #expect(sections.last?.state == .empty)
    }

    @Test func retryOnlyAsksTheProvidersOfThatFamily() async {
        let tmdb = MockProvider(id: "tmdb", kinds: [.film], result: .success([film]))
        let openLibrary = MockProvider(id: "openlibrary", kinds: [.book], result: .success([book]))
        let useCase = SearchUseCase(providers: [tmdb, openLibrary])

        let sections = await collect(useCase.retry("dune", family: .books))

        #expect(sections.map(\.family) == [.books, .books])
        #expect(sections.last?.state == .loaded([book]))
        #expect(tmdb.calls.isEmpty)
        #expect(openLibrary.calls == ["dune"])
    }

    @Test func familiesFollowTheCanonicalOrderWhateverTheProviderOrder() {
        let useCase = SearchUseCase(providers: [
            MockProvider(id: "openlibrary", kinds: [.book], result: .success([])),
            MockProvider(id: "tmdb", kinds: [.film, .series], result: .success([])),
        ])

        #expect(useCase.families == [.screen, .books])
    }
}
