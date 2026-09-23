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
        let services = AppServices(context: context)

        for logID in [log.id, UUID()] {
            let view = LogEditView(logID: logID, services: services)
            let host = UIHostingController(rootView: view)
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
            window.rootViewController = host
            window.makeKeyAndVisible()
            host.view.layoutIfNeeded()
            #expect(host.view.bounds.height > 0)
        }
    }

    @Test func rendersTheCreationForm() throws {
        let container = try ModelContainerFactory.inMemory()
        let context = container.mainContext
        let item = MediaItem(kind: .film, title: "La Planète sauvage", year: 1973)
        context.insert(item)
        try context.save()

        let host = UIHostingController(rootView: LogEditView(target: .item(item.id), services: AppServices(context: context)))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        #expect(host.view.bounds.height > 0)
        #expect(try context.fetchCount(FetchDescriptor<LogEntry>()) == 0)
        withExtendedLifetime(container) {}
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
