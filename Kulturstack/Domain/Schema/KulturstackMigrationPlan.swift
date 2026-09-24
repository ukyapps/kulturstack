import SwiftData

enum KulturstackMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [KulturstackSchemaV1.self, KulturstackSchemaV2.self] }
    static var stages: [MigrationStage] { [v1ToV2] }

    static var current: any VersionedSchema.Type { KulturstackSchemaV2.self }

    // On ajoute deux modèles et un lien optionnel ; rien d'existant ne change de forme.
    private static let v1ToV2 = MigrationStage.lightweight(
        fromVersion: KulturstackSchemaV1.self,
        toVersion: KulturstackSchemaV2.self
    )
}
