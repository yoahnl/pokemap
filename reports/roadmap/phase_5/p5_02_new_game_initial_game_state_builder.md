# P5-02 — New Game / Initial GameState Builder V0

## 1. Résumé exécutif

P5-02 est validable.

Le builder New Game existant était déjà sain pour le contrat explicite `mapId + position + facing`. Le gap réel était le pont minimal entre une `MapData` authorée et ce builder : résolution de spawn, position/facing de départ, puis production d'un `GameState` initial sans launch save écrite à la main.

Le lot ajoute donc une API pure et petite :

```dart
createNewGameStateFromMap(...)
```

Elle réutilise `resolveInitialPlayerSpawn(...)`, puis délègue à `createNewGameState(...)`. Elle ne crée pas de Boot Flow, pas de starter flow, pas de rewards, pas de Selbrume et pas de nouveau modèle persistant.

## 2. Scope du lot

Inclus :

- audit du builder New Game existant ;
- audit du resolver de spawn ;
- helper pur `MapData -> GameState` ;
- export public `map_gameplay.dart` ;
- tests ciblés sur `defaultSpawnId`, fallback `playerStart`, erreurs et roundtrip `SaveData` ;
- correction de deux diagnostics `dart analyze` locaux à `map_gameplay`.

Exclus :

- écran titre, vidéo d'intro, écran de slots, Continue / Nouvelle partie complet ;
- starter UI / starter flow ;
- rewards, money reward apply, XP, level-up ;
- heal center ;
- capture party-or-box ;
- runtime architecture, map editor UI, Selbrume final.

## 3. Sources lues

Fichiers principaux lus :

- `AGENTS.md` fourni dans le prompt utilisateur.
- `MVP Selbrume/road_map_global.md`
- `MVP Selbrume/road_map_phase_5.md`
- `reports/roadmap/phase_5/p5_01_runtime_project_disk_smoke_editor_created_project_proof.md`
- `packages/map_gameplay/lib/src/new_game_state_builder.dart`
- `packages/map_gameplay/lib/src/player_spawn_resolver.dart`
- `packages/map_gameplay/lib/src/direction.dart`
- `packages/map_gameplay/lib/src/gameplay_player_state.dart`
- `packages/map_gameplay/lib/src/gameplay_exceptions.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_gameplay/test/new_game_state_builder_test.dart`
- `packages/map_gameplay/test/los_detection_test.dart`
- `packages/map_core/lib/src/models/game_state.dart`
- `packages/map_core/lib/src/models/save_data.dart`
- `packages/map_core/lib/src/operations/game_state_persistence.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/collision/player_collision_conventions_v1.dart`

Sources utiles observées :

- `createNewGameState(...)` crée déjà un `GameState` propre : party vide, bag vide, progression vide, story flags vides, consumed events vides, metadata vide, money à 0 via `TrainerProfile`.
- `resolveInitialPlayerSpawn(...)` résout `map.mapMetadata.defaultSpawnId`, puis retombe sur le premier spawn `playerStart` trié par id.
- `SaveData` et `game_state_persistence.dart` permettent un roundtrip pur `GameState -> SaveData -> GameState`.

## 4. API New Game existante

Avant P5-02, `createNewGameState(...)` acceptait déjà :

- `startMapId` obligatoire ;
- `startPosition`, par défaut `(0, 0)` ;
- `startFacing`, par défaut `south` ;
- `saveId`, par défaut `new_game` ;
- `playerName`, par défaut `Player`.

Le builder trim `startMapId`, refuse un id vide, normalise `saveId` et `playerName`, puis initialise les systèmes de base sans contenu gameplay avancé.

Ce comportement n'a pas été réécrit.

## 5. Builder / helpers ajoutés ou durcis

Ajout :

```dart
GameState createNewGameStateFromMap({
  required MapData startMap,
  String saveId = 'new_game',
  String playerName = 'Player',
  int tileWidthPx = 16,
  int tileHeightPx = 16,
})
```

Comportement :

- résout le spawn initial via `resolveInitialPlayerSpawn(...)` ;
- utilise `spawn.pos` comme `playerPosition` ;
- convertit `spawn.facing` en `EntityFacing` ;
- délègue toute l'initialisation d'état à `createNewGameState(...)` ;
- conserve les erreurs existantes : `ArgumentError` pour map id blank, `GameplaySpawnResolutionException` pour spawn introuvable ;
- reste pure Dart, sans I/O, sans runtime et sans modèle persistant nouveau.

## 6. Spawn / position / facing

P5-02 prouve :

- `defaultSpawnId` sur `MapMetadata` donne la position/facing de départ ;
- si `defaultSpawnId` est absent, le resolver choisit le premier spawn `playerStart` trié par id ;
- un map id vide est refusé ;
- l'absence de spawn joueur est refusée par `GameplaySpawnResolutionException`.

Limite volontaire :

- P5-02 n'ajoute pas de paramètre public `spawnId` explicite. Le contrat existant stable est `defaultSpawnId` ou fallback `playerStart`. Un sélecteur de spawn plus riche relève plutôt d'un validator bêta ou d'un flow New Game plus produit.

