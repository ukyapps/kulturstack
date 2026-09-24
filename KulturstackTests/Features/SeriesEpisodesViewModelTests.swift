import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct SeriesEpisodesViewModelTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func make(_ provider: StubEpisodeProvider) throws -> (MediaItem, SeriesEpisodesViewModel) {
        let context = container.mainContext
        let media = SwiftDataMediaRepository(context: context)
        let item = MediaItem(kind: .series, title: "Severance")
        try media.add(item, refs: [ExternalRef(provider: "tmdb", value: "tv:95396")])
        let useCase = EpisodeUseCase(
            repository: SwiftDataEpisodeRepository(context: context),
            providers: [provider],
            log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
            edit: EditLogUseCase(repository: SwiftDataLogRepository(context: context))
        )
        return (item, SeriesEpisodesViewModel(itemID: item.id, repository: media, useCase: useCase))
    }

    private func rows(_ state: SeriesEpisodesViewModel.SeasonsState) throws -> [SeasonRowModel] {
        guard case .loaded(let rows) = state else {
            Issue.record("état attendu : loaded, reçu \(state)")
            return []
        }
        return rows
    }

    private func rows(_ state: SeriesEpisodesViewModel.EpisodesState?) throws -> [EpisodeRowModel] {
        guard case .loaded(let rows) = state else {
            Issue.record("état attendu : loaded, reçu \(String(describing: state))")
            return []
        }
        return rows
    }

    // MARK: - La liste des saisons

    @Test func aSeriesListsItsSeasonsWithTheSpecialsLast() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 9),
                                                              StubEpisodeProvider.season(2, episodes: 10),
                                                              StubEpisodeProvider.season(0, episodes: 3, isSpecials: true)]))
        let (_, viewModel) = try make(provider)

        await viewModel.load()

        let seasons = try rows(viewModel.seasons)
        #expect(seasons.map(\.number) == [1, 2, 0])
        #expect(seasons.last?.isSpecials == true)
        #expect(seasons.first?.isSpecials == false)
    }

    @Test func aSeriesWithoutSeasonShowsItsOwnEmptyState() async throws {
        let (_, viewModel) = try make(StubEpisodeProvider(seasons: .success([])))

        await viewModel.load()

        #expect(viewModel.seasons == .empty)
    }

    @Test func aSourceFailureShowsTheErrorState() async throws {
        let (_, viewModel) = try make(StubEpisodeProvider(seasons: .failure(HTTPError.status(500))))

        await viewModel.load()

        #expect(viewModel.seasons == .failed)
    }

    // MARK: - Déplier une saison

    @Test func openingASeasonLoadsOnlyItsEpisodes() async throws {
        let provider = StubEpisodeProvider(
            seasons: .success([StubEpisodeProvider.season(1), StubEpisodeProvider.season(2)]),
            episodes: [2: .success([StubEpisodeProvider.episode(1, title: "Hello, Ms. Cobel"),
                                    StubEpisodeProvider.episode(2)])])
        let (_, viewModel) = try make(provider)
        await viewModel.load()

        await viewModel.open(2)

        #expect(try rows(viewModel.episodes[2]).map(\.number) == [1, 2])
        #expect(viewModel.episodes[1] == nil)
        #expect(provider.episodeCalls.map(\.season) == [2])
    }

    @Test func anAnnouncedButEmptySeasonShowsItsOwnEmptyState() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(4, episodes: 0)]),
                                           episodes: [4: .success([])])
        let (_, viewModel) = try make(provider)
        await viewModel.load()

        await viewModel.open(4)

        #expect(viewModel.episodes[4] == .empty)
    }

    @Test func aSeasonThatFailsToLoadShowsItsOwnErrorState() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1)]),
                                           episodes: [1: .failure(HTTPError.status(500))])
        let (_, viewModel) = try make(provider)
        await viewModel.load()

        await viewModel.open(1)

        #expect(viewModel.episodes[1] == .failed)
        #expect(try rows(viewModel.seasons).count == 1)
    }

    // MARK: - Cocher

    @Test func checkingAnEpisodeMarksItsRowAndTheSeasonProgress() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)

        viewModel.toggle(episode: 2, in: 1)

        #expect(try rows(viewModel.episodes[1]).map(\.isWatched) == [false, true, false])
        #expect(try rows(viewModel.seasons).first?.watchedCount == 1)
    }

    @Test func uncheckingAnEpisodeClearsItsRow() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 2)]),
                                           episodes: [1: .success((1...2).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)

        viewModel.toggle(episode: 1, in: 1)
        viewModel.toggle(episode: 1, in: 1)

        #expect(try rows(viewModel.episodes[1]).map(\.isWatched) == [false, false])
        #expect(try rows(viewModel.seasons).first?.watchedCount == 0)
    }

    @Test func checkingUpToHereMarksEverythingBeforeIt() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 5)]),
                                           episodes: [1: .success((1...5).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)

        viewModel.checkUpTo(episode: 3, in: 1)

        #expect(try rows(viewModel.episodes[1]).map(\.isWatched) == [true, true, true, false, false])
        #expect(try rows(viewModel.seasons).first?.watchedCount == 3)
    }

    // La saison est cochée en entier : c'est ce que la PR 15 lira pour proposer « terminé ».
    @Test func aFullyCheckedSeasonSaysSo() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 2)]),
                                           episodes: [1: .success((1...2).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)

        viewModel.checkUpTo(episode: 2, in: 1)

        #expect(try rows(viewModel.seasons).first?.isComplete == true)
    }

    // Replier puis redéplier ne rappelle pas la source : la saison est déjà en cache.
    @Test func reopeningASeasonDoesNotAskTheSourceAgain() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 2)]),
                                           episodes: [1: .success((1...2).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()

        await viewModel.open(1)
        await viewModel.open(1)

        #expect(provider.episodeCalls.count == 1)
    }

    @Test func aWorkThatDisappearedShowsTheErrorState() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1)]))
        let context = container.mainContext
        let media = SwiftDataMediaRepository(context: context)
        let useCase = EpisodeUseCase(
            repository: SwiftDataEpisodeRepository(context: context), providers: [provider],
            log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
            edit: EditLogUseCase(repository: SwiftDataLogRepository(context: context)))
        let viewModel = SeriesEpisodesViewModel(itemID: UUID(), repository: media, useCase: useCase)

        await viewModel.load()

        #expect(viewModel.seasons == .failed)
    }
}
