---
type: plan
tranche: Podcasts (T4a du PRD, avancée avant l'import — décision founder du 27/09)
statut: en cours — PRs 30 à 34 livrées ; reste la PR 35 (seed DEBUG et finitions)
créé: 2026-09-27
---

# Plan — Podcasts

**Objectif** : à la fin, un podcast se cherche, se logge et **s'écoute épisode par épisode**. On ouvre sa fiche, on voit ses épisodes du plus récent au plus ancien, on coche ce qu'on a écouté. Le Journal compte les podcasts comme il compte les films.

**Ce qui déclenche cette tranche** : la founder, le 27/09 — « maintenant je voudrais qu'on ajoute les podcasts et tout, c'est prévu pour quand ça ? ». C'était prévu en T4, après l'import ; elle a tranché l'inverse.

## Ce que j'ai vérifié avant d'écrire ce plan

Tout ce qui suit a été testé sur les API réelles le 27/09, pas supposé.

| Question | Réponse mesurée |
|---|---|
| Apple sait-il chercher un podcast français ? | **Oui, très bien.** `itunes.apple.com/search?media=podcast&country=FR` rend le nom, le producteur, la jaquette 600 px, le nombre d'épisodes et le genre. Pas de clé, pas de compte. |
| Donne-t-il le flux RSS ? | **Presque toujours — sauf Radio France.** Arte Radio, Binge, Louie Media, Simplecast, Megaphone, Ausha : flux fourni. **France Inter et France Culture : 10 podcasts testés, 10 sans flux**, y compris par l'endpoint `lookup`. C'est la question ouverte de cette tranche. |
| Un flux RSS se lit-il proprement ? | **Oui.** « Le code a changé » : 96 épisodes, chacun avec titre, date de diffusion, durée (`00:16:57`) et `guid`. `XMLParser` suffit, aucune dépendance. |
| Quelle taille fait un flux ? | 264 Ko pour 96 épisodes ; 494 Ko pour 64 épisodes chez The Daily. **Les éditeurs tronquent leur historique** : The Daily en a publié des milliers, son flux n'en garde que 64. |
| Les épisodes sont-ils numérotés ? | **Non.** Ni `itunes:episode`, ni `itunes:season` sur les deux flux testés. Un podcast est une **liste plate**, du plus récent au plus ancien. |

## Ce que ça implique pour le modèle

**L'identité d'un épisode de podcast est son `guid`, pas son numéro.** Un numéro de position n'est pas stable : quand l'éditeur tronque son flux ou publie un nouvel épisode, tout se décale, et une coche se retrouverait sur le mauvais épisode. C'est la raison d'être de la première PR — **un schéma V3**, donc une migration, donc la procédure de vérification sur l'appareil du 24/09.

Tout le reste du modèle tient sans changement : un podcast est un `MediaItem(kind: .podcast)`, ses épisodes sont des `Episode` dans une `Season` implicite, et `kind.hasEpisodes` est déjà vrai pour les podcasts depuis la T1.

## Périmètre

**Dedans** : chercher un podcast (Apple), sa fiche, ses épisodes par le flux RSS, cocher un épisode, « tout cocher jusqu'ici », le Journal et ses compteurs.

**Dehors, même « vite fait »** :
- **L'onglet « En cours » et « prochain épisode ».** Une série se regarde du premier au dernier ; un podcast s'écoute **par le plus récent**. « La suite » n'y veut pas dire la même chose, et je préfère le vérifier à l'usage plutôt que le deviner. À rouvrir dès que la founder aura vécu avec.
- Les **saisons de podcast** (`itunes:season`) : aucun des flux testés n'en a. Liste plate.
- L'**import** (T3), les **disques** (T4b), la lecture audio (Kulturstack journalise, ne joue rien), les **notes par épisode**.

## Règles du plan

Les mêmes qu'en T1 et T2, elles ont tenu :
- 1 PR = 1 branche = 1 jour max = **quelque chose de visible à l'écran** à la fin.
- Tests d'abord (rouge → vert), strings FR + EN dans la même PR, captures vide / rempli dans la description.
- Merge quand `test` est vert **et** que la review locale est PASS dans la PR.
- Si une PR déborde d'une journée : la couper.

**Estimation** : 4 à 5 PRs ≈ 5 jours de travail. Rien ne se ferme à une date.

---

## PR 30 — Schéma V3 : l'identité d'un épisode `feat/schema-v3`

**Livre** : `Episode.externalID` (le `guid` du flux), `KulturstackSchemaV3` et son étage de migration. Aucune interface.

- Stage **lightweight** : on ajoute un champ optionnel, on ne touche à rien d'existant.
- Les épisodes de séries gardent `externalID = nil` : leur identité reste (saison, numéro), et TMDB les numérote.
- Unicité : un `externalID` ne se répète pas dans une saison.
- Tests : **T-01 étendu** — un store V2 **contenant des séries, des épisodes cochés et des logs** est rouvert avec le plan V3, tout est intact et `externalID` vaut `nil` ; un épisode de podcast se retrouve par son `guid` ; deux flux différents peuvent porter le même `guid` sans se mélanger.

**Démo** : le badge DEBUG affiche « Base V3 ». Peu spectaculaire, assumé — comme la PR 12.

> **La base de la founder contient ses vrais logs depuis le 23/09, et ses épisodes depuis le 24/09.** Avant de fusionner : sauvegarde du store depuis l'iPhone, comparaison **ligne à ligne** avant / après, exactement comme le 24/09. Mode d'emploi dans `docs/journal/2026-09-24-lancement-tranche-2.md`.

## PR 31 — Chercher un podcast `feat/apple-podcasts`

**Livre** : une section « Podcasts » dans la recherche, alimentée par Apple.

- `ApplePodcastProvider: MetadataProvider` — `itunes.apple.com/search?media=podcast&country=<pays de l'app>`.
- Dédup par `itunes:<collectionId>` ; le flux, quand Apple le donne, est stocké en clé secondaire `feed:<url>`.
- `PodcastDetails` : producteur, nombre d'épisodes, genre, URL du flux.
- **Pas de clé, pas de compte, pas de secret** — c'est une API publique.
- Tests : fixture réelle capturée sur l'API, un podcast sans flux ne casse rien, panne réseau → la section montre son erreur et le reste de la recherche vit sa vie (le mécanisme existe depuis la T1).

**Démo** : « transfert » rend Transfert, avec sa jaquette ; le `+` le logge en un geste ; sa fiche s'ouvre.

## PR 32 — Les épisodes par le flux RSS `feat/rss-episodes`

**Livre** : de quoi remplir la liste d'épisodes d'un podcast, derrière le protocole `EpisodeProvider` **qui existe déjà** (T2).

- `RSSEpisodeProvider` : lit le flux avec `XMLParser`, rend des `EpisodeSummary` — titre, `pubDate`, `itunes:duration` (`HH:MM:SS` → minutes), `guid`.
- **Le flux n'est chargé qu'à l'ouverture de la fiche**, jamais pendant la recherche : c'est un fichier de 250 à 500 Ko.
- **Plafond de 300 épisodes** gardés, les plus récents. Un flux tronqué par son éditeur ne doit pas décaler ce qui est déjà coché : c'est le `guid` qui fait foi.
- Tests : fixture réelle (un flux Radio France de 96 épisodes, un flux court), durée mal formée, date absente, `guid` manquant (repli sur le lien), XML invalide → la fiche reste lisible.

> **Cette PR livre les podcasts dont Apple donne le flux** — c'est-à-dire tout sauf Radio France, qui arrive en PR 35 (décision founder du 27/09 : « les deux à parts égales », donc le reste d'abord).

