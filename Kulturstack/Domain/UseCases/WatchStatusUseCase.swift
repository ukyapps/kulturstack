import Foundation

@MainActor
struct WatchStatusUseCase {
    // Ce que cocher a posé tout seul, par opposition à ce que la founder a dit elle-même.
    static let automaticSource = "episodes"

    let log: LogUseCase
    let edit: EditLogUseCase

    // Le statut d'une œuvre, c'est son dernier log qui parle d'elle : une envie n'en est pas un,
    // un épisode coché non plus.
    nonisolated static func status(of item: MediaItem) -> LogStatus? { statusLog(of: item)?.status }

    nonisolated static func statusLog(of item: MediaItem) -> LogEntry? {
        item.logs
            .filter { $0.episode == nil && $0.status != .wishlist }
            .max { ($0.date, $0.createdAt) < ($1.date, $1.createdAt) }
    }

    static func hasWatchedEpisodes(_ item: MediaItem) -> Bool {
        item.logs.contains { $0.episode != nil && $0.status == .done }
    }

    // Tout vu, c'est terminé (founder, 30/09 : « si j'ai tout vu, ça doit me la mettre en
    // terminé pas rester en cours »). Remplace la proposition du 24/09, qui demandait.
    //
    // Toutes les saisons doivent être connues *et* complètes : une saison jamais ouverte, ou
    // une saison à trous, ne finit rien. Les spéciaux ne comptent pas — un bonus ne finit pas
    // une série. Un podcast n'a pas de fin : il publiera encore la semaine prochaine.
    //
    // Ce qui fait autorité sur « combien de saisons existent » : la liste des saisons quand
    // l'écran l'a (la fiche), le compte rangé dans la fiche sinon (l'onglet « En cours », qui
    // ne va pas sur le réseau). Sans l'un ni l'autre, on ne devine pas.
    static func isFullyWatched(_ item: MediaItem, seasons: [SeasonSummary] = []) -> Bool {
        guard item.kind == .series else { return false }
        let known = item.orderedSeasons.filter { $0.number > 0 && !$0.episodes.isEmpty }
        guard !known.isEmpty, let expected = expectedSeasons(of: item, seasons: seasons),
              Set(known.map(\.number)) == expected else { return false }
        return known.allSatisfy { $0.orderedEpisodes.allSatisfy(\.isWatched) }
    }

    private static func expectedSeasons(of item: MediaItem, seasons: [SeasonSummary]) -> Set<Int>? {
        let listed = seasons.filter { !$0.isSpecials }.map(\.number)
        if !listed.isEmpty { return Set(listed) }
        guard let total = (item.details as? SeriesDetails)?.seasonCount, total > 0 else { return nil }
        return Set(1...total)
    }

    // Cocher un premier épisode met la série en cours ; tout décocher reprend ce que cocher
    // avait posé, jamais ce qui a été dit à la main. Sans épisode coché, aucun statut deviné.
    func refreshAfterChecking(_ item: MediaItem, seasons: [SeasonSummary] = [], now: Date = .now) throws {
        guard Self.hasWatchedEpisodes(item) else {
            try edit.delete(item.logs.filter { $0.episode == nil && $0.source == Self.automaticSource })
            return
        }
        // Tout vu pose « terminé », le reste pose « en cours » : le même geste, deux issues.
        let target: LogStatus = Self.isFullyWatched(item, seasons: seasons) ? .done : .inProgress
        let latest = Self.statusLog(of: item)
        guard latest?.status != target else { return }
        if let latest, latest.status == .done, latest.source != Self.automaticSource {
            // Une série qu'elle a dite finie ne se rouvre pas dans son dos : elle ne repart
            // qu'en cochant un épisode après coup — une saison 2 qui sort. Un « terminé » posé
            // par l'app, lui, se reprend librement : décocher un épisode la remet en cours.
            guard Self.hasWatchedEpisode(item, after: latest.date) else { return }
        }
        try log.log(item, status: target, date: now, source: Self.automaticSource)
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
