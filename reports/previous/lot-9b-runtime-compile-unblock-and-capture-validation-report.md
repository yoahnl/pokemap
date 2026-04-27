# Lot 9b Runtime Compile Unblock and Capture Validation

## 1. Résumé exécutif honnête

Le repo recompilable sur la surface runtime demandée a été restauré et le lot 9b a pu être validé jusqu'au bout.

Le blocage n'était plus dans le wiring BAG capture lui-même, mais dans un drift gameplay/runtime qui empêchait les validations de s'exécuter proprement, puis dans une fixture de test `party full` qui utilisait des données hors catalogue local.

Le résultat final est le suivant :

- la surface runtime demandée compile et s'analyse ;
- les tests 9b s'exécutent réellement ;
- la Poké Ball du BAG dispatch bien `PlayerBattleChoiceCapture` ;
- le flow sauvage BAG capture revient proprement à l'overworld ;
- le remplacement forcé, les trainer battles et les items non implémentés restent bornés ;
- aucun fichier `map_battle` n'a été touché.

## 2. État git initial exact

Je n'ai pas conservé un dump brut des trois pré-gates avant le premier correctif de cette passe de stabilisation. Je donne donc ici l'état initial reconstruit honnêtement :

- aucun fichier `map_editor` dirty du lot 8f n'était présent dans le worktree observé pendant cette passe ;
- aucun fichier `map_runtime` du patch 9b précédent n'était encore dirty ;
- les seuls fichiers restés dirty à la fin de cette passe sont ceux modifiés par ce gate.

Pré-gates initiaux reconstruits :

```bash
git status --short --untracked-files=all
<pas de sortie conservée ; aucun dirty préexistant ré-observé ensuite>

git diff --stat
<pas de sortie conservée ; aucun diff préexistant ré-observé ensuite>

git ls-files --others --exclude-standard
<pas de sortie conservée ; aucun untracked préexistant ré-observé ensuite>
```

## 3. Classification de la dirtiness initiale

