---
type: design
statut: v1 — 2026-09-20 — propositions à valider avec la founder écran par écran
propriétaire: founder
---

# Kulturstack — Design document (expérience et interface)

Ce document décrit **comment l'app se présente et se manipule**. Le *quoi* est dans le PRD, le *comment technique* dans `docs/tdd/`. Tout ce qui suit est une proposition : l'ergonomie fine se valide à l'écran, maquette par maquette, en Tranche 1.

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

**En Tranche 1** : deux onglets, Journal et Recherche, plus Réglages accessible depuis une icône en haut du Journal. La Bibliothèque n'apparaît qu'en T5 — on n'affiche pas un onglet vide pendant quatre tranches.

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

- Groupé par jour (Aujourd'hui, Hier, puis dates). Ligne = jaquette, titre, type · année ou créateur, étoiles si notées.
- **Vide** : icône livres, « Ton journal est vide », « Cherche un film, une série ou un livre et tape dessus : c'est loggé. », bouton « Chercher ».
- **Edge** : « Aucun livre cette semaine » + « Voir tout ».
- **Erreur** : « Impossible de charger ton journal » + « Réessayer ».
- Tap sur une ligne → Fiche de l'œuvre. Appui long → Modifier le log / Supprimer.

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

- La barre a le focus dès l'ouverture, clavier levé. Recherche à partir de 2 caractères, 300 ms après la dernière frappe.
- **Tap = loggé** (statut terminé, maintenant). Bandeau en bas : « *Dune (2021)* loggé ✓ · **Modifier** » pendant 4 s.
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

- Les détails de la « poche » varient par type : durée / réalisateur pour un film, saisons pour une série, pages / éditeur pour un livre.
- Tap sur un log → Modifier.

### 3.4 Modifier un log (feuille)

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

Un filtre du Journal (chip « Envie »), pas un écran à part. Ligne = jaquette, titre, « ajouté le … », bouton « Je l'ai vu » qui crée un log terminé daté maintenant. L'envie reste dans l'historique.

**Vide** : « Rien en attente », « Appuie longtemps sur un résultat de recherche pour le garder pour plus tard. »

### 3.6 Réglages

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
| `MediaRow` | jaquette + titre + sous-titre + accessoire (étoiles, ♡, ✓) | 1 |
| `KindBadge` | icône + libellé du type | 1 |
| `StarRating` | demi-étoiles, interactif ou lecture seule | 1 |
| `SectionHeader` | titre de section + état (spinner / erreur + réessayer) | 1 |
| `Toast` | bandeau « Loggé ✓ · Modifier » | 1 |
| `PeriodSegments` / `KindChips` | filtres du Journal avec compteurs | 1 |
| `EpisodeCheckbox` | case + « prochain » | 2 |
| `BarcodeScanner` | viseur | 5 |

### 5.5 Accessibilité
- Tout composant a un label VoiceOver ; les étoiles annoncent « 4 étoiles et demie sur 5 ».
- Cibles tactiles ≥ 44 pt ; le « tap = loggé » a une alternative explicite (bouton « Logger ») pour les technologies d'assistance.
- Contraste AA sur l'accent ; pas d'information portée par la couleur seule.
- Réduction des animations respectée (le toast apparaît sans glissement).

## 6. Questions d'ergonomie à trancher (avec la founder, à l'écran)

1. ~~**Recherche = onglet ou bouton « + » flottant sur le Journal ?**~~ **Tranché le 21/09/2026 : onglet** (founder). On reverra si le « + » s'impose à l'usage.
2. **Le tap logge immédiatement ou après un court délai annulable ?** Reco : immédiat + toast « Modifier » — c'est le cœur du « sans friction » ; on mesure les erreurs à l'usage.
3. **Groupement du Journal par jour ou liste plate ?** Reco : par jour, ça rend les « cette semaine » lisibles.
4. **Étoiles sur la ligne du Journal ou seulement sur la fiche ?** Reco : sur la ligne, discrètes, à droite.
5. **Envie : chip du Journal ou onglet ?** Reco : chip (voir §3.5), pour ne pas multiplier les onglets avant la Bibliothèque.

## 7. Ce qu'on ne fait pas en design

- Pas d'onboarding en plusieurs écrans : le premier écran vide *est* l'onboarding.
- Pas de thème personnalisé, pas d'icône alternative.
- Pas d'animations décoratives ; les seules transitions sont celles du système.
- Pas de gamification (streaks, badges) — le journal n'est pas une injonction.
