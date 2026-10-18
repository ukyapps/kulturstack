import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct OwnedCopyTests {
    private func container() throws -> ModelContainer { try ModelContainerFactory.inMemory() }

    // La founder, le 17/10 : « les disques, je les écoute pas, je les ai dans ma bibliothèque ».
    // Posséder et consommer sont deux relations séparées (ADR-010) : ni l'une ni l'autre
    // n'implique sa voisine.
    @Test func anItemCanBeOwnedWithoutAnyLog() throws {
        let container = try container()
        let album = MediaItem(kind: .album, title: "Random Access Memories")
        container.mainContext.insert(album)

        container.mainContext.insert(try OwnedCopy.make(item: album))
        try container.mainContext.save()

        #expect(album.isOwned)
        #expect(album.logs.isEmpty)
    }

    @Test func anItemCanBeLoggedWithoutBeingOwned() throws {
        let container = try container()
        let film = MediaItem(kind: .film, title: "Dune")
        container.mainContext.insert(film)
        container.mainContext.insert(try LogEntry.make(item: film, status: .done, rating: 9))
        try container.mainContext.save()

        #expect(!film.isOwned)
        #expect(film.logs.count == 1)
    }

    @Test func anItemCanBeBoth() throws {
        let container = try container()
        let book = MediaItem(kind: .book, title: "Kafka sur le rivage")
        container.mainContext.insert(book)
        container.mainContext.insert(try LogEntry.make(item: book, status: .done))
        container.mainContext.insert(try OwnedCopy.make(item: book))
        try container.mainContext.save()

        #expect(book.isOwned)
        #expect(book.logs.count == 1)
    }

    // Un podcast ne se range pas sur une étagère, un concert non plus : leur fiche n'a pas à
    // proposer « Dans ma bibliothèque », et le modèle le refuse plutôt que de l'autoriser en
    // silence.
    @Test(arguments: [MediaKind.podcast, .concert, .theatre, .exhibition])
    func whatCannotBeOwnedIsRefused(kind: MediaKind) throws {
        let container = try container()
        let item = MediaItem(kind: kind, title: "Quelque chose")
        container.mainContext.insert(item)

        #expect(throws: DomainError.ownershipNotAllowed(for: kind)) {
            _ = try OwnedCopy.make(item: item)
        }
        withExtendedLifetime(container) {}
    }

    @Test(arguments: [MediaKind.film, .series, .book, .album, .game])
    func whatIsAnObjectCanBeOwned(kind: MediaKind) throws {
        let container = try container()
        let item = MediaItem(kind: kind, title: "Quelque chose")
        container.mainContext.insert(item)

        #expect(throws: Never.self) { _ = try OwnedCopy.make(item: item) }
        withExtendedLifetime(container) {}
    }

    // Deux exemplaires du même disque — le vinyle et le CD — sont deux lignes, et l'œuvre
    // reste une. C'est ce qui permettra d'y accrocher un format sans tout refaire.
    @Test func anItemCanHoldSeveralCopies() throws {
        let container = try container()
        let album = MediaItem(kind: .album, title: "Discovery")
        container.mainContext.insert(album)

        container.mainContext.insert(try OwnedCopy.make(item: album, format: "vinyl"))
        container.mainContext.insert(try OwnedCopy.make(item: album, format: "cd"))
        try container.mainContext.save()

        #expect(album.ownedCopies.count == 2)
        #expect(Set(album.ownedCopies.compactMap(\.format)) == ["vinyl", "cd"])
    }

    // Un exemplaire sans format reste un exemplaire : « je l'ai » se dit sans préciser quoi.
    @Test func aCopyNeedsNothingButItsWork() throws {
        let container = try container()
        let book = MediaItem(kind: .book, title: "Piranesi")
        container.mainContext.insert(book)

        let copy = try OwnedCopy.make(item: book)

        #expect(copy.format == nil)
        #expect(copy.editionRef == nil)
        #expect(copy.acquiredAt == nil)
        #expect(copy.item?.title == "Piranesi")
        withExtendedLifetime(container) {}
    }

    // Supprimer l'œuvre emporte ses exemplaires, comme elle emporte ses logs.
    @Test func deletingTheWorkDeletesItsCopies() throws {
        let container = try container()
        let context = container.mainContext
        let album = MediaItem(kind: .album, title: "Discovery")
        context.insert(album)
        context.insert(try OwnedCopy.make(item: album))
        try context.save()

        context.delete(album)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<OwnedCopy>()) == 0)
    }
}
