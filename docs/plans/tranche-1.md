---
type: plan
tranche: 1 — Le log magique
statut: prêt à exécuter
créé: 2026-09-20
---

# Plan Tranche 1 — Le log magique

**Objectif** : à la fin, l'app permet de chercher un film, une série ou un livre, de le logger en un tap (daté maintenant, modifiable), de le noter, de le mettre en « envie », et de regarder son journal par semaine / mois / année et par type. Base vide au premier lancement, seed derrière un bouton DEBUG.

**Hors périmètre T1** (ne pas y toucher, même « vite fait ») : épisodes, import, disques, podcasts, possessions, « en cours », iPad, widgets, sync, analytics.

**Règles du plan**
- 1 PR = 1 branche = 1 jour max = **quelque chose de visible à l'écran** à la fin.
- Chaque PR : tests d'abord (rouge → vert), strings dans `Localizable.xcstrings` FR + EN, captures état vide / rempli dans la description.
- Merge quand `test` est vert en CI et que la review locale (CLAUDE.md) est PASS, collée dans la PR.
- Si une PR déborde d'une journée : la couper, pas la forcer.

**Estimation** : 12 PRs ≈ 12 jours de travail → **4 à 6 semaines part-time**.

---

## PR 0 — Bootstrap `chore/bootstrap`

**Livre** : le projet compile, l'app se lance sur simulateur et affiche « Kulturstack » avec un `EmptyState` placeholder. Le repo est « prêt » au sens des 3 étapes.

- `project.yml` (XcodeGen) : cible `Kulturstack` + `KulturstackTests`, iOS 18.0, `bundleIdPrefix: com.ukyapps`, `developmentLanguage: fr`, `TARGETED_DEVICE_FAMILY: "1"`, `configFiles` → `Config/Secrets.xcconfig`, `Info.plist` avec `TMDBReadToken = $(TMDB_READ_TOKEN)`.
- `Makefile` : `generate`, `secrets`, `build`, `test SIM="iPhone 16 Pro"`, `coverage`.
- `scripts/secrets.sh` (env d'abord, sinon Trousseau, sinon message avec la commande d'ajout).
- `.gitignore` (xcodeproj, `Config/Secrets.xcconfig`, DerivedData), hook pre-commit anti-secret.
- `Localizable.xcstrings` FR + EN avec la première string.
- `PrivacyInfo.xcprivacy`.
- `DesignSystem/` : tokens (couleurs, espacements, typo), `EmptyState` (icône + titre + message + CTA optionnel).
- `CLAUDE.md`, `docs/` (déjà écrits), `README.md`.
- ~~`.github/workflows/claude-review.yml`~~ — mis en place puis **retiré le 2026-09-20** (ADR-012) : remplacé par la review locale.
- Ruleset `main` exigeant le check `test` (repo public → gratuit).

**Démo** : `make generate && make build`, app lancée, écran avec `EmptyState`. **Tests** : 1 test trivial qui prouve que la cible de test tourne.

