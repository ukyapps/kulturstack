import Foundation

// « Les disques, je les écoute pas, je les ai dans ma bibliothèque » (founder, 17/10).
// Posséder est une relation à part : rien ici n'écrit de log, rien ici ne lit le Journal.
@MainActor
struct OwnershipUseCase {
    let repository: any MediaRepository

    // Deux appuis ne font pas deux exemplaires : le bouton de la fiche est une bascule, pas
    // un compteur. Le modèle, lui, sait en porter plusieurs — le vinyle et le CD viendront
    // avec le format, quand l'écran le demandera (ADR-017).
    func own(_ item: MediaItem) throws {
        guard !item.isOwned else { return }
        try repository.add(try OwnedCopy.make(item: item))
    }

    func disown(_ item: MediaItem) throws {
        guard item.isOwned else { return }
        try repository.delete(item.ownedCopies)
    }

    @discardableResult
    func toggle(_ item: MediaItem) throws -> Bool {
        if item.isOwned {
            try disown(item)
            return false
        }
        try own(item)
        return true
    }
}
