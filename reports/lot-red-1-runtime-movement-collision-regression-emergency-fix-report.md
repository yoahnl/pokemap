# Lot RED-1 Runtime Movement / Collision Regression Emergency Fix

## 1. Résumé exécutif honnête

Le runtime avait une régression réelle et sévère sur trois symptômes utilisateur :

- collisions perçues comme cassées ;
- déplacement joueur anormalement lent et saccadé ;
- risque de dérive logique/visuelle sur certains repositionnements runtime.

La racine n'était pas dans le battle BAG ni dans `map_battle`.

Le problème venait d'un mélange incohérent entre :

- des collisions legacy `collisionProfile.cells` encore présentes dans le contenu projet ;
- un cache pixel monde utilisé par le vrai déplacement joueur qui ne reflétait pas ces collisions legacy ;
- un fallback runtime qui rescannait les `placedElements` en boucle sur un hot path ;
- quelques chemins runtime qui changeaient la cellule logique du joueur sans reconstruire proprement `playerPositionPx`.

Le correctif RED-1 a restauré une sémantique runtime cohérente sans ouvrir de nouveau système collision :

- les cellules collisionnées rebloquent ;
- les entités bloquantes rebloquent ;
- les placed elements collisionnés legacy rebloquent la vraie hitbox joueur ;
- le scan chaud des collisions legacy a été supprimé ;
- les transitions runtime testées restent visuellement alignées à la position logique ;
- un step cardinal atteint exactement la case attendue, sans demi-offset.

## 2. Symptômes observés

Symptômes remontés côté runtime :

- les collisions ne bloquaient plus comme avant ;
- le personnage donnait l'impression de "se traîner" ;
- le jeu laggait fortement ;
- après certaines transitions, le risque d'écart entre position logique et position rendue du joueur restait plausible.

## 3. État git capturé avant rédaction du report

Sorties exactes relevées avant création de ce report :

```bash
git status --short --untracked-files=all
 M examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj
 M packages/map_gameplay/lib/src/gameplay_world_state.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/test/playable_map_game_input_test.dart
?? packages/map_gameplay/test/runtime_movement_collision_regression_test.dart
```

```bash
git diff --stat
 .../macos/Runner.xcodeproj/project.pbxproj         |  10 +-
 .../map_gameplay/lib/src/gameplay_world_state.dart | 102 +++++--
 .../src/presentation/flame/playable_map_game.dart  |  67 ++++-
 .../test/playable_map_game_input_test.dart         | 333 +++++++++++++++++++++
 4 files changed, 466 insertions(+), 46 deletions(-)
```

```bash
git ls-files --others --exclude-standard
packages/map_gameplay/test/runtime_movement_collision_regression_test.dart
```

## 4. Classification de la dirtiness

- `preexisting_in_scope`: aucune dirtiness RED-1 distincte ré-observée avant ce correctif
- `preexisting_out_of_scope`: `examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj`
- `modified_by_this_lot`:
  - `packages/map_gameplay/lib/src/gameplay_world_state.dart`
  - `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - `packages/map_runtime/test/playable_map_game_input_test.dart`
- `created_by_this_lot`:
  - `packages/map_gameplay/test/runtime_movement_collision_regression_test.dart`
  - ce report

## 5. Diagnostic racine

### 5.1 Collision legacy non projetée dans la vraie collision joueur

Le déplacement réel du joueur s'appuie sur le cache pixel monde dans :

- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_world_state.dart`

Or les placed elements legacy définis avec :

- `collisionProfile.cells`

étaient encore visibles pour des systèmes grille, mais pas correctement intégrés au cache pixel utilisé par la vraie hitbox joueur.

Conséquence :

- une cellule pouvait sembler "collisionnée" côté logique auteur ;
- mais la vraie collision runtime du joueur pouvait continuer à traverser l'obstacle.

### 5.2 Fallback trop coûteux sur un hot path

Le fallback legacy rescannait les `placedElements` à chaque lookup de blocage.

Sur une grande carte avec beaucoup d'éléments placés, cela rendait :

- `isBlocked(...)`
- `movementBlockReasonAt(...)`

beaucoup trop coûteux.

Conséquence :

- gros lag ;
- sensation de déplacement anormalement lent ;
- dégradation directe du frame time sur les chemins de mouvement.

### 5.3 Drift grid -> pixel sur certains repositionnements runtime

Dans :

- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

certaines opérations runtime changeaient la cellule logique du joueur en modifiant seulement `pos`, sans reconstruire `playerPositionPx` avec la même convention que le rendu et les transitions.

Conséquence :

- risque de décalage entre position logique et position visuelle après certains repositionnements forcés.

## 6. Corrections appliquées

### 6.1 `packages/map_gameplay/lib/src/gameplay_world_state.dart`

Corrections apportées :

