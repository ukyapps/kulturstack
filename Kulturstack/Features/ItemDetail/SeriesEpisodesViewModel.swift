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

    // Où elle en est, en haut de la fiche : « à quel épisode j'en suis » (retour du 27/09).
    struct Next: Equatable {
        let season: Int
        let number: Int
        let title: String?
    }

    private(set) var next: Next?
    private(set) var currentSeason: Int?
    // Une série se regarde par saisons, un podcast s'écoute à plat : les mots et l'écran suivent.
    private(set) var kind: MediaKind = .series
    private(set) var seasons: SeasonsState = .loading
    private(set) var episodes: [Int: EpisodesState] = [:]
    private(set) var watchStatus: LogStatus?
    var didFailToCheck = false
    var proposesFinish = false

    private let itemID: UUID
    private let repository: any MediaRepository
    private let useCase: EpisodeUseCase
    private let status: WatchStatusUseCase
    private let onChange: () -> Void
    private var summaries: [SeasonSummary] = []
    private var stored: [Int: Season] = [:]

    init(itemID: UUID, repository: any MediaRepository, useCase: EpisodeUseCase,
         status: WatchStatusUseCase, onChange: @escaping () -> Void = {}) {
        self.itemID = itemID
        self.repository = repository
        self.useCase = useCase
        self.status = status
        self.onChange = onChange
    }

    func load() async {
        seasons = .loading
        guard let item = item() else {
            seasons = .failed
            return
        }
        watchStatus = WatchStatusUseCase.status(of: item)
        kind = item.kind
        do {
            summaries = try await useCase.seasons(of: item)
            seasons = summaries.isEmpty ? .empty : .loaded(seasonRows())
        } catch {
            seasons = .failed
            return
        }
        // Une seule saison se charge à l'ouverture — celle où elle en est. Sans ça, « où j'en
        // suis » ne saurait rien dire tant qu'elle n'a pas déplié quelque chose à la main.
        currentSeason = seasonInProgress(of: item)
        if let currentSeason { await open(currentSeason) }
        next = nextEpisode(of: item)
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
            next = nextEpisode(of: item)
        } catch {
            episodes[number] = .failed
        }
    }

    // Le ✓ de « prochain épisode ». Si la suite est dans une saison encore inconnue, on la
    // charge d'abord : c'est le seul moment où cocher déclenche un appel réseau.
    func checkNext() async {
        guard let next else { return }
        if stored[next.season] == nil { await open(next.season) }
        toggle(episode: next.number, in: next.season)
    }

    func toggle(episode number: Int, in season: Int) {
        perform(episode: number, in: season) { try useCase.toggle($1, of: $0) }
    }

    func checkUpTo(episode number: Int, in season: Int) {
        perform(episode: number, in: season) { try useCase.checkUpTo($1, of: $0) }
    }

    // « J'ai vu toute la saison » en un geste. Une saison non dépliée n'a pas ses épisodes
    // en mémoire : il n'y a rien à cocher, et rien à signaler.
    func checkSeason(_ number: Int) {
        performSeason(number) { try useCase.checkAll($1, of: $0) }
    }

    func uncheckSeason(_ number: Int) {
        performSeason(number) { try useCase.uncheckAll($1, of: $0) }
    }

    func finish() { record { try status.finish($0) } }

    func drop() { record { try status.drop($0) } }

    func resume() { record { try status.resume($0) } }

    private func perform(episode number: Int, in season: Int, _ action: (MediaItem, Episode) throws -> Void) {
        guard let episode = stored[season]?.episodes.first(where: { $0.number == number }) else { return }
        apply(in: season, trigger: episode) { try action($0, episode) }
    }

    // Cocher toute une saison, c'est cocher son dernier épisode du point de vue du statut :
    // même déclencheur, donc même proposition de « terminé » sur la dernière saison.
    private func performSeason(_ number: Int, _ action: (MediaItem, Season) throws -> Void) {
        guard let season = stored[number] else { return }
        apply(in: number, trigger: season.orderedEpisodes.last) { try action($0, season) }
    }

    private func apply(in season: Int, trigger: Episode?, _ action: (MediaItem) throws -> Void) {
        guard let item = item() else { return }
        do {
            try action(item)
            try status.refreshAfterChecking(item)
            didFailToCheck = false
            refresh(season)
            next = nextEpisode(of: item)
            watchStatus = WatchStatusUseCase.status(of: item)
            // Finir la dernière saison propose « terminé » ; une série qui continue n'est pas finie.
            if watchStatus != .done, let trigger, WatchStatusUseCase.finishes(trigger, seasons: summaries) {
                proposesFinish = true
            }
            onChange()
        } catch {
            didFailToCheck = true
        }
    }

    private func record(_ action: (MediaItem) throws -> Void) {
        guard let item = item() else { return }
        do {
            try action(item)
            didFailToCheck = false
            proposesFinish = false
            watchStatus = WatchStatusUseCase.status(of: item)
            onChange()
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

    // La saison où elle en est : la dernière qu'elle a entamée, sinon la première à suivre.
    private func seasonInProgress(of item: MediaItem) -> Int? {
        let started = item.orderedSeasons
            .filter { $0.number > 0 && $0.episodes.contains { $0.isWatched } }
            .map(\.number)
        return started.max() ?? summaries.first { !$0.isSpecials }?.number
    }

    // La suite, c'est le premier épisode non coché de ce qu'on connaît. Quand une saison est
    // finie, la suivante se devine par la liste des saisons, sans avoir à la charger.
    private func nextEpisode(of item: MediaItem) -> Next? {
        if let episode = InProgressUseCase.next(for: item), let season = episode.season {
            return Next(season: season.number, number: episode.number, title: episode.title)
        }
        let known = Set(item.orderedSeasons.filter { !$0.episodes.isEmpty }.map(\.number))
        guard let upcoming = summaries.filter({ !$0.isSpecials }).map(\.number).sorted()
            .first(where: { !known.contains($0) }) else { return nil }
        return Next(season: upcoming, number: 1, title: nil)
    }

    private func seasonRows() -> [SeasonRowModel] {
        summaries.map { SeasonRowModel(summary: $0, season: stored[$0.number]) }
    }

    private func item() -> MediaItem? { try? repository.find(itemID: itemID) }
}
