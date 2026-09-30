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
    let note: String?
    let coverURL: URL?
    let symbol: String
    // « Le prochain épisode dans le journal aussi, comme dans en cours » (founder, 27/09).
    // Une série n'a qu'une ligne dans le Journal — celle de son statut : c'est là que la
    // suite se coche, et nulle part ailleurs, sinon la même série s'avancerait à dix endroits.
    let watch: WatchProgress?

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
        note = Self.comment(log.note)
        coverURL = log.item?.coverURL
        symbol = kind.symbol
        watch = Self.watch(log: log)
    }

    private static func watch(log: LogEntry) -> WatchProgress? {
        guard log.status == .inProgress, let item = log.item,
              WatchStatusUseCase.statusLog(of: item)?.id == log.id else { return nil }
        return WatchProgress(item: item)
    }

    private static func comment(_ note: String?) -> String? {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty ?? true) ? nil : trimmed
    }

    var tapAction: JournalRowTap {
        if let itemID { .showItem(itemID) } else { .edit(id) }
    }

    private static func subtitle(kind: MediaKind, year: Int?, creator: String?) -> String {
        let yearText = year.map(String.init)
        let detail = kind == .book ? (creator ?? yearText) : (yearText ?? creator)
        guard let detail else { return kind.label }
        return String(localized: "journal.row.subtitle \(kind.label) \(detail)")
    }
}
