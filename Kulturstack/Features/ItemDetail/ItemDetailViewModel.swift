import Foundation
import Observation

@MainActor @Observable
final class ItemDetailViewModel {
    enum State: Equatable {
        case loading
        case loaded(ItemDetailModel)
        case missing
        case failed
    }

    private(set) var state: State = .loading
    var didFailToLog = false

    let itemID: UUID
    private let repository: any MediaRepository
    private let logUseCase: LogUseCase

    init(itemID: UUID, repository: any MediaRepository, logUseCase: LogUseCase) {
        self.itemID = itemID
        self.repository = repository
        self.logUseCase = logUseCase
    }

    func load() {
        do {
            guard let item = try repository.find(itemID: itemID) else {
                state = .missing
                return
            }
            state = .loaded(ItemDetailModel(item: item))
        } catch {
            state = .failed
        }
    }

    func logAgain() {
        do {
            guard let item = try repository.find(itemID: itemID) else {
                state = .missing
                return
            }
            try logUseCase.logAgain(item)
            didFailToLog = false
            load()
        } catch {
            didFailToLog = true
        }
    }
}
