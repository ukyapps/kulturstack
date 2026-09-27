import SwiftData

enum KulturstackMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [KulturstackSchemaV1.self, KulturstackSchemaV2.self, KulturstackSchemaV3.self]
    }

    static var stages: [MigrationStage] { [v1ToV2, v2ToV3] }

    static var current: any VersionedSchema.Type { KulturstackSchemaV3.self }

    // On ajoute deux modèles et un lien optionnel ; rien d'existant ne change de forme.
    private static let v1ToV2 = MigrationStage.lightweight(
        fromVersion: KulturstackSchemaV1.self,
        toVersion: KulturstackSchemaV2.self
    )

    // On ajoute un champ optionnel à Episode ; la clé des épisodes de séries ne change pas,
    // donc aucune ligne existante n'est réécrite.
    private static let v2ToV3 = MigrationStage.lightweight(
        fromVersion: KulturstackSchemaV2.self,
        toVersion: KulturstackSchemaV3.self
    )
}
