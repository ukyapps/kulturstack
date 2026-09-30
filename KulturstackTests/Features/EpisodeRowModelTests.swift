import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct EpisodeRowModelTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func episode(_ number: Int, title: String? = nil, airDate: Date? = nil,
                         runtime: Int? = nil, watched: Bool = false) throws -> Episode {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        let episode = Episode(number: number, title: title, airDate: airDate, runtimeMinutes: runtime, season: season)
        context.insert(episode)
        if watched { context.insert(try LogEntry.make(item: item, status: .done, episode: episode)) }
        try context.save()
        return episode
    }

    @Test func anEpisodeWithATitleShowsItsNumberAndItsTitle() throws {
        let row = EpisodeRowModel(try episode(4, title: "Woe’s Hollow"))

        #expect(row.label == String(localized: "series.episode.titled \(4) \("Woe’s Hollow")"))
    }

    @Test func anEpisodeWithoutATitleFallsBackOnItsNumber() throws {
        let row = EpisodeRowModel(try episode(4))

        #expect(row.label == String(localized: "series.episode \(4)"))
        #expect(row.detail == nil)
    }

    @Test func aDiffusionDateAndARuntimeShareTheSameLine() throws {
        let day = try Date("2025-01-17", strategy: .iso8601.year().month().day())
        let row = EpisodeRowModel(try episode(1, airDate: day, runtime: 42))

        let detail = try #require(row.detail)
        #expect(detail.contains(String(localized: "series.episode.runtime \(42)")))
        #expect(detail.contains(day.formatted(date: .abbreviated, time: .omitted)))
    }

    @Test func anEpisodeWithALogIsChecked() throws {
        #expect(EpisodeRowModel(try episode(1, watched: true)).isWatched)
    }

    // MARK: - Un épisode de podcast (tranche Podcasts, PR 33)

    // Le rang d'un épisode de podcast bouge à chaque publication : il ne s'affiche pas.
    @Test func aPodcastEpisodeShowsItsTitleWithoutItsRank() throws {
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        let episode = Episode(number: 3, title: "Le Français qui a vu naître Google",
                              externalID: "guid-abc", season: season)
        context.insert(episode)
        try context.save()

        #expect(EpisodeRowModel(episode).label == "Le Français qui a vu naître Google")
    }

    // Un épisode de série, lui, garde son numéro : c'est celui que TMDB lui donne.
    @Test func aSeriesEpisodeKeepsItsNumberInTheLabel() throws {
        let row = EpisodeRowModel(try episode(4, title: "Woe’s Hollow"))

        #expect(row.label == String(localized: "series.episode.titled \(4) \("Woe’s Hollow")"))
    }

    // Sans titre — un spécial de Friends, par exemple —, le numéro reste le seul repère.
    @Test func anEpisodeWithoutATitleFallsBackOnItsNumberEvenWithAnIdentity() throws {
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Un podcast")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        let episode = Episode(number: 7, externalID: "guid-sans-titre", season: season)
        context.insert(episode)
        try context.save()

        #expect(EpisodeRowModel(episode).label == String(localized: "series.episode \(7)"))
    }

    // MARK: - « Jusqu'ici », rendu visible (retour du 27/09)

    // Le bouton ne s'affiche que là où il sert : s'il reste un épisode non coché derrière.
    @Test func anEpisodeWithAHoleBehindItOffersToCheckUpToHere() throws {
        let season = try season(of: 5, watched: [1, 2])

        let rows = season.orderedEpisodes.map(EpisodeRowModel.init)

        #expect(rows.map(\.canCheckUpTo) == [false, false, false, true, true])
    }

    @Test func theFirstEpisodeNeverOffersIt() throws {
        let season = try season(of: 3, watched: [])

        #expect(EpisodeRowModel(season.orderedEpisodes[0]).canCheckUpTo == false)
    }

    // Déjà coché ne veut pas dire inutile : on peut avoir coché E5 sans avoir coché E1 à E4.
    @Test func aCheckedEpisodeStillOffersItWhenSomethingIsMissingBehind() throws {
        let season = try season(of: 5, watched: [5])

        #expect(EpisodeRowModel(season.orderedEpisodes[4]).canCheckUpTo)
    }

    @Test func aSeasonWatchedInOrderOffersItNowhere() throws {
        let season = try season(of: 4, watched: [1, 2, 3, 4])

        #expect(season.orderedEpisodes.map(EpisodeRowModel.init).allSatisfy { !$0.canCheckUpTo })
    }

    private func season(of count: Int, watched: [Int]) throws -> Season {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        for number in 1...count { context.insert(Episode(number: number, season: season)) }
        try context.save()
        for episode in season.orderedEpisodes where watched.contains(episode.number) {
            context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        try context.save()
        return season
    }

    // Une envie posée sur l'œuvre n'est pas « j'ai vu cet épisode ».
    @Test func onlyADoneLogChecksAnEpisode() throws {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        let episode = Episode(number: 1, season: season)
        context.insert(episode)
        context.insert(try LogEntry.make(item: item, status: .inProgress, episode: episode))
        try context.save()

        #expect(EpisodeRowModel(episode).isWatched == false)
    }
}
