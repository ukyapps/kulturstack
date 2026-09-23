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
}
