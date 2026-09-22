import Foundation
import Testing
@testable import Kulturstack

struct MediaKindPresentationTests {
    @Test(arguments: MediaKind.allCases)
    func everyKindHasALabelAndASymbol(kind: MediaKind) {
        #expect(!kind.label.isEmpty)
        #expect(!kind.label.hasPrefix("kind."))
        #expect(!kind.pluralLabel.isEmpty)
        #expect(!kind.pluralLabel.hasPrefix("kind."))
        #expect(!kind.symbol.isEmpty)
        #expect(!kind.seenActionLabel.isEmpty)
        #expect(!kind.seenActionLabel.hasPrefix("journal."))
    }

    @Test(arguments: LogStatus.allCases)
    func everyStatusHasALabel(status: LogStatus) {
        #expect(!status.label.isEmpty)
        #expect(!status.label.hasPrefix("status."))
    }

    @Test(arguments: SearchFamily.allCases)
    func everyFamilyHasALabel(family: SearchFamily) {
        #expect(!family.label.isEmpty)
        #expect(!family.label.hasPrefix("family."))
    }

    @Test func labelsExistInBothLanguages() {
        for kind in MediaKind.allCases {
            let key = "kind.\(kind.rawValue)"
            let fr = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "fr"))
            let en = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "en"))
            #expect(fr != key, "FR manquant pour \(key)")
            #expect(en != key, "EN manquant pour \(key)")
        }
    }
}
