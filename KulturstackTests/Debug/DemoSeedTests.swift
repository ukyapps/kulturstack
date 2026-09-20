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
        #expect(first == second)
    }

    @Test @MainActor func wipeLeavesNothing() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let seed = DemoSeed(context: context)

        try seed.fill()
        try seed.wipe()

        #expect(try counts(in: context) == Counts(items: 0, logs: 0, refs: 0))
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

    private struct Counts: Equatable {
        let items: Int
        let logs: Int
        let refs: Int
    }

    @MainActor private func counts(in context: ModelContext) throws -> Counts {
        Counts(
            items: try context.fetchCount(FetchDescriptor<MediaItem>()),
            logs: try context.fetchCount(FetchDescriptor<LogEntry>()),
            refs: try context.fetchCount(FetchDescriptor<ExternalRef>())
        )
    }
}
