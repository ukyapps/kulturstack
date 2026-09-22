---
type: retours
statut: vivant — une entrée par retour, daté, avec ce qu'on en a fait
---

# Retours utilisateurs

L'utilisatrice principale est la founder. Chaque retour est noté tel quel, avec la décision prise. Quand d'autres personnes utiliseront l'app (TestFlight, T1), leurs retours iront ici aussi, sous leur propre section.

## Founder — session du 2026-09-19 / 20 (avant toute ligne de code)

### Sur le concept

| Retour | Ce qu'on en a fait |
|---|---|
| « Un journal de consommation culturelle multi-média sans friction … pour remplacer le bordel Trakt / Goodreads / Culture.md / Discogs / podcasts → log par défaut au moment de la saisie, éditable, granularité à l'épisode. » | Le pitch tel quel. Principes 1, 2 et 4 du PRD. Discogs et podcasts étaient dans la phrase d'origine mais pas dans le cadrage de juillet → réintégrés (voir plus bas). |
| « Ça n'a rien à voir avec le truc, c'est complètement à côté de la plaque » (sur trois listes de noms : fun, littéral, profil culturel) | Changement d'angle : nommer **l'objet** (le média), pas l'utilisatrice ni l'acte. Voir ADR-008. |
| Noms aimés : Letterboxd, Arte, Deezer, TV Time, Discogs, Goodreads | Le pattern qui a débloqué le naming : des mots du vocabulaire du média. |
| « Backlog et Culture Time j'aime bien » | Backlog vérifié → trop pris. Direction Culture Time / Culture Stack → Kulturstack. |
| « Kulturstack ou Kulturklub ? » | Kulturstack (ADR-008). Kulturklub réservé à une éventuelle feature sociale. |

### Sur les fonctionnalités

| Retour | Ce qu'on en a fait |
|---|---|
| « Y a peut-être une section en mode *où j'en suis*, un truc *j'ai consommé quoi cette année / ce dernier mois / cette dernière semaine*, et un truc *par typologie de contenu* » | Trois écrans ajoutés au PRD et au design. « Par période » et « par type » en **T1** (PR 9), « où j'en suis » en **T2** avec les épisodes. A servi de test au modèle : tous filtrent sur des champs communs (ADR-002). |
| « Il manque les disques que l'on a, Discogs possible ? Et les podcasts écoutés » | Disques (Discogs) et podcasts (Apple Podcasts + RSS) ajoutés comme types 4 et 5. Tranche 4 dédiée, avant les jeux (ADR-011). |
| « De la même manière que les disques, on pourrait créer un truc *ce que j'ai dans ma bibliothèque* avec les CD, les vinyles, les DVD, les cassettes, les livres. Pardon je pivote un poil le projet » | Pas un pivot : une deuxième relation à l'œuvre, `OwnedCopy` (ADR-010). Tranche 5 « Collection » avec scan de code-barres et import Discogs. |
| « En gros si je reformule c'est soit je l'ai vu / écouté, soit je le possède, quand on l'ajoute » | Oui, et « les deux ». Deux cases indépendantes à l'ajout ; « je l'ai vu » cochée par défaut, « je le possède » par défaut au scan. Design §4. |
| « Dans les statuts t'as aussi *je l'ai dans ma bibliothèque* » | Expliqué pourquoi ce n'est pas un statut (ça se combine avec tous) mais que ça **ressemblera** à un statut dans les filtres. Validé. ADR-006. |
| « 5 étoiles avec demi » | ADR-006. Stockage 1…10, conversions d'import sans perte. |
| « Option B, une seule barre qui cherche tout, et on peut filtrer si on a envie » | ADR-005. |
| « On peut voir l'ergonomie après » | Le design document (`design.md`) est écrit comme une **proposition à valider écran par écran**, pas comme une spec figée. Cinq questions d'ergonomie y sont listées pour elle. |

### Sur les sources de données

| Retour | Ce qu'on en a fait |
|---|---|
| « On est sûrs de Setlist.fm ? J'arrive pas à accéder au site » | Vérifié : site et API en ligne, protection anti-bot Cloudflare qui bloque certains navigateurs. Conseil : essayer en 4G. Setlist.fm gardé. |
| « Pour le théâtre, t'as exploré L'Officiel des spectacles ? BilletReduc ? » + lien Eurêkoi | Exploré : aucun n'a d'API ; la liste Eurêkoi concerne les *textes*, pas les *représentations*. Retenu : saisie assistée + OpenAgenda + Les Archives du spectacle à contacter. |
| « Non, pas de mail » (aux Archives du spectacle) | Pas envoyé. Noté comme piste à rouvrir avant T7. |

### Sur la façon de travailler

