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
    private let repository: any LogRepository

    init(repository: any LogRepository) {
        self.repository = repository
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
