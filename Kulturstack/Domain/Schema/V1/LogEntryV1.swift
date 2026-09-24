import Foundation
import SwiftData

extension KulturstackSchemaV1 {
    @Model
    final class LogEntry {
        @Attribute(.unique) var id: UUID
        var date: Date
        var statusRaw: String
        var rating: Int?
        var note: String?
        var source: String
        var createdAt: Date
        var item: MediaItem?

        init(item: MediaItem, status: LogStatus, date: Date = .now, rating: Int? = nil,
             note: String? = nil, source: String = "manual") {
            self.id = UUID()
            self.date = date
            self.statusRaw = status.rawValue
            self.rating = rating
            self.note = note
            self.source = source
            self.createdAt = .now
            self.item = item
        }
    }
}
