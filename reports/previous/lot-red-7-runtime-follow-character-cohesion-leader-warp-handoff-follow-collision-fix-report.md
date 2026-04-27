# Lot RED-7 — Runtime FollowCharacter Cohesion / Leader Warp Handoff / Follow Collision Fix

## 1. Resume executif honnete

Le lot RED-7 est implemente dans `packages/map_runtime` uniquement.

Le runtime corrige maintenant les trois causes principales observees sur `followCharacter` :

- le follower n'utilise plus le vieux `MoveIntent(direction)` a pas par defaut ; il utilise un pas complet aligne sur la tile runtime ;
- le leader suivi n'est plus traite comme bloqueur dynamique pour son propre follower pendant le calcul de chemin ;
- si le leader entre dans un warp pendant un follow actif, le follower n'est plus abandonne sur la map source : le handoff de warp reste actif jusqu'au transfert du joueur.

Comportement obtenu :

- le joueur suiveur reste a cadence coherente avec un leader qui marche normalement ;
- le follower n'explore plus de grands detours absurdes quand il est deja adjacent ou quasi-adjacent ;
- les autres PNJ restent bloquants pour le joueur hors contexte `followCharacter` ;
- la completion runtime reste bloquee par `follow_character_active` jusqu'au handoff warp final.

Point honnete :

- `flutter analyze --no-pub ...` sur la surface demandee ne finit pas verte a cause de 67 infos `prefer_const_*` deja presentes dans des fichiers analyses hors correctif RED-7 direct ; il n'y a pas d'erreur ni de warning bloquant sur le patch RED-7 lui-meme ;
- la review separee a ete lancee, mais n'a pas repondu dans le delai de cette session. Elle est documentee comme timeout, pas comme "sans findings".

## 2. Etat git initial exact

### `git status --short --untracked-files=all`

```text
 M packages/map_runtime/lib/src/application/script_runtime_controller.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/player_component_test.dart
 M packages/map_runtime/test/script_system_integration_test.dart
?? reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md
?? reports/lot-red-6-runtime-scenario-immediate-input-lock-dialogue-startup-race-fix-report.md
```

### `git diff --stat`

```text
 .../src/application/script_runtime_controller.dart |   9 +-
 .../src/presentation/flame/playable_map_game.dart  | 364 ++++++++-
 .../test/playable_map_game_input_test.dart         | 902 ++++++++++++++++++++-
 .../map_runtime/test/player_component_test.dart    |  21 +
 .../test/script_system_integration_test.dart       |  66 +-
 5 files changed, 1302 insertions(+), 60 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md
reports/lot-red-6-runtime-scenario-immediate-input-lock-dialogue-startup-race-fix-report.md
```

## 3. Classification de la dirtiness initiale

### `preexisting_in_scope`

- `packages/map_runtime/lib/src/application/script_runtime_controller.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_runtime/test/player_component_test.dart`
- `packages/map_runtime/test/script_system_integration_test.dart`
- `reports/lot-red-5-runtime-connection-tile-space-continuity-movement-speed-restore-report.md`
- `reports/lot-red-6-runtime-scenario-immediate-input-lock-dialogue-startup-race-fix-report.md`

### `preexisting_out_of_scope`

- aucun fichier visible dans les pre-gates

### `created_by_this_lot`

- `reports/lot-red-7-runtime-follow-character-cohesion-leader-warp-handoff-follow-collision-fix-report.md`

