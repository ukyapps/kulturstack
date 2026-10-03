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
    // Cocher toute une série peut demander plusieurs saisons à la source : le bouton doit
    // dire qu'il travaille, sinon on appuie deux fois.
    private(set) var isCheckingEverything = false
    var didFailToCheck = false
    // Le retour haptique suit le geste : cocher, tout cocher, abandonner, reprendre. Attaché
    // au nombre d'épisodes vus, il manquait tout ce qui ne le changeait pas (founder, 03/10).
    private(set) var feedback = 0

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
            rememberSeasonCount(of: item)
            watchStatus = WatchStatusUseCase.status(of: item)
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

    // « J'ai vu toute la saison » en un geste, y compris **repliée** : le bouton vit sur
    // l'en-tête depuis le 30/09, donc la saison se charge d'abord si on ne la connaît pas.
    func checkSeason(_ number: Int) async {
        if stored[number] == nil { await open(number) }
        performSeason(number) { try useCase.checkAll($1, of: $0) }
    }

    // « J'ai vu toute la série » : toutes les saisons, spéciaux exclus — un bonus ne fait pas
    // partie de la série. Une saison que la source ne rend pas se signale et n'est pas cochée :
    // la série n'est alors pas déclarée finie, ce qui est la vérité.
    func checkEverything() async {
        isCheckingEverything = true
        defer { isCheckingEverything = false }
        var missed = false
        for summary in summaries where !summary.isSpecials {
            if stored[summary.number] == nil { await open(summary.number) }
            guard stored[summary.number] != nil else {
                missed = true
                continue
            }
            performSeason(summary.number) { try useCase.checkAll($1, of: $0) }
        }
        if missed { didFailToCheck = true }
    }

    func uncheckSeason(_ number: Int) {
        performSeason(number) { try useCase.uncheckAll($1, of: $0) }
    }

    // Une année de podcast se coche et se décoche comme une saison : c'est ce qu'elle est à
    // l'écran. Le flux étant déjà chargé en entier, rien ne part sur le réseau.
    func checkYear(_ year: Int?, in season: Int) {
        performYear(year, in: season) { try useCase.check($1, of: $0) }
    }

    func uncheckYear(_ year: Int?, in season: Int) {
        performYear(year, in: season) { try useCase.uncheck($1, of: $0) }
    }

    private func performYear(_ year: Int?, in season: Int,
                             _ action: (MediaItem, [Episode]) throws -> Void) {
        guard let stored = stored[season] else { return }
        let episodes = stored.orderedEpisodes.filter { $0.year == year }
        guard !episodes.isEmpty else { return }
        apply(in: season) { try action($0, episodes) }
    }

    func drop() { record { try status.drop($0) } }

    func resume() { record { try status.resume($0) } }

    private func perform(episode number: Int, in season: Int, _ action: (MediaItem, Episode) throws -> Void) {
        guard let episode = stored[season]?.episodes.first(where: { $0.number == number }) else { return }
        apply(in: season) { try action($0, episode) }
    }

    private func performSeason(_ number: Int, _ action: (MediaItem, Season) throws -> Void) {
        guard let season = stored[number] else { return }
        apply(in: number) { try action($0, season) }
    }

    private func apply(in season: Int, _ action: (MediaItem) throws -> Void) {
        guard let item = item() else { return }
        do {
            try action(item)
            // La liste des saisons fait autorité ici : l'écran l'a chargée, il sait donc si
            // tout est vu — et « tout vu » pose « terminé » sans le demander (founder, 30/09).
            try status.refreshAfterChecking(item, seasons: summaries)
            didFailToCheck = false
            feedback += 1
            refresh(season)
            next = nextEpisode(of: item)
            watchStatus = WatchStatusUseCase.status(of: item)
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
            feedback += 1
            watchStatus = WatchStatusUseCase.status(of: item)
            onChange()
        } catch {
            didFailToCheck = true
        }
    }

    // Le nombre de saisons n'est récupéré qu'une fois, à l'enrichissement de la fiche : une
    // saison qui sort après coup ne le changerait jamais, et la série resterait « terminée »
    // pour toujours. La liste qu'on vient de charger fait foi — c'est le seul endroit de
    // l'app qui la voit fraîche.
    private func rememberSeasonCount(of item: MediaItem) {
        guard let count = SeasonCount.from(summaries) else { return }
        do {
            guard try SeasonCount.remember(count, on: item) else { return }
            try repository.save()
        } catch {
            // Un compte pas rangé n'empêche pas de regarder la série : la fiche s'affiche.
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
        // « Je suis pas obligée de commencer par le premier podcast, y'a pas toujours d'ordre »
        // (founder, 30/09). Un podcast n'a pas de suite imposée — le plan de la tranche le
        // disait déjà, la carte était passée quand même.
        guard item.kind.showsSeasons else { return nil }
        if let episode = InProgressUseCase.next(for: item), let season = episode.season {
            return Next(season: season.number, number: episode.number, title: episode.title)
        }
        let known = Set(item.orderedSeasons.filter { !$0.episodes.isEmpty }.map(\.number))
        guard let upcoming = summaries.filter({ !$0.isSpecials }).map(\.number).sorted()
            .first(where: { !known.contains($0) }) else { return nil }
        return Next(season: upcoming, number: 1, title: nil)
    }

    // L'année la plus récente du flux : c'est celle qu'on écoute, donc celle qui s'ouvre.
    var latestYear: Int? {
        guard !kind.showsSeasons, case .loaded(let rows) = episodes[1] else { return nil }
        return EpisodeYearGroup.group(rows).last?.id
    }

    private func seasonRows() -> [SeasonRowModel] {
        summaries.map { SeasonRowModel(summary: $0, season: stored[$0.number]) }
    }

    private func item() -> MediaItem? { try? repository.find(itemID: itemID) }
}
