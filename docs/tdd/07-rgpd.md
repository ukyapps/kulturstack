---
type: tdd
statut: accepté
créé: 2026-09-20
---

# 07 — RGPD et vie privée

Un historique de consommation culturelle est une **donnée personnelle** (goûts, habitudes, parfois opinions ou orientation — livres, films militants, lieux fréquentés). Local-first n'exempte pas : il simplifie.

## Ce qui sort de l'appareil en Tranche 1

| Flux | Destinataire | Données | Base légale / remarque |
|---|---|---|---|
| Recherche | TMDB (US) | le texte tapé + IP + User-Agent | nécessaire au service ; aucune donnée de compte |
| Recherche | OpenLibrary / Internet Archive (US) | idem + email de contact de l'app dans le User-Agent (pas celui de l'utilisatrice) | idem |
| Images | image.tmdb.org, covers.openlibrary.org | URL d'affiche + IP | idem |

**Rien d'autre.** Pas d'analytics, pas de crash reporter tiers, pas de compte, pas de sync. Les logs, notes, dates ne quittent jamais l'iPhone (hors sauvegarde iCloud de l'appareil, gérée par Apple et chiffrée).

## Obligations concrètes (T1)

1. **`PrivacyInfo.xcprivacy`** (manifeste Apple, obligatoire) : `NSPrivacyTracking = false`, aucun type de données collectées, API `UserDefaults` déclarée avec la raison `CA92.1`.
2. **Étiquette App Store** : « Données non collectées ».
3. **Écran À propos / Confidentialité** dans Réglages, en FR et EN : ce qui part, vers qui, et le fait que tout le reste est local. Deux paragraphes, pas un pavé juridique.
4. **Suppression** : « Tout effacer » dans Réglages, **en Release aussi** (distinct du bouton DEBUG de seed), avec confirmation. Droit à l'effacement = un bouton.
5. **Portabilité** : export JSON complet de la base (fiches + logs + possessions) — prévu en **T3** avec l'import, parce que c'est le même code de sérialisation. Droit à la portabilité = un bouton.
6. **Aucune donnée dans les logs de debug** en Release (`os.Logger` avec `privacy: .private` sur titres et notes).

## Quand ça se complique

| Tranche | Changement | À faire |
|---|---|---|
| 6-7 | Proxy Supabase | héberger en **région UE** ; le proxy ne journalise pas les requêtes au-delà du strict comptage ; DPA Supabase signé ; mettre à jour l'écran Confidentialité |
| 7 | LLM (Anthropic) | les titres saisis pour théâtre/expos sont envoyés à un tiers → le dire explicitement, et ne jamais envoyer les notes personnelles ni l'historique complet |
| 7 (social) | Comptes + sync | vrai traitement : registre, politique de confidentialité complète, consentement, chiffrement au repos, suppression de compte en cascade. **C'est le gros morceau — et c'est pour ça que le social est dernier.** |

## Red flag à signaler

Toute proposition d'ajouter un SDK d'analytics, de crash reporting ou de pub « pour voir » en T1-T5 doit être refusée par défaut et discutée en ADR.
