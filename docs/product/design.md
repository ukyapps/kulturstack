---
type: design
statut: v1.1 — 2026-09-21 — Journal et Recherche réalisés et validés à l'écran ; Fiche, Modifier, Envie, Réglages à faire
propriétaire: founder
---

# Kulturstack — Design document (expérience et interface)

Ce document décrit **comment l'app se présente et se manipule**. Le *quoi* est dans le PRD, le *comment technique* dans `docs/tdd/`. L'ergonomie fine se valide à l'écran, maquette par maquette, en Tranche 1 — chaque écran ci-dessous porte un encadré **Réalisé** qui dit ce qui est dans l'app et ce qui manque encore.

## 0. Où en est l'interface (21/09/2026)

| Écran | État | PR |
|---|---|---|
| Barre d'onglets Journal / Recherche | ✅ | #7 |
| Journal — liste, état vide (+ CTA Chercher), état d'erreur, edge | ✅ groupé par jour, segments période, chips par type, compteurs | #4, #7, #13 |
| Recherche — barre, sections, chips, trois vides, section en erreur | ✅ · ⏳ bandeau hors-ligne (PR 11), ♡ Envie (PR 10) | #7, #10 |
| Tap = fiche · + = loggé + bandeau « Modifier » | ✅ (décision du 22/09) | #8, #9, #11 |
| Fiche d'une œuvre | ✅ | #10, #11, #12 |
| Modifier un log | ✅ | #9 |
| Envie — onglet, ♡ sur un résultat et dans la fiche, « Je l'ai vu » | ✅ (onglet, pas chip : décision du 22/09) | #14 |
| Réglages, Confidentialité, À propos, Tout effacer | ✅ | #15 |

Les captures d'écran de chaque PR sont dans `docs/captures/pr-NN/`.

## 1. Les trois idées qui guident tout

**1. Le résultat est le bouton.**
Dans la recherche, taper sur une œuvre la logge. Pas d'écran intermédiaire, pas de « confirmer ». Un bandeau discret dit « Loggé ✓ — Modifier » pendant quelques secondes, et c'est là qu'on corrige si besoin.

**2. Un seul endroit pour entrer, trois pour regarder.**
Une barre de recherche pour tout ajouter. Puis le journal (chronologique), le « où j'en suis » (en cours), et la bibliothèque (ce qu'on possède) pour regarder.

