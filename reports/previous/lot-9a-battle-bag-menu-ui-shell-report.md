# Lot 9a — Battle BAG Menu UI Shell Report

## 1. Résumé exécutif honnête

Le lot 9a est fermé côté `packages/map_runtime`.

Le bouton `BAG` du root menu battle ouvre maintenant un vrai sous-menu inspectable et testable, construit à partir du contrat pur `BattleBagMenuModel` du lot 8a. Le sous-menu affiche les items du sac, leurs quantités, leur type court et leur état disponible ou grisé. En tour libre, le retour arrière ramène au root menu. En remplacement forcé, le comportement lot 7 reste prioritaire et le menu `POKÉMON` forcé continue de bloquer tout retour vers `BAG`/`FIGHT`/`RUN`.

Le lot reste volontairement borné :

- aucun objet n’est consommé ;
- aucune capture n’est appliquée ;
- aucun `PlayerBattleChoiceCapture` n’est dispatché depuis `BAG` ;
- aucune mutation `GameState` n’est faite depuis l’overlay ;
- aucun fichier `map_battle` n’a été touché.

## 2. État git initial exact

### `git status --short --untracked-files=all`

```text
 M packages/map_editor/lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart
 M packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
 M packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart
 M packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart
 M packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
?? reports/lot-8f-moves-external-sync-workspace-ux-report.md
```

### `git diff --stat`

```text
 .../pokemon_moves_workspace_providers.dart         |  30 +++
 .../sync_pokemon_moves_catalog_use_case.dart       | 147 ++++++++----
 .../moves_catalog_workspace.dart                   | 253 +++++++++++++++++++--
 .../pokemon_moves_catalog_workspace_ui_test.dart   | 225 ++++++++++++++++++
 .../sync_pokemon_moves_catalog_use_case_test.dart  | 109 +++++++++
 5 files changed, 694 insertions(+), 70 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/lot-8f-moves-external-sync-workspace-ux-report.md
```

### Classification honnête

- `preexisting_in_scope`: aucun
- `preexisting_out_of_scope`:
  - `packages/map_editor/lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart`
  - `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
  - `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
  - `packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart`
  - `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`
  - `reports/lot-8f-moves-external-sync-workspace-ux-report.md`
- `created_by_this_lot`: aucun au démarrage
- `modified_by_this_lot`: aucun au démarrage

## 3. Fichiers lus

- `reports/lot-8a-battle-bag-menu-contract-report.md`
- `reports/lot-7-battle-pokemon-menu-end-to-end-report.md`
- `reports/lot-8e-items-pokeapi-sync-sprite-cache-report.md`
- `reports/lot-8f-moves-external-sync-workspace-ux-report.md`
- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `packages/map_runtime/test/battle_bag_menu_model_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `AGENTS.md`

## 4. Fichiers modifiés/créés

### Modifiés

- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`

### Créé

- `reports/lot-9a-battle-bag-menu-ui-shell-report.md`

## 5. Fichiers volontairement non touchés

