import Foundation

// « Pour les podcasts, je voudrais que chaque année soit traitée comme une saison, avec
// l'option tout cocher, et qu'on puisse dérouler et replier » (founder, 01/10).
//
// Un flux n'a ni saison ni numéro stable. L'année de diffusion est le seul découpage qu'il
// porte, et il le porte toujours : elle tient donc lieu de saison — repliable, cochable
// d'un bloc, avec sa progression, exactement comme une saison de série.
struct EpisodeYearGroup: Identifiable, Equatable {
    let year: Int?
    let rows: [EpisodeRowModel]

    var id: Int { year ?? 0 }
    var title: String { year.map(String.init) ?? String(localized: "podcast.episodes.undated") }

    var watchedCount: Int { rows.filter(\.isWatched).count }
    var isComplete: Bool { !rows.isEmpty && watchedCount == rows.count }

    var progress: String {
        watchedCount == 0
            ? String(localized: "detail.episodes \(rows.count)")
            : String(localized: "podcast.year.progress \(watchedCount) \(rows.count)")
    }

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
