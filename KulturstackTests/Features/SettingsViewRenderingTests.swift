import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

// `.serialized` et conteneur gardé : l'écran des Réglages prépare l'export dans un `task`,
// qui interroge le dépôt après la fin du test. Sur un conteneur libéré, SwiftData plante le
// processus — et c'est un AUTRE test qui tombe (piège du 18/10, consigné dans CLAUDE.md).
@MainActor @Suite(.serialized)
struct SettingsViewRenderingTests {
    @Test func settingsPrivacyAndAboutRender() throws {
        let container = try GardeConteneurs.neuf()
        let services = AppServices(context: container.mainContext)
        let views: [AnyView] = [
            AnyView(SettingsView(services: services)),
            AnyView(PrivacyView()),
            AnyView(AboutView(versionLine: "Kulturstack 1.0 (3)")),
        ]
        for view in views {
            let host = UIHostingController(rootView: NavigationStack { view })
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            #expect(host.view.bounds.height > 0)
            window.rootViewController = nil
            window.isHidden = true
        }
        withExtendedLifetime(container) {}
    }

    // L'export se propose au-dessus de « Tout effacer », et son libellé compte les œuvres :
    // une base vide et une base remplie ne disent pas la même chose.
    @Test func theExportRowCountsTheWorks() throws {
        let container = try GardeConteneurs.neuf()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        for title in ["Dune", "Piranesi"] {
            try repository.add(MediaItem(kind: .book, title: title), refs: [])
        }
        let viewModel = SettingsViewModel(wipe: WipeUseCase(repository: repository),
                                          export: ExportUseCase(repository: repository),
                                          version: "1.0", build: "3")

        viewModel.prepareExport(directory: FileManager.default.temporaryDirectory)

        #expect(viewModel.exportFile != nil)
        #expect(viewModel.exportedWorks == 2)
        #expect(!viewModel.didFailToExport)
        // Une clé non résolue s'afficherait en clair sous le bouton.
        #expect(!viewModel.exportFooter.contains("settings.export.footer"))
        #expect(viewModel.exportFooter.contains("2"))
        withExtendedLifetime(container) {}
    }

    // Un dépôt qui tombe ne doit pas proposer un fichier qui n'existe pas.
    @Test func aFailingRepositoryOffersNoFile() throws {
        let repository = FailingMediaRepository()
        let viewModel = SettingsViewModel(wipe: WipeUseCase(repository: repository),
                                          export: ExportUseCase(repository: repository),
                                          version: "1.0", build: "3")

        viewModel.prepareExport(directory: FileManager.default.temporaryDirectory)

        #expect(viewModel.exportFile == nil)
        #expect(viewModel.didFailToExport)
    }

    // Le chemin complet depuis l'écran : un vrai fichier sur le disque, choisi comme le
    // ferait la feuille de fichiers d'iOS.
    @Test func restoringFromAFileBringsTheWorksBackAndSaysSo() throws {
        let container = try GardeConteneurs.neuf()
        let media = SwiftDataMediaRepository(context: container.mainContext)
        let episodes = SwiftDataEpisodeRepository(context: container.mainContext)
        let item = MediaItem(kind: .book, title: "Piranesi")
        try media.add(item, refs: [ExternalRef(provider: "isbn13", value: "9781635575637")])
        try media.add(try LogEntry.make(item: item, status: .done, rating: 9))
        let fichier = FileManager.default.temporaryDirectory
            .appending(path: "restore-\(UUID().uuidString).json")
        try ExportUseCase(repository: media).json(appVersion: "1.0").write(to: fichier)
        defer { try? FileManager.default.removeItem(at: fichier) }
        try WipeUseCase(repository: media).wipe()

        let viewModel = SettingsViewModel(wipe: WipeUseCase(repository: media),
                                          export: ExportUseCase(repository: media),
                                          importer: ImportUseCase(media: media, episodes: episodes),
                                          version: "1.0", build: "3")
        viewModel.restore(from: .success(fichier))

        #expect(!viewModel.didFailToRestore)
        let résumé = try #require(viewModel.restoreSummary)
        #expect(résumé.contains("1"))
        // Une clé non résolue s'afficherait en clair dans l'alerte.
        #expect(!résumé.contains("settings.restore.done"))
        #expect(try media.allItems().map(\.title) == ["Piranesi"])
        // Le fichier d'export se refait dans la foulée : il est périmé sinon.
        #expect(viewModel.exportedWorks == 1)
        withExtendedLifetime(container) {}
    }

    @Test func anUnreadableFileChangesNothingAndSaysSo() throws {
        let container = try GardeConteneurs.neuf()
        let media = SwiftDataMediaRepository(context: container.mainContext)
        let episodes = SwiftDataEpisodeRepository(context: container.mainContext)
        let fichier = FileManager.default.temporaryDirectory
            .appending(path: "cassé-\(UUID().uuidString).json")
        try Data("pas du json".utf8).write(to: fichier)
        defer { try? FileManager.default.removeItem(at: fichier) }

        let viewModel = SettingsViewModel(wipe: WipeUseCase(repository: media),
                                          export: ExportUseCase(repository: media),
                                          importer: ImportUseCase(media: media, episodes: episodes),
                                          version: "1.0", build: "3")
        viewModel.restore(from: .success(fichier))

        #expect(viewModel.didFailToRestore)
        #expect(viewModel.restoreSummary == nil)
        #expect(try media.allItems().isEmpty)
        withExtendedLifetime(container) {}
    }

    @Test func cancellingTheFilePickerIsNotAFailure() throws {
        let container = try GardeConteneurs.neuf()
        let media = SwiftDataMediaRepository(context: container.mainContext)
        let viewModel = SettingsViewModel(wipe: WipeUseCase(repository: media),
                                          export: ExportUseCase(repository: media),
                                          importer: ImportUseCase(media: media,
                                                                  episodes: SwiftDataEpisodeRepository(context: container.mainContext)),
                                          version: "1.0", build: "3")

        viewModel.restore(from: .failure(CocoaError(.userCancelled)))

        // Annuler reste une erreur côté iOS, mais l'app ne doit pas inventer un échec de
        // restauration — à revoir si l'alerte apparaît à l'usage après une simple annulation.
        #expect(viewModel.restoreSummary == nil)
        withExtendedLifetime(container) {}
    }

    @Test(arguments: ["privacy.leaves.body", "privacy.stays.body", "about.tmdb.notice", "about.openlibrary.body", "settings.wipe.confirm.title", "search.offline"])
    func privacyAndAboutTextsExistInBothLanguages(key: String) throws {
        let fr = try localized(key, language: "fr")
        let en = try localized(key, language: "en")
        #expect(fr != key)
        #expect(en != key)
        #expect(fr != en)
    }

    private func localized(_ key: String, language: String) throws -> String {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try #require(Bundle(path: path)).localizedString(forKey: key, value: key, table: "Localizable")
    }
}
