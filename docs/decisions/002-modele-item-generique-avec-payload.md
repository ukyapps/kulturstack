# ADR-002 — Un seul `MediaItem` + poche de détails Codable par type

- Statut : **accepted**
- Date : 2026-09-20

## Contexte

Neuf types de contenu (film, série, livre, disque, podcast, jeu, concert, théâtre, expo), chacun avec des champs propres. Promesse du cadrage : ajouter un type = 1 case d'enum + 1 adaptateur, zéro refactor de schéma.

## Options

1. Un `@Model` unique avec toutes les colonnes optionnelles.
2. Un `@Model` par type + protocole commun.
3. **Un `@Model` unique avec champs communs + `detailsData: Data` Codable typé par `kind`.**
4. Enum Swift à valeurs associées — SwiftData ne la stocke pas nativement ; revient à la 3 en moins contrôlé.

## Décision

**Option 3.** Les champs spécifiques ne sont **jamais interrogés** (on filtre par type, date, statut, note — tous communs). Ils servent à afficher. Ils peuvent donc vivre dans une poche opaque, versionnée (`detailsVersion`).

Exception assumée : `Season` / `Episode` (T2) sont de vrais modèles, parce qu'on les interroge (progression, prochain épisode).

## Conséquences

- Ajouter un type = case dans `MediaKind` + struct `XxxDetails` + `MetadataProvider`. Pas de migration.
- Les écrans validés (par période, par type, où j'en suis) n'utilisent que les champs communs — vérifié.
- Tous les champs des poches sont optionnels ou avec défaut ; test T-15.
- Écartée : option 2, car chaque `LogEntry` devrait pointer vers N types et chaque écran gérer N cas.
