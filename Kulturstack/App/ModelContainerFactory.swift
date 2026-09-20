import Foundation
import SwiftData

enum ModelContainerFactory {
    static var schema: Schema { Schema(versionedSchema: KulturstackMigrationPlan.current) }

    static func production() throws -> ModelContainer {
        try make(ModelConfiguration("Kulturstack", schema: schema))
    }

    static func onDisk(url: URL) throws -> ModelContainer {
        try make(ModelConfiguration(schema: schema, url: url))
    }

    static func inMemory() throws -> ModelContainer {
        try make(ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }

    private static func make(_ configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(for: schema, migrationPlan: KulturstackMigrationPlan.self, configurations: configuration)
    }
}
