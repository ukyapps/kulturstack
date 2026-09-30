import Foundation
@testable import Kulturstack

// La date du dernier passage, en mémoire : les tests n'écrivent pas dans les réglages
// de la machine qui les fait tourner.
@MainActor
final class StubRefreshHistory: RefreshHistory {
    private(set) var recorded: [Date] = []
    private var last: Date?

    init(last: Date? = nil) { self.last = last }

    func lastRefresh() -> Date? { last }

    func record(_ date: Date) {
        last = date
        recorded.append(date)
    }
}
