# Lot 7a — Battle Party Switch Contract Report

## 1. Résumé exécutif honnête

Le lot 7a est réussi dans le périmètre demandé. Un contrat pur et testable existe maintenant côté `map_runtime` pour représenter l’équipe battle du joueur dans le contexte du futur menu `POKÉMON`, sans ouvrir le rendu UI, sans appliquer de switch, et sans toucher à `map_battle`.

Le modèle créé sait :
- exposer le Pokémon actif et les réserves ;
- distinguer `switch volontaire`, `remplacement forcé` et `état non actionnable` ;
- dire quelles entrées sont sélectionnables ;
- dire pourquoi une entrée est grisée ;
- associer une entrée sélectionnable à un vrai `PlayerBattleChoiceSwitch(reserveIndex)` déjà autorisé par la `BattleDecisionRequest` courante ;
- préserver correctement les `reserveIndex` battle.

## 2. État git initial

Pré-gates réellement exécutés avant modification :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultats initiaux :

### `git status --short --untracked-files=all`

```text
?? examples/.DS_Store
```

### `git diff --stat`

```text
<aucune différence suivie>
```

### `git ls-files --others --exclude-standard`

```text
examples/.DS_Store
```

Conclusion honnête :
- le code du repo était propre avant le lot ;
- un seul untracked préexistant hors scope était présent : `examples/.DS_Store`.

## 3. Fichiers lus

Reports :
- `reports/lot-5-trainer-difficulty-behavior-lift-report.md`
- `reports/lot-6-trainer-voluntary-switch-behavior-lift-report.md`

Battle :
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/test/battle_decision_request_test.dart`
- `packages/map_battle/test/battle_switch_test.dart`

Runtime :
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`

Skills relus pour cadrer la méthode :
- `superpowers:brainstorming`
- `superpowers:test-driven-development`
- `superpowers:writing-plans`

## 4. Fichiers modifiés

Créés :
- `packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart`
- `packages/map_runtime/test/battle_party_menu_model_test.dart`
- `reports/lot-7a-battle-party-switch-contract-report.md`

Aucun fichier existant du runtime UI, du battle-core, de l’editor, du core ou du host n’a été modifié.

## 5. Fichiers volontairement non touchés

Volontairement non touchés pour garder le lot 7a petit et pur :
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- tout `packages/map_battle/**`
- tout `packages/map_core/**`
- tout `packages/map_editor/**`
- tout `packages/map_gameplay/**`
- tout `examples/playable_runtime_host/**`

Justification :
- le lot 7a ne doit pas ouvrir le rendu du menu `POKÉMON` ;
- le moteur expose déjà la vérité nécessaire via `BattleSession.decisionRequest` et `BattleState`.

## 6. Description du contrat créé

Le contrat créé vit dans :
- `packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart`

Surface exposée :

### `BattlePartyMenuMode`
- `voluntarySwitch`
- `forcedReplacement`
- `unavailable`

### `BattlePartyMenuDisabledReason`
- `activePokemon`
- `fainted`
- `notAllowedByCurrentRequest`
- `noSwitchAvailable`

### `BattlePartyMenuEntry`
- `visualIndex`
- `reserveIndex`
- `speciesId`
- `level`
- `currentHp`
- `maxHp`
- `isActive`
- `isFainted`
- `isSelectable`
- `disabledReason`
- `playerChoice`

### `BattlePartyMenuModel`
- `mode`
- `activeEntry`
- `reserveEntries`
- `allEntries`
- `hasSelectableEntries`

### Construction

Le modèle est construit via :

```dart
buildBattlePartyMenuModel({
  required BattleSession session,
})
```

La source de vérité retenue est volontairement une vraie `BattleSession`, parce que :
- elle porte déjà l’état battle observable ;
- elle porte déjà la `BattleDecisionRequest` typée ;
- elle évite qu’un contrat UI local diverge de la légalité moteur.

Le modèle ne synthétise jamais de switch de lui-même. Il reprend seulement les `PlayerBattleChoiceSwitch` déjà présents dans la request courante.

## 7. Différence claire entre active, reserveIndex, visualIndex et partyIndex

### `active`
- c’est le Pokémon actuellement actif dans `BattleState.player`
- il est visible dans le modèle
- il n’a pas de `reserveIndex`
- il n’est jamais sélectionnable

### `reserveIndex`
- c’est l’index battle courant dans `BattleState.playerReserve`
- c’est exactement ce que consomme `PlayerBattleChoiceSwitch(reserveIndex)`
- c’est la vraie donnée de mapping moteur

### `visualIndex`
- c’est l’ordre d’affichage du menu party battle
- dans ce lot, il vaut :
  - `0` pour l’actif
  - `1..n` pour les réserves dans l’ordre d’affichage
- il ne doit jamais être confondu avec `reserveIndex`

### `partyIndex`
- ce contrat n’en invente pas
- le moteur battle ne travaille pas en index global de party ; il travaille en actif + réserve battle courante
- le lot 7a évite donc volontairement de projeter un faux `partyIndex` qui n’est pas une vérité moteur ici

