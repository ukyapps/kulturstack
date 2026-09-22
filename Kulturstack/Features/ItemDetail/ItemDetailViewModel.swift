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
    private(set) var enrichmentTask: Task<Void, Never>?
    private let repository: any MediaRepository
    private let logUseCase: LogUseCase
    private let enrich: EnrichUseCase?

    init(subject: Subject, repository: any MediaRepository, logUseCase: LogUseCase, enrich: EnrichUseCase? = nil) {
        self.subject = subject
        self.repository = repository
        self.logUseCase = logUseCase
        self.enrich = enrich
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
                enrichIfNeeded(item)
            case .candidate(let candidate):
                if let item = try repository.findItem(withAnyKey: candidate.externalKeys) {
                    subject = .stored(item.id)
                    state = .loaded(ItemDetailModel(item: item))
                    enrichIfNeeded(item)
                } else {
                    state = .loaded(ItemDetailModel(candidate: candidate))
                }
            }
        } catch {
            state = .failed
        }
    }

    // Une seule tentative par ouverture : si la source ne répond pas, la fiche reste comme elle est.
    private func enrichIfNeeded(_ item: MediaItem) {
        guard let enrich, enrichmentTask == nil, EnrichUseCase.needsEnrichment(item) else { return }
        enrichmentTask = Task {
            if await enrich.enrich(item), case .loaded = state {
                state = .loaded(ItemDetailModel(item: item))
            }
        }
    }

    func log() {
        record(stored: { try logUseCase.logAgain($0) }, candidate: { try logUseCase.logNow($0) })
    }

    func wish() {
        record(stored: { try logUseCase.wish($0) }, candidate: { try logUseCase.wish($0) })
    }

    private func record(stored: (MediaItem) throws -> LogEntry, candidate: (MediaCandidate) throws -> LogEntry) {
        do {
            switch subject {
            case .stored(let itemID):
                guard let item = try repository.find(itemID: itemID) else {
                    state = .missing
                    return
                }
                _ = try stored(item)
            case .candidate(let value):
                let log = try candidate(value)
                if let item = log.item { subject = .stored(item.id) }
            }
            didFailToLog = false
            load()
        } catch {
            didFailToLog = true
        }
    }
}
