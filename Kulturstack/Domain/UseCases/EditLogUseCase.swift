import Foundation

@MainActor
struct EditLogUseCase {
    let repository: any LogRepository

    func log(id: UUID) throws -> LogEntry? {
        try repository.find(id: id)
    }

    func update(_ log: LogEntry, date: Date, status: LogStatus, rating: Int?, note: String?) throws {
        try LogRules.validate(status: status, for: log.item?.kind ?? .film)
        try LogRules.validate(rating: rating)
        log.date = date
        log.status = status
        log.rating = rating
        log.note = LogRules.note(note)
        try repository.save()
    }

    func delete(_ log: LogEntry) throws {
        try repository.delete(log)
    }

}
