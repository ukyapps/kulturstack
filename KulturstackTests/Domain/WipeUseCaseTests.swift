import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct WipeUseCaseTests {
    private func counts(_ context: ModelContext) throws -> (Int, Int, Int, Int, Int) {
        (try context.fetchCount(FetchDescriptor<MediaItem>()),
         try context.fetchCount(FetchDescriptor<LogEntry>()),
         try context.fetchCount(FetchDescriptor<ExternalRef>()),
         try context.fetchCount(FetchDescriptor<Season>()),
         try context.fetchCount(FetchDescriptor<Episode>()))
    }

    @Test func wipeLeavesNothingBehind() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context).fill()
        let series = MediaItem(kind: .series, title: "Severance")
        context.insert(series)
        let season = try Season.make(number: 2, item: series)
        context.insert(season)
        context.insert(Episode(number: 4, season: season))
        try context.save()
        #expect(try counts(context) != (0, 0, 0, 0, 0))

        try WipeUseCase(repository: SwiftDataMediaRepository(context: context)).wipe()

        #expect(try counts(context) == (0, 0, 0, 0, 0))
        #expect(context.hasChanges == false)
    }

    @Test func wipeOnAnEmptyStoreIsFine() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext

        try WipeUseCase(repository: SwiftDataMediaRepository(context: context)).wipe()

        #expect(try counts(context) == (0, 0, 0, 0, 0))
    }
}
