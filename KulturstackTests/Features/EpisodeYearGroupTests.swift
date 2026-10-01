import Foundation
import SwiftData
import Testing
@testable import Kulturstack

// « Dans les podcasts, ça s'organise pas par saison ? On pourrait le faire par année »
// (founder, 30/09). Les épisodes arrivent du plus ancien au plus récent : les années sortent
// dans le même sens, sans que rien ne soit réordonné.
@MainActor
struct EpisodeYearGroupTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func rows(_ dates: [Date?]) throws -> [EpisodeRowModel] {
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        for (index, date) in dates.enumerated() {
            context.insert(Episode(number: index + 1, title: "Épisode \(index + 1)", airDate: date,
                                   externalID: "guid-\(index + 1)", season: season))
        }
        try context.save()
        return season.orderedEpisodes.map(EpisodeRowModel.init)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func consecutiveYearsBecomeGroupsInOrder() throws {
        let groups = EpisodeYearGroup.group(try rows([day(2024, 3, 1), day(2024, 11, 2),
                                                      day(2025, 1, 5), day(2026, 9, 23)]))

        #expect(groups.map(\.year) == [2024, 2025, 2026])
        #expect(groups.map(\.rows.count) == [2, 1, 1])
        #expect(groups[0].title == "2024")
    }

    @Test func oneYearAloneMakesOneGroup() throws {
        let groups = EpisodeYearGroup.group(try rows([day(2026, 1, 1), day(2026, 6, 1)]))

        #expect(groups.count == 1)
        #expect(groups[0].rows.count == 2)
    }

    // Un épisode sans date reste à sa place plutôt que d'être relégué en bas d'une liste
    // qu'il traverse : c'est sa position dans le flux qui a un sens, pas son absence de date.
    @Test func anUndatedEpisodeKeepsItsPlace() throws {
        let groups = EpisodeYearGroup.group(try rows([day(2024, 3, 1), nil, day(2025, 1, 5)]))

        #expect(groups.map(\.year) == [2024, nil, 2025])
        #expect(groups[1].title == String(localized: "podcast.episodes.undated"))
    }

    @Test func noEpisodeMeansNoGroup() throws {
        #expect(EpisodeYearGroup.group([]).isEmpty)
    }

    // Deux tranches de la même année séparées par un trou sans date restent deux groupes :
    // on découpe là où l'année change, on ne rassemble jamais par-dessus la liste.
    @Test func theSameYearOnBothSidesOfAGapStaysTwoGroups() throws {
        let groups = EpisodeYearGroup.group(try rows([day(2026, 1, 1), nil, day(2026, 12, 1)]))

        #expect(groups.map(\.year) == [2026, nil, 2026])
    }

    // Une année se lit comme une saison : combien sur combien, et finie ou non.
    @Test func aYearReportsItsProgressLikeASeason() throws {
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        for (index, date) in [day(2025, 1, 5), day(2025, 6, 1), day(2026, 2, 2)].enumerated() {
            context.insert(Episode(number: index + 1, title: "Épisode \(index + 1)", airDate: date,
                                   externalID: "guid-\(index + 1)", season: season))
        }
        try context.save()
        let first = try #require(season.orderedEpisodes.first)
        context.insert(try LogEntry.make(item: podcast, status: .done, episode: first))
        try context.save()

        let groups = EpisodeYearGroup.group(season.orderedEpisodes.map(EpisodeRowModel.init))

        #expect(groups.map(\.year) == [2025, 2026])
        #expect(groups[0].watchedCount == 1)
        #expect(groups[0].isComplete == false)
        #expect(groups[0].progress == String(localized: "podcast.year.progress \(1) \(2)"))
        #expect(groups[1].progress == String(localized: "detail.episodes \(1)"))
    }

    @Test func aYearEntirelyListenedIsComplete() throws {
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        for index in 1...2 {
            context.insert(Episode(number: index, airDate: day(2025, index, 1),
                                   externalID: "guid-\(index)", season: season))
        }
        try context.save()
        for episode in season.orderedEpisodes {
            context.insert(try LogEntry.make(item: podcast, status: .done, episode: episode))
        }
        try context.save()

        let groups = EpisodeYearGroup.group(season.orderedEpisodes.map(EpisodeRowModel.init))

        #expect(groups.count == 1)
        #expect(groups[0].isComplete)
    }
}
