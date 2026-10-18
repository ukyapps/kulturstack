import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct LibraryViewModelTests {
    private func make() throws -> (LibraryViewModel, any MediaRepository, ModelContainer) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        return (LibraryViewModel(repository: repository), repository, container)
    }

    private func own(_ kind: MediaKind, _ title: String, year: Int? = nil, creators: [String] = [],
                     in repository: any MediaRepository) throws {
        let item = MediaItem(kind: kind, title: title, year: year, creators: creators)
        try repository.add(item, refs: [])
        try OwnershipUseCase(repository: repository).own(item)
    }

    // Rien possédé ≠ erreur de chargement : deux écrans différents, c'est la règle du repo.
    @Test func anEmptyLibraryIsNotAnError() async throws {
        let (viewModel, _, container) = try make()

        await viewModel.load()

        #expect(viewModel.state == .empty)
        withExtendedLifetime(container) {}
    }

    @Test func listsWhatIsOwned() async throws {
        let (viewModel, repository, container) = try make()
        try own(.album, "Random Access Memories", year: 2013, creators: ["Daft Punk"], in: repository)
        try own(.book, "Piranesi", year: 2020, creators: ["Susanna Clarke"], in: repository)

        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state else {
            Issue.record("bibliothèque attendue, obtenu \(viewModel.state)")
            return
        }
        #expect(rows.map(\.title) == ["Piranesi", "Random Access Memories"])
        let album = try #require(rows.last)
        #expect(album.kind == .album)
        // La ligne dit le type, l'année et l'auteur — et pas une clé non résolue.
        #expect(album.subtitle.contains("2013"))
        #expect(album.subtitle.contains("Daft Punk"))
        #expect(!album.subtitle.contains("kind."))
        withExtendedLifetime(container) {}
    }

    @Test func aWorkThatIsOnlyLoggedStaysOut() async throws {
        let (viewModel, repository, container) = try make()
        let seen = MediaItem(kind: .film, title: "Dune")
        try repository.add(seen, refs: [])
        try repository.add(try LogEntry.make(item: seen, status: .done))

        await viewModel.load()

        #expect(viewModel.state == .empty)
        withExtendedLifetime(container) {}
    }

    @Test func aFailingRepositoryShowsTheErrorState() async throws {
        let viewModel = LibraryViewModel(repository: FailingMediaRepository())

        await viewModel.load()

        #expect(viewModel.state == .failed)
    }

    @Test func removingFromTheLibraryReloadsTheList() async throws {
        let (viewModel, repository, container) = try make()
        try own(.album, "Discovery", in: repository)
        await viewModel.load()

        guard case .loaded(let rows) = viewModel.state, let row = rows.first else {
            Issue.record("une ligne attendue")
            return
        }
        await viewModel.remove(itemID: row.id)

        #expect(viewModel.state == .empty)
        withExtendedLifetime(container) {}
    }
}

