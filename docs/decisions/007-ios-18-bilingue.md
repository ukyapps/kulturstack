# ADR-007 — iOS 18.0 minimum, iPhone only, FR + EN dès la PR 1

- Statut : **accepted**
- Date : 2026-09-20

## Contexte

Le cadrage de juillet visait iOS 17.0 (référence Mealkin). SwiftData y est fragile sur exactement ce que Kulturstack utilise : migrations (ADR-003), contraintes `unique` (ADR-004), relations. iOS 26 vient de sortir (sept. 2026) et abandonne XS/XR.

## Décision

- **iOS 18.0** : bugs SwiftData corrigés ; ~90 % du parc actif ; Kulturstack n'a aucune utilisatrice à protéger, c'est le moment de choisir.
- **iPhone uniquement** (`TARGETED_DEVICE_FAMILY: "1"`).
- **FR (référence) + EN** via `Localizable.xcstrings` dès la première PR. Coût jour 1 quasi nul (toutes les strings passent déjà par le catalogue) ; rattrapage = chantier.

## Conséquences

- `deploymentTarget: iOS 18.0`, `developmentLanguage: fr` dans `project.yml`.
- Swift Testing disponible (Xcode 16+).
- Chaque PR qui ajoute une string ajoute sa traduction EN.
