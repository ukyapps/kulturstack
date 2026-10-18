import SwiftData
import SwiftUI
import Testing
@testable import Kulturstack

// `.serialized` : Swift Testing lance les tests en parallèle, et un écran rendu dans une
// fenêtre hors écran peut laisser une tâche derrière lui. Elle plante alors **un autre
// test**, choisi au hasard — ce qui rend le coupable introuvable.
@MainActor @Suite(.serialized)
struct LibraryViewRenderingTests {
    private func shoot(_ view: some View, height: CGFloat = 844) -> Data {
        let host = UIHostingController(rootView: AnyView(view))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: height))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let png = renderer.image { context in window.layer.render(in: context.cgContext) }.pngData() ?? Data()
        // La fenêtre se démonte ici : sans ça, le `task` de l'écran survit à la fin du test
        // et appelle le dépôt sur un conteneur déjà libéré — ce qui fait tomber **le test
        // suivant**, pas celui qui faute. La pile est dans ~/Library/Logs/DiagnosticReports.
        window.rootViewController = nil
        window.isHidden = true
        return png
    }

    // Vide ≠ erreur ≠ rempli. Comparés image contre image : un `height > 0` passerait même
    // si les trois écrans étaient blancs.
    @Test func theLibraryHasThreeDistinctRenders() async throws {
        var shots: [Data] = []

        let vide = try GardeConteneurs.neuf()
        let videView = LibraryView(services: AppServices(context: vide.mainContext))
        shots.append(shoot(videView))
        await videView.viewModelForTesting.load()
        shots[0] = shoot(videView)
        #expect(videView.viewModelForTesting.state == .empty)

        let plein = try GardeConteneurs.neuf()
        let repository = SwiftDataMediaRepository(context: plein.mainContext)
        let album = MediaItem(kind: .album, title: "Random Access Memories", year: 2013, creators: ["Daft Punk"])
        try repository.add(album, refs: [])
        try OwnershipUseCase(repository: repository).own(album)
        let pleinView = LibraryView(services: AppServices(context: plein.mainContext))
        await pleinView.viewModelForTesting.load()
        shots.append(shoot(pleinView))

        // Conteneur nommé, jamais temporaire : l'écran charge dans une tâche, et un
        // conteneur libéré avant qu'elle tourne fait planter `ownedItems()` dans SwiftData.
        let vidé = try GardeConteneurs.neuf()
        let casse = LibraryView(services: AppServices(context: vidé.mainContext))
        // L'état d'erreur se rend depuis le modèle, le dépôt en mémoire ne tombe pas en panne.
        casse.viewModelForTesting.failForTesting()
        shots.append(shoot(casse))

        #expect(shots.count == 3)
        #expect(Set(shots).count == 3)
    }

    // **Le bouton de la fiche ne se prouve pas par une image.** Rendre `ItemDetailView` dans
    // une fenêtre hors écran fait tomber le test, et trois hypothèses sur la cause se sont
    // révélées fausses (le type d'œuvre, l'absence de `NavigationStack`, la durée de vie du
    // conteneur). Ce qui se teste, c'est la **donnée** qui déclenche l'affichage — la règle
    // que le repo s'est donnée le 27/09. Le bouton lui-même se juge sur l'appareil.
    @Test func theDataBehindTheButtonSaysWhenItShows() throws {
        let container = try GardeConteneurs.neuf()
        let repository = SwiftDataMediaRepository(context: container.mainContext)
        let album = MediaItem(kind: .album, title: "Discovery")
        let podcast = MediaItem(kind: .podcast, title: "Transfert")
        try repository.add(album, refs: [])
        try repository.add(podcast, refs: [])

        // La vue n'affiche le bouton que si `canBeOwned`, et son libellé suit `isOwned`.
        #expect(ItemDetailModel(item: album).kind.canBeOwned)
        #expect(!ItemDetailModel(item: podcast).kind.canBeOwned)
        #expect(!ItemDetailModel(item: album).isOwned)

        try OwnershipUseCase(repository: repository).own(album)

        #expect(ItemDetailModel(item: album).isOwned)
        withExtendedLifetime(container) {}
    }
}
