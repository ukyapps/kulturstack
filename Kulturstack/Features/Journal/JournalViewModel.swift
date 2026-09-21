import Foundation
import Observation

@MainActor @Observable
final class JournalViewModel {
    enum State: Equatable {
        case loading
        case empty
        case loaded([JournalRowModel])
        case failed
    }

    private(set) var state: State = .loading
    var didFailToDelete = false
    private let repository: any LogRepository
    private let editUseCase: EditLogUseCase

    init(repository: any LogRepository) {
        self.repository = repository
        editUseCase = EditLogUseCase(repository: repository)
    }

    func delete(id: UUID) async {
        do {
            guard let log = try editUseCase.log(id: id) else { return }
            try editUseCase.delete(log)
            await load()
        } catch {
            didFailToDelete = true
        }
    }

    func load() async {
        do {
            let logs = try await repository.fetchAll()
            state = logs.isEmpty ? .empty : .loaded(logs.map(JournalRowModel.init))
        } catch {
            state = .failed
        }
    }
}
