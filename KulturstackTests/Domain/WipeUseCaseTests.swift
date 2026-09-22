import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct WipeUseCaseTests {
    private func counts(_ context: ModelContext) throws -> (Int, Int, Int) {
        (try context.fetchCount(FetchDescriptor<MediaItem>()),
         try context.fetchCount(FetchDescriptor<LogEntry>()),
         try context.fetchCount(FetchDescriptor<ExternalRef>()))
    }

    @Test func wipeLeavesNothingBehind() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        try DemoSeed(context: context).fill()
        #expect(try counts(context) != (0, 0, 0))

        try WipeUseCase(repository: SwiftDataMediaRepository(context: context)).wipe()

        #expect(try counts(context) == (0, 0, 0))
        #expect(context.hasChanges == false)
    }

    @Test func wipeOnAnEmptyStoreIsFine() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext

        try WipeUseCase(repository: SwiftDataMediaRepository(context: context)).wipe()

        #expect(try counts(context) == (0, 0, 0))
    }
}
