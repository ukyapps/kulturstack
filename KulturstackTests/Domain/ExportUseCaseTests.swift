import Foundation
import SwiftData
import Testing
@testable import Kulturstack

@MainActor
struct ExportUseCaseTests {
    private func make() throws -> (ExportUseCase, any MediaRepository, ModelContainer) {
        let container = try ModelContainerFactory.inMemory()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        return (ExportUseCase(repository: repository), repository, container)
    }

    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    // L'export existe pour une seule raison : pouvoir tout remettre après une perte. Donc il
    // porte tout — y compris ce qui n'a aucun log et ne se verrait pas dans le Journal.
    @Test func carriesEveryWorkEvenWithoutALog() throws {
        let (useCase, repository, container) = try make()
        let loggé = MediaItem(kind: .film, title: "Dune", year: 2021, creators: ["Denis Villeneuve"])
        let possédé = MediaItem(kind: .album, title: "Discovery", year: 2001)
        try repository.add(loggé, refs: [ExternalRef(provider: "tmdb", value: "movie:438631")])
        try repository.add(possédé, refs: [])
        try repository.add(try LogEntry.make(item: loggé, status: .done, date: date, rating: 9, note: "Enfin."))
        try repository.add(try OwnedCopy.make(item: possédé))

        let export = try useCase.snapshot(now: date, appVersion: "1.2")

        #expect(export.items.count == 2)
        let titres = export.items.map(\.title).sorted()
        #expect(titres == ["Discovery", "Dune"])
        withExtendedLifetime(container) {}
    }

    @Test func carriesLogsWithTheirRatingNoteAndStatus() throws {
        let (useCase, repository, container) = try make()
        let item = MediaItem(kind: .book, title: "Piranesi")
        try repository.add(item, refs: [])
        try repository.add(try LogEntry.make(item: item, status: .done, date: date, rating: 9, note: "D'une traite."))

        let export = try useCase.snapshot(now: date, appVersion: "1.2")
        let log = try #require(export.items.first?.logs.first)

        #expect(log.status == "done")
        #expect(log.rating == 9)
        #expect(log.note == "D'une traite.")
        #expect(log.date == date)
        withExtendedLifetime(container) {}
    }

    // Le `guid` d'un épisode de podcast est son identité : sans lui, les coches se
    // retrouveraient sur les mauvais épisodes au retour.
    @Test func carriesEpisodesWithTheirIdentityAndTheirChecks() throws {
        let (useCase, repository, container) = try make()
        let podcast = MediaItem(kind: .podcast, title: "Transfert")
        try repository.add(podcast, refs: [])
        let season = try Season.make(number: 1, item: podcast)
        container.mainContext.insert(season)
        let écouté = Episode(number: 1, title: "Un", externalID: "guid-1", season: season)
        let pasÉcouté = Episode(number: 2, title: "Deux", externalID: "guid-2", season: season)
        container.mainContext.insert(écouté)
        container.mainContext.insert(pasÉcouté)
        try repository.add(try LogEntry.make(item: podcast, status: .done, date: date, episode: écouté))

        let export = try useCase.snapshot(now: date, appVersion: "1.2")
        let item = try #require(export.items.first)
        let épisodes = item.seasons.flatMap(\.episodes)

        #expect(épisodes.map(\.externalID) == ["guid-1", "guid-2"])
        // Le log d'épisode désigne son épisode par sa clé, pas par sa position.
        let cochés = item.logs.compactMap(\.episodeKey)
        #expect(cochés == [écouté.key])
        withExtendedLifetime(container) {}
    }

    @Test func carriesTheDetailsPocketVerbatim() throws {
        let (useCase, repository, container) = try make()
        let album = MediaItem(kind: .album, title: "Random Access Memories")
        try album.setDetails(AlbumDetails(trackCount: 14, genre: "Pop"))
        try repository.add(album, refs: [])

        let export = try useCase.snapshot(now: date, appVersion: "1.2")
        let json = try #require(export.items.first?.detailsJSON)

        #expect(json.contains("14"))
        #expect(json.contains("Pop"))
        withExtendedLifetime(container) {}
    }

    @Test func carriesExternalKeysSoAReimportDeduplicates() throws {
        let (useCase, repository, container) = try make()
        let item = MediaItem(kind: .film, title: "Dune")
        try repository.add(item, refs: [ExternalRef(provider: "tmdb", value: "movie:438631"),
                                        ExternalRef(provider: "imdb", value: "tt1160419")])

        let export = try useCase.snapshot(now: date, appVersion: "1.2")

        #expect(export.items.first?.externalKeys.sorted() == ["imdb:tt1160419", "tmdb:movie:438631"])
        withExtendedLifetime(container) {}
    }

    // Une base vide s'exporte quand même : c'est un fichier valide avec zéro œuvre, pas une
    // erreur. Sinon la founder ne saurait pas distinguer « rien à sauver » de « ça a raté ».
    @Test func anEmptyBaseStillProducesAValidFile() throws {
        let (useCase, _, container) = try make()

        let data = try useCase.json(now: date, appVersion: "1.2")
        let relu = try JSONDecoder.kulturstackExport.decode(KulturstackExport.self, from: data)

        #expect(relu.items.isEmpty)
        #expect(relu.formatVersion == KulturstackExport.currentFormatVersion)
        withExtendedLifetime(container) {}
    }

    // Le fichier se relit : c'est ce qui sépare une sauvegarde d'un presse-papier.
    @Test func theFileParsesBackWithTheSameCounts() throws {
        let (useCase, repository, container) = try make()
        for title in ["Dune", "Piranesi", "Discovery"] {
            let item = MediaItem(kind: .book, title: title)
            try repository.add(item, refs: [ExternalRef(provider: "demo", value: title)])
            try repository.add(try LogEntry.make(item: item, status: .done, date: date, rating: 8))
        }

        let data = try useCase.json(now: date, appVersion: "1.2")
        let relu = try JSONDecoder.kulturstackExport.decode(KulturstackExport.self, from: data)

        #expect(relu.items.count == 3)
        #expect(relu.items.allSatisfy { $0.logs.count == 1 })
        #expect(relu.items.allSatisfy { $0.externalKeys.count == 1 })
        #expect(relu.exportedAt == date)
        #expect(relu.app == "1.2")
        withExtendedLifetime(container) {}
    }

    // Les dates sont en ISO 8601, lisibles par un humain et par n'importe quel outil : un
    // horodatage brut ne se relit pas dans six mois.
    @Test func datesAreWrittenInISO8601() throws {
        let (useCase, repository, container) = try make()
        let item = MediaItem(kind: .film, title: "Dune")
        try repository.add(item, refs: [])
        try repository.add(try LogEntry.make(item: item, status: .done, date: date))

        let texte = try #require(String(data: try useCase.json(now: date, appVersion: "1.2"), encoding: .utf8))

        #expect(texte.contains("2027-01-15"))
        #expect(!texte.contains("1800000000"))
        withExtendedLifetime(container) {}
    }

    @Test func theFileNameCarriesTheDate() {
        #expect(ExportUseCase.fileName(now: date) == "kulturstack-2027-01-15.json")
    }
}
