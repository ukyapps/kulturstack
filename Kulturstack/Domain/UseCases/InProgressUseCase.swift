import Foundation

@MainActor
struct InProgressUseCase {
    let repository: any LogRepository

    // Une œuvre est en cours tant que son dernier log qui parle d'elle dit « en cours ».
    // La plus récemment commencée d'abord : c'est celle qu'on reprend ce soir.
    func items() async throws -> [MediaItem] {
        var seen = Set<UUID>()
        return try await repository.fetchAll()
            .filter { $0.status == .inProgress && $0.episode == nil }
            .compactMap(\.item)
            .filter { seen.insert($0.id).inserted }
            .filter { WatchStatusUseCase.status(of: $0) == .inProgress }
    }

    // La suite, c'est le premier épisode non coché — un trou au milieu passe avant ce qui suit
    // le dernier vu. Les spéciaux (saison 0 chez TMDB) ne sont jamais la suite.
    nonisolated static func next(for item: MediaItem) -> Episode? {
        followable(item).first { !$0.isWatched }
    }

    nonisolated static func lastWatched(of item: MediaItem) -> Episode? {
        followable(item).last { $0.isWatched }
    }

    // Où se trouve la suite, même quand sa saison n'a jamais été ouverte. L'écran « En cours »
    // ne va pas sur le réseau — il ferait dix appels à son ouverture —, mais il n'a pas besoin
    // d'y aller : le nombre de saisons est déjà rangé dans la fiche depuis son enrichissement.
    struct NextUp: Equatable {
        let season: Int
        let number: Int
        // Nil quand la saison n'est pas encore en base : c'est le ✓ qui ira la chercher.
        let episode: Episode?
    }

    nonisolated static func nextUp(for item: MediaItem) -> NextUp? {
        // Un podcast se reprend par le plus récent qu'on n'a pas écouté, pas par le plus
        // ancien : « je suis pas obligée de commencer par le premier » (founder, 30/09).
        guard item.kind.isFollowedInOrder else {
            guard let episode = followable(item).last(where: { !$0.isWatched }) else { return nil }
            return NextUp(season: episode.season?.number ?? 0, number: episode.number, episode: episode)
        }
        if let episode = next(for: item) {
            return NextUp(season: episode.season?.number ?? 0, number: episode.number, episode: episode)
        }
        // Tout ce qu'on connaît est vu. Sans savoir combien de saisons existent, on ne devine
        // pas : mieux vaut proposer « Terminé » qu'inventer une saison qui n'existe pas.
        guard let known = knownSeasons(item).map(\.number).max(),
              let total = (item.details as? SeriesDetails)?.seasonCount,
              known < total else { return nil }
        return NextUp(season: known + 1, number: 1, episode: nil)
    }

    nonisolated private static func followable(_ item: MediaItem) -> [Episode] {
        knownSeasons(item).flatMap(\.orderedEpisodes)
    }

    // Une saison créée sans ses épisodes ne compte pas pour connue : elle ne dit rien.
    nonisolated private static func knownSeasons(_ item: MediaItem) -> [Season] {
        item.orderedSeasons.filter { $0.number > 0 && !$0.episodes.isEmpty }
    }
}