## 7. Party / bag / money / progression initiale

Tests ajoutés ou confirmés :

- party vide ;
- bag vide ;
- `trainerProfile.money == 0` ;
- progression vide ;
- story flags vides ;
- consumed events vides ;
- metadata vide ;
- aucun Pokémon préchargé ;
- aucun id Selbrume hardcodé.

P5-02 ne crée pas de starter. Le starter minimal reste P5-03.

## 8. Persistence roundtrip

Preuve retenue :

```text
GameState -> saveDataFromGameState -> gameStateFromSaveData -> normalizeLoadedGameState
```

Ce niveau est volontairement dans `map_gameplay` / `map_core`, sans dépendance runtime. Le roundtrip runtime complet reste P5-07.

## 9. Ce qui est prouvé

- Un `GameState` initial minimal peut être créé depuis une `MapData`.
- La position/facing peuvent venir d'un spawn authoré.
- Les defaults gameplay initiaux restent propres et vides.
- L'état initial survit à un roundtrip de persistence core.
- L'API reste pure et déterministe.
- Le package `map_gameplay` passe ses tests ciblés et son analyse.

## 10. Ce qui n’est pas prouvé

- Aucun Boot Flow complet.
- Aucun écran titre, slot save, intro, cinématique ou handoff UX.
- Aucun starter flow.
- Aucun runtime launch direct depuis ce builder.
- Aucun reward, money reward apply, XP, level-up.
- Aucun heal center.
- Aucune capture party-or-box.
- Aucun validator bêta complet start map/spawn/starter.

## 11. Limites et reports vers P5-03 / P5-07 / P5-09

- P5-03 doit utiliser ce socle pour ajouter une party initiale ou starter minimal.
- P5-07 devra prouver la persistence gameplay bêta avec les états ajoutés après P5-03 à P5-06.
- P5-09 devra diagnostiquer les projets non lançables : map de départ absente, spawn absent, starter/party incohérents, etc.
- Le Boot Flow complet reste hors scope Phase 5 immédiate.

## 12. Tests exécutés

Test rouge TDD initial :

```text
cd packages/map_gameplay && dart test test/new_game_state_builder_test.dart

00:00 +0: loading test/new_game_state_builder_test.dart
00:00 +0 -1: loading test/new_game_state_builder_test.dart [E]
  Failed to load "test/new_game_state_builder_test.dart":
  test/new_game_state_builder_test.dart:280:21: Error: Method not found: 'createNewGameStateFromMap'.
        final state = createNewGameStateFromMap(
                      ^^^^^^^^^^^^^^^^^^^^^^^^^
  test/new_game_state_builder_test.dart:301:21: Error: Method not found: 'createNewGameStateFromMap'.
        final state = createNewGameStateFromMap(
                      ^^^^^^^^^^^^^^^^^^^^^^^^^
  test/new_game_state_builder_test.dart:336:15: Error: Method not found: 'createNewGameStateFromMap'.
          () => createNewGameStateFromMap(
                ^^^^^^^^^^^^^^^^^^^^^^^^^
  test/new_game_state_builder_test.dart:345:15: Error: Method not found: 'createNewGameStateFromMap'.
          () => createNewGameStateFromMap(
                ^^^^^^^^^^^^^^^^^^^^^^^^^
  test/new_game_state_builder_test.dart:356:21: Error: Method not found: 'createNewGameStateFromMap'.
        final state = createNewGameStateFromMap(
                      ^^^^^^^^^^^^^^^^^^^^^^^^^
  test/new_game_state_builder_test.dart:375:21: Error: Method not found: 'createNewGameStateFromMap'.
        final state = createNewGameStateFromMap(startMap: newGameMap());
                      ^^^^^^^^^^^^^^^^^^^^^^^^^
00:00 +0 -1: Some tests failed.

Failing tests:
  test/new_game_state_builder_test.dart: loading test/new_game_state_builder_test.dart
```

Test ciblé final :

