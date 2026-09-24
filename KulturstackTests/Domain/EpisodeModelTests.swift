import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct EpisodeModelTests {
    // Le conteneur doit vivre aussi longtemps que son contexte : un `inMemory().mainContext`
    // jeté dans une fonction laisse un contexte orphelin, et SwiftData s'arrête net.
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func store() -> ModelContext { container.mainContext }

    private func series(_ title: String = "Severance", in context: ModelContext) -> MediaItem {
        let item = MediaItem(kind: .series, title: title)
        context.insert(item)
        return item
    }

    private func season(_ number: Int, of item: MediaItem, in context: ModelContext) throws -> Season {
        let season = try Season.make(number: number, item: item)
        context.insert(season)
        return season
    }

    @Test func anEpisodeIsUniqueWithinItsSeason() throws {
        let context = store()
        let two = try season(2, of: series(in: context), in: context)
        context.insert(Episode(number: 4, title: "Woe's Hollow", season: two))
        context.insert(Episode(number: 4, title: "Doublon", season: two))
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Episode>()) == 1)
    }

    @Test func theSameEpisodeNumberLivesInTwoSeasons() throws {
        let context = store()
        let item = series(in: context)
        context.insert(Episode(number: 4, season: try season(1, of: item, in: context)))
        context.insert(Episode(number: 4, season: try season(2, of: item, in: context)))
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Episode>()) == 2)
    }

    @Test func aSeasonIsUniqueWithinItsWork() throws {
        let context = store()
        let item = series(in: context)
        _ = try season(1, of: item, in: context)
        _ = try season(1, of: item, in: context)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Season>()) == 1)
    }

    @Test func twoSeriesEachKeepTheirFirstSeason() throws {
        let context = store()
        _ = try season(1, of: series(in: context), in: context)
        _ = try season(1, of: series("Shogun", in: context), in: context)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Season>()) == 2)
    }

    @Test func aLogOnAnEpisodeCarriesItsWork() throws {
        let context = store()
        let item = series(in: context)
        let episode = Episode(number: 4, season: try season(2, of: item, in: context))
        context.insert(episode)
        context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        try context.save()

        let saved = try #require(try context.fetch(FetchDescriptor<LogEntry>()).first)
        #expect(saved.item?.title == "Severance")
        #expect(saved.episode?.number == 4)
        #expect(saved.episode?.season?.number == 2)
        #expect(item.logs.count == 1)
    }

    @Test func aLogCannotCarryAnEpisodeOfAnotherWork() throws {
        let context = store()
        let elsewhere = Episode(number: 1, season: try season(1, of: series("Shogun", in: context), in: context))
        context.insert(elsewhere)

        #expect(throws: DomainError.episodeNotOfThisItem) {
            try LogEntry.make(item: series(in: context), status: .done, episode: elsewhere)
        }
    }

    // Les saisons et les épisodes sont du cache TMDB ; un log est de la donnée utilisatrice.
    // Recharger une saison ne doit jamais effacer « j'ai vu cet épisode ».
    @Test func deletingAnEpisodeKeepsTheLogItCarried() throws {
        let context = store()
        let item = series(in: context)
        let episode = Episode(number: 4, season: try season(2, of: item, in: context))
        context.insert(episode)
        context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        try context.save()

        context.delete(episode)
        try context.save()

        let logs = try context.fetch(FetchDescriptor<LogEntry>())
        #expect(logs.count == 1)
        #expect(logs.first?.episode == nil)
        #expect(logs.first?.item?.title == "Severance")
    }

    @Test func deletingTheWorkTakesItsSeasonsAndEpisodes() throws {
        let context = store()
        let item = series(in: context)
        let two = try season(2, of: item, in: context)
        context.insert(Episode(number: 4, season: two))
        context.insert(Episode(number: 5, season: two))
        try context.save()

        context.delete(item)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Season>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Episode>()) == 0)
    }

    @Test func aSeasonKnowsItsEpisodesInOrder() throws {
        let context = store()
        let item = series(in: context)
        let two = try season(2, of: item, in: context)
        context.insert(Episode(number: 5, season: two))
        context.insert(Episode(number: 4, season: two))
        try context.save()

        #expect(two.orderedEpisodes.map(\.number) == [4, 5])
        #expect(item.orderedSeasons.map(\.number) == [2])
    }

    @Test func onlyAWorkWithEpisodesGetsSeasons() throws {
        let context = store()
        let film = MediaItem(kind: .film, title: "Dune")
        context.insert(film)

        #expect(throws: DomainError.seasonsNotAllowed(for: .film)) { try Season.make(number: 1, item: film) }
    }
}
