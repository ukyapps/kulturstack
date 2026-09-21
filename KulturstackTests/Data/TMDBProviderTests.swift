import Foundation
import Testing
@testable import Kulturstack

struct TMDBProviderTests {
    private func makeProvider(client: StubHTTPClient, token: String? = "tok") -> TMDBProvider {
        let secrets = MockSecrets(values: token.map { [.tmdbReadToken: $0] } ?? [:])
        return TMDBProvider(secrets: secrets, client: client, language: "fr-FR")
    }

    @Test func parsesFixtureIntoFilmsAndSeriesOnly() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-search-multi-dune"))

        let candidates = try await makeProvider(client: client).search("dune")

        #expect(candidates.count == 13)
        #expect(candidates.filter { $0.kind == .film }.count == 8)
        #expect(candidates.filter { $0.kind == .series }.count == 5)
        #expect(candidates.allSatisfy { $0.providerID == "tmdb" })
    }

    @Test func movieBecomesAFilmCandidateWithTMDBKey() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-search-multi-dune"))

        let candidates = try await makeProvider(client: client).search("dune")
        let dune = try #require(candidates.first { $0.id == "tmdb:movie:438631" })

        #expect(dune.kind == .film)
        #expect(dune.title == "Dune")
        #expect(dune.originalTitle == "Dune")
        #expect(dune.year == 2021)
        #expect(dune.coverURL == URL(string: "https://image.tmdb.org/t/p/w342/qpyaW4xUPeIiYA5ckg5zAZFHvsb.jpg"))
        #expect(dune.summary?.hasPrefix("L'histoire de Paul Atreides") == true)
        #expect(dune.externalKeys == ["tmdb:movie:438631"])
        #expect(dune.details is FilmDetails)
    }

    @Test func tvShowBecomesASeriesCandidateWithTMDBKey() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-search-multi-dune"))

        let candidates = try await makeProvider(client: client).search("dune")
        let prophecy = try #require(candidates.first { $0.id == "tmdb:tv:90228" })

        #expect(prophecy.kind == .series)
        #expect(prophecy.title == "Dune : Prophecy")
        #expect(prophecy.year == 2024)
        #expect(prophecy.details is SeriesDetails)
    }

    @Test func candidatesKeepTheProviderOrder() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-search-multi-dune"))

        let ids = try await makeProvider(client: client).search("dune").prefix(3).map(\.id)

        #expect(ids == ["tmdb:movie:438631", "tmdb:tv:90228", "tmdb:movie:693134"])
    }

    @Test func requestCarriesQueryLanguageAndBearerToken() async throws {
        let client = StubHTTPClient(data: Data(#"{"page":1,"results":[]}"#.utf8))

        _ = try await makeProvider(client: client).search("dune part two")
        let call = try #require(client.calls.first)
        let components = try #require(URLComponents(url: call.url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(components.host == "api.themoviedb.org")
        #expect(components.path == "/3/search/multi")
        #expect(query["query"] == "dune part two")
        #expect(query["language"] == "fr-FR")
        #expect(query["include_adult"] == "false")
        #expect(call.headers["Authorization"] == "Bearer tok")
    }

    @Test func missingTokenFailsBeforeAnyNetworkCall() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-search-multi-dune"))

        await #expect(throws: SecretsError.missing(.tmdbReadToken)) {
            try await makeProvider(client: client, token: nil).search("dune")
        }
        #expect(client.calls.isEmpty)
    }

    @Test func httpFailurePropagates() async {
        let client = StubHTTPClient(error: HTTPError.status(401))

        await #expect(throws: HTTPError.status(401)) {
            try await makeProvider(client: client).search("dune")
        }
    }

    @Test func malformedJSONIsAnError() async {
        let client = StubHTTPClient(data: Data("not json".utf8))

        await #expect(throws: (any Error).self) {
            try await makeProvider(client: client).search("dune")
        }
    }

    @Test(arguments: [("fr_FR", "fr-FR"), ("en_US", "en-US"), ("en_GB", "en-US"), ("de_DE", "en-US")])
    func languageFollowsTheLocale(identifier: String, expected: String) {
        #expect(TMDBProvider.language(for: Locale(identifier: identifier)) == expected)
    }

    @Test func declaresFilmsAndSeries() {
        let provider = makeProvider(client: StubHTTPClient(data: Data()))
        #expect(provider.id == "tmdb")
        #expect(provider.supportedKinds == [.film, .series])
    }
}
