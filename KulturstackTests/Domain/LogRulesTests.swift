import Foundation
import Testing
@testable import Kulturstack

struct LogRulesTests {
    @Test func statusNotAllowedForKindIsRejected() {
        #expect(throws: DomainError.statusNotAllowed(.inProgress, for: .film)) {
            try LogRules.validate(status: .inProgress, for: .film)
        }
    }

    @Test func allowedStatusPasses() throws {
        try LogRules.validate(status: .inProgress, for: .book)
        try LogRules.validate(status: .done, for: .concert)
    }

    @Test(arguments: [0, 11, -3])
    func ratingOutOfRangeIsRejected(rating: Int) {
        #expect(throws: DomainError.ratingOutOfRange(rating)) {
            try LogRules.validate(rating: rating)
        }
    }

    @Test(arguments: [1, 5, 10])
    func ratingInRangePasses(rating: Int) throws {
        try LogRules.validate(rating: rating)
    }

    @Test func nilRatingIsAccepted() throws {
        try LogRules.validate(rating: nil)
    }

    @Test @MainActor func logCreatedWithoutDateIsStampedNow() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .film, title: "Dune")
        context.insert(item)

        let before = Date()
        let log = try LogEntry.make(item: item, status: .done)
        context.insert(log)
        let after = Date()

        #expect(log.date >= before && log.date <= after)
        #expect(log.status == .done)
        #expect(log.source == "manual")
    }

    @Test @MainActor func makeRefusesInvalidStatusForItemKind() throws {
        let container = try ModelContainerFactory.inMemory()
        let item = MediaItem(kind: .exhibition, title: "Rothko")
        container.mainContext.insert(item)

        #expect(throws: DomainError.statusNotAllowed(.dropped, for: .exhibition)) {
            try LogEntry.make(item: item, status: .dropped)
        }
    }
}
