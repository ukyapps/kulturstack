---
type: design
statut: v1.6 — 2026-09-28 — Tranches 1 et 2 livrées et vécues ; les huit retours du 27/09 intégrés (#38 → #45) ; tranche Podcasts en cours (#48 → #51) ; les questions 6 et 7 sont closes
propriétaire: founder
---

# Kulturstack — Design document (expérience et interface)

Ce document décrit **comment l'app se présente et se manipule**. Le *quoi* est dans le PRD, le *comment technique* dans `docs/tdd/`. L'ergonomie fine se valide à l'écran, maquette par maquette, en Tranche 1 — chaque écran ci-dessous porte un encadré **Réalisé** qui dit ce qui est dans l'app et ce qui manque encore.

## 0. Où en est l'interface (28/09/2026)

> **Tranches 1 et 2 livrées, tranche Podcasts en cours.** La barre compte quatre onglets — **Journal · Envie · En cours · Recherche** —, une série se suit épisode par épisode, et les podcasts entrent dans la Recherche. Chaque écran ci-dessous porte son encadré **Réalisé**.

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

**Après deux jours d'usage réel sur iPhone** (23/09) — sept retours, cinq PRs :

| Ce qui a bougé | Pourquoi | PR |
|---|---|---|
| Le Journal s'ouvre sur **Tout** ; segments Tout · Semaine · Mois · Année | Un log daté hors de la semaine avait l'air perdu | #18 |
| Tap sur une ligne = **la fiche** ; modifier passe à l'appui long (Journal et Envie) | Demande de la founder, retour au geste d'origine du design | #18 |
| La ligne montre **l'aperçu du commentaire** à la place de la date | La date est déjà l'en-tête du jour, juste au-dessus | #19 |
| Le sélecteur de date ne propose plus d'heure | « Pas l'heure, c'est un peu abusé » | #20 |
| « Logger » depuis la fiche **ouvre le formulaire** ; rien n'est écrit avant « Enregistrer » | Le 1-tap reste le `+` de la Recherche, pour aller vite | #20 |
| Chercher un réalisateur ou une actrice ramène **sa filmographie** | « wes anderson » ne donnait aucun de ses films | #21 |
| Le `+` sur une œuvre déjà loggée **demande confirmation** | Un deuxième log ne doit pas se faire par accident | #22 |

**Après trois jours d'usage des épisodes** (27/09) — huit retours, sept PRs. Elles ne changent pas ce que l'app fait : elles raccourcissent le chemin.

| Ce qui a bougé | Pourquoi | PR |
|---|---|---|
| **Toute la ligne** du Journal ouvre la fiche | Seuls la jaquette et le titre répondaient — la seule ligne des quatre écrans à ne pas déclarer sa zone tactile | #38 |
| « J'ai vu toute la saison » et « Jusqu'ici » deviennent des **boutons visibles** ; l'appui long disparaît | « Je ne l'avais pas trouvé » après trois jours — voir le principe 4 du § 1 | #39 |
| Les livres se cherchent dans leur **édition française** | `murakami kafka` rendait `海辺のカフカ` | #40 |
| La fiche d'une série s'ouvre sur **« Prochain épisode »**, cochable ; le `+` d'une série y mène au lieu de la logger d'un bloc | « Ça me met la série comme un film au lieu de m'afficher les épisodes » | #42 |
| Le ✓ **se voit et se sent** : barre de progression animée, bouton qui s'enfonce, retour haptique | « Si je misclick je m'en rends pas compte » | #43 |
| Le **prochain épisode dans le Journal** aussi, sur la ligne de statut d'une série en cours | « Comme dans en cours » | #44 |
| **« Je le commence »** sur une fiche de livre, série, podcast ou jeu | « Je peux pas dire en cours dans les boutons en haut » | #45 |

**Tranche Podcasts, en cours** (27 → 28/09) : schéma V3 — l'identité d'un épisode de podcast est le `guid` de son flux (#48) ; section **Podcasts** dans la Recherche, via Apple (#49) ; épisodes lus dans le **flux RSS** (#50) ; **vocabulaire propre aux podcasts** — liste à plat, « ÉPISODES », « J'ai tout écouté » (#51). Restent Radio France (Apple ne publie pas leurs flux) et les finitions du seed.

Les captures d'écran de chaque PR sont dans `docs/captures/`.

## 1. Les trois idées qui guident tout

**1. Le résultat est le bouton.**
Dans la recherche, taper sur une œuvre la logge. Pas d'écran intermédiaire, pas de « confirmer ». Un bandeau discret dit « Loggé ✓ — Modifier » pendant quelques secondes, et c'est là qu'on corrige si besoin.

**2. Un seul endroit pour entrer, trois pour regarder.**
Une barre de recherche pour tout ajouter. Puis le journal (chronologique), le « où j'en suis » (en cours), et la bibliothèque (ce qu'on possède) pour regarder.

**3. Chaque écran a trois visages.**
Vide (rien encore — un écran conçu, avec une invitation), erreur (ça n'a pas chargé — avec « réessayer »), edge (filtre sans résultat — « aucun livre ce mois-ci »). Jamais un blanc, jamais une ligne grise.

**4. Ce qui ne se voit pas n'existe pas.**
Ajouté le 27/09, après que l'usage a tranché **trois fois dans le même sens** : l'appui long « Envie » jamais trouvé (22/09), le bandeau « où j'en suis » refusé au profit d'un onglet (24/09), et « tout cocher jusqu'ici » caché derrière un appui long — réclamé comme une fonctionnalité manquante alors qu'il existait depuis trois jours (27/09). Une action qui compte a **une surface visible** : un bouton avec son libellé, un onglet. Le geste iOS (appui long, swipe) peut venir **en plus**, jamais seul. Visible ne veut pas dire partout : un bouton ne s'affiche que là où il sert — « Jusqu'ici » n'apparaît que s'il reste un épisode à combler derrière.

**5. Un geste qui écrit doit répondre.**
Cocher, avancer, commencer : la vue bouge (une barre se remplit, une carte avance), le bouton s'enfonce sous le doigt, et le téléphone vibre **au moment où c'est enregistré** — pas au moment du tap. Un geste raté ne vibre pas.

## 2. Architecture de l'information

```
Kulturstack
├── Journal            ← onglet 1, écran d'accueil
│   ├── filtre période : Tout · Semaine · Mois · Année
│   ├── filtre type    : chips (Films · Séries · Livres · …)
│   └── → Fiche d'une œuvre → Modifier un log
├── Envie              ← onglet 2 (T1) — un onglet, pas un chip (founder, 22/09)
├── En cours           ← onglet 3 (T2) — **livré #35**, place **confirmée à l'usage** le 27/09 (§ 6 q. 7)
├── Recherche          ← onglet 4 (tranché le 21/09 : onglet, pas de « + » flottant)
│   ├── sections par famille : Films & séries ✅ · Livres ✅ · **Podcasts ✅ (#49)** · Disques · Jeux · Live
│   ├── chips de filtre après la saisie
│   └── « Aucun résultat ? Ajouter à la main » (T7)
├── Bibliothèque       ← (T5) — place à retrouver : un cinquième onglet, c'est un de trop (§ 6 q. 9)
│   ├── par format : Vinyles · CD · Livres · DVD · …
│   └── scan code-barres
└── Réglages           ← depuis ⚙︎ en haut du Journal (#15), pas un onglet
    ├── Import / Export (T3)
    ├── Tout effacer
    ├── Confidentialité
    └── À propos (attributions)
```

**En Tranche 1** : trois onglets, Journal, Envie et Recherche (✅ #7, #14), plus Réglages depuis ⚙︎ en haut du Journal (✅ #15). **La Tranche 2** en a ajouté un quatrième, « En cours » (#35), en **troisième position** — confirmée par la founder le 27/09 : « oui c'est bien ». La barre ne bouge plus. La Bibliothèque n'apparaît qu'en T5 — on n'affiche pas un onglet vide pendant quatre tranches, et à ce moment-là il faudra reposer la question de la barre (§ 6 q. 9).

**Une famille de recherche n'apparaît que si une source la sert.** Les sections Disques, Jeux et Live sont dans l'arbre ci-dessus mais **pas à l'écran** : aucune source ne les alimente encore. La section Podcasts est apparue le 27/09 en même temps que sa source — rien à câbler dans l'écran.

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

> **Réalisé le 27/09 (#38, #44)** : **toute la ligne** ouvre la fiche, pas seulement la jaquette et le titre ; et la ligne d'une **série en cours** porte sa progression (« S2 · E4 sur 10 »), sa barre, « Prochain : E5 » et le **✓ qui coche la suite** sans quitter le Journal. Une seule ligne le fait — celle qui porte le statut de la série —, sinon la même série s'avancerait depuis trois endroits.
>
> **Réalisé (PR #4, #7, #8)** : liste du plus récent au plus ancien, ligne = jaquette + titre + « Type · année » (films, séries) ou « Type · auteur » (livres) + date + pastille de statut si ≠ terminé + demi-étoiles ; état vide avec bouton « Chercher » qui bascule d'onglet ; état d'erreur avec « Réessayer » ; rechargement automatique après un log ; tap → feuille d'édition, appui long → Voir la fiche / Supprimer (PR #9, #10) ; segments Semaine · Mois · Année · Tout avec compteur dans l'actif, chips par type avec compteur, groupé par jour, edge « Pas de livres cette semaine » + Voir tout (#13) ; **ouverture sur Tout, segments Tout · Semaine · Mois · Année, tap → la fiche de l'œuvre, appui long → Modifier / Supprimer (#18)** ; **l'aperçu du commentaire (2 lignes) remplace la date sur la ligne, qui est déjà l'en-tête de sa section (#19)**.

- Groupé par jour (Aujourd'hui, Hier, puis dates). Ligne = jaquette, titre, type · année ou créateur, étoiles si notées.
- **Vide** : icône livres, « Ton journal est vide », « Cherche un film, une série ou un livre et tape dessus : c'est loggé. », bouton « Chercher ».
- **Edge** : « Aucun livre cette semaine » + « Voir tout ».
- **Erreur** : « Impossible de charger ton journal » + « Réessayer ».
- ~~Tap sur une ligne → Fiche de l'œuvre. Appui long → Modifier le log / Supprimer.~~ ~~**Tranché le 22/09 (§6.6)** : tap → feuille d'édition ; appui long → Voir la fiche / Supprimer.~~ **Retranché le 23/09 après usage réel** : tap → la fiche de l'œuvre ; appui long → Modifier / Supprimer. Le geste d'origine, revenu par l'usage (#18).

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

> **Réalisé le 27/09 (#40, #42, #49)** : les **livres** se cherchent dans leur **édition française** — titre, couverture et nom d'auteur (`murakami kafka` → *Kafka sur le Rivage*, et non `海辺のカフカ`) ; un livre sans édition française reste trouvable. Une section **Podcasts** (Apple) ; le bouton d'une **série ou d'un podcast** n'est plus un `+` mais une **liste à cocher**, qui mène à ses épisodes au lieu de le logger d'un bloc. Le texte d'accueil et le placeholder parlent des podcasts.
>
> **Réalisé (PR #7, #8)** : onglet Recherche, barre avec focus et clavier levé, 2 caractères, debounce 300 ms, sections Films & séries / Livres à états indépendants (spinner dans l'en-tête, résultats, « Aucun résultat », « Livres indisponibles · Réessayer »), chips Tous · Films · Séries · Livres côté client, vide initial « Tape un titre », « Aucun résultat pour “xyz” », edge « Rien dans ce type · Tout voir », **tap = loggé** avec bandeau 4 s et bouton « Modifier » (#9). Ligne = jaquette + titre + « Type · année · créateur ». « Vu le 20 sept. » / « Lu le … » sur une ligne déjà loggée (#10) ; tap = fiche, + = loggé (#11), ♡ = envie (#14). Bandeau hors-ligne (#15). **Chercher un réalisateur ou une actrice ramène sa filmographie (#21)**. **Le + sur une œuvre déjà loggée demande confirmation avant d'ajouter un deuxième log (#22)**. **Manque** : « Ajouter à la main » (T7).

- La barre a le focus dès l'ouverture, clavier levé. Recherche à partir de 2 caractères, 300 ms après la dernière frappe.
- **Tap = fiche de l'œuvre** (aperçu si pas encore en base, avec « Logger »). **« + » au bout de la ligne = loggé** (terminé, maintenant) avec bandeau « *Dune* loggé ✓ · **Modifier** » 4 s. Tranché le 22/09 (§6.2), réalisé en #11.
- **Sauf pour ce qui a des épisodes.** Une série ou un podcast n'a pas de `+` mais une **liste à cocher**, qui ouvre sa fiche — laquelle s'ouvre sur « où j'en suis ». Logger une série d'un bloc reste possible depuis le bouton « Logger » de sa fiche : une série qu'on ne suit pas épisode par épisode a le droit de rester une ligne (#42).
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
│   [ Logger ]  [ ♡ Envie ]       │
│   [ ▶ Je le commence ]          │  ← seulement ce qui dure : livre, série, podcast, jeu
│                                 │
│   ┌───────────────────────────┐ │  ← séries et podcasts
│   │ PROCHAIN ÉPISODE      (✓) │ │
│   │ S2 · E5 · Woe's Hollow    │ │
│   └───────────────────────────┘ │
│                                 │
│   SAISONS                   ••• │
│   ▾ Saison 2 · vus 4/10         │
│     [ ⊘ J'ai vu toute la saison]│
│     ◯ 5 · Woe's Hollow  [Jusqu'ici]
│                                 │
│   Résumé (3 lignes, « plus »)   │
│                                 │
│   TES LOGS                      │
│   12 sept. 2026     ★★★★½   ›   │
│   3 mars 2024       ★★★★    ›   │
│                                 │
│   Source : TMDB                 │
└─────────────────────────────────┘
```

> **Réalisé le 27/09 (#42, #45)** : **l'ordre des blocs change** — jaquette, titre, **actions**, **où j'en suis**, saisons, *puis* le résumé. Ce qu'on vient faire sur une fiche passe avant ce qu'on vient y lire ; sinon la carte « Prochain épisode » tombait sous trois lignes de résumé. Une **carte « Prochain épisode »** en haut pour une série ou un podcast, cochable d'un tap, qui avance toute seule et disparaît quand tout est vu. La saison où on en est **s'ouvre d'elle-même** — une seule saison chargée, celle-là. Un bouton **« Je le commence »** pour ce qui dure (livre, série, podcast, jeu) ; une œuvre déjà commencée montre sa pastille « En cours » à la place.
>
> **Réalisé (PR #10)** : jaquette, « Dune (2021) », « Film · 2h35 · réalisateur » (quand la poche les a), genres / saisons · épisodes / pages · éditeur · sujets selon le type, résumé sur 3 lignes avec « Plus », « Logger à nouveau », TES LOGS (date, statut, étoiles, commentaire ; tap → feuille), « Source : TMDB ». États introuvable et erreur. Ouverte par le titre de la feuille d'édition ou par appui long dans le Journal. Depuis la Recherche : tap sur un résultat, aperçu avec « Logger » s'il n'est pas encore en base (#11). Réalisateur, durée, genres, saisons complétés chez TMDB à l'ouverture (#12) ; bouton « Envie » ♡ à côté de « Logger » (#14). **« Logger » / « Logger à nouveau » ouvre le formulaire (date, demi-étoiles, statut, commentaire) au lieu d'enregistrer sec, et rien n'est écrit tant qu'on n'a pas enregistré — y compris pour une œuvre pas encore en base : annuler ne laisse pas de fiche orpheline (#20)**. Ouverte aussi au **tap sur une ligne du Journal ou de l'Envie** (#18).

- Les détails de la « poche » varient par type : durée / réalisateur pour un film, saisons pour une série, pages / éditeur pour un livre.
- Tap sur un log → Modifier.

### 3.4 Modifier un log (feuille)

> **Réalisé (PR #9)** : feuille Annuler / Log / Enregistrer, titre « Dune (2021) », date avec raccourcis Aujourd'hui · Hier · Ce week-end, demi-étoiles cliquables (re-tap = sans note), statut segmenté limité au type, commentaire, « Supprimer ce log » avec confirmation ; états « ce log n'existe plus » et erreur de lecture. Ouverte par « Modifier » sur le bandeau de la Recherche, par appui long dans le Journal ou l'Envie (Modifier / Supprimer), et depuis la fiche en touchant un log. **Le sélecteur de date ne propose plus d'heure — l'heure reste stockée, elle ordonne deux logs du même jour (#20)**. **La même feuille sert à créer un log depuis la fiche** : formulaire vierge, pas de « Supprimer », écriture à l'enregistrement (#20).

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

### 3.6 Épisodes d'une série (fiche)

> **Réalisé (#33, #34, #39, #42)**. Sous les actions : la carte « Prochain épisode », puis les **saisons dépliables**. Une saison n'est chargée qu'au dépliement — sauf celle où on en est, ouverte d'office à l'arrivée sur la fiche. Une case par épisode, son titre, sa date, sa durée.

- **« J'ai vu toute la saison »** : un bouton visible sous la saison dépliée. Quand elle est complète, il devient **« Tout décocher »** — seule action destructrice de l'écran, donc la seule à demander confirmation, et elle ne touche que cette saison.
- **« Jusqu'ici »** : un bouton sur la ligne de l'épisode, affiché **seulement s'il reste un épisode non coché derrière**. Il remplace l'appui long, que personne n'avait trouvé (#39).
- **Statut** : une pastille (En cours · Terminé · Abandonnée) et un menu ••• pour abandonner ou reprendre. Cocher un premier épisode met la série **en cours** toute seule ; finir la dernière saison **propose** « terminé » sans l'imposer.
- **Les spéciaux** ferment la liste, cochables, **jamais** « la suite ».
- Trois visages : « Aucune saison » (la source ne découpe pas la série), « Impossible de charger » + Réessayer, la liste.

### 3.7 Épisodes d'un podcast (fiche)

> **Réalisé (#50, #51)**. Un podcast **n'a pas de saisons** : il en a une, implicite, qu'on n'affiche pas. Sa liste est **plate, du plus récent au plus ancien** — l'ordre dans lequel on écoute un podcast.

- Le vocabulaire change avec le type : **« ÉPISODES »** et non « SAISONS », **« J'ai tout écouté »** et non « J'ai vu toute la saison », « Abandonner **ce podcast** ».
- **Le rang ne s'affiche pas.** Le numéro d'un épisode de podcast est sa position dans le flux : elle change à chaque publication. La ligne montre le **titre**, la date et la durée. Un épisode de série garde son numéro, que TMDB lui donne et qui ne bouge pas.
- **« Jusqu'ici » y prend le bon sens tout seul** : comme la liste va du plus récent au plus ancien, cocher un épisode ancien coche **tout ce qui est plus récent** — c'est exactement ce qu'on fait quand on rattrape un podcast.
- **Pas de « terminé » proposé** : un podcast publiera encore la semaine prochaine.
- La carte « Prochain épisode » montre le **titre** de l'épisode, sans « S1 · E1 ».
- Trois visages : « Aucun épisode » (le flux n'en donne pas), « Impossible de charger les épisodes » + Réessayer, la liste.

> **Ce qui manque encore** : les podcasts de **Radio France** — Apple ne publie pas leurs flux (dix testés, dix sans flux). Ils sont trouvables et loggables, mais sans liste d'épisodes tant qu'une deuxième source n'est pas branchée. Décision de la founder le 27/09 : le reste d'abord, Radio France ensuite.

### 3.8 En cours (onglet)

> **Réalisé (#35, #43)**, en troisième position — **place confirmée à l'usage** le 27/09. L'écran qui répond à « je reprends quoi ce soir ? ».

- Une ligne par œuvre en cours : jaquette, titre, « S2 · E4 sur 10 », **une barre qui se remplit**, « Prochain : E5 », et un **✓ rond** qui coche la suite sans ouvrir la fiche.
- Le ✓ coche **une seule** chose, la suite : il ne comble pas ce qui a été sauté derrière. Un trou au milieu passe avant ce qui suit le dernier vu.
- Un **livre**, ou une série arrivée au bout de ce qu'on connaît d'elle, montre **« Terminé »** à la place.
- Le tap sur la ligne ouvre la fiche, comme partout.
- **Vide** : « Rien en cours », « Ce que tu commences apparaîtra ici : une série suivie épisode par épisode, un livre entamé. » + Chercher. C'est un onglet permanent : il sera vu vide souvent, son état vide est un écran d'accueil.

### 3.9 Réglages

> **Réalisé (PR #15)** : ⚙︎ dans la barre du Journal → Langue (suit le système, lien vers les Réglages iOS), Confidentialité, À propos (version, logo TMDB + mention, OpenLibrary), Tout effacer (double confirmation), section DEBUG hors Release avec le badge de base. Import / Export attend T3. Bandeau hors-ligne dans la Recherche.

Liste simple : Langue (suit le système), Import / Export (T3, masqué avant), **Tout effacer** (rouge, double confirmation), Confidentialité (deux paragraphes), À propos (version, attributions TMDB avec logo, OpenLibrary). En DEBUG uniquement : « Remplir données démo » / « Tout effacer (démo) » et le badge « Base V1 · n fiches · n logs ».

## 4. Les écrans des tranches suivantes (esquisse)

| Tranche | Écran | L'idée en une ligne |
|---|---|---|
| 2 | **Où j'en suis** | ✅ **Livré (#35)** — décrit au § 3.8, en troisième position. Une ligne par œuvre : « Severance · S2 · E4 sur 10 · *Prochain : E5* » avec un ✓ qui coche l'épisode suivant sans ouvrir la fiche. Livres en cours avec « Terminé » en un tap — **sans** « p. 212 sur 480 » : le modèle ne suit pas la page courante (il faudrait un `SchemaV3`). |
| 2 | **Saisons / épisodes** | ✅ **Livré (#33, #34, #39, #42)** — décrit au § 3.6. « Tout cocher jusqu'ici » est passé de l'appui long au **bouton visible** le 27/09. |
| — | **Podcasts** | ✅ **En cours (#48 → #51)** — décrit au § 3.7. Recherche chez Apple, épisodes par le flux RSS, liste à plat. |
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
| `PeriodSegments` | segments Tout · Semaine · Mois · Année avec compteurs | 1 ⏳ (PR 9) |
| `EpisodeRow` | case + titre + date · durée + bouton « Jusqu'ici » quand il sert | 2 ✅ (#33, #39) |
| `NextEpisodeCard` | « Prochain épisode » + ✓ ; la carte entière est le bouton | 2 ✅ (#42) |
| `ProgressBar` | barre fine qui se remplit **avec animation** | 2 ✅ (#43) |
| `PressFeedback` | style de bouton qui s'enfonce sous le doigt, puis revient | 2 ✅ (#43) |
| `BarcodeScanner` | viseur | 5 |

### 5.5 Accessibilité
- Tout composant a un label VoiceOver ; les étoiles annoncent « 4 étoiles et demie sur 5 ».
- Cibles tactiles ≥ 44 pt ; le « tap = loggé » a une alternative explicite (bouton « Logger ») pour les technologies d'assistance.
- Contraste AA sur l'accent ; pas d'information portée par la couleur seule.
- Réduction des animations respectée (le toast apparaît sans glissement).
- **Retour haptique** sur les gestes qui écrivent (cocher un épisode, avancer), déclenché par le **changement de donnée** et non par le tap : ce qui n'a pas été enregistré ne vibre pas. Il double l'information visuelle, il ne la remplace jamais.
- **Toute la ligne est tapable**, pas seulement ses pixels dessinés : chaque ligne déclare sa zone tactile, et un test le vérifie pour les quatre à la fois (#38).

## 6. Questions d'ergonomie à trancher (avec la founder, à l'écran)

1. ~~**Recherche = onglet ou bouton « + » flottant sur le Journal ?**~~ **Tranché le 21/09/2026 : onglet** (founder). On reverra si le « + » s'impose à l'usage.
2. ~~**Le tap logge immédiatement ou après un court délai annulable ?**~~ Tranché le 21/09/2026 : immédiat + bandeau. **Retranché le 22/09/2026 après usage : tap sur un résultat = fiche de l'œuvre, on logge depuis la fiche** (founder : « dans la recherche, je peux pas accéder à la fiche avant de logger un truc, c'est pas logique »). Claude a proposé un bouton ⓘ ou un appui long pour garder le tap = loggé ; la founder a préféré la fiche. Puis, pendant la démo de la PR 8b, la founder a demandé **un « + » au bout de chaque ligne** pour logger en un geste : tap = fiche, + = loggé + bandeau « Modifier ». Réalisé en #11.
3. ~~**Groupement du Journal par jour ou liste plate ?**~~ **Tranché le 22/09/2026 : par jour** (#13), après la démo de la PR 7 où un log passé à hier avait « disparu » en bas de liste.
4. **Étoiles sur la ligne du Journal ou seulement sur la fiche ?** Reco : sur la ligne, discrètes, à droite.
5. ~~**Envie : chip du Journal ou onglet ?**~~ **Tranché le 22/09/2026 : onglet** (founder), contre la reco chip. Trois onglets Journal · Envie · Recherche ; la Bibliothèque (T5) devra trouver sa place.
6. ~~**Tap sur une ligne du Journal : fiche ou édition ?**~~ ~~**Tranché le 22/09/2026 : édition directe** (founder) ; la fiche par le titre de la feuille ou par appui long.~~ **Retranché le 23/09/2026 après quelques jours d'usage : la fiche** (founder : « quand je fais un tap sur un film que j'ai vu, je voudrais que ça ouvre la fiche du film, et que j'aie une option pour modifier depuis la fiche »). Modifier reste à l'appui long, et depuis la fiche. Même geste dans l'onglet Envie (#18).
7. ~~**Où vit « où j'en suis » (T2) ?** Trois options : chip du Journal (ce que dit le § 4), quatrième onglet (cohérent avec Envie), ou **bandeau de cartes en haut du Journal**. **Reco : le bandeau**.~~ **Tranché le 24/09/2026 : un quatrième onglet « En cours »** (founder), contre la reco du bandeau — comme pour Envie le 22/09. L'écran entier lui appartient : progression, prochain épisode, bouton pour avancer. **Livré le 27/09 (#35) en troisième position** : Journal · Envie · En cours · Recherche — ni Journal ni Envie ne bougent. **Clos le 27/09** : « oui c'est bien » — il **reste en troisième position**, la barre ne bouge plus.
8. ~~**Le Journal s'ouvre-t-il filtré ?**~~ **Tranché le 23/09/2026 : sur Tout** (founder, après qu'un log daté hors de la semaine a eu l'air perdu). Filtrer est un geste, pas un défaut.
9. **Où va la Bibliothèque (T5) ?** Conséquence directe de la question 7, et **la barre en compte quatre depuis le 27/09** : la Bibliothèque en ferait cinq — un de trop sur un iPhone. Options à ouvrir le moment venu : fusionner Journal et En cours, passer Envie dans le Journal, ou un « Plus ». **Pas maintenant** — à trancher en T5, pas avant.
10. ~~**« Tout cocher jusqu'ici » derrière un appui long ?**~~ **Tranché le 27/09/2026 : un bouton visible** (founder : « ah non je ne l'avais pas trouvé, faut le rendre visible »), après trois jours d'usage quotidien sans l'avoir jamais découvert — au point de le redemander comme une fonctionnalité manquante. L'appui long est retiré : deux chemins pour un geste, dont un invisible, c'est un de trop. **Troisième geste caché abandonné** ; c'est devenu le principe 4 du § 1.
11. **Le résumé descend sous les épisodes sur toutes les fiches** (#42), films et livres compris — les actions avant la lecture. Assumé, mais c'est un changement d'écran : **à juger à l'usage**, pas sur le papier.
12. **Les libellés d'action restent génériques sur un podcast** : « Logger », « Je le commence ». `MediaKind.seenActionLabel` sait déjà dire « Je l'ai écouté ». À reprendre si ça sonne faux.

## 7. Ce qu'on ne fait pas en design

- Pas d'onboarding en plusieurs écrans : le premier écran vide *est* l'onboarding.
- Pas de thème personnalisé, pas d'icône alternative.
- Pas d'animations décoratives ; les seules transitions sont celles du système.
- Pas de gamification (streaks, badges) — le journal n'est pas une injonction.
