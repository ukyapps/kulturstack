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
}
