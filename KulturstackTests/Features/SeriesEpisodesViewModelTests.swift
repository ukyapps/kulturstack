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
        let status = WatchStatusUseCase(
            log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
            edit: EditLogUseCase(repository: SwiftDataLogRepository(context: context)))
        return (item, SeriesEpisodesViewModel(itemID: item.id, repository: media, useCase: useCase, status: status))
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

    // Dix saisons annoncées, deux appels : celui de la saison où elle en est à l'ouverture
    // de la fiche, celui de la saison qu'elle déplie. Jamais les dix.
    @Test func openingASeasonLoadsOnlyItsEpisodes() async throws {
        let provider = StubEpisodeProvider(
            seasons: .success((1...10).map { StubEpisodeProvider.season($0) }),
            episodes: [1: .success([StubEpisodeProvider.episode(1)]),
                       7: .success([StubEpisodeProvider.episode(1, title: "Hello, Ms. Cobel"),
                                    StubEpisodeProvider.episode(2)])])
        let (_, viewModel) = try make(provider)
        await viewModel.load()

        await viewModel.open(7)

        #expect(try rows(viewModel.episodes[7]).map(\.number) == [1, 2])
        #expect(viewModel.episodes[4] == nil)
        #expect(provider.episodeCalls.map(\.season) == [1, 7])
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

    // MARK: - Toute la saison d'un geste (retour du 27/09)

    @Test func checkingTheWholeSeasonChecksEveryEpisodeAndTheSeriesFollows() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 5),
                                                              StubEpisodeProvider.season(2, episodes: 4)]),
                                           episodes: [1: .success((1...5).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)

        viewModel.checkSeason(1)

        #expect(try rows(viewModel.episodes[1]).allSatisfy { $0.isWatched })
        #expect(try rows(viewModel.seasons).first?.isComplete == true)
        #expect(viewModel.watchStatus == .inProgress)
    }

    // Cocher toute la dernière saison finit la série, sans le demander (founder, 30/09).
    @Test func checkingTheWholeLastSeasonMarksItDone() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)

        viewModel.checkSeason(1)

        #expect(viewModel.watchStatus == .done)
    }

    @Test func uncheckingTheWholeSeasonClearsItAndTheStatus() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 4)]),
                                           episodes: [1: .success((1...4).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)
        viewModel.checkSeason(1)

        viewModel.uncheckSeason(1)

        #expect(try rows(viewModel.episodes[1]).allSatisfy { !$0.isWatched })
        #expect(try rows(viewModel.seasons).first?.watchedCount == 0)
        #expect(viewModel.watchStatus == nil)
    }

    // Une saison qu'on n'a pas dépliée n'a pas d'épisode en mémoire : rien à cocher, rien qui
    // plante. La saison 1 s'ouvre toute seule à l'arrivée sur la fiche, la 2 non.
    @Test func checkingASeasonThatIsNotOpenChangesNothing() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3),
                                                              StubEpisodeProvider.season(2, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) }),
                                                      2: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()

        viewModel.checkSeason(2)

        #expect(viewModel.watchStatus == nil)
        #expect(viewModel.didFailToCheck == false)
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

    // MARK: - En cours, terminé, abandonné

    @Test func checkingAnEpisodeShowsTheSeriesAsInProgress() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)
        #expect(viewModel.watchStatus == nil)

        viewModel.toggle(episode: 1, in: 1)

        #expect(viewModel.watchStatus == .inProgress)
    }

    @Test func uncheckingEverythingClearsTheStatus() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)

        viewModel.toggle(episode: 1, in: 1)
        viewModel.toggle(episode: 1, in: 1)

        #expect(viewModel.watchStatus == nil)
    }

    @Test func checkingTheLastEpisodeOfTheLastSeasonMarksItDone() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)

        viewModel.checkUpTo(episode: 3, in: 1)

        #expect(viewModel.watchStatus == .done)
    }

    // Décocher un épisode reprend le « terminé » que l'app avait posé : elle repart en cours,
    // et il n'y a toujours qu'une ligne de statut, pas une par changement d'avis.
    @Test func uncheckingAfterTheAutomaticDoneGoesBackToInProgress() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)
        viewModel.checkUpTo(episode: 3, in: 1)

        viewModel.toggle(episode: 3, in: 1)

        #expect(viewModel.watchStatus == .inProgress)
    }

    @Test func aSeriesWithASeasonLeftStaysInProgress() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3),
                                                              StubEpisodeProvider.season(2, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)

        viewModel.checkUpTo(episode: 3, in: 1)

        #expect(viewModel.watchStatus == .inProgress)
    }

    @Test func droppingThenResumingIsShown() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (_, viewModel) = try make(provider)
        await viewModel.load()
        await viewModel.open(1)
        viewModel.toggle(episode: 1, in: 1)

        viewModel.drop()
        #expect(viewModel.watchStatus == .dropped)

        viewModel.resume()
        #expect(viewModel.watchStatus == .inProgress)
    }

    // Une série déjà en cours se rouvre en cours : le statut se lit, il ne se redevine pas.
    @Test func theStatusIsReadWhenTheSectionLoads() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
                                           episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (item, viewModel) = try make(provider)
        container.mainContext.insert(try LogEntry.make(item: item, status: .dropped))
        try container.mainContext.save()

        await viewModel.load()

        #expect(viewModel.watchStatus == .dropped)
    }

    // MARK: - « À quel épisode j'en suis » (retour du 27/09)

    private func provider(seasons: [SeasonSummary], episodes: [Int: [Int]]) -> StubEpisodeProvider {
        StubEpisodeProvider(
            seasons: .success(seasons),
            episodes: episodes.mapValues { .success($0.map { StubEpisodeProvider.episode($0) }) })
    }

    @Test func aSeriesNeverStartedProposesItsFirstEpisode() async throws {
        let (_, viewModel) = try make(provider(seasons: [StubEpisodeProvider.season(1, episodes: 3)],
                                               episodes: [1: [1, 2, 3]]))

        await viewModel.load()

        let next = try #require(viewModel.next)
        #expect((next.season, next.number) == (1, 1))
    }

    // La fiche s'ouvre sur la saison où elle en est — la dernière entamée —, pas sur la première.
    @Test func theFicheOpensOnTheSeasonWhereSheIsAt() async throws {
        let stub = provider(seasons: [StubEpisodeProvider.season(1, episodes: 2),
                                      StubEpisodeProvider.season(2, episodes: 4)],
                            episodes: [1: [1, 2], 2: [1, 2, 3, 4]])
        let (_, viewModel) = try make(stub)
        await viewModel.load()
        viewModel.checkSeason(1)
        await viewModel.open(2)
        viewModel.checkUpTo(episode: 2, in: 2)

        await viewModel.load()

        #expect(viewModel.currentSeason == 2)
        let next = try #require(viewModel.next)
        #expect((next.season, next.number) == (2, 3))
    }

    @Test func theNextEpisodeIsTheFirstUncheckedOne() async throws {
        let (_, viewModel) = try make(provider(seasons: [StubEpisodeProvider.season(1, episodes: 5)],
                                               episodes: [1: [1, 2, 3, 4, 5]]))
        await viewModel.load()
        viewModel.toggle(episode: 1, in: 1)
        viewModel.toggle(episode: 3, in: 1)

        let next = try #require(viewModel.next)
        #expect((next.season, next.number) == (1, 2))
    }

    // La saison suivante se devine sans être chargée : on connaît son numéro par la liste des saisons.
    @Test func aFinishedSeasonPointsToTheNextOneWithoutLoadingIt() async throws {
        let stub = provider(seasons: [StubEpisodeProvider.season(1, episodes: 2),
                                      StubEpisodeProvider.season(2, episodes: 6)],
                            episodes: [1: [1, 2], 2: [1, 2, 3, 4, 5, 6]])
        let (_, viewModel) = try make(stub)
        await viewModel.load()
        viewModel.checkSeason(1)

        let next = try #require(viewModel.next)
        #expect((next.season, next.number) == (2, 1))
        #expect(stub.episodeCalls.map(\.season) == [1])
    }

    @Test func aSeriesSeenToTheEndHasNoNextEpisode() async throws {
        let (_, viewModel) = try make(provider(seasons: [StubEpisodeProvider.season(1, episodes: 2)],
                                               episodes: [1: [1, 2]]))
        await viewModel.load()
        viewModel.checkSeason(1)

        #expect(viewModel.next == nil)
    }

    // Un bonus n'est jamais « la suite » : la règle des spéciaux vaut aussi pour la fiche.
    @Test func theSpecialsAreNeverTheNextEpisode() async throws {
        let stub = provider(seasons: [StubEpisodeProvider.season(1, episodes: 2),
                                      StubEpisodeProvider.season(0, episodes: 3, isSpecials: true)],
                            episodes: [1: [1, 2], 0: [1, 2, 3]])
        let (_, viewModel) = try make(stub)
        await viewModel.load()
        viewModel.checkSeason(1)

        #expect(viewModel.next == nil)
    }

    @Test func checkingTheNextEpisodeMarksItAndMovesOn() async throws {
        let (_, viewModel) = try make(provider(seasons: [StubEpisodeProvider.season(1, episodes: 3)],
                                               episodes: [1: [1, 2, 3]]))
        await viewModel.load()

        await viewModel.checkNext()

        #expect(try rows(viewModel.episodes[1]).map(\.isWatched) == [true, false, false])
        let next = try #require(viewModel.next)
        #expect((next.season, next.number) == (1, 2))
        #expect(viewModel.watchStatus == .inProgress)
    }

    // Cocher la suite quand elle est dans une saison pas encore chargée : on la charge d'abord.
    @Test func checkingANextEpisodeFromAnUnloadedSeasonLoadsItFirst() async throws {
        let stub = provider(seasons: [StubEpisodeProvider.season(1, episodes: 1),
                                      StubEpisodeProvider.season(2, episodes: 3)],
                            episodes: [1: [1], 2: [1, 2, 3]])
        let (_, viewModel) = try make(stub)
        await viewModel.load()
        viewModel.checkSeason(1)

        await viewModel.checkNext()

        #expect(stub.episodeCalls.map(\.season) == [1, 2])
        let next = try #require(viewModel.next)
        #expect((next.season, next.number) == (2, 2))
    }

    @Test func aWorkThatDisappearedShowsTheErrorState() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1)]))
        let context = container.mainContext
        let media = SwiftDataMediaRepository(context: context)
        let useCase = EpisodeUseCase(
            repository: SwiftDataEpisodeRepository(context: context), providers: [provider],
            log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
            edit: EditLogUseCase(repository: SwiftDataLogRepository(context: context)))
        let viewModel = SeriesEpisodesViewModel(
            itemID: UUID(), repository: media, useCase: useCase,
            status: WatchStatusUseCase(log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
                                       edit: EditLogUseCase(repository: SwiftDataLogRepository(context: context))))

        await viewModel.load()

        #expect(viewModel.seasons == .failed)
    }

    // MARK: - Une saison qui sort après coup

    // Le nombre de saisons vient de l'enrichissement, qui n'a lieu qu'une fois. Sans ça, une
    // série finie resterait finie même après la sortie d'une saison 2 — et l'onglet
    // « En cours » ne la reverrait jamais.
    @Test func openingTheFicheLearnsThatANewSeasonCameOut() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 9),
                                                              StubEpisodeProvider.season(2, episodes: 10)]),
                                           episodes: [1: .success((1...9).map { StubEpisodeProvider.episode($0) })])
        let (item, viewModel) = try make(provider)
        try item.setDetails(SeriesDetails(seasonCount: 1))

        await viewModel.load()

        #expect((item.details as? SeriesDetails)?.seasonCount == 2)
    }

    // La conséquence, celle qui compte : la série n'est plus « tout vu ».
    @Test func aSeriesFinishedBeforeANewSeasonIsNoLongerFullyWatched() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 2),
                                                              StubEpisodeProvider.season(2, episodes: 2)]),
                                           episodes: [1: .success((1...2).map { StubEpisodeProvider.episode($0) })])
        let (item, viewModel) = try make(provider)
        try item.setDetails(SeriesDetails(seasonCount: 1))
        await viewModel.load()
        viewModel.checkUpTo(episode: 2, in: 1)
        #expect(viewModel.watchStatus == .inProgress)

        #expect(WatchStatusUseCase.isFullyWatched(item) == false)
    }

    // Les spéciaux ne gonflent pas le compte : la saison 0 n'est pas une saison.
    @Test func theSpecialsAreNotCountedAsASeason() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 9),
                                                              StubEpisodeProvider.season(0, episodes: 4, isSpecials: true)]),
                                           episodes: [1: .success((1...9).map { StubEpisodeProvider.episode($0) })])
        let (item, viewModel) = try make(provider)

        await viewModel.load()

        #expect((item.details as? SeriesDetails)?.seasonCount == 1)
    }

    // Une source en panne ne doit pas écraser ce qu'on savait par un zéro.
    @Test func aFailedLoadLeavesTheSeasonCountAlone() async throws {
        let provider = StubEpisodeProvider(seasons: .failure(HTTPError.status(500)))
        let (item, viewModel) = try make(provider)
        try item.setDetails(SeriesDetails(seasonCount: 3))

        await viewModel.load()

        #expect((item.details as? SeriesDetails)?.seasonCount == 3)
    }
}
