import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct WatchStatusUseCaseTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private func make() throws -> (MediaItem, Season, WatchStatusUseCase) {
        let context = container.mainContext
        let media = SwiftDataMediaRepository(context: context)
        let item = MediaItem(kind: .series, title: "Severance")
        try media.add(item, refs: [ExternalRef(provider: "tmdb", value: "tv:95396")])
        let season = try Season.make(number: 1, item: item)
        context.insert(season)
        for number in 1...3 { context.insert(Episode(number: number, season: season)) }
        try context.save()
        let useCase = WatchStatusUseCase(
            log: LogUseCase(repository: media, dedup: DedupUseCase(repository: media)),
            edit: EditLogUseCase(repository: SwiftDataLogRepository(context: context)))
        return (item, season, useCase)
    }

    private func check(_ numbers: [Int], of season: Season, item: MediaItem) throws {
        for episode in season.orderedEpisodes where numbers.contains(episode.number) {
            container.mainContext.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        try container.mainContext.save()
    }

    private func statusLogs(_ item: MediaItem) -> [LogEntry] {
        item.logs.filter { $0.episode == nil }
    }

    // MARK: - En cours

    @Test func aSeriesWithoutACheckedEpisodeHasNoStatus() throws {
        let (item, _, useCase) = try make()

        try useCase.refreshAfterChecking(item)

        #expect(WatchStatusUseCase.status(of: item) == nil)
        #expect(statusLogs(item).isEmpty)
    }

    @Test func checkingAFirstEpisodePutsTheSeriesInProgress() throws {
        let (item, season, useCase) = try make()
        try check([1], of: season, item: item)

        try useCase.refreshAfterChecking(item)

        let status = try #require(statusLogs(item).first)
        #expect(statusLogs(item).count == 1)
        #expect(status.status == .inProgress)
        #expect(status.episode == nil)
        #expect(status.source == WatchStatusUseCase.automaticSource)
        #expect(WatchStatusUseCase.status(of: item) == .inProgress)
    }

    @Test func checkingMoreEpisodesDoesNotAddASecondStatus() throws {
        let (item, season, useCase) = try make()
        try check([1], of: season, item: item)
        try useCase.refreshAfterChecking(item)

        try check([2, 3], of: season, item: item)
        try useCase.refreshAfterChecking(item)

        #expect(statusLogs(item).count == 1)
    }

    // Décocher, c'est corriger une erreur : le statut posé tout seul s'en va avec.
    @Test func uncheckingEverythingTakesBackTheAutomaticStatus() throws {
        let (item, season, useCase) = try make()
        try check([1], of: season, item: item)
        try useCase.refreshAfterChecking(item)

        for log in item.logs.filter({ $0.episode != nil }) { container.mainContext.delete(log) }
        try container.mainContext.save()
        try useCase.refreshAfterChecking(item)

        #expect(WatchStatusUseCase.status(of: item) == nil)
        #expect(statusLogs(item).isEmpty)
    }

    // Ce qui a été dit à la main reste : décocher n'efface pas « abandonnée ».
    @Test func uncheckingEverythingKeepsWhatWasSaidByHand() throws {
        let (item, season, useCase) = try make()
        try check([1], of: season, item: item)
        try useCase.refreshAfterChecking(item)
        try useCase.drop(item)

        for log in item.logs.filter({ $0.episode != nil }) { container.mainContext.delete(log) }
        try container.mainContext.save()
        try useCase.refreshAfterChecking(item)

        #expect(WatchStatusUseCase.status(of: item) == .dropped)
    }

    // MARK: - Abandonner et reprendre

    @Test func droppingThenResumingEndsInProgress() throws {
        let (item, season, useCase) = try make()
        try check([1], of: season, item: item)
        try useCase.refreshAfterChecking(item)

        try useCase.drop(item, now: .now.addingTimeInterval(60))
        #expect(WatchStatusUseCase.status(of: item) == .dropped)

        try useCase.resume(item, now: .now.addingTimeInterval(120))
        #expect(WatchStatusUseCase.status(of: item) == .inProgress)
    }

    @Test func checkingAnEpisodeAfterDroppingPutsItBackInProgress() throws {
        let (item, season, useCase) = try make()
        try check([1], of: season, item: item)
        try useCase.refreshAfterChecking(item)
        try useCase.drop(item, now: .now.addingTimeInterval(60))

        try check([2], of: season, item: item)
        try useCase.refreshAfterChecking(item, now: .now.addingTimeInterval(120))

        #expect(WatchStatusUseCase.status(of: item) == .inProgress)
    }

    // Severance : saison 1 finie, saison 2 qui sort. Cocher un épisode après coup la remet en cours.
    @Test func aFinishedSeriesThatStartsAgainGoesBackInProgress() throws {
        let (item, season, useCase) = try make()
        try check([1], of: season, item: item)
        try useCase.refreshAfterChecking(item, now: Date(timeIntervalSince1970: 100))
        try useCase.finish(item, now: Date(timeIntervalSince1970: 200))

        let next = Episode(number: 4, season: season)
        container.mainContext.insert(next)
        container.mainContext.insert(try LogEntry.make(item: item, status: .done,
                                                       date: Date(timeIntervalSince1970: 300), episode: next))
        try container.mainContext.save()
        try useCase.refreshAfterChecking(item, now: Date(timeIntervalSince1970: 300))

        #expect(WatchStatusUseCase.status(of: item) == .inProgress)
    }

    // Une série finie le reste tant qu'on n'a rien regardé depuis.
    @Test func aFinishedSeriesWithoutANewEpisodeStaysDone() throws {
        let (item, season, useCase) = try make()
        try check([1], of: season, item: item)
        try useCase.refreshAfterChecking(item, now: Date(timeIntervalSince1970: 100))
        try useCase.finish(item, now: Date.now.addingTimeInterval(3600))

        try useCase.refreshAfterChecking(item)

        #expect(WatchStatusUseCase.status(of: item) == .done)
    }

    // MARK: - Le statut courant

    @Test func theStatusIsTheLatestLogThatTalksAboutTheWork() throws {
        let (item, season, useCase) = try make()
        try check([1], of: season, item: item)
        try useCase.refreshAfterChecking(item, now: Date(timeIntervalSince1970: 100))
        try useCase.finish(item, now: Date(timeIntervalSince1970: 200))

        #expect(WatchStatusUseCase.status(of: item) == .done)
    }

    @Test func anEnvyIsNotAStatus() throws {
        let (item, _, useCase) = try make()
        try useCase.log.wish(item)

        #expect(WatchStatusUseCase.status(of: item) == nil)
    }

    @Test func aCheckedEpisodeIsNotTheStatusOfTheWork() throws {
        let (item, season, _) = try make()
        try check([1, 2, 3], of: season, item: item)

        #expect(WatchStatusUseCase.status(of: item) == nil)
    }

    // MARK: - Terminer toute seule

    private func seasons(_ numbers: [Int], specials: Bool = false) -> [SeasonSummary] {
        numbers.map { SeasonSummary(number: $0, title: nil, episodeCount: 3, airDate: nil) }
            + (specials ? [SeasonSummary(number: 0, title: nil, episodeCount: 2, airDate: nil, isSpecials: true)] : [])
    }

    @Test func everySeasonWatchedMeansTheSeriesIsFinished() throws {
        let (item, season, _) = try make()
        try check([1, 2, 3], of: season, item: item)

        #expect(WatchStatusUseCase.isFullyWatched(item, seasons: seasons([1])))
    }

    @Test func aSeasonWithAHoleDoesNotFinishTheSeries() throws {
        let (item, season, _) = try make()
        try check([1, 3], of: season, item: item)

        #expect(WatchStatusUseCase.isFullyWatched(item, seasons: seasons([1])) == false)
    }

    // Une saison jamais ouverte n'est pas une saison vue : on ne finit pas ce qu'on ignore.
    @Test func aSeasonNeverOpenedDoesNotFinishTheSeries() throws {
        let (item, season, _) = try make()
        try check([1, 2, 3], of: season, item: item)

        #expect(WatchStatusUseCase.isFullyWatched(item, seasons: seasons([1, 2])) == false)
    }

    // Les bonus ne terminent pas une série : la saison 0 ne compte pas.
    @Test func theSpecialsAloneNeverFinishASeries() throws {
        let context = container.mainContext
        let (item, _, _) = try make()
        let specials = try Season.make(number: 0, item: item)
        context.insert(specials)
        context.insert(Episode(number: 1, season: specials))
        try context.save()
        try check([1], of: specials, item: item)

        #expect(WatchStatusUseCase.isFullyWatched(item, seasons: seasons([1], specials: true)) == false)
    }

    @Test func aSeriesFinishesEvenWithSpecialsLeftUnwatched() throws {
        let context = container.mainContext
        let (item, season, _) = try make()
        let specials = try Season.make(number: 0, item: item)
        context.insert(specials)
        context.insert(Episode(number: 1, season: specials))
        try context.save()
        try check([1, 2, 3], of: season, item: item)

        #expect(WatchStatusUseCase.isFullyWatched(item, seasons: seasons([1], specials: true)))
    }

    // L'onglet « En cours » n'a pas la liste des saisons : c'est le compte rangé dans la
    // fiche qui lui dit combien il en existe.
    @Test func theSeasonCountFromTheDetailsIsEnoughToFinish() throws {
        let (item, season, _) = try make()
        try item.setDetails(SeriesDetails(seasonCount: 1))
        try check([1, 2, 3], of: season, item: item)

        #expect(WatchStatusUseCase.isFullyWatched(item))
    }

    // Sans savoir combien de saisons existent, rien n'est fini : mieux vaut « en cours »
    // qu'une série déclarée terminée à tort.
    @Test func withoutKnowingHowManySeasonsExistNothingIsFinished() throws {
        let (item, season, _) = try make()
        try check([1, 2, 3], of: season, item: item)

        #expect(WatchStatusUseCase.isFullyWatched(item) == false)
    }

    @Test func aPodcastIsNeverFinished() throws {
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        for number in 1...2 { context.insert(Episode(number: number, externalID: "guid-\(number)", season: season)) }
        try context.save()
        for episode in season.orderedEpisodes {
            context.insert(try LogEntry.make(item: podcast, status: .done, episode: episode))
        }
        try context.save()

        #expect(WatchStatusUseCase.isFullyWatched(podcast, seasons: seasons([1])) == false)
    }

    // MARK: - Ce que cocher pose comme statut

    @Test func watchingEverythingMarksTheSeriesDoneWithoutAsking() throws {
        let (item, season, useCase) = try make()
        try check([1, 2, 3], of: season, item: item)

        try useCase.refreshAfterChecking(item, seasons: seasons([1]))

        #expect(WatchStatusUseCase.status(of: item) == .done)
    }

    @Test func watchingPartOfItLeavesTheSeriesInProgress() throws {
        let (item, season, useCase) = try make()
        try check([1, 2], of: season, item: item)

        try useCase.refreshAfterChecking(item, seasons: seasons([1]))

        #expect(WatchStatusUseCase.status(of: item) == .inProgress)
    }

    // Un « terminé » posé par l'app se reprend : décocher un épisode remet la série en cours.
    @Test func uncheckingAnEpisodeTakesBackTheAutomaticDone() throws {
        let (item, season, useCase) = try make()
        try check([1, 2, 3], of: season, item: item)
        try useCase.refreshAfterChecking(item, seasons: seasons([1]))
        let last = try #require(season.orderedEpisodes.last)
        for entry in last.logs { try EditLogUseCase(repository: SwiftDataLogRepository(context: container.mainContext)).delete(entry) }

        try useCase.refreshAfterChecking(item, seasons: seasons([1]))

        #expect(WatchStatusUseCase.status(of: item) == .inProgress)
    }

    // Un « terminé » qu'elle a dit elle-même ne se rouvre pas dans son dos.
    @Test func aManualDoneIsNotTakenBack() throws {
        let (item, season, useCase) = try make()
        try check([1, 2], of: season, item: item)
        try useCase.finish(item)

        try useCase.refreshAfterChecking(item, seasons: seasons([1]))

        #expect(WatchStatusUseCase.status(of: item) == .done)
    }
}
