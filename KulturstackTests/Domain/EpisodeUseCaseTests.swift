import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct EpisodeUseCaseTests {
    private static let key = "tmdb:tv:95396"

    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func make(provider: StubEpisodeProvider,
                      kind: MediaKind = .series) throws -> (MediaItem, EpisodeUseCase) {
        let media = SwiftDataMediaRepository(context: container.mainContext)
        let item = MediaItem(kind: kind, title: "Severance")
        try media.add(item, refs: [ExternalRef(provider: "tmdb", value: "tv:95396")])
        return (item, makeUseCase(provider))
    }

    private func makeUseCase(_ provider: StubEpisodeProvider) -> EpisodeUseCase {
        let context = container.mainContext
        let media = SwiftDataMediaRepository(context: context)
        return EpisodeUseCase(
            repository: SwiftDataEpisodeRepository(context: context),
            providers: [provider],
            log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
            edit: EditLogUseCase(repository: SwiftDataLogRepository(context: context))
        )
    }

    private func logs() throws -> [LogEntry] {
        try container.mainContext.fetch(FetchDescriptor<LogEntry>())
    }

    // MARK: - Les saisons

    @Test func theSeasonsOfASeriesComeFromTheSource() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1, episodes: 9),
                                                              StubEpisodeProvider.season(2, episodes: 10)]))
        let (item, useCase) = try make(provider: provider)

        let seasons = try await useCase.seasons(of: item)

        #expect(seasons.map(\.number) == [1, 2])
        #expect(provider.seasonCalls == [Self.key])
    }

    @Test func aWorkWithoutEpisodesAsksNothing() async throws {
        let provider = StubEpisodeProvider(seasons: .success([StubEpisodeProvider.season(1)]))
        let (item, useCase) = try make(provider: provider, kind: .film)

        #expect(try await useCase.seasons(of: item).isEmpty)
        #expect(provider.seasonCalls.isEmpty)
    }

    @Test func aSourceFailureIsReported() async throws {
        let provider = StubEpisodeProvider(seasons: .failure(HTTPError.status(500)))
        let (item, useCase) = try make(provider: provider)

        await #expect(throws: HTTPError.status(500)) { try await useCase.seasons(of: item) }
    }

    // MARK: - Ouvrir une saison

    @Test func openingASeasonStoresItAndItsEpisodes() async throws {
        let provider = StubEpisodeProvider(episodes: [2: .success([StubEpisodeProvider.episode(1, title: "Hello, Ms. Cobel"),
                                                                   StubEpisodeProvider.episode(2, title: "Goodbye, Mrs. Selvig")])])
        let (item, useCase) = try make(provider: provider)

        let season = try await useCase.open(StubEpisodeProvider.season(2), of: item)

        #expect(season.number == 2)
        #expect(season.orderedEpisodes.map(\.number) == [1, 2])
        #expect(season.orderedEpisodes.first?.title == "Hello, Ms. Cobel")
        #expect(try container.mainContext.fetchCount(FetchDescriptor<Season>()) == 1)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<Episode>()) == 2)
    }

    // Une série de dix saisons ne déclenche pas dix appels réseau à l'ouverture de la fiche.
    @Test func openingOneSeasonLoadsOnlyThatOne() async throws {
        let provider = StubEpisodeProvider(
            seasons: .success((1...10).map { StubEpisodeProvider.season($0) }),
            episodes: [3: .success([StubEpisodeProvider.episode(1)])])
        let (item, useCase) = try make(provider: provider)

        _ = try await useCase.seasons(of: item)
        _ = try await useCase.open(StubEpisodeProvider.season(3), of: item)

        #expect(provider.episodeCalls == [.init(key: Self.key, season: 3)])
    }

    @Test func openingASeasonTwiceKeepsOneCopyAndRefreshesIt() async throws {
        let provider = StubEpisodeProvider(episodes: [1: .success([StubEpisodeProvider.episode(1, title: "Titre provisoire")])])
        let (item, useCase) = try make(provider: provider)
        _ = try await useCase.open(StubEpisodeProvider.season(1), of: item)

        let refreshed = makeUseCase(StubEpisodeProvider(episodes: [1: .success([StubEpisodeProvider.episode(1, title: "Good News About Hell"),
                                                                            StubEpisodeProvider.episode(2)])]))
        let season = try await refreshed.open(StubEpisodeProvider.season(1), of: item)

        #expect(try container.mainContext.fetchCount(FetchDescriptor<Season>()) == 1)
        #expect(season.orderedEpisodes.map(\.number) == [1, 2])
        #expect(season.orderedEpisodes.first?.title == "Good News About Hell")
    }

    // Les épisodes sont du cache, les logs sont de la donnée : recharger une saison ne décoche rien.
    @Test func reopeningASeasonKeepsWhatWasChecked() async throws {
        let provider = StubEpisodeProvider(episodes: [1: .success([StubEpisodeProvider.episode(1),
                                                                   StubEpisodeProvider.episode(2)])])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(1), of: item)
        try useCase.toggle(season.orderedEpisodes[0], of: item)

        let again = try await useCase.open(StubEpisodeProvider.season(1), of: item)

        #expect(again.orderedEpisodes.map(\.isWatched) == [true, false])
        #expect(try logs().count == 1)
    }

    @Test func aSeasonAnnouncedButEmptyStoresNoEpisode() async throws {
        let provider = StubEpisodeProvider(episodes: [4: .success([])])
        let (item, useCase) = try make(provider: provider)

        let season = try await useCase.open(StubEpisodeProvider.season(4), of: item)

        #expect(season.orderedEpisodes.isEmpty)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<Season>()) == 1)
    }

    // MARK: - Cocher

    @Test func checkingAnEpisodeWritesOneDoneLogCarryingIt() async throws {
        let provider = StubEpisodeProvider(episodes: [2: .success([StubEpisodeProvider.episode(4)])])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(2), of: item)
        let episode = try #require(season.orderedEpisodes.first)

        try useCase.toggle(episode, of: item)

        let saved = try #require(try logs().first)
        #expect(try logs().count == 1)
        #expect(saved.status == .done)
        #expect(saved.episode?.number == 4)
        #expect(saved.item?.id == item.id)
        #expect(episode.isWatched)
    }

    @Test func uncheckingRemovesTheLog() async throws {
        let provider = StubEpisodeProvider(episodes: [2: .success([StubEpisodeProvider.episode(4)])])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(2), of: item)
        let episode = try #require(season.orderedEpisodes.first)

        try useCase.toggle(episode, of: item)
        try useCase.toggle(episode, of: item)

        #expect(try logs().isEmpty)
        #expect(!episode.isWatched)
    }

    @Test func checkingThenUncheckingThenCheckingLeavesOneLog() async throws {
        let provider = StubEpisodeProvider(episodes: [2: .success([StubEpisodeProvider.episode(4)])])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(2), of: item)
        let episode = try #require(season.orderedEpisodes.first)

        try useCase.toggle(episode, of: item)
        try useCase.toggle(episode, of: item)
        try useCase.toggle(episode, of: item)

        #expect(try logs().count == 1)
    }

    // MARK: - Tout cocher jusqu'ici

    @Test func checkingUpToHereFillsTheHolesWithoutDoubling() async throws {
        let provider = StubEpisodeProvider(episodes: [1: .success((1...5).map { StubEpisodeProvider.episode($0) })])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(1), of: item)
        try useCase.toggle(season.orderedEpisodes[1], of: item)

        try useCase.checkUpTo(season.orderedEpisodes[3], of: item)

        #expect(season.orderedEpisodes.map(\.isWatched) == [true, true, true, true, false])
        #expect(try logs().count == 4)
    }

    @Test func checkingUpToHereLeavesTheRestAlone() async throws {
        let provider = StubEpisodeProvider(episodes: [1: .success((1...5).map { StubEpisodeProvider.episode($0) })])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(1), of: item)

        try useCase.checkUpTo(season.orderedEpisodes[0], of: item)

        #expect(season.orderedEpisodes.map(\.isWatched) == [true, false, false, false, false])
    }

    @Test func checkingUpToHereTwiceChangesNothingTheSecondTime() async throws {
        let provider = StubEpisodeProvider(episodes: [1: .success((1...3).map { StubEpisodeProvider.episode($0) })])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(1), of: item)

        try useCase.checkUpTo(season.orderedEpisodes[2], of: item)
        try useCase.checkUpTo(season.orderedEpisodes[2], of: item)

        #expect(try logs().count == 3)
    }

    // MARK: - Toute une saison (retour du 27/09)

    @Test func checkingAWholeSeasonChecksEveryEpisode() async throws {
        let provider = StubEpisodeProvider(episodes: [1: .success((1...5).map { StubEpisodeProvider.episode($0) })])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(1), of: item)

        try useCase.checkAll(season, of: item)

        #expect(season.orderedEpisodes.allSatisfy { $0.isWatched })
        #expect(try logs().count == 5)
    }

    // « J'ai vu toute la saison » alors que trois épisodes l'étaient déjà : cinq logs, pas huit.
    @Test func checkingAWholeSeasonDoesNotDoubleWhatIsAlreadyChecked() async throws {
        let provider = StubEpisodeProvider(episodes: [1: .success((1...5).map { StubEpisodeProvider.episode($0) })])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(1), of: item)
        for index in [0, 2, 4] { try useCase.toggle(season.orderedEpisodes[index], of: item) }

        try useCase.checkAll(season, of: item)

        #expect(season.orderedEpisodes.allSatisfy { $0.isWatched })
        #expect(try logs().count == 5)
    }

    @Test func checkingAnEmptySeasonChangesNothing() async throws {
        let provider = StubEpisodeProvider(episodes: [1: .success([])])
        let (item, useCase) = try make(provider: provider)
        let season = try stored(season: 1, of: item)

        try useCase.checkAll(season, of: item)

        #expect(try logs().isEmpty)
    }

    @Test func uncheckingAWholeSeasonRemovesItsLogs() async throws {
        let provider = StubEpisodeProvider(episodes: [1: .success((1...4).map { StubEpisodeProvider.episode($0) })])
        let (item, useCase) = try make(provider: provider)
        let season = try await useCase.open(StubEpisodeProvider.season(1), of: item)
        try useCase.checkAll(season, of: item)

        try useCase.uncheckAll(season, of: item)

        #expect(season.orderedEpisodes.allSatisfy { !$0.isWatched })
        #expect(try logs().isEmpty)
    }

    // Décocher une saison ne touche qu'elle : la saison 2 garde ce qui a été vu.
    @Test func uncheckingASeasonLeavesTheOtherSeasonsAlone() async throws {
        let provider = StubEpisodeProvider(episodes: [
            1: .success((1...3).map { StubEpisodeProvider.episode($0) }),
            2: .success((1...3).map { StubEpisodeProvider.episode($0) }),
        ])
        let (item, useCase) = try make(provider: provider)
        let first = try await useCase.open(StubEpisodeProvider.season(1), of: item)
        let second = try await useCase.open(StubEpisodeProvider.season(2), of: item)
        try useCase.checkAll(first, of: item)
        try useCase.checkAll(second, of: item)

        try useCase.uncheckAll(first, of: item)

        #expect(first.orderedEpisodes.allSatisfy { !$0.isWatched })
        #expect(second.orderedEpisodes.allSatisfy { $0.isWatched })
        #expect(try logs().count == 3)
    }

    private func stored(season number: Int, of item: MediaItem) throws -> Season {
        let repository = SwiftDataEpisodeRepository(context: container.mainContext)
        let season = try Season.make(number: number, item: item)
        try repository.add(season)
        return season
    }
}
