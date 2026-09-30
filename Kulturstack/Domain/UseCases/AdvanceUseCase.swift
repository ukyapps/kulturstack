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
    func advance(itemID: UUID, now: Date = .now) async throws -> Bool {
        guard let item = try media.find(itemID: itemID),
              let next = InProgressUseCase.nextUp(for: item) else { return false }
        guard let episode = try await episode(next, of: item) else { return false }
        try episodes.toggle(episode, of: item, now: now)
        try status.refreshAfterChecking(item, now: now)
        return true
    }

    // La suite est dans une saison jamais ouverte : c'est le seul moment où avancer va
    // chercher quelque chose à la source. Une saison que la source ne connaît pas n'écrit rien.
    private func episode(_ next: InProgressUseCase.NextUp, of item: MediaItem) async throws -> Episode? {
        if let known = next.episode { return known }
        return try await episodes.openSeason(next.season, of: item)?.orderedEpisodes.first
    }
}