### `modified_by_this_lot`

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_runtime/test/scenario_runtime_completion_gate_test.dart`

## 4. Diagnostic racine

### 4.1 Pas follower incomplet

La cause la plus directe etait bien presente dans `_stepPlayerAlongFollowPath(...)` :

- le follow utilisait encore `stepGameplayWorld(_world, MoveIntent(direction))` ;
- le mouvement normal joueur, lui, avait deja ete corrige par RED-5 pour utiliser un pas complet runtime via `pixelsPerStep`.

Sur des projets `32x32`, cela laissait le follower sur un pas logique plus court que celui du leader.

### 4.2 Position leader mal resolue quand le leader n'etait pas tracke

`_resolveScenarioLeaderPosition(...)` prenait `scriptedNpcMovementStatus(...).currentPos` meme quand le statut etait `failed`, ce qui introduisait une fausse position `(0,0)` pour un leader non tracke. Cela pouvait :

- terminer un follow trop tot ;
- calculer un trailing point absurde ;
- rendre les tests follow non representatifs.

Le helper ignore maintenant le `currentPos` d'un statut `failed` et retombe proprement sur acteur runtime / runtime pos / map entity.

### 4.3 Leader suivi encore vu comme bloqueur dynamique

Le follower pouvait encore se heurter a son leader par deux chemins :

- reservations runtime `_scriptedNpcReservedOccupiedCellsByEntity` ;
- lecture du monde pour `isBlocked(...)`.

Le calcul de follow reconstruit maintenant un monde de planning ou le leader suivi est non-bloquant pour son follower uniquement, et les reservations du leader peuvent etre ignorees via `ignoreEntityId`.

### 4.4 Handoff warp du leader qui coupait le follow trop tot

Quand le leader entrait dans un warp, `_despawnNpcFromActiveMap(...)` annulait le follow parce que le leader disparaissait de la map source. Le completion gate pouvait alors se debloquer trop tot.

Le runtime garde maintenant le follow actif pendant un `pendingLeaderWarpHandoff`, planifie le warp joueur, puis ne libere le follow qu'apres le transfert vers la map cible.

## 5. Fichiers lus

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_controller.dart`
- `packages/map_runtime/lib/src/application/scripted_entity_movement_models.dart`
- `packages/map_runtime/lib/src/application/scripted_npc_anchor_passability.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart`
- `packages/map_runtime/lib/src/application/script_command_executor.dart`
- `packages/map_runtime/lib/src/application/script_runtime_controller.dart`
- `packages/map_runtime/lib/src/application/scenario_runtime_completion_gate.dart`
- `packages/map_gameplay/lib/src/gameplay_step.dart`
- `packages/map_gameplay/lib/src/gameplay_intent.dart`
- `packages/map_gameplay/lib/src/grid_pathfinder.dart`
- `packages/map_core/lib/src/operations/map_entity_collision_footprint.dart`
- `packages/map_runtime/test/scripted_entity_movement_controller_test.dart`
- `packages/map_runtime/test/scripted_npc_anchor_passability_test.dart`
- `packages/map_runtime/test/scripted_npc_runtime_interaction_test.dart`
- `packages/map_runtime/test/script_system_integration_test.dart`
- `packages/map_runtime/test/scenario_runtime_completion_gate_test.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_gameplay/test/grid_pathfinder_test.dart`

## 6. Fichiers modifies / crees

### Modifies

- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/test/playable_map_game_input_test.dart`
- `packages/map_runtime/test/scenario_runtime_completion_gate_test.dart`

### Cree

- `reports/lot-red-7-runtime-follow-character-cohesion-leader-warp-handoff-follow-collision-fix-report.md`

## 7. Fichiers volontairement non touches

- `packages/map_battle/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- `packages/map_gameplay/**`
- BAG battle / capture
- catalogues Pokemon
- IA battle
- `packages/map_runtime/lib/src/application/script_runtime_controller.dart`
- `packages/map_runtime/test/script_system_integration_test.dart`
- `packages/map_runtime/test/player_component_test.dart`

Ces trois derniers fichiers etaient deja dirty avant RED-7 et n'ont pas ete retouches.

## 8. Comportement obtenu

- `followCharacter` fait avancer le joueur avec un vrai pas runtime aligne sur la taille de tile du projet ;
- le follower garde une distance bornee avec un leader qui marche normalement ;
- le leader suivi n'est plus un bloqueur dynamique pour son propre follower ;
- le follower n'est plus abandonne quand le leader entre dans un warp ;
- la completion runtime reste bloquee jusqu'au handoff warp final ;
- les autres collisions NPC restent intactes pour le gameplay normal.

## 9. Preuve que `_stepPlayerAlongFollowPath` n'utilise plus le default move step

Le chemin suit maintenant :

- `_stepPlayerAlongFollowPath(...)`
- `stepGameplayWorld(followWorld, _fullTileMoveIntent(direction))`

`_fullTileMoveIntent(direction)` delegue a `_playerStepPixels(direction)` :

- `east/west => _world.tileWidthPx`
- `north/south => _world.tileHeightPx`

Le follow ne repasse donc plus par `MoveIntent(direction)` sans `pixelsPerStep`.

Le test qui verrouille ce point :

- `followCharacter player step uses full tile movement on 32px maps`

