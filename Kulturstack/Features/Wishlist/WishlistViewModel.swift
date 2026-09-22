import Foundation
import Observation

@MainActor @Observable
final class WishlistViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([JournalRowModel])
        case failed
    }

    private(set) var state: State = .loading
    var didFailToDelete = false
    var didFailToMarkSeen = false
    private let repository: any LogRepository
    private let editUseCase: EditLogUseCase
    private let logUseCase: LogUseCase

    init(repository: any LogRepository, logUseCase: LogUseCase) {
        self.repository = repository
        self.logUseCase = logUseCase
        editUseCase = EditLogUseCase(repository: repository)
    }

    func load() async {
        do {
            let wishes = StatsUseCase.pendingWishes(try await repository.fetchAll().map(JournalRowModel.init))
            state = wishes.isEmpty ? .empty : .loaded(wishes)
        } catch {
            state = .failed
        }
    }

    // « Je l'ai vu » ajoute un log terminé ; l'envie reste dans l'historique de la fiche (ADR-006).
    func markSeen(id: UUID) async {
        do {
            guard let wish = try editUseCase.log(id: id), let item = wish.item else { return }
            try logUseCase.logAgain(item)
            await load()
        } catch {
            didFailToMarkSeen = true
        }
    }

    func delete(id: UUID) async {
        do {
            guard let log = try editUseCase.log(id: id) else { return }
            try editUseCase.delete(log)
            await load()
        } catch {
            didFailToDelete = true
        }
    }
}
