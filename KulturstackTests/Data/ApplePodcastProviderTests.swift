import Foundation
import Testing
@testable import Kulturstack

// Fixture capturée sur l'API réelle le 27/09 : « le code a changé », 3 résultats, dont un
// sans flux RSS — c'est le cas Radio France, qui décide de la suite de la tranche.
struct ApplePodcastProviderTests {
    private func makeProvider(client: StubHTTPClient, country: String = "FR") -> ApplePodcastProvider {
        ApplePodcastProvider(client: client, country: country)
    }

    private func candidates() async throws -> [MediaCandidate] {
        let client = StubHTTPClient(data: try Fixtures.data("itunes-search-podcast-code"))
        return try await makeProvider(client: client).search("le code a changé")
    }

    @Test func parsesFixtureIntoPodcastCandidates() async throws {
        let results = try await candidates()

        #expect(results.count == 3)
        #expect(results.allSatisfy { $0.kind == .podcast && $0.providerID == "apple" })
        let code = try #require(results.first)
        #expect(code.id == "itunes:1498344139")
        #expect(code.title == "Le code a changé")
        #expect(code.creators == ["France Inter"])
        #expect(code.externalKeys.contains("itunes:1498344139"))
    }

    // La jaquette en 600 px, pas la vignette de 100 : c'est une fiche, pas une ligne de liste.
    @Test func theCoverIsTheLargeOne() async throws {
        let code = try #require(try await candidates().first)

        #expect(code.coverURL?.absoluteString.hasSuffix("600x600bb.jpg") == true)
    }

    // La date que rend Apple est celle du dernier épisode, pas celle du podcast : elle
    // afficherait « 2026 » sur un podcast lancé en 2020. Mieux vaut rien que faux.
    @Test func aPodcastHasNoYear() async throws {
        #expect(try await candidates().allSatisfy { $0.year == nil })
    }

    @Test func fillsPodcastDetails() async throws {
        let code = try #require(try await candidates().first)
        let details = try #require(code.details as? PodcastDetails)

        #expect(details.episodeCount == 96)
        #expect(details.publisher == "France Inter")
        #expect(details.genre == "Actualités technologiques")
        #expect(details.feedURL == nil)
    }

    // Le flux, quand Apple le donne, devient une clé externe : c'est par elle que les épisodes
    // se chargeront. Quand il manque — Radio France —, le podcast reste trouvable et loggable.
    @Test func theFeedBecomesAKeyWhenAppleGivesIt() async throws {
        let results = try await candidates()
        let withFeed = try #require(results.first { $0.id == "itunes:1831788215" })
        let withoutFeed = try #require(results.first { $0.id == "itunes:1498344139" })

        #expect(withFeed.externalKeys.contains("feed:https://anchor.fm/s/1081405b0/podcast/rss"))
        #expect((withFeed.details as? PodcastDetails)?.feedURL?.host() == "anchor.fm")
        #expect(withoutFeed.externalKeys.allSatisfy { !$0.hasPrefix("feed:") })
    }

    @Test func sendsTheExpectedQuery() async throws {
        let client = StubHTTPClient(data: Data(#"{"resultCount":0,"results":[]}"#.utf8))

        let results = try await makeProvider(client: client).search("transfert")
        let call = try #require(client.calls.first)
        let components = try #require(URLComponents(url: call.url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(results.isEmpty)
        #expect(components.host == "itunes.apple.com")
        #expect(components.path == "/search")
        #expect(query["term"] == "transfert")
        #expect(query["media"] == "podcast")
        #expect(query["entity"] == "podcast")
        #expect(query["country"] == "FR")
        #expect(query["limit"] == "20")
    }

    // Un catalogue par pays : chercher « the daily » depuis les États-Unis ne rend pas la
    // même chose que depuis la France.
    @Test func theCatalogFollowsTheCountryOfTheApp() async throws {
        let client = StubHTTPClient(data: Data(#"{"resultCount":0,"results":[]}"#.utf8))

        _ = try await makeProvider(client: client, country: "US").search("the daily")
        let call = try #require(client.calls.first)
        let components = try #require(URLComponents(url: call.url, resolvingAgainstBaseURL: false))

        #expect(components.queryItems?.first { $0.name == "country" }?.value == "US")
    }

    @Test func httpFailurePropagates() async {
        let client = StubHTTPClient(error: HTTPError.status(503))

        await #expect(throws: HTTPError.status(503)) {
            try await makeProvider(client: client).search("transfert")
        }
    }

    @Test func declaresPodcastsOnly() {
        let provider = makeProvider(client: StubHTTPClient(data: Data()))

        #expect(provider.id == "apple")
        #expect(provider.supportedKinds == [.podcast])
    }

    // Un résultat sans nom n'a rien à montrer : il est écarté, il ne fait pas tomber le reste.
    @Test func aResultWithoutANameIsDropped() async throws {
        let client = StubHTTPClient(data: Data(#"""
        {"resultCount":2,"results":[{"collectionId":1,"artistName":"X"},
        {"collectionId":2,"collectionName":"Vrai podcast","artistName":"Y"}]}
        """#.utf8))

        let results = try await makeProvider(client: client).search("x")

        #expect(results.map(\.title) == ["Vrai podcast"])
    }
}
