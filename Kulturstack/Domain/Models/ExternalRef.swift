import SwiftData

extension KulturstackSchemaV1 {
    @Model
    final class ExternalRef {
        @Attribute(.unique) var key: String
        var provider: String
        var value: String
        var item: MediaItem?

        init(provider: String, value: String, item: MediaItem? = nil) {
            self.provider = provider
            self.value = value
            self.key = Self.key(provider: provider, value: value)
            self.item = item
        }

        static func key(provider: String, value: String) -> String { "\(provider):\(value)" }
    }
}