**Fait le 2026-09-20 (#1).**

## PR 1 — Schéma V1 et plan de migration `feat/schema-v1`

**Livre** : `MediaItem`, `ExternalRef`, `LogEntry`, `MediaKind`, `LogStatus`, `KulturstackSchemaV1`, `KulturstackMigrationPlan`, `ModelContainer` de prod et in-memory de test.

- Tests : **T-01** (migration), T-02 (statut interdit), T-03 (rating), T-06 (date par défaut), T-15 (poche avec champ manquant).
- Règles métier dans `Domain/` : `allowedStatuses`, validation rating, `DetailsCodec`.

**Démo** : le placeholder affiche un badge DEBUG « Base V1 · 0 fiches · 0 logs ». (Peu spectaculaire, assumé : ce sont les fondations, voir ADR-003.)

**Fait le 2026-09-20 (#2) — 21 tests, Domain 81-100 %.**

## PR 2 — Journal vide + seed DEBUG `feat/journal-empty-and-seed`

**Livre** : l'écran Journal (liste des logs, tri date desc, ligne = jaquette + titre + type + date + ★) avec son `EmptyState` ; menu DEBUG « Remplir données démo » / « Tout effacer », compilé hors Release.

- Tests : **T-14** (seed idempotent, wipe → 0), `LogRepository.fetchAll` trié.
- Seed : ~15 fiches réalistes (films, séries, livres) avec jaquettes TMDB/OL en dur, ~25 logs répartis sur 12 mois, quelques notes.

**Démo** : état vide → tap « Remplir » → journal rempli → « Tout effacer » → vide. Captures des deux.

## PR 3 — Secrets + client TMDB `feat/tmdb-provider`

**Livre** : `SecretsProviding` + `BundleSecrets` + `MockSecrets` ; `HTTPClient` ; `TMDBProvider.search` (films + séries) avec fixture réelle.

- Tests : **T-10**, **T-13**, décodage `FilmDetails` / `SeriesDetails`, clés `tmdb:movie:` / `tmdb:tv:`, timeout.
- Fixture : `tmdb-search-multi-dune.json` capturée avec la vraie API.

**Démo** : écran DEBUG « Test recherche » avec un champ et une liste brute de résultats TMDB (titre, année, type). Suffit à prouver que la clé et le client marchent.

## PR 4 — OpenLibrary + recherche unifiée `feat/unified-search`

**Livre** : `OpenLibraryProvider` ; `SearchUseCase` (debounce, annulation, TaskGroup, `AsyncStream<SearchSection>`) ; `ProviderRegistry`.

- Tests : **T-07**, **T-08**, **T-09**, **T-11**, **T-12**.
- Fixture : `openlibrary-search-dune.json`.

**Démo** : le champ DEBUG affiche maintenant deux sections avec états indépendants. Simuler une panne OL (mock) → section Livres en erreur avec « Réessayer », Films intacts.

## PR 5 — Écran Recherche `feat/search-screen`

**Livre** : le vrai écran Recherche du design system : barre, sections, ligne de résultat (jaquette, titre, année, créateurs, badge type), trois états par section, chips de filtre par type (client-side), `EmptyState` « Tape un titre » et « Aucun résultat pour … ».

- Tests : `SearchViewModel` (filtres, mapping des états) ≥ 50 %.

**Démo** : captures état initial / résultats / section en erreur / filtre actif.

## PR 6 — Le log en 1 tap `feat/one-tap-log`

**Livre** : `DedupUseCase` + `LogUseCase.logNow(candidate)` ; tap sur un résultat → fiche créée ou retrouvée, log `done` daté maintenant ; bandeau « Loggé ✓ — Modifier » (4 s) ; le journal se met à jour.

- Tests : **T-04**, **T-05**, création des `ExternalRef`, poche encodée, `source == "manual"`.

**Démo** : chercher « dune », tap, bandeau, retour au journal, l'entrée est là. Re-tap → 1 fiche, 2 logs (visible dans le badge DEBUG).

## PR 7 — Modifier un log `feat/log-edit`

**Livre** : feuille d'édition : date (picker, défaut = maintenant), `StarRating` demi-étoiles (composant design system), statut limité à `allowedStatuses` du type, note texte, supprimer (avec confirmation).

- Tests : `LogEditViewModel` (statuts proposés par type, validation, sauvegarde), `StarRating` mapping 1…10 ↔ ★.

**Démo** : depuis le bandeau « Modifier » et depuis le journal ; un film ne propose pas « en cours ».

## PR 8 — Fiche d'une œuvre `feat/item-detail`

**Livre** : écran détail : jaquette, titre, année, créateurs, résumé, détails de la poche selon le type (durée / saisons / pages), liste de tous les logs de la fiche, bouton « Logger à nouveau ».

- Tests : `ItemDetailViewModel` (décodage de la poche par type, tri des logs).

**Démo** : fiche film, fiche livre, fiche avec 2 logs.

## PR 9 — Journal par période et par type `feat/journal-filters`

**Livre** : en tête du journal, segments « Semaine · Mois · Année · Tout » avec compteur de logs ; chips par type avec compteur ; trois rendus distincts : vide (rien loggé), edge (filtre sans résultat : « Aucun livre ce mois-ci »), erreur (chargement raté).

- Tests : **T-16**, `StatsUseCase` (bornes de période en heure locale, semaine commençant lundi), `JournalViewModel` filtres combinés.

**Démo** : seed → « 4 films et 2 livres ce mois-ci » ; filtre livre + semaine → état edge.

## PR 10 — Envie `feat/wishlist`

**Livre** : action secondaire sur un résultat (appui long ou bouton) « Envie » → log `wishlist` ; onglet ou filtre « Envie » dans le journal avec son `EmptyState` ; depuis une envie, « Je l'ai vu » crée un log `done` (l'envie est conservée, ADR-006).

- Tests : `LogUseCase.wish(candidate)`, transition envie → vu = 2 logs.

**Démo** : captures envie vide / rempli / transition.

## PR 11 — Réglages, À propos, Confidentialité, finitions `feat/settings-about`

**Livre** : écran Réglages : « Tout effacer » (Release, avec confirmation — distinct du DEBUG), À propos (version, attribution TMDB + logo, OpenLibrary), Confidentialité (les deux paragraphes de `07-rgpd.md`), langue suivie du système ; passe complète sur les traductions EN ; labels d'accessibilité ; icône placeholder.

- Tests : `WipeUseCase` (tout effacer = 0 fiche, 0 log, 0 ref).

**Démo** : captures FR et EN de chaque écran.

## Jalon — TestFlight (pas une PR)

Founder : compte développeur, archive, upload TestFlight, installation sur son iPhone. **Premier vrai lancement sur base vide** : vérifier l'onboarding réel, pas le seed.

---

## Ordre de dépendance

```
PR0 → PR1 → PR2 ─┐
            PR3 → PR4 → PR5 → PR6 → PR7
                                 └→ PR8
                          PR2 + PR6 → PR9 → PR10
                                            PR11
```

PR 2 et PR 3 peuvent se faire dans n'importe quel ordre après PR 1.

## Ce qu'on vérifie à la fin de T1 avant de dire « shippé »

**Vérifié le 2026-09-23 — la Tranche 1 est shippée.**

- [x] Premier lancement = base vide — l'app s'est ouverte sur un **Journal vide** sur l'iPhone, pas sur du seed. `EmptyState` sur chaque écran : Journal, Envie et Recherche vus sur l'appareil, les autres couverts par les tests de rendu.
- [x] Seed → wipe → seed : même nombre d'objets (**T-14**).
- [x] Coverage ≥ 70 % Domain, ≥ 50 % Features — 83 % sur l'ensemble de l'app.
- [x] Test **T-01** vert (et il devra le rester à la migration V2).
- [x] Panne OpenLibrary simulée : films toujours cherchables (interrupteur de l'écran DEBUG + test).
- [x] Aucune string en dur — `grep 'Text("' sans String(localized:)` = 0.
- [x] `Secrets.xcconfig` absent du dépôt, hook pre-commit actif.
- [x] Chaque PR porte sa fiche de review locale (CLAUDE.md).
- [x] `PrivacyInfo.xcprivacy` présent, attribution TMDB visible dans À propos.
- [x] Installé sur l'iPhone de la founder — **par câble** (Personal Team, `make device`), pas par TestFlight : décision du 22/09 de ne pas prendre de compte développeur payant tant qu'il n'y a qu'une testeuse. Signature valable 7 jours, à refaire vers le 30/09.

**Ce que la T1 a appris, une fois vécue** : les sept retours du 23/09 et leurs cinq PRs (#18 → #22) sont dans `docs/product/retours-utilisateurs.md` et résumés dans `docs/etat-du-projet.md` § 2. Le plus instructif : un filtre par défaut qui cache sans le dire coûte plus cher qu'il ne rapporte.
