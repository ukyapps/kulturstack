import Foundation
import Observation

@MainActor @Observable
final class ItemDetailViewModel {
    enum Subject: Hashable {
        case stored(UUID)
        case candidate(MediaCandidate)
    }

    enum State: Equatable {
        case loading
        case loaded(ItemDetailModel)
        case missing
        case failed
    }

    private(set) var state: State = .loading
    var didFailToLog = false

    private(set) var subject: Subject
    private let repository: any MediaRepository
    private let logUseCase: LogUseCase

    init(subject: Subject, repository: any MediaRepository, logUseCase: LogUseCase) {
        self.subject = subject
        self.repository = repository
        self.logUseCase = logUseCase
    }

    // Un candidat déjà en base devient sa fiche réelle ; sinon on montre l'aperçu de la recherche.
    func load() {
        do {
            switch subject {
            case .stored(let itemID):
                guard let item = try repository.find(itemID: itemID) else {
                    state = .missing
                    return
                }
                state = .loaded(ItemDetailModel(item: item))
            case .candidate(let candidate):
                if let item = try repository.findItem(withAnyKey: candidate.externalKeys) {
                    subject = .stored(item.id)
                    state = .loaded(ItemDetailModel(item: item))
                } else {
                    state = .loaded(ItemDetailModel(candidate: candidate))
                }
            }
        } catch {
            state = .failed
        }
    }

    func log() {
        do {
            switch subject {
            case .stored(let itemID):
                guard let item = try repository.find(itemID: itemID) else {
                    state = .missing
                    return
                }
                try logUseCase.logAgain(item)
            case .candidate(let candidate):
                let log = try logUseCase.logNow(candidate)
                if let item = log.item { subject = .stored(item.id) }
            }
            didFailToLog = false
            load()
        } catch {
            didFailToLog = true
        }
    }
}
