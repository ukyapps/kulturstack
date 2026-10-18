import Foundation
import Observation

@MainActor @Observable
final class LibraryViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([LibraryRowModel])
        case failed
    }

    private(set) var state: State = .loading
    var didFailToRemove = false
    // Le retour haptique suit le geste, pas la donnée (founder, 03/10).
    private(set) var feedback = 0

    private let repository: any MediaRepository
    private let ownership: OwnershipUseCase

    init(repository: any MediaRepository) {
        self.repository = repository
        ownership = OwnershipUseCase(repository: repository)
    }

    #if DEBUG
    // Le dépôt en mémoire ne tombe pas en panne : l'état d'erreur ne se rend pas autrement.
    func failForTesting() { state = .failed }
    #endif

    func load() async {
        do {
            let rows = try repository.ownedItems().map(LibraryRowModel.init)
            state = rows.isEmpty ? .empty : .loaded(rows)
        } catch {
            state = .failed
        }
    }

    // Retirer de la bibliothèque n'efface pas l'œuvre ni ses logs : on cesse de la posséder,
    // on ne l'oublie pas.
    func remove(itemID: UUID) async {
        do {
            guard let item = try repository.find(itemID: itemID) else { return }
            try ownership.disown(item)
            didFailToRemove = false
            feedback += 1
            await load()
        } catch {
            didFailToRemove = true
        }
    }
}
