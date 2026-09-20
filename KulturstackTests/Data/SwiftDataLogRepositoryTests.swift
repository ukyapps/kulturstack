import Foundation
import SwiftData
import Testing
@testable import Kulturstack

struct SwiftDataLogRepositoryTests {
    @Test @MainActor func fetchAllReturnsLogsNewestFirst() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .film, title: "Dune")
        context.insert(item)
        for days in [3, 1, 2] {
            let date = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
            context.insert(try LogEntry.make(item: item, status: .done, date: date))
        }
        try context.save()

        let logs = try await SwiftDataLogRepository(context: context).fetchAll()

        #expect(logs.count == 3)
        #expect(logs.map(\.date) == logs.map(\.date).sorted(by: >))
    }

    @Test @MainActor func fetchAllOnEmptyStoreReturnsNothing() async throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext

        let logs = try await SwiftDataLogRepository(context: context).fetchAll()

        #expect(logs.isEmpty)
    }
}
