import Foundation
import SwiftData

extension KulturstackSchemaV1 {
    @Model
    final class MediaItem {
        @Attribute(.unique) var id: UUID
        var kindRaw: String
        var title: String
        var originalTitle: String?
        var year: Int?
        var creators: [String]
        var summary: String?
        var coverURL: URL?
        var detailsVersion: Int
        var detailsData: Data?
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \ExternalRef.item) var externalRefs: [ExternalRef]
        @Relationship(deleteRule: .cascade, inverse: \LogEntry.item) var logs: [LogEntry]

        init(kind: MediaKind, title: String, originalTitle: String? = nil, year: Int? = nil,
             creators: [String] = [], summary: String? = nil, coverURL: URL? = nil) {
            self.id = UUID()
            self.kindRaw = kind.rawValue
            self.title = title
            self.originalTitle = originalTitle
            self.year = year
            self.creators = creators
            self.summary = summary
            self.coverURL = coverURL
            self.detailsVersion = DetailsCodec.currentVersion
            self.detailsData = nil
            self.createdAt = .now
            self.updatedAt = .now
            self.externalRefs = []
            self.logs = []
        }

        var kind: MediaKind {
            get { MediaKind(rawValue: kindRaw) ?? .film }
            set { kindRaw = newValue.rawValue }
        }

        var details: (any DetailsPayload)? {
            guard let detailsData else { return nil }
            return try? DetailsCodec.decode(kind: kind, from: detailsData)
        }

        func setDetails(_ payload: some DetailsPayload) throws {
            detailsData = try DetailsCodec.encode(payload)
            detailsVersion = DetailsCodec.currentVersion
            updatedAt = .now
        }
    }
}
