---
type: état des lieux
maj: 2026-09-22
règle: mis à jour à chaque PR fusionnée — c'est la photo du projet, pas son histoire (l'histoire est dans docs/journal/)
---

# État du projet

## 1. En deux lignes

Le cadrage est complet (12 ADRs, PRD, design, TDD, plan T1). Le code contient les **fondations** (projet Xcode, design system, schéma V1 + migration), le **Journal** (liste des logs, états vide / erreur, seed DEBUG) et l'**écran Recherche** (deux onglets, TMDB + OpenLibrary en parallèle, sections par famille, chips) **le log en 1 tap** (tap sur un résultat → fiche créée ou retrouvée par ses clés externes, log « terminé » daté maintenant, bandeau « loggé ✓ », le Journal se met à jour) **l'édition d'un log** (feuille : date + raccourcis, demi-étoiles, statut limité au type, commentaire, suppression ; tap sur une ligne du Journal) et **la fiche d'une œuvre** (jaquette, détails par type, résumé, tous les logs, « Logger » ; ouverte au tap sur un résultat de Recherche, même pas encore en base) et **le + au bout de chaque résultat** qui logge en un geste avec « Vu le … » et bandeau « Modifier » ; la fiche d'un film ou d'une série se **complète chez TMDB** à l'ouverture (réalisateur, durée, genres, saisons) ; le **Journal se filtre** par Semaine · Mois · Année · Tout et par type, avec compteurs, groupé par jour ; l'onglet **Envie** garde ce qu'on veut voir (♡ sur un résultat ou dans la fiche, « Je l'ai vu » le fait passer au Journal) ; **Réglages** (Confidentialité, À propos avec attributions, Tout effacer en double confirmation), bandeau hors-ligne, icône provisoire. 195 tests. **La Tranche 1 est complète** ; prochaine étape : TestFlight.

## 2. Features — planifié vs livré

