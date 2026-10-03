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

## Founder — session du 2026-09-22 (Envie)

| Retour | Ce qu'on en a fait |
|---|---|
| Les envies : à part (reco) plutôt que mélangées aux compteurs | Le Journal et ses compteurs ne montrent que ce qui a été consommé (#14). |
| « Je veux pas d'un chip envie dans le journal, je pense qu'il faut faire un 3ᵉ onglet comme journal recherche avec envie » | Onglet Envie (#14), contre la reco chip du design §6.5. |
| Après « Je l'ai vu », « il reste, il devrait disparaître et aller dans journal mais plus être dans envie » | Bug : je listais toutes les envies. Corrigé : en attente = pas de consommation postérieure ; testé dans les deux sens (#14). |
| « Dans la recherche comme le petit + pour logger, il y ait le petit cœur d'envie pour ajouter direct » | ♡ à côté du + sur chaque ligne ; l'appui long est retiré (#14). |

## Founder — session du 2026-09-23 (premiers jours d'usage réel, sur son iPhone)

Sept retours d'un coup, après avoir vécu avec l'app. Triés en quatre PRs ; l'ordre suit ce qui gêne au quotidien.

| Retour | Ce qu'on en a fait |
|---|---|
| « Y'a un bug, j'ai log la planète sauvage, mais ça n'apparaît pas dans mon journal. Pourtant quand je le recherche c'est bien loggé avec la bonne date et mon commentaire. » | **Pas une perte de données** : le log existait, mais le Journal s'ouvrait sur **Semaine** et elle avait daté le log hors de cette semaine. Rien ne le disait. Corrigé (PR 18) : le Journal s'ouvre sur **Tout**, et les segments deviennent Tout · Semaine · Mois · Année. |
| « Dans journal, quand je fais un tap sur un film que j'ai vu, je voudrais que ça ouvre la fiche du film, et que j'aie une option pour modifier depuis la fiche » | Fait (PR 18) : tap = la fiche ; on modifie un log depuis la fiche (déjà le cas) ou par appui long sur la ligne. **Inverse la décision du 22/09** (tap = feuille d'édition) — l'usage a tranché. Même geste dans l'onglet Envie, pour ne pas avoir deux règles. |
| « Quand j'enregistre une fiche, très bien de mettre la date, mais pas l'heure c'est un peu abusé. » | Le sélecteur de date proposait date **+ heure** alors que l'heure ne s'affiche nulle part. Corrigé (PR 20) : le jour seulement. L'heure reste stockée en coulisse, elle sert à ordonner deux logs du même jour. |
| « Quand j'ouvre une fiche, et que je clique sur log, ça m'ouvre pas le log avec ma note et tout, ça log juste. Je voudrais qu'on ouvre le log avec le détail notes et tout. L'option log en un clic est dispo que depuis la recherche pour aller vite. » | Fait (PR 20) : « Logger » ouvre le formulaire, et **rien n'est écrit tant qu'on n'a pas enregistré** — Annuler ne laisse pas de log derrière. Le 1-tap reste le `+` de la Recherche, et ♡ « Envie » reste direct. |
| « La recherche fonctionne que sur les titres ? Pas les auteurs ou les artistes ? Ex : si je mets wes anderson, je n'ai pas tous les films de Wes Anderson. » | Fait (PR 21). TMDB renvoyait bien la personne, on ne gardait que les titres. Maintenant : personne reconnue dans les 3 premiers résultats → sa filmographie, filtrée par son métier (un réalisateur ramène ce qu'il a réalisé, une actrice ce qu'elle a joué), 20 œuvres au plus. Vérifié sur l'API réelle : « wes anderson » ramène The Grand Budapest Hotel, L'Île aux chiens, Fantastic Mr. Fox, Asteroid City, The French Dispatch, Moonrise Kingdom, La Famille Tenenbaum, Rushmore… |
| « La recherche par artiste a l'air de fonctionner si je le fais par auteur pour la partie livre donc. » | Exact : OpenLibrary cherche nativement dans les auteurs. Rien à faire côté livres. |
| « Dans journal à la place de mettre la date en petit sur quand j'ai vu je voudrais un aperçu du commentaire. » | Fait (PR 19) : la ligne du Journal montre le début du commentaire (2 lignes) là où était la date. La date ne se perd pas — elle est l'en-tête du jour, juste au-dessus. Sans commentaire, la ligne ne montre rien à cet endroit. |
| « On peut enregistrer les trucs en double, on devrait pas, c'est une fois un film, même si on peut l'avoir revu, on peut mettre sur la même fiche qu'on l'a revu mais voilà » | Il n'y a **jamais deux fiches** (dédup par clé externe, ADR-004) : ce sont deux **logs** de la même œuvre, ce qui est voulu pour un revisionnage. Ce qui manquait, c'est l'avertissement : la ligne affichait « Vu le 20 sept. » et le `+` ajoutait quand même un log sans rien dire. Fait (PR 22) : le `+` sur une œuvre déjà loggée demande confirmation en rappelant la date, et « Logger à nouveau » reste à un bouton — un film revu, c'est bien deux logs sur la même fiche. |

## Founder — session du 2026-09-24 (où vit « où j'en suis »)

| Retour | Ce qu'on en a fait |
|---|---|
| « **Pour où j'en suis fais un nouvel onglet** » — puis, la question reposée plus tard dans la journée avec trois maquettes comparées (chip du Journal, quatrième onglet, bandeau de cartes), même réponse : **le quatrième onglet**, contre ma reco du bandeau. | Consigné dans le design (§ 2, § 4, § 6 q. 7) et dans le plan de la T2 (PR 16, qui était bloquée là-dessus). L'écran entier appartient à « En cours » : progression, prochain épisode, bouton pour avancer. **Deuxième fois que la founder choisit l'onglet contre une reco de chip ou de bandeau** (déjà pour Envie le 22/09) : dans cette app, une chose qui compte mérite sa place dans la barre, pas un filtre. J'en tiens compte pour les prochaines recos. |
| Conséquence non demandée, mais créée par ce choix : la barre comptera quatre onglets, et la Bibliothèque (T5) en ferait cinq. | Ouvert comme question 9 du design, **à trancher en T5, pas maintenant**. Pas de décision prise dans le dos. |
| Sur les épisodes spéciaux, que j'avais écartés : « et pourquoi on peut pas les mettre au sein des saisons ? » | Bonne question, vérifiée sur les vraies données avant de répondre : **TMDB ne dit jamais à quelle saison un spécial se rattache**. Il n'y a pas de champ pour ça, et le seul indice utilisable — la date de diffusion — manque pour **37 des 39** spéciaux de Friends. En français ils n'ont même pas de titre (« Épisode 3 »). Les intercaler serait une devinette. Décision founder : **une section « Spéciaux » en bas de la fiche**, cochable, jamais comptée comme « prochain épisode » (PR 13 pour la donnée, PR 14 pour l'écran). |

## Founder — session du 2026-09-27 (la Tranche 2 à l'usage)

Huit retours après trois jours d'usage des épisodes, plus deux réponses à mes questions. Aucun n'est une perte de données ; **un seul est un bug** (la zone tactile du Journal). Triés en sept PRs, de la plus agaçante au quotidien à la plus confortable.

| Retour | Ce qu'on en a fait |
|---|---|
| « Quand je clique sur une ligne ça ouvre pas la fiche, c'est uniquement si je clique sur l'image ou le titre » | **Bug.** `JournalRow` était la seule ligne des quatre écrans à ne pas déclarer sa zone tactile (`contentShape`) : SwiftUI ne comptait alors que les pixels dessinés — la jaquette, le titre — et ignorait les vides et la marge. Corrigé (PR 23). |
| « Quand je veux log une série, ça me met d'abord la série comme un film au lieu de direct m'afficher les épisodes pour que je dise ce que j'ai vu » | Le `+` d'un résultat créait un log « série vue » d'un bloc, comme pour un film. Corrigé (PR 25) : sur une **série**, le `+` ouvre sa fiche, qui s'ouvre elle-même sur « où j'en suis ». Logger une série en une ligne reste possible depuis le bouton « Logger » de la fiche — le plan de la T2 y tenait, une série peut rester une ligne unique. |
| « Quand je suis sur la fiche série je veux une option qui dit à quel épisode j'en suis genre en haut et j'appuie dessus et ça dit que j'ai vu cet épisode. » | Même PR (25) : une carte « Prochain : S2 E5 » en haut de la fiche, cochable d'un tap, avant les saisons dépliables. |
| « Et en vrai dans le journal aussi, comme dans en cours » | Le même bouton sur les lignes du Journal qui portent une série en cours (PR 27). |
| « Je veux ajouter une option qui dit j'ai vu toute une saison, où ça sélectionne tout d'un coup » | « Tout cocher » sur l'en-tête de saison (PR 24), et « jusqu'ici » rendu visible sur chaque épisode — voir la question ci-dessous. |
| « Dans en cours, quand je clique sur la série pour mettre l'épisode d'après on voit à peine que j'ai cliqué… si je misclick je m'en rends pas compte » | PR 26 : une barre de progression qui se remplit **avec animation**, et un retour haptique au tap. Le ✓ existait, la confirmation manquait. |
| « Quand je cherche les livres c'est bizarre… quand je tape Murakami je trouve rien de ce que je cherche. Et si je tape murakami kafka, je tombe pas du tout sur kafka sur le rivage. Je vois surtout un livre avec le titre en japonais et la couverture en espagnol. » | **Vérifié sur l'API réelle avant de répondre.** OpenLibrary trouve bien l'œuvre — `murakami kafka` renvoie `海辺のカフカ` en premier résultat, qui **est** Kafka sur le rivage : l'API donne le titre de l'**œuvre originale**, pas celui de l'édition française. Corrigé (PR 29) en demandant les éditions françaises (`language:fre` + sous-requête `editions`) : `murakami kafka` → **Kafka sur le Rivage** avec sa couverture française ; `murakami` → Danse danse danse, 1Q84 au lieu de l'autre Murakami (Ryū) ; `dune` → Le Messie de Dune, Les enfants de Dune. Même API, pas de clé, pas de compte. |
| « Quand je cherche un livre je peux pas dire en cours dans les boutons en haut. » | Rien ne permettait de dire « je le commence » sans passer par le formulaire : un livre ne pouvait pas entrer dans l'onglet « En cours ». Corrigé (PR 28). **Question posée, trois emplacements proposés ; founder : sur la fiche** (« Sur la fiche du livre »), pas dans la ligne de résultat — la ligne garde `+` et ♡. Le bouton vaut pour tous les types, pas seulement les livres. |
| « Maintenant je voudrais qu'on ajoute les podcasts et tout, c'est prévu pour quand ça ? » | Réponse honnête : **Tranche 4**, après l'import (T3) — quelques semaines, pas la prochaine chose. Ma reco : **les podcasts avant l'import**, juste après ces sept correctifs, puisqu'elle les demande et que son historique Trakt ne va nulle part. **Pas encore tranché** : à confirmer avant d'ouvrir la tranche suivante. |

### Mes deux questions, ses deux réponses

| Question | Réponse | Ce qu'on en a fait |
|---|---|---|
| L'onglet « En cours » est en troisième position. Est-ce là que ton pouce le cherche, ou plus à gauche ? | « Oui c'est bien. » | La barre reste **Journal · Envie · En cours · Recherche**. La question restée ouverte dans le plan de la T2 (PR 16) est close. |
| Sur un épisode, un appui long propose « Tout cocher jusqu'ici ». Tu l'as trouvé tout seul, ou il faut le rendre visible ? | « Ah non je ne l'avais pas trouvé faut le rendre visible, ça faisait d'ailleurs partie de mes retours enfin sur le toute une saison. » | **Un appui long n'existe pas s'il n'est pas annoncé.** « Jusqu'ici » devient un bouton visible sur la ligne d'épisode, et « Tout cocher » un bouton sur l'en-tête de saison (PR 24). Troisième fois que la découvrabilité tranche contre un geste caché (déjà l'appui long de l'Envie, retiré le 22/09). |

## Founder — session du 2026-09-30 (deux jours de podcasts, et le Journal qui double)

Huit retours après deux jours d'usage des podcasts, plus une demande de vérification : « vérifie que tous les retours que j'ai consigné ont bien été intégré ». Vérification faite, dans le code et pas seulement dans les docs : **les quinze retours du 23/09 et du 27/09 sont livrés**. Sur les huit nouveaux, **deux sont des bugs**, un est déjà corrigé depuis le 28/09 à midi, et cinq sont des décisions produit.

| Retour | Ce qu'on en a fait |
|---|---|
| « Quand je suis dans journal, tout est toujours dupliqué. Et là sur les épisodes ça me met une fois où j'ai mis ma note et une fois où j'ai mis que j'ai tout écouté… **une œuvre = une seule fiche dans le journal**. Ça me fait la même chose sur les séries. Pareil pour les livres et le reste en fait. Pareil les films. » | **Bug, et le plus gênant des huit.** Une ligne de Journal = un **log**, pas une œuvre. Cocher un épisode écrit un log « en cours » automatique (`source = "episodes"`), sa note en écrit un deuxième : deux lignes pour la même œuvre. Un film revu en fait deux aussi. La règle devient **une œuvre = une ligne**, la plus récente en tête, les autres logs restant visibles dans la fiche. **Troisième fois qu'elle demande la même chose** (23/09 : « on peut mettre sur la même fiche qu'on l'a revu ») — cette fois, sans ambiguïté. |
| « Quand je finis une saison, dans en cours, ça fait disparaître la série alors que ça devrait afficher la saison suivante. » | **Bug.** L'onglet « En cours » ne connaît que les saisons **déjà dépliées une fois** : les autres ne sont pas en base. Saison 1 finie, saison 2 jamais ouverte → plus de « prochain épisode », et le ✓ laisse place à « Terminé ». La fiche, elle, sait déjà passer à la saison suivante sans la charger (`nextEpisode` retombe sur la liste des saisons). Les deux écrans doivent répondre pareil. |
| « Quand je ferme l'onglet d'une saison je peux pas ajouter toute la saison, ou sur une série je peux pas dire j'ai tout vu toute la série quoi. Et si j'ai tout vu, ça doit me la mettre en terminé pas rester en cours. » | Trois choses, vérifiées : « J'ai vu toute la saison » n'existe que **saison dépliée** ; « toute la série » n'existe pas ; « terminé » est seulement **proposé**, et seulement au moment où on coche le dernier épisode de la dernière saison. Les trois se corrigent ensemble. |
| « Quand je clique pour log une série ou un podcast, faut me demander quel épisode directement, car je peux pas tout avoir vu d'un coup. » | **Déjà livré** (#42, 27/09) : le `+` d'une série **ou d'un podcast** ouvre sa fiche sur les épisodes au lieu de logger d'un bloc. Si elle ne le voit pas, c'est que son app date d'avant — à vérifier avec elle avant de recoder quoi que ce soit. |
| « Pour les podcasts, je vois pas les épisodes je vois que les noms des podcasts, y'a marqué que cette série n'est pas découpé chez tmdb d'ailleurs, alors que c'est pas tmdb la source… » | Deux choses. Le **message** est corrigé depuis le **28/09 à 12h** (#51, vocabulaire des podcasts) : un podcast sans épisode dit maintenant « Ce podcast n'a pas encore publié d'épisode, ou son flux ne les donne pas ». Les **épisodes manquants**, eux, sont le trou connu de la tranche : Apple ne publie pas les flux de Radio France (mesuré le 27/09, 10 podcasts sur 10). C'est la PR 34, qui attend cinq minutes d'inscription gratuite à Podcast Index de sa part. |
| « Dans les podcasts, ça s'organise pas par saison ? On pourrait le faire par année quand c'est pas rangé par saison ? Et ça doit rangé dans l'autre sens, là si je mets que j'ai écouté jusqu'ici ça me met les plus récents jusqu'à l'ancien et pas dans l'autre sens. » | Question posée avec une reco (garder le plus récent en haut, ne retourner que « jusqu'ici ») ; **founder : « je voulais comme sur les séries donc à l'envers »**. Donc : liste **du plus ancien au plus récent**, **regroupée par année** puisqu'un flux n'a pas de saison, et « jusqu'ici » coche l'épisode et tout ce qui le précède — la même règle que pour une série. |
| « Quand j'ouvre la fiche podcast je vois pas les épisodes, je suis pas obligée de commencer par le premier podcast tu vois ? Là ça m'oblige à dire je commence, mais y'a pas toujours d'ordre. » | La carte « Prochain épisode » s'affiche sur les podcasts alors que **le plan de la tranche disait de ne pas la mettre** (« on écoute un podcast par le plus récent, pas par le premier non écouté »). Écart entre le plan et le code, pas une décision : la carte est retirée des podcasts, elle reste sur les séries. |
| « En fait quelle différence entre logger et j'ai commencé. C'est bizarre. » | Elle a raison : la fiche affichait **Logger**, **Envie** et **Je le commence** — trois boutons dont deux écrivaient un log. Trois dispositions proposées avec maquettes (une ligne « Où j'en suis » à part — ma reco ; renommer les trois boutons ; supprimer « Je le commence »). **Founder : supprimer.** La fiche garde deux boutons, le statut se choisit dans le formulaire de log, où il est depuis la T1. **Inverse son propre retour du 27/09** (« je peux pas dire en cours dans les boutons en haut », #45) : elle perd le « je commence » en un tap, et l'a choisi en connaissance de cause — c'était écrit dans l'option. |

### Une question qui a ouvert une feature

« On est d'accord que c'est un flux et ça s'update quand y'a une nouvelle saison de série qui arrive ou quand y'a des episodes qui vont sortir bientôt ? »

**Non — et la question a trouvé un bug.** Le nombre de saisons d'une série n'était récupéré qu'une fois et jamais revu : avec le « terminé » automatique, une série finie serait restée finie pour toujours, même après la sortie d'une saison suivante. Corrigé dans la PR 40 : la fiche réapprend le compte à chaque ouverture.

Reste ce qu'elle demandait vraiment : **être prévenue**. « Ah oui j'ai pas prévu l'option mais faudrait qu'on l'ajoute quoi. » Deux formes proposées, avec leur promesse réelle — iOS ne réveille une app fermée que quand ça l'arrange, une vraie notification demanderait le serveur de la T6. Founder : le rafraîchissement à l'ouverture, pas la notification.

Puis, sur ma maquette de bandeau « du nouveau » en haut de l'onglet : **« pourquoi tu veux faire un bandeau ? c'est pas dans suivi que ça apparaît juste quand y'a une suite ? »** — et elle a raison. Un bandeau, c'est un deuxième endroit à consulter pour une information qui a déjà son écran. **Retenu : pas de bandeau.** Une série dont une saison sort **réapparaît dans « En cours »**, comme n'importe quelle série suivie. Plan : `docs/plans/nouvelles-saisons.md`.

**Quatrième fois qu'elle simplifie une de mes propositions d'écran** (chip → onglet Envie le 22/09, bandeau → onglet « En cours » le 24/09, geste caché → bouton visible le 27/09, et ici bandeau → l'onglet existant). La leçon tient en une phrase : **quand une information a déjà un écran qui lui va, elle n'a pas besoin du sien.**

### Ce que cette session a appris sur la méthode

**Un plan qui dit « pas ça » doit être relu à la fin de la PR, pas seulement au début.** La carte « Prochain épisode » sur les podcasts et l'ordre de la liste étaient tous les deux écrits noir sur blanc dans `docs/plans/podcasts.md` — et tous les deux livrés à l'envers de ce qui y était écrit. Le plan avait raison sur la carte, tort sur l'ordre : ce n'est pas le plan qui a manqué, c'est la relecture du plan contre le diff.

## Founder — session du 2026-10-03 (deux jours sur l'iPhone, après les correctifs)

Cinq retours après avoir vécu avec la version installée le 01/10. **Deux causes pour les cinq**, et aucune n'était visible en test.

| Retour | Ce qu'on en a fait |
|---|---|
| « Il n'y a plus le petit truc satisfaisant quand je valide que j'ai vu ou écouté un épisode… ça le fait sur Dix pour cent ou Peaky Blinders, mais pas sur Arrested Development ou Transfert. J'ai ajouté une série, ça le fait bien. Sur un nouveau podcast, cela fonctionne aussi. » | **Ses exemples étaient le diagnostic.** Le retour haptique était accroché à une **valeur affichée** (la position dans la saison) : muet sur **Transfert**, parce qu'un podcast n'a plus de barre de progression depuis la #63 ; muet sur **Arrested Development**, parce que cocher son dernier épisode la terminait et la faisait **quitter la liste** — la ligne disparaissait avant d'avoir vibré. Dix pour cent et Peaky Blinders, au milieu d'une saison, marchaient. Corrigé (#70) : le déclencheur suit le **geste**, pas la donnée, et vit au niveau de l'écran. |
| « Ça fait pas la vibration quand c'est le dernier épisode. » | Même cause, et c'est le cas le plus net : la ligne part, le retour partait avec elle. |
| « Sur tous les boutons en fait, je voudrais la même petite vibration satisfaisante. » | Fait (#70) : cocher, tout cocher, toute la série, abandonner, reprendre, Logger, Envie, et le `+` comme le ♡ de la recherche. Un geste qui n'écrit rien ne vibre pas. |
| « Petit bug quand je veux cliquer sur "tout décocher"… ça a mis beaucoup de temps pour tout décocher. » | **Ce n'était pas la quantité de données, c'était le nombre d'écritures** : une par épisode. Corrigé (#69) : une seule écriture par geste, et quatre tests qui **comptent les écritures** plutôt que de chronométrer. |
| « Ça lag quand je veux enregistrer les podcasts tout d'un coup. » | Même cause, en pire : « J'ai tout écouté » sur un flux de 96 épisodes, c'était 96 enregistrements à la suite. |

**Ce que cette session apprend.** Aucun de ces cinq retours n'est sorti d'une relecture de code ni d'un test — la suite était verte à 600 tests. Ils sont sortis de **deux jours d'usage**. Et quand elle donne des exemples qui marchent **et** des exemples qui ne marchent pas, ces exemples discriminent la cause : il faut chercher ce qui les sépare avant de lire le code au hasard.

## Autres utilisatrices

*(vide — à remplir dès le premier TestFlight)*
