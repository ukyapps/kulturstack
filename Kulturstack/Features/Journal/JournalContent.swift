struct JournalContent: Equatable {
    struct KindCount: Equatable {
        let kind: MediaKind
        let count: Int
    }

    let sections: [JournalDaySection]
    let total: Int
}
