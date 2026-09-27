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

        @Relationship(deleteRule: .nullify, inverse: \LogEntry.episode) var logs: [LogEntry]

        init(key: String, number: Int, title: String? = nil, airDate: Date? = nil,
             runtimeMinutes: Int? = nil, season: Season) {
            self.key = key
            self.number = number
            self.title = title
            self.airDate = airDate
            self.runtimeMinutes = runtimeMinutes
            self.season = season
            self.logs = []
        }
    }
}