- ajout d'un cache dédié `_placedElementCellCollisionCache` pour les collisions legacy par cellule ;
- construction de ce cache dès `GameplayWorldState.initial(...)` et `GameplayWorldState.fromMap(...)` ;
- intégration de ce cache dans `movementBlockReasonAt(...)` ;
- intégration de ces collisions legacy dans `_buildPixelCollisionCache(...)` en les stampant comme tuiles solides complètes ;
- suppression du besoin de rescanner les `placedElements` sur le hot path ;
- propagation cohérente du cache dans les reconstructions d'état monde.

Effet obtenu :

- les placed elements collisionnés legacy bloquent à nouveau la vraie hitbox joueur ;
- les lookups restent rapides ;
- la sémantique collision redevient cohérente entre grille et runtime.

### 6.2 `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

Corrections apportées :

- ajout d'un helper `_gridAlignedPlayerState(...)` pour reconstruire proprement `GameplayPlayerState` depuis une cellule logique ;
- `debugSetPlayerStateForTest(...)` utilise désormais cette reconstruction cohérente ;
- les chemins joueur dans `_startScriptedNpcStep(...)` et `_commitScriptedNpcPosition(...)` utilisent la même convention ;
- ajout de seams de debug testables :
  - `debugRenderedPlayerFootCell`
  - `debugPlayerWorldTopLeft`
  - `debugExpectedPlayerWorldTopLeft`
  - `debugIsPlayerStepping`
  - `debugHasPendingMapTransition`

Effet obtenu :

- un step cardinal termine sur la case attendue ;
- warp et connection restent visuellement alignés à la position logique ;
- pas de demi-offset parasite sur les chemins testés.

## 7. Fichiers modifiés / créés

Modifiés :

