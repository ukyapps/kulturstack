# ADR-015 — Podcast Index en second recours, pour Radio France seulement

- Statut : **accepted**
- Date : 2026-10-03
- Contexte : tranche Podcasts, PR 36. Prolonge l'[ADR-014](014-flux-radio-france-par-leur-page.md).

## Contexte

L'ADR-014 lit le flux d'un podcast de Radio France dans la page que Radio France publie. Mesuré sur un échantillon aléatoire de 106 podcasts tirés des 514 : **76 %**. Les 25 qui manquaient se répartissaient en deux familles — 8 dont la page ne déclare aucun flux, 17 dont l'adresse de page ne se déduit pas du titre.

J'y avais écrit que les 8 premiers « ne se récupéreront jamais : un flux que Radio France ne publie pas n'existe nulle part ». **C'était déduit, pas vérifié.** La founder a demandé qu'on vise les 100 %, a obtenu une clé Podcast Index le soir même, et la mesure a montré l'inverse.

## Ce qui a été mesuré le 03/10, la clé en main

| Question | Mesure |
|---|---|
| Podcast Index retrouve-t-il les 25 manquants ? | **22 sur 25**, avec un appariement strict. Dont **7 des 8** que l'ADR-014 déclarait perdus. |
| Couverture totale ? | **97 %** (103 sur 106), contre 76 % par la seule page. |
| Sa correspondance « par identifiant Apple » (`byitunesid`) ? | **Inutilisable : 1 sur 4 testés.** Les flux de Radio France y portent `itunesId: 0` ou rien. Il faut passer par la recherche par titre. |
| Le danger de la recherche par titre ? | **Réel.** Sur « L'instant M », l'index rend aussi « L'instant pour Soi », dont l'**auteur** s'appelle « L'instant M ». Un appariement lâche afficherait les épisodes d'un autre podcast. |
| Des doublons ? | **Oui.** Deux entrées « L'instant M » de France Inter, l'une à 24 épisodes mise à jour le jour même, l'autre à 1 épisode datant de 2025. |
| Ce qui reste perdu ? | **3 podcasts** : « Mazan, un procès pour l'histoire », « Les résidents », « L'Édito sport ». |

## Décision

1. **Podcast Index n'est consulté que lorsque la page de Radio France n'a rien donné.** La page est gratuite et sans clé ; l'index coûte une clé et un quota. L'ordre n'est pas négociable, et un test le vérifie.
2. **Il ne sert qu'à Radio France.** Un flux hébergé ailleurs que chez `radiofrance-podcast.net` n'est **jamais** retenu, et un producteur qui n'est pas une station de Radio France ne déclenche aucune requête. C'est ce qui borne les dégâts d'un mauvais appariement, et ce qui garde le quota pour ce à quoi il sert.
3. **L'appariement est strict** : titre **et** producteur identiques (accents, casse et ponctuation ignorés — Apple et l'index n'écrivent pas pareil), flux vivant, hôte attendu. Entre deux entrées du même podcast : celle qui a le plus d'épisodes, puis la plus récemment vue.
4. **Deux secrets de plus** — `PODCASTINDEX_KEY` et `PODCASTINDEX_SECRET` — par le **même tuyau que TMDB** : Trousseau → `make secrets` → `Config/Secrets.xcconfig` (gitignoré) → `Info.plist`. Jamais dans le dépôt, jamais dans le chat.
5. **Sans clé, l'app marche.** La source se tait au lieu d'appeler une API qui la rejettera : les podcasts dont la page donne le flux continuent, les autres montrent leur état vide. C'est ce qui permet à la CI de tourner avec un simple `ci-placeholder`.

## Conséquences

- **Couverture de Radio France : 76 % → 97 %.**
- **Deux secrets de plus sont extractibles du binaire.** C'est le risque déjà accepté pour TMDB (ADR-001), avec une différence qui compte : ce sont les identifiants **personnels de la founder** chez Podcast Index. Quelqu'un qui les extrairait consommerait son quota sous son nom. Rayon d'explosion limité (une API de lecture, gratuite, révocable en une minute depuis son compte), mais à nommer. **Ils migrent derrière le proxy en T6, avec TMDB.**
- **Un podcast non couvert coûte une requête de plus** à la première ouverture de sa fiche. La réponse est retenue pour la session, absence comprise.
- **Si la clé est révoquée ou expire**, la panne remonte comme une panne : la fiche dit « Impossible de charger les épisodes » au lieu de mentir avec « Aucun épisode ». Vide ≠ erreur, ici aussi.
- **Trois podcasts restent sans épisodes** sur l'échantillon, et leur fiche l'explique déjà (« ou son flux ne les donne pas »).

## La leçon de l'ADR-014

« Cette source ne l'a pas » ne veut pas dire « ça n'existe pas ». J'ai conclu à l'impossibilité depuis une seule source, et je l'ai écrit dans un ADR comme un fait. Il a suffi d'une deuxième source pour que 7 des 8 cas « définitivement perdus » reviennent. **Avant d'écrire qu'une chose est impossible, vérifier ailleurs** — ou écrire « je n'ai pas trouvé », qui est ce que je savais réellement.

## Alternatives écartées

- **`byitunesid` plutôt que la recherche par titre** : ce serait sans ambiguïté, donc sans risque d'appariement. Mais l'index ne connaît l'identifiant Apple que d'un podcast de Radio France sur quatre — mesuré. Gardé comme première tentative serait un appel de plus pour trois échecs sur quatre.
- **fyyd** : 2 récupérés sur 25 (ADR-014). Même risque d'appariement, pour neuf fois moins de résultat.
- **Podcast Index comme source unique**, à la place de la page : il faudrait la clé pour **tous** les podcasts de Radio France au lieu d'un sur quatre, et l'app cesserait de marcher sans elle. La page d'abord garde l'app autonome.
- **Un proxy dès maintenant** pour ne rien embarquer : c'est la Tranche 6, elle demande un serveur. Les deux secrets y passeront avec TMDB.
