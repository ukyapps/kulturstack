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

    // Retour du 23/09 : « si je mets wes anderson, je n'ai pas tous les films de Wes Anderson ».
    @Test func aPersonSearchBringsBackTheirWorksMostPopularFirst() async throws {
        let client = try personClient()

        let candidates = try await makeProvider(client: client).search("wes anderson")

        #expect(candidates.map(\.id) == ["tmdb:movie:120467", "tmdb:movie:399170", "tmdb:movie:83666",
                                         "tmdb:movie:536437", "tmdb:tv:4444", "tmdb:movie:999999"])
        #expect(candidates.first?.title == "The Grand Budapest Hotel")
        #expect(candidates.first?.year == 2014)
    }

    @Test func theWorksOfAPersonAreAskedOnceInTheRightLanguage() async throws {
        let client = try personClient()

        _ = try await makeProvider(client: client).search("wes anderson")

        #expect(client.calls.count == 2)
        let credits = try #require(URLComponents(url: client.calls[1].url, resolvingAgainstBaseURL: false))
        #expect(credits.path == "/3/person/5655/combined_credits")
        #expect(credits.queryItems?.first { $0.name == "language" }?.value == "fr-FR")
        #expect(client.calls[1].headers["Authorization"] == "Bearer tok")
    }

    // La filmographie est un bonus : si elle ne répond pas, la recherche par titre tient toujours.
    @Test func aFailingFilmographyLeavesTheTitleMatches() async throws {
        let client = StubHTTPClient(routes: [
            "search/multi": .success(try Fixtures.data("tmdb-search-multi-wes-anderson")),
            "combined_credits": .failure(HTTPError.status(500)),
        ])

        let candidates = try await makeProvider(client: client).search("wes anderson")

        #expect(candidates.map(\.id) == ["tmdb:movie:399170", "tmdb:movie:999999"])
    }

    // « dune » ramène aussi des homonymes (Aggy Dune…) loin dans la liste : leurs films n'ont rien à faire là.
    @Test func aTitleSearchDoesNotGoLookingForPeople() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-search-multi-dune"))

        let candidates = try await makeProvider(client: client).search("dune")

        #expect(client.calls.count == 1)
        #expect(candidates.count == 13)
    }

    @Test func aFilmographyIsCappedAndKeepsTheMostPopular() async throws {
        let works = (1...30).map {
            #"{"id":\#($0),"title":"Film \#($0)","media_type":"movie","popularity":\#($0).0,"release_date":"2020-01-01"}"#
        }.joined(separator: ",")
        let client = StubHTTPClient(routes: [
            "search/multi": .success(Data(#"{"results":[{"id":5655,"name":"X","media_type":"person"}]}"#.utf8)),
            "combined_credits": .success(Data("{\"crew\":[\(works)]}".utf8)),
        ])

        let candidates = try await makeProvider(client: client).search("x")

        #expect(candidates.count == 20)
        #expect(candidates.first?.id == "tmdb:movie:30")
        #expect(candidates.last?.id == "tmdb:movie:11")
    }

    // Un réalisateur ramène ce qu'il a réalisé, pas « Tous en scène » où il double un personnage.
    @Test func aDirectorBringsBackWhatTheyDirectedNotWhatTheyActedIn() async throws {
        let client = try personClient()

        let candidates = try await makeProvider(client: client).search("wes anderson")

        #expect(!candidates.contains { $0.id == "tmdb:movie:1234567" })
    }

    @Test func anActorBringsBackWhatTheyPlayedIn() async throws {
        let client = StubHTTPClient(routes: [
            "search/multi": .success(Data(#"""
            {"results":[{"id":1,"name":"Bill Murray","media_type":"person","known_for_department":"Acting"}]}
            """#.utf8)),
            "combined_credits": .success(Data(#"""
            {"cast":[{"id":153,"title":"Lost in Translation","media_type":"movie","popularity":16.0,"release_date":"2003-09-12"}],
             "crew":[{"id":777,"title":"Un film qu'il a produit","media_type":"movie","popularity":99.0,"job":"Producer","release_date":"2010-01-01"}]}
            """#.utf8)),
        ])

        let candidates = try await makeProvider(client: client).search("bill murray")

        #expect(candidates.map(\.id) == ["tmdb:movie:153"])
    }

    private func personClient() throws -> StubHTTPClient {
        StubHTTPClient(routes: [
            "search/multi": .success(try Fixtures.data("tmdb-search-multi-wes-anderson")),
            "combined_credits": .success(try Fixtures.data("tmdb-person-credits-wes-anderson")),
        ])
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
