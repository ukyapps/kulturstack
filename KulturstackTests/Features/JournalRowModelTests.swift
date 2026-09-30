import Foundation
import SwiftData
import Testing
@testable import Kulturstack

struct JournalRowModelTests {
    @Test @MainActor func bookShowsItsAuthor() throws {
        let (container, log) = try makeLog(kind: .book, year: 1965, creators: ["Frank Herbert"])
        withExtendedLifetime(container) {
            let model = JournalRowModel(log: log)
            #expect(model.subtitle.contains("Frank Herbert"))
            #expect(!model.subtitle.contains("1965"))
            #expect(model.symbol == MediaKind.book.symbol)
        }
    }

    @Test @MainActor func filmShowsItsYear() throws {
        let (container, log) = try makeLog(kind: .film, year: 2021, creators: ["Denis Villeneuve"])
        withExtendedLifetime(container) {
            let model = JournalRowModel(log: log)
            #expect(model.subtitle.contains("2021"))
            #expect(!model.subtitle.contains("Villeneuve"))
        }
    }

    @Test @MainActor func fallsBackToTheOtherDetailThenToKindAlone() throws {
        let (container, bare) = try makeLog(kind: .film, year: nil, creators: [])
        let (_, creatorOnly) = try makeLog(kind: .film, year: nil, creators: ["Céline Sciamma"], in: container)
        withExtendedLifetime(container) {
            #expect(JournalRowModel(log: bare).subtitle == MediaKind.film.label)
            #expect(JournalRowModel(log: creatorOnly).subtitle.contains("Céline Sciamma"))
        }
    }

    @Test @MainActor func carriesTheLogFields() throws {
        let (container, log) = try makeLog(kind: .series, year: 2022, creators: [], status: .inProgress, rating: 7)
        withExtendedLifetime(container) {
            let model = JournalRowModel(log: log)
            #expect(model.title == "Titre")
            #expect(model.status == .inProgress)
            #expect(model.rating == 7)
            #expect(model.date == log.date)
            #expect(model.coverURL == URL(string: "https://example.com/cover.jpg"))
        }
    }

    @Test @MainActor func carriesTheCommentAndIgnoresABlankOne() throws {
        let (container, log) = try makeLog(kind: .film, year: 2021, creators: [])

        log.note = "Vu au cinéma, la copie restaurée"
        #expect(JournalRowModel(log: log).note == "Vu au cinéma, la copie restaurée")

        log.note = "   \n "
        #expect(JournalRowModel(log: log).note == nil)

        log.note = nil
        #expect(JournalRowModel(log: log).note == nil)
        withExtendedLifetime(container) {}
    }

    @Test @MainActor func aTapOpensTheWorkAndAnOrphanLogFallsBackToEditing() throws {
        let (container, log) = try makeLog(kind: .film, year: 2021, creators: [])
        let itemID = try #require(log.item?.id)

        #expect(JournalRowModel(log: log).tapAction == .showItem(itemID))
        #expect(JournalRowModel(log: log).tapAction.hint != JournalRowTap.edit(log.id).hint)

        log.item = nil

        #expect(JournalRowModel(log: log).tapAction == .edit(log.id))
        withExtendedLifetime(container) {}
    }

    @MainActor private func makeLog(kind: MediaKind, year: Int?, creators: [String], status: LogStatus = .done,
                                    rating: Int? = nil, in existing: ModelContainer? = nil) throws -> (ModelContainer, LogEntry) {
        let container = try existing ?? ModelContainerFactory.inMemory()
        let item = MediaItem(kind: kind, title: "Titre", year: year, creators: creators,
                             coverURL: URL(string: "https://example.com/cover.jpg"))
        container.mainContext.insert(item)
        let log = try LogEntry.make(item: item, status: status, rating: rating)
        container.mainContext.insert(log)
        return (container, log)
    }

    // MARK: - Le prochain épisode dans le Journal (retour du 27/09)

    @MainActor
    private func startedSeries(episodes count: Int, watched: [Int], in container: ModelContainer) throws -> MediaItem {
        let context = container.mainContext
        let item = MediaItem(kind: .series, title: "Severance")
        context.insert(item)
        let season = try Season.make(number: 2, item: item)
        context.insert(season)
        for number in 1...count { context.insert(Episode(number: number, season: season)) }
        try context.save()
        for episode in season.orderedEpisodes where watched.contains(episode.number) {
            context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        context.insert(try LogEntry.make(item: item, status: .inProgress,
                                         source: WatchStatusUseCase.automaticSource))
        try context.save()
        return item
    }

    @MainActor
    @Test func theLineOfASeriesInProgressCarriesItsProgressAndItsNext() throws {
        let container = try ModelContainerFactory.inMemory()
        let item = try startedSeries(episodes: 10, watched: [1, 2, 3], in: container)
        let statusLog = try #require(WatchStatusUseCase.statusLog(of: item))

        let watch = try #require(JournalRowModel(log: statusLog).watch)

        #expect(watch.position?.position == 3)
        #expect(watch.position?.total == 10)
        #expect(watch.next?.number == 4)
        withExtendedLifetime(container) {}
    }

    // Un épisode coché ne crée pas de ligne : c'est la ligne de statut qui porte le bouton,
    // sinon la même série s'avancerait depuis dix endroits différents.
    @MainActor
    @Test func onlyTheStatusLineCarriesTheButton() throws {
        let container = try ModelContainerFactory.inMemory()
        let item = try startedSeries(episodes: 5, watched: [1], in: container)
        let context = container.mainContext
        let older = try LogEntry.make(item: item, status: .inProgress,
                                      date: Date(timeIntervalSince1970: 1), source: WatchStatusUseCase.automaticSource)
        context.insert(older)
        try context.save()

        #expect(JournalRowModel(log: older).watch == nil)
        withExtendedLifetime(container) {}
    }

    @MainActor
    @Test func aFilmLineCarriesNothingToCheck() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let film = MediaItem(kind: .film, title: "La Planète sauvage")
        context.insert(film)
        let log = try LogEntry.make(item: film, status: .done)
        context.insert(log)
        try context.save()

        #expect(JournalRowModel(log: log).watch == nil)
        withExtendedLifetime(container) {}
    }

    // Une série terminée ou abandonnée n'a plus de suite à cocher depuis le Journal.
    @MainActor
    @Test func aFinishedSeriesCarriesNothing() throws {
        let container = try ModelContainerFactory.inMemory()
        let item = try startedSeries(episodes: 3, watched: [1, 2, 3], in: container)
        let context = container.mainContext
        let done = try LogEntry.make(item: item, status: .done)
        context.insert(done)
        try context.save()

        #expect(JournalRowModel(log: done).watch == nil)
        withExtendedLifetime(container) {}
    }
}
