import Foundation
import SwiftData

// V4 — « Ma bibliothèque ». `OwnedCopy` est une **deuxième relation à l'œuvre**, à côté des
// logs : on peut posséder sans avoir consommé, consommer sans posséder, ou les deux (ADR-010).
// La founder, le 17/10 : « les disques, je les écoute pas, je les ai dans ma bibliothèque ».
enum KulturstackSchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [MediaItem.self, ExternalRef.self, LogEntry.self, Season.self, Episode.self, OwnedCopy.self]
    }
}

typealias MediaItem = KulturstackSchemaV4.MediaItem
typealias ExternalRef = KulturstackSchemaV4.ExternalRef
typealias LogEntry = KulturstackSchemaV4.LogEntry
typealias Season = KulturstackSchemaV4.Season
typealias Episode = KulturstackSchemaV4.Episode
typealias OwnedCopy = KulturstackSchemaV4.OwnedCopy
