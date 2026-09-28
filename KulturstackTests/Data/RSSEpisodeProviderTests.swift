import Foundation
import Testing
@testable import Kulturstack

// Fixture : les six épisodes les plus récents du vrai flux de « Le code a changé », plus trois
// cas limites ajoutés à la main — sans durée ni date, durée en secondes, sans guid.
struct RSSEpisodeProviderTests {
    private static let feedKey = "feed:https://radiofrance-podcast.net/podcast09/podcast_le-code-a-change.xml"

    private func makeProvider(_ client: StubHTTPClient) -> RSSEpisodeProvider {
        RSSEpisodeProvider(client: client, userAgent: "Kulturstack/0.1.0")
    }

    private func feedClient() throws -> StubHTTPClient {
        StubHTTPClient(data: try Fixtures.data("rss-le-code-a-change", extension: "xml"))
    }

    // MARK: - La saison implicite

    // Un podcast n'a pas de saisons : il en a une, invisible, qui porte tous ses épisodes.
    @Test func aFeedHasOneImplicitSeason() async throws {
        let provider = makeProvider(try feedClient())

        let seasons = try await provider.seasons(forKey: Self.feedKey)

        #expect(seasons.count == 1)
        #expect(seasons.first?.number == 1)
        #expect(seasons.first?.episodeCount == 9)
        #expect(seasons.first?.isSpecials == false)
    }

    // Une clé qui n'est pas un flux ne déclenche aucune requête : c'est TMDB qui répond pour
    // les séries, et cette source doit se taire.
    @Test func aKeyThatIsNotAFeedAsksNothing() async throws {
        let client = try feedClient()
        let provider = makeProvider(client)

        #expect(try await provider.seasons(forKey: "tmdb:tv:95396").isEmpty)
        #expect(try await provider.episodes(forKey: "itunes:1498344139", season: 1).isEmpty)
        #expect(client.calls.isEmpty)
    }

    // MARK: - Les épisodes

    @Test func theMostRecentEpisodeComesFirst() async throws {
        let episodes = try await makeProvider(try feedClient()).episodes(forKey: Self.feedKey, season: 1)

        #expect(episodes.count == 9)
        #expect(episodes.first?.number == 1)
        #expect(episodes.first?.title?.hasPrefix("Bande annonce") == true)
        #expect(episodes.map(\.number) == Array(1...9))
    }

    // L'identité vient du flux, pas de la position : c'est elle qui tient les coches.
    @Test func eachEpisodeCarriesItsFeedIdentifier() async throws {
        let episodes = try await makeProvider(try feedClient()).episodes(forKey: Self.feedKey, season: 1)

        #expect(episodes.first?.externalID == "355a727b-b9d9-4061-87ab-1e389f7a72ab")
        #expect(episodes.allSatisfy { $0.externalID?.isEmpty == false })
    }

    // Un épisode sans guid se reconnaît à son lien : mieux qu'un épisode qu'on ne peut pas cocher.
    @Test func anEpisodeWithoutAGuidFallsBackOnItsLink() async throws {
        let episodes = try await makeProvider(try feedClient()).episodes(forKey: Self.feedKey, season: 1)
        let sansGuid = try #require(episodes.first { $0.title?.contains("sans guid") == true })

        #expect(sansGuid.externalID == "https://www.radiofrance.fr/franceinter/podcasts/le-code-a-change/sans-guid")
    }

    @Test func durationsAreReadInBothFormats() async throws {
        let episodes = try await makeProvider(try feedClient()).episodes(forKey: Self.feedKey, season: 1)

        // 00:16:57 → 17 minutes, arrondi à la minute la plus proche.
        #expect(episodes.first { $0.title?.hasPrefix("Et si nous vivions") == true }?.runtimeMinutes == 17)
        // 1017 secondes → 17 minutes aussi.
        #expect(episodes.first { $0.title?.contains("en secondes") == true }?.runtimeMinutes == 17)
        // 00:00:52 → une minute, pas zéro : un épisode dure au moins une minute.
        #expect(episodes.first?.runtimeMinutes == 1)
    }

    @Test func aDateIsReadInTheFeedFormat() async throws {
        let episodes = try await makeProvider(try feedClient()).episodes(forKey: Self.feedKey, season: 1)
        let date = try #require(episodes.first?.airDate)

        let parts = Calendar(identifier: .gregorian).dateComponents(in: TimeZone(identifier: "Europe/Paris")!, from: date)
        #expect((parts.year, parts.month, parts.day) == (2026, 9, 23))
    }

    // Ni date ni durée : l'épisode existe quand même et reste cochable.
    @Test func anEpisodeWithoutMetadataIsStillThere() async throws {
        let episodes = try await makeProvider(try feedClient()).episodes(forKey: Self.feedKey, season: 1)
        let nu = try #require(episodes.first { $0.title?.contains("sans durée") == true })

        #expect(nu.airDate == nil)
        #expect(nu.runtimeMinutes == nil)
        #expect(nu.externalID == "guid-sans-metadonnees")
    }

    // MARK: - Les limites

    // Un flux de 1 000 épisodes ne remplit pas la base : on garde les plus récents.
    @Test func aVeryLongFeedIsCappedToTheMostRecentEpisodes() async throws {
        let items = (1...400).map { """
        <item><title>Épisode \($0)</title><guid>guid-\($0)</guid></item>
        """ }.joined()
        let feed = "<rss><channel><title>Long</title>\(items)</channel></rss>"
        let provider = makeProvider(StubHTTPClient(data: Data(feed.utf8)))

        let episodes = try await provider.episodes(forKey: Self.feedKey, season: 1)

        #expect(episodes.count == RSSEpisodeProvider.maxEpisodes)
        #expect(episodes.first?.title == "Épisode 1")
        #expect(episodes.last?.title == "Épisode \(RSSEpisodeProvider.maxEpisodes)")
    }

    @Test func anEmptyFeedHasNoEpisodeAndNoSeason() async throws {
        let provider = makeProvider(StubHTTPClient(data: Data("<rss><channel><title>Vide</title></channel></rss>".utf8)))

        #expect(try await provider.seasons(forKey: Self.feedKey).isEmpty)
        #expect(try await provider.episodes(forKey: Self.feedKey, season: 1).isEmpty)
    }

    // Un flux illisible n'est pas une panne réseau : la fiche doit rester lisible.
    @Test func anInvalidFeedGivesNoEpisodeWithoutThrowing() async throws {
        let provider = makeProvider(StubHTTPClient(data: Data("ceci n'est pas du XML".utf8)))

        #expect(try await provider.episodes(forKey: Self.feedKey, season: 1).isEmpty)
    }

    @Test func aNetworkFailurePropagates() async {
        let provider = makeProvider(StubHTTPClient(error: HTTPError.status(503)))

        await #expect(throws: HTTPError.status(503)) {
            _ = try await provider.episodes(forKey: Self.feedKey, season: 1)
        }
    }

    // Déplier une saison juste après l'avoir listée ne retélécharge pas le flux : il pèse 250 Ko.
    @Test func theFeedIsDownloadedOnlyOncePerLookup() async throws {
        let client = try feedClient()
        let provider = makeProvider(client)

        _ = try await provider.seasons(forKey: Self.feedKey)
        _ = try await provider.episodes(forKey: Self.feedKey, season: 1)

        #expect(client.calls.count == 1)
    }
}
