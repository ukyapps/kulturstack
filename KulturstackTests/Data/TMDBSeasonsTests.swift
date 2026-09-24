import Foundation
import Testing
@testable import Kulturstack

struct TMDBSeasonsTests {
    private func makeProvider(client: StubHTTPClient, token: String? = "tok") -> TMDBProvider {
        let secrets = MockSecrets(values: token.map { [.tmdbReadToken: $0] } ?? [:])
        return TMDBProvider(secrets: secrets, client: client, language: "fr-FR")
    }

    private func json(_ raw: String) -> StubHTTPClient { StubHTTPClient(data: Data(raw.utf8)) }

    // Une date de diffusion TMDB est un jour, pas un instant : on l'attend à minuit UTC.
    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        return try #require(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }

    // Les « Épisodes spéciaux » sont la saison 0 chez TMDB. TMDB ne dit jamais à quelle
    // saison ils se rattachent : ils ne peuvent pas être intercalés, ils passent en dernier.
    @Test func theSpecialsComeLastAndNeverBetweenTwoSeasons() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-tv-friends"))

        let seasons = try await makeProvider(client: client).seasons(forKey: "tmdb:tv:1668")

        #expect(seasons.map(\.number) == Array(1...10) + [0])
        #expect(seasons.last?.isSpecials == true)
        #expect(seasons.last?.title == "Épisodes spéciaux")
        #expect(seasons.last?.episodeCount == 39)
        #expect(seasons.dropLast().allSatisfy { $0.isSpecials == false })
    }

    // Un spécial se coche comme un épisode : la saison 0 se charge comme les autres.
    @Test func theSpecialsSeasonLoadsItsEpisodesLikeAnyOther() async throws {
        let client = json(#"""
        {"season_number": 0, "episodes": [
            {"episode_number": 1, "name": "The Stuff You've Never Seen", "air_date": "2001-02-15", "runtime": 42},
            {"episode_number": 10, "name": "Épisode 10", "air_date": null, "runtime": null}
        ]}
        """#)

        let episodes = try await makeProvider(client: client).episodes(forKey: "tmdb:tv:1668", season: 0)

        #expect(episodes.map(\.number) == [1, 10])
        #expect(episodes.first?.title == "The Stuff You've Never Seen")
        #expect(episodes.last?.airDate == nil)
    }

    @Test func aSeasonCarriesItsTitleItsCountAndItsFirstAirDate() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-tv-friends"))

        let seasons = try await makeProvider(client: client).seasons(forKey: "tmdb:tv:1668")

        let first = try #require(seasons.first)
        #expect(first.title == "Saison 1")
        #expect(first.episodeCount == 24)
        #expect(first.airDate == (try day(1994, 9, 22)))
        #expect(seasons.first { $0.number == 10 }?.episodeCount == 17)
    }

    // Une série longue, c'est dix appels réseau pour rien : lister les saisons n'en charge aucune.
    @Test func listingTheSeasonsLoadsNoEpisode() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-tv-friends"))

        _ = try await makeProvider(client: client).seasons(forKey: "tmdb:tv:1668")

        #expect(client.calls.count == 1)
        let call = try #require(client.calls.first)
        #expect(call.url.path().hasSuffix("/tv/1668"))
        #expect(call.url.path().contains("/season/") == false)
        #expect(call.url.query()?.contains("language=fr-FR") == true)
        #expect(call.headers["Authorization"] == "Bearer tok")
    }

    @Test func theEpisodesOfASeasonCarryNumberTitleDateAndRuntime() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-tv-season-dune-prophecy-1"))

        let episodes = try await makeProvider(client: client).episodes(forKey: "tmdb:tv:90228", season: 1)

        #expect(episodes.count == 6)
        let first = try #require(episodes.first)
        #expect(first.number == 1)
        #expect(first.title == "La main sur le pouvoir")
        #expect(first.runtimeMinutes == 66)
        #expect(first.airDate == (try day(2024, 11, 17)))
        #expect(episodes.map(\.number) == Array(1...6))
    }

    @Test func theEpisodeRequestNamesItsSeason() async throws {
        let client = StubHTTPClient(data: try Fixtures.data("tmdb-tv-season-dune-prophecy-1"))

        _ = try await makeProvider(client: client).episodes(forKey: "tmdb:tv:90228", season: 2)

        let call = try #require(client.calls.first)
        #expect(call.url.path().hasSuffix("/tv/90228/season/2"))
    }

    // Une saison annoncée mais pas encore diffusée : pas d'épisodes, pas d'erreur.
    @Test func anAnnouncedSeasonWithoutEpisodesIsEmptyNotBroken() async throws {
        let client = json(#"{"season_number": 3, "episodes": []}"#)

        let episodes = try await makeProvider(client: client).episodes(forKey: "tmdb:tv:90228", season: 3)

        #expect(episodes.isEmpty)
    }

    @Test func anEpisodeWithoutAnAirDateIsStillListed() async throws {
        let client = json(#"""
        {"season_number": 3, "episodes": [
            {"episode_number": 1, "name": "Inconnu", "air_date": null, "runtime": null},
            {"episode_number": 2, "name": "", "air_date": "", "runtime": 0}
        ]}
        """#)

        let episodes = try await makeProvider(client: client).episodes(forKey: "tmdb:tv:90228", season: 3)

        #expect(episodes.count == 2)
        #expect(episodes.first?.airDate == nil)
        #expect(episodes.first?.runtimeMinutes == nil)
        #expect(episodes.first?.title == "Inconnu")
        // Un titre vide n'est pas un titre : l'écran affichera « Épisode 2 ».
        #expect(episodes.last?.title == nil)
        #expect(episodes.last?.airDate == nil)
        #expect(episodes.last?.runtimeMinutes == nil)
    }

    @Test(arguments: ["tmdb:movie:438631", "ol:work:OL1W", "tmdb:tv:", "tmdb:person:1"])
    func aKeyOfAnotherShapeAsksNothing(key: String) async throws {
        let client = StubHTTPClient(data: Data())

        let seasons = try await makeProvider(client: client).seasons(forKey: key)

        #expect(seasons.isEmpty)
        #expect(client.calls.isEmpty)
    }

    @Test func aNetworkOutageSurfacesTheError() async {
        let client = StubHTTPClient(error: HTTPError.status(503))

        await #expect(throws: HTTPError.self) {
            _ = try await makeProvider(client: client).seasons(forKey: "tmdb:tv:1668")
        }
    }

    @Test func aMissingSecretFailsBeforeAnyRequest() async {
        let client = StubHTTPClient(data: Data())

        await #expect(throws: (any Error).self) {
            _ = try await makeProvider(client: client, token: nil).seasons(forKey: "tmdb:tv:1668")
        }
        #expect(client.calls.isEmpty)
    }
}
