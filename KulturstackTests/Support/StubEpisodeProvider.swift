import Foundation
import Synchronization
@testable import Kulturstack

// Une source d'épisodes qui ne sort pas de la mémoire : ce qu'elle rend est décidé au montage,
// et elle note ce qu'on lui a demandé — c'est ce qui prouve qu'une saison n'est chargée qu'au dépliement.
final class StubEpisodeProvider: EpisodeProvider, Sendable {
    struct EpisodeCall: Equatable, Sendable {
        let key: String
        let season: Int
    }

    private let key: String
    private let seasonResult: Result<[SeasonSummary], Error>
    private let episodeResults: [Int: Result<[EpisodeSummary], Error>]
    private let recorded = Mutex<(seasons: [String], episodes: [EpisodeCall])>(([], []))

    init(key: String = "tmdb:tv:95396",
         seasons: Result<[SeasonSummary], Error> = .success([]),
         episodes: [Int: Result<[EpisodeSummary], Error>] = [:]) {
        self.key = key
        self.seasonResult = seasons
        self.episodeResults = episodes
    }

    var seasonCalls: [String] { recorded.withLock { $0.seasons } }
    var episodeCalls: [EpisodeCall] { recorded.withLock { $0.episodes } }

    // Une clé qui n'est pas la mienne ne déclenche aucune requête : liste vide, comme TMDB.
    func seasons(forKey key: String) async throws -> [SeasonSummary] {
        guard key == self.key else { return [] }
        recorded.withLock { $0.seasons.append(key) }
        return try seasonResult.get()
    }

    func episodes(forKey key: String, season: Int) async throws -> [EpisodeSummary] {
        guard key == self.key else { return [] }
        recorded.withLock { $0.episodes.append(EpisodeCall(key: key, season: season)) }
        return try episodeResults[season]?.get() ?? []
    }

    static func season(_ number: Int, episodes: Int = 10, isSpecials: Bool = false) -> SeasonSummary {
        SeasonSummary(number: number, title: nil, episodeCount: episodes, airDate: nil, isSpecials: isSpecials)
    }

    static func episode(_ number: Int, title: String? = nil) -> EpisodeSummary {
        EpisodeSummary(number: number, title: title, airDate: nil, runtimeMinutes: nil)
    }
}
