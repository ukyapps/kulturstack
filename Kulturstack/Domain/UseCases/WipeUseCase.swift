// « Tout effacer » de Réglages : le droit à l'effacement tient en un bouton (TDD 07).
@MainActor
struct WipeUseCase {
    let repository: any MediaRepository

    func wipe() throws {
        try repository.deleteAll()
    }
}
