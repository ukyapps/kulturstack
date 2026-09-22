import Foundation
import Observation

@MainActor @Observable
final class SettingsViewModel {
    var didFailToWipe = false
    private let wipe: WipeUseCase
    private let version: String
    private let build: String

    init(wipe: WipeUseCase, version: String, build: String) {
        self.wipe = wipe
        self.version = version
        self.build = build
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
