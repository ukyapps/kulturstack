---
type: prd
statut: v1 — 2026-09-20
propriétaire: founder
---

# Kulturstack — PRD (Product Requirements Document)

## 1. En une phrase

Kulturstack est le journal de tout ce que tu consommes culturellement — séries, films, livres, disques, podcasts, jeux, concerts, théâtre, expos — et de tout ce que tu possèdes, en un seul endroit, **sans friction** : tu cherches, tu tapes, c'est loggé.

## 2. Le problème

Aujourd'hui la consommation culturelle d'une personne est éparpillée : Trakt pour les séries, Goodreads pour les livres, Discogs pour les vinyles, rien pour les concerts et les expos, et un fichier texte pour le reste. Chaque outil a sa friction — Trakt demande « quand l'as-tu vu ? » à chaque log, Goodreads n'a plus d'API, Discogs ne parle que de disques. Résultat : on ne logge pas, ou on logge en retard, et le journal ment.

Le besoin n'est pas un tracker de plus. C'est **un seul geste, pour tout, au moment où ça se passe**.

## 3. Pour qui

**Utilisatrice principale : la founder.** Consomme beaucoup, tous formats, veut un journal fidèle sans y passer du temps. Possède une bibliothèque physique (livres, vinyles, CD, DVD) qu'elle aimerait avoir en poche.

**Utilisatrices secondaires (distribuable)** : des personnes comme elle — curieuses, multi-formats, agacées par l'éparpillement. Pas de persona « collectionneur hardcore » ni « social first » : le produit est un journal perso avant tout.

**Contexte d'usage** : téléphone en main, sur le canapé après un épisode, dans le métro après un livre, à la sortie d'une salle. Dix secondes. Souvent hors connexion (métro, salle de concert).

## 4. Principes produit (non négociables)

1. **Log d'abord, range après.** La date par défaut est *maintenant*. On corrige après, jamais avant.
2. **Un geste, tous les formats.** Une seule barre de recherche, pas de choix de type avant de taper.
3. **Local-first.** Les données vivent sur le téléphone. Pas de compte pour commencer. Ça marche hors connexion (sauf la recherche de nouvelles œuvres).
4. **Le journal raconte, il n'écrase pas.** Un film revu = deux entrées. « Envie » puis « vu » = deux entrées.
5. **L'état vide est un écran, pas un vide.** Le premier lancement est conçu, pas subi.
6. **Rien ne sort du téléphone sans raison.** Pas d'analytics, pas de pub, pas de compte tant que le social n'existe pas.

## 5. Objectifs et mesures

| Objectif | Mesure | Horizon |
|---|---|---|
| Remplacer Trakt + Goodreads + notes pour la founder | Elle n'ouvre plus Trakt ni Goodreads ; 100 % des logs passent par Kulturstack | 3 mois après T1 |
| Sans friction | Un log = ≤ 3 gestes (ouvrir, taper, tap) ; ≤ 10 s | T1 |
| Journal fidèle | ≥ 80 % des logs faits le jour même | T2 |
| Historique récupéré | Trakt + Goodreads importés sans doublon visible | T3 |
| Distribuable | Sur TestFlight avec une proche ; puis App Store | fin T1 / après T5 |

**Ce qu'on ne mesure pas** : rétention, DAU, viralité. Ce n'est pas un produit de croissance.

## 6. Périmètre — ce que fait le produit

### 6.1 Types de contenu

| Type | Source | Granularité |
|---|---|---|
| Films | TMDB | l'œuvre |
| Séries | TMDB | l'épisode |
| Livres | OpenLibrary | l'œuvre |
| Disques | Discogs | l'album |
| Podcasts | Apple Podcasts + RSS | l'épisode |
| Jeux vidéo | IGDB | le jeu |
| Concerts | Setlist.fm | le concert |
| Théâtre | saisie assistée | la représentation |
| Expos | saisie assistée | la visite |

### 6.2 Fonctionnalités, par ordre de livraison

**Tranche 1 — Le log magique**
- Chercher une œuvre (films, séries, livres) dans une barre unique ; résultats par sections, chaque section avec son état.
- Logger en un tap : statut *terminé*, date = maintenant.
- Modifier un log : date, note (demi-étoiles / 5), statut, commentaire ; supprimer.
- Voir la fiche d'une œuvre : jaquette, infos, tous ses logs.
- Le journal : liste chronologique, filtrable par période (semaine / mois / année) et par type, avec compteurs.
- Envie : marquer une œuvre à voir / lire, la retrouver, la passer en « vu ».
- Réglages : tout effacer, à propos, confidentialité. FR + EN.

