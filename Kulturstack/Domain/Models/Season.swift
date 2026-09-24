import Foundation
import SwiftData

extension KulturstackSchemaV2 {
    @Model
    final class Season {
        @Attribute(.unique) var key: String
        var number: Int
        var title: String?
        var item: MediaItem?

        @Relationship(deleteRule: .cascade, inverse: \Episode.season) var episodes: [Episode]

        private init(number: Int, title: String?, item: MediaItem) {
            self.key = Self.key(itemID: item.id, number: number)
            self.number = number
            self.title = title
            self.item = item
            self.episodes = []
        }

        static func make(number: Int, title: String? = nil, item: MediaItem) throws -> Season {
            guard item.kind.hasEpisodes else { throw DomainError.seasonsNotAllowed(for: item.kind) }
            return Season(number: number, title: title, item: item)
        }

        // Même mécanique que ExternalRef.key : une clé unique, donc pas de saison en double.
        static func key(itemID: UUID, number: Int) -> String { "\(itemID.uuidString):s\(number)" }

        var orderedEpisodes: [Episode] { episodes.sorted { $0.number < $1.number } }
    }
}
