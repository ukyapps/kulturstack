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

    // Créer un log demande plus que le modifier : l'œuvre visée et de quoi l'enregistrer.
    private struct Creation {
        let target: LogTarget
        let repository: any MediaRepository
        let logUseCase: LogUseCase
    }

    private(set) var state: State = .loading
    private(set) var title = ""
    private(set) var itemID: UUID?
    private(set) var allowedStatuses: [LogStatus] = []
    private(set) var didFail = false
    var date = Date.now
    var status = LogStatus.done
    var rating: Int?
    var note = ""

    private let logID: UUID?
    private let useCase: EditLogUseCase
    private let creation: Creation?
    private var log: LogEntry?

    var isCreating: Bool { creation != nil }

    init(logID: UUID, useCase: EditLogUseCase) {
        self.logID = logID
        self.useCase = useCase
        creation = nil
    }

    init(target: LogTarget, useCase: EditLogUseCase, repository: any MediaRepository, logUseCase: LogUseCase) {
        logID = nil
        self.useCase = useCase
        creation = Creation(target: target, repository: repository, logUseCase: logUseCase)
    }

    func load() {
        do {
            if let creation {
                try prepare(creation)
            } else {
                try fill()
            }
        } catch {
            state = .failed
        }
    }

    func apply(_ shortcut: DateShortcut, now: Date = .now) {
        date = shortcut.date(now: now)
    }

    func save() -> Bool {
        do {
            if let creation {
                try create(creation)
            } else {
                guard let log else { return false }
                try useCase.update(log, date: date, status: status, rating: rating, note: note)
            }
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

    private func fill() throws {
        guard let logID, let log = try useCase.log(id: logID) else {
            state = .missing
            return
        }
        self.log = log
        title = Self.title(log.item?.title, year: log.item?.year)
        itemID = log.item?.id
        allowedStatuses = (log.item?.kind ?? .film).allowedStatuses
        date = log.date
        status = log.status
        rating = log.rating
        note = log.note ?? ""
        state = .ready
    }

    // Un formulaire vierge : rien n'est écrit tant qu'on n'a pas enregistré.
    private func prepare(_ creation: Creation) throws {
        switch creation.target {
        case .item(let id):
            guard let item = try creation.repository.find(itemID: id) else {
                state = .missing
                return
            }
            itemID = item.id
            title = Self.title(item.title, year: item.year)
            allowedStatuses = item.kind.allowedStatuses
        case .candidate(let candidate):
            title = Self.title(candidate.title, year: candidate.year)
            allowedStatuses = candidate.kind.allowedStatuses
        }
        state = .ready
    }

    private func create(_ creation: Creation) throws {
        switch creation.target {
        case .item(let id):
            guard let item = try creation.repository.find(itemID: id) else { throw DomainError.itemNotFound }
            try creation.logUseCase.log(item, status: status, date: date, rating: rating, note: note)
        case .candidate(let candidate):
            try creation.logUseCase.logNow(candidate, status: status, now: date, rating: rating, note: note)
        }
    }

    private static func title(_ title: String?, year: Int?) -> String {
        guard let title else { return "" }
        guard let year else { return title }
        return String(localized: "log.edit.work \(title) \(String(year))")
    }
}
