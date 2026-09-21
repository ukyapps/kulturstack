import Foundation
import Observation

@MainActor @Observable
final class LogEditViewModel {
    enum State: Equatable {
        case loading
        case ready
        case missing
        case failed
    }

    private(set) var state: State = .loading
    private(set) var title = ""
    private(set) var allowedStatuses: [LogStatus] = []
    private(set) var didFail = false
    var date = Date.now
    var status = LogStatus.done
    var rating: Int?
    var note = ""

    let logID: UUID
    private let useCase: EditLogUseCase
    private var log: LogEntry?

    init(logID: UUID, useCase: EditLogUseCase) {
        self.logID = logID
        self.useCase = useCase
    }

    func load() {
        do {
            guard let log = try useCase.log(id: logID) else {
                state = .missing
                return
            }
            self.log = log
            title = Self.title(of: log.item)
            allowedStatuses = (log.item?.kind ?? .film).allowedStatuses
            date = log.date
            status = log.status
            rating = log.rating
            note = log.note ?? ""
            state = .ready
        } catch {
            state = .failed
        }
    }

    func apply(_ shortcut: DateShortcut, now: Date = .now) {
        date = shortcut.date(now: now)
    }

    func save() -> Bool {
        guard let log else { return false }
        do {
            try useCase.update(log, date: date, status: status, rating: rating, note: note)
            didFail = false
            return true
        } catch {
            didFail = true
            return false
        }
    }

    func delete() -> Bool {
        guard let log else { return false }
        do {
            try useCase.delete(log)
            didFail = false
            return true
        } catch {
            didFail = true
            return false
        }
    }

    private static func title(of item: MediaItem?) -> String {
        guard let item else { return "" }
        guard let year = item.year else { return item.title }
        return String(localized: "log.edit.work \(item.title) \(String(year))")
    }
}
