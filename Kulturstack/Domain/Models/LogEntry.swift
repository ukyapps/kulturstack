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

        private init(item: MediaItem, status: LogStatus, date: Date, rating: Int?, note: String?, source: String) {
            self.id = UUID()
            self.date = date
            self.statusRaw = status.rawValue
            self.rating = rating
            self.note = note
            self.source = source
            self.createdAt = .now
            self.item = item
        }

        static func make(item: MediaItem, status: LogStatus, date: Date = .now, rating: Int? = nil,
                         note: String? = nil, source: String = "manual") throws -> LogEntry {
            try LogRules.validate(status: status, for: item.kind)
            try LogRules.validate(rating: rating)
            return LogEntry(item: item, status: status, date: date, rating: rating, note: note, source: source)
        }

        var status: LogStatus {
            get { LogStatus(rawValue: statusRaw) ?? .done }
            set { statusRaw = newValue.rawValue }
        }
    }
}
