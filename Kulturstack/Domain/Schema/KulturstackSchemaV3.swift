import Foundation
import SwiftData

// V3 — l'identité d'un épisode de podcast. Version figée : les modèles vivants sont ceux
// de la V4.
enum KulturstackSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MediaItem.self, ExternalRef.self, LogEntry.self, Season.self, Episode.self]
    }
}
