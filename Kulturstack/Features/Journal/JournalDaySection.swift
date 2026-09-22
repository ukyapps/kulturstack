import Foundation

struct JournalDaySection: Identifiable, Equatable {
    let id: Date
    let title: String
    var rows: [JournalRowModel]
}
