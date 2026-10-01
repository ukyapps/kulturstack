import Foundation
import SwiftData

extension KulturstackSchemaV3 {
    @Model
    final class Episode {
        @Attribute(.unique) var key: String
        var number: Int
        var title: String?
        var airDate: Date?
        var runtimeMinutes: Int?
        // L'identité d'un épisode de podcast. Un numéro de position ne tient pas : les flux
        // RSS sont tronqués par leurs éditeurs, et tout se décalerait sous les coches.
        // Les épisodes de séries n'en ont pas : TMDB les numérote, c'est stable.
        var externalID: String?
        var season: Season?

        // Un épisode est du cache TMDB, un log est de la donnée utilisatrice : recharger
        // une saison détache les logs, ça ne les efface pas.
        @Relationship(deleteRule: .nullify, inverse: \LogEntry.episode) var logs: [LogEntry]

        init(number: Int, title: String? = nil, airDate: Date? = nil,
             runtimeMinutes: Int? = nil, externalID: String? = nil, season: Season) {
            self.key = Self.key(seasonKey: season.key, number: number, externalID: externalID)
            self.number = number
            self.title = title
            self.airDate = airDate
            self.runtimeMinutes = runtimeMinutes
            self.externalID = externalID
            self.season = season
            self.logs = []
        }

        // Un épisode qui porte une identité de source est reconnu par elle ; sinon par son
        // numéro, comme avant la V3 — les clés des séries déjà en base ne bougent pas.
        static func key(seasonKey: String, number: Int, externalID: String? = nil) -> String {
            guard let externalID else { return "\(seasonKey):e\(number)" }
            return "\(seasonKey):g\(externalID)"
        }

        // Coché = il existe un log « vu » qui porte cet épisode.
        var isWatched: Bool { logs.contains { $0.status == .done } }

        // L'année de diffusion. Un flux de podcast n'a ni saison ni numéro stable : c'est par
        // l'année que ses épisodes se rangent, et c'est elle qui tient lieu de saison à l'écran.
        var year: Int? { airDate.map { Calendar.current.component(.year, from: $0) } }
    }
}
