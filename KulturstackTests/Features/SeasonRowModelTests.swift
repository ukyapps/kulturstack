import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct SeasonRowModelTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func season(_ number: Int, episodes: Int, watched: Int) throws -> Season {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: number, item: item)
        context.insert(season)
        for index in 1...max(episodes, 1) where episodes > 0 {
            let episode = Episode(number: index, season: season)
            context.insert(episode)
            if index <= watched { context.insert(try LogEntry.make(item: item, status: .done, episode: episode)) }
        }
        try context.save()
        return season
    }

    @Test func aSeasonNotYetOpenedCountsWhatTheSourceAnnounces() {
        let row = SeasonRowModel(summary: SeasonSummary(number: 2, title: nil, episodeCount: 10, airDate: nil), season: nil)

        #expect(row.episodeCount == 10)
        #expect(row.watchedCount == 0)
        #expect(row.isComplete == false)
        #expect(row.title == String(localized: "series.season \(2)"))
    }

    @Test func anOpenedSeasonCountsWhatItReallyHolds() throws {
        let stored = try season(1, episodes: 3, watched: 2)

        let row = SeasonRowModel(summary: SeasonSummary(number: 1, title: nil, episodeCount: 10, airDate: nil), season: stored)

        #expect(row.episodeCount == 3)
        #expect(row.watchedCount == 2)
        #expect(row.progress == String(localized: "series.season.progress \(2) \(3)"))
    }

    @Test func aSeasonWithNothingWatchedShowsItsCount() {
        let row = SeasonRowModel(summary: SeasonSummary(number: 1, title: nil, episodeCount: 9, airDate: nil), season: nil)

        #expect(row.progress == String(localized: "detail.episodes \(9)"))
    }

    @Test func aFullyWatchedSeasonIsComplete() throws {
        let stored = try season(1, episodes: 2, watched: 2)

        let row = SeasonRowModel(summary: SeasonSummary(number: 1, title: nil, episodeCount: 2, airDate: nil), season: stored)

        #expect(row.isComplete)
    }

    // Une saison annoncée sans épisode n'est pas une saison terminée.
    @Test func aSeasonWithoutEpisodeIsNotComplete() {
        let row = SeasonRowModel(summary: SeasonSummary(number: 5, title: nil, episodeCount: 0, airDate: nil), season: nil)

        #expect(row.isComplete == false)
    }

    @Test func theSpecialsCarryTheirOwnNameNotTheOneFromTheSource() {
        let row = SeasonRowModel(
            summary: SeasonSummary(number: 0, title: "Season 0", episodeCount: 39, airDate: nil, isSpecials: true),
            season: nil)

        #expect(row.isSpecials)
        #expect(row.title == String(localized: "series.specials"))
    }

    @Test func aSeasonNamedBySourceKeepsThatName() {
        let row = SeasonRowModel(
            summary: SeasonSummary(number: 1, title: "Les origines", episodeCount: 9, airDate: nil), season: nil)

        #expect(row.title == "Les origines")
    }
}
