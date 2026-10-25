import Foundation
@testable import Kulturstack

// Un dépôt qui échoue à tout : c'est ce qui permet de rendre l'état d'erreur d'un écran,
// qu'un dépôt en mémoire ne produit jamais. Il vivait en trois copies privées identiques
// (fiche, Réglages, bibliothèque) — et chaque méthode ajoutée au protocole les cassait
// toutes les trois.
struct FailingRepositoryError: Error {}

@MainActor
struct FailingMediaRepository: MediaRepository {
    func findItem(withAnyKey keys: [String]) throws -> MediaItem? { throw FailingRepositoryError() }
    func find(itemID: UUID) throws -> MediaItem? { throw FailingRepositoryError() }
    func add(_ item: MediaItem, refs: [ExternalRef]) throws { throw FailingRepositoryError() }
    func add(_ refs: [ExternalRef], to item: MediaItem) throws { throw FailingRepositoryError() }
    func add(_ log: LogEntry) throws { throw FailingRepositoryError() }
    func add(_ logs: [LogEntry]) throws { throw FailingRepositoryError() }
    func add(_ copy: OwnedCopy) throws { throw FailingRepositoryError() }
    func delete(_ copies: [OwnedCopy]) throws { throw FailingRepositoryError() }
    func ownedItems() throws -> [MediaItem] { throw FailingRepositoryError() }
    func allItems() throws -> [MediaItem] { throw FailingRepositoryError() }
    func save() throws { throw FailingRepositoryError() }
    func deleteAll() throws { throw FailingRepositoryError() }
}
