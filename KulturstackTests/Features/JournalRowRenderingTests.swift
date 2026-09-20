import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

struct JournalRowRenderingTests {
    @Test @MainActor func rowRendersWithAndWithoutRating() throws {
        let container = try ModelContainerFactory.inMemory()
        let item = MediaItem(kind: .book, title: "Piranesi", year: 2020, creators: ["Susanna Clarke"])
        container.mainContext.insert(item)
        let rated = try LogEntry.make(item: item, status: .done, rating: 9)
        let unrated = try LogEntry.make(item: item, status: .inProgress)
        container.mainContext.insert(rated)
        container.mainContext.insert(unrated)

        for log in [rated, unrated] {
            let host = UIHostingController(rootView: JournalRow(model: JournalRowModel(log: log)))
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 200))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            let size = host.sizeThatFits(in: CGSize(width: 390, height: CGFloat.greatestFiniteMagnitude))
            #expect(size.height > 44)
        }
    }
}
