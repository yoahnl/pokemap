# Lot 9b — Battle BAG Capture Wiring Report

## 1. Résumé exécutif honnête

Le lot 9b a été implémenté minimalement côté `map_runtime` : la sélection d'une Poké Ball réellement capturable dans le sous-menu `BAG` dispatch maintenant le vrai `PlayerBattleChoiceCapture` au callback battle existant. Les medicines et items unsupported restent non actionnables.

La fermeture complète du lot reste toutefois bloquée par une casse de compilation préexistante hors scope entre `map_core`, `map_gameplay` et certaines zones de `map_runtime`. Les validations demandées n'ont donc pas pu passer au vert, malgré un patch 9b ciblé et une review séparée sans finding.

## 2. État git initial exact

### `git status --short --untracked-files=all`

```text
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
```

### `git diff --stat`

```text
 .../test/battle_overlay_component_test.dart        |  93 +++++++++-
 .../test/wild_battle_end_to_end_flow_test.dart     | 201 +++++++++++++++++++++
 2 files changed, 288 insertions(+), 6 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
```

## 3. Classification de la dirtiness initiale

- `preexisting_in_scope`
  - `packages/map_runtime/test/battle_overlay_component_test.dart`
  - `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `preexisting_out_of_scope`
  - aucune dirtiness détectée au démarrage
- `created_by_this_lot`
  - `reports/lot-9b-battle-bag-capture-wiring-report.md`
- `modified_by_this_lot`
  - `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - modifications supplémentaires sur les deux fichiers de test déjà dirty

## 4. Fichiers lus

- `reports/lot-9a-battle-bag-menu-ui-shell-report.md`
- `reports/lot-8a-battle-bag-menu-contract-report.md`
- `reports/lot-7-battle-pokemon-menu-end-to-end-report.md`
- `packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/test/battle_bag_menu_model_test.dart`
- `packages/map_runtime/test/battle_command_menu_component_test.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/models/element_collision_profile.dart`
- `packages/map_core/lib/src/models/element_collision_profile.g.dart`

## 5. Fichiers modifiés/créés

- modifié : `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- modifié : `packages/map_runtime/test/battle_overlay_component_test.dart`
- modifié : `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- créé : `reports/lot-9b-battle-bag-capture-wiring-report.md`

## 6. Fichiers volontairement non touchés

- `packages/map_battle/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_command_panel_component.dart`

## 7. Comportement obtenu

- Une entrée `BAG` portant une vraie `BattleBagMenuActionCapture` route maintenant son `PlayerBattleChoiceCapture` vers `onPlayerChoice(...)`.
- Les autres entrées `BAG` restent non destructives.
- Les entries BAG disabled continuent de ne rien dispatcher.
- Le shell BAG lot 9a n'a pas été réécrit.

## 8. Décision sur la consommation de Poké Ball

La consommation n'a pas été réimplémentée dans l'overlay. L'audit a montré qu'elle existait déjà proprement dans `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart` via `_consumeOnePokeBallOrThrow(...)` lors de l'application d'un outcome `captured`.

Décision prise : réutiliser ce seam existant et ne rien dupliquer dans l'UI.

## 9. Décision sur le write-back du Pokémon capturé

L'audit a montré que `applyRuntimeBattleOutcomeToGameState(...)` gérait déjà :

- le refus de capture en trainer battle ;
- le refus quand la party est pleine ;
- l'ajout du Pokémon capturé à la party ;
- la mise à jour `seen/caught` ;
- la consommation d'une Poké Ball.

Décision prise : ne pas modifier ce write-back, seulement brancher le dispatch BAG vers le flux runtime déjà existant.

## 10. Tests ajoutés et ce qu’ils prouvent

### `packages/map_runtime/test/battle_overlay_component_test.dart`

- `selecting a capture-capable poke ball dispatches PlayerBattleChoiceCapture`
  - prouve le nouveau dispatch runtime depuis le sous-menu BAG
  - vérifie que l'overlay ne mute pas directement la session
- `selecting disabled poke ball in trainer battle does not dispatch capture`
  - prouve que les Poké Balls grisées en trainer battle ne dispatchent rien
- `selecting medicine from battle bag does not dispatch a battle choice`
  - prouve que les medicines restent non branchées en 9b