### Tranche 1 — Le log magique (**complète**, 14 PRs sur 14)

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
| 8 | Fiche d'une œuvre | ✅ PR #10 (2026-09-22) |
| 8b | Fiche depuis la Recherche (tap = fiche, + = loggé) | ✅ PR #11 (2026-09-22) |
| 8c | Détails TMDB (réalisateur, durée, genres, saisons) à l'ouverture de la fiche | ✅ PR #12 (2026-09-22) |
| 9 | Journal par période et par type, compteurs, groupé par jour | ✅ PR #13 (2026-09-22) |
| 10 | Envie — onglet, ♡ sur un résultat et dans la fiche, « Je l'ai vu » | ✅ PR #14 (2026-09-22) |
| 11 | Réglages, À propos, Confidentialité, Tout effacer, hors-ligne, icône | ✅ PR #15 (2026-09-22) |
| — | Sur l'iPhone (câble, Personal Team) | ✅ 23/09 — installée et lancée sur l'iPhone de la founder |
| — | TestFlight (compte développeur payant) | ⏳ quand d'autres testeuses seront nécessaires |

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
│   ├── RootView.swift                TabView Journal / Envie / Recherche ; AppServices + providers ; badge DEBUG
│   ├── AppServices.swift             repositories + use cases composés une fois sur le contexte (+ detailsProviders, connectivity), injectés par initializer
│   └── ModelContainerFactory.swift   production() / onDisk(url:) / inMemory() — toujours avec le plan de migration
├── Data/
│   ├── Network/
│   │   ├── NetworkMonitor.swift      NWPathMonitor → isOnline (@Observable), implémente ConnectivityMonitoring
│   │   ├── SecretsProviding.swift    protocole + SecretKey (.tmdbReadToken) + SecretsError.missing (message = commande d'ajout)
│   │   ├── BundleSecrets.swift       lit Info.plist ; vide, blanc ou « $(…) » non résolu = manquant
│   │   ├── HTTPClient.swift          protocole get(url, headers) + HTTPError
│   │   └── URLSessionHTTPClient.swift  timeout 8 s, non-2xx → HTTPError.status
│   ├── Providers/
│   │   ├── ProviderRegistry.swift    live(secrets:client:appVersion:) = [TMDB, OpenLibrary] ; detailsProviders ; userAgent(appVersion:)
│   │   ├── TMDBProvider.swift        search/multi fr-FR|en-US, Bearer, garde movie + tv, clés tmdb:movie:<id> / tmdb:tv:<id>, affiches w342 ; details(forKey:) → movie/{id}+credits, tv/{id}
│   │   ├── TMDBSearchResponse.swift  DTO Decodable (snake_case) + TMDBMovieDetailsResponse / TMDBTVDetailsResponse
│   │   ├── OpenLibraryProvider.swift search.json, User-Agent « Kulturstack/<v> (+repo) », clés ol:work:<id> + isbn13:<…> (max 20), couverture -M, BookDetails
│   │   └── OpenLibrarySearchResponse.swift  DTO
│   └── Repositories/
│       ├── SwiftDataLogRepository.swift  fetchAll (date desc, createdAt desc) · find(id:) · save() · delete(_:)
│       └── SwiftDataMediaRepository.swift  findItem(withAnyKey:) via #Predicate sur ExternalRef.key ; find(itemID:) ; add item + refs ; add refs ; add log ; save ; deleteAll (objet par objet)
├── Features/
│   ├── Journal/
│   │   ├── JournalView.swift         ⚙︎ → Réglages ; 5 rendus : chargement · vide (EmptyState) · erreur (EmptyState + Réessayer) · edge (chips conservés + « Voir tout ») · liste groupée par jour ; segments « Semaine · n » + chips « Films · n » ; tap → feuille d'édition ; appui long → Voir la fiche / Supprimer (confirmation)
│   │   ├── JournalViewModel.swift    @Observable ; state = loading | empty | loaded([JournalRowModel]) | failed ; period (défaut semaine) + selectedKind → presentation (… | edge | loaded(JournalContent)) ; kindCounts ; showAll() ; delete(id:) ; now / calendar injectables
│   │   ├── JournalContent.swift      sections par jour + total ; KindCount
│   │   ├── JournalDaySection.swift   id = début du jour, titre (Aujourd'hui / Hier / date), rows
│   │   ├── JournalRowModel.swift     instantané VALEUR d'un log (itemID, kind, titre, sous-titre, date, statut, note, jaquette)
│   │   └── JournalRow.swift          jaquette + titre + « Type · année ou auteur » + date + pastille statut + étoiles
│   ├── Search/
│   │   ├── SearchView.swift          .searchable + focus à l'ouverture ; bandeau hors-ligne (safeAreaInset) ; 4 rendus ; ligne = NavigationLink → fiche (mode candidat) ; ♡ → envie, + → log ; Toast « Modifier » → feuille ; pastilles rafraîchies sur didSave
│   │   ├── SearchViewModel.swift     query (didSet → debounce 300 ms), sections, selectedKind, presentation ; log(candidate) → logNow injecté + pastille + toast 4 s ; wish(candidate) → toast ; lastLogDate injecté → row(for:) ; refreshLogDates()
│   │   ├── SearchResultRowModel.swift  instantané valeur d'un candidat (titre, « Type · année · créateur », jaquette, lastLoggedAt, loggedLabel)
│   │   ├── SearchResultRow.swift     MediaRow avec pastille « Vu le … » + boutons ♡ et + (borderless) en accessoire
│   │   └── KindChips.swift           « Tous » + un chip par type des familles enregistrées
│   ├── LogEdit/
│   │   ├── LogEditView.swift         feuille : titre « Dune (2021) » (lien vers la fiche), date + raccourcis, StarRatingPicker, statut segmenté, commentaire, supprimer ; 4 rendus (chargement · formulaire · introuvable · erreur)
│   │   ├── LogEditViewModel.swift    load() → champs éditables + itemID ; save() / delete() → Bool + didFail ; allowedStatuses du type
│   │   ├── DateShortcut.swift        today · yesterday · weekend (samedi le plus récent), heure conservée
│   │   └── LogReference.swift        l'id qu'une vue garde pour ouvrir la feuille (jamais le @Model)
│   ├── Settings/
│   │   ├── SettingsView.swift        Langue (suit le système + lien Réglages iOS) · Confidentialité · À propos · Tout effacer (double confirmation) · section DEBUG
│   │   ├── SettingsViewModel.swift   wipeAll() → Bool + didFailToWipe ; versionLine
│   │   ├── PrivacyView.swift         « Ce qui sort de ton iPhone » / « Ce qui reste chez toi » (TDD 07)
│   │   └── AboutView.swift           version + build, tagline, logo TMDB (SVG) + mention obligatoire, OpenLibrary
│   ├── Wishlist/
│   │   ├── WishlistView.swift        onglet Envie : liste des envies en attente, vide « Rien en attente » + Chercher, erreur ; tap → feuille ; appui long → fiche / supprimer
│   │   ├── WishlistViewModel.swift   state = loading | empty | loaded([JournalRowModel]) | failed ; markSeen(id:) = logAgain(item) ; delete(id:)
│   │   └── WishRow.swift             jaquette + titre + sous-titre + « Ajouté le … » + bouton « Je l'ai vu / lu / écouté »
│   ├── ItemDetail/
│   │   ├── ItemDetailView.swift      jaquette 120, titre (année), headline, faits, résumé repliable (« Plus »), « Logger » / « Logger à nouveau » (haptique) + « Envie » ♡, TES LOGS (tap → feuille), source ; 4 rendus (chargement · fiche · introuvable · erreur)
│   │   ├── ItemDetailViewModel.swift Subject = stored(id) | candidate ; load() (candidat déjà en base → fiche réelle ; enrichissement TMDB si la poche est vide) / log() / wish() ; state = loading | loaded | missing | failed
│   │   ├── ItemDetailModel.swift     instantané valeur, init(item:) ou init(candidate:) : headline « Type · 2h35 · créateur », facts par type (genres / saisons · épisodes / pages · éditeur · sujets), logs triés, source (TMDB, OpenLibrary, IMDb, Trakt)
│   │   ├── ItemLogRowModel.swift     instantané valeur d'un log de la fiche
│   │   ├── ItemLogRow.swift          date + pastille statut + étoiles + chevron + commentaire (2 lignes)
│   │   └── ItemReference.swift       l'id qu'une vue garde pour ouvrir la fiche
│   └── Shared/
│       ├── MediaKind+Presentation.swift   label, pluralLabel, symbole SF, loggedLabel(on:) « Vu le / Lu le / … », seenActionLabel « Je l'ai vu / lu / … »
│       ├── Period+Presentation.swift      label (Semaine…) + phrase (« cette semaine », « ce mois-ci »…)
│       ├── LogStatus+Presentation.swift   label localisé par statut
│       └── SearchFamily+Presentation.swift  label localisé par famille
├── Debug/                            compilé hors Release
│   ├── DemoSeed.swift                fill() = wipe() puis 23 fiches / 25 logs sur 12 mois ; wipe() = WipeUseCase
│   ├── DebugSection.swift            section de Réglages : « Remplir données démo » / « Tout effacer (démo) » / « Test recherche TMDB » + badge « Base V1 · n fiches · n logs »
│   └── DebugSearchView.swift         champ + sections par famille (5 lignes max) + interrupteur « Simuler une panne OpenLibrary » + Réessayer ; sans test (outil jetable)
├── Domain/
│   ├── Models/
│   │   ├── MediaKind.swift           9 types ; hasEpisodes, hasDuration, allowedStatuses, searchFamily
│   │   ├── Period.swift              week · month · year · all ; range(containing:calendar:) semaine du lundi, [début, fin)
│   │   ├── LogStatus.swift           wishlist · inProgress · done · dropped
│   │   ├── MediaItem.swift           la fiche : champs communs + detailsData (poche) ; relations externalRefs / logs
│   │   ├── ExternalRef.swift         clé unique "provider:value"
│   │   └── LogEntry.swift            fabrique make() qui valide statut et note ; date = .now par défaut
│   ├── Details/
│   │   ├── DetailsPayload.swift      FilmDetails · SeriesDetails · BookDetails · GenericDetails (tolérants)
│   │   └── DetailsCodec.swift        encode / decode(kind:) ; currentVersion = 1
│   ├── Repositories/                 PROTOCOLES (les impls SwiftData sont dans Data/)
│   │   ├── LogRepository.swift       fetchAll() · find(id:) · save() · delete(_:)
│   │   └── MediaRepository.swift     findItem(withAnyKey:) · find(itemID:) · add(item, refs:) · add(refs, to:) · add(log) · save()
│   ├── Rules/
│   │   ├── LogRules.swift            validate(status:for:) · validate(rating:)
│   │   └── DomainError.swift
│   ├── Network/
│   │   └── ConnectivityMonitoring.swift  protocole @Observable : isOnline
│   ├── Search/
│   │   ├── MetadataProvider.swift    protocole : id, supportedKinds, search(_:)
│   │   ├── DetailsProvider.swift     protocole : details(forKey:) → MediaEnrichment? (créateurs + poche) ; nil = pas ma clé
│   │   ├── MediaCandidate.swift      résultat de recherche ; identité = clé externe principale
│   │   └── SearchSection.swift       famille + SectionState (loading · loaded · empty · failed(reason)) ; SearchError.timeout
│   ├── UseCases/
│   │   ├── StatsUseCase.swift        count (T-16 : des logs, pas des fiches, envies exclues) · filter(période, type) · groupByDay (Aujourd'hui, Hier, dates) · pendingWishes (envie sans consommation postérieure)
│   │   ├── WipeUseCase.swift         wipe() = repository.deleteAll() — droit à l'effacement (TDD 07)
│   │   ├── EnrichUseCase.swift       needsEnrichment(item) ; enrich(item) → Bool, meilleur effort, garde les créateurs existants
│   │   ├── EditLogUseCase.swift      log(id:) · update(date, status, rating, note) validé par LogRules, commentaire blanc → nil · delete
│   │   ├── LogHistoryUseCase.swift   lastLogDate(for: candidate) = date du dernier log non-envie de la fiche partageant une clé
│   │   ├── SearchUseCase.swift       search(_:) → AsyncStream<SearchSection> : loading pour chaque famille, puis TaskGroup, timeout 8 s par provider, annulation propagée ; retry(_:family:)
│   │   ├── DedupUseCase.swift        existingItem(for: candidate) = fiche partageant AU MOINS une clé externe (ADR-004)
│   │   └── LogUseCase.swift          logNow(candidate, status: .done) : valide le statut, retrouve ou crée la fiche (+ poche encodée + refs), ajoute les clés manquantes, crée le log source « manual » ; logAgain(item) ; wish(candidate) / wish(item)
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
    ├── Localizable.xcstrings         ~170 clés FR + EN (3 pluriels)
    ├── PrivacyInfo.xcprivacy         aucune donnée collectée
    └── Assets.xcassets               AccentColor, AppIcon (« K » provisoire), TMDBLogo (SVG)
```

**Pas encore là** : Import / Export (T3). Filtrage du Journal en mémoire après `fetchAll()` — à passer en `#Predicate` si l'import T3 amène des milliers de logs.

**Écart au TDD 01** : les *protocoles* de repositories sont dans `Domain/Repositories/` (pas `Data/`) pour que `Domain/UseCases/` n'importe rien de `Data/`. Les implémentations SwiftData restent dans `Data/`.

**Règle apprise en PR 2** : une vue ne garde jamais un `@Model` en main — le ViewModel expose des instantanés valeur (`JournalRowModel`), et une feuille s'ouvre sur un `LogReference` (un id). Sinon, supprimer l'objet pendant que la liste l'affiche fait planter l'app (vu au premier « Tout effacer »).

## 4. Tests — 195, tous verts

| Fichier | Tests | Couvre |
|---|---|---|
| `SmokeTests` | 2 | `EmptyState` garde son contenu ; FR et EN existent |
| `MediaKindTests` | 4 (paramétrés : 9 cas) | statuts par type, épisodes, familles de recherche |
| `LogRulesTests` | 7 (paramétrés : 11 cas) | **T-02** statut interdit, **T-03** note hors plage, **T-06** date = maintenant, fabrique refuse un statut interdit |
| `DetailsCodecTests` | 5 | round-trip, **T-15** champs manquants → défauts, `{}` → défauts, décodage par type, `MediaItem.details` |
| `SchemaMigrationTests` | 3 | **T-01** store V1 rouvert avec le plan → données intactes ; schéma courant = dernier du plan ; clé `ExternalRef` unique |
| `DemoSeedTests` | 3 | **T-14** fill × 2 = mêmes comptes ; wipe → 0 ; logs dans les 12 derniers mois, avec notes et commentaires |
| `SwiftDataLogRepositoryTests` | 2 | tri du plus récent au plus ancien ; base vide → liste vide |
| `LogHistoryUseCaseTests` | 3 | jamais loggé → nil ; le plus récent gagne ; une envie ne compte pas |
| `ItemDetailModelTests` | 8 (paramétrés : 11 cas) | aperçu d'un candidat sans log, source du provider ; headline film (type · 2h35 · réalisateur) + genres ; film sans détails ; saisons · épisodes ; pages · éditeur · 3 sujets max ; logs du plus récent au plus ancien ; source TMDB / OpenLibrary / « TMDB, IMDb » / nil |
| `ItemDetailViewModelTests` | 10 | ♡ sur un candidat → fiche + log envie ; ♡ sur une fiche → log envie ; un film sans détails est enrichi à l'ouverture ; chargé ; introuvable ; erreur ; logger à nouveau ; candidat pas en base → aperçu sans rien écrire ; candidat déjà en base → sa fiche et ses logs ; logger un candidat deux fois → 1 fiche, 2 logs |
| `ItemDetailViewRenderingTests` | 1 | la fiche se rend en fiche, en aperçu et en « introuvable » |
| `SearchResultRowModelTests` | 2 (paramétrés : 10 cas) | chaque type a une pastille avec la date ; pas de date → pas de pastille |
| `EditLogUseCaseTests` | 6 | find par id ; update persiste date / statut / note / commentaire trimé ; blanc → nil ; statut interdit refusé ; note hors plage refusée ; delete garde la fiche |
| `PeriodTests` | 5 (paramétrés : 7 cas) | semaine du lundi au dimanche quelle que soit la locale ; mois et année entiers ; tout = sans bornes ; dimanche 23:59:59 dedans, lundi 00:00 dehors ; labels |
| `StatsUseCaseTests` | 5 | **T-16** un film revu compte 2, par période et par type ; envies ni comptées ni listées ; envie vue après → plus en attente, vue avant → reste ; filter période × type du plus récent ; groupement Aujourd'hui / Hier / dates |
| `WipeUseCaseTests` | 2 | tout effacer → 0 fiche, 0 log, 0 ref ; base vide OK |
| `SettingsViewModelTests` | 3 | wipe réussi ; échec signalé ; ligne de version |
| `SettingsViewRenderingTests` | 2 (paramétrés : 7 cas) | Réglages, Confidentialité, À propos se rendent ; 6 textes existent en FR **et** EN, différents |
| `OfflineBannerTests` | 1 | hors ligne → isOffline, retour en ligne → plus |
| `WishlistViewModelTests` | 5 | liste les envies seules ; aucune → vide ; « Je l'ai vu » ajoute un log terminé, l'envie reste dans l'historique et sort de la liste ; supprimer ; erreur |
| `WishlistViewRenderingTests` | 1 | l'onglet se rend en liste (seed : 2 envies) et en vide |
| `JournalFilterTests` | 7 | envies hors du journal et des compteurs ; que des envies = journal vide ; ouvre sur la semaine, groupé par jour, chips avec compteurs (0 compris) ; période × type ; filtre sans résultat = edge (chips conservés) puis Voir tout ; aucun log = vide quel que soit le filtre ; erreur reste erreur |
| `JournalViewRenderingTests` | 1 | l'écran se rend en liste groupée (seed : 25 logs) et en edge |
| `JournalViewModelTests` | 8 | loading au départ ; vide ; chargé ; erreur ; reprise après erreur ; **l'état survit à la suppression des logs** (régression du crash) ; delete(id:) recharge ; échec de suppression signalé |
| `LogEditViewModelTests` | 9 | load remplit le formulaire (+ itemID) ; titre sans année ; statuts du type (film, livre) ; introuvable ; erreur de lecture ; save écrit ; save invalide → didFail sans rien changer ; delete ; raccourci de date |
| `LogEditViewRenderingTests` | 2 | la feuille se rend en formulaire et en « introuvable » ; le picker se rend pour chaque note |
| `DateShortcutTests` | 4 (paramétrés : 8 cas) | aujourd'hui = maintenant ; hier garde l'heure ; « ce week-end » = samedi le plus récent (mer., lun., dim., sam., ven.) ; labels |
| `StarRatingPickerTests` | 3 (paramétrés : 6 cas) | tap = valeur ; re-tap = sans note ; étoile × moitié → 1…10 |
| `JournalRowModelTests` | 4 | livre → auteur, film → année, repli, champs recopiés |
| `JournalRowRenderingTests` | 1 | la ligne se rend avec et sans note (UIHostingController) |
| `MediaKindPresentationTests` | 4 (paramétrés : 19 cas) | chaque type (singulier, pluriel, « Je l'ai vu / lu… »), statut et famille a un label, FR et EN |
| `StarRatingTests` | 1 (paramétré : 6 cas) | 1…10 → étoiles pleines / demi |
| `SecretsTests` | 5 (paramétrés : 7 cas) | **T-13** manquant → message avec la commande ; blanc / « $(…) » = manquant ; valeur trimée ; bundle sans clé ; `MockSecrets` |
| `URLSessionHTTPClientTests` | 3 | en-têtes + timeout 8 s + GET (via `StubURLProtocol`) ; 401 → `HTTPError.status` ; panne réseau propagée |
| `TMDBProviderTests` | 10 (paramétrés : 13 cas) | **T-10** fixture réelle → 8 films + 5 séries, personnes ignorées ; film et série détaillés ; ordre conservé ; URL + langue + Bearer ; secret manquant → aucun appel réseau ; 401 et JSON cassé → erreur ; langue selon la locale |
| `MediaCandidateTests` | 1 | identité = clé externe |
| `OpenLibraryProviderTests` | 5 | **T-11** fixture réelle → 20 livres, `ol:work:` + `isbn13:` (13 chiffres, max 20) ; `BookDetails` ; **T-12** User-Agent + requête ; 503 propagé ; livres seulement |
| `ProviderRegistryTests` | 2 | live = [tmdb, openlibrary], familles [écran, livres], detailsProviders = [TMDB] ; User-Agent nomme l'app et un contact |
| `TMDBDetailsTests` | 5 (paramétrés : 8 cas) | fixture film → 2h35, genres, réalisateur ; fixture série → 2 saisons, 14 épisodes, statut, genres, créateurs ; URL movie/{id} + credits + langue + Bearer ; clés d'une autre forme → nil sans requête ; secret manquant → erreur sans requête |
| `EnrichUseCaseTests` | 5 (paramétrés : 10 cas) | remplit créateurs + poche et enregistre ; créateurs existants gardés ; panne → rien ne change ; clé inconnue → sauté ; needsEnrichment par type |
| `SearchViewModelTests` | 15 | ♡ → wish + toast portant l'id, pas de pastille ; ligne déjà loggée → « Vu le … », refreshLogDates la met à jour ; + → logNow + pastille + toast (portant l'id du log) qui s'efface, échec → toast d'erreur sans id ; idle sous 2 caractères ; une section par famille ; **debounce → un seul appel avec la dernière saisie** ; effacer → idle ; filtre par type (candidats filtrés, familles étrangères masquées) ; filtre sans résultat = edge ; rien nulle part = aucun résultat ; section en erreur visible à côté des résultats ; retry ciblé ; chips = types des familles ; sous-titre |
| `SearchViewRenderingTests` | 2 | l'écran traverse ses 4 rendus dans une UIWindow ; chips, en-tête et ligne se rendent |
| `LogUseCaseTests` | 10 | envie puis vu = 2 logs sur 1 fiche ; envie sur une fiche existante ; logAgain = log done maintenant sur la même fiche ; find(itemID:) ; premier log = fiche + refs + poche + log done/manual/maintenant ; **T-04** deux fois le même candidat → 1 fiche, 2 logs ; **T-05** clé partagée → même fiche, clés nouvelles ajoutées ; œuvres différentes → fiches différentes ; Envie accepté, statut interdit refusé ; `findItem(withAnyKey:)` |
| `SearchUseCaseTests` | 8 | loading pour chaque famille puis settle ; **T-07** panne isolée ; **T-09** le rapide n'attend pas le lent ; **T-08** annulation → providers annulés, rien de périmé ; timeout → failed ; vide → empty ; retry n'appelle que la famille ; ordre canonique des familles |

Couverture : `Domain/` 96 %, `Data/` 97 %, `Features/` 87 %, `DesignSystem/` 86 %. Fixtures réelles : `tmdb-search-multi-dune.json`, `openlibrary-search-dune.json` (21/09/2026), `tmdb-movie-dune.json` (réduite), `tmdb-tv-dune-prophecy.json` (22/09/2026). Réseau stubbé par `StubURLProtocol` (suite `.serialized`) ou `StubHTTPClient` ; providers simulés par `MockProvider` (délai, erreur, trace d'annulation). Cibles (≥ 70 % Domain et Data, ≥ 50 % Features) tenues.

Tests du plan pas encore écrits : T-17 (conversion des notes, T3).

## 5. Infrastructure

| | État |
|---|---|
| Repo | `ukyapps/kulturstack`, public, `main` par défaut |
| Protection de `main` | ruleset `protect-main` : PR obligatoire, check `test` requis, pas de bypass, pas de force-push, pas de suppression |
| CI | `tests.yml` : macos-26, Xcode 26.3, `make test`, ~5 min. **Vert.** |
| Review | **locale**, par Claude, avant chaque push (CLAUDE.md § Review locale). Plus de review en CI (ADR-012). |
| Secrets GitHub | aucun |
| Signature | équipe personnelle gratuite (app valable 7 jours, `make device` pour réinstaller) ; `DEVELOPMENT_TEAM` dans le Trousseau, jamais dans le dépôt |
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

**Founder** : réserver les domaines · utiliser l'app quelques jours et noter les retours · (optionnel) désinstaller l'app GitHub « Claude » · recherche INPI avant le store · avant toute monétisation, demander l'accord commercial TMDB.

**Prochaine session** : recueillir les **retours d'usage réel** (l'app tourne sur l'iPhone de la founder depuis le 23/09) et les écrire dans `retours-utilisateurs.md`. `make device` réinstalle en une commande quand la signature personnelle expire (7 jours). Ensuite seulement : `docs/plans/tranche-2.md` (épisodes), ou TestFlight si d'autres testeuses sont nécessaires.

**Questions produit ouvertes** (PRD §9, design §6) : musique écoutée vs possédée ; Envie en chip. **Tranché le 22/09** : journal groupé par jour (#13). **Tranché le 22/09** : tap Journal = édition ; tap Recherche = fiche, + = loggé.