## PR 33 — Cocher un épisode de podcast `feat/podcast-episodes`

**Livre** : sur la fiche d'un podcast, la liste de ses épisodes, **du plus récent au plus ancien**, une case par épisode.

- Pas d'en-tête « Saison 1 » pour un podcast : la saison implicite ne se montre pas, la liste est plate.
- « Tout cocher jusqu'ici » garde son sens, dans l'ordre de la liste : cocher un épisode ancien coche tout ce qui est **plus récent** que lui — c'est ainsi qu'on rattrape un podcast.
- Pas de carte « Prochain épisode » : hors périmètre, voir plus haut.
- Trois rendus : flux vide (« aucun épisode publié »), chargement raté (« Réessayer »), la liste.
- Tests : cocher, décocher, tout cocher jusqu'ici, idempotence ; un épisode coché **reste coché après un rafraîchissement du flux** qui a ajouté trois épisodes en tête (c'est le test qui justifie la PR 30).

**Démo** : captures fiche podcast repliée / dépliée / après avoir coché.

## PR 34 — Radio France `feat/radio-france-sans-cle` ✅

**Livre** : les épisodes des podcasts que Apple laisse sans flux — France Inter, France Culture, franceinfo, France Musique, FIP, Mouv'.

**Sans clé, sans compte, sans inscription** — ce qui change par rapport à ce que ce plan prévoyait. Mesuré le 03/10 avant d'écrire une ligne : la **page** d'un podcast Radio France déclare son flux, dans la balise `<link rel="alternate" type="application/rss+xml">` que lit n'importe quel lecteur de podcasts, et l'adresse de cette page se déduit du producteur et du titre que rend Apple. Podcast Index — et les cinq minutes d'inscription de la founder — devient inutile. Décision et chiffres : **ADR-014**.

