enum DomainError: Error, Equatable {
    case statusNotAllowed(LogStatus, for: MediaKind)
    case ratingOutOfRange(Int)
    case itemNotFound
    case seasonsNotAllowed(for: MediaKind)
    case episodeNotOfThisItem
}