```text
cd packages/map_gameplay && dart test test/new_game_state_builder_test.dart

00:00 +0: loading test/new_game_state_builder_test.dart
00:00 +0: createNewGameState creates a GameState with the correct start map id
00:00 +1: createNewGameState trims whitespace from startMapId
00:00 +2: createNewGameState sets the default start position to (0, 0)
00:00 +3: createNewGameState sets a custom start position
00:00 +4: createNewGameState sets the default facing to south
00:00 +5: createNewGameState sets a custom facing
00:00 +6: createNewGameState initializes party as empty
00:00 +7: createNewGameState initializes bag as empty
00:00 +8: createNewGameState initializes storyFlags as empty
00:00 +9: createNewGameState initializes scriptVariables as empty
00:00 +10: createNewGameState initializes completedStepIds as empty
00:00 +11: createNewGameState initializes completedCutsceneIds as empty
00:00 +12: createNewGameState initializes consumedEventIds as empty
00:00 +13: createNewGameState initializes progression seenSpeciesIds as empty
00:00 +14: createNewGameState initializes progression caughtSpeciesIds as empty
00:00 +15: createNewGameState initializes progression storyFlags as empty
00:00 +16: createNewGameState initializes unlockedFieldAbilities as empty
00:00 +17: createNewGameState initializes metadata as empty
00:00 +18: createNewGameState sets playerMovementMode to walk
00:00 +19: createNewGameState does not preload any Pokemon
00:00 +20: createNewGameState sets the default saveId to new_game
00:00 +21: createNewGameState accepts a custom saveId
00:00 +22: createNewGameState falls back to new_game when saveId is blank
00:00 +23: createNewGameState sets the default player name to Player
00:00 +24: createNewGameState accepts a custom player name
00:00 +25: createNewGameState falls back to Player when playerName is blank
00:00 +26: createNewGameState trainerProfile starts with zero money
00:00 +27: createNewGameState trainerProfile starts with zero playtime
00:00 +28: createNewGameState trainerProfile starts with no badges
00:00 +29: createNewGameState throws ArgumentError when startMapId is empty
00:00 +30: createNewGameState throws ArgumentError when startMapId is blank
00:00 +31: createNewGameState round-trips through SaveData correctly
00:00 +32: createNewGameState does not reference any Selbrume-specific ids
00:00 +33: createNewGameStateFromMap resolves defaultSpawnId into start position and facing
00:00 +34: createNewGameStateFromMap falls back to the first playerStart spawn when defaultSpawnId is absent
00:00 +35: createNewGameStateFromMap throws when the map id is blank
00:00 +36: createNewGameStateFromMap throws when no player spawn can be resolved
00:00 +37: createNewGameStateFromMap round-trips the spawn-derived state through SaveData
00:00 +38: createNewGameStateFromMap does not hardcode Selbrume ids when resolving a map spawn
00:00 +39: All tests passed!
```

Régressions ciblées :

```text
cd packages/map_gameplay && dart test test/give_pokemon_test.dart

00:00 +0: loading test/give_pokemon_test.dart
00:00 +0: GameStateMutations.givePokemon adds a Pokemon to an empty party
00:00 +1: GameStateMutations.givePokemon appends to an existing party
00:00 +2: GameStateMutations.givePokemon preserves existing party members
00:00 +3: GameStateMutations.givePokemon preserves bag
00:00 +4: GameStateMutations.givePokemon preserves storyFlags
00:00 +5: GameStateMutations.givePokemon preserves currentMapId and playerPosition
00:00 +6: GameStateMutations.givePokemon preserves progression
00:00 +7: GameStateMutations.givePokemon is a no-op when speciesId is empty
00:00 +8: GameStateMutations.givePokemon is a no-op when speciesId is blank
00:00 +9: GameStateMutations.givePokemon trims speciesId whitespace
00:00 +10: GameStateMutations.givePokemon prevents duplicate species when requested
00:00 +11: GameStateMutations.givePokemon allows duplicate species when preventDuplicateSpecies is false
00:00 +12: GameStateMutations.givePokemon allows duplicate species by default
00:00 +13: GameStateMutations.givePokemon does not hardcode any Selbrume ids
00:00 +14: GameStateMutations.givePokemon round-trips through save/load
00:00 +15: GameStateMutations.givePokemon full flow: createNewGameState then givePokemon then save/load
00:00 +16: All tests passed!
```

```text
cd packages/map_gameplay && dart test test/game_state_mutations_test.dart

00:00 +0: loading test/game_state_mutations_test.dart
00:00 +0: GameStateMutations - giveItem giveItem adds a new item to an empty Bag
00:00 +1: GameStateMutations - giveItem giveItem adds a new item of default category items
00:00 +2: GameStateMutations - giveItem giveItem accumulates quantity if the item already exists
00:00 +3: GameStateMutations - giveItem giveItem preserves other items in the Bag
00:00 +4: GameStateMutations - giveItem giveItem does nothing (no-op) when quantity <= 0
00:00 +5: GameStateMutations - giveItem giveItem does nothing (no-op) when itemId is empty or whitespace-only
00:00 +6: All tests passed!
```

```text
cd packages/map_gameplay && dart test test/los_detection_test.dart

00:00 +0: loading test/los_detection_test.dart
00:00 +0: checkLineOfSight joueur dans axe + distance valide + pas d'obstacle → true
00:00 +1: checkLineOfSight joueur hors axe → false
00:00 +2: checkLineOfSight distance > lineOfSightRange → false
00:00 +3: checkLineOfSight obstacle entre NPC et joueur → false
00:00 +4: checkLineOfSight joueur adjacent → true (pas d'obstacle testé)
00:00 +5: checkLineOfSight lineOfSightRange = 0 → false
00:00 +6: checkLineOfSight joueur dans mauvais sens → false
00:00 +7: checkLineOfSight joueur à l'est → true avec facing east
00:00 +8: checkLineOfSight joueur à l'ouest → true avec facing west
00:00 +9: checkLineOfSight joueur au sud → true avec facing south
00:00 +10: All tests passed!
```

