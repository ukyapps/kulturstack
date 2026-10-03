import Foundation
import Testing
@testable import Kulturstack

// Fixture réelle du 03/10 : la recherche « L'instant M » chez Podcast Index. Elle porte tous
// les pièges d'un coup — un podcast dont l'**auteur** s'appelle « L'instant M », un titre
// voisin (« La chronique de l'instant M »), et **deux** entrées « L'instant M » de France
// Inter avec des flux différents, dont une qui n'a qu'un épisode.
struct PodcastIndexFeedResolverTests {
    private static let theRightFeed =
        "https://radiofrance-podcast.net/podcast09/podcast_74ccb30d-1988-43b3-aec4-086578ac174e.xml"

    private func makeResolver(_ client: StubHTTPClient,
                              secrets: MockSecrets = MockSecrets(values: [.podcastIndexKey: "KEY123",
                                                                          .podcastIndexSecret: "SECRET456"]))
    -> PodcastIndexFeedResolver {
        PodcastIndexFeedResolver(secrets: secrets, client: client, userAgent: "Kulturstack/0.1.0")
    }

    private func searchClient() throws -> StubHTTPClient {
        StubHTTPClient(data: try Fixtures.data("podcastindex-search-instant-m"))
    }

    // MARK: - L'appariement

    // Deux entrées portent le même titre et le même producteur : celle qui a des épisodes gagne.
    @Test func theRichestFeedOfTheRightPodcastWins() async throws {
        let feed = try await makeResolver(try searchClient()).feedURL(title: "L'instant M", publisher: "France Inter")

        #expect(feed?.absoluteString == Self.theRightFeed)
    }

    // « L'instant pour Soi » a pour **auteur** « L'instant M » : chercher le nom n'importe où
    // ramènerait ses épisodes sur la fiche d'une émission de France Inter.
    @Test func aPodcastWhosePublisherLooksLikeTheTitleIsNotAMatch() async throws {
        let feed = try await makeResolver(try searchClient()).feedURL(title: "L'instant M", publisher: "Nulle part")

        #expect(feed == nil)
    }

    // Le titre doit être le même, pas seulement y ressembler.
    @Test func aNeighbouringTitleIsNotAMatch() async throws {
        let feed = try await makeResolver(try searchClient())
            .feedURL(title: "La chronique de l'instant", publisher: "France Inter")

        #expect(feed == nil)
    }

    // Les accents, la casse et la ponctuation ne comptent pas : « Ecoutez, révisez ! » chez
    // Apple s'écrit « Écoutez, révisez ! » dans l'index, ou l'inverse.
    @Test func accentsAndPunctuationDoNotCount() async throws {
        let feed = try await makeResolver(try searchClient()).feedURL(title: "l’instant m !", publisher: "FRANCE INTER")

        #expect(feed?.absoluteString == Self.theRightFeed)
    }

