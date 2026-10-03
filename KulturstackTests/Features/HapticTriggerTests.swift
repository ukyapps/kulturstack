import Foundation
import SwiftData
import Testing
@testable import Kulturstack

// « Il n'y a plus le petit truc satisfaisant quand je valide que j'ai vu un épisode… ça le
// fait sur Dix pour cent, pas sur Arrested Development ou Transfert » et « ça fait pas la
// vibration quand c'est le dernier épisode » (founder, 03/10).
//
// La vibration elle-même ne se teste pas — SwiftUI ne l'expose pas. Ce qui se teste, c'est la
// **donnée qui la déclenche** : un compteur qui suit le geste, et non une valeur affichée.
// C'était tout le bug : accroché à la progression, il ne bougeait ni sur un podcast (qui n'a
// pas de barre) ni quand la ligne quittait l'écran.
@MainActor
struct HapticTriggerTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private var context: ModelContext { container.mainContext }

    private func services() -> AppServices { AppServices(context: context) }

    private func inProgressViewModel() -> InProgressViewModel {
        let services = services()
        return InProgressViewModel(useCase: services.inProgressUseCase, repository: services.mediaRepository,
                                   advance: services.advanceUseCase, status: services.watchStatusUseCase)
    }

    @discardableResult
    private func work(_ kind: MediaKind, episodes count: Int, watched: [Int],
                      seasonCount: Int? = nil) throws -> MediaItem {
        let item = MediaItem(kind: kind, title: kind == .podcast ? "Transfert" : "Arrested Development")
        context.insert(item)
        if let seasonCount { try item.setDetails(SeriesDetails(seasonCount: seasonCount)) }
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        for number in 1...count {
            context.insert(Episode(number: number, title: "Épisode \(number)",
                                   externalID: kind == .podcast ? "guid-\(number)" : nil, season: season))
        }
        try context.save()
        for episode in season.orderedEpisodes where watched.contains(episode.number) {
            context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        context.insert(try LogEntry.make(item: item, status: .inProgress,
                                         source: WatchStatusUseCase.automaticSource))
        try context.save()
        return item
    }

    // Transfert : un podcast n'a pas de barre de progression, le déclencheur ne bougeait jamais.
    @Test func advancingAPodcastTriggersTheFeedback() async throws {
        try work(.podcast, episodes: 4, watched: [1])
        let viewModel = inProgressViewModel()
        await viewModel.load()
        guard case .loaded(let rows) = viewModel.state, let row = rows.first else {
            Issue.record("la ligne du podcast est attendue")
            return
        }

        await viewModel.advance(row)

        #expect(viewModel.feedback == 1)
    }

    // Le dernier épisode : la série passe en terminé et **quitte la liste**. Accroché à la
    // ligne, le retour haptique disparaissait avec elle.
    @Test func advancingTheLastEpisodeStillTriggersTheFeedback() async throws {
        try work(.series, episodes: 3, watched: [1, 2], seasonCount: 1)
        let viewModel = inProgressViewModel()
        await viewModel.load()
        guard case .loaded(let rows) = viewModel.state, let row = rows.first else {
            Issue.record("la ligne de la série est attendue")
            return
        }

        await viewModel.advance(row)

        #expect(viewModel.feedback == 1)
        // Elle est bien partie : c'est exactement le cas où l'ancien déclencheur se taisait.
        #expect(viewModel.state == .empty)
    }

    @Test func advancingTwiceTriggersTwice() async throws {
        try work(.series, episodes: 5, watched: [1])
        let viewModel = inProgressViewModel()
        await viewModel.load()

        for _ in 0..<2 {
            guard case .loaded(let rows) = viewModel.state, let row = rows.first else { return }
            await viewModel.advance(row)
        }

        #expect(viewModel.feedback == 2)
    }

    // Ce qui échoue ne se félicite pas.
    @Test func aFailedAdvanceTriggersNothing() async throws {
        let viewModel = inProgressViewModel()
        await viewModel.load()
        let ghost = InProgressRowModel(item: MediaItem(kind: .series, title: "Fantôme"))

        await viewModel.advance(ghost)

        #expect(viewModel.feedback == 0)
    }

    // Sur la fiche : cocher, tout cocher, abandonner — un seul compteur pour tous les gestes.
    @Test func everyGestureOnTheFicheTriggersTheFeedback() async throws {
        let provider = StubEpisodeProvider(
            seasons: .success([StubEpisodeProvider.season(1, episodes: 3)]),
            episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let media = SwiftDataMediaRepository(context: context)
        let item = MediaItem(kind: .series, title: "Severance")
        try media.add(item, refs: [ExternalRef(provider: "tmdb", value: "tv:95396")])
        let logs = SwiftDataLogRepository(context: context)
        let logUseCase = LogUseCase(repository: media, dedup: DedupUseCase(repository: media))
        let viewModel = SeriesEpisodesViewModel(
            itemID: item.id, repository: media,
            useCase: EpisodeUseCase(repository: SwiftDataEpisodeRepository(context: context),
                                    providers: [provider], log: logUseCase,
                                    edit: EditLogUseCase(repository: logs)),
            status: WatchStatusUseCase(log: logUseCase, edit: EditLogUseCase(repository: logs)))
        await viewModel.load()
        #expect(viewModel.feedback == 0)

        viewModel.toggle(episode: 1, in: 1)
        #expect(viewModel.feedback == 1)

        await viewModel.checkSeason(1)
        #expect(viewModel.feedback == 2)

        viewModel.drop()
        #expect(viewModel.feedback == 3)
    }
}