```text
cd packages/map_core && dart test test/game_state_persistence_test.dart

00:00 +0: loading test/game_state_persistence_test.dart
00:00 +0: gameStateFromSaveData migrates legacy save fields to GameState
00:00 +1: saveDataFromGameState keeps core fields and merges story flags in legacy slot
00:00 +2: saveDataFromGameState syncs party species into caught and seen for persistence
00:00 +3: normalizeLoadedGameState hydrates storyFlags from progression when storyFlags are empty
00:00 +4: normalizeLoadedGameState keeps explicit storyFlags as source of truth when already set
00:00 +5: normalizeLoadedGameState hydrates caught and seen from party for legacy states
00:00 +6: normalizeLoadedGameState markSpeciesSeenInGameState adds seen without inventing caught
00:00 +7: All tests passed!
```

Analyse :

```text
cd packages/map_gameplay && dart analyze

Analyzing map_gameplay...
No issues found!
```

Format :

```text
cd packages/map_gameplay && dart format --set-exit-if-changed lib/src/new_game_state_builder.dart test/new_game_state_builder_test.dart test/los_detection_test.dart

Formatted 3 files (0 changed) in 0.01 seconds.
```

## 13. Modifications effectuées

Fichiers créés :

- `reports/roadmap/phase_5/p5_02_new_game_initial_game_state_builder.md`

Fichiers modifiés :

- `MVP Selbrume/road_map_phase_5.md`
- `packages/map_gameplay/lib/src/new_game_state_builder.dart`
- `packages/map_gameplay/lib/map_gameplay.dart`
- `packages/map_gameplay/test/new_game_state_builder_test.dart`
- `packages/map_gameplay/pubspec.yaml`
- `packages/map_gameplay/test/los_detection_test.dart`

Notes :

- `pubspec.yaml` reçoit `publish_to: none` pour aligner `map_gameplay` avec les autres packages locaux et rendre `dart analyze` clean.
- `los_detection_test.dart` ne change pas de comportement ; le helper local perd son underscore pour satisfaire la lint, et la liste de tiles est remplacée par `List.filled(100, 0)` pour garder un diff lisible après format.

## 14. Evidence Pack

### git status initial exact

```text
git status --short --untracked-files=all

<aucune sortie>
```

### Commandes exécutées

```text
git status --short --untracked-files=all
sed -n '1,360p' "MVP Selbrume/road_map_global.md"
sed -n '1,920p' "MVP Selbrume/road_map_phase_5.md"
sed -n '1,320p' reports/roadmap/phase_5/p5_01_runtime_project_disk_smoke_editor_created_project_proof.md
sed -n '1,260p' packages/map_gameplay/lib/src/new_game_state_builder.dart
sed -n '1,260p' packages/map_gameplay/lib/src/player_spawn_resolver.dart
sed -n '1,320p' packages/map_gameplay/test/new_game_state_builder_test.dart
sed -n '1,260p' packages/map_core/lib/src/models/game_state.dart
sed -n '1,360p' packages/map_core/lib/src/models/save_data.dart
sed -n '1,260p' packages/map_core/lib/src/operations/game_state_persistence.dart
rg -n "createNewGameState|NewGame|initial|spawn|defaultSpawnId|playerFacing|playerPosition|TrainerProfile|money|party|bag|progression|storyFlags|consumedEventIds|metadata" packages/map_core packages/map_gameplay packages/map_runtime --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,260p' packages/map_gameplay/lib/map_gameplay.dart
sed -n '1,360p' packages/map_core/lib/src/models/map_data.dart
sed -n '1,260p' packages/map_core/lib/src/models/map_entity_payloads.dart
sed -n '1,220p' packages/map_core/lib/src/models/enums.dart
sed -n '1,220p' packages/map_gameplay/test/player_spawn_resolver_test.dart
find packages/map_gameplay/test -maxdepth 2 -type f | sort | rg "spawn|new_game|game_state"
rg -n "resolveInitialPlayerSpawn|GameplaySpawnResolutionException|defaultSpawnId|MapEntitySpawnData|EntitySpawnRole" packages/map_gameplay packages/map_core/test packages/map_gameplay/test --glob '!build/**' --glob '!**/.dart_tool/**'
sed -n '1,220p' packages/map_gameplay/lib/src/direction.dart
sed -n '1,220p' packages/map_gameplay/lib/src/gameplay_player_state.dart
sed -n '1,180p' packages/map_gameplay/lib/src/gameplay_exceptions.dart
sed -n '220,420p' packages/map_core/lib/src/models/save_data.dart
dart test test/new_game_state_builder_test.dart
dart format --set-exit-if-changed lib/src/new_game_state_builder.dart test/new_game_state_builder_test.dart
dart test test/new_game_state_builder_test.dart
dart test test/give_pokemon_test.dart
dart test test/game_state_mutations_test.dart
dart test test/game_state_persistence_test.dart
dart analyze
sed -n '1,80p' packages/map_gameplay/pubspec.yaml
sed -n '1,80p' packages/map_gameplay/test/los_detection_test.dart
rg -n "publish_to: none" packages/*/pubspec.yaml examples/*/pubspec.yaml pubspec.yaml --glob '!build/**' --glob '!**/.dart_tool/**'
rg -n "_createWorld" packages/map_gameplay/test/los_detection_test.dart
dart format --set-exit-if-changed lib/src/new_game_state_builder.dart test/new_game_state_builder_test.dart test/los_detection_test.dart
dart test test/los_detection_test.dart
dart analyze
git diff -- packages/map_gameplay/lib/src/new_game_state_builder.dart
git diff -- packages/map_gameplay/lib/map_gameplay.dart
git diff -- packages/map_gameplay/test/new_game_state_builder_test.dart
git diff -- packages/map_gameplay/pubspec.yaml packages/map_gameplay/test/los_detection_test.dart
git diff -- "MVP Selbrume/road_map_phase_5.md"
```

