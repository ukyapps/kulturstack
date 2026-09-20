# ADR-011 — Ordre des tranches (révision du 2026-09-20)

- Statut : **accepted**
- Date : 2026-09-20
- Remplace : la séquence en 7 tranches du cadrage de juillet

## Contexte

Ajout des disques, podcasts (sans serveur, faciles) et de la collection. Trakt passe en import fichier (ADR-009). Le proxy n'est plus nécessaire avant les jeux/concerts.

## Décision

| # | Tranche | Ce qui ship | Serveur ? |
|---|---|---|---|
| **1** | **Le log magique** | modèle + SwiftData V1 · recherche TMDB + OpenLibrary · log 1 tap (défaut = maintenant, éditable) · notation · envie · journal par période (semaine / mois / année) et par type · empty-first + seed DEBUG. Séries au niveau série. | non |
| 2 | Épisodes | saisons / épisodes (séries **et** podcasts, même structure), progression, « où j'en suis », statuts en cours / abandonné | non |
| 3 | Import du passé | Trakt ZIP JSON, CSV Goodreads / IMDb / Letterboxd / générique, file « à confirmer », **export JSON complet** (portabilité RGPD) | non |
| 4 | Disques + Podcasts | Discogs, Apple Podcasts + RSS, deux sections de plus dans la recherche | non |
| 5 | Collection | `OwnedCopy`, formats, import collection Discogs, scan code-barres ISBN / EAN, vue « Ma bibliothèque » | non |
| 6 | Jeux + Concerts | IGDB, Setlist.fm — **proxy Supabase introduit ici**, TMDB migre derrière | **oui** |
| 7 | Théâtre / Expos + IA | saisie assistée (lieux open data, OpenAgenda), enrichissement LLM, puis recos IA + export Obsidian | oui |
| 8 | Social *(nice-to-have)* | comptes, partage avec une proche, recos croisées, sync | le gros backend |

## Estimation honnête

- T1 : **4 à 6 semaines part-time** (pas 2-4) — ce n'est pas la feature qui coûte, c'est l'infrastructure de qualité posée une fois (XcodeGen, TDD 70 %, migration plan, empty states, CI review, bilinguisme). Levier si besoin : sortir « envie » et les stats de T1.
- Vision complète : 4 à 6 mois part-time, social exclu.
