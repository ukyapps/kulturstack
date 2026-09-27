import Foundation
import SwiftData
import Testing
@testable import Kulturstack

// Retour du 27/09 : « quand je clique sur la série pour mettre l'épisode d'après on voit à
// peine que j'ai cliqué… si je misclick je m'en rends pas compte ». La barre qui se remplit
// dit la même chose que le texte de la ligne, en une image.
@MainActor
struct InProgressRowModelTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func series(episodes count: Int, watched: [Int], season number: Int = 2) throws -> MediaItem {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: number, item: item)
        context.insert(season)
        for episode in 1...count { context.insert(Episode(number: episode, season: season)) }
        try context.save()
        for episode in season.orderedEpisodes where watched.contains(episode.number) {
            context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        try context.save()
        return item
    }

    @Test func theBarFollowsWhatTheLineSays() throws {
        let row = InProgressRowModel(item: try series(episodes: 10, watched: [1, 2, 3, 4]))

        let progress = try #require(row.progress)
        #expect((progress.position, progress.total) == (4, 10))
        #expect(progress.fraction == 0.4)
        #expect(row.detail == String(localized: "inprogress.progress \(2) \(4) \(10)"))
    }

    // Un épisode sauté ne fait pas reculer la barre : elle dit où on en est, pas combien on a vu.
    @Test func aSkippedEpisodeDoesNotEmptyTheBar() throws {
        let row = InProgressRowModel(item: try series(episodes: 10, watched: [1, 2, 4]))

        let progress = try #require(row.progress)
        #expect((progress.position, progress.total) == (4, 10))
    }

    @Test func aFinishedSeasonFillsTheBar() throws {
        let row = InProgressRowModel(item: try series(episodes: 3, watched: [1, 2, 3]))

        #expect(try #require(row.progress).fraction == 1)
    }

    @Test func aSeriesWithoutACheckedEpisodeHasNoBar() throws {
        #expect(InProgressRowModel(item: try series(episodes: 5, watched: [])).progress == nil)
    }

    // Un livre n'a pas de progression connue : pas de barre plutôt qu'une barre vide.
    @Test func aBookHasNoBar() throws {
        let book = MediaItem(kind: .book, title: "Piranesi")
        container.mainContext.insert(book)
        try container.mainContext.save()

        #expect(InProgressRowModel(item: book).progress == nil)
    }
}
