import SwiftData

extension KulturstackSchemaV2 {
    @Model
    final class Season {
        @Attribute(.unique) var key: String
        var number: Int
        var title: String?
        var item: MediaItem?

        @Relationship(deleteRule: .cascade, inverse: \Episode.season) var episodes: [Episode]

        init(key: String, number: Int, title: String? = nil, item: MediaItem) {
            self.key = key
            self.number = number
            self.title = title
            self.item = item
            self.episodes = []
        }
    }
}
