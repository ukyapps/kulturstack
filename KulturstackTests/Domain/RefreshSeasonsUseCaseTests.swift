import Foundation
import SwiftData
import Testing
@testable import Kulturstack

// « C'est pas dans suivi que ça apparaît juste quand y'a une suite ? » (founder, 30/09).
// Ce passage est ce qui l'apprend sans qu'elle ouvre la fiche.
@MainActor
struct RefreshSeasonsUseCaseTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private var context: ModelContext { container.mainContext }

    private func make(_ provider: StubEpisodeProvider,
                      history: StubRefreshHistory) -> RefreshSeasonsUseCase {
        let media = SwiftDataMediaRepository(context: context)
        let logs = SwiftDataLogRepository(context: context)
        let episodes = EpisodeUseCase(repository: SwiftDataEpisodeRepository(context: context),
                                      providers: [provider],
                                      log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
                                      edit: EditLogUseCase(repository: logs))
        return RefreshSeasonsUseCase(media: media, logs: logs, episodes: episodes, history: history)
    }

    @discardableResult
    private func series(_ title: String, id: Int, status: LogStatus, seasonCount: Int?,
                        kind: MediaKind = .series) throws -> MediaItem {
        let media = SwiftDataMediaRepository(context: context)
        let item = MediaItem(kind: kind, title: title)
        try media.add(item, refs: [ExternalRef(provider: "tmdb", value: "tv:\(id)")])
        if let seasonCount { try item.setDetails(SeriesDetails(seasonCount: seasonCount)) }
        context.insert(try LogEntry.make(item: item, status: status))
        try context.save()
        return item
    }

    private func provider(id: Int, seasons: [Int]) -> StubEpisodeProvider {
        StubEpisodeProvider(key: "tmdb:tv:\(id)",
                            seasons: .success(seasons.map { StubEpisodeProvider.season($0) }))
    }

    // Le vrai cas : elle a vu la saison 1, l'a marquée finie, et la 2 sort.
    @Test func aSeasonThatCameOutIsLearnedWithoutOpeningTheFiche() async throws {
        let item = try series("Severance", id: 1, status: .done, seasonCount: 1)
        try watchWholeFirstSeason(of: item, episodes: 3)
        let history = StubRefreshHistory()

        let learned = await make(provider(id: 1, seasons: [1, 2]), history: history).run()

        #expect(learned == 1)
        #expect((item.details as? SeriesDetails)?.seasonCount == 2)
        // Et c'est ça qui la fait revenir : une suite existe, dans une saison jamais ouverte.
        let next = try #require(InProgressUseCase.nextUp(for: item))
        #expect(next.season == 2)
        #expect(next.episode == nil)
    }

    private func watchWholeFirstSeason(of item: MediaItem, episodes count: Int) throws {
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        for number in 1...count { context.insert(Episode(number: number, season: season)) }
        try context.save()
        for episode in season.orderedEpisodes {
            context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        try context.save()
    }

    @Test func nothingNewLearnsNothing() async throws {
        try series("Severance", id: 1, status: .inProgress, seasonCount: 2)
        let history = StubRefreshHistory()

        #expect(await make(provider(id: 1, seasons: [1, 2]), history: history).run() == 0)
    }

    // Une fois par jour : deux ouvertures de l'app dans la même journée ne font qu'un passage.
    @Test func twoLaunchesTheSameDayMakeOnlyOnePass() async throws {
        try series("Severance", id: 1, status: .done, seasonCount: 1)
        let history = StubRefreshHistory()
        let source = provider(id: 1, seasons: [1, 2])
        let useCase = make(source, history: history)
        let morning = Date()

        await useCase.run(now: morning)
        await useCase.run(now: morning.addingTimeInterval(3600))

        #expect(history.recorded.count == 1)
        #expect(source.seasonCalls.count == 1)
    }

    @Test func aDayLaterThePassHappensAgain() async throws {
        try series("Severance", id: 1, status: .done, seasonCount: 1)
        let history = StubRefreshHistory()
        let source = provider(id: 1, seasons: [1, 2])
        let useCase = make(source, history: history)
        let morning = Date()

        await useCase.run(now: morning)
        await useCase.run(now: morning.addingTimeInterval(RefreshSeasonsUseCase.interval + 60))

        #expect(history.recorded.count == 2)
    }

    // Abandonner est un choix : la série ne reviendra pas, l'interroger serait un appel pour rien.
    @Test func aDroppedSeriesIsNeverAsked() async throws {
        try series("Severance", id: 1, status: .dropped, seasonCount: 1)
        let source = provider(id: 1, seasons: [1, 2])

        await make(source, history: StubRefreshHistory()).run()

        #expect(source.seasonCalls.isEmpty)
    }

    // Une envie n'est pas une série suivie : rien à rafraîchir tant qu'on ne l'a pas commencée.
    @Test func aWishIsNeverAsked() async throws {
        try series("Severance", id: 1, status: .wishlist, seasonCount: 1)
        let source = provider(id: 1, seasons: [1, 2])

        await make(source, history: StubRefreshHistory()).run()

        #expect(source.seasonCalls.isEmpty)
    }

    // Hors ligne : rien ne casse, et surtout rien n'est écrasé par un zéro.
    @Test func aFailingSourceLeavesWhatWeKnewAlone() async throws {
        let item = try series("Severance", id: 1, status: .done, seasonCount: 3)
        let source = StubEpisodeProvider(key: "tmdb:tv:1", seasons: .failure(HTTPError.status(500)))

        let learned = await make(source, history: StubRefreshHistory()).run()

        #expect(learned == 0)
        #expect((item.details as? SeriesDetails)?.seasonCount == 3)
    }

    // Une source qui ne connaît pas la série rend une liste vide : on n'écrit pas zéro.
    @Test func anEmptyAnswerLeavesWhatWeKnewAlone() async throws {
        let item = try series("Severance", id: 1, status: .done, seasonCount: 3)
        let source = StubEpisodeProvider(key: "tmdb:tv:1", seasons: .success([]))

        await make(source, history: StubRefreshHistory()).run()

        #expect((item.details as? SeriesDetails)?.seasonCount == 3)
    }

    // Les spéciaux ne gonflent pas le compte.
    @Test func theSpecialsAreNotCounted() async throws {
        let item = try series("Severance", id: 1, status: .done, seasonCount: 3)
        let source = StubEpisodeProvider(
            key: "tmdb:tv:1",
            seasons: .success([StubEpisodeProvider.season(1), StubEpisodeProvider.season(2),
                               StubEpisodeProvider.season(0, isSpecials: true)]))

        await make(source, history: StubRefreshHistory()).run()

        #expect((item.details as? SeriesDetails)?.seasonCount == 2)
    }

    // Vingt séries au maximum, les plus récemment touchées d'abord : pas de rafale au lancement.
    @Test func theNumberOfSeriesAskedIsCapped() async throws {
        let media = SwiftDataMediaRepository(context: context)
        for index in 1...25 {
            let item = MediaItem(kind: .series, title: "Série \(index)")
            try media.add(item, refs: [ExternalRef(provider: "tmdb", value: "tv:\(index)")])
            try item.setDetails(SeriesDetails(seasonCount: 1))
            context.insert(try LogEntry.make(item: item, status: .done,
                                             date: Date().addingTimeInterval(-Double(index) * 60)))
        }
        try context.save()
        // Une source qui répond à tout le monde : ce qu'on compte, c'est le nombre d'appels.
        let source = CountingEpisodeProvider()

        await RefreshSeasonsUseCase(
            media: media, logs: SwiftDataLogRepository(context: context),
            episodes: EpisodeUseCase(repository: SwiftDataEpisodeRepository(context: context),
                                     providers: [source],
                                     log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
                                     edit: EditLogUseCase(repository: SwiftDataLogRepository(context: context))),
            history: StubRefreshHistory()).run()

        #expect(source.asked.count == RefreshSeasonsUseCase.maxSeries)
        // Les plus récemment touchées : la série 1 est la plus récente, la 25 la plus vieille.
        #expect(source.asked.contains("tmdb:tv:1"))
        #expect(source.asked.contains("tmdb:tv:25") == false)
    }
}

// Une source qui accepte n'importe quelle clé TMDB et note ce qu'on lui a demandé.
private final class CountingEpisodeProvider: EpisodeProvider, @unchecked Sendable {
    private(set) var asked: [String] = []

    func seasons(forKey key: String) async throws -> [SeasonSummary] {
        guard key.hasPrefix("tmdb:tv:") else { return [] }
        asked.append(key)
        return [SeasonSummary(number: 1, title: nil, episodeCount: 3, airDate: nil),
                SeasonSummary(number: 2, title: nil, episodeCount: 3, airDate: nil)]
    }

    func episodes(forKey key: String, season: Int) async throws -> [EpisodeSummary] { [] }
}
