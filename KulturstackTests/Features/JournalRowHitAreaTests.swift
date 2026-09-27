import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

// Retour du 27/09 : « quand je clique sur une ligne ça ouvre pas la fiche, c'est uniquement si
// je clique sur l'image ou le titre ». Une ligne dont le corps ne déclare pas de zone tactile
// ne répond que sur les pixels dessinés : ni la marge, ni les vides, ni la colonne de la note.
//
// SwiftUI ne laisse pas observer sa zone tactile depuis un test — un UIHostingController n'expose
// qu'une seule UIView opaque, et hitTest y renvoie la même vue avec et sans contentShape. Ce qui
// est observable, c'est le type du corps de la vue : il porte la liste de ses modificateurs.
struct JournalRowHitAreaTests {
    private let container: ModelContainer

    init() throws {
        container = try ModelContainerFactory.inMemory()
    }

    private func declaresAHitArea(_ view: some View) -> Bool {
        String(describing: type(of: view.body)).contains("_ContentShapeModifier<Rectangle>")
    }

    @Test @MainActor func theJournalRowDeclaresItsHitArea() throws {
        let item = MediaItem(kind: .film, title: "La Planète sauvage", year: 1973)
        container.mainContext.insert(item)
        let log = try LogEntry.make(item: item, status: .done, rating: 8)
        container.mainContext.insert(log)

        #expect(declaresAHitArea(JournalRow(model: JournalRowModel(log: log))))
    }

    // Les quatre lignes tapables de l'app suivent la même règle : la ligne entière répond.
    // Le 27/09, le Journal était la seule à ne pas le faire.
    @Test @MainActor func everyTappableRowDeclaresItsHitArea() throws {
        let item = MediaItem(kind: .series, title: "Severance", year: 2022)
        container.mainContext.insert(item)
        let log = try LogEntry.make(item: item, status: .wishlist)
        container.mainContext.insert(log)
        let model = JournalRowModel(log: log)

        #expect(declaresAHitArea(JournalRow(model: model)))
        #expect(declaresAHitArea(WishRow(model: model, onSeen: {})))
        #expect(declaresAHitArea(MediaRow(coverURL: nil, placeholderSymbol: "film", title: "Dune", subtitle: "Film")))
        #expect(declaresAHitArea(InProgressRow(model: InProgressRowModel(item: item), onAdvance: {}, onFinish: {})))
    }
}
