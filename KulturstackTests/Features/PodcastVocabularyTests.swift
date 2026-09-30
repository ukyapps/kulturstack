import Foundation
import SwiftData
import Testing
@testable import Kulturstack

// « Maintenant je voudrais qu'on ajoute les podcasts » (founder, 27/09). Un podcast n'a pas
// de saisons et ne se « regarde » pas : les mots de l'écran doivent suivre.
@MainActor
struct PodcastVocabularyTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    @Test func aPodcastDoesNotShowSeasons() {
        #expect(MediaKind.series.showsSeasons)
        #expect(MediaKind.podcast.showsSeasons == false)
    }

    // Chaque mot de l'écran des épisodes a sa version série et sa version podcast, et les deux
    // disent quelque chose : un libellé vide passerait inaperçu jusqu'au téléphone.
    @Test func everyWordDiffersBetweenASeriesAndAPodcast() {
        let words: [(String, String)] = [
            (MediaKind.series.episodesSectionTitle, MediaKind.podcast.episodesSectionTitle),
            (MediaKind.series.checkEverythingLabel, MediaKind.podcast.checkEverythingLabel),
            (MediaKind.series.dropLabel, MediaKind.podcast.dropLabel),
            (MediaKind.series.resumeLabel, MediaKind.podcast.resumeLabel),
            (MediaKind.series.statusMenuLabel, MediaKind.podcast.statusMenuLabel),
            (MediaKind.series.uncheckEverythingTitle, MediaKind.podcast.uncheckEverythingTitle),
            (MediaKind.series.uncheckEverythingMessage, MediaKind.podcast.uncheckEverythingMessage),
            (MediaKind.series.noEpisodesTitle, MediaKind.podcast.noEpisodesTitle),
            (MediaKind.series.noEpisodesMessage, MediaKind.podcast.noEpisodesMessage),
            (MediaKind.series.episodesFailedTitle, MediaKind.podcast.episodesFailedTitle),
        ]

        #expect(words.count == 10)
        #expect(words.allSatisfy { !$0.0.isEmpty && !$0.1.isEmpty })
        #expect(words.allSatisfy { $0.0 != $0.1 })
    }

    @Test func noWordTalksAboutSeasonsForAPodcast() {
        let words = [MediaKind.podcast.episodesSectionTitle, MediaKind.podcast.checkEverythingLabel,
                     MediaKind.podcast.dropLabel, MediaKind.podcast.uncheckEverythingMessage,
                     MediaKind.podcast.noEpisodesMessage]

        #expect(words.allSatisfy { !$0.lowercased().contains("saison") })
        #expect(words.allSatisfy { !$0.lowercased().contains("série") })
    }

    // Un podcast n'a pas de fin : écouter ce que son flux contient ne le termine pas.
    @Test func listeningToEverythingDoesNotFinishAPodcast() throws {
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        for number in 1...3 {
            context.insert(Episode(number: number, externalID: "guid-\(number)", season: season))
        }
        try context.save()
        for episode in season.orderedEpisodes {
            context.insert(try LogEntry.make(item: podcast, status: .done, episode: episode))
        }
        try context.save()
        #expect(WatchStatusUseCase.isFullyWatched(podcast, seasons: [SeasonSummary(number: 1, title: nil,
                                                                                   episodeCount: 3, airDate: nil)]) == false)
    }

    // La même règle, pour une série : là, tout écouter la termine bien.
    @Test func watchingEverythingStillFinishesASeries() throws {
        let context = container.mainContext
        let series = MediaItem(kind: .series, title: "Severance")
        context.insert(series)
        let season = try Season.make(number: 1, item: series)
        context.insert(season)
        for number in 1...3 { context.insert(Episode(number: number, season: season)) }
        try context.save()
        for episode in season.orderedEpisodes {
            context.insert(try LogEntry.make(item: series, status: .done, episode: episode))
        }
        try context.save()
        #expect(WatchStatusUseCase.isFullyWatched(series, seasons: [SeasonSummary(number: 1, title: nil,
                                                                                  episodeCount: 3, airDate: nil)]))
    }
}