    // Cette source ne sert qu'à Radio France : un flux hébergé ailleurs n'est jamais retenu,
    // même quand le titre et le producteur concordent. C'est ce qui borne les dégâts d'un
    // mauvais appariement.
    @Test func aFeedHostedElsewhereIsNeverTaken() async throws {
        let client = StubHTTPClient(data: Data(#"""
        {"status":"true","feeds":[{"title":"Transfert","author":"France Inter",
        "url":"https://anchor.fm/s/x/podcast/rss","episodeCount":40,"lastUpdateTime":1790000000,"dead":0}]}
        """#.utf8))

        #expect(try await makeResolver(client).feedURL(title: "Transfert", publisher: "France Inter") == nil)
    }

    @Test func aDeadFeedIsIgnored() async throws {
        let client = StubHTTPClient(data: Data(#"""
        {"status":"true","feeds":[{"title":"Zombie","author":"France Inter",
        "url":"https://radiofrance-podcast.net/podcast09/mort.xml","episodeCount":99,
        "lastUpdateTime":1790000000,"dead":1}]}
        """#.utf8))

        #expect(try await makeResolver(client).feedURL(title: "Zombie", publisher: "France Inter") == nil)
    }

    // À nombre d'épisodes égal, le plus récemment mis à jour : c'est le cas des quatre
    // doublons mesurés le 03/10, tous à un épisode.
    @Test func atEqualEpisodeCountTheMostRecentWins() async throws {
        let client = StubHTTPClient(data: Data(#"""
        {"status":"true","feeds":[
        {"title":"Reggae","author":"Mouv'","url":"https://radiofrance-podcast.net/podcast09/vieux.xml",
         "episodeCount":1,"lastUpdateTime":1741000000,"dead":0},
        {"title":"Reggae","author":"Mouv'","url":"https://radiofrance-podcast.net/podcast09/recent.xml",
         "episodeCount":1,"lastUpdateTime":1791000000,"dead":0}]}
        """#.utf8))

        let feed = try await makeResolver(client).feedURL(title: "Reggae", publisher: "Mouv'")

        #expect(feed?.lastPathComponent == "recent.xml")
    }

    @Test func anEmptyAnswerGivesNothing() async throws {
        let client = StubHTTPClient(data: Data(#"{"status":"true","count":0,"feeds":[]}"#.utf8))

        #expect(try await makeResolver(client).feedURL(title: "Rien", publisher: "France Inter") == nil)
    }

    // MARK: - La requête

    // Podcast Index signe chaque appel : SHA-1 de la clé, du secret et de l'heure. Sans
    // l'en-tête exact, il répond 401 — vérifié sur l'API réelle le 03/10.
    @Test func theRequestIsSignedTheWayPodcastIndexAsks() async throws {
        let client = try searchClient()

        _ = try await makeResolver(client).feedURL(title: "L'instant M", publisher: "France Inter")
        let call = try #require(client.calls.first)

        #expect(call.url.host() == "api.podcastindex.org")
        #expect(call.url.path() == "/api/1.0/search/byterm")
        #expect(call.headers["X-Auth-Key"] == "KEY123")
        let date = try #require(call.headers["X-Auth-Date"])
        #expect(Double(date).map { abs($0 - Date.now.timeIntervalSince1970) < 120 } == true)
        let signature = try #require(call.headers["Authorization"])
        #expect(signature.count == 40)
        #expect(signature.allSatisfy { $0.isHexDigit && !$0.isUppercase })
        // Ils refusent les User-Agent génériques : « Sample code UA strings […] are not allowed ».
        #expect(call.headers["User-Agent"] == "Kulturstack/0.1.0")
    }

    // La signature elle-même, sur une heure figée, comparée à ce que rend `shasum -a 1` :
    // c'est la seule façon de prouver qu'on calcule le bon hash et pas le nôtre.
    // $ printf '%s' "KEY123SECRET4561700000000" | shasum -a 1
    @Test func theSignatureIsASHA1OfKeySecretAndTime() {
        let signature = PodcastIndexFeedResolver.signature(key: "KEY123", secret: "SECRET456", date: "1700000000")

        #expect(signature == "ba3aa7b676e968751bfc0773e46701fd09259b31")
    }

    @Test func theSearchedTermIsTheTitle() async throws {
        let client = try searchClient()

        _ = try await makeResolver(client).feedURL(title: "L'instant M", publisher: "France Inter")
        let call = try #require(client.calls.first)
        let components = try #require(URLComponents(url: call.url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(query["q"] == "L'instant M")
    }

    // MARK: - Sans clé

    // L'app doit marcher sans la clé : les podcasts dont la page donne le flux continuent, et
    // cette source se tait au lieu d'appeler une API qui la rejettera. Le `$(PODCASTINDEX_KEY)`
    // non substitué d'une compilation sans secrets compte déjà comme absent — `SecretsTests`.
    @Test func withoutCredentialsNothingIsAsked() async throws {
        let client = try searchClient()
        let resolver = makeResolver(client, secrets: MockSecrets(values: [:]))

        #expect(try await resolver.feedURL(title: "L'instant M", publisher: "France Inter") == nil)
        #expect(client.calls.isEmpty)
    }

    @Test func aFailurePropagates() async {
        let resolver = makeResolver(StubHTTPClient(error: HTTPError.status(401)))

        await #expect(throws: HTTPError.status(401)) {
            _ = try await resolver.feedURL(title: "L'instant M", publisher: "France Inter")
        }
    }
}
