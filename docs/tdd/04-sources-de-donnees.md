---
type: tdd
statut: accepté
créé: 2026-09-20
vérifié: 2026-09-19 (remplace le tableau du 2026-07-04)
---

# 04 — Sources de données

À re-vérifier avant chaque tranche qui branche une source.

## Par type de contenu

| Type | Source | Clé ? | Secrète ? | Sans serveur ? | Rate limit | Tranche | Import du passé |
|---|---|---|---|---|---|---|---|
| Films / séries | **TMDB** | oui | non (faible valeur, ADR-001) | ✅ | généreux (~50 req/s) | 1 | Trakt ZIP JSON, CSV IMDb / Letterboxd (T3) |
| Livres | **OpenLibrary** | **aucune** | — | ✅ | 1 req/s anonyme, 3 req/s avec User-Agent + email ; pannes de 30-45 min récurrentes | 1 | CSV Goodreads (T3) |
| Disques | **Discogs** | optionnelle | non | ✅ | 25 req/min sans clé, 60 avec | 4 | Export CSV ou API de la collection Discogs (T5) |
| Podcasts | **Apple Podcasts** (iTunes Search) + RSS | aucune | — | ✅ | ~20 req/min | 4 | aucun (Apple n'exporte rien) |
| Jeux | **IGDB** | oui (Twitch) | **oui** — `client_secret` | ❌ proxy | 4 req/s, 8 en vol | 6 | CSV manuel |
| Concerts | **Setlist.fm** | oui | oui (clé « test » au départ, upgrade sur demande) | ❌ proxy | 16 req/s, 50 000/jour | 6 | aucun |
| Théâtre | saisie assistée : autocomplétion lieu (open data IdF / France) + OpenAgenda + LLM | OpenAgenda : clé non secrète | LLM : oui | ❌ proxy (LLM) | — | 7 | aucun |
| Expos | saisie assistée : Muséofile (lieux) + OpenAgenda / Que faire à Paris + LLM | idem | idem | ❌ proxy (LLM) | — | 7 | aucun |

## Ce qui a changé depuis le 2026-07-04

- **Trakt** : depuis début août 2026, créer une application API exige un compte VIP (4,99 $/mois) côté développeur ; des apps existantes ont été supprimées. → **ADR-009 : import par le ZIP JSON** (gratuit, `Settings → Data → Export now`), l'OAuth devient optionnel.
- **OpenLibrary** : rate limit et pannes récurrentes documentés → états d'erreur par section (ADR-005).
- **Setlist.fm** : clé initiale explicitement « à usage de test » → demander l'upgrade avant T6.
- **theatre-contemporain.net** (API ouverte, licence Etalab) a fusionné avec ARTCENA en 2026 ; le devenir de l'API est inconnu (`ressources-theatre.net/doc/api`). À vérifier à la main avant T7.
- **Les Archives du spectacle** (179 000 spectacles, la meilleure base FR) : pas d'API publique connue. Contact : contact@lesarchivesduspectacle.net — à faire avant T7, ça changerait tout pour le théâtre.

## Sources écartées et pourquoi

| Source | Raison |
|---|---|
| Goodreads API | fermée depuis 2020 |
| IMDb API | pas d'API publique gratuite |
| Allociné, L'Officiel des spectacles, BilletReduc | aucune API ; scraping fragile et juridiquement glissant |
| Songkick | API fermée aux nouvelles apps |
| Google Books | gardé en **secours** d'OpenLibrary (meilleures couvertures), pas en T1 |
| RAWG (jeux) | alternative sans proxy à IGDB si on veut les jeux avant T6 ; base moins soignée |
| MusicBrainz | alternative sans clé à Discogs ; moins bon sur les éditions physiques |
| Paris Musées API | décrit les œuvres, pas les expositions |

## Obligations

- **TMDB** : attribution « This product uses the TMDB API but is not endorsed or certified by TMDB » + logo, dans À propos. Usage non commercial uniquement (app gratuite sans pub = OK ; à renégocier si monétisation).
- **OpenLibrary** : `User-Agent` identifiant l'app + email de contact.
- **Setlist.fm** : non commercial ; attribution.
- **Discogs** : `User-Agent` obligatoire.