### Sorties utiles

`sed packages/map_gameplay/test/player_spawn_resolver_test.dart` :

```text
sed: packages/map_gameplay/test/player_spawn_resolver_test.dart: No such file or directory
```

`find packages/map_gameplay/test ...` :

```text
packages/map_gameplay/test/game_state_mutations_test.dart
packages/map_gameplay/test/new_game_state_builder_test.dart
```

`rg resolveInitialPlayerSpawn...` :

```text
packages/map_gameplay/lib/src/player_spawn_resolver.dart:12:GameplayPlayerState resolveInitialPlayerSpawn(
packages/map_gameplay/lib/src/player_spawn_resolver.dart:17:  final spawnId = map.mapMetadata.defaultSpawnId?.trim();
packages/map_gameplay/lib/src/player_spawn_resolver.dart:34:    throw GameplaySpawnResolutionException(
packages/map_gameplay/lib/src/player_spawn_resolver.dart:39:    throw GameplaySpawnResolutionException(
packages/map_gameplay/lib/src/player_spawn_resolver.dart:60:            e.spawn?.role == EntitySpawnRole.playerStart,
packages/map_gameplay/lib/src/player_spawn_resolver.dart:66:    throw const GameplaySpawnResolutionException(
packages/map_gameplay/lib/src/gameplay_world_state.dart:190:    final player = resolveInitialPlayerSpawn(
```

`rg createNewGameState...` a produit une sortie très longue. Signaux utiles :

- `packages/map_gameplay/lib/src/new_game_state_builder.dart` contient le builder New Game ;
- `packages/map_gameplay/test/new_game_state_builder_test.dart`, `give_pokemon_test.dart`, `complete_step_test.dart` et d'autres tests utilisent déjà `createNewGameState(...)` ;
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart` contient déjà des blocs party/capture/write-back hors scope P5-02 ;
- `packages/map_core/lib/src/validation/validators.dart` valide déjà certains `defaultSpawnId`.

### Diff complet des fichiers modifiés

```diff
diff --git a/packages/map_gameplay/lib/src/new_game_state_builder.dart b/packages/map_gameplay/lib/src/new_game_state_builder.dart
index a3c61f6c..8f4f21cd 100644
--- a/packages/map_gameplay/lib/src/new_game_state_builder.dart
+++ b/packages/map_gameplay/lib/src/new_game_state_builder.dart
@@ -1,5 +1,8 @@
 import 'package:map_core/map_core.dart';
 
+import 'direction.dart';
+import 'player_spawn_resolver.dart';
+
 /// Crée un [GameState] initial pour une nouvelle partie.
 ///
 /// Le state produit est propre : party vide, bag vide, flags vides,
@@ -53,3 +56,30 @@ GameState createNewGameState({
     metadata: const {},
   );
 }
+
+/// Crée un [GameState] initial depuis une map de départ authorée.
+///
+/// Ce helper garde P5-02 au niveau New Game minimal : il résout uniquement la
+/// position/facing via le spawn de la map, puis délègue l'initialisation du
+/// state à [createNewGameState].
+GameState createNewGameStateFromMap({
+  required MapData startMap,
+  String saveId = 'new_game',
+  String playerName = 'Player',
+  int tileWidthPx = 16,
+  int tileHeightPx = 16,
+}) {
+  final spawn = resolveInitialPlayerSpawn(
+    startMap,
+    tileWidthPx: tileWidthPx,
+    tileHeightPx: tileHeightPx,
+  );
+
+  return createNewGameState(
+    startMapId: startMap.id,
+    startPosition: spawn.pos,
+    startFacing: spawn.facing.asFacing,
+    saveId: saveId,
+    playerName: playerName,
+  );
+}
diff --git a/packages/map_gameplay/lib/map_gameplay.dart b/packages/map_gameplay/lib/map_gameplay.dart
index a897a462..f0dc29da 100644
--- a/packages/map_gameplay/lib/map_gameplay.dart
+++ b/packages/map_gameplay/lib/map_gameplay.dart
@@ -61,4 +61,5 @@ export 'src/script_condition_evaluator.dart'
     show ScriptConditionEvaluator, ScriptEvaluationContext;
 export 'src/event_page_resolver.dart' show EventPageResolver;
 export 'src/game_state_mutations.dart' show GameStateMutations;
