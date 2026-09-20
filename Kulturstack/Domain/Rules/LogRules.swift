enum LogRules {
    static let ratingRange = 1...10

    static func validate(status: LogStatus, for kind: MediaKind) throws {
        guard kind.allowedStatuses.contains(status) else {
            throw DomainError.statusNotAllowed(status, for: kind)
        }
    }

    static func validate(rating: Int?) throws {
        guard let rating else { return }
        guard ratingRange.contains(rating) else { throw DomainError.ratingOutOfRange(rating) }
    }
}