| Retour | Ce qu'on en a fait |
|---|---|
| « Alors là j'y comprends plus rien. On peut d'abord se poser sur les sources de données possibles pour chaque typologie de contenu ? » (après un retour de 8 questions techniques d'un coup) | Changement de méthode : **une question à la fois**, langage simple, mots expliqués, reco + tableau court. Consigné dans CLAUDE.md § Contexte founder. |
| « Je n'ai pas trop compris le truc de PR et c'est quoi qui prend une demi-journée » | Expliqué (paquet de travail relu, temps de Claude pas le sien). Règle : expliquer chaque terme à sa première apparition. |
| « Bah moi j'ai pas accès au truc Mealkin, mais je veux que mon truc soit propre et moi j'y connais rien, ça va être ok quand même ? » | Oui : propre = tests + `main` protégée + docs, pas Mealkin. Repo créé sur `ukyapps`, bundle id `com.ukyapps`. |
| « Ok oui public » | Repo public (protection de `main` gratuite). |
| Jeton Claude collé dans le chat | Révoqué, recréé. Règle rappelée et écrite : un secret ne va qu'à l'invite du Terminal. |
| « Est-ce qu'on peut abandonner le process de CI/CD sur GitHub ? Je n'ai pas les secrets et c'est bourbier pour le projet. » | Review Claude en CI retirée (ADR-012). Tests CI gardés (aucun secret). Review faite par Claude en local avant chaque PR. |
| « Vérifie que tu as bien exhaustivement documenté le projet à date, l'architecture, les features et les retours utilisateurs » | Ce fichier, l'état des lieux dans `docs/journal/`, la carte des documents du README, et l'inventaire des features dans le PRD §6. |

## Founder — sessions du 2026-09-21 (en utilisant le prototype)

| Retour | Ce qu'on en a fait |
|---|---|
| Tape 7 fois sur Dune dans la Recherche, rien ne dit que c'est déjà loggé | Comportement voulu (re-tap = revisionnage), mais « Vu le … » sur la ligne de résultat passe en PR 8 avec la fiche. |
| Tap immédiat plutôt que délai annulable | Décision produit : tap = loggé + bandeau 4 s. Design §6. |
| Après avoir passé un log à « Hier », « je vois pas la date d'hier » — le log était en bas de liste, hors écran | Rien à corriger, mais argument fort pour le Journal groupé par jour (PR 9). |
| « Modifier » sur le bandeau ouvre « une autre feuille » — celle du nouveau log, pas du log édité avant | Expliqué : chaque tap crée un log. Renforce le besoin de « Vu le … » (PR 8). |
| « J'aimerais que quand je clique dessus juste ça s'ouvre, pas besoin de dire modifier et tout. À terme. » | **À trancher avant la PR 8.** Le design prévoit tap → fiche de l'œuvre, appui long → modifier. Pistes : (a) tap → feuille d'édition directement, la fiche accessible depuis la feuille ; (b) tap → fiche avec le log en tête, éditable sur place. Reco à venir avec la PR 8. |

## Founder — session du 2026-09-22 (fiche d'une œuvre)

| Retour | Ce qu'on en a fait |
|---|---|
| A — édition directe au tap sur une ligne du Journal | Fait en PR 8 : tap = feuille ; titre de la feuille → fiche ; appui long → Voir la fiche / Supprimer. Design §6.6. |
| « Dans recherche je voudrais qu'un tap ça ouvre la fiche, et double tap ça se log » puis « si je suis dans la recherche, je peux pas accéder à la fiche avant de logger un truc, c'est pas logique » | Le double tap est écarté (pas un geste iOS, retarde chaque tap). Trois options proposées : ⓘ sur la ligne (reco), appui long, tap = fiche. **Founder : tap = fiche, on logge depuis la fiche.** Remplace « tap = loggé » du 21/09. Design §6.2, PR 8b. |
| « On pourrait pas mettre le petit + de logger à la fin de chaque ligne pour logger directement ? que ce soit plus rapide ? » | Oui : + au bout de chaque résultat = loggé en un geste (#11). C'est le compromis tap = fiche / + = log. |
| « Quand je log avec le petit bouton, ça me met plus la petite barre orange qui dit c'est loggé, modifier » | Bandeau « loggé ✓ · Modifier » remis sur le + (#11). |
| « Pourquoi le titre s'affiche en plus ? Parfois le titre va être trop long, non ? … Il faut pas mettre le titre du tout. » | Claude proposait de garder le titre coupé au milieu (dit lequel des cinq « Dune »). Founder : sans titre. Bandeau = « Loggé ✓ · Modifier » (#11). |
| Fiche de Dune sans réalisateur ni genres | La recherche TMDB ne renvoie pas ces champs. Appel « détails » à l'ouverture de la fiche (#12). |

## Autres utilisatrices

*(vide — à remplir dès le premier TestFlight)*
