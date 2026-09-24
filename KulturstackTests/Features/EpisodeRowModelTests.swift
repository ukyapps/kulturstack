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
