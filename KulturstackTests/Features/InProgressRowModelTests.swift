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

    // « Ça devrait afficher la saison suivante » (founder, 30/09). Une saison finie ne vide
    // pas la ligne : elle annonce la saison d'après, et le dit — « E1 » tout seul laisserait
    // croire qu'on recommence la série depuis le début.
    @Test func aFinishedSeasonAnnouncesTheNextOneWithItsNumber() throws {
        let item = try series(episodes: 3, watched: [1, 2, 3], season: 1)
        try item.setDetails(SeriesDetails(seasonCount: 2))

        let row = InProgressRowModel(item: item)

        let next = try #require(row.next)
        #expect((next.season, next.number) == (2, 1))
        // Comparer deux String(localized:) ne prouverait rien : si la clé n'existe pas, les
        // deux côtés rendent la clé et le test passe. On vérifie que la phrase est traduite.
        #expect(next.label.contains("S2"))
        #expect(next.label.contains("E1"))
        #expect(next.label == String(localized: "inprogress.next.season \(2) \(1)"))
    }

    // Dans la même saison, la ligne reste courte : la saison est déjà dans la progression.
    @Test func insideTheSameSeasonTheLineOnlyNamesTheEpisode() throws {
        let row = InProgressRowModel(item: try series(episodes: 3, watched: [1]))

        let next = try #require(row.next)
        #expect(next.label.contains("E2"))
        #expect(!next.label.contains("S2"))
        #expect(next.label == String(localized: "inprogress.next \(2)"))
    }

    // Une série finie pour de bon n'annonce rien : la ligne propose « Terminé ».
    @Test func theLastSeasonFinishedLeavesNoNextToAnnounce() throws {
        let item = try series(episodes: 3, watched: [1, 2, 3], season: 1)
        try item.setDetails(SeriesDetails(seasonCount: 1))

        #expect(InProgressRowModel(item: item).next == nil)
    }
}
