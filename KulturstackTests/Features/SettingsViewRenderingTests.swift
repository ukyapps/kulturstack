import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct SettingsViewRenderingTests {
    @Test func settingsPrivacyAndAboutRender() throws {
        let container = try ModelContainerFactory.inMemory()
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
        }
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