- `packages/map_battle/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- `examples/playable_runtime_host/**`
- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_party_menu_model.dart`

## 6. Comportement obtenu

- Le root menu battle garde `FIGHT / BAG / POKÉMON / RUN`.
- En tour libre, `BAG` est désormais inspectable même si aucune capture n’est autorisée.
- Valider `BAG` ouvre un vrai sous-menu battle BAG.
- Le sous-menu affiche les entrées visibles du sac normalisé.
- Chaque entrée affiche :
  - un label humain lisible ;
  - la quantité ;
  - un type court (`Capture`, `Medicine`, `Unsupported`) ;
  - un état (`OK`, `Trainer battle`, `Not implemented`, `Unsupported item`, etc.).
- Un sac vide ouvre un état stable avec prompt `Sac vide.`.
- Les items disabled restent visibles et grisées.
- Le retour arrière depuis `BAG` revient au root seulement en tour libre.
- En remplacement forcé, le menu `POKÉMON` lot 7 reste prioritaire et `BAG` ne devient pas une échappatoire.
- Valider une Poké Ball sélectionnable n’applique rien dans ce lot ; l’UI affiche seulement un message sobre indiquant que l’utilisation des objets viendra au lot suivant.

## 7. Détails d’intégration du `BattleBagMenuModel`

Le contrat pur du lot 8a a été consommé tel quel via :

```dart
buildBattleBagMenuModel({
  required GameState gameState,
  required BattleSession session,
})
```

Décision d’intégration retenue :

- le `GameState` runtime courant est passé en lecture seule à `BattleOverlayComponent` ;
- le modèle BAG est reconstruit dans l’overlay à partir de `BattleSession + GameState` ;
- `BattleCommandPanelComponent` reçoit ensuite un `BattleBagMenuModel` prêt à rendre.

Pourquoi ce choix :

- pas de duplication de la logique métier du bag dans l’UI ;
- pas de reparse manuel du sac dans le composant Flame ;
- blast radius limité à `map_runtime` ;
- `updateState(...)` peut rafraîchir la source BAG quand la session ou le `GameState` changent.

Deux seams supplémentaires ont été nécessaires et justifiés :

- `battle_command_menu_model.dart`
  - pour corriger la vérité du root menu et rendre `BAG` inspectable en tour libre sans dépendre des choix capture ;
- `playable_map_game.dart`
  - pour injecter le `GameState` runtime courant en lecture seule dans l’overlay et lors des refreshs `updateState(...)`.

## 8. Preuve que rien n’est consommé ou appliqué

Ce lot ne dispatch jamais d’action item battle :

- le mode `BAG` n’expose plus de `choiceEntries` moteur dans `BattleCommandMenuModel` ;
- `BattleOverlayComponent.getSelectedChoice()` retourne `null` quand le mode courant est `BAG` ;
- `BattleOverlayComponent.validateSelectedChoice()` intercepte le mode `BAG` et ne passe jamais par `onPlayerChoice(...)` ;
- `_handleBagEntrySelected(...)` ne fait qu’afficher un message local :
  - `L’utilisation des objets sera branchée au prochain lot.`

Il n’y a donc dans ce lot :

- ni `PlayerBattleChoiceCapture` dispatché ;
- ni soin ;
- ni mutation du sac ;
- ni mutation de `GameState` depuis l’overlay ;
- ni outcome capture.

## 9. Tests ajoutés et ce qu’ils prouvent

### `packages/map_runtime/test/battle_command_menu_component_test.dart`

- `trainer root keeps BAG enabled for inspection and RUN disabled when those choices are absent`
  - prouve que `BAG` n’est plus dépendant de la capture pour être inspectable.
- `battle bag submenu opens from root BAG when bag can be inspected`
  - prouve l’ouverture du sous-menu et l’affichage d’une Poké Ball avec quantité.
- `battle bag submenu renders disabled medicine and unsupported items`
  - prouve la visibilité et le grisé des items non utilisables.
- `battle bag submenu keeps poke ball visible but disabled in trainer battle`
  - prouve la visibilité de la Poké Ball avec raison disabled lisible.
- `battle bag submenu handles an empty bag`
  - prouve l’état vide stable sans crash.
- `battle bag submenu layout survives portrait and landscape`
  - prouve la robustesse responsive du rendu BAG.

### `packages/map_runtime/test/battle_overlay_component_test.dart`

- `root BAG opens the battle bag submenu without dispatching a battle choice`
  - prouve qu’ouvrir `BAG` ne dispatch rien vers le moteur.
- `selecting a capture-capable poke ball does not apply capture in lot 9a`
  - prouve qu’une Poké Ball sélectionnable n’applique toujours aucune capture.
- `updateState refreshes bag menu source`
  - prouve que l’overlay reconstruit bien la source BAG quand son `GameState` change.
- `forced replacement opens party menu and does not allow backing out to invalid root actions`
  - renforcé pour vérifier que `BAG` reste inaccessible pendant le remplacement forcé.

## 10. Validations exécutées avec résultats

### Analyse ciblée

Commande exécutée :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/presentation/flame/battle_bag_menu_model.dart \
  lib/src/presentation/flame/battle_party_menu_model.dart \
  lib/src/presentation/flame/battle_command_menu_model.dart \
  lib/src/presentation/flame/battle_command_panel_component.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  test/battle_bag_menu_model_test.dart \
  test/battle_party_menu_model_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_overlay_component_test.dart
```

Résultat :

```text
No issues found! (ran in 2.9s)
```

### Tests ciblés et smokes runtime

Commande exécutée :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter test \
  test/battle_bag_menu_model_test.dart \
  test/battle_party_menu_model_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_overlay_component_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Résultat :

```text
All tests passed!
```

### TDD ciblé intermédiaire

Commande exécutée avant implémentation complète :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter test test/battle_command_menu_component_test.dart --plain-name 'battle bag submenu opens from root BAG when bag can be inspected'
```

Résultat :

- échec de compilation attendu ;
- absence du paramètre `gameState` dans `BattleOverlayComponent` ;
- getters BAG absents dans `BattleCommandPanelComponent`.

Cette exécution a servi de rouge initial réel pour le lot 9a.

## 11. Limites assumées

- Les objets restent purement inspectables ; aucune action BAG battle n’est branchée.
- Une Poké Ball sélectionnable n’applique pas encore la capture.
- Les medicine/unsupported ne font qu’afficher un état disabled ; aucun soin n’est branché.
- Le rendu BAG reste textuel ; aucun sprite d’item n’est affiché.
- Les labels item sont humanisés localement depuis `itemId`, sans catalogue editor.

## 12. Ce qui est reporté au lot 9b

- dispatch réel d’une Poké Ball vers `PlayerBattleChoiceCapture`
- application réelle de la capture côté flow runtime
- éventuelle consommation d’objet au moment adéquat
- copie produit plus précise sur les cas capture
- éventuelle différenciation plus fine des objets utilisables ultérieurement

## 13. Retour de review séparée

Une review séparée a bien été lancée via un agent dédié.

Retour reçu :

- `No findings.`
- vérification explicite :
  - BAG inspect-only en `BattleTurnChoiceRequest`
  - aucun dispatch depuis les entrées BAG
  - refresh du modèle BAG sur `updateState(..., gameState: ...)`
  - validations ciblées passantes

Point de vigilance remonté, sans finding formel :

- les nouveaux tests ne pinent pas directement tous les cas `continue/wait` côté accessibilité BAG runtime ;
- le reviewer a toutefois jugé la logique actuelle cohérente et n’a pas remonté de régression concrète.

## 14. État git final exact

### `git status --short --untracked-files=all`

```text
 M packages/map_editor/lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart
 M packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
 M packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart
 M packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart
 M packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/battle_command_menu_component_test.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
?? reports/lot-8f-moves-external-sync-workspace-ux-report.md
?? reports/lot-9a-battle-bag-menu-ui-shell-report.md
```

### `git diff --stat`

```text
 .../pokemon_moves_workspace_providers.dart         |  30 ++
 .../sync_pokemon_moves_catalog_use_case.dart       | 147 +++++---
 .../moves_catalog_workspace.dart                   | 253 +++++++++++--
 .../pokemon_moves_catalog_workspace_ui_test.dart   | 225 ++++++++++++
 .../sync_pokemon_moves_catalog_use_case_test.dart  | 109 ++++++
 .../flame/battle_command_menu_model.dart           |  28 +-
 .../flame/battle_command_panel_component.dart      | 395 ++++++++++++++++++++-
 .../flame/battle_overlay_component.dart            | 172 ++++++++-
 .../src/presentation/flame/playable_map_game.dart  |  15 +-
 .../test/battle_command_menu_component_test.dart   | 277 ++++++++++++++-
 .../test/battle_overlay_component_test.dart        | 169 +++++++++
 11 files changed, 1700 insertions(+), 120 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/lot-8f-moves-external-sync-workspace-ux-report.md
reports/lot-9a-battle-bag-menu-ui-shell-report.md
```

### Classification finale

- `preexisting_out_of_scope` conservé inchangé :
  - `packages/map_editor/lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart`
  - `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
  - `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
  - `packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart`
  - `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`
  - `reports/lot-8f-moves-external-sync-workspace-ux-report.md`
- `modified_by_this_lot` :
  - `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - `packages/map_runtime/test/battle_command_menu_component_test.dart`
  - `packages/map_runtime/test/battle_overlay_component_test.dart`
- `created_by_this_lot` :
  - `reports/lot-9a-battle-bag-menu-ui-shell-report.md`

## 15. Décision finale

Lot 9a réussi.

Le BAG battle existe maintenant comme shell UI inspectable et testable, prêt pour le lot 9b qui branchera la capture réelle depuis une Poké Ball.
