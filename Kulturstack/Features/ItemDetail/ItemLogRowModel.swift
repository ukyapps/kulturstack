import Foundation

struct ItemLogRowModel: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let status: LogStatus
    let rating: Int?
    let note: String?

    init(log: LogEntry) {
        id = log.id
        date = log.date
        status = log.status
        rating = log.rating
        note = log.note
    }
}
