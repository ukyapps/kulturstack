import SwiftData
@testable import Kulturstack

// Les conteneurs des tests de rendu ne sont jamais libérés : un écran rendu hors écran
// laisse derrière lui la tâche de son `task`, qui interroge le dépôt plus tard. Si le
// conteneur est mort entre-temps, SwiftData plante le processus entier. Les garder coûte
// quelques kilo-octets et supprime toute une famille de faux rouges.
@MainActor
enum GardeConteneurs {
    static var tous: [ModelContainer] = []

    static func neuf() throws -> ModelContainer {
        let container = try ModelContainerFactory.inMemory()
        tous.append(container)
        return container
    }
}