prouve que sur une map `32x32`, le follower termine bien sur la cellule attendue avec rendu aligne a `debugExpectedPlayerWorldTopLeft`.

## 10. Cohesion follower / leader

Le test :

- `followCharacter follower keeps pace with a walking leader`

demontre que :

- un leader peut marcher de `x=2` a `x=7` ;
- le follower reste a distance de Manhattan `<= 2` ;
- la distance ne diverge pas a chaque pas ;
- le follower finit proprement derriere le leader.

La cause principale etait bien le pas partiel du follower ; elle est maintenant supprimee.

## 11. Collision leader ignoree seulement dans le contexte follow

Le follow utilise des helpers locaux :

- `_buildFollowPlanningWorldIgnoringLeader(...)`
- `_isCellReservedByScriptedNpc(... ignoreEntityId: leaderEntityId)`
- `_canPlacePlayerAtForFollow(...)`
- `_computeFollowPlayerPath(... leaderEntityId: ...)`

Cela signifie :

- le leader suivi est ignore pour son follower uniquement ;
- les autres NPC, reservations, murs, collisions map et placed elements restent pris en compte normalement.

Le test :

- `followCharacter pathfinding ignores the followed leader dynamic blocker`

verrouille que le follow ne part pas en echec a cause du leader lui-meme et garde un chemin tres court pres du leader.

## 12. Preuve que les autres NPC restent bloquants

Le test :

- `non-follow NPC dynamic collision still blocks the player`

prouve que le correctif RED-7 ne rend pas les NPC traversables globalement. Il ne modifie que le planning de follow pour le leader activement suivi.

## 13. Anti-detour pathfinding

Le follow avait tendance a recalculer des chemins trop longs quand il etait deja adjacent ou presque adjacent au leader.

Le correctif ajoute un comportement plus sobre dans `_resolveFollowPathPlanNearLeader(...)` :

- tentative du trailing preferentiel ;
- fallback adjacent si necessaire ;
- si le joueur est deja adjacent et qu'aucune meilleure case utile n'existe, on accepte un plan de longueur `1` au lieu de partir dans un detour lointain ;
- les compteurs debug `_lastFollowPathNodeCount` / `_lastFollowPathDestination` sont remis a zero quand aucun plan n'est retenu.

Le test RED-7 qui le verrouille indirectement reste :

- `followCharacter pathfinding ignores the followed leader dynamic blocker`

avec `debugLastFollowPathNodeCount <= 2`.

## 14. Leader warp handoff

Le handoff de warp du leader suivi est maintenant explicite :

1. `_completeScenarioNpcWarpEntry(...)` detecte si l'entite qui disparait est le leader du follow actif ;
2. le runtime cree `_PendingScenarioLeaderWarpHandoff` ;
3. il programme `_pendingWarp` pour le joueur ;
4. il despawn le leader avec `keepActiveFollow: true` ;
5. `_processPendingScenarioFollowRequest()` garde le follow actif tant que ce handoff existe ;
6. `_handleWarp(...)` ne libere le follow qu'apres le succes du transfert joueur sur la map cible.

Le test :

- `followCharacter transfers player when followed leader enters a warp`

prouve que :

- le joueur ne reste pas sur la map source ;
- le joueur arrive bien sur la map cible ;
- le follow actif et le pending handoff sont nettoyes seulement apres ce transfert.

## 15. Completion gate

Le gate pur n'a pas eu besoin d'etre complexifie :

- `scenarioRuntimeCompletionBlockingReason(...)` priorise deja `follow_character_active`.

Le vrai correctif RED-7 est donc de garder `_pendingScenarioFollowRequest` vivant jusqu'au handoff warp final.

Le test ajoute :

- `followCharacter completion waits for leader warp handoff`

verrouille que si follow est encore actif pendant un warp runtime pending, la raison bloquante reste bien `follow_character_active`.

## 16. Tests ajoutes / renforces et ce qu'ils prouvent

### `packages/map_runtime/test/playable_map_game_input_test.dart`

- `followCharacter player step uses full tile movement on 32px maps`
  - prouve le pas follower full-tile sur maps `32x32`.
- `followCharacter follower keeps pace with a walking leader`
  - prouve que le retard follower reste borne.
- `followCharacter pathfinding ignores the followed leader dynamic blocker`
  - prouve que le leader n'est plus un bloqueur pour son follower et que le chemin reste court.
