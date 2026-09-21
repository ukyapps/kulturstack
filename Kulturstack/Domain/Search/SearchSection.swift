struct SearchSection: Sendable, Equatable, Identifiable {
    let family: SearchFamily
    var state: SectionState

    var id: SearchFamily { family }
}

enum SectionState: Sendable, Equatable {
    case loading
    case loaded([MediaCandidate])
    case empty
    case failed(reason: String)
}

enum SearchError: Error, Equatable {
    case timeout
}
