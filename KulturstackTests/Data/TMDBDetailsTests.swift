import Foundation
import Testing
@testable import Kulturstack

struct TMDBDetailsTests {
    private func makeProvider(client: StubHTTPClient, token: String? = "tok") -> TMDBProvider {
        let secrets = MockSecrets(values: token.map { [.tmdbReadToken: $0] } ?? [:])
        return TMDBProvider(secrets: secrets, client: client, language: "fr-FR")
    }

    @Test func movieDetailsGiveRuntimeGenresAndDirectors() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-movie-dune"))

        let enrichment = try #require(try await makeProvider(client: client).details(forKey: "tmdb:movie:438631"))

        #expect(enrichment.creators == ["Denis Villeneuve"])
        let film = try #require(enrichment.details as? FilmDetails)
        #expect(film.runtimeMinutes == 155)
        #expect(film.genres == ["Science-Fiction", "Aventure"])
        #expect(film.directors == ["Denis Villeneuve"])
    }

    @Test func tvDetailsGiveSeasonsEpisodesStatusGenresAndCreators() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-tv-dune-prophecy"))

        let enrichment = try #require(try await makeProvider(client: client).details(forKey: "tmdb:tv:90228"))

        #expect(enrichment.creators == ["Diane Ademu-John", "Alison Schapker"])
        let series = try #require(enrichment.details as? SeriesDetails)
        #expect(series.seasonCount == 2)
        #expect(series.episodeCount == 14)
        #expect(series.status == "Returning Series")
        #expect(series.genres == ["Science-Fiction & Fantastique", "Drame", "Action & Adventure"])
    }

    @Test func movieRequestAsksForCreditsInTheRightLanguageWithTheToken() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-movie-dune"))

        _ = try await makeProvider(client: client).details(forKey: "tmdb:movie:438631")

        let call = try #require(client.calls.first)
        #expect(call.url.path().hasSuffix("/movie/438631"))
        #expect(call.url.query()?.contains("append_to_response=credits") == true)
        #expect(call.url.query()?.contains("language=fr-FR") == true)
        #expect(call.headers["Authorization"] == "Bearer tok")
    }

    @Test(arguments: ["imdb:tt1160419", "tmdb:person:1", "tmdb:movie:", "ol:work:1"])
    func keysOfAnotherShapeAreIgnoredWithoutAnyRequest(key: String) async throws {
        let client = StubHTTPClient(data: Data())

        let enrichment = try await makeProvider(client: client).details(forKey: key)

        #expect(enrichment == nil)
        #expect(client.calls.isEmpty)
    }

    @Test func aMissingSecretFailsBeforeAnyRequest() async {
        let client = StubHTTPClient(data: Data())

        await #expect(throws: SecretsError.self) {
            try await makeProvider(client: client, token: nil).details(forKey: "tmdb:movie:1")
        }
        #expect(client.calls.isEmpty)
    }
}
