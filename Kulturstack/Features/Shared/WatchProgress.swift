import Foundation

// Où on en est dans une œuvre suivie épisode par épisode : la position dans la saison en
// cours et l'épisode suivant. Le même objet sert à l'onglet « En cours », au Journal et à la
// fiche — il n'y a qu'une définition de « la suite » dans l'app, c'est la règle de la PR 16.
//
// Une série et un podcast ne se reprennent pas par le même bout, donc ne se racontent pas
// pareil : une série dit « S2 · E4 sur 10 » et sa barre se remplit vers la fin ; un podcast
// n'a pas de fin, il dit combien d'épisodes on a écoutés et lequel écouter maintenant.
struct WatchProgress: Equatable {
    struct Position: Equatable {
        let season: Int
        let position: Int
        let total: Int

        var fraction: Double { total > 0 ? Double(position) / Double(total) : 0 }
        var label: String { String(localized: "inprogress.progress \(season) \(position) \(total)") }
    }

    struct Next: Equatable {
        let season: Int
        let number: Int
        let label: String
    }

    // La barre et sa position : une série seulement. Un éditeur tronque son flux quand il
    // veut — le nombre d'épisodes d'un podcast ne veut rien dire, une barre dessus mentirait.
    let position: Position?
    // Ce que la ligne raconte à la place de la barre : « 12 épisodes écoutés ».
    let summary: String?
    let next: Next?

    // Rien de commencé et rien à suivre : il n'y a pas de progression, pas même vide.
    init?(item: MediaItem) {
        guard item.kind.hasEpisodes else { return nil }
        let followed = item.kind.isFollowedInOrder
        let seen = followed ? InProgressUseCase.lastWatched(of: item).flatMap(Self.position) : nil
        position = seen
        summary = followed ? nil : Self.listened(item)
        next = InProgressUseCase.nextUp(for: item).map {
            Next(season: $0.season, number: $0.number,
                 label: Self.label(for: $0, of: item, after: seen?.season))
        }
        if position == nil && summary == nil && next == nil { return nil }
    }

    // Un épisode de podcast ne montre pas son rang : il change à chaque publication du flux.
    // C'est son titre qui le désigne, comme sur sa fiche depuis la #51.
    private static func label(for next: InProgressUseCase.NextUp, of item: MediaItem,
                              after season: Int?) -> String {
        guard item.kind.isFollowedInOrder else {
            return next.episode?.title ?? String(localized: "inprogress.next \(next.number)")
        }
        // Quand la suite change de saison, « E1 » tout seul laisserait croire qu'on recommence.
        guard next.season != season else { return String(localized: "inprogress.next \(next.number)") }
        return String(localized: "inprogress.next.season \(next.season) \(next.number)")
    }

    private static func listened(_ item: MediaItem) -> String? {
        let count = item.orderedSeasons.flatMap(\.orderedEpisodes).filter(\.isWatched).count
        guard count > 0 else { return nil }
        return String(localized: "inprogress.listened \(count)")
    }

    private static func position(_ episode: Episode) -> Position? {
        guard let season = episode.season, !season.episodes.isEmpty else { return nil }
        return Position(season: season.number, position: episode.number, total: season.episodes.count)
    }
}
