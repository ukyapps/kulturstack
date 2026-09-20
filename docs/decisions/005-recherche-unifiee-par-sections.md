# ADR-005 — Une seule barre de recherche, sections par type, états indépendants

- Statut : **accepted**
- Date : 2026-09-20

## Contexte

« Sans friction » est le cœur du produit. Deux formes possibles : choisir le type avant de taper (Trakt), ou une barre unique qui interroge tout (TV Time).

## Décision

- **Une barre unique**, tous les providers interrogés en parallèle.
- Résultats en **sections par famille** (Films & séries / Livres / Disques / Podcasts / …), **pas de classement fusionné** — un ranking inter-sources est un puits sans fond.
- **Chaque section a son propre état** (chargement / résultats / vide / erreur + réessayer). TMDB (~0,2 s) s'affiche sans attendre OpenLibrary (1-2 s, pannes fréquentes).
- Filtres par type **après** la saisie, optionnels, côté client.
- Le résultat est le bouton : tap = loggé, daté maintenant, bandeau « Loggé ✓ — modifier ». Correction après, jamais confirmation avant.
- Pour les types sans base (théâtre, expos, T7) : la même barre propose « Ajouter à la main » en bas.

## Conséquences

- Signature `MetadataProvider.search(_:) async throws -> [MediaCandidate]` + `SearchUseCase` en `AsyncStream<SearchSection>`.
- Ajouter une source (T4, T6) = une section apparaît, l'utilisatrice ne réapprend rien.
- Tests T-07 à T-09.
