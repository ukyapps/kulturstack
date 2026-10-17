import Foundation
import Testing
@testable import Kulturstack

// Fixture capturée sur l'API réelle le 17/10 : « random access memories », 5 résultats, dont
// une compilation « Multi-interprètes » et un **autre artiste** qui a sorti un disque du même
// titre — c'est le cas qui prouve qu'un titre ne fait pas une identité.
struct AppleAlbumProviderTests {
    private func makeProvider(client: StubHTTPClient, country: String = "FR") -> AppleAlbumProvider {
        AppleAlbumProvider(client: client, country: country)
    }

    private func candidates() async throws -> [MediaCandidate] {
        let client = StubHTTPClient(data: try Fixtures.data("itunes-search-album-ram"))
        return try await makeProvider(client: client).search("random access memories")
    }

    @Test func parsesFixtureIntoAlbumCandidates() async throws {
        let results = try await candidates()

        #expect(results.count == 5)
        #expect(results.allSatisfy { $0.kind == .album && $0.providerID == "apple-music" })
        let ram = try #require(results.first)
        #expect(ram.title == "Random Access Memories")
        #expect(ram.creators == ["Daft Punk"])
    }

    // Les podcasts portent `itunes:<id>` depuis la T4a. Un disque porte `itunes:album:<id>` —
    // comme TMDB distingue `tmdb:movie:` de `tmdb:tv:`. Préfixer le disque plutôt que le
    // podcast évite de réécrire les clés déjà en base.
    @Test func theKeyNamesTheKindSoAPodcastIsNeverAnAlbum() async throws {
        let ram = try #require(try await candidates().first)

        #expect(ram.id == "itunes:album:617154241")
        #expect(ram.externalKeys == ["itunes:album:617154241"])
    }

    // Deux disques nommés « Random Access Memories », deux artistes : deux œuvres. C'est
    // l'identifiant d'Apple qui tranche, jamais le titre.
    @Test func sameTitleByAnotherArtistIsAnotherWork() async throws {
        let results = try await candidates()
        let daftPunk = try #require(results.first { $0.creators == ["Daft Punk"] && $0.title == "Random Access Memories" })
        let kirmann = try #require(results.first { $0.creators == ["Franz Kirmann"] })

        #expect(kirmann.title == daftPunk.title)
        #expect(kirmann.id != daftPunk.id)
    }

    // Apple ne rend que `artworkUrl100` sur un disque — pas d'`artworkUrl600` comme sur un
    // podcast. L'adresse se réécrit : vérifié le 17/10, `600x600bb.jpg` rend bien 600×600 px.
    @Test func theCoverIsRaisedToSixHundred() async throws {
        let ram = try #require(try await candidates().first)

        #expect(ram.coverURL?.absoluteString.hasSuffix("/600x600bb.jpg") == true)
        #expect(ram.coverURL?.absoluteString.contains("100x100") == false)
    }

    // Une jaquette qui ne suit pas le gabarit d'Apple est gardée telle quelle : mieux vaut la
    // vignette que rien.
    @Test func anUnexpectedCoverIsKeptAsIs() async throws {
        let client = StubHTTPClient(data: Data(#"""
        {"resultCount":1,"results":[{"collectionId":1,"collectionName":"X","artistName":"Y",
        "artworkUrl100":"https://example.com/pochette.png"}]}
        """#.utf8))

        let result = try #require(try await makeProvider(client: client).search("x").first)

        #expect(result.coverURL?.absoluteString == "https://example.com/pochette.png")
    }

    @Test func anAlbumWithoutACoverIsStillUsable() async throws {
        let client = StubHTTPClient(data: Data(#"""
        {"resultCount":1,"results":[{"collectionId":2,"collectionName":"Sans pochette","artistName":"Y"}]}
        """#.utf8))

        let result = try #require(try await makeProvider(client: client).search("x").first)

        #expect(result.coverURL == nil)
        #expect(result.title == "Sans pochette")
    }

    // Contrairement à un podcast, un disque a une date de sortie qui ne bouge plus : elle
    // s'affiche.
    @Test func anAlbumKeepsItsReleaseYear() async throws {
        let ram = try #require(try await candidates().first)

        #expect(ram.year == 2013)
    }

    @Test func aMalformedReleaseDateLeavesTheYearEmpty() async throws {
        let client = StubHTTPClient(data: Data(#"""
        {"resultCount":1,"results":[{"collectionId":3,"collectionName":"X","artistName":"Y",
        "releaseDate":"bientôt"}]}
        """#.utf8))

        let result = try #require(try await makeProvider(client: client).search("x").first)

        #expect(result.year == nil)
    }

    @Test func fillsAlbumDetails() async throws {
        let ram = try #require(try await candidates().first)
        let details = try #require(ram.details as? AlbumDetails)

        #expect(details.trackCount == 14)
        #expect(details.genre == "Pop")
    }

    @Test func sendsTheExpectedQuery() async throws {
        let client = StubHTTPClient(data: Data(#"{"resultCount":0,"results":[]}"#.utf8))

        let results = try await makeProvider(client: client).search("thriller")
        let call = try #require(client.calls.first)
        let components = try #require(URLComponents(url: call.url, resolvingAgainstBaseURL: false))
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })

        #expect(results.isEmpty)
        #expect(components.host == "itunes.apple.com")
        #expect(components.path == "/search")
        #expect(query["term"] == "thriller")
        #expect(query["media"] == "music")
        #expect(query["entity"] == "album")
        #expect(query["country"] == "FR")
        #expect(query["limit"] == "20")
    }

    // Le catalogue musical est par pays comme celui des podcasts : les droits ne sont pas les
    // mêmes partout.
    @Test func theCatalogFollowsTheCountryOfTheApp() async throws {
        let client = StubHTTPClient(data: Data(#"{"resultCount":0,"results":[]}"#.utf8))

        _ = try await makeProvider(client: client, country: "US").search("thriller")
        let call = try #require(client.calls.first)
        let components = try #require(URLComponents(url: call.url, resolvingAgainstBaseURL: false))

        #expect(components.queryItems?.first { $0.name == "country" }?.value == "US")
    }

    @Test func httpFailurePropagates() async {
        let client = StubHTTPClient(error: HTTPError.status(503))

        await #expect(throws: HTTPError.status(503)) {
            try await makeProvider(client: client).search("thriller")
        }
    }

    @Test func declaresAlbumsOnly() {
        let provider = makeProvider(client: StubHTTPClient(data: Data()))

        #expect(provider.id == "apple-music")
        #expect(provider.supportedKinds == [.album])
    }

    @Test func aResultWithoutANameIsDropped() async throws {
        let client = StubHTTPClient(data: Data(#"""
        {"resultCount":2,"results":[{"collectionId":1,"artistName":"X"},
        {"collectionId":2,"collectionName":"Vrai disque","artistName":"Y"}]}
        """#.utf8))

        let results = try await makeProvider(client: client).search("x")

        #expect(results.map(\.title) == ["Vrai disque"])
    }
}
