import Foundation
import SwiftData

// Copie figée du modèle tel qu'il était en V1 — elle décrit la base déjà installée sur
// l'iPhone de la founder. On ne la modifie plus : c'est contre elle que T-01 migre.
// Seules les propriétés stockées comptent ici ; les règles et le confort vivent dans la V2.
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
            self.detailsVersion = 1
            self.detailsData = nil
            self.createdAt = .now
            self.updatedAt = .now
            self.externalRefs = []
            self.logs = []
        }
    }
}
