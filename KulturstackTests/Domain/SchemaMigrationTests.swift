import Foundation
import SwiftData
import Testing
@testable import Kulturstack

struct SchemaMigrationTests {
    // T-01 : la base de la founder contient ses vrais logs depuis le 23/09. Une migration
    // ne se teste pas à vide — on écrit un store V1 peuplé, puis on le rouvre avec le plan.
    @Test @MainActor func storeCreatedWithV1SurvivesReopeningWithCurrentPlan() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("migration-\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let v1 = try ModelContainer(
                for: Schema(versionedSchema: KulturstackSchemaV1.self),
                configurations: ModelConfiguration(url: url)
            )
            let dune = KulturstackSchemaV1.MediaItem(kind: .film, title: "Dune")
            let severance = KulturstackSchemaV1.MediaItem(kind: .series, title: "Severance")
            v1.mainContext.insert(dune)
            v1.mainContext.insert(severance)
            v1.mainContext.insert(KulturstackSchemaV1.ExternalRef(provider: "tmdb", value: "movie:438631", item: dune))
            v1.mainContext.insert(KulturstackSchemaV1.LogEntry(item: dune, status: .done, rating: 9, note: "Enfin vu."))
            v1.mainContext.insert(KulturstackSchemaV1.LogEntry(item: severance, status: .inProgress))
            try v1.mainContext.save()
        }

        let current = try ModelContainerFactory.onDisk(url: url)
        let items = try current.mainContext.fetch(FetchDescriptor<MediaItem>(sortBy: [SortDescriptor(\.title)]))
        let logs = try current.mainContext.fetch(FetchDescriptor<LogEntry>())
        let refs = try current.mainContext.fetch(FetchDescriptor<ExternalRef>())

        #expect(items.map(\.title) == ["Dune", "Severance"])
        #expect(refs.first?.key == "tmdb:movie:438631")
        #expect(refs.first?.item?.title == "Dune")
        #expect(logs.count == 2)
        #expect(logs.first(where: { $0.rating == 9 })?.note == "Enfin vu.")
        #expect(logs.contains { $0.status == .inProgress })
        // Le champ ajouté par la V2 existe et ne casse rien : il est simplement vide.
        #expect(logs.allSatisfy { $0.episode == nil })
        #expect(try current.mainContext.fetchCount(FetchDescriptor<Season>()) == 0)
        #expect(try current.mainContext.fetchCount(FetchDescriptor<Episode>()) == 0)
    }

    @Test func currentSchemaIsTheLastOfThePlan() {
        #expect(KulturstackMigrationPlan.schemas.count == 2)
        #expect(KulturstackMigrationPlan.schemas.last == KulturstackMigrationPlan.current)
        #expect(KulturstackMigrationPlan.current.versionIdentifier == KulturstackSchemaV2.versionIdentifier)
        #expect(KulturstackMigrationPlan.stages.count == 1)
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
