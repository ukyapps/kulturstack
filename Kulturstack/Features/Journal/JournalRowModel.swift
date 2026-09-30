import Foundation

struct JournalRowModel: Identifiable, Equatable {
    let id: UUID
    let itemID: UUID?
    let kind: MediaKind
    let title: String
    let subtitle: String
    let date: Date
    // Deux logs du même jour se départagent à l'écriture : sans ça, la ligne montrerait
    // n'importe lequel des deux, et c'est exactement ce qui arrive quand on note une série
    // puis qu'on coche un épisode dans la foulée.
    let createdAt: Date
    let status: LogStatus
    let rating: Int?
    let note: String?
    let coverURL: URL?
    let symbol: String
    // Combien de fois l'œuvre a été consommée. Passer de « en cours » à « terminé » n'est pas
    // un deuxième visionnage : seuls les logs qui disent qu'on l'a finie comptent.
    let timesSeen: Int
    // Combien de logs cette ligne représente. Au-delà d'un, on ne modifie plus depuis la
    // ligne — la fiche les montre tous, et c'est là qu'on choisit lequel toucher.
    let logCount: Int
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
        createdAt = log.createdAt
        status = log.status
        rating = log.rating
        note = Self.comment(log.note)
        coverURL = log.item?.coverURL
        symbol = kind.symbol
        timesSeen = log.status == .done ? 1 : 0
        logCount = 1
        watch = Self.watch(log: log)
    }

    // « Une œuvre = une seule fiche dans le journal » (founder, 30/09). Le log le plus récent
    // parle — sa date, son statut, sa progression —, les autres lui prêtent ce qu'il n'a pas :
    // une note et un commentaire écrits la semaine dernière ne disparaissent pas parce qu'on
    // a coché un épisode ce soir.
    init?(group: [JournalRowModel]) {
        let rows = group.sorted(by: Self.newestFirst)
        guard let latest = rows.first else { return nil }
        id = latest.id
        itemID = latest.itemID
        kind = latest.kind
        title = latest.title
        subtitle = latest.subtitle
        date = latest.date
        createdAt = latest.createdAt
        status = latest.status
        rating = rows.compactMap(\.rating).first
        note = rows.compactMap(\.note).first
        coverURL = latest.coverURL
        symbol = latest.symbol
        timesSeen = rows.reduce(0) { $0 + $1.timesSeen }
        logCount = rows.reduce(0) { $0 + $1.logCount }
        watch = latest.watch
    }

    static func newestFirst(_ lhs: JournalRowModel, _ rhs: JournalRowModel) -> Bool {
        (lhs.date, lhs.createdAt) > (rhs.date, rhs.createdAt)
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