**Couverture mesurée : 76 %**, sur un échantillon aléatoire de 106 podcasts tiré des 514 que Radio France publie chez Apple sans flux. Les **émissions** passent (FIP 100 %, France Musique 93 %, franceinfo 87 %, France Culture 77 %, France Inter 67 %) ; les **chroniques et mixes** ratent (Mouv' 38 %). **ICI (ex-France Bleu) : zéro**, ses podcasts sont sur ici.fr.

**76 % est le plafond de cette source**, et c'est mesuré, pas estimé : sur les 25 qui manquent, **8** ont une page qui ne déclare aucun flux, et **17** ont une adresse de page qu'aucune règle ne déduit du titre. Les retrouver par ce chemin demanderait un index des pages de Radio France, c'est-à-dire un crawl — que leur `robots.txt` interdit explicitement.

**Mais une autre source va plus loin.** Mesuré le 03/10 au soir, la clé de la founder en main : **Podcast Index retrouve 22 des 25**, dont 7 des 8 dont la page ne déclare rien. Le plafond réel est donc **97 %**, pas 76 %. Ce sera une **PR 36**, avec son ADR : elle introduit deux secrets et une deuxième source, et demande un appariement strict (titre **et** producteur) parce que la correspondance par identifiant Apple de Podcast Index est très incomplète.

- Un **résolveur appelé uniquement quand le flux manque** : il part de la clé `itunes:` que porte déjà tout podcast en base — donc il marche aussi sur ceux **déjà loggés**, sans les rechercher. Il demande leur nom à Apple (`lookup`, 2 Ko), puis essaie **au plus trois adresses** de page. Le `RSSEpisodeProvider` de la PR 32 fait le reste, sans rien savoir de tout ça.
- Un podcast dont Apple donne le flux ne le fait **jamais** travailler : le flux répond avant lui.
- **Une absence n'est pas une panne** : page inexistante → orthographe suivante, les trois épuisées → l'état vide, qui dit déjà « son flux ne les donne pas ». Toute autre panne remonte en « Impossible de charger les épisodes ».
- Tests : 19 nouveaux, dont le calcul d'adresse comparé aux **31 cas mesurés sur le vrai site**. Fixtures réelles : le `lookup` d'Apple, la page de « Le code a changé », son flux.
- **Hors périmètre, et écrit** : ICI (ex-France Bleu), dont les podcasts vivent sur ici.fr.

**Démo** : la fiche d'un podcast Radio France, vide avant, avec ses épisodes après — `docs/captures/podcasts-pr-34/`.

## PR 35 — Le seed DEBUG et les finitions `chore/podcasts-seed`

**Livre** : le seed DEBUG crée un podcast avec ses épisodes, les compteurs du Journal montrent « Podcasts · n », et les libellés FR / EN sont relus (« écouté » et non « vu » — `MediaKind.seenActionLabel` existe déjà).

---

## Ordre de dépendance

```
PR30 → PR31 → PR32 → PR33 → PR35
                        ↘ PR34 (Radio France, dès que la clé est là)
```

Le schéma d'abord, la recherche ensuite, les épisodes après, l'écran en dernier. La PR 31 peut se faire en parallèle de la PR 30 : elle ne touche pas au modèle.

## Radio France — tranché le 27/09

**Apple ne publie pas le flux RSS des podcasts de Radio France.** Mesuré le 27/09 : « Le code a changé », « Affaires sensibles », et les dix premiers résultats de « france inter » et « france culture » — **aucun** n'a de `feedUrl`, ni par la recherche, ni par `lookup`. Les autres producteurs testés (Arte Radio, Binge, Louie Media, The Daily, Transfert) en ont tous un.

Les flux **existent** pourtant : `radiofrance-podcast.net/podcast09/podcast_<uuid>.xml`, et ils se lisent parfaitement (96 épisodes datés et minutés pour « Le code a changé »). C'est leur **découverte** qui manque : rien, dans ce que rend Apple, ne permet de remonter jusqu'à eux.

| | Ce que ça donne | Ce que ça coûte |
|---|---|---|
| **A. Podcast Index** (reco) | Un index ouvert des flux, avec un endpoint « donne-moi le flux de ce podcast Apple ». Un appel de plus, **uniquement** quand Apple n'a rien. Radio France couvert comme le reste. | Une **inscription gratuite** (5 minutes) et une clé à ranger dans le Trousseau, comme TMDB. Un ADR. À vérifier une fois la clé en main : que Radio France y est bien indexé. |
| **B. Sans Radio France** | Rien à faire, rien à inscrire. Les podcasts Radio France restent **cherchables et loggables en une ligne**, comme une série qu'on ne suit pas épisode par épisode — mais **sans liste d'épisodes**. | Si la founder écoute surtout France Inter et France Culture, la tranche rate sa cible. |

**Réponse de la founder : « les deux à parts égales ».** Donc **l'option B d'abord, l'option A ensuite** : la tranche se fait sans Radio France (PRs 30 → 33), et Radio France arrive en **PR 34**, quand elle aura cinq minutes pour l'inscription gratuite. Elle aura entre-temps les épisodes de tout le reste.

### Ce que le 03/10 a changé : une option C, qui ne coûte rien

Avant de demander ces cinq minutes, une troisième piste a été mesurée : **la page du podcast sur radiofrance.fr déclare son flux**, et son adresse se déduit du producteur et du titre rendus par Apple. **23 podcasts sur 24**, dont 21 du premier essai. Ni clé, ni compte, ni secret.

L'ADR-013 avait écarté cette piste d'une phrase — « rien dans ce que rend Apple ne permet de remonter jusqu'à la page ». C'était **supposé, pas mesuré, et faux**. La founder a tranché l'option C le 03/10, Podcast Index restant le recours écrit si la page cesse de marcher. Détail et chiffres : **ADR-014**.

## Ce qu'on vérifie avant de dire « shippé »

- [ ] **La base de la founder survit à la migration V3** — testée sur son iPhone, avec ses vrais logs et ses épisodes cochés.
- [ ] T-01 vert, dans sa version V2 → V3 **avec des données**.
- [ ] Un épisode coché **reste coché** après qu'un flux a publié trois épisodes de plus.
- [ ] Un podcast de 500 épisodes ne fait pas ramer la fiche (plafond à 300).
- [ ] Le flux n'est **jamais** chargé pendant la recherche.
- [ ] Trois rendus distincts sur chaque nouvel écran, comparés image contre image.
- [ ] Coverage ≥ 70 % Domain et Data, ≥ 50 % Features.
- [ ] Aucune string en dur, FR + EN dans la même PR.
- [ ] Captures vide **et** rempli dans chaque PR.
- [x] Aucun secret dans le dépôt — **la PR 34 n'en introduit aucun** : elle lit une page publique, sans clé ni compte (ADR-014).
- [x] Un podcast dont Apple donne le flux **n'appelle pas** le résolveur de la PR 34.

## Ce que cette tranche ne résout pas

Kulturstack ne **joue** pas les podcasts : il journalise ce qu'on a écouté. L'app ne saura pas qu'un épisode a été écouté à 80 % dans une autre application — il se coche à la main, comme un épisode de série. Si ça devient le point de friction, la piste est un import (Apple Podcasts n'a pas d'API de lecture ; Pocket Casts et Overcast en ont une) : ce serait une tranche à part, pas un ajout « vite fait ».
