import Foundation
import SwiftData
import Testing
@testable import Kulturstack

struct DemoSeedTests {
    @Test @MainActor func fillTwiceGivesTheSameCounts() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let seed = DemoSeed(context: context)

        try seed.fill()
        let first = try counts(in: context)
        try seed.fill()
        let second = try counts(in: context)

        #expect(first.items > 0)
        #expect(first.logs > 0)
        #expect(first.refs > 0)
        // Les saisons et les épisodes comptent aussi : sans eux, « remplir » deux fois pourrait
        // les empiler sans que le test s'en aperçoive.
        #expect(first.seasons > 0)
        #expect(first.episodes > 0)
        #expect(first == second)
    }

    @Test @MainActor func wipeLeavesNothing() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let seed = DemoSeed(context: context)

        try seed.fill()
        try seed.wipe()

        #expect(try counts(in: context) == Counts(items: 0, logs: 0, refs: 0, seasons: 0, episodes: 0))
    }

    @Test @MainActor func seededLogsSpreadOverTheLastYear() throws {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context, now: now).fill()

        let logs = try context.fetch(FetchDescriptor<LogEntry>())
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now)!

        #expect(logs.allSatisfy { $0.date <= now && $0.date >= oneYearAgo })
        #expect(logs.contains { $0.rating != nil })
        #expect(logs.contains { $0.note != nil })
        #expect(logs.allSatisfy { $0.item != nil })
    }

    // Sans podcast, « Remplir données démo » ne montre pas la moitié de l'app : ni la liste
    // d'épisodes, ni le compteur « Podcasts » du Journal, ni le vocabulaire « écouté ».
    @Test @MainActor func theSeedContainsAPodcastWithItsEpisodes() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context).fill()

        let items = try context.fetch(FetchDescriptor<MediaItem>())
        let podcast = try #require(items.first { $0.kind == .podcast })

        #expect(podcast.seasons.flatMap(\.episodes).count >= 6)
        // Un podcast se range par année (#68) : il en faut au moins deux pour que ça se voie.
        let years = Set(podcast.seasons.flatMap(\.episodes).compactMap(\.airDate)
            .map { Calendar.current.component(.year, from: $0) })
        #expect(years.count >= 2)
        // Les épisodes de podcast portent l'identité de leur flux, pas leur position.
        #expect(podcast.seasons.flatMap(\.episodes).allSatisfy { $0.externalID?.isEmpty == false })
    }

    // Une série avec ses saisons, dont une commencée : c'est ce qui remplit l'onglet « En cours »
    // et la carte « prochain épisode ».
    @Test @MainActor func theSeedContainsASeriesStartedInTheMiddleOfASeason() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context).fill()

        let items = try context.fetch(FetchDescriptor<MediaItem>())
        let series = try #require(items.first { $0.kind == .series && $0.seasons.count >= 2 })
        let seasons = series.seasons.sorted { $0.number < $1.number }
        let first = try #require(seasons.first)
        let second = try #require(seasons.dropFirst().first)

        #expect(first.episodes.allSatisfy { !$0.logs.isEmpty })
        #expect(second.episodes.contains { !$0.logs.isEmpty })
        #expect(second.episodes.contains { $0.logs.isEmpty })
    }

    // Un épisode coché est un log qui porte son épisode **et** son œuvre : c'est ce qui le
    // distingue d'une ligne de Journal.
    @Test @MainActor func checkedEpisodesCarryTheirItem() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context).fill()

        let episodeLogs = try context.fetch(FetchDescriptor<LogEntry>()).filter { $0.episode != nil }

        #expect(episodeLogs.count >= 10)
        #expect(episodeLogs.allSatisfy { $0.item != nil && $0.status == .done })
        #expect(episodeLogs.allSatisfy { $0.episode?.season?.item?.id == $0.item?.id })
    }

    // Les compteurs du Journal n'affichent un type que s'il est loggé : « Podcasts · n »
    // n'apparaît que si le podcast du seed porte un log daté, pas une simple envie.
    @Test @MainActor func everyKindOfTheSeedHasAtLeastOneDatedLog() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context).fill()

        let logs = try context.fetch(FetchDescriptor<LogEntry>())
        let kinds = Set(logs.filter { $0.status != .wishlist && $0.episode == nil }.compactMap { $0.item?.kind })

        #expect(kinds.isSuperset(of: [.film, .series, .book, .podcast]))
    }

    private struct Counts: Equatable {
        let items: Int
        let logs: Int
        let refs: Int
        let seasons: Int
        let episodes: Int
    }

    @MainActor private func counts(in context: ModelContext) throws -> Counts {
        Counts(
            items: try context.fetchCount(FetchDescriptor<MediaItem>()),
            logs: try context.fetchCount(FetchDescriptor<LogEntry>()),
            refs: try context.fetchCount(FetchDescriptor<ExternalRef>()),
            seasons: try context.fetchCount(FetchDescriptor<Season>()),
            episodes: try context.fetchCount(FetchDescriptor<Episode>())
        )
    }
}
