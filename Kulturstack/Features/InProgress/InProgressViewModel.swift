import Foundation
import Observation

@MainActor @Observable
final class InProgressViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([InProgressRowModel])
        case failed
    }

    private(set) var state: State = .loading
    var didFailToAdvance = false

    private let useCase: InProgressUseCase
    private let repository: any MediaRepository
    private let episodes: EpisodeUseCase
    private let status: WatchStatusUseCase

    init(useCase: InProgressUseCase, repository: any MediaRepository,
         episodes: EpisodeUseCase, status: WatchStatusUseCase) {
        self.useCase = useCase
        self.repository = repository
        self.episodes = episodes
        self.status = status
    }

    func load() async {
        do {
            let items = try await useCase.items()
            state = items.isEmpty ? .empty : .loaded(items.map(InProgressRowModel.init))
        } catch {
            state = .failed
        }
    }

    // Le ✓ coche la suite, une seule : il ne comble pas ce qui a été sauté derrière.
    func advance(_ row: InProgressRowModel) async {
        await change(row) { item in
            guard let next = InProgressUseCase.next(for: item) else { return }
            try episodes.toggle(next, of: item)
            try status.refreshAfterChecking(item)
        }
    }

    func finish(_ row: InProgressRowModel) async {
        await change(row) { try status.finish($0) }
    }

    private func change(_ row: InProgressRowModel, _ action: (MediaItem) throws -> Void) async {
        do {
            if let item = try repository.find(itemID: row.itemID) { try action(item) }
            didFailToAdvance = false
        } catch {
            didFailToAdvance = true
        }
        await load()
    }
}