- `followCharacter transfers player when followed leader enters a warp`
  - prouve le handoff leader/follower sur warp.
- `non-follow NPC dynamic collision still blocks the player`
  - prouve l'absence de regression collision globale.

### `packages/map_runtime/test/scenario_runtime_completion_gate_test.dart`

- `followCharacter completion waits for leader warp handoff`
  - prouve la priorite du blocage follow tant que le handoff n'est pas fini.

## 17. Validations executees et resultats

### `packages/map_runtime`

Commande :

```bash
flutter analyze --no-pub \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/application/scripted_entity_movement_controller.dart \
  lib/src/application/scripted_entity_movement_models.dart \
  lib/src/application/scripted_npc_anchor_passability.dart \
  lib/src/application/scenario_runtime/scenario_runtime_executor.dart \
  lib/src/application/script_command_executor.dart \
  lib/src/application/script_runtime_controller.dart \
  lib/src/application/scenario_runtime_completion_gate.dart \
  test/playable_map_game_input_test.dart \
  test/scripted_entity_movement_controller_test.dart \
  test/scripted_npc_anchor_passability_test.dart \
  test/scripted_npc_runtime_interaction_test.dart \
  test/script_system_integration_test.dart \
  test/scenario_runtime_completion_gate_test.dart
```

Resultat :

- non vert strictement ;
- 67 infos `prefer_const_*` deja presentes sur la surface analysee ;
- aucune erreur compile ni warning bloquant RED-7.

Commande :

```bash
flutter test \
  test/playable_map_game_input_test.dart \
  test/scripted_entity_movement_controller_test.dart \
  test/scripted_npc_anchor_passability_test.dart \
  test/scripted_npc_runtime_interaction_test.dart \
  test/script_system_integration_test.dart \
  test/scenario_runtime_completion_gate_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/wild_battle_end_to_end_flow_test.dart
```

Resultat :

- vert

### `packages/map_gameplay`

Commande :

```bash
dart test
```

Resultat :

- vert

### `examples/playable_runtime_host`

Commande :

```bash
flutter test test/phase_a_golden_slice_launch_test.dart
```

Resultat :

- vert

## 18. Review separee

Review demandee sur :

- full-tile MoveIntent follow ;
- collision leader ignoree seulement pour son follower ;
- autres NPC encore bloquants ;
- absence de detour long absurde ;
- handoff warp leader/follower ;
- completion gate follow ;
- absence de regression RED-5 / RED-6 ;
- absence de modification battle/editor.

Statut :

- review lancee dans cette session ;
- pas de retour exploitable avant timeout ;
- donc aucun "No findings" n'est revendique.

## 19. Limites assumees

- le test `followCharacter` deplacement cadence couvre le cas produit principal et le warp handoff, mais ne transforme pas le follow en systeme generique de followers multiples ;
- un log controleur `npc_patrol blocked anchor ...` peut encore apparaitre ponctuellement pendant un replan NPC, mais le spam massif observe cote follow n'est plus reproduit par la suite RED-7 ;
- le lot ne retouche pas `packages/map_gameplay/**`, `map_battle`, `map_editor`, ni la completion gate pure au-dela d'un test supplementaire.

## 20. Etat git final exact

### `git status --short --untracked-files=all`

```text
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
 M packages/map_runtime/test/scenario_runtime_completion_gate_test.dart
?? reports/lot-red-7-runtime-follow-character-cohesion-leader-warp-handoff-follow-collision-fix-report.md
```

### `git diff --stat`

```text
 .../src/presentation/flame/playable_map_game.dart  | 274 ++++++++++++-
 .../test/playable_map_game_input_test.dart         | 447 ++++++++++++++++++++-
 .../scenario_runtime_completion_gate_test.dart     |  18 +
 3 files changed, 723 insertions(+), 16 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
reports/lot-red-7-runtime-follow-character-cohesion-leader-warp-handoff-follow-collision-fix-report.md
```

## 21. Decision finale

Lot RED-7 reussi :

- le follower n'utilise plus le pas partiel par defaut ;
- il garde la cadence d'un leader qui marche normalement ;
- il n'est plus bloque par le leader suivi ;
- les autres collisions NPC restent valides ;
- le warp du leader ne laisse plus le follower abandonne ;
- la completion runtime attend correctement le handoff follow/warp ;
- aucun fichier `map_battle` ou `map_editor` n'a ete touche.
