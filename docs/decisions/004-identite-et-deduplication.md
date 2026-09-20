# ADR-004 — Identité par clés externes, dédup par intersection, fiche au niveau de l'œuvre

- Statut : **accepted**
- Date : 2026-09-20

## Contexte

La même œuvre arrive par la recherche (T1), l'export Trakt (T3), un CSV Letterboxd/Goodreads/IMDb (T3), la collection Discogs (T5). Sans règle : doublons et stats fausses. La règle se joue dans la forme du modèle → à poser en T1.

## Décision

1. Clé primaire = `UUID` local. Une fiche saisie à la main (théâtre) n'a pas d'identifiant externe et doit exister quand même.
2. `ExternalRef` = modèle séparé, `key` unique au format `<provider>:<value>` (`tmdb:movie:438631`, `imdb:tt1160419`, `ol:work:OL893415W`, `isbn13:…`, `discogs:master:…`). Plusieurs par fiche.
3. **Deux candidats sont la même œuvre dès qu'ils partagent au moins une clé externe.** Les sources se citent (Trakt → TMDB + IMDb ; Goodreads → ISBN), ce qui rend la jointure fiable.
4. **Livres : identité au niveau du work** (OpenLibrary `OL…W`), pas de l'édition. L'ISBN est une clé secondaire qui aide à retrouver le work.
5. **Disques : identité au niveau du master Discogs** ; le pressage précis (`release`) est porté par `OwnedCopy` (ADR-010).
6. Sans clé (Letterboxd) : recherche titre normalisé + année → un seul candidat évident → lier ; sinon file **« À confirmer »**. Jamais de fusion silencieuse ambiguë.
7. Métadonnées : on garde la plus riche. **Les logs ne fusionnent pas** (un log = un événement), sauf même fiche + même jour civil + même source → doublon d'import.

## Conséquences

- `DedupUseCase` posé en T1 (test T-04, T-05), réutilisé tel quel par `ImportResolver` en T3.
- `.unique` sur `ExternalRef.key` → iOS 18 (ADR-007).
