import Foundation

@MainActor
struct EpisodeUseCase {
    let repository: any EpisodeRepository
    let providers: [any EpisodeProvider]
    let log: LogUseCase
    let edit: EditLogUseCase

    // Le découpage tel que la source le voit. Rien n'est persisté ici : une saison n'entre en
    // base que quand on l'ouvre, sinon une série de dix saisons en écrirait dix pour rien.
    func seasons(of item: MediaItem) async throws -> [SeasonSummary] {
        guard item.kind.hasEpisodes else { return [] }
        for provider in providers {
            for key in item.externalRefs.map(\.key) {
                let seasons = try await provider.seasons(forKey: key)
                if !seasons.isEmpty { return seasons }
            }
        }
        return []
    }

    // Déplier une saison : on la charge, on la met en cache, on rend ses épisodes.
    // La source d'abord, la base ensuite : une panne réseau ne laisse pas de saison à moitié créée.
    @discardableResult
    func open(_ summary: SeasonSummary, of item: MediaItem) async throws -> Season {
        let fetched = try await episodes(season: summary.number, of: item)
        let season = try stored(summary, of: item)
        var missing: [Episode] = []
        for episode in fetched {
            guard let cached = match(episode, in: season) else {
                missing.append(Episode(number: episode.number, title: episode.title, airDate: episode.airDate,
                                       runtimeMinutes: episode.runtimeMinutes,
                                       externalID: episode.externalID, season: season))
                continue
            }
            // Un flux qui publie fait descendre ses épisodes d'un rang : la position change,
            // l'identité non — et c'est l'identité qui tient la coche.
            cached.number = episode.number
            cached.title = episode.title
            cached.airDate = episode.airDate
            cached.runtimeMinutes = episode.runtimeMinutes
        }
        try repository.add(missing)
        return season
    }

    // Cocher = un log `done` daté maintenant qui porte l'épisode. Décocher = supprimer ce log.
    func toggle(_ episode: Episode, of item: MediaItem, now: Date = .now) throws {
        let watched = episode.logs.filter { $0.item?.id == item.id }
        guard watched.isEmpty else {
            for entry in watched { try edit.delete(entry) }
            return
        }
        try log.log(item, status: .done, date: now, episode: episode)
    }

    // « Tout cocher jusqu'ici » : on comble les trous de la saison, on ne redouble jamais ce qui l'est déjà.
    func checkUpTo(_ episode: Episode, of item: MediaItem, now: Date = .now) throws {
        guard let season = episode.season else { return }
        for candidate in season.orderedEpisodes where candidate.number <= episode.number && !candidate.isWatched {
            try log.log(item, status: .done, date: now, episode: candidate)
        }
    }

    // « J'ai vu toute la saison » : la même règle que « jusqu'ici », appliquée au dernier épisode.
    // Une saison sans épisode en mémoire n'a rien à cocher.
    func checkAll(_ season: Season, of item: MediaItem, now: Date = .now) throws {
        guard let last = season.orderedEpisodes.last else { return }
        try checkUpTo(last, of: item, now: now)
    }

    // Décocher une saison ne touche qu'elle : les autres gardent ce qu'elles ont.
    func uncheckAll(_ season: Season, of item: MediaItem) throws {
        for episode in season.orderedEpisodes {
            for entry in episode.logs.filter({ $0.item?.id == item.id }) { try edit.delete(entry) }
        }
    }

    // Un épisode de podcast se reconnaît à son identité de flux ; un épisode de série, qui
    // n'en a pas, à son numéro — celui que la source lui donne et ne change jamais.
    private func match(_ episode: EpisodeSummary, in season: Season) -> Episode? {
        guard let identity = episode.externalID else {
            return season.episodes.first { $0.externalID == nil && $0.number == episode.number }
        }
        return season.episodes.first { $0.externalID == identity }
    }

    private func episodes(season number: Int, of item: MediaItem) async throws -> [EpisodeSummary] {
        guard item.kind.hasEpisodes else { return [] }
        for provider in providers {
            for key in item.externalRefs.map(\.key) {
                let episodes = try await provider.episodes(forKey: key, season: number)
                if !episodes.isEmpty { return episodes }
            }
        }
        return []
    }

    private func stored(_ summary: SeasonSummary, of item: MediaItem) throws -> Season {
        if let season = try repository.season(ofItem: item.id, number: summary.number) { return season }
        let season = try Season.make(number: summary.number, title: summary.title, item: item)
        try repository.add(season)
        return season
    }
}
