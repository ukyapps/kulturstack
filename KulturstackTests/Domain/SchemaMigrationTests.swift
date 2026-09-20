import Foundation
import SwiftData
import Testing
@testable import Kulturstack

struct SchemaMigrationTests {
    @Test @MainActor func storeCreatedWithV1SurvivesReopeningWithCurrentPlan() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let v1 = try ModelContainer(
                for: Schema(versionedSchema: KulturstackSchemaV1.self),
                configurations: ModelConfiguration(url: url)
            )
            let item = KulturstackSchemaV1.MediaItem(kind: .film, title: "Dune")
            let log = try KulturstackSchemaV1.LogEntry.make(item: item, status: .done, rating: 9)
            v1.mainContext.insert(item)
            v1.mainContext.insert(log)
            try v1.mainContext.save()
        }

        let current = try ModelContainerFactory.onDisk(url: url)
        let items = try current.mainContext.fetch(FetchDescriptor<MediaItem>())
        let logs = try current.mainContext.fetch(FetchDescriptor<LogEntry>())

        #expect(items.count == 1)
        #expect(items.first?.title == "Dune")
        #expect(logs.count == 1)
        #expect(logs.first?.rating == 9)
        #expect(logs.first?.item?.title == "Dune")
    }

    @Test func currentSchemaIsTheLastOfThePlan() {
        #expect(KulturstackMigrationPlan.schemas.last == KulturstackMigrationPlan.current)
        #expect(KulturstackMigrationPlan.current.versionIdentifier == KulturstackSchemaV1.versionIdentifier)
    }

    @Test @MainActor func externalRefKeyIsUnique() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let dune = MediaItem(kind: .film, title: "Dune")
        let other = MediaItem(kind: .film, title: "Autre")
        context.insert(dune)
        context.insert(other)
        context.insert(ExternalRef(provider: "tmdb", value: "movie:438631", item: dune))
        context.insert(ExternalRef(provider: "tmdb", value: "movie:438631", item: other))
        try context.save()

        let refs = try context.fetch(FetchDescriptor<ExternalRef>())
        #expect(refs.count == 1)
        #expect(refs.first?.key == "tmdb:movie:438631")
    }
}
