import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct EditLogUseCaseTests {
    private func makeLog(kind: MediaKind = .film) throws -> (ModelContainer, LogEntry, EditLogUseCase) {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: kind, title: "Dune", year: 2021)
        context.insert(item)
        let log = try LogEntry.make(item: item, status: .done)
        context.insert(log)
        try context.save()
        return (container, log, EditLogUseCase(repository: SwiftDataLogRepository(context: context)))
    }

    @Test func findsALogByItsID() throws {
        let (container, log, useCase) = try makeLog()

        #expect(try useCase.log(id: log.id)?.id == log.id)
        #expect(try useCase.log(id: UUID()) == nil)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<LogEntry>()) == 1)
    }

    @Test func updatePersistsDateStatusRatingAndNote() throws {
        let (container, log, useCase) = try makeLog()
        let yesterday = Date.now.addingTimeInterval(-86_400)

        try useCase.update(log, date: yesterday, status: .wishlist, rating: 7, note: "  Superbe  ")

        let saved = try #require(try useCase.log(id: log.id))
        #expect(saved.date == yesterday)
        #expect(saved.status == .wishlist)
        #expect(saved.rating == 7)
        #expect(saved.note == "Superbe")
        #expect(container.mainContext.hasChanges == false)
    }

    @Test func blankNoteIsStoredAsNothing() throws {
        let (container, log, useCase) = try makeLog()
        log.note = "avant"

        try useCase.update(log, date: log.date, status: .done, rating: nil, note: "   \n")

        #expect(log.note == nil)
        #expect(log.rating == nil)
        withExtendedLifetime(container) {}
    }

    @Test func updateRefusesAStatusTheKindDoesNotAllow() throws {
        let (container, log, useCase) = try makeLog(kind: .film)

        #expect(throws: DomainError.statusNotAllowed(.inProgress, for: .film)) {
            try useCase.update(log, date: log.date, status: .inProgress, rating: nil, note: nil)
        }
        #expect(log.status == .done)
        withExtendedLifetime(container) {}
    }

    @Test func updateRefusesARatingOutOfRange() throws {
        let (container, log, useCase) = try makeLog()

        #expect(throws: DomainError.ratingOutOfRange(11)) {
            try useCase.update(log, date: log.date, status: .done, rating: 11, note: nil)
        }
        #expect(log.rating == nil)
        withExtendedLifetime(container) {}
    }

    @Test func deleteRemovesTheLogButKeepsTheItem() throws {
        let (container, log, useCase) = try makeLog()
        let context = container.mainContext

        try useCase.delete(log)

        #expect(try context.fetchCount(FetchDescriptor<LogEntry>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<MediaItem>()) == 1)
    }
}
