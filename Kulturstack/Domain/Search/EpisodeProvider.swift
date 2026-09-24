import Foundation

// Ce qu'une source sait dire du découpage d'une série. Des valeurs, pas des modèles :
// le Domain ne dépend de rien, et ce qui est persisté est décidé ailleurs.
struct SeasonSummary: Sendable, Equatable, Identifiable {
    let number: Int
    let title: String?
    let episodeCount: Int
    let airDate: Date?
    // Le tiroir à making-of et bonus : il se coche, mais il n'est jamais « la suite ».
    let isSpecials: Bool

    init(number: Int, title: String?, episodeCount: Int, airDate: Date?, isSpecials: Bool = false) {
        self.number = number
        self.title = title
        self.episodeCount = episodeCount
        self.airDate = airDate
        self.isSpecials = isSpecials
    }

    var id: Int { number }
}

struct EpisodeSummary: Sendable, Equatable, Identifiable {
    let number: Int
    let title: String?
    let airDate: Date?
    let runtimeMinutes: Int?

    var id: Int { number }
}

protocol EpisodeProvider: Sendable {
    // Une clé qui n'est pas de ma forme ne déclenche aucune requête : liste vide.
    func seasons(forKey key: String) async throws -> [SeasonSummary]
    func episodes(forKey key: String, season: Int) async throws -> [EpisodeSummary]
}
