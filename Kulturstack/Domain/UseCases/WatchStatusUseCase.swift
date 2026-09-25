import Foundation

@MainActor
struct WatchStatusUseCase {
    // Ce que cocher a posé tout seul, par opposition à ce que la founder a dit elle-même.
    static let automaticSource = "episodes"

    let log: LogUseCase
    let edit: EditLogUseCase

    // Le statut d'une œuvre, c'est son dernier log qui parle d'elle : une envie n'en est pas un,
    // un épisode coché non plus.
    static func status(of item: MediaItem) -> LogStatus? { statusLog(of: item)?.status }

    static func statusLog(of item: MediaItem) -> LogEntry? {
        item.logs
            .filter { $0.episode == nil && $0.status != .wishlist }
            .max { ($0.date, $0.createdAt) < ($1.date, $1.createdAt) }
    }

    static func hasWatchedEpisodes(_ item: MediaItem) -> Bool {
        item.logs.contains { $0.episode != nil && $0.status == .done }
    }

    // Le dernier épisode de la dernière saison, spéciaux exclus : un bonus ne finit pas une série.
    static func finishes(_ episode: Episode, seasons: [SeasonSummary]) -> Bool {
        guard let season = episode.season, !season.episodes.isEmpty,
              let last = seasons.filter({ !$0.isSpecials }).map(\.number).max(),
              season.number == last else { return false }
        return season.orderedEpisodes.allSatisfy(\.isWatched)
    }

    // Cocher un premier épisode met la série en cours ; tout décocher reprend ce que cocher
    // avait posé, jamais ce qui a été dit à la main. Sans épisode coché, aucun statut deviné.
    func refreshAfterChecking(_ item: MediaItem, now: Date = .now) throws {
        guard Self.hasWatchedEpisodes(item) else {
            for entry in item.logs.filter({ $0.episode == nil && $0.source == Self.automaticSource }) {
                try edit.delete(entry)
            }
            return
        }
        let latest = Self.statusLog(of: item)
        switch latest?.status {
        case .inProgress:
            return
        case .done:
            // Une série finie qui repart — une saison 2 qui sort — revient en cours dès qu'on
            // coche un épisode après l'avoir marquée terminée. Sinon elle reste finie.
            guard let latest, Self.hasWatchedEpisode(item, after: latest.date) else { return }
        default:
            break
        }
        try log.log(item, status: .inProgress, date: now, source: Self.automaticSource)
    }

    private static func hasWatchedEpisode(_ item: MediaItem, after date: Date) -> Bool {
        item.logs.contains { $0.episode != nil && $0.status == .done && $0.date > date }
    }

    func finish(_ item: MediaItem, now: Date = .now) throws {
        try log.log(item, status: .done, date: now)
    }

    func drop(_ item: MediaItem, now: Date = .now) throws {
        try log.log(item, status: .dropped, date: now)
    }

    func resume(_ item: MediaItem, now: Date = .now) throws {
        try log.log(item, status: .inProgress, date: now)
    }
}
