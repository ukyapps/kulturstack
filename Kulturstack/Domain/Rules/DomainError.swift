enum DomainError: Error, Equatable {
    case statusNotAllowed(LogStatus, for: MediaKind)
    case ratingOutOfRange(Int)
}
