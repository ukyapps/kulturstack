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
