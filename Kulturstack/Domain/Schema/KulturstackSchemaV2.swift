import Foundation
import SwiftData

// V2 — saisons et épisodes. Les types courants de l'app sont ceux-ci : les typealias
// ci-dessous font que le reste du code ne connaît jamais de numéro de version.
enum KulturstackSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MediaItem.self, ExternalRef.self, LogEntry.self, Season.self, Episode.self]
    }
}

typealias MediaItem = KulturstackSchemaV2.MediaItem
typealias ExternalRef = KulturstackSchemaV2.ExternalRef
typealias LogEntry = KulturstackSchemaV2.LogEntry
typealias Season = KulturstackSchemaV2.Season
typealias Episode = KulturstackSchemaV2.Episode
