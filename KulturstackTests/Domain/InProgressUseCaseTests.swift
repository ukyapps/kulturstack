import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct InProgressUseCaseTests {
    private let container: ModelContainer

    init() throws { container = try ModelContainerFactory.inMemory() }

    private var context: ModelContext { container.mainContext }

    private func useCase() -> InProgressUseCase {
        InProgressUseCase(repository: SwiftDataLogRepository(context: context))
    }

    @discardableResult
    private func work(_ title: String, kind: MediaKind = .series) -> MediaItem {
        let item = MediaItem(kind: kind, title: title)
        context.insert(item)
        return item
    }

    @discardableResult
    private func season(_ number: Int, of item: MediaItem, episodes: Int) throws -> Season {
        let season = try Season.make(number: number, item: item)
        context.insert(season)
        for index in 1...episodes { context.insert(Episode(number: index, season: season)) }
        try context.save()
        return season
    }

    private func status(_ status: LogStatus, on item: MediaItem, at date: Date = .now) throws {
        context.insert(try LogEntry.make(item: item, status: status, date: date))
        try context.save()
    }

    private func watch(_ numbers: [Int], of season: Season, item: MediaItem) throws {
        for episode in season.orderedEpisodes where numbers.contains(episode.number) {
            context.insert(try LogEntry.make(item: item, status: .done, episode: episode))
        }
        try context.save()
    }

    // MARK: - Ce qui est en cours

    @Test func aWorkInProgressIsListed() async throws {
        let item = work("Severance")
        try status(.inProgress, on: item)

        #expect(try await useCase().items().map(\.title) == ["Severance"])
    }

    @Test func aFinishedWorkIsNotListed() async throws {
        let item = work("Severance")
        try status(.inProgress, on: item, at: Date(timeIntervalSince1970: 100))
        try status(.done, on: item, at: Date(timeIntervalSince1970: 200))

        #expect(try await useCase().items().isEmpty)
    }

    @Test func aDroppedWorkIsNotListed() async throws {
        let item = work("Severance")
        try status(.inProgress, on: item, at: Date(timeIntervalSince1970: 100))
        try status(.dropped, on: item, at: Date(timeIntervalSince1970: 200))

        #expect(try await useCase().items().isEmpty)
    }

    // Reprendre après un abandon remet l'œuvre dans la liste.
    @Test func aWorkPickedBackUpIsListedAgain() async throws {
        let item = work("Severance")
        try status(.inProgress, on: item, at: Date(timeIntervalSince1970: 100))
        try status(.dropped, on: item, at: Date(timeIntervalSince1970: 200))
        try status(.inProgress, on: item, at: Date(timeIntervalSince1970: 300))

        #expect(try await useCase().items().map(\.title) == ["Severance"])
    }

    @Test func anEnvyIsNotInProgress() async throws {
        let item = work("Shogun")
        try status(.wishlist, on: item)

        #expect(try await useCase().items().isEmpty)
    }

    @Test func aWorkStartedTwiceAppearsOnce() async throws {
        let item = work("Severance")
        try status(.inProgress, on: item, at: Date(timeIntervalSince1970: 100))
        try status(.inProgress, on: item, at: Date(timeIntervalSince1970: 200))

        #expect(try await useCase().items().count == 1)
    }

    @Test func theMostRecentlyStartedComesFirst() async throws {
        let old = work("Shogun")
        let recent = work("Severance")
        try status(.inProgress, on: old, at: Date(timeIntervalSince1970: 100))
        try status(.inProgress, on: recent, at: Date(timeIntervalSince1970: 200))

        #expect(try await useCase().items().map(\.title) == ["Severance", "Shogun"])
    }

    // Un livre en cours a sa place dans la liste, même sans épisode.
    @Test func aBookInProgressIsListedToo() async throws {
        let book = work("Piranesi", kind: .book)
        try status(.inProgress, on: book)

        #expect(try await useCase().items().map(\.title) == ["Piranesi"])
        #expect(InProgressUseCase.next(for: book) == nil)
    }

    // MARK: - Le prochain épisode

    @Test func theNextEpisodeIsTheFirstUncheckedOne() throws {
        let item = work("Severance")
        let one = try season(1, of: item, episodes: 5)
        try watch([1, 2], of: one, item: item)

        #expect(InProgressUseCase.next(for: item)?.number == 3)
        #expect(InProgressUseCase.lastWatched(of: item)?.number == 2)
    }

    @Test func theNextEpisodeCrossesIntoTheFollowingSeason() throws {
        let item = work("Severance")
        let one = try season(1, of: item, episodes: 2)
        try season(2, of: item, episodes: 3)
        try watch([1, 2], of: one, item: item)

        let next = try #require(InProgressUseCase.next(for: item))
        #expect(next.season?.number == 2)
        #expect(next.number == 1)
    }

    // Les bonus ne sont jamais « la suite », même pas cochés en partie.
    @Test func theNextEpisodeIgnoresTheSpecials() throws {
        let item = work("Severance")
        let one = try season(1, of: item, episodes: 2)
        try season(0, of: item, episodes: 4)
        try watch([1, 2], of: one, item: item)

        #expect(InProgressUseCase.next(for: item) == nil)
    }

    @Test func aFullyWatchedSeriesHasNoNextEpisode() throws {
        let item = work("Severance")
        let one = try season(1, of: item, episodes: 2)
        try watch([1, 2], of: one, item: item)

        #expect(InProgressUseCase.next(for: item) == nil)
    }

    @Test func aSeriesNeverStartedProposesItsFirstEpisode() throws {
        let item = work("Severance")
        try season(1, of: item, episodes: 3)

        #expect(InProgressUseCase.next(for: item)?.number == 1)
        #expect(InProgressUseCase.lastWatched(of: item) == nil)
    }

    // Un trou au milieu : la suite, c'est le trou, pas ce qui vient après le dernier vu.
    @Test func theNextEpisodeFillsTheHoleFirst() throws {
        let item = work("Severance")
        let one = try season(1, of: item, episodes: 5)
        try watch([1, 3, 4], of: one, item: item)

        #expect(InProgressUseCase.next(for: item)?.number == 2)
        #expect(InProgressUseCase.lastWatched(of: item)?.number == 4)
    }

    // MARK: - La saison suivante, jamais ouverte

    // « Quand je finis une saison, dans en cours, ça fait disparaître la série alors que ça
    // devrait afficher la saison suivante » (founder, 30/09). L'onglet ne va pas sur le
    // réseau : c'est le nombre de saisons, déjà rangé dans la fiche, qui le lui apprend.
    @Test func theNextEpisodeMovesToTheFollowingSeasonEvenWhenItWasNeverOpened() throws {
        let item = work("Severance")
        try item.setDetails(SeriesDetails(seasonCount: 2))
        let one = try season(1, of: item, episodes: 3)
        try watch([1, 2, 3], of: one, item: item)

        let next = try #require(InProgressUseCase.nextUp(for: item))
        #expect(next.season == 2)
        #expect(next.number == 1)
        // Elle n'existe pas encore en base : c'est le ✓ qui la chargera.
        #expect(next.episode == nil)
    }

    // Sans savoir combien de saisons existent, on ne devine pas : mieux vaut « Terminé »
    // qu'une saison 2 inventée.
    @Test func withoutKnowingHowManySeasonsExistThereIsNoNextAfterTheLastKnownOne() throws {
        let item = work("Severance")
        let one = try season(1, of: item, episodes: 3)
        try watch([1, 2, 3], of: one, item: item)

        #expect(InProgressUseCase.nextUp(for: item) == nil)
    }

    @Test func theLastSeasonFinishedReallyHasNoNext() throws {
        let item = work("Severance")
        try item.setDetails(SeriesDetails(seasonCount: 2))
        let one = try season(1, of: item, episodes: 2)
        let two = try season(2, of: item, episodes: 2)
        try watch([1, 2], of: one, item: item)
        try watch([1, 2], of: two, item: item)

        #expect(InProgressUseCase.nextUp(for: item) == nil)
    }

    // Un trou dans une saison connue passe avant la saison suivante : on ne saute rien.
    @Test func aHoleInAKnownSeasonComesBeforeTheFollowingSeason() throws {
        let item = work("Severance")
        try item.setDetails(SeriesDetails(seasonCount: 2))
        let one = try season(1, of: item, episodes: 3)
        try watch([1, 3], of: one, item: item)

        let next = try #require(InProgressUseCase.nextUp(for: item))
        #expect(next.season == 1)
        #expect(next.number == 2)
        #expect(next.episode != nil)
    }

    // Une saison en base mais vide (créée sans ses épisodes) ne compte pas comme connue.
    @Test func anEmptySeasonDoesNotPassForAKnownOne() throws {
        let item = work("Severance")
        try item.setDetails(SeriesDetails(seasonCount: 3))
        let one = try season(1, of: item, episodes: 2)
        try watch([1, 2], of: one, item: item)
        let two = try Season.make(number: 2, item: item)
        context.insert(two)
        try context.save()

        let next = try #require(InProgressUseCase.nextUp(for: item))
        #expect(next.season == 2)
    }

    // MARK: - Un podcast se reprend par l'autre bout

    // « On écoute un podcast par le plus récent, pas par le premier non écouté » — la liste
    // va du plus ancien au plus récent depuis le 30/09, donc la suite est le dernier non coché.
    @Test func theNextEpisodeOfAPodcastIsTheMostRecentNotListened() throws {
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        for number in 1...4 {
            context.insert(Episode(number: number, title: "Épisode \(number)",
                                   externalID: "guid-\(number)", season: season))
        }
        try context.save()
        for episode in season.orderedEpisodes where episode.number == 2 {
            context.insert(try LogEntry.make(item: podcast, status: .done, episode: episode))
        }
        try context.save()

        let next = try #require(InProgressUseCase.nextUp(for: podcast))

        // Le 4 est le plus récent du flux : c'est lui qu'on écoute, pas le 1 qu'on a sauté.
        #expect(next.number == 4)
        #expect(next.episode?.title == "Épisode 4")
    }

    // Une série, elle, comble ses trous : le 1 sauté passe avant le 4.
    @Test func aSeriesStillFillsItsHolesFirst() throws {
        let item = work("Severance")
        let one = try season(1, of: item, episodes: 4)
        try watch([2], of: one, item: item)

        #expect(InProgressUseCase.nextUp(for: item)?.number == 1)
    }

    @Test func aPodcastEntirelyListenedHasNoNext() throws {
        let context = container.mainContext
        let podcast = MediaItem(kind: .podcast, title: "Le code a changé")
        context.insert(podcast)
        let season = try Season.make(number: 1, item: podcast)
        context.insert(season)
        for number in 1...2 {
            context.insert(Episode(number: number, externalID: "guid-\(number)", season: season))
        }
        try context.save()
        for episode in season.orderedEpisodes {
            context.insert(try LogEntry.make(item: podcast, status: .done, episode: episode))
        }
        try context.save()

        #expect(InProgressUseCase.nextUp(for: podcast) == nil)
    }
}