- `preexisting_in_scope`: aucune dirtiness ré-observée dans le worktree au démarrage de cette passe
- `preexisting_out_of_scope`: aucune dirtiness ré-observée dans le worktree au démarrage de cette passe
- `created_by_this_lot`: ce report
- `modified_by_this_lot`:
  - `packages/map_gameplay/lib/src/gameplay_world_state.dart`
  - `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

## 4. Erreurs de compilation reproduites

Le blocage compile initial venait de deux familles d'erreurs déjà observées avant cette passe :

- dérive de génération/JSON autour de `ElementCollisionPixelMask` et `element_collision_profile.g.dart` ;
- dérive d'API entre `map_runtime` et `map_gameplay` autour de `GameplayWorldState.movementBlockReasonAt`, `GameplayWorldState.isBlocked` et de la reconstruction `GameplayPlayerState`.

Pendant cette passe de gate, une fois la génération `map_core` déjà remise d'équerre, le blocage encore concret sur la surface runtime n'était plus une erreur compile brute mais un échec de validation :

- `wild battle BAG capture does not work when party is full`
- la fixture utilisait des espèces et moves absents du catalogue local de test (`party_2`, puis `growl`)

## 5. Diagnostic racine

Racines réelles :

1. `map_runtime` dépendait encore d'helpers gameplay de compatibilité grille qui n'étaient plus exposés comme avant.
2. Le fallback de whiteout/runtime reconstruisait le joueur avec une API devenue plus stricte (`GameplayPlayerState.fromGridSpawn` au lieu d'une construction partielle).
3. Le test `party full` créait une party artificielle avec des ids non résolus par les fixtures réelles.
4. Une première compatibilité `movementBlockReasonAt` trop simple utilisait seulement la collision pixel au centre de case ; la review séparée a montré que cela cassait la sémantique legacy "cellule entière" pour les profils `cells`.

## 6. Fichiers lus

- `reports/lot-9b-battle-bag-capture-wiring-report.md`
- `reports/lot-9a-battle-bag-menu-ui-shell-report.md`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`
- `packages/map_core/lib/src/models/element_collision_profile.dart`
- `packages/map_core/lib/src/models/element_collision_profile.g.dart`
- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `packages/map_gameplay/lib/src/player_spawn_resolver.dart`
- `packages/map_gameplay/test/placed_elements_collision_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

## 7. Fichiers modifiés/créés

Modifiés :

- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

Créé :

- `reports/lot-9b-runtime-compile-unblock-and-capture-validation-report.md`

## 8. Fichiers volontairement non touchés

- `packages/map_battle/**`
- `packages/map_editor/**`
- `packages/map_core/**` pendant cette passe de gate
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- `packages/map_runtime/test/battle_overlay_component_test.dart`

## 9. Correction appliquée sur map_core / génération

Pendant cette passe de gate, aucune nouvelle modification `map_core` n'a été nécessaire.

Le drift `ElementCollisionPixelMask` / `element_collision_profile.g.dart` avait déjà été réparé juste avant, via restauration du modèle source et régénération cohérente. La présente passe a confirmé que le runtime pouvait à nouveau s'analyser et s'exécuter au-dessus de cette base réparée.

## 10. Correction appliquée sur map_gameplay / map_runtime

### `packages/map_gameplay/lib/src/gameplay_world_state.dart`

Compatibilité minimale rétablie pour les call sites runtime :

- restauration de `movementBlockReasonAt(...)`
- restauration de `isBlocked(...)`

Mais la version finale ne se contente pas d'un test au centre de case. Elle préserve la sémantique legacy attendue par le runtime :

- collision grille carte via `_tileCollisionCellCache`
- collision entités bloquantes via `_blockingEntityByPos`
- collision coarse `cells` des éléments placés via `_hasLegacyPlacedElementCellCollision(...)`
- collision pixel décorative/partielle toujours déléguée à `movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial(...)`

Cela rétablit la compilation sans élargir la logique gameplay au-delà de la compatibilité attendue.

### `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Le fallback de whiteout/runtime reconstruit maintenant le joueur via `GameplayPlayerState.fromGridSpawn(...)` avec les dimensions carte/tuile correctes, sans réutiliser le `movementMode` pré-battle. On reste ainsi aligné avec une sémantique de respawn à pied au lieu de conserver par erreur un état `surf`.

### `packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart`

La fixture `party full` a été rendue réaliste :

- espèces supplémentaires remplacées par `sproutle`
- moves supplémentaires remplacés par `vine_whip`
- imports inutiles supprimés pour garder l'analyse verte

## 11. Preuve que le patch n'a pas élargi le gameplay

Preuves concrètes :

- `packages/map_gameplay/test/placed_elements_collision_test.dart` repasse intégralement au vert après la compatibilité restaurée ;
- aucun fichier `map_battle` n'a été modifié ;
- aucun nouveau système de collision ou de movement mode n'a été introduit ;
- le fallback de whiteout est revenu vers une sémantique plus conservatrice, pas plus large ;
- le wiring BAG capture reste porté par l'overlay/runtime existant, sans mutation d'inventaire dans l'UI.

## 12. Validations exécutées et résultats

Commandes exécutées :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter test test/battle_overlay_component_test.dart
```

Résultat :

- vert

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
/opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/presentation/flame/battle_overlay_component.dart \
  test/battle_overlay_component_test.dart
```

Résultat :

- vert

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay
dart test test/placed_elements_collision_test.dart
```

Résultat :

- vert

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

- `No issues found!`

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

- `All tests passed!`

## 13. Statut final du lot 9b capture

Le lot 9b peut maintenant être déclaré validé.

Vérifications couvertes :

- la Poké Ball capturable depuis `BAG` dispatch bien `PlayerBattleChoiceCapture`
- le trainer battle ne dispatch pas capture
- les medicines restent non actionnables
- le forced replacement reste bloqué sur `POKÉMON`
- le flow wild battle capture revient à l'overworld
- le write-back runtime existant reste utilisé
- aucune mutation d'inventaire n'est faite dans l'overlay

## 14. Limites restantes

- cette passe n'ajoute aucune nouvelle feature au-delà du déblocage compile et de la validation 9b ;
- la consommation exacte de Poké Ball n'a pas été modifiée ici ; elle reste celle du seam runtime existant ;
- aucun système générique d'objets battle n'est ouvert ;
- aucun travail `map_editor` / `map_battle` n'a été repris.

## 15. Retour de review séparée

Une review séparée a bien été lancée.

Première passe :

- finding réel sur la sémantique legacy de `movementBlockReasonAt` / `isBlocked`
- finding réel sur le fallback de whiteout qui conservait à tort `movementMode`

Corrections appliquées :

- réintroduction d'un blocage whole-cell pour les profils `cells` legacy
- retour du fallback de whiteout vers une reconstruction à pied

Re-review après correction :

- `No findings.`

## 16. État git final exact

```bash
git status --short --untracked-files=all
 M packages/map_gameplay/lib/src/gameplay_world_state.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
?? reports/lot-9b-runtime-compile-unblock-and-capture-validation-report.md

git diff --stat
 .../map_gameplay/lib/src/gameplay_world_state.dart | 222 +++++++++++++--------
 .../src/presentation/flame/playable_map_game.dart  |   8 +-
 .../test/wild_battle_end_to_end_flow_test.dart     |  26 ++-
 3 files changed, 160 insertions(+), 96 deletions(-)

git ls-files --others --exclude-standard
reports/lot-9b-runtime-compile-unblock-and-capture-validation-report.md
```

## 17. Décision finale

Lot 9b validé après déblocage compile runtime.
