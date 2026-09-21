import Foundation

struct OpenLibrarySearchResponse: Decodable {
    let docs: [OpenLibraryDoc]
}

struct OpenLibraryDoc: Decodable {
    let key: String
    let title: String?
    let authorName: [String]?
    let firstPublishYear: Int?
    let coverI: Int?
    let isbn: [String]?
    let numberOfPagesMedian: Int?
    let publisher: [String]?
    let subject: [String]?
}
