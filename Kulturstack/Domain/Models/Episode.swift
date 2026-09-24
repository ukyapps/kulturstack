import Foundation
import SwiftData

extension KulturstackSchemaV2 {
    @Model
    final class Episode {
        @Attribute(.unique) var key: String
        var number: Int
        var title: String?
        var airDate: Date?
        var runtimeMinutes: Int?
        var season: Season?

        // Un épisode est du cache TMDB, un log est de la donnée utilisatrice : recharger
        // une saison détache les logs, ça ne les efface pas.
        @Relationship(deleteRule: .nullify, inverse: \LogEntry.episode) var logs: [LogEntry]

        init(number: Int, title: String? = nil, airDate: Date? = nil,
             runtimeMinutes: Int? = nil, season: Season) {
            self.key = Self.key(seasonKey: season.key, number: number)
            self.number = number
            self.title = title
            self.airDate = airDate
            self.runtimeMinutes = runtimeMinutes
            self.season = season
            self.logs = []
        }

        static func key(seasonKey: String, number: Int) -> String { "\(seasonKey):e\(number)" }
    }
}