### `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

- `wild battle can capture from BAG poke ball and return to overworld`
  - vise à prouver le flow complet BAG -> capture -> outcome -> retour overworld
- `wild battle BAG capture does not work when party is full`
  - vise à prouver le garde-fou party pleine déjà annoncé par le modèle BAG

Ces deux tests ont été écrits, mais pas exécutés avec succès à cause du blocage compile hors lot décrit ci-dessous.

## 11. Validations exécutées avec résultats

### Workaround tooling local

Commande exécutée :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
rm -rf build/native_assets
```

Raison :

- premier `flutter test` bloqué par un souci local natif Flutter/macOS autour de `lipo` dans `build/native_assets`
- suppression limitée à un artefact généré

### Test ciblé overlay

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart
```

Résultat :

- échec de compilation hors lot
- causes visibles :
  - `packages/map_core/lib/src/models/element_collision_profile.g.dart` désynchronisé par rapport à `element_collision_profile.dart`
  - usages downstream cassés de `ElementCollisionPixelMask` / `collisionMask`

### Analyse demandée par le prompt

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/presentation/flame/battle_bag_menu_model.dart \
  lib/src/presentation/flame/battle_command_menu_model.dart \
  lib/src/presentation/flame/battle_command_panel_component.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/application/runtime_battle_outcome_apply.dart \
  test/battle_bag_menu_model_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_overlay_component_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Résultat :

- échec hors lot
- erreurs principales :
  - `GameplayWorldState.movementBlockReasonAt` absent
  - `GameplayWorldState.isBlocked` absent
  - `GameplayPlayerState.playerPositionPx` requis
  - drift `map_runtime` / `map_gameplay`

### Suite de tests demandée par le prompt

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter test \
  test/battle_bag_menu_model_test.dart \
  test/battle_party_menu_model_test.dart \
  test/battle_command_menu_component_test.dart \
  test/battle_overlay_component_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Résultat :

- échec global hors lot pour les mêmes raisons compile
- observation utile :
  - `test/battle_party_menu_model_test.dart` a tout de même exécuté 7 tests verts avant le blocage du reste

## 12. Limites assumées

- validation Flutter complète impossible tant que la casse compile `map_core/map_gameplay/map_runtime` hors scope n'est pas résolue
- le test end-to-end 9b a été ajouté mais n'a pas pu être exécuté
- aucun lot hors `map_runtime` n'a été ouvert pour réparer ce blocage

## 13. Ce qui est reporté au lot suivant

- toute logique générique `UseItem`
- medicines réellement utilisables
- unsupported items réellement utilisables
- toute évolution d'inventaire hors la consommation de Poké Ball déjà existante dans le write-back
- toute réparation du drift collision/gameplay hors scope de 9b

## 14. Retour de review séparée

Review séparée demandée sur :

- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

Retour :

```text
No findings. I couldn’t complete the targeted flutter test run because the preexisting map_core/map_gameplay compile break blocks compilation, but nothing in the three changed files looks like a BAG capture dispatch or disabled-item gating regression.
```

## 15. État git final exact

### `git status --short --untracked-files=all`

```text
 M packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
 M packages/map_runtime/test/battle_overlay_component_test.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? reports/lot-9b-battle-bag-capture-wiring-report.md
```

### `git diff --stat`

```text
 .../flame/battle_overlay_component.dart            |   6 +
 .../test/battle_overlay_component_test.dart        |  95 +++++++++-
 .../test/wild_battle_end_to_end_flow_test.dart     | 202 +++++++++++++++++++++
 3 files changed, 296 insertions(+), 7 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/lot-9b-battle-bag-capture-wiring-report.md
```

## 16. Décision finale

Implémentation 9b réalisée, mais lot non clôturable honnêtement à ce stade.

Décision nette :

- le wiring BAG -> `PlayerBattleChoiceCapture` est en place
- la consommation Poké Ball et le write-back capture restent adossés au seam runtime existant
- la validation requise du lot est bloquée par une casse compile préexistante hors scope

Conclusion honnête :

`Lot 9b est implémenté côté BAG capture wiring, mais ne peut pas être déclaré réussi tant que le repo ne recompilera pas sur la surface runtime demandée.`
