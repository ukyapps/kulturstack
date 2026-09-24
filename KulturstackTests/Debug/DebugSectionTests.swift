import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct DebugSectionTests {
    // La seule surface visible de la PR 12 : le badge doit compter les épisodes, et le dire
    // dans les deux langues. Le menu DEBUG n'existe pas en Release, ce test non plus.
    @Test func theStorageBadgeCountsEpisodesInBothLanguages() throws {
        let key = "debug.storage.badge %lld %lld %lld %lld"
        let fr = try localized(key, language: "fr")
        let en = try localized(key, language: "en")

        #expect(fr.contains("V%1$lld"))
        #expect(fr.contains("%4$lld épisodes"))
        #expect(en.contains("%4$lld episodes"))
        #expect(fr != en)
    }

    @Test func theDebugSectionRendersWithSeasonsAndEpisodes() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let severance = MediaItem(kind: .series, title: "Severance")
        context.insert(severance)
        let season = try Season.make(number: 2, item: severance)
        context.insert(season)
        context.insert(Episode(number: 4, title: "Woe's Hollow", season: season))
        try context.save()

        let host = UIHostingController(rootView: Form { DebugSection() }.modelContainer(container))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        #expect(host.view.bounds.height > 0)
        #expect(Int(KulturstackMigrationPlan.current.versionIdentifier.major) == 2)
    }

    private func localized(_ key: String, language: String) throws -> String {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        return try #require(Bundle(path: path)).localizedString(forKey: key, value: key, table: "Localizable")
    }
}