**3. Chaque écran a trois visages.**
Vide (rien encore — un écran conçu, avec une invitation), erreur (ça n'a pas chargé — avec « réessayer »), edge (filtre sans résultat — « aucun livre ce mois-ci »). Jamais un blanc, jamais une ligne grise.

## 2. Architecture de l'information

```
Kulturstack
├── Journal            ← onglet 1, écran d'accueil
│   ├── filtre période : Semaine · Mois · Année · Tout
│   ├── filtre type    : chips (Films · Séries · Livres · …)
│   ├── Envie          (T1)  — un filtre spécial, pas un onglet
│   ├── Où j'en suis   (T2)  — idem
│   └── → Fiche d'une œuvre → Modifier un log
├── Recherche          ← onglet 2, ou bouton flottant « + » (à trancher, voir §6)
│   ├── sections par famille : Films & séries · Livres · Disques · Podcasts · Jeux · Live
│   ├── chips de filtre après la saisie
│   └── « Aucun résultat ? Ajouter à la main » (T7)
├── Bibliothèque       ← onglet 3 (T5)
│   ├── par format : Vinyles · CD · Livres · DVD · …
│   └── scan code-barres
└── Réglages           ← onglet 4 (ou dans le profil)
    ├── Import / Export (T3)
    ├── Tout effacer
    ├── Confidentialité
    └── À propos (attributions)
```

**En Tranche 1** : deux onglets, Journal et Recherche (✅ depuis la PR #7), plus Réglages accessible depuis une icône en haut du Journal (PR 11). La Bibliothèque n'apparaît qu'en T5 — on n'affiche pas un onglet vide pendant quatre tranches.

## 3. Les écrans de la Tranche 1

### 3.1 Journal (accueil)

```
┌─────────────────────────────────┐
│ Kulturstack                  ⚙︎ │
│                                 │
│ [Semaine] Mois  Année  Tout     │  ← segments, compteur dans le segment actif : « Semaine · 4 »
│ (Tous) Films Séries Livres      │  ← chips, chacune avec son compteur
│                                 │
│ Aujourd'hui                     │
│ ▣ Dune : deuxième partie   ★★★★½│
│   Film · 2024                   │
│ ▣ Le Messie de Dune             │
│   Livre · Frank Herbert         │
│                                 │
│ Hier                            │
│ ▣ Severance S1                  │
│   Série · 2022               ★★★│
│                                 │
├─────────────────────────────────┤
│   Journal          Recherche    │
└─────────────────────────────────┘
```

> **Réalisé (PR #4, #7, #8)** : liste du plus récent au plus ancien, ligne = jaquette + titre + « Type · année » (films, séries) ou « Type · auteur » (livres) + date + pastille de statut si ≠ terminé + demi-étoiles ; état vide avec bouton « Chercher » qui bascule d'onglet ; état d'erreur avec « Réessayer » ; rechargement automatique après un log ; tap → feuille d'édition, appui long → Voir la fiche / Supprimer (PR #9, #10) ; segments Semaine · Mois · Année · Tout avec compteur dans l'actif, chips par type avec compteur, groupé par jour, edge « Pas de livres cette semaine » + Voir tout (#13).

- Groupé par jour (Aujourd'hui, Hier, puis dates). Ligne = jaquette, titre, type · année ou créateur, étoiles si notées.
- **Vide** : icône livres, « Ton journal est vide », « Cherche un film, une série ou un livre et tape dessus : c'est loggé. », bouton « Chercher ».
- **Edge** : « Aucun livre cette semaine » + « Voir tout ».
- **Erreur** : « Impossible de charger ton journal » + « Réessayer ».
- ~~Tap sur une ligne → Fiche de l'œuvre. Appui long → Modifier le log / Supprimer.~~ **Tranché le 22/09 (§6.6)** : tap → feuille d'édition ; appui long → Voir la fiche / Supprimer.

### 3.2 Recherche

```
┌─────────────────────────────────┐
│ 🔍 dune                       ✕ │
│ (Tous) Films Séries Livres      │
│                                 │
│ FILMS & SÉRIES                  │
│ ▣ Dune (2021)                   │
│   Denis Villeneuve              │
│ ▣ Dune (1984)                   │
│   David Lynch                   │
│ ▣ Dune : Prophecy (série, 2024) │
│                                 │
│ LIVRES                    ◌     │  ← spinner de section pendant qu'OpenLibrary répond
│                                 │
└─────────────────────────────────┘
```

> **Réalisé (PR #7, #8)** : onglet Recherche, barre avec focus et clavier levé, 2 caractères, debounce 300 ms, sections Films & séries / Livres à états indépendants (spinner dans l'en-tête, résultats, « Aucun résultat », « Livres indisponibles · Réessayer »), chips Tous · Films · Séries · Livres côté client, vide initial « Tape un titre », « Aucun résultat pour “xyz” », edge « Rien dans ce type · Tout voir », **tap = loggé** avec bandeau 4 s et bouton « Modifier » (#9). Ligne = jaquette + titre + « Type · année · créateur ». « Vu le 20 sept. » / « Lu le … » sur une ligne déjà loggée (#10) ; tap = fiche, + = loggé (#11), ♡ = envie (#14). Bandeau hors-ligne (#15). **Manque** : « Ajouter à la main » (T7).

- La barre a le focus dès l'ouverture, clavier levé. Recherche à partir de 2 caractères, 300 ms après la dernière frappe.
- **Tap = fiche de l'œuvre** (aperçu si pas encore en base, avec « Logger »). **« + » au bout de la ligne = loggé** (terminé, maintenant) avec bandeau « *Dune* loggé ✓ · **Modifier** » 4 s. Tranché le 22/09 (§6.2), réalisé en #11.
- **Appui long** (ou icône ♡ en bout de ligne) = Envie.
- Si l'œuvre a déjà été loggée : la ligne l'indique (« Vu le 12 mars ») et le tap logge **quand même** — c'est un revisionnage. On ne bloque jamais.
- **Vide initial** : « Tape un titre » avec trois suggestions de ce qu'on peut chercher.
- **Vide après saisie** : « Aucun résultat pour “xyz” » — et en T7 : « Ajouter à la main ».
- **Section en erreur** : « Livres indisponibles · Réessayer » — les autres sections restent.
- **Hors ligne** : bandeau « Pas de connexion — la recherche a besoin du réseau. Ton journal reste consultable. »

### 3.3 Fiche d'une œuvre

```
┌─────────────────────────────────┐
│ ‹                               │
│        ┌─────────┐              │
│        │ jaquette│              │
│        └─────────┘              │
│   Dune (2021)                   │
│   Film · 2h35 · Denis Villeneuve│
│   Science-fiction               │
│                                 │
│   Résumé (3 lignes, « plus »)   │
│                                 │
│   [ Logger à nouveau ]  [ ♡ ]   │
│                                 │
│   TES LOGS                      │
│   12 sept. 2026     ★★★★½   ›   │
│   3 mars 2024       ★★★★    ›   │
│                                 │
│   Source : TMDB                 │
└─────────────────────────────────┘
```

> **Réalisé (PR #10)** : jaquette, « Dune (2021) », « Film · 2h35 · réalisateur » (quand la poche les a), genres / saisons · épisodes / pages · éditeur · sujets selon le type, résumé sur 3 lignes avec « Plus », « Logger à nouveau », TES LOGS (date, statut, étoiles, commentaire ; tap → feuille), « Source : TMDB ». États introuvable et erreur. Ouverte par le titre de la feuille d'édition ou par appui long dans le Journal. Depuis la Recherche : tap sur un résultat, aperçu avec « Logger » s'il n'est pas encore en base (#11). Réalisateur, durée, genres, saisons complétés chez TMDB à l'ouverture (#12) ; bouton « Envie » ♡ à côté de « Logger » (#14).

- Les détails de la « poche » varient par type : durée / réalisateur pour un film, saisons pour une série, pages / éditeur pour un livre.
- Tap sur un log → Modifier.

### 3.4 Modifier un log (feuille)

> **Réalisé (PR #9)** : feuille Annuler / Log / Enregistrer, titre « Dune (2021) », date avec raccourcis Aujourd'hui · Hier · Ce week-end, demi-étoiles cliquables (re-tap = sans note), statut segmenté limité au type, commentaire, « Supprimer ce log » avec confirmation ; états « ce log n'existe plus » et erreur de lecture. Ouverte par « Modifier » sur le bandeau de la Recherche et par appui long dans le Journal (Modifier / Supprimer).

```
┌─────────────────────────────────┐
│ Annuler       Log       Enregistrer
│                                 │
│ Dune (2021)                     │
│                                 │
│ Date      12 sept. 2026, 21:40 ›│
│ Note      ☆☆☆☆☆  (demi-étoiles) │
│ Statut    (Vu)  Envie           │  ← seulement les statuts permis pour le type
│ Commentaire                     │
│ ┌─────────────────────────────┐ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│           Supprimer ce log      │
└─────────────────────────────────┘
```

- La date s'ouvre sur un sélecteur avec raccourcis « Aujourd'hui · Hier · Ce week-end ».
- Un film ne propose jamais « En cours ». Une série le proposera en T2.
- Supprimer demande confirmation.

### 3.5 Envie

> **Réalisé (PR #14)** — **en onglet**, pas en chip (founder, 22/09 : « je veux pas d'un chip envie dans le journal, il faut faire un 3ᵉ onglet »). Onglets : Journal · Envie · Recherche.

~~Un filtre du Journal (chip « Envie »), pas un écran à part.~~ Un onglet « Envie » : liste des envies **en attente** (pas encore consommées). Ligne = jaquette, titre, « Ajouté le … », bouton « Je l'ai vu » (« Je l'ai lu » pour un livre, « Je l'ai écouté » pour un disque) qui crée un log terminé daté maintenant. L'envie reste dans l'historique de la fiche mais sort de la liste. Les envies ne comptent pas dans le Journal ni ses compteurs.

On garde en envie par **♡ à côté du + sur chaque résultat** de Recherche, ou par « Envie » dans la fiche.

**Vide** : « Rien en attente », « Tape sur ♡ à côté d'un résultat de recherche, ou dans sa fiche, pour le garder pour plus tard. » + bouton Chercher. **Erreur** : « Impossible de charger tes envies » + Réessayer.

### 3.6 Réglages

> **Réalisé (PR #15)** : ⚙︎ dans la barre du Journal → Langue (suit le système, lien vers les Réglages iOS), Confidentialité, À propos (version, logo TMDB + mention, OpenLibrary), Tout effacer (double confirmation), section DEBUG hors Release avec le badge de base. Import / Export attend T3. Bandeau hors-ligne dans la Recherche.

Liste simple : Langue (suit le système), Import / Export (T3, masqué avant), **Tout effacer** (rouge, double confirmation), Confidentialité (deux paragraphes), À propos (version, attributions TMDB avec logo, OpenLibrary). En DEBUG uniquement : « Remplir données démo » / « Tout effacer (démo) » et le badge « Base V1 · n fiches · n logs ».

## 4. Les écrans des tranches suivantes (esquisse)

| Tranche | Écran | L'idée en une ligne |
|---|---|---|
| 2 | **Où j'en suis** | Chip du Journal. Cartes « Severance · S2 E4 sur 10 · *Prochain : E5* » avec un bouton ✓ qui coche l'épisode suivant. Livres en cours avec « terminé » en un tap. |
| 2 | **Saisons / épisodes** | Sur la fiche d'une série : liste des saisons dépliables, cases à cocher par épisode, « tout cocher jusqu'ici ». |
| 3 | **Import** | Choisir un fichier → aperçu « 312 films, 48 séries, 0 doublon » → importer → file « À confirmer » (titre + année, 2-3 candidats, « c'est celui-là » / « ignorer »). |
| 5 | **Bibliothèque** | Onglet. Grille de jaquettes par format, onglets Vinyles · CD · Livres · DVD. Bouton scan en haut : viseur plein écran, bip, fiche pré-remplie avec « je le possède » coché. |
| 5 | **Ajouter** (revu) | Sur un résultat : deux cases « ☑ Je l'ai vu » « ☐ Je le possède » — la première cochée par défaut ; format demandé seulement si la seconde est cochée. |
| 7 | **Ajouter à la main** | Titre, type, lieu (autocomplétion), date, puis « compléter avec l'IA » qui propose résumé et image, à accepter ou non. |

## 5. Le design system

### 5.1 Ton et langage
- **Tutoiement**, phrases courtes, pas de jargon (« loggé » est le seul mot technique, et il est assumé — il est dans le pitch).
- Les messages d'état vide invitent, ils ne culpabilisent pas (« Rien en attente », pas « Vous n'avez rien ajouté »).
- FR et EN écrits en même temps ; l'EN est une traduction de ton, pas mot à mot.

### 5.2 Couleurs
- **Accent** : un rouge-orangé chaud (`#D94E34`, à affiner) — chaleureux, culturel, distinct des bleus d'app utilitaire. Sert aux boutons principaux, à la chip active, aux étoiles.
- **Fond / texte** : couleurs système (clair / sombre suivis automatiquement).
- **Une couleur par type** ? Non — un **badge textuel** (« Film », « Livre ») et une **icône SF Symbol** par type suffisent. La jaquette apporte déjà la couleur.

| Type | Icône |
|---|---|
| Film | `film` |
| Série | `tv` |
| Livre | `book` |
| Disque | `opticaldisc` |
| Podcast | `mic` |
| Jeu | `gamecontroller` |
| Concert | `music.mic` |
| Théâtre | `theatermasks` |
| Expo | `photo.artframe` |

### 5.3 Typographie et espacement
- Police système (SF), Dynamic Type respecté partout.
- Échelle d'espacement : 4 · 8 · 16 · 24 · 40 (`Spacing.xs … xl`). Rayons : 6 · 12.
- Jaquettes : ratio 2:3 (films, livres, séries), 1:1 (disques, podcasts), coins arrondis 6.

### 5.4 Composants
| Composant | Rôle | Tranche |
|---|---|---|
| `EmptyState` | icône + titre + message + CTA optionnel ; sert aux trois visages | 0 ✅ |
| `CoverThumbnail` | jaquette 2:3 avec placeholder par type | 1 ✅ (#4) |
| `MediaRow` | jaquette + titre + sous-titre + accessoire (étoiles, ♡, ✓) | 1 ✅ (#7) — utilisé par la Recherche ; le Journal a encore sa propre `JournalRow` |
| `KindBadge` | icône + libellé du type | 1 — remplacé par le libellé dans le sous-titre + l'icône du placeholder ; à créer seulement si un écran en a besoin |
| `StarRating` | demi-étoiles, interactif ou lecture seule | 1 ✅ lecture seule (#4) · ✅ `StarRatingPicker` (#9) |
| `SectionHeader` | titre de section + état (spinner / erreur + réessayer) | 1 ✅ titre + spinner (#7) ; l'erreur est une ligne de section |
| `Toast` | bandeau « Loggé ✓ · Modifier » | 1 ✅ (#8, #9) |
| `Chip` / `KindChips` | chips de filtre par type | 1 ✅ Recherche (#7) · ⏳ Journal avec compteurs (PR 9) |
| `PeriodSegments` | segments Semaine · Mois · Année · Tout avec compteurs | 1 ⏳ (PR 9) |
| `EpisodeCheckbox` | case + « prochain » | 2 |
| `BarcodeScanner` | viseur | 5 |

### 5.5 Accessibilité
- Tout composant a un label VoiceOver ; les étoiles annoncent « 4 étoiles et demie sur 5 ».
- Cibles tactiles ≥ 44 pt ; le « tap = loggé » a une alternative explicite (bouton « Logger ») pour les technologies d'assistance.
- Contraste AA sur l'accent ; pas d'information portée par la couleur seule.
- Réduction des animations respectée (le toast apparaît sans glissement).

## 6. Questions d'ergonomie à trancher (avec la founder, à l'écran)

1. ~~**Recherche = onglet ou bouton « + » flottant sur le Journal ?**~~ **Tranché le 21/09/2026 : onglet** (founder). On reverra si le « + » s'impose à l'usage.
2. ~~**Le tap logge immédiatement ou après un court délai annulable ?**~~ Tranché le 21/09/2026 : immédiat + bandeau. **Retranché le 22/09/2026 après usage : tap sur un résultat = fiche de l'œuvre, on logge depuis la fiche** (founder : « dans la recherche, je peux pas accéder à la fiche avant de logger un truc, c'est pas logique »). Claude a proposé un bouton ⓘ ou un appui long pour garder le tap = loggé ; la founder a préféré la fiche. Puis, pendant la démo de la PR 8b, la founder a demandé **un « + » au bout de chaque ligne** pour logger en un geste : tap = fiche, + = loggé + bandeau « Modifier ». Réalisé en #11.
6. ~~**Tap sur une ligne du Journal : fiche ou édition ?**~~ **Tranché le 22/09/2026 : édition directe** (founder) ; la fiche par le titre de la feuille ou par appui long.
3. ~~**Groupement du Journal par jour ou liste plate ?**~~ **Tranché le 22/09/2026 : par jour** (#13), après la démo de la PR 7 où un log passé à hier avait « disparu » en bas de liste.
4. **Étoiles sur la ligne du Journal ou seulement sur la fiche ?** Reco : sur la ligne, discrètes, à droite.
5. ~~**Envie : chip du Journal ou onglet ?**~~ **Tranché le 22/09/2026 : onglet** (founder), contre la reco chip. Trois onglets Journal · Envie · Recherche ; la Bibliothèque (T5) devra trouver sa place.

## 7. Ce qu'on ne fait pas en design

- Pas d'onboarding en plusieurs écrans : le premier écran vide *est* l'onboarding.
- Pas de thème personnalisé, pas d'icône alternative.
- Pas d'animations décoratives ; les seules transitions sont celles du système.
- Pas de gamification (streaks, badges) — le journal n'est pas une injonction.
