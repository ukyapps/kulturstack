import Foundation
import SwiftData

// V3 — l'identité d'un épisode de podcast. Les types courants de l'app sont ceux-ci : les
// typealias ci-dessous font que le reste du code ne connaît jamais de numéro de version.
enum KulturstackSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MediaItem.self, ExternalRef.self, LogEntry.self, Season.self, Episode.self]
    }
}

typealias MediaItem = KulturstackSchemaV3.MediaItem
typealias ExternalRef = KulturstackSchemaV3.ExternalRef
typealias LogEntry = KulturstackSchemaV3.LogEntry
typealias Season = KulturstackSchemaV3.Season
typealias Episode = KulturstackSchemaV3.Episode
