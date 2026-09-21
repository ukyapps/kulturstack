import Foundation

struct OpenLibraryProvider: MetadataProvider {
    static let baseURL = URL(string: "https://openlibrary.org/search.json")!
    static let coverBaseURL = URL(string: "https://covers.openlibrary.org/b/id")!
    static let maxISBNKeys = 20
    static let maxSubjects = 10
    private static let fields = "key,title,author_name,first_publish_year,cover_i,isbn,number_of_pages_median,publisher,subject"

    let id = "openlibrary"
    let supportedKinds: Set<MediaKind> = [.book]

    private let client: any HTTPClient
    private let userAgent: String

    init(client: any HTTPClient, userAgent: String) {
        self.client = client
        self.userAgent = userAgent
    }

    func search(_ query: String) async throws -> [MediaCandidate] {
        var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: Self.fields),
            URLQueryItem(name: "limit", value: "20"),
        ]
        let data = try await client.get(components.url!, headers: [
            "User-Agent": userAgent,
            "Accept": "application/json",
        ])
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(OpenLibrarySearchResponse.self, from: data)
        return response.docs.compactMap { Self.candidate(from: $0) }
    }

    private static func candidate(from doc: OpenLibraryDoc) -> MediaCandidate? {
        guard let title = doc.title, !title.isEmpty else { return nil }
        let workID = doc.key.replacingOccurrences(of: "/works/", with: "")
        let workKey = ExternalRef.key(provider: "ol", value: "work:\(workID)")
        let isbnKeys = (doc.isbn ?? [])
            .filter { $0.count == 13 && $0.allSatisfy(\.isNumber) }
            .prefix(maxISBNKeys)
            .map { ExternalRef.key(provider: "isbn13", value: $0) }
        return MediaCandidate(
            id: workKey,
            kind: .book,
            title: title,
            originalTitle: nil,
            year: doc.firstPublishYear,
            creators: doc.authorName ?? [],
            coverURL: doc.coverI.map { coverBaseURL.appending(path: "\($0)-M.jpg") },
            summary: nil,
            externalKeys: [workKey] + isbnKeys,
            details: BookDetails(
                pageCount: doc.numberOfPagesMedian,
                publisher: doc.publisher?.first,
                firstPublishYear: doc.firstPublishYear,
                subjects: Array((doc.subject ?? []).prefix(maxSubjects))
            ),
            providerID: "openlibrary"
        )
    }
}
