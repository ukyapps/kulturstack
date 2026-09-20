import SwiftData

enum KulturstackMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [KulturstackSchemaV1.self] }
    static var stages: [MigrationStage] { [] }

    static var current: any VersionedSchema.Type { KulturstackSchemaV1.self }
}
