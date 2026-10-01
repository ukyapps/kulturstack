import Foundation

// « C'est pas dans suivi que ça apparaît juste quand y'a une suite ? » (founder, 30/09).
// Pour que l'onglet le sache, il faut que quelqu'un l'apprenne : jusqu'ici, seule la fiche
// interrogeait la source — et c'est précisément la fiche qu'on n'ouvre pas quand on croit
// une série finie. Ce passage le fait au lancement, à sa place.
//
// Meilleur effort, comme l'enrichissement : une panne ne remonte pas, l'app s'ouvre pareil.
@MainActor
struct RefreshSeasonsUseCase {
    // Vingt séries par passage : au-delà, on ferait une rafale d'appels au lancement pour
    // des séries qu'elle n'a pas touchées depuis des mois. Les plus récentes d'abord.
    static let maxSeries = 20
    // Une fois par jour. Une saison ne sort pas deux fois dans la même journée.
    static let interval: TimeInterval = 24 * 3600

    let media: any MediaRepository
    let logs: any LogRepository
    let episodes: EpisodeUseCase
    let history: any RefreshHistory

    // Rend le nombre de séries dont le compte de saisons a changé — zéro quand il n'y avait
    // rien de neuf, et zéro aussi quand le passage n'était pas dû.
    @discardableResult
    func run(now: Date = .now) async -> Int {
        guard isDue(now) else { return 0 }
        // Noté avant d'appeler : un réseau lent ne doit pas provoquer deux passages.
        history.record(now)
        var learned = 0
        for item in await candidates() {
            guard let seasons = try? await episodes.seasons(of: item),
                  let count = SeasonCount.from(seasons) else { continue }
            if (try? SeasonCount.remember(count, on: item)) == true { learned += 1 }
        }
        guard learned > 0 else { return 0 }
        try? media.save()
        return learned
    }

    private func isDue(_ now: Date) -> Bool {
        guard let last = history.lastRefresh() else { return true }
        return now.timeIntervalSince(last) >= Self.interval
    }

    // Les séries qu'elle suit : en cours, ou finies — ce sont celles-là dont une saison de
    // plus change quelque chose. Une série **abandonnée** n'est jamais interrogée : elle ne
    // reviendra pas, ce serait un appel pour rien.
    private func candidates() async -> [MediaItem] {
        guard let entries = try? await logs.fetchAll() else { return [] }
        var seen = Set<UUID>()
        return entries
            .filter { $0.episode == nil && ($0.status == .inProgress || $0.status == .done) }
            .compactMap(\.item)
            .filter { $0.kind == .series }
            .filter { seen.insert($0.id).inserted }
            .filter { item in
                let status = WatchStatusUseCase.status(of: item)
                return status == .inProgress || status == .done
            }
            .prefix(Self.maxSeries)
            .map { $0 }
    }
}
