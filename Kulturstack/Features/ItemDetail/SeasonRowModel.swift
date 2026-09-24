import Foundation

struct SeasonRowModel: Identifiable, Equatable {
    let number: Int
    let title: String
    let episodeCount: Int
    let watchedCount: Int
    let isSpecials: Bool

    var id: Int { number }

    // Une saison sans épisode annoncé n'est pas une saison terminée.
    var isComplete: Bool { episodeCount > 0 && watchedCount == episodeCount }

    var progress: String {
        watchedCount == 0
            ? String(localized: "detail.episodes \(episodeCount)")
            : String(localized: "series.season.progress \(watchedCount) \(episodeCount)")
    }

    init(summary: SeasonSummary, season: Season?) {
        let episodes = season?.orderedEpisodes ?? []
        number = summary.number
        isSpecials = summary.isSpecials
        // Tant que la saison n'est pas dépliée, c'est la source qui dit combien elle compte.
        episodeCount = episodes.isEmpty ? summary.episodeCount : episodes.count
        watchedCount = episodes.filter(\.isWatched).count
        title = summary.isSpecials
            ? String(localized: "series.specials")
            : summary.title ?? String(localized: "series.season \(summary.number)")
    }
}
