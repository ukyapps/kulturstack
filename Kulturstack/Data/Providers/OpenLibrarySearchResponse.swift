import Foundation

struct OpenLibrarySearchResponse: Decodable {
    let docs: [OpenLibraryDoc]
}

struct OpenLibraryDoc: Decodable {
    let key: String
    let title: String?
    let authorName: [String]?
    let authorAlternativeName: [String]?
    let firstPublishYear: Int?
    let coverI: Int?
    let isbn: [String]?
    let numberOfPagesMedian: Int?
    let publisher: [String]?
    let subject: [String]?
    // Ce que la source répond quand on lui demande les éditions qui correspondent à la requête :
    // c'est là que vit « Kafka sur le rivage », là où l'œuvre s'appelle 海辺のカフカ.
    let editions: OpenLibraryEditions?
}

struct OpenLibraryEditions: Decodable {
    let docs: [OpenLibraryEdition]
}

struct OpenLibraryEdition: Decodable {
    let title: String?
    let language: [String]?
    let coverI: Int?
}
