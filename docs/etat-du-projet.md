---
type: état des lieux
maj: 2026-09-21
règle: mis à jour à chaque PR fusionnée — c'est la photo du projet, pas son histoire (l'histoire est dans docs/journal/)
---

# État du projet

## 1. En deux lignes

Le cadrage est complet (12 ADRs, PRD, design, TDD, plan T1). Le code contient les **fondations** (projet Xcode, design system, schéma V1 + migration), le **Journal** (liste des logs, états vide / erreur, seed DEBUG) et l'**écran Recherche** (deux onglets, TMDB + OpenLibrary en parallèle, sections par famille, chips) **le log en 1 tap** (tap sur un résultat → fiche créée ou retrouvée par ses clés externes, log « terminé » daté maintenant, bandeau « loggé ✓ », le Journal se met à jour) et **l'édition d'un log** (feuille : date + raccourcis, demi-étoiles, statut limité au type, commentaire, suppression ; depuis le bandeau et par appui long dans le Journal). 123 tests. **Le cœur du produit marche** ; il manque la fiche (PR 8), les filtres du Journal (PR 9), Envie (PR 10), les réglages (PR 11).

## 2. Features — planifié vs livré

### Tranche 1 — Le log magique (en cours, 8 PRs sur 12)

| PR | Feature | État |
|---|---|---|
| 0 | Bootstrap : projet, Makefile, secrets, `EmptyState`, FR/EN, CI tests | ✅ fusionnée (#1, 2026-09-20) |
| 1 | Schéma V1 + plan de migration + règles métier | ✅ fusionnée (#2, 2026-09-20) |
| 2 | Journal vide + seed DEBUG | ✅ PR #4 (2026-09-20) |
| 3 | Secrets + client TMDB | ✅ PR #5 (2026-09-21) |
| 4 | OpenLibrary + recherche unifiée | ✅ PR #6 (2026-09-21) |
| 5 | Écran Recherche | ✅ PR #7 (2026-09-21) |
| 6 | Log en 1 tap | ✅ PR #8 (2026-09-21) |
| 7 | Modifier un log (date, demi-étoiles, statut, note, supprimer) | ✅ PR #9 (2026-09-21) |
| 8 | Fiche d'une œuvre | ⏳ prochaine |
| 9 | Journal par période et par type, compteurs | — |
| 10 | Envie | — |
| 11 | Réglages, À propos, Confidentialité, finitions | — |
| — | TestFlight | — |

### Tranches suivantes (rien de commencé)

| # | Tranche | Contenu | Serveur |
|---|---|---|---|
| 2 | Épisodes | saisons / épisodes (séries, podcasts), « où j'en suis », statuts en cours / abandonné | non |
| 3 | Import du passé | Trakt ZIP JSON, CSV Goodreads / IMDb / Letterboxd / générique, file « à confirmer », export JSON | non |
| 4 | Disques + Podcasts | Discogs, Apple Podcasts + RSS | non |
| 5 | Collection | `OwnedCopy`, formats, import collection Discogs, scan code-barres, « Ma bibliothèque » | non |
| 6 | Jeux + Concerts | IGDB, Setlist.fm, **proxy Supabase** | oui |
| 7 | Théâtre / Expos + IA | saisie assistée, enrichissement LLM, recos, export Obsidian | oui |
| 8 | Social | comptes, partage, sync — nice-to-have | oui |

Le détail de chaque feature : `docs/product/prd.md` §6. Les écrans : `docs/product/design.md`.

## 3. Architecture — telle qu'implémentée

```
Kulturstack/
├── App/
│   ├── KulturstackApp.swift          ouvre le ModelContainer de prod ; EmptyState d'erreur si échec
│   ├── RootView.swift                TabView Journal / Recherche ; compose LogUseCase + providers ; badge DEBUG
│   └── ModelContainerFactory.swift   production() / onDisk(url:) / inMemory() — toujours avec le plan de migration
├── Data/
│   ├── Network/
│   │   ├── SecretsProviding.swift    protocole + SecretKey (.tmdbReadToken) + SecretsError.missing (message = commande d'ajout)
│   │   ├── BundleSecrets.swift       lit Info.plist ; vide, blanc ou « $(…) » non résolu = manquant
│   │   ├── HTTPClient.swift          protocole get(url, headers) + HTTPError
│   │   └── URLSessionHTTPClient.swift  timeout 8 s, non-2xx → HTTPError.status
│   ├── Providers/
│   │   ├── ProviderRegistry.swift    live(secrets:client:appVersion:) = [TMDB, OpenLibrary] ; userAgent(appVersion:)
│   │   ├── TMDBProvider.swift        search/multi fr-FR|en-US, Bearer, garde movie + tv, clés tmdb:movie:<id> / tmdb:tv:<id>, affiches w342
│   │   ├── TMDBSearchResponse.swift  DTO Decodable (snake_case)
│   │   ├── OpenLibraryProvider.swift search.json, User-Agent « Kulturstack/<v> (+repo) », clés ol:work:<id> + isbn13:<…> (max 20), couverture -M, BookDetails
│   │   └── OpenLibrarySearchResponse.swift  DTO
│   └── Repositories/
│       ├── SwiftDataLogRepository.swift  fetchAll (date desc, createdAt desc) · find(id:) · save() · delete(_:)
│       └── SwiftDataMediaRepository.swift  findItem(withAnyKey:) via #Predicate sur ExternalRef.key ; add item + refs ; add refs ; add log
├── Features/
│   ├── Journal/
│   │   ├── JournalView.swift         4 rendus : chargement · vide (EmptyState) · erreur (EmptyState + Réessayer) · liste ; appui long → Modifier (feuille) / Supprimer (confirmation)
│   │   ├── JournalViewModel.swift    @Observable ; state = loading | empty | loaded([JournalRowModel]) | failed ; delete(id:) + didFailToDelete
│   │   ├── JournalRowModel.swift     instantané VALEUR d'un log (titre, sous-titre, date, statut, note, jaquette)
│   │   └── JournalRow.swift          jaquette + titre + « Type · année ou auteur » + date + pastille statut + étoiles
│   ├── Search/
│   │   ├── SearchView.swift          .searchable + focus à l'ouverture ; 4 rendus ; chaque ligne est un bouton → log ; Toast en overlay avec « Modifier » → feuille
│   │   ├── SearchViewModel.swift     query (didSet → debounce 300 ms), sections, selectedKind, presentation ; log(candidate) → logNow injecté (renvoie l'id) + toast 4 s portant l'id
│   │   ├── SearchResultRowModel.swift  instantané valeur d'un candidat (titre, « Type · année · créateur », jaquette)
│   │   ├── SearchResultRow.swift     MediaRow sans accessoire (le tap arrive en PR 6)
│   │   └── KindChips.swift           « Tous » + un chip par type des familles enregistrées
│   ├── LogEdit/
│   │   ├── LogEditView.swift         feuille : titre « Dune (2021) », date + raccourcis, StarRatingPicker, statut segmenté, commentaire, supprimer ; 4 rendus (chargement · formulaire · introuvable · erreur)
│   │   ├── LogEditViewModel.swift    load() → champs éditables ; save() / delete() → Bool + didFail ; allowedStatuses du type
│   │   ├── DateShortcut.swift        today · yesterday · weekend (samedi le plus récent), heure conservée
│   │   └── LogReference.swift        l'id qu'une vue garde pour ouvrir la feuille (jamais le @Model)
│   └── Shared/
│       ├── MediaKind+Presentation.swift   label, pluralLabel + symbole SF par type
│       ├── LogStatus+Presentation.swift   label localisé par statut
│       └── SearchFamily+Presentation.swift  label localisé par famille
├── Debug/                            compilé hors Release
│   ├── DemoSeed.swift                fill() = wipe() puis 23 fiches / 25 logs sur 12 mois ; wipe() = tout supprimer
│   ├── DebugMenu.swift               coccinelle dans la toolbar : « Remplir données démo » / « Tout effacer » / « Test recherche TMDB »
│   └── DebugSearchView.swift         champ + sections par famille (5 lignes max) + interrupteur « Simuler une panne OpenLibrary » + Réessayer ; sans test (outil jetable)
├── Domain/
│   ├── Models/
│   │   ├── MediaKind.swift           9 types ; hasEpisodes, hasDuration, allowedStatuses, searchFamily
│   │   ├── LogStatus.swift           wishlist · inProgress · done · dropped
│   │   ├── MediaItem.swift           la fiche : champs communs + detailsData (poche) ; relations externalRefs / logs
│   │   ├── ExternalRef.swift         clé unique "provider:value"
│   │   └── LogEntry.swift            fabrique make() qui valide statut et note ; date = .now par défaut
│   ├── Details/
│   │   ├── DetailsPayload.swift      FilmDetails · SeriesDetails · BookDetails · GenericDetails (tolérants)
│   │   └── DetailsCodec.swift        encode / decode(kind:) ; currentVersion = 1
│   ├── Repositories/                 PROTOCOLES (les impls SwiftData sont dans Data/)
│   │   ├── LogRepository.swift       fetchAll() · find(id:) · save() · delete(_:)
│   │   └── MediaRepository.swift     findItem(withAnyKey:) · add(item, refs:) · add(refs, to:) · add(log)
│   ├── Rules/
│   │   ├── LogRules.swift            validate(status:for:) · validate(rating:)
│   │   └── DomainError.swift
│   ├── Search/
│   │   ├── MetadataProvider.swift    protocole : id, supportedKinds, search(_:)
│   │   ├── MediaCandidate.swift      résultat de recherche ; identité = clé externe principale
│   │   └── SearchSection.swift       famille + SectionState (loading · loaded · empty · failed(reason)) ; SearchError.timeout
│   ├── UseCases/
│   │   ├── EditLogUseCase.swift      log(id:) · update(date, status, rating, note) validé par LogRules, commentaire blanc → nil · delete
│   │   ├── SearchUseCase.swift       search(_:) → AsyncStream<SearchSection> : loading pour chaque famille, puis TaskGroup, timeout 8 s par provider, annulation propagée ; retry(_:family:)
│   │   ├── DedupUseCase.swift        existingItem(for: candidate) = fiche partageant AU MOINS une clé externe (ADR-004)
│   │   └── LogUseCase.swift          logNow(candidate, status: .done) : valide le statut, retrouve ou crée la fiche (+ poche encodée + refs), ajoute les clés manquantes, crée le log source « manual »
│   └── Schema/
│       ├── KulturstackSchemaV1.swift 3 modèles ; typealias MediaItem / ExternalRef / LogEntry
│       └── KulturstackMigrationPlan.swift  schemas [V1], stages [], current
├── DesignSystem/
│   ├── Tokens.swift                  Spacing, Radius, Color.*
│   ├── EmptyState.swift              icône + titre + message + action optionnelle
│   ├── StarRating.swift              note 1…10 → 5 étoiles avec demi ; Stars(rating:) testable
│   ├── StarRatingPicker.swift        5 étoiles, chaque moitié cliquable ; re-tap = sans note ; VoiceOver ajustable
│   ├── CoverThumbnail.swift          AsyncImage 2:3 avec placeholder par symbole
│   ├── MediaRow.swift                jaquette + titre + sous-titre + accessoire générique
│   ├── Chip.swift                    capsule sélectionnable (accent quand active)
│   ├── SectionHeader.swift           titre de section + spinner optionnel
│   └── Toast.swift                   bandeau accent (ou rouge si erreur) avec icône et action optionnelle
└── Resources/
    ├── Localizable.xcstrings         93 clés FR + EN
    ├── PrivacyInfo.xcprivacy         aucune donnée collectée
    └── Assets.xcassets               AccentColor, AppIcon (vide)
```

**Pas encore là** : `ItemDetail` (PR 8), filtres et groupement par jour du Journal (PR 9), `Settings` (PR 11), bandeau hors-ligne (PR 11), « Vu le … » sur une ligne de résultat déjà loggée (design §3.2, à faire en PR 8 avec la fiche), tap sur une ligne du Journal → fiche (PR 8).

**Écart au TDD 01** : les *protocoles* de repositories sont dans `Domain/Repositories/` (pas `Data/`) pour que `Domain/UseCases/` n'importe rien de `Data/`. Les implémentations SwiftData restent dans `Data/`.

**Règle apprise en PR 2** : une vue ne garde jamais un `@Model` en main — le ViewModel expose des instantanés valeur (`JournalRowModel`), et une feuille s'ouvre sur un `LogReference` (un id). Sinon, supprimer l'objet pendant que la liste l'affiche fait planter l'app (vu au premier « Tout effacer »).

## 4. Tests — 123, tous verts

| Fichier | Tests | Couvre |
|---|---|---|
| `SmokeTests` | 2 | `EmptyState` garde son contenu ; FR et EN existent |
| `MediaKindTests` | 4 (paramétrés : 9 cas) | statuts par type, épisodes, familles de recherche |
| `LogRulesTests` | 7 (paramétrés : 11 cas) | **T-02** statut interdit, **T-03** note hors plage, **T-06** date = maintenant, fabrique refuse un statut interdit |
| `DetailsCodecTests` | 5 | round-trip, **T-15** champs manquants → défauts, `{}` → défauts, décodage par type, `MediaItem.details` |
| `SchemaMigrationTests` | 3 | **T-01** store V1 rouvert avec le plan → données intactes ; schéma courant = dernier du plan ; clé `ExternalRef` unique |
| `DemoSeedTests` | 3 | **T-14** fill × 2 = mêmes comptes ; wipe → 0 ; logs dans les 12 derniers mois, avec notes et commentaires |
| `SwiftDataLogRepositoryTests` | 2 | tri du plus récent au plus ancien ; base vide → liste vide |
| `EditLogUseCaseTests` | 6 | find par id ; update persiste date / statut / note / commentaire trimé ; blanc → nil ; statut interdit refusé ; note hors plage refusée ; delete garde la fiche |
| `JournalViewModelTests` | 8 | loading au départ ; vide ; chargé ; erreur ; reprise après erreur ; **l'état survit à la suppression des logs** (régression du crash) ; delete(id:) recharge ; échec de suppression signalé |
| `LogEditViewModelTests` | 9 | load remplit le formulaire ; titre sans année ; statuts du type (film, livre) ; introuvable ; erreur de lecture ; save écrit ; save invalide → didFail sans rien changer ; delete ; raccourci de date |
| `LogEditViewRenderingTests` | 2 | la feuille se rend en formulaire et en « introuvable » ; le picker se rend pour chaque note |
| `DateShortcutTests` | 4 (paramétrés : 8 cas) | aujourd'hui = maintenant ; hier garde l'heure ; « ce week-end » = samedi le plus récent (mer., lun., dim., sam., ven.) ; labels |
| `StarRatingPickerTests` | 3 (paramétrés : 6 cas) | tap = valeur ; re-tap = sans note ; étoile × moitié → 1…10 |
| `JournalRowModelTests` | 4 | livre → auteur, film → année, repli, champs recopiés |
| `JournalRowRenderingTests` | 1 | la ligne se rend avec et sans note (UIHostingController) |
| `MediaKindPresentationTests` | 4 (paramétrés : 19 cas) | chaque type (singulier et pluriel), statut et famille a un label, FR et EN |
| `StarRatingTests` | 1 (paramétré : 6 cas) | 1…10 → étoiles pleines / demi |
| `SecretsTests` | 5 (paramétrés : 7 cas) | **T-13** manquant → message avec la commande ; blanc / « $(…) » = manquant ; valeur trimée ; bundle sans clé ; `MockSecrets` |
| `URLSessionHTTPClientTests` | 3 | en-têtes + timeout 8 s + GET (via `StubURLProtocol`) ; 401 → `HTTPError.status` ; panne réseau propagée |
| `TMDBProviderTests` | 10 (paramétrés : 13 cas) | **T-10** fixture réelle → 8 films + 5 séries, personnes ignorées ; film et série détaillés ; ordre conservé ; URL + langue + Bearer ; secret manquant → aucun appel réseau ; 401 et JSON cassé → erreur ; langue selon la locale |
| `MediaCandidateTests` | 1 | identité = clé externe |
| `OpenLibraryProviderTests` | 5 | **T-11** fixture réelle → 20 livres, `ol:work:` + `isbn13:` (13 chiffres, max 20) ; `BookDetails` ; **T-12** User-Agent + requête ; 503 propagé ; livres seulement |
| `ProviderRegistryTests` | 2 | live = [tmdb, openlibrary], familles [écran, livres] ; User-Agent nomme l'app et un contact |
| `SearchViewModelTests` | 13 | tap → logNow + toast (portant l'id du log) qui s'efface, échec → toast d'erreur sans id ; idle sous 2 caractères ; une section par famille ; **debounce → un seul appel avec la dernière saisie** ; effacer → idle ; filtre par type (candidats filtrés, familles étrangères masquées) ; filtre sans résultat = edge ; rien nulle part = aucun résultat ; section en erreur visible à côté des résultats ; retry ciblé ; chips = types des familles ; sous-titre |
| `SearchViewRenderingTests` | 2 | l'écran traverse ses 4 rendus dans une UIWindow ; chips, en-tête et ligne se rendent |
| `LogUseCaseTests` | 6 | premier log = fiche + refs + poche + log done/manual/maintenant ; **T-04** deux fois le même candidat → 1 fiche, 2 logs ; **T-05** clé partagée → même fiche, clés nouvelles ajoutées ; œuvres différentes → fiches différentes ; Envie accepté, statut interdit refusé ; `findItem(withAnyKey:)` |
| `SearchUseCaseTests` | 8 | loading pour chaque famille puis settle ; **T-07** panne isolée ; **T-09** le rapide n'attend pas le lent ; **T-08** annulation → providers annulés, rien de périmé ; timeout → failed ; vide → empty ; retry n'appelle que la famille ; ordre canonique des familles |

Couverture : `Domain/` 95 %, `Data/` 98 %, `Features/` 87 %, `DesignSystem/` 86 %. Fixtures réelles : `tmdb-search-multi-dune.json`, `openlibrary-search-dune.json` (capturées le 21/09/2026). Réseau stubbé par `StubURLProtocol` (suite `.serialized`) ou `StubHTTPClient` ; providers simulés par `MockProvider` (délai, erreur, trace d'annulation). Cibles (≥ 70 % Domain et Data, ≥ 50 % Features) tenues.

Tests du plan pas encore écrits : T-16 (stats, PR 9), T-17 (conversion des notes, T3).

## 5. Infrastructure

| | État |
|---|---|
| Repo | `ukyapps/kulturstack`, public, `main` par défaut |
| Protection de `main` | ruleset `protect-main` : PR obligatoire, check `test` requis, pas de bypass, pas de force-push, pas de suppression |
| CI | `tests.yml` : macos-26, Xcode 26.3, `make test`, ~5 min. **Vert.** |
| Review | **locale**, par Claude, avant chaque push (CLAUDE.md § Review locale). Plus de review en CI (ADR-012). |
| Secrets GitHub | aucun |
| Secrets locaux | Trousseau `kulturstack` : `TMDB_READ_TOKEN` posé le 21/09 (usage personnel déclaré à TMDB — à renégocier si monétisation). `Config/Secrets.xcconfig` généré, gitignoré. |
| Outils locaux | Xcode 26.3, Swift 6.2, XcodeGen 2.46, simulateur iPhone 17 Pro (iOS 26.2), hook pre-commit installé. Repo dans `~/Documents/kulturstack` (déplacé du Bureau le 21/09) |
| Identité git | `ukyapps` + email noreply |
| Domaines | kulturstack.com / .app / .io / .fr **libres au 19/09, pas réservés** |

## 6. Décisions (12 ADRs)

001 clé TMDB embarquée · 002 modèle générique + poche · 003 migration dès la PR 1 · 004 identité et dédup · 005 recherche unifiée · 006 notation et statuts · 007 iOS 18 + FR/EN · 008 nom Kulturstack · 009 Trakt par export JSON · 010 collection `OwnedCopy` · 011 ordre des tranches · 012 review locale, pas de review CI.

## 7. Carte de la documentation

| Fichier | Quoi | Quand le lire |
|---|---|---|
| `README.md` | carte du projet, identité | en arrivant |
| `CLAUDE.md` | conventions, review locale, contexte founder | **à chaque session** |
| `docs/etat-du-projet.md` | **ce fichier** — la photo à date | à chaque session |
| `docs/journal/` | une page par session : décisions, pièges, à-faire | pour reprendre |
| `docs/product/prd.md` | le produit : problème, principes, périmètre, exigences | avant de planifier |
| `docs/product/design.md` | l'expérience : écrans, états, design system | avant un écran |
| `docs/product/retours-utilisateurs.md` | ce que la founder (et plus tard d'autres) a dit, et ce qu'on en a fait | avant de trancher |
| `docs/tdd/01…07` | architecture, modèle, protocoles, sources, tests, secrets, RGPD | avant de coder une couche |
| `docs/decisions/001…012` | les ADRs | quand on se demande « pourquoi » |
| `docs/plans/tranche-1.md` | les 12 PRs de T1 | avant chaque PR |

## 8. Ouvert / à faire

**Founder** : réserver les domaines · (optionnel) désinstaller l'app GitHub « Claude » · recherche INPI avant le store · avant toute monétisation, demander l'accord commercial TMDB.

**Prochaine session** : PR 8 — Fiche d'une œuvre (jaquette, titre, année, créateurs, résumé, poche selon le type, tous les logs de la fiche, « Logger à nouveau »), plus « Vu le … » sur une ligne de résultat déjà loggée et le tap sur une ligne du Journal → fiche. Le bandeau hors-ligne de la Recherche est reporté en PR 11.

**Questions produit ouvertes** (PRD §9, design §6) : musique écoutée vs possédée ; recherche = onglet ou « + » ; journal groupé par jour (la démo de la PR 7 plaide pour : un log qui change de date « disparaît » en bas de liste) ; Envie en chip.