- `/Users/karim/Project/pokemonProject/packages/map_gameplay/lib/src/gameplay_world_state.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `/Users/karim/Project/pokemonProject/packages/map_runtime/test/playable_map_game_input_test.dart`

Créés :

- `/Users/karim/Project/pokemonProject/packages/map_gameplay/test/runtime_movement_collision_regression_test.dart`
- `/Users/karim/Project/pokemonProject/reports/lot-red-1-runtime-movement-collision-regression-emergency-fix-report.md`

Volontairement non touchés :

- `packages/map_battle/**`
- `packages/map_editor/**`
- `packages/map_core/**`
- la logique BAG battle
- tout nouveau système collision

## 8. Tests ajoutés / renforcés

### 8.1 `packages/map_gameplay/test/runtime_movement_collision_regression_test.dart`

Couverture ajoutée :

- `collision cell blocks the player`
- `blocking entity blocks the player`
- `placed element collision blocks the player`
- `legacy placed element collision lookups stay cheap`

Ces tests verrouillent :

- collision carte ;
- collision entité ;
- collision placed element legacy ;
- non-régression de perf sur le chemin de blocage.

### 8.2 `packages/map_runtime/test/playable_map_game_input_test.dart`

Couverture ajoutée :

- `one cardinal step lands on the expected cell without a visual offset`
- `warp transition keeps the player visually aligned to the logical target`
- `connection transition keeps the player visually aligned to the logical target`

Ces tests verrouillent :

- alignement logique/visuel du joueur ;
- absence de demi-offset ;
- stabilité des transitions runtime ciblées.

## 9. Validations exécutées

Commandes exécutées :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && /opt/homebrew/bin/dart test
```

Résultat :

- vert

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter test test/playable_map_game_input_test.dart test/playable_map_game_whiteout_lite_test.dart test/wild_battle_end_to_end_flow_test.dart
```

Résultat :

- vert

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && /opt/homebrew/bin/flutter test test/phase_a_golden_slice_launch_test.dart
```

Résultat :

- vert

```bash
cd /Users/karim/Project/pokemonProject/packages/map_gameplay && /opt/homebrew/bin/dart analyze lib/src/gameplay_world_state.dart test/runtime_movement_collision_regression_test.dart
```

Résultat :

- vert

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub lib/src/presentation/flame/playable_map_game.dart test/playable_map_game_input_test.dart test/playable_map_game_whiteout_lite_test.dart test/wild_battle_end_to_end_flow_test.dart
```

Résultat :

- vert

## 10. Preuve que le patch reste borné

Le patch ne continue pas le lot 9c et n'ajoute pas de feature gameplay.

Il se limite à :

- restaurer les collisions runtime ;
- retirer le coût pathologique sur les lookups legacy ;
- réaligner la reconstruction joueur grid -> pixel sur des chemins runtime ciblés ;
- ajouter les tests de non-régression nécessaires.

Il ne fait pas :

- nouveau moteur collision ;
- offset magique ;
- patch cosmétique ;
- modification battle ;
- modification `map_battle` ;
- modification `map_editor`.

## 11. Note sur `project_overview_old.txt`

Le fichier :

- `/Users/karim/Project/pokemonProject/project_overview_old.txt`

est utile comme snapshot d'arborescence/historique de surface, mais pas comme diff source fiable pour identifier la racine logique de cette régression.

Le vrai signal technique est venu :

- du diff des fichiers runtime/gameplay touchés ;
- du repro testable ;
- puis des tests rouges sur collision runtime.

## 12. Limites restantes

Ce correctif restaure le comportement runtime stable ciblé, mais ce report ne prétend pas fermer :

- une refonte collision pixel-level plus large ;
- un audit exhaustif de tous les chemins de transition non couverts ;
- un polish gameplay plus vaste.

Le but était l'urgence RED-1 :

- collisions ;
- vitesse de déplacement ;
- alignement joueur après step/warp/connection.

## 13. Décision finale

RED-1 est réparé de façon bornée et testée.

Le runtime retrouve :

- des collisions bloquantes fonctionnelles ;
- une vitesse de déplacement normale ;
- un placement visuel cohérent du joueur sur les chemins testés ;
- une couverture de non-régression dédiée pour éviter le retour de cette classe de panne.

## 14. Code exact modifié

Cette section contient le code exact du correctif RED-1 dans le périmètre utile.

Je n'y inclus pas :

- le `project.pbxproj` hors scope ;
- ce report lui-même ;
- aucun fichier battle/editor non touché.

### 14.1 Diff exact — `packages/map_gameplay/lib/src/gameplay_world_state.dart`

```diff
diff --git a/packages/map_gameplay/lib/src/gameplay_world_state.dart b/packages/map_gameplay/lib/src/gameplay_world_state.dart
index 6a5c7650..d4c1896e 100644
--- a/packages/map_gameplay/lib/src/gameplay_world_state.dart
+++ b/packages/map_gameplay/lib/src/gameplay_world_state.dart
@@ -29,6 +29,7 @@ class GameplayWorldState {
     required this.map,
     required this.player,
     required List<bool> tileCollisionCellCache,
+    required List<bool> placedElementCellCollisionCache,
     required List<bool> pixelCollisionCache,
     required Map<int, MapEntity> blockingEntityByPos,
     required Map<int, List<MapWarp>> warpCandidatesByPos,
@@ -51,6 +52,7 @@ class GameplayWorldState {
     this.npcMapPresencePredicate,
     required ProjectManifest? projectManifest,
   })  : _tileCollisionCellCache = tileCollisionCellCache,
+        _placedElementCellCollisionCache = placedElementCellCollisionCache,
         _pixelCollisionCache = pixelCollisionCache,
         _blockingEntityByPos = blockingEntityByPos,
         _projectManifest = projectManifest,
@@ -86,6 +88,11 @@ class GameplayWorldState {
       map,
       npcPresence: npcMapPresencePredicate,
     );
+    final placedElementCellCollisionCache =
+        _buildPlacedElementCellCollisionCache(
+      map,
+      project: project,
+    );
     return GameplayWorldState._(
       map: map,
       player: GameplayPlayerState.fromGridSpawn(
@@ -98,12 +105,14 @@ class GameplayWorldState {
         mapHeightCells: map.size.height,
       ),
       tileCollisionCellCache: _buildTileCollisionCellCache(map),
+      placedElementCellCollisionCache: placedElementCellCollisionCache,
       blockingEntityByPos: blockingEntities,
       pixelCollisionCache: _buildPixelCollisionCache(
         map,
         project: project,
         tileWidth: tileWidth,
         tileHeight: tileHeight,
+        placedElementCellCollisionCache: placedElementCellCollisionCache,
         blockingEntityByPos: blockingEntities,
       ),
       warpCandidatesByPos:
@@ -184,6 +193,11 @@ class GameplayWorldState {
       tileHeightPx: tileHeight,
     );
     final cache = _buildTileCollisionCellCache(map);
+    final placedElementCellCollisionCache =
+        _buildPlacedElementCellCollisionCache(
+      map,
+      project: project,
+    );
     final blockingEntities = _buildBlockingEntityByPos(
       map,
       npcPresence: npcMapPresencePredicate,
@@ -193,6 +207,7 @@ class GameplayWorldState {
       project: project,
       tileWidth: tileWidth,
       tileHeight: tileHeight,
+      placedElementCellCollisionCache: placedElementCellCollisionCache,
       blockingEntityByPos: blockingEntities,
     );
     final warps = _buildWarpCandidatesByPos(map, tileWidth, tileHeight);
@@ -204,6 +219,7 @@ class GameplayWorldState {
       map: map,
       player: player,
       tileCollisionCellCache: cache,
+      placedElementCellCollisionCache: placedElementCellCollisionCache,
       pixelCollisionCache: pixelCache,
       blockingEntityByPos: blockingEntities,
       warpCandidatesByPos: warps,
@@ -282,6 +298,7 @@ class GameplayWorldState {
 
   /// Calque collision **tuiles** uniquement (grille auteur). Pas les éléments placés.
   final List<bool> _tileCollisionCellCache;
+  final List<bool> _placedElementCellCollisionCache;
   final List<bool> _pixelCollisionCache;
   final Map<int, MapEntity> _blockingEntityByPos;
   final Map<int, List<MapWarp>> _warpCandidatesByPos;
@@ -399,12 +416,10 @@ class GameplayWorldState {
     }
     final index = y * map.size.width + x;
     if (_tileCollisionCellCache[index] ||
+        _placedElementCellCollisionCache[index] ||
         _blockingEntityByPos.containsKey(index)) {
       return GameplayMovementBlockReason.solid;
     }
-    if (_hasLegacyPlacedElementCellCollision(x, y)) {
-      return GameplayMovementBlockReason.solid;
-    }
     return movementBlockReasonAtPlayerFeetCellForWaterAndGridSolidTrial(
       cellX: x,
       cellY: y,
@@ -425,31 +440,6 @@ class GameplayWorldState {
         null;
   }
 
-  bool _hasLegacyPlacedElementCellCollision(int x, int y) {
-    final project = _projectManifest;
-    if (project == null) {
-      return false;
-    }
-    final elementById = <String, ProjectElementEntry>{
-      for (final entry in project.elements) entry.id: entry,
-    };
-    for (final instance in map.placedElements) {
-      if (!instance.applyCollision) {
-        continue;
-      }
-      final profile = elementById[instance.elementId]?.collisionProfile;
-      if (profile == null || profile.collisionMask != null) {
-        continue;
-      }
-      for (final cell in profile.cells) {
-        if (instance.pos.x + cell.x == x && instance.pos.y + cell.y == y) {
-          return true;
-        }
-      }
-    }
-    return false;
-  }
-
   MapWarp? warpAt(int x, int y) {
     return _resolveWarpCandidate(
       x: x,
@@ -621,6 +611,7 @@ class GameplayWorldState {
         map: map,
         player: player,
         tileCollisionCellCache: _tileCollisionCellCache,
+        placedElementCellCollisionCache: _placedElementCellCollisionCache,
         pixelCollisionCache: _pixelCollisionCache,
         blockingEntityByPos: _blockingEntityByPos,
         warpCandidatesByPos: _warpCandidatesByPos,
@@ -656,11 +647,13 @@ class GameplayWorldState {
       map: map,
       player: player,
       tileCollisionCellCache: _tileCollisionCellCache,
+      placedElementCellCollisionCache: _placedElementCellCollisionCache,
       pixelCollisionCache: _buildPixelCollisionCache(
         map,
         project: _projectManifest,
         tileWidth: _tileWidth,
         tileHeight: _tileHeight,
+        placedElementCellCollisionCache: _placedElementCellCollisionCache,
         blockingEntityByPos: newBlocking,
       ),
       blockingEntityByPos: newBlocking,
@@ -729,11 +722,13 @@ class GameplayWorldState {
       map: updatedMap,
       player: player,
       tileCollisionCellCache: _tileCollisionCellCache,
+      placedElementCellCollisionCache: _placedElementCellCollisionCache,
       pixelCollisionCache: _buildPixelCollisionCache(
         updatedMap,
         project: _projectManifest,
         tileWidth: _tileWidth,
         tileHeight: _tileHeight,
+        placedElementCellCollisionCache: _placedElementCellCollisionCache,
         blockingEntityByPos: newBlocking,
       ),
       // Les entités bloquantes et interactives doivent refléter la nouvelle map.
@@ -865,6 +860,7 @@ List<bool> _buildPixelCollisionCache(
   required ProjectManifest? project,
   required int tileWidth,
   required int tileHeight,
+  required List<bool> placedElementCellCollisionCache,
   required Map<int, MapEntity> blockingEntityByPos,
 }) {
   final safeTileWidth = tileWidth <= 0 ? 16 : tileWidth;
@@ -956,7 +952,23 @@ List<bool> _buildPixelCollisionCache(
     );
   }
 
-  // 2) Éléments placés : **uniquement** [ElementCollisionPixelMask] (pas `cells`).
+  for (var i = 0;
+      i < placedElementCellCollisionCache.length &&
+          i < map.size.width * map.size.height;
+      i++) {
+    if (!placedElementCellCollisionCache[i]) {
+      continue;
+    }
+    final x = i % map.size.width;
+    final y = i ~/ map.size.width;
+    stampSolidRect(
+      leftPx: x * safeTileWidth,
+      topPx: y * safeTileHeight,
+      rectWidthPx: safeTileWidth,
+      rectHeightPx: safeTileHeight,
+    );
+  }
+
   final elementById = project == null
       ? const <String, ProjectElementEntry>{}
       : {
@@ -1002,6 +1014,38 @@ List<bool> _buildPixelCollisionCache(
   return cache;
 }
 
+List<bool> _buildPlacedElementCellCollisionCache(
+  MapData map, {
+  required ProjectManifest? project,
+}) {
+  final size = map.size.width * map.size.height;
+  final cache = List<bool>.filled(size, false);
+  if (size <= 0 || project == null) {
+    return cache;
+  }
+  final elementById = <String, ProjectElementEntry>{
+    for (final entry in project.elements) entry.id: entry,
+  };
+  for (final instance in map.placedElements) {
+    if (!instance.applyCollision) {
+      continue;
+    }
+    final profile = elementById[instance.elementId]?.collisionProfile;
+    if (profile == null || profile.collisionMask != null) {
+      continue;
+    }
+    for (final cell in profile.cells) {
+      final x = instance.pos.x + cell.x;
+      final y = instance.pos.y + cell.y;
+      if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
+        continue;
+      }
+      cache[y * map.size.width + x] = true;
+    }
+  }
+  return cache;
+}
+
 List<bool> _buildWaterCellCache(
   MapData map, {
   required ProjectManifest? project,
```

### 14.2 Diff exact — `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 392cea54..5cfe084d 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -302,6 +302,34 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   @visibleForTesting
   String get debugFlowPhaseName => _flowPhase.name;
 
+  @visibleForTesting
+  bool get debugIsPlayerStepping => _player.isStepping;
+
+  @visibleForTesting
+  bool get debugHasPendingMapTransition =>
+      _pendingWarp != null || _pendingConnection != null;
+
+  @visibleForTesting
+  GridPos? get debugRenderedPlayerFootCell =>
+      isLoaded ? _renderedPlayerFootGridCell() : null;
+
+  @visibleForTesting
+  Vector2 get debugPlayerWorldTopLeft => _player.position.clone();
+
+  @visibleForTesting
+  Vector2 get debugExpectedPlayerWorldTopLeft {
+    final tileWidth = _bundle.manifest.settings.tileWidth;
+    final tileHeight = _bundle.manifest.settings.tileHeight;
+    final scaleX = _cellWidth / (tileWidth > 0 ? tileWidth : 1);
+    final scaleY = _cellHeight / (tileHeight > 0 ? tileHeight : 1);
+    final origin = _player.mapOrigin;
+    final topLeft = _world.player.playerPositionPx;
+    return Vector2(
+      (origin.x + topLeft.leftPx * scaleX).roundToDouble(),
+      (origin.y + topLeft.topPx * scaleY).roundToDouble(),
+    );
+  }
+
   @visibleForTesting
   void debugApplyBattleOutcomeForTest({
     required RuntimeActiveBattleContext context,
@@ -324,15 +352,9 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     required Direction facing,
     MovementMode movementMode = MovementMode.walk,
   }) {
-    // Petit seam de test volontaire :
-    // - il permet de placer le joueur sur une cellule précise avant un scénario
-    //   de reprise runtime ;
-    // - il évite d'écrire un test d'input Flame plus fragile que la logique que
-    //   l'on cherche réellement à prouver ici ;
-    // - il ne sert pas au produit, uniquement à valider la cohérence du lot 15.
     _world = _world.withPlayer(
-      _world.player.copyWith(
-        pos: position,
+      _gridAlignedPlayerState(
+        position: position,
         facing: facing,
         movementMode: movementMode,
       ),
@@ -5835,7 +5857,10 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   }) {
     if (entityId.trim() == 'player') {
       final walkFacing = _directionFromEntityFacing(facing);
-      final nextState = _world.player.copyWith(pos: to, facing: walkFacing);
+      final nextState = _gridAlignedPlayerState(
+        position: to,
+        facing: walkFacing,
+      );
       _player.startStep(
         nextState,
         durationSeconds: durationSeconds ?? PlayerComponent.kDefaultStepSeconds,
@@ -5884,7 +5909,10 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       final facing = _directionBetweenAdjacent(from: from, to: position) ??
           _world.player.facing;
       _world = _world.withPlayer(
-        _world.player.copyWith(pos: position, facing: facing),
+        _gridAlignedPlayerState(
+          position: position,
+          facing: facing,
+        ),
       );
       _runtimeNpcPositions['player'] = position;
       _scriptedNpcReservedOccupiedCellsByEntity.remove(entityId);
@@ -5906,6 +5934,25 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     return false;
   }
 
+  GameplayPlayerState _gridAlignedPlayerState({
+    required GridPos position,
+    Direction? facing,
+    MovementMode? movementMode,
+  }) {
+    final current = _world.player;
+    return GameplayPlayerState.fromGridSpawn(
+      cell: position,
+      facing: facing ?? current.facing,
+      movementMode: movementMode ?? current.movementMode,
+      tileWidthPx: _bundle.manifest.settings.tileWidth,
+      tileHeightPx: _bundle.manifest.settings.tileHeight,
+      mapWidthCells: _world.map.size.width,
+      mapHeightCells: _world.map.size.height,
+      spriteWidthPx: current.playerSpriteWidthPx,
+      spriteHeightPx: current.playerSpriteHeightPx,
+    );
+  }
+
   void _reserveScriptedNpcStepOccupiedCells({
     required String entityId,
     required GridPos fromAnchorPos,
```

### 14.3 Diff exact — `packages/map_runtime/test/playable_map_game_input_test.dart`

```diff
diff --git a/packages/map_runtime/test/playable_map_game_input_test.dart b/packages/map_runtime/test/playable_map_game_input_test.dart
index b8012ea9..edecd653 100644
--- a/packages/map_runtime/test/playable_map_game_input_test.dart
+++ b/packages/map_runtime/test/playable_map_game_input_test.dart
@@ -1,10 +1,14 @@
+import 'dart:convert';
+import 'dart:io';
 import 'dart:ui' show KeyEventDeviceType;
 
+import 'package:flame/components.dart';
 import 'package:flutter/services.dart';
 import 'package:flutter/widgets.dart' show KeyEventResult;
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_runtime/map_runtime.dart';
+import 'package:path/path.dart' as p;
 
 void main() {
   TestWidgetsFlutterBinding.ensureInitialized();
@@ -95,6 +99,140 @@ void main() {
         ],
       );
     });
+
+    test('one cardinal step lands on the expected cell without a visual offset',
+        () async {
+      final root = await Directory.systemTemp.createTemp(
+        'runtime_step_regression_',
+      );
+      addTearDown(() async {
+        if (await root.exists()) {
+          await root.delete(recursive: true);
+        }
+      });
+      final projectFilePath = await _writeRuntimeProject(
+        root,
+        maps: <MapData>[
+          _singleStepMap(),
+        ],
+      );
+      final bundle = await loadRuntimeMapBundle(
+        projectFilePath: projectFilePath,
+        mapId: 'step_map',
+      );
+      final game = _TestPlayableMapGame(
+        bundle: bundle,
+        projectFilePath: projectFilePath,
+      );
+
+      game.onGameResize(_testViewportSize);
+      await game.onLoad();
+
+      await _runSingleMove(game, RuntimeInputControl.right);
+
+      expect(game.gameStateSnapshot.currentMapId, 'step_map');
+      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
+      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 0));
+      expect(
+          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
+    });
+
+    test(
+        'warp transition keeps the player visually aligned to the logical target',
+        () async {
+      final root = await Directory.systemTemp.createTemp(
+        'runtime_warp_regression_',
+      );
+      addTearDown(() async {
+        if (await root.exists()) {
+          await root.delete(recursive: true);
+        }
+      });
+      final projectFilePath = await _writeRuntimeProject(
+        root,
+        maps: <MapData>[
+          _warpSourceMap(),
+          _targetMap(id: 'warp_target'),
+        ],
+      );
+      final bundle = await loadRuntimeMapBundle(
+        projectFilePath: projectFilePath,
+        mapId: 'warp_source',
+      );
+      final game = _TestPlayableMapGame(
+        bundle: bundle,
+        projectFilePath: projectFilePath,
+      );
+
+      game.onGameResize(_testViewportSize);
+      await game.onLoad();
+
+      await _runSingleMove(game, RuntimeInputControl.right);
+      await _pumpUntil(
+        game,
+        () =>
+            game.gameStateSnapshot.currentMapId == 'warp_target' &&
+            game.debugFlowPhaseName == 'overworld' &&
+            !game.debugIsPlayerStepping &&
+            !game.debugHasPendingMapTransition,
+      );
+
+      expect(game.gameStateSnapshot.currentMapId, 'warp_target');
+      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 1));
+      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 1, y: 1));
+      expect(
+          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
+    });
+
+    test(
+        'connection transition keeps the player visually aligned to the logical target',
+        () async {
+      final root = await Directory.systemTemp.createTemp(
+        'runtime_connection_regression_',
+      );
+      addTearDown(() async {
+        if (await root.exists()) {
+          await root.delete(recursive: true);
+        }
+      });
+      final projectFilePath = await _writeRuntimeProject(
+        root,
+        maps: <MapData>[
+          _connectionSourceMap(),
+          _targetMap(id: 'connection_target'),
+        ],
+      );
+      final bundle = await loadRuntimeMapBundle(
+        projectFilePath: projectFilePath,
+        mapId: 'connection_source',
+      );
+      final game = _TestPlayableMapGame(
+        bundle: bundle,
+        projectFilePath: projectFilePath,
+      );
+
+      game.onGameResize(_testViewportSize);
+      await game.onLoad();
+
+      await _runSingleMove(game, RuntimeInputControl.right);
+      await _pumpUntil(
+        game,
+        () =>
+            game.gameStateSnapshot.currentMapId == 'connection_target' &&
+            game.debugFlowPhaseName == 'overworld' &&
+            !game.debugIsPlayerStepping &&
+            !game.debugHasPendingMapTransition,
+      );
+
+      expect(game.gameStateSnapshot.currentMapId, 'connection_target');
+      expect(
+        game.gameStateSnapshot.playerPosition,
+        const GridPos(x: 0, y: 0),
+      );
+      expect(game.debugRenderedPlayerFootCell, const GridPos(x: 0, y: 0));
+      expect(
+          game.debugPlayerWorldTopLeft, game.debugExpectedPlayerWorldTopLeft);
+    });
   });
 }
 
@@ -113,6 +251,16 @@ class _RecordingPlayableMapGame extends PlayableMapGame {
   }
 }
 
+class _TestPlayableMapGame extends PlayableMapGame {
+  _TestPlayableMapGame({
+    required super.bundle,
+    required super.projectFilePath,
+  });
+
+  @override
+  bool get isLoaded => true;
+}
+
 RuntimeMapBundle _baseBundle() {
   return RuntimeMapBundle(
     manifest: const ProjectManifest(
@@ -138,3 +286,188 @@ RuntimeMapBundle _baseBundle() {
     tilesetAbsolutePathsById: const {},
   );
 }
+
+final _testViewportSize = Vector2(640, 480);
+
+Future<void> _runSingleMove(
+  PlayableMapGame game,
+  RuntimeInputControl control,
+) async {
+  expect(
+    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
+    isTrue,
+  );
+  game.update(0.016);
+  expect(
+    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control)),
+    isTrue,
+  );
+  await _pumpUntil(
+    game,
+    () => !game.debugIsPlayerStepping && !game.debugHasPendingMapTransition,
+  );
+}
+
+Future<void> _pumpUntil(
+  PlayableMapGame game,
+  bool Function() done, {
+  int maxTicks = 240,
+}) async {
+  for (var i = 0; i < maxTicks; i++) {
+    if (done()) {
+      return;
+    }
+    game.update(0.016);
+    await Future<void>.delayed(Duration.zero);
+  }
+  fail('Timed out waiting for the runtime game to settle.');
+}
+
+Future<String> _writeRuntimeProject(
+  Directory root, {
+  required List<MapData> maps,
+}) async {
+  final manifest = ProjectManifest(
+    name: 'Runtime Movement Regression',
+    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
+    maps: maps
+        .map(
+          (map) => ProjectMapEntry(
+            id: map.id,
+            name: map.name,
+            relativePath: 'maps/${map.id}.json',
+          ),
+        )
+        .toList(growable: false),
+    tilesets: const <ProjectTilesetEntry>[],
+  );
+  final mapsDir = Directory(p.join(root.path, 'maps'));
+  await mapsDir.create(recursive: true);
+  for (final map in maps) {
+    await File(p.join(mapsDir.path, '${map.id}.json')).writeAsString(
+      const JsonEncoder.withIndent('  ').convert(map.toJson()),
+    );
+  }
+  final projectFile = File(p.join(root.path, 'project.json'));
+  await projectFile.writeAsString(
+    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
+  );
+  return projectFile.path;
+}
+
+MapData _singleStepMap() {
+  return const MapData(
+    id: 'step_map',
+    name: 'Step Map',
+    size: GridSize(width: 3, height: 2),
+    layers: <MapLayer>[
+      MapLayer.object(id: 'objects', name: 'Objects'),
+    ],
+    entities: <MapEntity>[
+      MapEntity(
+        id: 'spawn_step',
+        name: 'Spawn Step',
+        kind: MapEntityKind.spawn,
+        pos: GridPos(x: 0, y: 0),
+        blocksMovement: false,
+        spawn: MapEntitySpawnData(
+          role: EntitySpawnRole.playerStart,
+          facing: EntityFacing.east,
+        ),
+      ),
+    ],
+    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_step'),
+  );
+}
+
+MapData _warpSourceMap() {
+  return const MapData(
+    id: 'warp_source',
+    name: 'Warp Source',
+    size: GridSize(width: 3, height: 2),
+    layers: <MapLayer>[
+      MapLayer.object(id: 'objects', name: 'Objects'),
+    ],
+    entities: <MapEntity>[
+      MapEntity(
+        id: 'spawn_warp_source',
+        name: 'Spawn Warp Source',
+        kind: MapEntityKind.spawn,
+        pos: GridPos(x: 0, y: 0),
+        blocksMovement: false,
+        spawn: MapEntitySpawnData(
+          role: EntitySpawnRole.playerStart,
+          facing: EntityFacing.east,
+        ),
+      ),
+    ],
+    warps: <MapWarp>[
+      MapWarp(
+        id: 'warp_to_target',
+        pos: GridPos(x: 1, y: 0),
+        targetMapId: 'warp_target',
+        targetPos: GridPos(x: 1, y: 1),
+      ),
+    ],
+    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_warp_source'),
+  );
+}
+
+MapData _connectionSourceMap() {
+  return const MapData(
+    id: 'connection_source',
+    name: 'Connection Source',
+    size: GridSize(width: 2, height: 2),
+    layers: <MapLayer>[
+      MapLayer.object(id: 'objects', name: 'Objects'),
+    ],
+    entities: <MapEntity>[
+      MapEntity(
+        id: 'spawn_connection_source',
+        name: 'Spawn Connection Source',
+        kind: MapEntityKind.spawn,
+        pos: GridPos(x: 1, y: 0),
+        blocksMovement: false,
+        spawn: MapEntitySpawnData(
+          role: EntitySpawnRole.playerStart,
+          facing: EntityFacing.east,
+        ),
+      ),
+    ],
+    connections: <MapConnection>[
+      MapConnection(
+        direction: MapConnectionDirection.east,
+        targetMapId: 'connection_target',
+        offset: 0,
+      ),
+    ],
+    mapMetadata: MapMetadata(defaultSpawnId: 'spawn_connection_source'),
+  );
+}
+
+MapData _targetMap({
+  required String id,
+}) {
+  return MapData(
+    id: id,
+    name: 'Target Map',
+    size: const GridSize(width: 3, height: 2),
+    layers: const <MapLayer>[
+      MapLayer.object(id: 'objects', name: 'Objects'),
+    ],
+    entities: const <MapEntity>[
+      MapEntity(
+        id: 'spawn_target',
+        name: 'Spawn Target',
+        kind: MapEntityKind.spawn,
+        pos: GridPos(x: 0, y: 0),
+        blocksMovement: false,
+        spawn: MapEntitySpawnData(
+          role: EntitySpawnRole.playerStart,
+          facing: EntityFacing.east,
+        ),
+      ),
+    ],
+    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_target'),
+  );
+}
```

### 14.4 Contenu complet — `packages/map_gameplay/test/runtime_movement_collision_regression_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  group('runtime movement collision regression', () {
    test('collision cell blocks the player', () {
      final world = GameplayWorldState.initial(
        map: const MapData(
          id: 'collision_map',
          name: 'Collision Map',
          size: GridSize(width: 3, height: 1),
          layers: <MapLayer>[
            MapLayer.collision(
              id: 'collision',
              name: 'Collision',
              collisions: <bool>[false, true, false],
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Blocked>());
      expect((result as Blocked).reason, GameplayMovementBlockReason.solid);
      expect(result.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('blocking entity blocks the player', () {
      final world = GameplayWorldState.initial(
        map: const MapData(
          id: 'entity_map',
          name: 'Entity Map',
          size: GridSize(width: 3, height: 1),
          entities: <MapEntity>[
            MapEntity(
              id: 'blocking_npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 1, y: 0),
              blocksMovement: true,
              npc: MapEntityNpcData(),
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Blocked>());
      expect((result as Blocked).reason, GameplayMovementBlockReason.solid);
      expect(result.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('placed element collision blocks the player', () {
      final world = GameplayWorldState.initial(
        map: const MapData(
          id: 'placed_map',
          name: 'Placed Map',
          size: GridSize(width: 3, height: 1),
          placedElements: <MapPlacedElement>[
            MapPlacedElement(
              id: 'rock_1',
              layerId: 'objects',
              elementId: 'rock',
              pos: GridPos(x: 1, y: 0),
              applyCollision: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: const ProjectManifest(
          name: 'Placed Collision Project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'terrain',
              name: 'Terrain',
              relativePath: 'tilesets/terrain.png',
            ),
          ],
          elementCategories: <ProjectElementCategory>[
            ProjectElementCategory(id: 'obstacles', name: 'Obstacles'),
          ],
          elements: <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'rock',
              name: 'Rock',
              tilesetId: 'terrain',
              categoryId: 'obstacles',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                ),
              ],
              collisionProfile: ElementCollisionProfile(
                cells: <GridPos>[GridPos(x: 0, y: 0)],
              ),
            ),
          ],
        ),
      );

      final result = stepGameplayWorld(world, const MoveIntent(Direction.east));

      expect(result, isA<Blocked>());
      expect((result as Blocked).reason, GameplayMovementBlockReason.solid);
      expect(result.world.player.pos, const GridPos(x: 0, y: 0));
    });

    test('legacy placed element collision lookups stay cheap', () {
      const mapWidth = 120;
      const mapHeight = 80;
      final placedElements = <MapPlacedElement>[
        for (var i = 0; i < 5000; i++)
          MapPlacedElement(
            id: 'rock_$i',
            layerId: 'objects',
            elementId: 'rock',
            pos: GridPos(
              x: i % mapWidth,
              y: (i ~/ mapWidth) % mapHeight,
            ),
            applyCollision: true,
          ),
      ];
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'perf_map',
          name: 'Perf Map',
          size: const GridSize(width: mapWidth, height: mapHeight),
          placedElements: placedElements,
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: const ProjectManifest(
          name: 'Perf Project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'terrain',
              name: 'Terrain',
              relativePath: 'tilesets/terrain.png',
            ),
          ],
          elementCategories: <ProjectElementCategory>[
            ProjectElementCategory(id: 'obstacles', name: 'Obstacles'),
          ],
          elements: <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'rock',
              name: 'Rock',
              tilesetId: 'terrain',
              categoryId: 'obstacles',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                ),
              ],
              collisionProfile: ElementCollisionProfile(
                cells: <GridPos>[GridPos(x: 0, y: 0)],
              ),
            ),
          ],
        ),
      );

      final stopwatch = Stopwatch()..start();
      var blocked = 0;
      for (var i = 0; i < 20000; i++) {
        final x = i % mapWidth;
        final y = (i ~/ mapWidth) % mapHeight;
        if (world.isBlocked(x, y)) {
          blocked += 1;
        }
      }
      stopwatch.stop();

      expect(blocked, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(1200));
    });
  });
}
```
