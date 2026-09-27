import Foundation

struct OpenLibraryProvider: MetadataProvider {
    static let baseURL = URL(string: "https://openlibrary.org/search.json")!
    static let coverBaseURL = URL(string: "https://covers.openlibrary.org/b/id")!
    static let maxISBNKeys = 20
    static let maxSubjects = 10
    private static let fields = """
    key,title,author_name,author_alternative_name,first_publish_year,cover_i,isbn,\
    number_of_pages_median,publisher,subject,editions,editions.title,editions.language,editions.cover_i
    """

    let id = "openlibrary"
    let supportedKinds: Set<MediaKind> = [.book]

    private let client: any HTTPClient
    private let userAgent: String
    private let language: String

    init(client: any HTTPClient, userAgent: String, language: String = OpenLibraryProvider.preferredLanguage()) {
        self.client = client
        self.userAgent = userAgent
        self.language = language
    }

    // OpenLibrary parle le code à trois lettres : « fre », pas « fr ».
    static func preferredLanguage(locale: Locale = .current) -> String {
        locale.language.languageCode?.identifier == "fr" ? "fre" : "eng"
    }

    // Les éditions dans la langue de l'app d'abord : sans ce filtre, une recherche de Murakami
    // rend le titre de l'œuvre originale et la couverture d'une édition au hasard (retour du 27/09).
    // Un livre sans édition dans cette langue ne doit pas disparaître pour autant : on redemande.
    func search(_ query: String) async throws -> [MediaCandidate] {
        let localized = try await search(query, inLanguage: language)
        guard localized.isEmpty else { return localized }
        return try await search(query, inLanguage: nil)
    }

    private func search(_ query: String, inLanguage code: String?) async throws -> [MediaCandidate] {
        var components = URLComponents(url: Self.baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "q", value: code.map { "\(query) language:\($0)" } ?? query),
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
        return response.docs.compactMap { candidate(from: $0) }
    }

    private func candidate(from doc: OpenLibraryDoc) -> MediaCandidate? {
        let edition = doc.editions?.docs.first { ($0.language ?? []).contains(language) }
        guard let title = edition?.title ?? doc.title, !title.isEmpty else { return nil }
        let workID = doc.key.replacingOccurrences(of: "/works/", with: "")
        let workKey = ExternalRef.key(provider: "ol", value: "work:\(workID)")
        let isbnKeys = (doc.isbn ?? [])
            .filter { $0.count == 13 && $0.allSatisfy(\.isNumber) }
            .prefix(Self.maxISBNKeys)
            .map { ExternalRef.key(provider: "isbn13", value: $0) }
        return MediaCandidate(
            id: workKey,
            kind: .book,
            title: title,
            originalTitle: nil,
            year: doc.firstPublishYear,
            creators: Self.creators(of: doc),
            coverURL: (edition?.coverI ?? doc.coverI).map { Self.coverBaseURL.appending(path: "\($0)-M.jpg") },
            summary: nil,
            externalKeys: [workKey] + isbnKeys,
            details: BookDetails(
                pageCount: doc.numberOfPagesMedian,
                publisher: doc.publisher?.first,
                firstPublishYear: doc.firstPublishYear,
                subjects: Array((doc.subject ?? []).prefix(Self.maxSubjects))
            ),
            providerID: "openlibrary"
        )
    }

    // La source nomme Murakami « 村上春樹 ». Sa variante latine est dans les noms alternatifs :
    // on prend la plus courte qui ne crie pas — les variantes tout en capitales y sont légion.
    private static func creators(of doc: OpenLibraryDoc) -> [String] {
        let names = doc.authorName ?? []
        guard let first = names.first, !isLatin(first) else { return names }
        let readable = (doc.authorAlternativeName ?? [])
            .filter { isLatin($0) && !shouts($0) }
            .min { ($0.count, $0) < ($1.count, $1) }
        return [readable ?? first] + names.dropFirst()
    }

    private static func isLatin(_ name: String) -> Bool {
        name.range(of: "[A-Za-zÀ-ÖØ-öø-ÿ]", options: .regularExpression) != nil
    }

    private static func shouts(_ name: String) -> Bool {
        name.split(separator: " ").contains { $0.count > 1 && $0 == Substring($0.uppercased()) }
    }
}
