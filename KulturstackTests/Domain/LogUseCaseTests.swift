import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct LogUseCaseTests {
    private let dune = MediaCandidate(
        id: "tmdb:movie:438631", kind: .film, title: "Dune", originalTitle: "Dune", year: 2021,
        creators: ["Denis Villeneuve"], coverURL: URL(string: "https://img/dune.jpg"), summary: "Paul Atreides…",
        externalKeys: ["tmdb:movie:438631", "imdb:tt1160419"], details: FilmDetails(runtimeMinutes: 155), providerID: "tmdb")

    private func makeUseCase() throws -> (ModelContainer, LogUseCase) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        return (container, LogUseCase(repository: repository, dedup: DedupUseCase(repository: repository)))
    }

    private func counts(_ container: ModelContainer) throws -> (items: Int, logs: Int, refs: Int) {
        let context = container.mainContext
        return (try context.fetchCount(FetchDescriptor<MediaItem>()),
                try context.fetchCount(FetchDescriptor<LogEntry>()),
                try context.fetchCount(FetchDescriptor<ExternalRef>()))
    }

    @Test func firstLogCreatesTheItemItsRefsAndADoneLogDatedNow() throws {
        let (container, useCase) = try makeUseCase()
        let before = Date.now

        let log = try useCase.logNow(dune)

        let item = try #require(log.item)
        #expect(item.title == "Dune")
        #expect(item.kind == .film)
        #expect(item.year == 2021)
        #expect(item.creators == ["Denis Villeneuve"])
        #expect(item.coverURL == dune.coverURL)
        #expect(item.summary == "Paul Atreides…")
        #expect((item.details as? FilmDetails)?.runtimeMinutes == 155)
        #expect(Set(item.externalRefs.map(\.key)) == ["tmdb:movie:438631", "imdb:tt1160419"])
        #expect(log.status == .done)
        #expect(log.source == "manual")
        #expect(log.rating == nil)
        #expect(log.date >= before && log.date <= .now)
        #expect(try counts(container) == (1, 1, 2))
    }

    @Test func loggingTheSameCandidateTwiceGivesOneItemAndTwoLogs() throws {
        let (container, useCase) = try makeUseCase()

        let first = try useCase.logNow(dune)
        let second = try useCase.logNow(dune)

        #expect(first.item?.persistentModelID == second.item?.persistentModelID)
        #expect(try counts(container) == (1, 2, 2))
    }

    @Test func candidatesSharingAKeyLandOnTheSameItemAndNewKeysAreKept() throws {
        let (container, useCase) = try makeUseCase()
        let fromTrakt = MediaCandidate(
            id: "imdb:tt1160419", kind: .film, title: "Dune (2021)", originalTitle: nil, year: 2021, creators: [],
            coverURL: nil, summary: nil, externalKeys: ["imdb:tt1160419", "trakt:movie:1"], details: FilmDetails(), providerID: "trakt")

        let first = try useCase.logNow(dune)
        let second = try useCase.logNow(fromTrakt)

        #expect(first.item?.persistentModelID == second.item?.persistentModelID)
        #expect(second.item?.title == "Dune")
        #expect(Set(second.item?.externalRefs.map(\.key) ?? []) == ["tmdb:movie:438631", "imdb:tt1160419", "trakt:movie:1"])
        #expect(try counts(container) == (1, 2, 3))
    }

    @Test func differentWorksStayDifferentItems() throws {
        let (container, useCase) = try makeUseCase()
        let messiah = MediaCandidate(
            id: "ol:work:OL893461W", kind: .book, title: "Dune Messiah", originalTitle: nil, year: 1969, creators: ["Frank Herbert"],
            coverURL: nil, summary: nil, externalKeys: ["ol:work:OL893461W"], details: BookDetails(), providerID: "openlibrary")

        try useCase.logNow(dune)
        try useCase.logNow(messiah)

        #expect(try counts(container) == (2, 2, 3))
    }

    @Test func statusCanBeWishlistAndIsValidatedForTheKind() throws {
        let (container, useCase) = try makeUseCase()

        let wish = try useCase.logNow(dune, status: .wishlist)
        #expect(wish.status == .wishlist)

        #expect(throws: DomainError.self) {
            try useCase.logNow(dune, status: .inProgress)
        }
        #expect(try counts(container).logs == 1)
    }

    @Test func repositoryFindsAnItemByAnyOfItsKeys() throws {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let item = MediaItem(kind: .film, title: "Dune")
        try repository.add(item, refs: [ExternalRef(provider: "tmdb", value: "movie:438631")])

        #expect(try repository.findItem(withAnyKey: ["nope:1", "tmdb:movie:438631"])?.title == "Dune")
        #expect(try repository.findItem(withAnyKey: ["nope:1"]) == nil)
        #expect(try repository.findItem(withAnyKey: []) == nil)
    }
}
