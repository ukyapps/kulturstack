import Foundation

extension LogStatus {
    var label: String {
        switch self {
        case .wishlist: String(localized: "status.wishlist")
        case .inProgress: String(localized: "status.inProgress")
        case .done: String(localized: "status.done")
        case .dropped: String(localized: "status.dropped")
        }
    }
}