Exemple concret :
- actif visuel = `visualIndex 0`, `reserveIndex null`
- première réserve visuelle = `visualIndex 1`, `reserveIndex 0`
- deuxième réserve visuelle = `visualIndex 2`, `reserveIndex 1`

Donc choisir la deuxième réserve affichée doit produire `PlayerBattleChoiceSwitch(1)`, jamais `2`.

## 8. Tests ajoutés et ce qu’ils prouvent

Nouveau fichier :
- `packages/map_runtime/test/battle_party_menu_model_test.dart`

Tests ajoutés :

1. `turn libre avec réserve valide expose un switch sélectionnable`
- prouve que le mode est `voluntarySwitch`
- prouve que l’actif est visible mais non sélectionnable
- prouve qu’une réserve valide expose bien `PlayerBattleChoiceSwitch(0)`

2. `tour libre avec réserve K.O. garde les entrées visibles mais grisées`
- prouve qu’une réserve K.O. reste visible
- prouve qu’elle est grisée avec la raison `fainted`
- prouve qu’aucun faux choix invalide n’est exposé

3. `remplacement forcé après K.O. expose seulement les switches valides`
- prouve le mode `forcedReplacement`
- prouve que l’actif K.O. reste visible
- prouve qu’une réserve valide reste sélectionnable
- prouve que le modèle n’expose pas d’autre action moteur

4. `remplacement forcé garde les reserveIndex exacts quand une réserve précédente est K.O.`
- prouve le cas anti-confusion d’index en forced replacement
- prouve qu’une réserve saine peut rester `reserveIndex 1` si une réserve précédente est K.O.

5. `continue request rend le modèle non actionnable`
- prouve qu’un `BattleContinueRequest` ne rend aucune entrée sélectionnable
- prouve que le modèle reste consumable sans inventer de switch

6. `équipe avec seulement l’actif ne crash pas et reste non actionnable`
- prouve le cas limite sans réserve

7. `anti-confusion d’index garde le reserveIndex battle exact`
- prouve explicitement que la deuxième réserve affichée produit `PlayerBattleChoiceSwitch(1)` et non l’index visuel global

### Rouge avant implémentation

Avant l’implémentation, la suite rouge échouait à la compilation pour les bonnes raisons :
- fichier `battle_party_menu_model.dart` absent ;
- symboles `BattlePartyMenuMode`, `BattlePartyMenuDisabledReason` et `buildBattlePartyMenuModel(...)` absents.

## 9. Validations exécutées avec résultats

### Rouge initial

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/battle_party_menu_model_test.dart
```

Résultat :
- rouge
- erreurs de compilation attendues sur l’absence du modèle pur

### Format

```bash
cd /Users/karim/Project/pokemonProject
dart format \
  packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart \
  packages/map_runtime/test/battle_party_menu_model_test.dart
```

Résultat :
- vert

### Analyze ciblé

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze --no-pub \
  lib/src/presentation/flame/battle_party_menu_model.dart \
  test/battle_party_menu_model_test.dart
```

Résultat :
- vert
- `No issues found!`

### Tests ciblés du lot

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test test/battle_party_menu_model_test.dart
```

Résultat :
- vert
- 7 tests passés

### Smoke minimal existant

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test \
  test/battle_command_menu_component_test.dart \
  test/battle_overlay_component_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
```

Résultat :
- vert
- aucune régression constatée sur la battle UI/runtime existante

### `map_battle`

Non relancé volontairement.

Justification :
- aucun fichier `map_battle` n’a été touché ;
- le lot 7a reste strictement dans `map_runtime`.

## 10. Limites assumées

Limites assumées de ce lot :
- aucun rendu UI du menu `POKÉMON` n’est ouvert ;
- aucun clic, focus ou navigation n’est branché ;
- aucune action n’est appliquée ;
- aucun `partyIndex` global n’est synthétisé ;
- aucune info décorative supplémentaire n’est ajoutée ;
- le contrat ne traite pas encore le bag, le résumé Pokémon, les sprites, ni les animations.

Le lot prépare explicitement le lot 7b sans mélanger les responsabilités :
- 7a = vérité pure, index corrects, grisage correct, action moteur correcte ;
- 7b = consommation UI.

## 11. État git final

### `git status --short --untracked-files=all`

```text
?? examples/.DS_Store
?? packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart
?? packages/map_runtime/test/battle_party_menu_model_test.dart
```

### `git diff --stat`

```text
<aucune différence suivie>
```

Explication honnête :
- ce lot n’a créé que des fichiers nouveaux non trackés ;
- il n’a modifié aucun fichier déjà suivi.

### `git ls-files --others --exclude-standard`

```text
examples/.DS_Store
packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart
packages/map_runtime/test/battle_party_menu_model_test.dart
```

## 12. Décision finale nette

**Lot 7a réussi — le menu Pokémon battle dispose maintenant d’un contrat pur, testable, prêt à être consommé par l’UI du lot 7b.**

Ce qui est vrai maintenant :
- le contrat pur existe ;
- les cas `switch volontaire`, `remplacement forcé` et `état non actionnable` sont couverts ;
- les `reserveIndex` battle sont prouvés corrects ;
- aucun rendu UI n’a été ouvert ;
- aucun switch n’est appliqué ;
- aucun package hors `map_runtime` n’a été touché.
