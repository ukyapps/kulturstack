import Foundation
import Observation

@MainActor @Observable
final class SettingsViewModel {
    var didFailToWipe = false
    var didFailToExport = false
    // Le fichier prêt à partager. Nil tant qu'il n'est pas écrit : le bouton ne se propose
    // pas avant d'avoir quelque chose à donner.
    private(set) var exportFile: URL?
    private(set) var exportedWorks = 0
    private let wipe: WipeUseCase
    private let export: ExportUseCase?
    private let version: String
    private let build: String

    init(wipe: WipeUseCase, export: ExportUseCase? = nil, version: String, build: String) {
        self.wipe = wipe
        self.export = export
        self.version = version
        self.build = build
    }

    // Écrit le fichier dans le dossier temporaire : c'est la feuille de partage d'iOS qui
    // décide ensuite où il atterrit — Fichiers, iCloud Drive, un mail à soi-même.
    func prepareExport(now: Date = .now, directory: URL = .temporaryDirectory) {
        guard let export else { return }
        do {
            let snapshot = try export.snapshot(now: now, appVersion: version)
            let data = try JSONEncoder.kulturstackExport.encode(snapshot)
            let url = directory.appending(path: ExportUseCase.fileName(now: now))
            try data.write(to: url, options: .atomic)
            exportedWorks = snapshot.items.count
            exportFile = url
            didFailToExport = false
        } catch {
            exportFile = nil
            didFailToExport = true
        }
    }

    var exportFooter: String {
        String(localized: "settings.export.footer \(exportedWorks)")
    }

    var versionLine: String {
        String(localized: "about.version \(version) \(build)")
    }

    func wipeAll() -> Bool {
        do {
            try wipe.wipe()
            didFailToWipe = false
            return true
        } catch {
            didFailToWipe = true
            return false
        }
    }
}
