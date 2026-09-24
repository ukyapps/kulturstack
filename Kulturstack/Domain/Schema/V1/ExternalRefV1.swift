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
            self.key = "\(provider):\(value)"
            self.item = item
        }
    }
}