**Tranche 2 — Épisodes**
- Saisons et épisodes pour séries et podcasts ; cocher un épisode ; « prochain épisode ».
- « Où j'en suis » : tout ce qui est en cours (séries, livres, podcasts, jeux).
- Statuts *en cours* et *abandonné*.

**Tranche 3 — Le passé**
- Importer : Trakt (export JSON), Goodreads / IMDb / Letterboxd (CSV), CSV générique.
- Dédoublonner automatiquement ; file « à confirmer » pour les cas ambigus.
- Exporter tout son journal (JSON).

**Tranche 4 — Disques et podcasts**
- Deux sections de plus dans la recherche. Épisodes de podcasts via RSS.

**Tranche 5 — Ma bibliothèque**
- Marquer une œuvre comme possédée, avec son format (vinyle, CD, cassette, DVD, Blu-ray, poche, grand format, boîte).
- Scanner un code-barres (ISBN, EAN) pour ajouter un livre ou un disque en deux secondes.
- Importer sa collection Discogs.
- Vue « Ma bibliothèque » par format.

**Tranche 6 — Jeux et concerts**
- IGDB et Setlist.fm derrière un proxy. Premier serveur.

**Tranche 7 — Théâtre, expos, intelligence**
- Saisie assistée (lieu en autocomplétion, OpenAgenda), enrichissement IA (résumé, image).
- Recommandations (proche de ce que tu aimes **et** qui élargit), export vers Obsidian.

**Tranche 8 — Social (nice-to-have)**
- Comptes, partage avec une proche, recommandations croisées, comparaison de goûts, sync.

### 6.3 Ce que le produit ne fait pas (et ne fera pas avant longtemps)

- Streaming, lecture, achat : Kulturstack ne joue rien, ne vend rien.
- Découverte « à la Netflix » : pas de flux de nouveautés en T1-T6.
- Notation sociale, avis publics, followers.
- iPad, Android, web (le social pourrait un jour justifier un fork).
- Scraping de sites sans API (Allociné, L'Officiel des spectacles, BilletReduc).

## 7. Exigences non fonctionnelles

| | Exigence |
|---|---|
| Plateforme | iOS 18.0+, iPhone uniquement |
| Langues | Français (référence) + anglais, dès la première version |
| Hors ligne | Journal, fiches, modification : 100 % hors ligne. Recherche : nécessite le réseau, avec un message clair sinon. |
| Performance | Résultats TMDB affichés < 1 s ; une source lente ou en panne n'en bloque jamais une autre |
| Données | Local-first (SwiftData). Migration de schéma sans perte à chaque mise à jour. Aucune donnée personnelle envoyée à un tiers hors termes de recherche. |
| Vie privée | Étiquette App Store « Données non collectées ». Boutons *tout effacer* et *tout exporter*. |
| Qualité | TDD ; ≥ 70 % de couverture sur le domaine ; review automatique sur chaque changement ; `main` protégée. |
| Attribution | TMDB, OpenLibrary, Discogs, Setlist.fm crédités dans « À propos ». Usage non commercial. |

## 8. Risques

| Risque | Impact | Mitigation |
|---|---|---|
| Une source change ses conditions (cf. Trakt, août 2026) | perte d'une fonctionnalité | sources isolées derrière des protocoles ; import par fichier plutôt qu'API quand possible |
| OpenLibrary tombe souvent | recherche livres indisponible | états par section ; Google Books en secours (à brancher si ça devient gênant) |
| Théâtre / expos sans base propre | saisie manuelle = friction | saisie assistée + IA ; contact avec Les Archives du spectacle |
| Dispersion de la founder (deux produits) | T1 s'éternise | plan en PRs d'une journée, chaque PR démontrable ; time-box |
| Coût de l'IA si distribué | opex par utilisatrice | cache + quotas, ou IA en premium — décision à prendre en T7 |

## 9. Questions ouvertes

- Musique **écoutée** (par opposition aux disques possédés) : Kulturstack logge-t-il des écoutes d'albums ? Décision implicite aujourd'hui : oui, un disque se logge comme un film (« écouté »). À confirmer à l'usage en T4.
- Monétisation : rien de prévu. Si un jour : IA premium plutôt que pub (la pub casse le principe 6 et l'usage non commercial de TMDB).
- Nom de la feature sociale : « le Klub » ?

## 10. Documents liés

- Vision UX et écrans : `docs/product/design.md`
- Cadrage technique : `docs/tdd/`
- Décisions : `docs/decisions/`
- Plan courant : `docs/plans/tranche-1.md`
- Journal de bord : `docs/journal/`
