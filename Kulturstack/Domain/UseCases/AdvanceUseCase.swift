import Foundation

// Cocher la suite d'une œuvre sans ouvrir sa fiche. Le ✓ de l'onglet « En cours » et celui
// d'une ligne du Journal passent par ici : un seul chemin, donc une seule façon d'avancer.
@MainActor
struct AdvanceUseCase {
    let media: any MediaRepository
    let episodes: EpisodeUseCase
    let status: WatchStatusUseCase

    // Rend « faux » quand il n'y avait rien à cocher : une série au bout de ce qu'on connaît
    // d'elle n'est pas une erreur, elle n'a simplement pas de suite.
    @discardableResult
    func advance(itemID: UUID, now: Date = .now) throws -> Bool {
        guard let item = try media.find(itemID: itemID),
              let next = InProgressUseCase.next(for: item) else { return false }
        try episodes.toggle(next, of: item, now: now)
        try status.refreshAfterChecking(item, now: now)
        return true
    }
}