-export 'src/new_game_state_builder.dart' show createNewGameState;
+export 'src/new_game_state_builder.dart'
+    show createNewGameState, createNewGameStateFromMap;
diff --git a/packages/map_gameplay/test/new_game_state_builder_test.dart b/packages/map_gameplay/test/new_game_state_builder_test.dart
index 15c41302..558ac8be 100644
--- a/packages/map_gameplay/test/new_game_state_builder_test.dart
+++ b/packages/map_gameplay/test/new_game_state_builder_test.dart
@@ -3,6 +3,33 @@ import 'package:map_gameplay/map_gameplay.dart';
 import 'package:test/test.dart';
 
 void main() {
+  MapData newGameMap({
+    String mapId = 'p5_new_game_map',
+    String? defaultSpawnId = 'p5_spawn_default',
+    List<MapEntity>? entities,
+  }) {
+    return MapData(
+      id: mapId,
+      name: 'P5 New Game Test Map',
+      size: const GridSize(width: 12, height: 10),
+      mapMetadata: MapMetadata(defaultSpawnId: defaultSpawnId),
+      entities: entities ??
+          const [
+            MapEntity(
+              id: 'p5_spawn_default',
+              name: 'Default Spawn',
+              kind: MapEntityKind.spawn,
+              pos: GridPos(x: 3, y: 4),
+              spawn: MapEntitySpawnData(
+                spawnKey: 'p5_spawn_default',
+                role: EntitySpawnRole.playerStart,
+                facing: EntityFacing.west,
+              ),
+            ),
+          ],
+    );
+  }
+
   group('createNewGameState', () {
     test('creates a GameState with the correct start map id', () {
       final state = createNewGameState(startMapId: 'test_start_map');
@@ -225,7 +252,8 @@ void main() {
       );
 
       final saveData = saveDataFromGameState(state);
-      final reloaded = normalizeLoadedGameState(gameStateFromSaveData(saveData));
+      final reloaded =
+          normalizeLoadedGameState(gameStateFromSaveData(saveData));
 
       expect(reloaded.currentMapId, state.currentMapId);
       expect(reloaded.playerPosition, state.playerPosition);
@@ -247,4 +275,113 @@ void main() {
       expect(state.currentMapId, isNot(contains('port')));
     });
   });
+
+  group('createNewGameStateFromMap', () {
+    test('resolves defaultSpawnId into start position and facing', () {
+      final state = createNewGameStateFromMap(
+        startMap: newGameMap(),
+        saveId: 'p5_new_game_save',
+        playerName: 'P5 Player',
+      );
+
+      expect(state.saveId, 'p5_new_game_save');
+      expect(state.currentMapId, 'p5_new_game_map');
+      expect(state.playerPosition, const GridPos(x: 3, y: 4));
+      expect(state.playerFacing, EntityFacing.west);
+      expect(state.trainerProfile.name, 'P5 Player');
+      expect(state.party.members, isEmpty);
+      expect(state.bag.entries, isEmpty);
+      expect(state.trainerProfile.money, 0);
+      expect(state.progression.completedStepIds, isEmpty);
+      expect(state.storyFlags.activeFlags, isEmpty);
+      expect(state.consumedEventIds, isEmpty);
+      expect(state.metadata, isEmpty);
+    });
+
+    test(
+        'falls back to the first playerStart spawn when defaultSpawnId is absent',
+        () {
+      final state = createNewGameStateFromMap(
+        startMap: newGameMap(
+          defaultSpawnId: null,
+          entities: const [
+            MapEntity(
+              id: 'z_spawn',
+              kind: MapEntityKind.spawn,
+              pos: GridPos(x: 7, y: 8),
+              spawn: MapEntitySpawnData(
+                spawnKey: 'z_spawn',
+                role: EntitySpawnRole.playerStart,
+                facing: EntityFacing.north,
+              ),
+            ),
+            MapEntity(
+              id: 'a_spawn',
+              kind: MapEntityKind.spawn,
+              pos: GridPos(x: 1, y: 2),
+              spawn: MapEntitySpawnData(
+                spawnKey: 'a_spawn',
+                role: EntitySpawnRole.playerStart,
+                facing: EntityFacing.east,
+              ),
+            ),
+          ],
+        ),
+      );
+
+      expect(state.currentMapId, 'p5_new_game_map');
+      expect(state.playerPosition, const GridPos(x: 1, y: 2));
+      expect(state.playerFacing, EntityFacing.east);
+    });
+
+    test('throws when the map id is blank', () {
+      expect(
+        () => createNewGameStateFromMap(
+          startMap: newGameMap(mapId: '   '),
+        ),
+        throwsArgumentError,
+      );
+    });
+
+    test('throws when no player spawn can be resolved', () {
+      expect(
+        () => createNewGameStateFromMap(
+          startMap: newGameMap(
+            defaultSpawnId: null,
+            entities: const [],
+          ),
+        ),
+        throwsA(isA<GameplaySpawnResolutionException>()),
+      );
+    });
+
+    test('round-trips the spawn-derived state through SaveData', () {
+      final state = createNewGameStateFromMap(
+        startMap: newGameMap(),
+        saveId: 'p5_roundtrip_save',
+      );
+
+      final saveData = saveDataFromGameState(state);
+      final reloaded =
+          normalizeLoadedGameState(gameStateFromSaveData(saveData));
+
+      expect(reloaded.saveId, 'p5_roundtrip_save');
+      expect(reloaded.currentMapId, 'p5_new_game_map');
+      expect(reloaded.playerPosition, const GridPos(x: 3, y: 4));
+      expect(reloaded.playerFacing, EntityFacing.west);
+      expect(reloaded.party.members, isEmpty);
+      expect(reloaded.bag.entries, isEmpty);
+      expect(reloaded.trainerProfile.money, 0);
+      expect(reloaded.progression.completedStepIds, isEmpty);
+    });
+
+    test('does not hardcode Selbrume ids when resolving a map spawn', () {
+      final state = createNewGameStateFromMap(startMap: newGameMap());
+
+      expect(state.currentMapId.toLowerCase(), isNot(contains('selbrume')));
+      expect(state.currentMapId.toLowerCase(), isNot(contains('lysa')));
+      expect(state.currentMapId.toLowerCase(), isNot(contains('mael')));
+      expect(state.currentMapId.toLowerCase(), isNot(contains('brume')));
+    });
+  });
 }
diff --git a/packages/map_gameplay/pubspec.yaml b/packages/map_gameplay/pubspec.yaml
index db3c8f27..0b9cb418 100644
--- a/packages/map_gameplay/pubspec.yaml
+++ b/packages/map_gameplay/pubspec.yaml
@@ -4,6 +4,7 @@ description: >-
   Player movement, collision resolution, and warp detection.
   Pure Dart — no rendering, no Flame dependency.
 version: 0.1.0
+publish_to: none
 
 repository: https://git.yoahn.me/yoahn/pokemonProject
 
diff --git a/packages/map_gameplay/test/los_detection_test.dart b/packages/map_gameplay/test/los_detection_test.dart
index 26e01f7d..5baf635a 100644
--- a/packages/map_gameplay/test/los_detection_test.dart
+++ b/packages/map_gameplay/test/los_detection_test.dart
@@ -5,7 +5,7 @@ import 'package:test/test.dart';
 void main() {
   group('checkLineOfSight', () {
     // Helper pour créer un GameplayWorldState de test
-    GameplayWorldState _createWorld({
+    GameplayWorldState createWorld({
       required MapData map,
       GridPos playerPos = const GridPos(x: 5, y: 5),
     }) {
@@ -21,9 +21,9 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
-        playerPos: const GridPos(x: 5, y: 2),  // 3 cases au nord
+        playerPos: const GridPos(x: 5, y: 2), // 3 cases au nord
       );
 
       final result = checkLineOfSight(
@@ -43,9 +43,9 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
-        playerPos: const GridPos(x: 6, y: 2),  // Décalé d'une case
+        playerPos: const GridPos(x: 6, y: 2), // Décalé d'une case
       );
 
       final result = checkLineOfSight(
@@ -65,15 +65,15 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
-        playerPos: const GridPos(x: 5, y: 0),  // 5 cases (distance > 3)
+        playerPos: const GridPos(x: 5, y: 0), // 5 cases (distance > 3)
       );
 
       final result = checkLineOfSight(
         npcPos: const GridPos(x: 5, y: 5),
         npcFacing: EntityFacing.north,
-        lineOfSightRange: 3,  // Trop court
+        lineOfSightRange: 3, // Trop court
         playerPos: const GridPos(x: 5, y: 0),
         world: world,
       );
@@ -88,20 +88,20 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
         layers: [
-          const MapLayer.tile(
+          MapLayer.tile(
             id: 'terrain',
             name: 'Terrain',
             tilesetId: 'ts',
-            tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
+            tiles: List.filled(100, 0),
           ),
           MapLayer.collision(
             id: 'collision',
             name: 'Collision',
-            collisions: List.generate(100, (i) => i == 35),  // Index 35 = (5, 3)
+            collisions: List.generate(100, (i) => i == 35), // Index 35 = (5, 3)
           ),
         ],
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
         playerPos: const GridPos(x: 5, y: 2),
       );
@@ -123,9 +123,9 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
-        playerPos: const GridPos(x: 5, y: 4),  // Adjacent (1 case)
+        playerPos: const GridPos(x: 5, y: 4), // Adjacent (1 case)
       );
 
       final result = checkLineOfSight(
@@ -145,7 +145,7 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
         playerPos: const GridPos(x: 5, y: 4),
       );
@@ -153,7 +153,7 @@ void main() {
       final result = checkLineOfSight(
         npcPos: const GridPos(x: 5, y: 5),
         npcFacing: EntityFacing.north,
-        lineOfSightRange: 0,  // Désactivé
+        lineOfSightRange: 0, // Désactivé
         playerPos: const GridPos(x: 5, y: 4),
         world: world,
       );
@@ -167,9 +167,10 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
-        playerPos: const GridPos(x: 5, y: 6),  // Au SUD du NPC (qui regarde au NORD)
+        playerPos:
+            const GridPos(x: 5, y: 6), // Au SUD du NPC (qui regarde au NORD)
       );
 
       final result = checkLineOfSight(
@@ -189,7 +190,7 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
         playerPos: const GridPos(x: 8, y: 5),
       );
@@ -211,7 +212,7 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
         playerPos: const GridPos(x: 2, y: 5),
       );
@@ -233,7 +234,7 @@ void main() {
         name: 'Test',
         size: const GridSize(width: 10, height: 10),
       );
-      final world = _createWorld(
+      final world = createWorld(
         map: map,
         playerPos: const GridPos(x: 5, y: 8),
       );
diff --git a/MVP Selbrume/road_map_phase_5.md b/MVP Selbrume/road_map_phase_5.md
index 286781b6..878727d8 100644
--- a/MVP Selbrume/road_map_phase_5.md	
+++ b/MVP Selbrume/road_map_phase_5.md	
@@ -6,6 +6,7 @@ Phase 5 active.
 
 P5-00 : terminé.
 P5-01 : terminé.
+P5-02 : terminé.
 
 Phase 5 reste orientée vers une boucle RPG minimale prouvable, pas vers une
 parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
@@ -13,7 +14,7 @@ parité Pokémon complète, pas vers Selbrume final, pas vers une UI premium.
 Prochain lot exact :
 
 ```text
-P5-02 — New Game / Initial GameState Builder V0
+P5-03 — Starter / Initial Party Minimal Flow V0
 ```
 
 ## Objectif Phase 5
@@ -137,7 +138,7 @@ aucun contenu final Selbrume
 
 ### P5-02 — New Game / Initial GameState Builder V0
 
-Statut : prochain lot exact.
+Statut : terminé.
 
 But :
 
@@ -157,6 +158,8 @@ aucun Boot Flow complet
 
 ### P5-03 — Starter / Initial Party Minimal Flow V0
 
+Statut : prochain lot exact.
+
 But :
 
 ```text
```

### Contrôles hors scope

- `road_map_global.md` n'a pas été modifié.
- P5-03 n'a pas été exécuté.
- Aucun Boot Flow complet n'a été créé.
- Aucun écran titre / vidéo d'intro / écran de slots / cinématique d'ouverture n'a été créé.
- Aucun starter UI / starter flow complet n'a été créé.
- Aucun Selbrume final n'a été créé.
- Aucun reward / money reward apply / XP / level-up n'a été ajouté.
- Aucun heal center n'a été ajouté.
- Aucune capture party-or-box n'a été ajoutée.
- Aucune UI premium n'a été créée.

### Sorties finales

`git diff --check` :

```text
<aucune sortie>
```

`git diff --stat` :

```text
 MVP Selbrume/road_map_phase_5.md                   |   7 +-
 packages/map_gameplay/lib/map_gameplay.dart        |   3 +-
 .../lib/src/new_game_state_builder.dart            |  30 +++++
 packages/map_gameplay/pubspec.yaml                 |   1 +
 packages/map_gameplay/test/los_detection_test.dart |  43 +++----
 .../test/new_game_state_builder_test.dart          | 139 ++++++++++++++++++++-
 6 files changed, 198 insertions(+), 25 deletions(-)
```

`git diff --name-only` :

```text
MVP Selbrume/road_map_phase_5.md
packages/map_gameplay/lib/map_gameplay.dart
packages/map_gameplay/lib/src/new_game_state_builder.dart
packages/map_gameplay/pubspec.yaml
packages/map_gameplay/test/los_detection_test.dart
packages/map_gameplay/test/new_game_state_builder_test.dart
```

`git status --short --untracked-files=all` :

```text
 M "MVP Selbrume/road_map_phase_5.md"
 M packages/map_gameplay/lib/map_gameplay.dart
 M packages/map_gameplay/lib/src/new_game_state_builder.dart
 M packages/map_gameplay/pubspec.yaml
 M packages/map_gameplay/test/los_detection_test.dart
 M packages/map_gameplay/test/new_game_state_builder_test.dart
?? reports/roadmap/phase_5/p5_02_new_game_initial_game_state_builder.md
```

## 15. Auto-review critique

Point positif : le lot reste petit et s'appuie sur les briques existantes au lieu de créer un nouveau modèle New Game.

Réserve : `createNewGameStateFromMap(...)` ne choisit pas encore explicitement un spawn par id paramétrable ; il suit le contrat actuel `defaultSpawnId` / fallback `playerStart`. C'est volontaire pour éviter un mini Boot Flow ou un config model prématuré.

Risque résiduel : le builder est prouvé en pur Dart et persistence core, mais pas encore injecté dans le runtime host. Ce raccord est normal après P5-01 et avant P5-03/P5-08.

## 16. Regard critique sur le prompt

Le prompt cadrait bien le piège produit : ne pas transformer New Game en expérience de lancement complète. La demande de `dart analyze` clean a révélé deux diagnostics locaux préexistants ; ils ont été corrigés de manière minimale pour garder le lot validable, avec une justification explicite dans l'Evidence Pack.

Verdict :

```text
P5-02 : validable.
Prochain lot exact : P5-03 — Starter / Initial Party Minimal Flow V0.
```
