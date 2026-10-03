import Foundation
import Testing
@testable import Kulturstack

// Apple ne publie pas le flux des podcasts de Radio France (mesuré le 27/09 : dix podcasts de
// France Inter et France Culture, dix sans flux). Leur page sur radiofrance.fr le déclare.
// Fixtures réelles : le `lookup` d'Apple pour « Le code a changé », sa page, et son flux.
struct RadioFranceEpisodeProviderTests {
    private static let itunesKey = "itunes:1498344139"
    private static let pagePath = "/franceinter/podcasts/le-code-a-change"

    private func makeProvider(_ client: StubHTTPClient) -> RadioFranceEpisodeProvider {
        RadioFranceEpisodeProvider(client: client, userAgent: "Kulturstack/0.1.0", country: "FR")
    }

    private func lookup(title: String, publisher: String, feed: String? = nil) -> Data {
        let feedField = feed.map { #","feedUrl":"\#($0)""# } ?? ""
        return Data(#"""
        {"resultCount":1,"results":[{"collectionId":42,"collectionName":"\#(title)",
        "artistName":"\#(publisher)","trackCount":3\#(feedField)}]}
        """#.utf8)
    }

    // La chaîne complète : la clé Apple, le nom du podcast, sa page, son flux, ses épisodes.
    private func fullChain() throws -> StubHTTPClient {
        StubHTTPClient(routes: [
            "/lookup": .success(try Fixtures.data("itunes-lookup-podcast-code")),
            Self.pagePath: .success(try Fixtures.data("radiofrance-le-code-a-change", extension: "html")),
            "/podcast09/": .success(try Fixtures.data("rss-le-code-a-change", extension: "xml")),
        ])
    }

    // MARK: - Les clés qui ne sont pas les siennes

    // Un podcast dont Apple donne le flux est servi par le flux, et cette source ne doit rien
    // charger : c'est la garantie que la page de Radio France n'est lue que quand il faut.
    @Test func aKeyThatIsNotAnApplePodcastAsksNothing() async throws {
        let client = try fullChain()
        let provider = makeProvider(client)

        #expect(try await provider.seasons(forKey: "feed:https://anchor.fm/s/x/podcast/rss").isEmpty)
        #expect(try await provider.seasons(forKey: "tmdb:tv:95396").isEmpty)
        #expect(try await provider.episodes(forKey: "ol:OL123W", season: 1).isEmpty)
        #expect(client.calls.isEmpty)
    }

    // Les clés Apple sont numériques : une clé d'une autre forme ne vaut pas une requête.
    @Test func aMalformedApplePodcastKeyAsksNothing() async throws {
        let client = try fullChain()
        let provider = makeProvider(client)

        #expect(try await provider.seasons(forKey: "itunes:").isEmpty)
        #expect(try await provider.seasons(forKey: "itunes:tt0903747").isEmpty)
        #expect(client.calls.isEmpty)
    }

    // MARK: - Du podcast Apple à ses épisodes

    @Test func aRadioFrancePodcastGetsItsEpisodesThroughItsPage() async throws {
        let provider = makeProvider(try fullChain())

        let episodes = try await provider.episodes(forKey: Self.itunesKey, season: 1)

        // Le flux arrive du plus récent au plus ancien ; la liste se lit dans l'autre sens.
        #expect(episodes.count == 9)
        #expect(episodes.last?.title?.hasPrefix("Bande annonce") == true)
        #expect(episodes.allSatisfy { $0.externalID?.isEmpty == false })
    }

    @Test func aRadioFrancePodcastHasTheSameImplicitSeasonAsAnyFeed() async throws {
        let provider = makeProvider(try fullChain())

        let seasons = try await provider.seasons(forKey: Self.itunesKey)

        #expect(seasons.count == 1)
        #expect(seasons.first?.episodeCount == 9)
    }

    @Test func theChainIsAppleThenThePageThenTheFeed() async throws {
        let client = try fullChain()

        _ = try await makeProvider(client).seasons(forKey: Self.itunesKey)
        let paths = client.calls.map { $0.url.path() }

        #expect(paths.count == 3)
        #expect(paths[0] == "/lookup")
        #expect(paths[1] == Self.pagePath)
        #expect(paths[2].hasPrefix("/podcast09/"))
        // Le podcast est cherché dans le catalogue du pays de l'app, comme la recherche.
        let query = try #require(URLComponents(url: client.calls[0].url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(query.contains(URLQueryItem(name: "id", value: "1498344139")))
        #expect(query.contains(URLQueryItem(name: "country", value: "FR")))
    }

    // La page pèse 450 Ko : lister la saison puis la déplier ne la retélécharge pas, et ne
    // redemande pas son nom à Apple.
    @Test func theResolutionHappensOnlyOnce() async throws {
        let client = try fullChain()
        let provider = makeProvider(client)

        _ = try await provider.seasons(forKey: Self.itunesKey)
        _ = try await provider.episodes(forKey: Self.itunesKey, season: 1)

        #expect(client.calls.count == 3)
    }

    // « Les Grandes Traversées » chez Apple, « grandes-traversees » sur radiofrance.fr : la
    // première orthographe n'existe pas, la deuxième oui.
    @Test func aSecondSpellingIsTriedWhenTheFirstPageDoesNotExist() async throws {
        let client = StubHTTPClient(routes: [
            "/lookup": .success(lookup(title: "Les Grandes Traversées", publisher: "France Culture")),
            "/franceculture/podcasts/grandes-traversees":
                .success(try Fixtures.data("radiofrance-le-code-a-change", extension: "html")),
            "/podcast09/": .success(try Fixtures.data("rss-le-code-a-change", extension: "xml")),
        ])

        let episodes = try await makeProvider(client).episodes(forKey: Self.itunesKey, season: 1)
        let paths = client.calls.map { $0.url.path() }

        #expect(episodes.count == 9)
        #expect(paths[1] == "/franceculture/podcasts/les-grandes-traversees")
        #expect(paths[2] == "/franceculture/podcasts/grandes-traversees")
    }

    // MARK: - Ce qui manque, et ce qui tombe en panne

    // « Le meilleur de l'histoire », le seul des 24 mesurés le 03/10 qui n'a pas de page chez
    // Radio France : la fiche montre son état vide, qui dit que le flux ne les donne pas.
    // Une absence n'est pas une panne.
    @Test func aPodcastWithoutAPageHasNoEpisodeAndNoError() async throws {
        let client = StubHTTPClient(routes: [
            "/lookup": .success(lookup(title: "Le meilleur de l'histoire", publisher: "France Inter")),
        ])
        let provider = makeProvider(client)

        #expect(try await provider.seasons(forKey: Self.itunesKey).isEmpty)
        #expect(try await provider.episodes(forKey: Self.itunesKey, season: 1).isEmpty)
        // Le nom demandé une fois, les deux orthographes essayées une fois : la deuxième
        // visite de la fiche ne redemande rien.
        #expect(client.calls.count == 3)
    }

    // Vide ≠ erreur : radiofrance.fr en panne ne doit pas se lire « ce podcast n'a pas
    // d'épisode », mais « impossible de charger les épisodes ».
    @Test func aPageThatFailsIsAnErrorNotAnAbsence() async throws {
        let client = StubHTTPClient(routes: [
            "/lookup": .success(try Fixtures.data("itunes-lookup-podcast-code")),
            Self.pagePath: .failure(HTTPError.status(503)),
        ])

        await #expect(throws: HTTPError.status(503)) {
            _ = try await makeProvider(client).seasons(forKey: Self.itunesKey)
        }
    }

    @Test func anAppleFailurePropagates() async {
        let client = StubHTTPClient(error: HTTPError.status(503))

        await #expect(throws: HTTPError.status(503)) {
            _ = try await makeProvider(client).seasons(forKey: Self.itunesKey)
        }
    }

    // MARK: - Les podcasts qui ne sont pas de Radio France

    // Un podcast d'un autre producteur sans flux chez Apple n'a pas de page à visiter : on
    // demande son nom, on s'arrête là. Pas de page chargée au hasard.
    @Test func aPodcastFromAnotherPublisherLoadsNoPage() async throws {
        let client = StubHTTPClient(routes: [
            "/lookup": .success(lookup(title: "Transfert", publisher: "Slate.fr")),
        ])

        #expect(try await makeProvider(client).seasons(forKey: Self.itunesKey).isEmpty)
        #expect(client.calls.count == 1)
    }

    // Si Apple a le flux, c'est lui qui gagne : aucune page de Radio France n'est lue.
    @Test func theFeedAppleGivesIsUsedWithoutReadingAnyPage() async throws {
        let client = StubHTTPClient(routes: [
            "/lookup": .success(lookup(title: "Le code a changé", publisher: "France Inter",
                                       feed: "https://radiofrance-podcast.net/podcast09/direct.xml")),
            "/podcast09/": .success(try Fixtures.data("rss-le-code-a-change", extension: "xml")),
        ])

        let episodes = try await makeProvider(client).episodes(forKey: Self.itunesKey, season: 1)
        let paths = client.calls.map { $0.url.path() }

        #expect(episodes.count == 9)
        #expect(paths == ["/lookup", "/podcast09/direct.xml"])
    }

    // Un podcast qu'Apple ne connaît plus : rien à montrer, rien à faire tomber.
    @Test func aPodcastAppleNoLongerKnowsGivesNothing() async throws {
        let client = StubHTTPClient(routes: ["/lookup": .success(Data(#"{"resultCount":0,"results":[]}"#.utf8))])

        #expect(try await makeProvider(client).seasons(forKey: Self.itunesKey).isEmpty)
    }
}
