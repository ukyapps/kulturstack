import Foundation
import Observation

@MainActor @Observable
final class InProgressViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([InProgressRowModel])
        case failed
    }

    private(set) var state: State = .loading
    // Le retour haptique suit le **geste**, pas la donnée. Attaché à une valeur affichée, il
    // ne se déclenchait pas quand la ligne disparaissait (dernier épisode, série terminée)
    // ni sur un podcast, qui n'a pas de barre de progression (founder, 03/10).
    private(set) var feedback = 0
    var didFailToAdvance = false

    private let useCase: InProgressUseCase
    private let repository: any MediaRepository
    private let status: WatchStatusUseCase
    private let advanceUseCase: AdvanceUseCase

    init(useCase: InProgressUseCase, repository: any MediaRepository,
         advance: AdvanceUseCase, status: WatchStatusUseCase) {
        self.useCase = useCase
        self.repository = repository
        self.advanceUseCase = advance
        self.status = status
    }

    func load() async {
        do {
            let items = try await useCase.items()
            state = items.isEmpty ? .empty : .loaded(items.map(InProgressRowModel.init))
        } catch {
            state = .failed
        }
    }

    // Le ✓ coche la suite, une seule : il ne comble pas ce qui a été sauté derrière.
    // Le Journal fait la même chose par le même chemin.
    func advance(_ row: InProgressRowModel) async {
        do {
            // Le retour haptique suit ce qui a **vraiment** été coché : une œuvre au bout de
            // ce qu'on connaît d'elle n'est pas une erreur, mais ce n'est pas un succès non plus.
            if try await advanceUseCase.advance(itemID: row.itemID) { feedback += 1 }
            didFailToAdvance = false
        } catch {
            didFailToAdvance = true
        }
        await load()
    }

    func finish(_ row: InProgressRowModel) async {
        await change(row) { try status.finish($0) }
    }

    private func change(_ row: InProgressRowModel, _ action: (MediaItem) throws -> Void) async {
        do {
            if let item = try repository.find(itemID: row.itemID) {
                try action(item)
                feedback += 1
            }
            didFailToAdvance = false
        } catch {
            didFailToAdvance = true
        }
        await load()
    }
}
