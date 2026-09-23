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

    // Le formulaire « Logger » de la fiche pose tout d'un coup : date choisie, note, commentaire.
    @Test func aLogCarriesTheDateRatingAndCommentGivenToIt() throws {
        let (container, useCase) = try makeUseCase()
        let item = MediaItem(kind: .film, title: "La Planète sauvage", year: 1973)
        container.mainContext.insert(item)
        let seen = Date(timeIntervalSince1970: 1_700_000_000)

        let log = try useCase.log(item, status: .done, date: seen, rating: 9, note: "  La copie restaurée  ")

        #expect(log.item?.id == item.id)
        #expect(log.date == seen)
        #expect(log.rating == 9)
        #expect(log.note == "La copie restaurée")
        #expect(try useCase.log(item, note: "   ").note == nil)
        withExtendedLifetime(container) {}
    }

    @Test func loggingACandidateCarriesTheSameFields() throws {
        let (container, useCase) = try makeUseCase()
        let seen = Date(timeIntervalSince1970: 1_700_000_000)

        let log = try useCase.logNow(dune, status: .done, now: seen, rating: 7, note: "Vu en IMAX")

        #expect(log.date == seen)
        #expect(log.rating == 7)
        #expect(log.note == "Vu en IMAX")
        #expect(try counts(container) == (items: 1, logs: 1, refs: 2))
        withExtendedLifetime(container) {}
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

    @Test func logAgainAddsADoneLogDatedNowToAnExistingItem() throws {
        let (container, useCase) = try makeUseCase()
        let first = try useCase.logNow(dune)
        let item = try #require(first.item)
        let later = Date.now.addingTimeInterval(60)

        let again = try useCase.logAgain(item, now: later)

        #expect(again.item?.persistentModelID == item.persistentModelID)
        #expect(again.status == .done)
        #expect(again.date == later)
        #expect(again.source == "manual")
        #expect(try counts(container) == (1, 2, 2))
    }

    @Test func wishThenSeenKeepsBothLogsOnOneItem() throws {
        let (container, useCase) = try makeUseCase()

        let wish = try useCase.wish(dune)
        #expect(wish.status == .wishlist)
        #expect(wish.source == "manual")

        let item = try #require(wish.item)
        let seen = try useCase.logAgain(item)

        #expect(seen.status == .done)
        #expect(seen.item?.persistentModelID == item.persistentModelID)
        #expect(try counts(container) == (1, 2, 2))
        #expect(item.logs.map(\.status).sorted { $0.rawValue < $1.rawValue } == [.done, .wishlist])
    }

    @Test func wishOnAStoredItemAddsAWishlistLog() throws {
        let (container, useCase) = try makeUseCase()
        let item = try #require(try useCase.logNow(dune).item)

        let wish = try useCase.wish(item)

        #expect(wish.status == .wishlist)
        #expect(try counts(container) == (1, 2, 2))
    }

    @Test func repositoryFindsAnItemByItsID() throws {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let item = MediaItem(kind: .film, title: "Dune")
        try repository.add(item, refs: [])

        #expect(try repository.find(itemID: item.id)?.title == "Dune")
        #expect(try repository.find(itemID: UUID()) == nil)
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
