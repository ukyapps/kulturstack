import Foundation
import SwiftData

enum KulturstackSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MediaItem.self, ExternalRef.self, LogEntry.self]
    }
}
