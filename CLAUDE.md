# Kulturstack — conventions du repo

Journal de consommation culturelle multi-média, sans friction, local-first, iOS. Lis ce fichier à chaque session. Les décisions sont dans `docs/decisions/`, le cadrage dans `docs/tdd/`, le plan courant dans `docs/plans/`.

> En CI, le reviewer n'a que `Read` / `Write` / `Grep` / `Glob` — pas de MCP, pas de daemon, pas de simulateur. Rien ici n'exige un autre outil.

## Identité

| | |
|---|---|
| Bundle id | `com.ukyapps.kulturstack` |
| iOS minimum | 18.0 — iPhone uniquement |
| Langues | français (référence) + anglais, `Localizable.xcstrings` |
| Service Trousseau | `kulturstack` |

## Stack

Swift 5.9+ · SwiftUI · MVVM + Repository · SwiftData (`VersionedSchema` + `SchemaMigrationPlan`, toujours) · `async/await` partout · Swift Testing.

**XcodeGen** : le `.xcodeproj` est généré depuis `project.yml`, jamais édité à la main.
```
make generate            # secrets + xcodegen
make build
make test SIM="iPhone 16 Pro"
make coverage
```

## Architecture (voir `docs/tdd/01-architecture.md`)

- `Domain/` ne dépend de rien. `Data/` dépend de `Domain`. `Features/` consomme les deux via protocoles injectés.
- Dossiers **par feature**, pas par couche : `Features/Journal/` contient ses Views + ViewModels + sous-modèles.
- 1 type principal par fichier, nom du fichier = nom du type.
- Injection **par initializer**. Zéro singleton.
- Sources externes uniquement derrière `MetadataProvider` / `HistoryImporter`.

## Modèle (voir `docs/tdd/02-modele-de-donnees.md`)

- `MediaItem` = l'œuvre, tous types. Champs communs interrogeables + poche `detailsData` Codable par type, jamais interrogée.
- `LogEntry` = je l'ai consommée. `OwnedCopy` (T5) = je la possède. Indépendants.
- `ExternalRef.key` unique, format `<provider>:<value>` → dédup.
- **Toute modification d'un `@Model` = nouveau `SchemaVN` + stage de migration.** Pas d'exception. Le test T-01 doit rester vert.
- Un statut doit appartenir à `kind.allowedStatuses`. `rating` ∈ 1…10.

## TDD strict

La founder ne relit pas le Swift en détail : **les tests sont le filet**. Pour chaque feature : écrire le(s) test(s) → vérifier qu'ils échouent → implémenter jusqu'au vert → commit. Cibles : **≥ 70 %** `Domain/` et `Data/`, **≥ 50 %** `Features/`. Aucun test n'appelle Internet (fixtures + `StubURLProtocol`). Les tests de secrets utilisent `MockSecrets`, jamais `BundleSecrets`.

## Prototype utilisable dès le jour 1 — non négociable

- **Jamais de seed au boot.** Premier lancement = base vide, réelle.
- Seed derrière un bouton DEBUG « Remplir données démo » / « Tout effacer », compilé hors Release, **idempotent** (remplir = wipe puis seed), testé.
- **Empty state conçu avec l'écran**, jamais après : `EmptyState` du design system (icône + titre + message + CTA optionnel). Pas un blanc, pas une ligne grise.
- Trois rendus distincts : **vide** (rien loggé) ≠ **erreur** (chargement raté) ≠ **edge** (filtre sans résultat).
- Avant « done » : captures de l'état vide **et** de l'état rempli dans la PR.

## Strings

**100 % via `Localizable.xcstrings`**, FR + EN dans la même PR. Jamais de texte UI en dur.

## Secrets (voir `docs/tdd/06-secrets.md`)

- **Jamais** dans le chat, un `.env`, un fichier versionné, un plist launchd.
- Trousseau → `make secrets` → `Config/Secrets.xcconfig` (gitignoré) → `Info.plist`. Env d'abord (`TMDB_READ_TOKEN`), trousseau sinon.
  ```bash
  security add-generic-password -s kulturstack -a TMDB_READ_TOKEN -w
  ```
- Un secret qui a transité en clair est à faire tourner.
- Clé TMDB embarquée = risque accepté (ADR-001). Proxy en T6.

## Git

- `main` protégée, **jamais** de commit direct. Branches `feat/` · `fix/` · `chore/`. 1 branche = 1 PR = 1 changement focalisé ; jamais réutiliser un nom de branche.
- Messages à l'infinitif, première ligne < 72 caractères, 1 commit = 1 changement logique.
- Merge sur verdict **PASS** de la review (zéro finding bloquant ; mineurs corrigés ou justifiés dans la PR). Le `/5` est indicatif — **ne pas chasser le 5/5**.
- Jamais de `--force`, `reset --hard` destructif, `--no-verify`, ni de secret committé.

## Code

- Zéro commentaire par défaut. Un commentaire explique un *pourquoi* non évident, jamais un *quoi*.
- `async/await`, pas de completion handlers.
- Pas de SDK d'analytics / crash / pub sans ADR (voir `docs/tdd/07-rgpd.md`).

## Poids du process

| Tâche | Process |
|---|---|
| Feature / bugfix | issue, TDD, coverage, PR, ADR si structurant |
| Docs / design / recherche | branche + PR pour la review du diff ; pas d'issue, pas de TDD |
| Chore / config | branche + PR, léger |

## Périmètre courant

Tranche 1 (`docs/plans/tranche-1.md`). **Hors périmètre** : épisodes, import, disques, podcasts, possessions, « en cours », iPad, widgets, sync. Si une PR déborde d'une journée, la couper.

## Contexte founder — à garder en tête

Retour de burn-out, recherche d'emploi en parallèle, deux produits iOS co-prioritaires (Mealkin + Kulturstack). Le risque identifié est la **dispersion**.

- Time-box les blocs ; pas de mélange Mealkin / Kulturstack dans une même session.
- **Pas d'urgence artificielle.** Rien ne se ferme en 90 jours.
- Après 22h ou si la founder exprime de la fatigue : suggérer d'arrêter.
- Si une tranche dépasse largement l'estimation : le dire franchement, ne pas rassurer.
- Red flags à nommer : session > 4h sans pause, « on s'en fout, on fait le truc rapide », raccourci sur les tests ou le RGPD.
- La founder n'est pas développeuse iOS : expliquer en langage simple, une question à la fois, avec une reco. Pas de listes de 8 questions d'un coup.
