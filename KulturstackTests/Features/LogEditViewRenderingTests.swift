import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

@MainActor
struct LogEditViewRenderingTests {
    @Test func rendersTheFormAndTheMissingState() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .book, title: "Piranesi", year: 2020)
        context.insert(item)
        let log = try LogEntry.make(item: item, status: .inProgress, rating: 7, note: "En cours")
        context.insert(log)
        try context.save()
        let useCase = EditLogUseCase(repository: SwiftDataLogRepository(context: context))

        for logID in [log.id, UUID()] {
            let view = LogEditView(logID: logID, useCase: useCase)
            let host = UIHostingController(rootView: view)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            #expect(host.view.bounds.height > 0)
        }
    }

    @Test func pickerRendersEveryRating() {
        for rating in [nil, 1, 5, 10] {
            let host = UIHostingController(rootView: StarRatingPicker(rating: .constant(rating)))
            host.view.layoutIfNeeded()
            let size = host.sizeThatFits(in: CGSize(width: 390, height: 100))
            #expect(size.width > 0)
        }
    }
}
