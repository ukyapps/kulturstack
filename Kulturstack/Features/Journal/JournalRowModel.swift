import Foundation

struct JournalRowModel: Identifiable, Equatable {
    let id: UUID
    let itemID: UUID?
    let kind: MediaKind
    let title: String
    let subtitle: String
    let date: Date
    let status: LogStatus
    let rating: Int?
    let coverURL: URL?
    let symbol: String

    init(log: LogEntry) {
        let kind = log.item?.kind ?? .film
        id = log.id
        itemID = log.item?.id
        self.kind = kind
        title = log.item?.title ?? ""
        subtitle = Self.subtitle(kind: kind, year: log.item?.year, creator: log.item?.creators.first)
        date = log.date
        status = log.status
        rating = log.rating
        coverURL = log.item?.coverURL
        symbol = kind.symbol
    }

    private static func subtitle(kind: MediaKind, year: Int?, creator: String?) -> String {
        let yearText = year.map(String.init)
        let detail = kind == .book ? (creator ?? yearText) : (yearText ?? creator)
        guard let detail else { return kind.label }
        return String(localized: "journal.row.subtitle \(kind.label) \(detail)")
    }
}
