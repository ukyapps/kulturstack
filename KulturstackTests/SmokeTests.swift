import Foundation
import Testing
@testable import Kulturstack

struct SmokeTests {
    @Test func emptyStateKeepsItsContent() {
        let state = EmptyState(icon: "books.vertical", title: "Titre", message: "Message")
        #expect(state.title == "Titre")
        #expect(state.message == "Message")
        #expect(state.action == nil)
    }

    @Test func frenchAndEnglishStringsExist() {
        let fr = String(localized: "journal.empty.title", locale: Locale(identifier: "fr"))
        let en = String(localized: "journal.empty.title", locale: Locale(identifier: "en"))
        #expect(!fr.isEmpty)
        #expect(!en.isEmpty)
        #expect(fr != "journal.empty.title")
    }
}
