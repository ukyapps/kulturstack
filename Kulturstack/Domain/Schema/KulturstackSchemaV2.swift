import Foundation
import SwiftData

// V2 — saisons et épisodes. Version figée : les modèles vivants sont ceux de la V3.
enum KulturstackSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MediaItem.self, ExternalRef.self, LogEntry.self, Season.self, Episode.self]
    }
}
