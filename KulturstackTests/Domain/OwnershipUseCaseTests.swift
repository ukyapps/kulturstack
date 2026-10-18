import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct OwnershipUseCaseTests {
    private func make() throws -> (OwnershipUseCase, any MediaRepository, ModelContainer) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        return (OwnershipUseCase(repository: repository), repository, container)
    }

    private func item(_ kind: MediaKind, _ title: String, in repository: any MediaRepository) throws -> MediaItem {
        let item = MediaItem(kind: kind, title: title)
        try repository.add(item, refs: [])
        return item
    }

    @Test func ownPutsTheWorkInTheLibrary() throws {
        let (useCase, repository, container) = try make()
        let album = try item(.album, "Random Access Memories", in: repository)

        try useCase.own(album)

        #expect(album.isOwned)
        #expect(try repository.ownedItems().map(\.title) == ["Random Access Memories"])
        withExtendedLifetime(container) {}
    }

    // Deux appuis ne font pas deux exemplaires. Sans ça, chaque tap ajouterait une ligne et
    // « retirer » n'en enlèverait qu'une.
    @Test func owningTwiceCreatesOnlyOneCopy() throws {
        let (useCase, repository, container) = try make()
        let book = try item(.book, "Piranesi", in: repository)

        try useCase.own(book)
        try useCase.own(book)

        #expect(book.ownedCopies.count == 1)
        #expect(try repository.ownedItems().count == 1)
        withExtendedLifetime(container) {}
    }

    @Test func disownTakesItBackOut() throws {
        let (useCase, repository, container) = try make()
        let film = try item(.film, "Dune", in: repository)
        try useCase.own(film)

        try useCase.disown(film)

        #expect(!film.isOwned)
        #expect(try repository.ownedItems().isEmpty)
        withExtendedLifetime(container) {}
    }

    @Test func disowningSomethingNotOwnedChangesNothing() throws {
        let (useCase, repository, container) = try make()
        let film = try item(.film, "Dune", in: repository)

        try useCase.disown(film)

        #expect(!film.isOwned)
        withExtendedLifetime(container) {}
    }

    @Test func toggleGoesBothWays() throws {
        let (useCase, repository, container) = try make()
        let album = try item(.album, "Discovery", in: repository)

        #expect(try useCase.toggle(album) == true)
        #expect(album.isOwned)
        #expect(try useCase.toggle(album) == false)
        #expect(!album.isOwned)
        withExtendedLifetime(container) {}
    }

    // Le bouton n'apparaîtra pas sur un podcast ; si quelque chose appelait quand même, le
    // modèle refuse plutôt que d'écrire une ligne que personne ne saurait afficher.
    @Test func aPodcastCannotBeOwned() throws {
        let (useCase, repository, container) = try make()
        let podcast = try item(.podcast, "Transfert", in: repository)

        #expect(throws: DomainError.ownershipNotAllowed(for: .podcast)) { try useCase.own(podcast) }
        #expect(!podcast.isOwned)
        withExtendedLifetime(container) {}
    }

    // Posséder n'écrit aucun log : la bibliothèque et le Journal ne se parlent pas.
    @Test func owningWritesNoLog() throws {
        let (useCase, repository, container) = try make()
        let album = try item(.album, "Discovery", in: repository)

        try useCase.own(album)

        #expect(album.logs.isEmpty)
        withExtendedLifetime(container) {}
    }

    // Une œuvre possédée **et** loggée reste une seule ligne dans la bibliothèque.
    @Test func theLibraryListsEachWorkOnce() throws {
        let (useCase, repository, container) = try make()
        let book = try item(.book, "Kafka sur le rivage", in: repository)
        try repository.add(try LogEntry.make(item: book, status: .done))
        try useCase.own(book)

        #expect(try repository.ownedItems().count == 1)
        withExtendedLifetime(container) {}
    }

    @Test func theLibraryIsSortedByTitle() throws {
        let (useCase, repository, container) = try make()
        for title in ["Severance", "Dune", "Piranesi"] {
            try useCase.own(try item(.book, title, in: repository))
        }

        #expect(try repository.ownedItems().map(\.title) == ["Dune", "Piranesi", "Severance"])
        withExtendedLifetime(container) {}
    }

    @Test func theLibraryIgnoresWhatIsOnlyLogged() throws {
        let (useCase, repository, container) = try make()
        let seen = try item(.film, "Dune", in: repository)
        try repository.add(try LogEntry.make(item: seen, status: .done))
        try useCase.own(try item(.album, "Discovery", in: repository))

        #expect(try repository.ownedItems().map(\.title) == ["Discovery"])
        withExtendedLifetime(container) {}
    }
}
