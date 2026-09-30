import Foundation

// « Dans les podcasts, ça s'organise pas par saison ? On pourrait le faire par année quand
// c'est pas rangé par saison » (founder, 30/09). Un flux n'a ni saison ni numéro : l'année de
// diffusion est le seul repère qu'il donne, et il le donne toujours.
struct EpisodeYearGroup: Identifiable, Equatable {
    let year: Int?
    let rows: [EpisodeRowModel]

    var id: Int { year ?? 0 }
    var title: String { year.map(String.init) ?? String(localized: "podcast.episodes.undated") }

    // Les épisodes arrivent déjà dans l'ordre de la liste — du plus ancien au plus récent.
    // On découpe là où l'année change, sans jamais réordonner : un épisode sans date reste
    // à sa place plutôt que d'être relégué en bas d'une liste qu'il traverse.
    static func group(_ rows: [EpisodeRowModel]) -> [EpisodeYearGroup] {
        var groups: [EpisodeYearGroup] = []
        for row in rows {
            if let last = groups.last, last.year == row.year {
                groups[groups.count - 1] = EpisodeYearGroup(year: last.year, rows: last.rows + [row])
            } else {
                groups.append(EpisodeYearGroup(year: row.year, rows: [row]))
            }
        }
        return groups
    }
}
