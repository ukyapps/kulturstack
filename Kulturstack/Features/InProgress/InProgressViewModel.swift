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
    private let status: WatchStatusUseCase
    private let advanceUseCase: AdvanceUseCase

    init(useCase: InProgressUseCase, repository: any MediaRepository,
         advance: AdvanceUseCase, status: WatchStatusUseCase) {
        self.useCase = useCase
        self.repository = repository
        self.advanceUseCase = advance
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
    // Le Journal fait la même chose par le même chemin.
    func advance(_ row: InProgressRowModel) async {
        do {
            try advanceUseCase.advance(itemID: row.itemID)
            didFailToAdvance = false
        } catch {
            didFailToAdvance = true
        }
        await load()
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
