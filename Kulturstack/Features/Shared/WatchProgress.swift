import Foundation

// Où on en est dans une œuvre suivie épisode par épisode : la position dans la saison en
// cours et l'épisode suivant. Le même objet sert à l'onglet « En cours », au Journal et à la
// fiche — il n'y a qu'une définition de « la suite » dans l'app, c'est la règle de la PR 16.
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
        // Quand la suite change de saison, « E1 » tout seul laisserait croire qu'on
        // recommence la série : la ligne dit alors la saison aussi.
        let showsSeason: Bool

        var label: String {
            showsSeason
                ? String(localized: "inprogress.next.season \(season) \(number)")
                : String(localized: "inprogress.next \(number)")
        }
    }

    let position: Position?
    let next: Next?

    // Rien de commencé et rien à suivre : il n'y a pas de progression, pas même vide.
    init?(item: MediaItem) {
        guard item.kind.hasEpisodes else { return nil }
        let seen = InProgressUseCase.lastWatched(of: item).flatMap(Self.position)
        position = seen
        next = InProgressUseCase.nextUp(for: item).map {
            Next(season: $0.season, number: $0.number, showsSeason: $0.season != seen?.season)
        }
        if position == nil && next == nil { return nil }
    }

    private static func position(_ episode: Episode) -> Position? {
        guard let season = episode.season, !season.episodes.isEmpty else { return nil }
        return Position(season: season.number, position: episode.number, total: season.episodes.count)
    }
}
