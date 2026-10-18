import Foundation
import SwiftData

extension KulturstackSchemaV3 {
    @Model
    final class Season {
        @Attribute(.unique) var key: String
        var number: Int
        var title: String?
        var item: MediaItem?

        @Relationship(deleteRule: .cascade, inverse: \Episode.season) var episodes: [Episode]

        init(number: Int, title: String? = nil, item: MediaItem) {
            self.key = "\(item.id.uuidString):s\(number)"
            self.number = number
            self.title = title
            self.item = item
            self.episodes = []
        }
    }
}
