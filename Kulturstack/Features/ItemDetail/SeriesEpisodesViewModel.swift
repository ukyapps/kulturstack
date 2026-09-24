import Foundation
import Observation

@MainActor @Observable
final class SeriesEpisodesViewModel {
    enum SeasonsState: Equatable {
        case loading
        case loaded([SeasonRowModel])
        case empty
        case failed
    }

    enum EpisodesState: Equatable {
        case loading
        case loaded([EpisodeRowModel])
        case empty
        case failed
    }

    private(set) var seasons: SeasonsState = .loading
    private(set) var episodes: [Int: EpisodesState] = [:]
    var didFailToCheck = false

    private let itemID: UUID
    private let repository: any MediaRepository
    private let useCase: EpisodeUseCase
    private var summaries: [SeasonSummary] = []
    private var stored: [Int: Season] = [:]

    init(itemID: UUID, repository: any MediaRepository, useCase: EpisodeUseCase) {
        self.itemID = itemID
        self.repository = repository
        self.useCase = useCase
    }

    func load() async {
        seasons = .loading
        guard let item = item() else {
            seasons = .failed
            return
        }
        do {
            summaries = try await useCase.seasons(of: item)
            seasons = summaries.isEmpty ? .empty : .loaded(seasonRows())
        } catch {
            seasons = .failed
        }
    }

    // Déplier. Une saison déjà chargée ne redemande rien à la source ; une saison en échec, si.
    func open(_ number: Int) async {
        guard stored[number] == nil,
              let summary = summaries.first(where: { $0.number == number }),
              let item = item() else { return }
        episodes[number] = .loading
        do {
            stored[number] = try await useCase.open(summary, of: item)
            refresh(number)
        } catch {
            episodes[number] = .failed
        }
    }

    func toggle(episode number: Int, in season: Int) {
        perform(episode: number, in: season) { try useCase.toggle($1, of: $0) }
    }

    func checkUpTo(episode number: Int, in season: Int) {
        perform(episode: number, in: season) { try useCase.checkUpTo($1, of: $0) }
    }

    private func perform(episode number: Int, in season: Int, _ action: (MediaItem, Episode) throws -> Void) {
        guard let item = item(),
              let episode = stored[season]?.episodes.first(where: { $0.number == number }) else { return }
        do {
            try action(item, episode)
            didFailToCheck = false
            refresh(season)
        } catch {
            didFailToCheck = true
        }
    }

    // Cocher change la ligne et la progression de sa saison : les deux se recalculent ensemble.
    private func refresh(_ number: Int) {
        guard let season = stored[number] else { return }
        let rows = season.orderedEpisodes.map(EpisodeRowModel.init)
        episodes[number] = rows.isEmpty ? .empty : .loaded(rows)
        if case .loaded = seasons { seasons = .loaded(seasonRows()) }
    }

    private func seasonRows() -> [SeasonRowModel] {
        summaries.map { SeasonRowModel(summary: $0, season: stored[$0.number]) }
    }

    private func item() -> MediaItem? { try? repository.find(itemID: itemID) }
}
