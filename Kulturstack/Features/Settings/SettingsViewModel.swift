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
    var didFailToRestore = false
    var restoreSummary: String?
    private let wipe: WipeUseCase
    private let export: ExportUseCase?
    private let importer: ImportUseCase?
    private let version: String
    private let build: String

    init(wipe: WipeUseCase, export: ExportUseCase? = nil, importer: ImportUseCase? = nil,
         version: String, build: String) {
        self.wipe = wipe
        self.export = export
        self.importer = importer
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

    // Restaurer **fusionne** : rien n'est effacé, ce qui manque est ajouté. C'est pour ça
    // qu'aucune confirmation ne précède — l'opération ne peut rien détruire.
    func restore(from result: Swift.Result<URL, any Error>) {
        guard let importer, case .success(let url) = result else {
            if case .failure = result { didFailToRestore = true }
            return
        }
        let accès = url.startAccessingSecurityScopedResource()
        defer { if accès { url.stopAccessingSecurityScopedResource() } }
        do {
            let bilan = try importer.restore(from: try Data(contentsOf: url))
            restoreSummary = String(localized: "settings.restore.done \(bilan.itemsAdded) \(bilan.logsAdded)")
            didFailToRestore = false
            prepareExport()
        } catch {
            restoreSummary = nil
            didFailToRestore = true
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
