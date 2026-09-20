# ADR-003 — `VersionedSchema` + `SchemaMigrationPlan` dès la première PR

- Statut : **accepted**
- Date : 2026-09-20

## Contexte

T1 ship les séries au niveau série ; T2 ajoute saisons/épisodes ; T5 ajoute les possessions. Sans plan de migration, chaque évolution efface la base (dev) ou perd les données (prod).

## Décision

- `KulturstackSchemaV1: VersionedSchema` nommé dans la PR 1, même seul.
- `KulturstackMigrationPlan: SchemaMigrationPlan` avec stages vides ; le `ModelContainer` est **toujours** construit avec ce plan.
- Test T-01 : un store V1 rouvert avec le plan courant conserve ses données. Tourne à chaque PR.
- Règle de repo : **toute modification d'un `@Model` = nouveau `SchemaVN` + stage** (lightweight quand possible, custom sinon). Pas d'exception.

## Conséquences

- Une demi-journée en PR 1, zéro ensuite.
- T2 (ajout de modèles + relation optionnelle) = migration lightweight.
- Dépend de la fiabilité de SwiftData → argument pour iOS 18 (ADR-007).
