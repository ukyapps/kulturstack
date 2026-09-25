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

    nonisolated private static func followable(_ item: MediaItem) -> [Episode] {
        item.orderedSeasons.filter { $0.number > 0 }.flatMap(\.orderedEpisodes)
    }
}
