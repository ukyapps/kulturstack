---
type: tdd
statut: accepté
créé: 2026-09-20
---

# 03 — Protocoles

Deux protocoles isolent les sources externes du reste de l'app. Ajouter une source = un type conforme + son enregistrement. Rien d'autre ne bouge.

## `MetadataProvider` — chercher une œuvre (ADR-005)

```swift
protocol MetadataProvider: Sendable {
    var id: String { get }                        // "tmdb", "openlibrary", "discogs"…
    var supportedKinds: Set<MediaKind> { get }
    func search(_ query: String) async throws -> [MediaCandidate]
    func lookup(barcode: String) async throws -> MediaCandidate?   // T5 ; défaut = nil
}

struct MediaCandidate: Identifiable, Hashable, Sendable {
    let id: String                 // = clé externe principale, ex. "tmdb:movie:438631"
    let kind: MediaKind
    let title: String
    let originalTitle: String?
    let year: Int?
    let creators: [String]
    let coverURL: URL?
    let summary: String?
    let externalKeys: [String]     // toutes les clés connues, la principale incluse
    let details: any DetailsPayload  // FilmDetails / BookDetails… (type-erased, Codable)
    let providerID: String
}
```

### Recherche unifiée : `SearchUseCase`

- Debounce 300 ms sur la saisie ; toute nouvelle saisie **annule** la tâche précédente.
- Lance `search` sur **tous** les providers enregistrés en parallèle (`withTaskGroup`).
- Émet un `AsyncStream<SearchSection>` : chaque section = une famille de types (`SearchFamily`) + un état :

```swift
enum SectionState { case loading; case loaded([MediaCandidate]); case empty; case failed(message: String, retry: () async -> Void) }
struct SearchSection { let family: SearchFamily; var state: SectionState }
```

- Une section **n'attend pas** les autres. Une panne OpenLibrary n'affecte que la section Livres.
- Pas de classement inter-sections. À l'intérieur d'une section : ordre du provider (TMDB trie déjà par pertinence/popularité ; OpenLibrary par pertinence).
- Filtre par type (chips) = filtre client-side sur les sections déjà reçues, jamais une nouvelle requête.
- Timeout par provider : 8 s → `failed` avec bouton réessayer.

### Providers de la Tranche 1

| Provider | Endpoint | Auth | Notes |
|---|---|---|---|
| **TMDB** | `GET /3/search/multi?query=&language=fr-FR&include_adult=false` — filtrer `media_type ∈ {movie, tv}` | `Authorization: Bearer <read access token v4>` | Images : `https://image.tmdb.org/t/p/w342<poster_path>`. Attribution obligatoire (logo + mention dans À propos). Clés externes : `tmdb:movie:<id>` / `tmdb:tv:<id>`. L'IMDb id n'est pas dans `/search` — récupéré plus tard si besoin via `/movie/{id}/external_ids` (T3, pour la dédup). |
| **OpenLibrary** | `GET https://openlibrary.org/search.json?q=&fields=key,title,author_name,first_publish_year,cover_i,isbn,number_of_pages_median,publisher,subject&limit=20` | aucune ; header `User-Agent: Kulturstack/<version> (<email de contact>)` | 3 req/s identifié. Couvertures : `https://covers.openlibrary.org/b/id/<cover_i>-M.jpg`. Clé externe : `ol:work:<key sans /works/>` + `isbn13:<…>` pour chaque ISBN-13 remonté. Identité au niveau **work** (ADR-004). |

Le `MockProvider` de test renvoie des candidats fixes, avec un délai et une erreur configurables.

## `HistoryImporter` — récupérer le passé (T3, conçu maintenant)

```swift
protocol HistoryImporter: Sendable {
    var id: String { get }                                   // "trakt-json", "csv-goodreads", "csv-imdb", "csv-letterboxd", "csv-generic"
    func canHandle(_ file: ImportFile) -> Bool
    func parse(_ file: ImportFile) async throws -> [ImportedEntry]
}

struct ImportedEntry: Sendable {
    let kindHint: MediaKind?
    let title: String
    let year: Int?
    let externalKeys: [String]     // ce que la source connaît : Trakt → tmdb + imdb ; Goodreads → isbn13 ; IMDb → imdb ; Letterboxd → rien
    let date: Date?                // date de visionnage/lecture ; nil → date d'import, marqué "date inconnue"
    let rating: Int?               // déjà converti en 1...10
    let status: LogStatus
    let sourceLabel: String
}
```

### `ImportResolver` (réutilise `DedupUseCase`)

1. Pour chaque `ImportedEntry`, si une clé externe correspond à un `ExternalRef` existant → fiche trouvée.
2. Sinon, si des clés externes existent mais pas de fiche → créer la fiche (les métadonnées seront complétées par un provider, best-effort).
3. Sinon (Letterboxd) → `MetadataProvider.search("<title> <year>")` ; **un seul** candidat avec titre normalisé égal et année identique → lier ; sinon → file **« À confirmer »** présentée à l'utilisatrice.
4. Créer le `LogEntry` (source = `import:<id>`) ; dédoublonner par (fiche, jour civil, source).

Jamais de fusion silencieuse en cas d'ambiguïté.

### Formats attendus (à re-vérifier en T3, ils bougent)

| Source | Forme | Colonnes / champs clés |
|---|---|---|
| Trakt | ZIP de JSON (`Settings → Data → Export`) | `history*.json` : `watched_at`, `movie.ids.{trakt,tmdb,imdb}`, `episode`/`show.ids`… ; `ratings*.json` |
| Goodreads | CSV | `Title`, `Author`, `ISBN13`, `My Rating` (0-5), `Date Read`, `Exclusive Shelf` (read / currently-reading / to-read) |
| IMDb | CSV | `Const` (tt…), `Your Rating` (1-10), `Date Rated`, `Title Type` |
| Letterboxd | CSV (`watched.csv`, `ratings.csv`, `diary.csv`) | `Name`, `Year`, `Watched Date`, `Rating` (0.5-5), `Letterboxd URI` |
| Discogs (T5) | CSV export collection ou API `/users/{u}/collection` | `release_id`, `Format`, `Date Added` |
| Générique | CSV | mapping manuel titre / date / note / type |

## Enregistrement

```swift
struct ProviderRegistry {
    let providers: [any MetadataProvider]
    // T1 : [TMDBProvider(...), OpenLibraryProvider(...)]
    // T4 : + DiscogsProvider, ApplePodcastsProvider
    // T6 : + IGDBProvider(proxy), SetlistFMProvider(proxy)
}
```

Injecté par initializer dans `SearchUseCase`. Aucun singleton.
