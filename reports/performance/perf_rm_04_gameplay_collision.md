# Evidence Pack — PERF-RM-04 — Collision gameplay en couches

Date : 2026-08-01  
Phase : 1 — Urgences P0  
Finding : `PERF-GAME-01`  
Lots mécaniques associés : `FG-016 TODO`, `FG-182 DONE`, `FG-183 DONE`, `FG-185 PARTIAL/NO-GO` inchangés  
Verdict proposé : **PARTIAL — stockage/move verts, réduction RSS comparable non prouvée**

## Résumé exécutif

`GameplayWorldState` ne construit plus un `List<bool>` de taille monde-pixel. La
collision statique possède les listes de cellules et n’alloue des chunks `Uint32` 32×32
que pour les pixels explicitement solides d’un masque. L’occupancy dynamique est évaluée
séparément et combinée au query. Les transitions joueur, entité, visibilité et règles monde
partagent le même stockage statique.

Le benchmark AOT donne un move p95 de 4 µs à 256² sans masque et 6–9 µs sur trois processus
512² isolés, avec zéro chunk pixel dans ce scénario. Un masque sparse de 64 pixels
traversant quatre chunks conserve exactement 4 chunks/128 mots aux tailles 32² à 256² et
un checksum stable. Les 455 tests gameplay complets,
bridges runtime/goldens et analyses sont verts.

Le statut reste `PARTIAL` : le RSS après-only du nouveau benchmark est trop bruité et ne
dispose pas d’un baseline pre-patch strictement comparable pour prouver l’objectif ≥90 %.

## Scope et non-objectifs

- Règles et stockage dans `map_gameplay`, sans Flutter/Flame.
- Aucune migration JSON ni changement de règle collision/interactions.
- Statique et dynamique séparés ; mouvement sans reconstruction pixel du monde.
- Le validateur narratif conserve son exploration symbolique actuelle ; le partage entre
  états narratifs est hors scope de ce premier sous-lot.
- Statuts FG et roadmap mécaniques non modifiés.

## Audit initial

Le world state matérialisait un bitmap booléen de
`worldPixelWidth × worldPixelHeight`, même sans masque, puis le reconstruisait lors de
changements dynamiques. L’audit signalait move 256² à 50,487 ms et 512² à 179,559 ms. Les
risques majeurs étaient de modifier la priorité `collisionMask`, les règles de visibilité,
les bords 31/32, ou la reachability.

## État Git initial

HEAD : `7f35d44d9f777d25046c6b94d8974a2fdd850a78`

```text
?? reports/performance/pokemap_full_performance_audit.md
?? reports/performance/pokemap_performance_remediation_roadmap.md
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

## Inventaire et zones modifiées

- `packages/map_gameplay/lib/src/collision/world_collision_storage.dart` (créé)
  - cellules statiques, chunks pixel sparse 32×32/`Uint32`, query dynamique et copies
    défensives.
- `packages/map_gameplay/lib/src/gameplay_world_state.dart`
  - remplacement du bitmap monde, séparation dynamique, partage du stockage statique ;
  - diagnostics de caractérisation dans une extension interne non exportée par le barrel.
- `packages/map_gameplay/test/gameplay_world_state_collision_storage_characterization_test.dart`
  (créé)
  - no-mask 256², statique/dynamique, partage, un bit, bords, clipping, rect vide,
    copies défensives.
- `packages/map_gameplay/test/gameplay_world_state_entity_move_test.dart`
  - invariant de partage statique lors d’un move.
- `packages/map_gameplay/benchmark/world_collision_scaling.dart` (créé)
  - schema v2, AOT/JIT, builds/moves/queries, checksums, masque sparse et runs 512 isolés.
- `packages/map_gameplay/test/benchmark/world_collision_scaling_cli_test.dart` (créé)
  - validation CLI et confinement output.
- `reports/performance/plans/2026-08-01-pokemap-perf-rm-04-gameplay-collision.md`
  (créé) : plan TDD du lot.

## Résultats AOT

```bash
cd packages/map_gameplay
dart compile exe benchmark/world_collision_scaling.dart -o build/performance/world_collision_scaling
build/performance/world_collision_scaling --warmups 5 --samples 30 --sizes 32,64,128,256 --isolated-size 512 --isolated-runs 3 --output build/performance/world_collision_scaling.json
```

| Taille cellules | chunks pixel | build p95 | move p95 | 1 000 queries p95 | delta RSS observé |
|---:|---:|---:|---:|---:|---:|
| 32² | 0 | 152 µs | 0 µs | 35 µs | 0 |
| 64² | 0 | 239 µs | 3 µs | 36 µs | 0 |
| 128² | 0 | 654 µs | 2 µs | 71 µs | 0 |
| 256² | 0 | 3 325 µs | 4 µs | 226 µs | −540 672 octets |

Runs 512² isolés, move p95 : 6 µs, 9 µs, 9 µs. Chaque run alloue zéro chunk
pixel et observe un delta RSS après-only nul.

Scénario masque sparse 64 pixels : 4 chunks et 128 mots alloués pour chaque taille ;
build p95 122/376/256/1 337 µs, query p95 1/0/0/0 µs et checksum `02b18e7b` stable.

Ces deltas ne sont pas une mesure de réduction de 90 % : ils sont quantifiés grossièrement,
sans GC contrôlé ni binaire pre-patch dans le même harness.

## Preuves TDD et validation

Les tests ciblés collision/reachability/rotation/LoS ont produit 85 succès. La suite
gameplay complète produit 455 succès. Un warning analyzer initial sur un black-hole de
benchmark a été supprimé ; l’analyse finale est propre.

La validation indépendante a exécuté 85 tests collision/reachability/runtime ciblés, puis la
suite gameplay complète à 455 succès. La passe post-corrections a rejoué 10 tests strictement
centrés sur stockage, mouvement et benchmark CLI. Les deux passages sont verts et
`dart analyze` ne rapporte aucun diagnostic. Les bridges runtime sont inclus dans une suite
runtime finale à `+2315 ~1`, et le golden host produit un succès.

La critique finale confirme que les diagnostics restent hors barrel public, que les
checksums Surface et collision sont déterministes et que le masque sparse alloue exactement
quatre chunks/128 mots. Le build MCP final et ses 23 tests séquentiels sont verts. Les
statuts mécaniques restent inchangés : `FG-016 TODO`, `FG-182 DONE`, `FG-183 DONE`,
`FG-185 PARTIAL/NO-GO`.

## Verdict des passes

- Audit / Architecture : **GO structurel**, statique/dynamique séparés et package boundary
  respectée.
- Implémentation : **GREEN fonctionnel**.
- Tests : **PASS** — 85 ciblés initiaux, 10 post-fix, 455 complets.
- Build / Validation : **PASS** — analyzer gameplay/runtime/host et builds verts.
- Critique finale : **PASS fonctionnel / PARTIAL roadmap**.

## Limites, auto-critique et risques

- Le compteur microseconde donne des 0–2 µs sur petites tailles ; il prouve surtout
  l’absence de scaling catastrophique, pas une distribution fine.
- La gate RSS ≥90 % n’est pas fermée.
- Le scénario principal est volontairement no-mask + une entité ; le masque sparse couvre
  les frontières de chunks mais pas une matrice complète de densité.
- Les diagnostics `debug*` sont portés par une extension importée explicitement depuis
  `src` par les tests/benchmarks et ne sont pas exportés dans `map_gameplay.dart`.
- Le validateur narratif construit toujours des worlds pour ses états symboliques.

Auto-critique : les résultats move et l’absence de bitmap mondial sont solides, mais le
benchmark RSS est insuffisant pour annoncer le gain contractuel. Prochaine étape :
baseline RM00 pre/post dans des processus isolés, densités de masque contrôlées et RSS
stabilisé ; ne pas modifier les règles gameplay entre les deux mesures.

## État Git final

```text
 M examples/playable_runtime_host/lib/main.dart
 M packages/map_authoring/lib/src/domains/maps/autotile_actions.dart
 M packages/map_core/lib/src/operations/surface_variant_role_resolver.dart
 M packages/map_core/test/surface_variant_role_resolver_test.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
 M packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
 M packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart
 M packages/map_gameplay/lib/src/gameplay_world_state.dart
 M packages/map_gameplay/test/gameplay_world_state_entity_move_test.dart
 M packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
 M packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/quarter_turn_pixel_renderer.dart
 M packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart
 M packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart
 M packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
 M packages/map_runtime/test/quarter_turn_pixel_renderer_test.dart
 M packages/map_runtime/test/surface/surface_runtime_resolver_test.dart
?? packages/map_core/benchmark/surface_role_scaling.dart
?? packages/map_core/test/benchmark/surface_role_scaling_cli_test.dart
?? packages/map_gameplay/benchmark/world_collision_scaling.dart
?? packages/map_gameplay/lib/src/collision/world_collision_storage.dart
?? packages/map_gameplay/test/benchmark/world_collision_scaling_cli_test.dart
?? packages/map_gameplay/test/gameplay_world_state_collision_storage_characterization_test.dart
?? packages/map_runtime/test/battle_mobile_command_overlay_asset_loading_test.dart
?? packages/map_runtime/test/playable_map_game_tileset_lifecycle_test.dart
?? packages/map_runtime/test/tile_image_loader_codec_disposal_test.dart
?? packages/map_runtime/test/tile_image_loader_singleflight_test.dart
?? reports/performance/perf_rm_01_runtime_asset_ownership.md
?? reports/performance/perf_rm_02_runtime_occlusion.md
?? reports/performance/perf_rm_03_surface_topology.md
?? reports/performance/perf_rm_04_gameplay_collision.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-01-runtime-asset-ownership.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-02-runtime-occlusion.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-03-surface-topology.md
?? reports/performance/plans/2026-08-01-pokemap-perf-rm-04-gameplay-collision.md
?? reports/performance/pokemap_full_performance_audit.md
?? reports/performance/pokemap_performance_remediation_roadmap.md
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

`git diff --check` : exit 0, aucune sortie. Les trois entrées audit/roadmap/pycache initiales sont préservées ; aucun Git write n’a été exécuté.

## Annexe A — Diff exact des fichiers modifiés

~~~~diff
diff --git a/packages/map_gameplay/lib/src/gameplay_world_state.dart b/packages/map_gameplay/lib/src/gameplay_world_state.dart
index dbf6cbea4..99ceadfdc 100644
--- a/packages/map_gameplay/lib/src/gameplay_world_state.dart
+++ b/packages/map_gameplay/lib/src/gameplay_world_state.dart
@@ -5,6 +5,7 @@ import 'gameplay_exceptions.dart';
 import 'movement_block_reason.dart';
 import 'gameplay_player_state.dart';
 import 'player_spawn_resolver.dart';
+import 'collision/world_collision_storage.dart';
 
 /// Indique si un PNJ doit exister sur la grille pour collision et interaction.
 ///
@@ -41,7 +42,7 @@ class GameplayWorldState {
     required this.player,
     required List<bool> tileCollisionCellCache,
     required List<bool> placedElementCellCollisionCache,
-    required List<bool> pixelCollisionCache,
+    required WorldCollisionStorage staticCollisionStorage,
     required Map<int, MapEntity> blockingEntityByPos,
     required Map<int, List<MapWarp>> warpCandidatesByPos,
     required Map<int, MapEntity> entityByPos,
@@ -62,12 +63,10 @@ class GameplayWorldState {
     required int tileHeight,
     this.npcMapPresencePredicate,
     this.mapEntityPresencePredicate,
-    required ProjectManifest? projectManifest,
   })  : _tileCollisionCellCache = tileCollisionCellCache,
         _placedElementCellCollisionCache = placedElementCellCollisionCache,
-        _pixelCollisionCache = pixelCollisionCache,
+        _staticCollisionStorage = staticCollisionStorage,
         _blockingEntityByPos = blockingEntityByPos,
-        _projectManifest = projectManifest,
         _warpCandidatesByPos = warpCandidatesByPos,
         _entityByPos = entityByPos,
         _actionBehaviorByPos = actionBehaviorByPos,
@@ -107,6 +106,7 @@ class GameplayWorldState {
       map,
       project: project,
     );
+    final tileCollisionCellCache = _buildTileCollisionCellCache(map);
     return GameplayWorldState._(
       map: map,
       player: GameplayPlayerState.fromGridSpawn(
@@ -118,16 +118,16 @@ class GameplayWorldState {
         mapWidthCells: map.size.width,
         mapHeightCells: map.size.height,
       ),
-      tileCollisionCellCache: _buildTileCollisionCellCache(map),
+      tileCollisionCellCache: tileCollisionCellCache,
       placedElementCellCollisionCache: placedElementCellCollisionCache,
       blockingEntityByPos: blockingEntities,
-      pixelCollisionCache: _buildPixelCollisionCache(
+      staticCollisionStorage: _buildStaticCollisionStorage(
         map,
         project: project,
         tileWidth: tileWidth,
         tileHeight: tileHeight,
+        tileCollisionCellCache: tileCollisionCellCache,
         placedElementCellCollisionCache: placedElementCellCollisionCache,
-        blockingEntityByPos: blockingEntities,
       ),
       warpCandidatesByPos:
           _buildWarpCandidatesByPos(map, tileWidth, tileHeight),
@@ -192,7 +192,6 @@ class GameplayWorldState {
       tileHeight: tileHeight,
       npcMapPresencePredicate: npcMapPresencePredicate,
       mapEntityPresencePredicate: mapEntityPresencePredicate,
-      projectManifest: project,
     );
   }
 
@@ -220,13 +219,13 @@ class GameplayWorldState {
       npcPresence: npcMapPresencePredicate,
       entityPresence: mapEntityPresencePredicate,
     );
-    final pixelCache = _buildPixelCollisionCache(
+    final staticCollisionStorage = _buildStaticCollisionStorage(
       map,
       project: project,
       tileWidth: tileWidth,
       tileHeight: tileHeight,
+      tileCollisionCellCache: cache,
       placedElementCellCollisionCache: placedElementCellCollisionCache,
-      blockingEntityByPos: blockingEntities,
     );
     final warps = _buildWarpCandidatesByPos(map, tileWidth, tileHeight);
     final entities = _buildEntityByPos(
@@ -239,7 +238,7 @@ class GameplayWorldState {
       player: player,
       tileCollisionCellCache: cache,
       placedElementCellCollisionCache: placedElementCellCollisionCache,
-      pixelCollisionCache: pixelCache,
+      staticCollisionStorage: staticCollisionStorage,
       blockingEntityByPos: blockingEntities,
       warpCandidatesByPos: warps,
       entityByPos: entities,
@@ -299,7 +298,6 @@ class GameplayWorldState {
       tileHeight: tileHeight,
       npcMapPresencePredicate: npcMapPresencePredicate,
       mapEntityPresencePredicate: mapEntityPresencePredicate,
-      projectManifest: project,
     );
     if (world.worldStaticObstaclesCollidePlayerCollisionRect()) {
       throw GameplaySpawnResolutionException(
@@ -322,7 +320,7 @@ class GameplayWorldState {
   /// Calque collision **tuiles** uniquement (grille auteur). Pas les éléments placés.
   final List<bool> _tileCollisionCellCache;
   final List<bool> _placedElementCellCollisionCache;
-  final List<bool> _pixelCollisionCache;
+  final WorldCollisionStorage _staticCollisionStorage;
   final Map<int, MapEntity> _blockingEntityByPos;
   final Map<int, List<MapWarp>> _warpCandidatesByPos;
   final Map<int, MapEntity> _entityByPos;
@@ -342,12 +340,6 @@ class GameplayWorldState {
   final int _tileWidth;
   final int _tileHeight;
 
-  /// Manifeste projet conservé pour **reconstruire** [_pixelCollisionCache] quand
-  /// [blockingEntityByPos] change (PNJ déplacé, prédicat de présence, etc.).
-  /// Peut être `null` : dans ce cas un rebuild ne peut pas ré-appliquer les
-  /// `pixelMask` d’éléments placés (même comportement qu’à la construction).
-  final ProjectManifest? _projectManifest;
-
   /// Taille tuile projet (pixels) — nécessaire pour projection pieds / rendu.
   int get tileWidthPx => _tileWidth;
   int get tileHeightPx => _tileHeight;
@@ -359,25 +351,10 @@ class GameplayWorldState {
 
   /// Test pixel-level contre l’union des obstacles statiques (bitmap monde).
   bool worldStaticObstaclesCollidePixelRect(PixelRect rect) {
-    final widthPx = map.size.width * _tileWidth;
-    final heightPx = map.size.height * _tileHeight;
-    for (var py = 0; py < rect.heightPx; py++) {
-      final y = rect.topPx + py;
-      for (var px = 0; px < rect.widthPx; px++) {
-        final x = rect.leftPx + px;
-        if (x < 0 || y < 0 || x >= widthPx || y >= heightPx) {
-          return true;
-        }
-        final idx = y * widthPx + x;
-        if (idx < 0 || idx >= _pixelCollisionCache.length) {
-          continue;
-        }
-        if (_pixelCollisionCache[idx]) {
-          return true;
-        }
-      }
-    }
-    return false;
+    return _staticCollisionStorage.collidesPixelRect(
+      rect,
+      isDynamicCellBlocked: _blockingEntityByPos.containsKey,
+    );
   }
 
   /// PNJ scripté / pathfinding : centre de case → bitmap (pas une primitive joueur).
@@ -388,18 +365,11 @@ class GameplayWorldState {
         cellY >= map.size.height) {
       return true;
     }
-    final cx = cellX * _tileWidth + _tileWidth ~/ 2;
-    final cy = cellY * _tileHeight + _tileHeight ~/ 2;
-    final widthPx = map.size.width * _tileWidth;
-    final heightPx = map.size.height * _tileHeight;
-    if (cx < 0 || cy < 0 || cx >= widthPx || cy >= heightPx) {
-      return true;
-    }
-    final idx = cy * widthPx + cx;
-    if (idx < 0 || idx >= _pixelCollisionCache.length) {
-      return false;
-    }
-    return _pixelCollisionCache[idx];
+    return _staticCollisionStorage.isCellCenterBlocked(
+      cellX,
+      cellY,
+      isDynamicCellBlocked: _blockingEntityByPos.containsKey,
+    );
   }
 
   bool isWaterCell(int x, int y) {
@@ -635,7 +605,7 @@ class GameplayWorldState {
         player: player,
         tileCollisionCellCache: _tileCollisionCellCache,
         placedElementCellCollisionCache: _placedElementCellCollisionCache,
-        pixelCollisionCache: _pixelCollisionCache,
+        staticCollisionStorage: _staticCollisionStorage,
         blockingEntityByPos: _blockingEntityByPos,
         warpCandidatesByPos: _warpCandidatesByPos,
         entityByPos: _entityByPos,
@@ -656,7 +626,6 @@ class GameplayWorldState {
         tileHeight: _tileHeight,
         npcMapPresencePredicate: npcMapPresencePredicate,
         mapEntityPresencePredicate: mapEntityPresencePredicate,
-        projectManifest: _projectManifest,
       );
 
   /// Reconstruit les caches spatiaux PNJ après changement de progression (visibilité).
@@ -673,14 +642,7 @@ class GameplayWorldState {
       player: player,
       tileCollisionCellCache: _tileCollisionCellCache,
       placedElementCellCollisionCache: _placedElementCellCollisionCache,
-      pixelCollisionCache: _buildPixelCollisionCache(
-        map,
-        project: _projectManifest,
-        tileWidth: _tileWidth,
-        tileHeight: _tileHeight,
-        placedElementCellCollisionCache: _placedElementCellCollisionCache,
-        blockingEntityByPos: newBlocking,
-      ),
+      staticCollisionStorage: _staticCollisionStorage,
       blockingEntityByPos: newBlocking,
       entityByPos: _buildEntityByPos(
         map,
@@ -705,7 +667,6 @@ class GameplayWorldState {
       tileHeight: _tileHeight,
       npcMapPresencePredicate: predicate,
       mapEntityPresencePredicate: mapEntityPresencePredicate,
-      projectManifest: _projectManifest,
     );
   }
 
@@ -724,14 +685,7 @@ class GameplayWorldState {
       player: player,
       tileCollisionCellCache: _tileCollisionCellCache,
       placedElementCellCollisionCache: _placedElementCellCollisionCache,
-      pixelCollisionCache: _buildPixelCollisionCache(
-        map,
-        project: _projectManifest,
-        tileWidth: _tileWidth,
-        tileHeight: _tileHeight,
-        placedElementCellCollisionCache: _placedElementCellCollisionCache,
-        blockingEntityByPos: newBlocking,
-      ),
+      staticCollisionStorage: _staticCollisionStorage,
       blockingEntityByPos: newBlocking,
       entityByPos: _buildEntityByPos(
         map,
@@ -756,7 +710,6 @@ class GameplayWorldState {
       tileHeight: _tileHeight,
       npcMapPresencePredicate: npcMapPresencePredicate,
       mapEntityPresencePredicate: predicate,
-      projectManifest: _projectManifest,
     );
   }
 
@@ -770,8 +723,8 @@ class GameplayWorldState {
   ///
   /// IMPORTANT:
   /// - si l'entité n'existe pas, on retourne `this` (no-op sûr);
-  /// - on ne modifie pas les layers auteur ; en revanche [_pixelCollisionCache]
-  ///   est **reconstruit** pour refléter le nouveau [blockingEntityByPos].
+  /// - on ne modifie pas les layers auteur ; le stockage statique est partagé,
+  ///   seule l'occupation dynamique des entités est reconstruite.
   GameplayWorldState withEntityPosition(
     String entityId,
     GridPos newPos,
@@ -805,14 +758,7 @@ class GameplayWorldState {
       player: player,
       tileCollisionCellCache: _tileCollisionCellCache,
       placedElementCellCollisionCache: _placedElementCellCollisionCache,
-      pixelCollisionCache: _buildPixelCollisionCache(
-        updatedMap,
-        project: _projectManifest,
-        tileWidth: _tileWidth,
-        tileHeight: _tileHeight,
-        placedElementCellCollisionCache: _placedElementCellCollisionCache,
-        blockingEntityByPos: newBlocking,
-      ),
+      staticCollisionStorage: _staticCollisionStorage,
       // Les entités bloquantes et interactives doivent refléter la nouvelle map.
       blockingEntityByPos: newBlocking,
       entityByPos: _buildEntityByPos(
@@ -840,7 +786,6 @@ class GameplayWorldState {
       tileHeight: _tileHeight,
       npcMapPresencePredicate: npcMapPresencePredicate,
       mapEntityPresencePredicate: mapEntityPresencePredicate,
-      projectManifest: _projectManifest,
     );
   }
 
@@ -936,163 +881,27 @@ List<bool> _buildTileCollisionCellCache(MapData map) {
       },
     );
   }
-  return cache;
+  return List<bool>.unmodifiable(cache);
 }
 
-List<bool> _buildPixelCollisionCache(
+WorldCollisionStorage _buildStaticCollisionStorage(
   MapData map, {
   required ProjectManifest? project,
   required int tileWidth,
   required int tileHeight,
+  required List<bool> tileCollisionCellCache,
   required List<bool> placedElementCellCollisionCache,
-  required Map<int, MapEntity> blockingEntityByPos,
 }) {
   final safeTileWidth = tileWidth <= 0 ? 16 : tileWidth;
   final safeTileHeight = tileHeight <= 0 ? 16 : tileHeight;
-  final widthPx = map.size.width * safeTileWidth;
-  final heightPx = map.size.height * safeTileHeight;
-  final cache = List<bool>.filled(widthPx * heightPx, false);
-  if (widthPx <= 0 || heightPx <= 0) {
-    return cache;
-  }
-
-  void stampSolidRect({
-    required int leftPx,
-    required int topPx,
-    required int rectWidthPx,
-    required int rectHeightPx,
-  }) {
-    for (var py = 0; py < rectHeightPx; py++) {
-      final y = topPx + py;
-      if (y < 0 || y >= heightPx) {
-        continue;
-      }
-      for (var px = 0; px < rectWidthPx; px++) {
-        final x = leftPx + px;
-        if (x < 0 || x >= widthPx) {
-          continue;
-        }
-        cache[y * widthPx + x] = true;
-      }
-    }
-  }
-
-  bool stampPackedMask({
-    required int leftPx,
-    required int topPx,
-    required ElementCollisionPixelMask mask,
-    required QuarterTurnPixelTransform transform,
-  }) {
-    List<bool> decoded;
-    try {
-      decoded = ElementCollisionMaskCodec.decodePackedBits(
-        widthPx: mask.widthPx,
-        heightPx: mask.heightPx,
-        dataBase64: mask.dataBase64,
-      );
-    } catch (_) {
-      return false;
-    }
-    final destinationSize = transform.destinationPixelSize;
-    final destinationLeft = BigInt.from(leftPx);
-    final destinationTop = BigInt.from(topPx);
-    final destinationRight =
-        destinationLeft + BigInt.from(destinationSize.width);
-    final destinationBottom =
-        destinationTop + BigInt.from(destinationSize.height);
-    final worldWidth = BigInt.from(widthPx);
-    final worldHeight = BigInt.from(heightPx);
-    if (destinationRight <= BigInt.zero ||
-        destinationBottom <= BigInt.zero ||
-        destinationLeft >= worldWidth ||
-        destinationTop >= worldHeight) {
-      return true;
-    }
-    final startX =
-        (destinationLeft.isNegative ? -destinationLeft : BigInt.zero).toInt();
-    final startY =
-        (destinationTop.isNegative ? -destinationTop : BigInt.zero).toInt();
-    final endX = (destinationRight > worldWidth
-            ? worldWidth - destinationLeft
-            : BigInt.from(destinationSize.width))
-        .toInt();
-    final endY = (destinationBottom > worldHeight
-            ? worldHeight - destinationTop
-            : BigInt.from(destinationSize.height))
-        .toInt();
-    if (transform.quarterTurns == 0 &&
-        destinationSize.width == mask.widthPx &&
-        destinationSize.height == mask.heightPx) {
-      for (var py = startY; py < endY; py++) {
-        final y = topPx + py;
-        for (var px = startX; px < endX; px++) {
-          final idx = py * mask.widthPx + px;
-          if (idx < 0 || idx >= decoded.length || !decoded[idx]) {
-            continue;
-          }
-          final x = leftPx + px;
-          cache[y * widthPx + x] = true;
-        }
-      }
-      return true;
-    }
-    for (var py = startY; py < endY; py++) {
-      final y = topPx + py;
-      for (var px = startX; px < endX; px++) {
-        final x = leftPx + px;
-        final source = transform.destinationPixelToSourcePixel(
-          GridPos(x: px, y: py),
-        );
-        final idx = source.y * mask.widthPx + source.x;
-        if (idx < 0 || idx >= decoded.length || !decoded[idx]) {
-          continue;
-        }
-        cache[y * widthPx + x] = true;
-      }
-    }
-    return true;
-  }
-
-  // 1) Calque collision carte: toute cellule true => tile plein.
-  for (final layer in map.layers) {
-    layer.whenOrNull(
-      collision: (id, name, isVisible, opacity, collisions) {
-        for (var i = 0; i < collisions.length; i++) {
-          if (!collisions[i]) {
-            continue;
-          }
-          final x = i % map.size.width;
-          final y = i ~/ map.size.width;
-          if (x < 0 || y < 0 || x >= map.size.width || y >= map.size.height) {
-            continue;
-          }
-          stampSolidRect(
-            leftPx: x * safeTileWidth,
-            topPx: y * safeTileHeight,
-            rectWidthPx: safeTileWidth,
-            rectHeightPx: safeTileHeight,
-          );
-        }
-      },
-    );
-  }
-
-  for (var i = 0;
-      i < placedElementCellCollisionCache.length &&
-          i < map.size.width * map.size.height;
-      i++) {
-    if (!placedElementCellCollisionCache[i]) {
-      continue;
-    }
-    final x = i % map.size.width;
-    final y = i ~/ map.size.width;
-    stampSolidRect(
-      leftPx: x * safeTileWidth,
-      topPx: y * safeTileHeight,
-      rectWidthPx: safeTileWidth,
-      rectHeightPx: safeTileHeight,
-    );
-  }
+  final storage = WorldCollisionStorageBuilder(
+    widthCells: map.size.width,
+    heightCells: map.size.height,
+    tileWidthPx: safeTileWidth,
+    tileHeightPx: safeTileHeight,
+    tileCollisionCells: tileCollisionCellCache,
+    placedElementCollisionCells: placedElementCellCollisionCache,
+  );
 
   final elementById = project == null
       ? const <String, ProjectElementEntry>{}
@@ -1146,7 +955,7 @@ List<bool> _buildPixelCollisionCache(
       width: destinationWidth.toInt(),
       height: destinationHeight.toInt(),
     );
-    stampPackedMask(
+    storage.stampPackedMask(
       leftPx: worldLeft.toInt(),
       topPx: worldTop.toInt(),
       mask: mask,
@@ -1158,25 +967,7 @@ List<bool> _buildPixelCollisionCache(
     );
   }
 
-  // 3) Entités bloquantes (PNJ / objets) : tuile pleine par cellule footprint.
-  final w = map.size.width;
-  for (final entry in blockingEntityByPos.entries) {
-    final e = entry.value;
-    if (!e.blocksMovement) {
-      continue;
-    }
-    final idx = entry.key;
-    final cx = idx % w;
-    final cy = idx ~/ w;
-    stampSolidRect(
-      leftPx: cx * safeTileWidth,
-      topPx: cy * safeTileHeight,
-      rectWidthPx: safeTileWidth,
-      rectHeightPx: safeTileHeight,
-    );
-  }
-
-  return cache;
+  return storage.build();
 }
 
 List<bool> _buildPlacedElementCellCollisionCache(
@@ -1186,7 +977,7 @@ List<bool> _buildPlacedElementCellCollisionCache(
   final size = map.size.width * map.size.height;
   final cache = List<bool>.filled(size, false);
   if (size <= 0 || project == null) {
-    return cache;
+    return List<bool>.unmodifiable(cache);
   }
   final elementById = <String, ProjectElementEntry>{
     for (final entry in project.elements) entry.id: entry,
@@ -1216,7 +1007,7 @@ List<bool> _buildPlacedElementCellCollisionCache(
       cache[y * map.size.width + x] = true;
     }
   }
-  return cache;
+  return List<bool>.unmodifiable(cache);
 }
 
 List<bool> _buildWaterCellCache(
@@ -1733,3 +1524,16 @@ class PathAnimationRuleActivation {
   final String ruleId;
   final PathAnimationTriggerRule rule;
 }
+
+/// Internal diagnostics imported explicitly by scaling tests and benchmarks.
+///
+/// The public map_gameplay.dart barrel exports only [GameplayWorldState] and
+/// its predicates from this library, so these probes do not become gameplay
+/// API for runtime consumers.
+extension GameplayWorldStateCollisionStorageDiagnostics on GameplayWorldState {
+  Object get debugStaticCollisionStorageToken => _staticCollisionStorage;
+  int get debugAllocatedPixelMaskChunkCount =>
+      _staticCollisionStorage.allocatedPixelMaskChunkCount;
+  int get debugAllocatedPixelMaskWordCount =>
+      _staticCollisionStorage.allocatedPixelMaskWordCount;
+}
diff --git a/packages/map_gameplay/test/gameplay_world_state_entity_move_test.dart b/packages/map_gameplay/test/gameplay_world_state_entity_move_test.dart
index 383dbe551..ad4632e42 100644
--- a/packages/map_gameplay/test/gameplay_world_state_entity_move_test.dart
+++ b/packages/map_gameplay/test/gameplay_world_state_entity_move_test.dart
@@ -1,5 +1,7 @@
 import 'package:map_core/map_core.dart';
 import 'package:map_gameplay/map_gameplay.dart';
+import 'package:map_gameplay/src/gameplay_world_state.dart'
+    show GameplayWorldStateCollisionStorageDiagnostics;
 import 'package:test/test.dart';
 
 void main() {
@@ -23,8 +25,11 @@ void main() {
       map: map,
       playerPos: const GridPos(x: 0, y: 0),
     );
-    expect(initial.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1), isTrue);
-    expect(initial.isCellCenterBlockedLegacyForGridIndexedSystems(3, 1), isFalse);
+    expect(
+        initial.isCellCenterBlockedLegacyForGridIndexedSystems(1, 1), isTrue);
+    expect(
+        initial.isCellCenterBlockedLegacyForGridIndexedSystems(3, 1), isFalse);
+    final staticStorage = initial.debugStaticCollisionStorageToken;
 
     final moved =
         initial.withEntityPosition('npc_1', const GridPos(x: 3, y: 1));
@@ -32,5 +37,9 @@ void main() {
     expect(moved.isCellCenterBlockedLegacyForGridIndexedSystems(3, 1), isTrue);
     expect(moved.entityAt(3, 1)?.id, 'npc_1');
     expect(moved.entityAt(1, 1), isNull);
+    expect(
+      identical(moved.debugStaticCollisionStorageToken, staticStorage),
+      isTrue,
+    );
   });
 }
~~~~

## Annexe B — Contenu complet des fichiers créés

Les Evidence Packs ne s’auto-dupliquent pas. Tous les autres fichiers créés par ce lot sont
reproduits intégralement.

### `packages/map_gameplay/benchmark/world_collision_scaling.dart`

~~~~dart

~~~~

### `packages/map_gameplay/lib/src/collision/world_collision_storage.dart`

~~~~dart
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

/// Immutable static collision storage for one gameplay map.
///
/// Authoring tile/cell collisions remain O(map cells). Pixel precision is
/// allocated only for chunks touched by an explicit element collision mask;
/// there is deliberately no `worldWidthPx * worldHeightPx` bitmap.
final class WorldCollisionStorage {
  WorldCollisionStorage._({
    required this.widthCells,
    required this.heightCells,
    required this.tileWidthPx,
    required this.tileHeightPx,
    required List<bool> tileCollisionCells,
    required List<bool> placedElementCollisionCells,
    required Map<(int, int), Uint32List> pixelMaskWordsByChunk,
  })  : _tileCollisionCells = tileCollisionCells,
        _placedElementCollisionCells = placedElementCollisionCells,
        _pixelMaskWordsByChunk = pixelMaskWordsByChunk;

  final int widthCells;
  final int heightCells;
  final int tileWidthPx;
  final int tileHeightPx;
  final List<bool> _tileCollisionCells;
  final List<bool> _placedElementCollisionCells;
  final Map<(int, int), Uint32List> _pixelMaskWordsByChunk;

  int get widthPx => widthCells * tileWidthPx;
  int get heightPx => heightCells * tileHeightPx;
  int get allocatedPixelMaskChunkCount => _pixelMaskWordsByChunk.length;
  int get allocatedPixelMaskWordCount =>
      _pixelMaskWordsByChunk.length * WorldCollisionStorageBuilder.chunkSize;

  bool collidesPixelRect(
    PixelRect rect, {
    required bool Function(int cellIndex) isDynamicCellBlocked,
  }) {
    for (var localY = 0; localY < rect.heightPx; localY += 1) {
      final y = rect.topPx + localY;
      for (var localX = 0; localX < rect.widthPx; localX += 1) {
        final x = rect.leftPx + localX;
        if (_isPixelBlocked(
          x,
          y,
          isDynamicCellBlocked: isDynamicCellBlocked,
        )) {
          return true;
        }
      }
    }
    return false;
  }

  bool isCellCenterBlocked(
    int cellX,
    int cellY, {
    required bool Function(int cellIndex) isDynamicCellBlocked,
  }) {
    if (cellX < 0 || cellY < 0 || cellX >= widthCells || cellY >= heightCells) {
      return true;
    }
    return _isPixelBlocked(
      cellX * tileWidthPx + tileWidthPx ~/ 2,
      cellY * tileHeightPx + tileHeightPx ~/ 2,
      isDynamicCellBlocked: isDynamicCellBlocked,
    );
  }

  bool _isPixelBlocked(
    int x,
    int y, {
    required bool Function(int cellIndex) isDynamicCellBlocked,
  }) {
    if (x < 0 || y < 0 || x >= widthPx || y >= heightPx) {
      return true;
    }
    final cellX = x ~/ tileWidthPx;
    final cellY = y ~/ tileHeightPx;
    final cellIndex = cellY * widthCells + cellX;
    if (_valueAt(_tileCollisionCells, cellIndex) ||
        _valueAt(_placedElementCollisionCells, cellIndex) ||
        isDynamicCellBlocked(cellIndex)) {
      return true;
    }

    final chunk = _pixelMaskWordsByChunk[(
      x ~/ WorldCollisionStorageBuilder.chunkSize,
      y ~/ WorldCollisionStorageBuilder.chunkSize
    )];
    if (chunk == null) {
      return false;
    }
    final localX = x % WorldCollisionStorageBuilder.chunkSize;
    final localY = y % WorldCollisionStorageBuilder.chunkSize;
    return (chunk[localY] & (1 << localX)) != 0;
  }
}

/// Mutable construction seam; discarded immediately after map loading.
final class WorldCollisionStorageBuilder {
  WorldCollisionStorageBuilder({
    required this.widthCells,
    required this.heightCells,
    required int tileWidthPx,
    required int tileHeightPx,
    required this.tileCollisionCells,
    required this.placedElementCollisionCells,
  })  : tileWidthPx = tileWidthPx <= 0 ? 16 : tileWidthPx,
        tileHeightPx = tileHeightPx <= 0 ? 16 : tileHeightPx;

  static const int chunkSize = 32;

  final int widthCells;
  final int heightCells;
  final int tileWidthPx;
  final int tileHeightPx;
  final List<bool> tileCollisionCells;
  final List<bool> placedElementCollisionCells;
  final Map<(int, int), Uint32List> _pixelMaskWordsByChunk =
      <(int, int), Uint32List>{};

  int get widthPx => widthCells * tileWidthPx;
  int get heightPx => heightCells * tileHeightPx;

  /// Stamps one transformed packed mask. Invalid masks remain a no-op, matching
  /// the historical runtime's fail-open behavior for malformed project data.
  bool stampPackedMask({
    required int leftPx,
    required int topPx,
    required ElementCollisionPixelMask mask,
    required QuarterTurnPixelTransform transform,
  }) {
    List<bool> decoded;
    try {
      decoded = ElementCollisionMaskCodec.decodePackedBits(
        widthPx: mask.widthPx,
        heightPx: mask.heightPx,
        dataBase64: mask.dataBase64,
      );
    } catch (_) {
      return false;
    }

    final destinationSize = transform.destinationPixelSize;
    final destinationLeft = BigInt.from(leftPx);
    final destinationTop = BigInt.from(topPx);
    final destinationRight =
        destinationLeft + BigInt.from(destinationSize.width);
    final destinationBottom =
        destinationTop + BigInt.from(destinationSize.height);
    final worldWidth = BigInt.from(widthPx);
    final worldHeight = BigInt.from(heightPx);
    if (destinationRight <= BigInt.zero ||
        destinationBottom <= BigInt.zero ||
        destinationLeft >= worldWidth ||
        destinationTop >= worldHeight) {
      return true;
    }

    final startX =
        (destinationLeft.isNegative ? -destinationLeft : BigInt.zero).toInt();
    final startY =
        (destinationTop.isNegative ? -destinationTop : BigInt.zero).toInt();
    final endX = (destinationRight > worldWidth
            ? worldWidth - destinationLeft
            : BigInt.from(destinationSize.width))
        .toInt();
    final endY = (destinationBottom > worldHeight
            ? worldHeight - destinationTop
            : BigInt.from(destinationSize.height))
        .toInt();

    for (var destinationY = startY; destinationY < endY; destinationY += 1) {
      for (var destinationX = startX; destinationX < endX; destinationX += 1) {
        final source = transform.destinationPixelToSourcePixel(
          GridPos(x: destinationX, y: destinationY),
        );
        final sourceIndex = source.y * mask.widthPx + source.x;
        if (sourceIndex < 0 ||
            sourceIndex >= decoded.length ||
            !decoded[sourceIndex]) {
          continue;
        }
        _setPixel(leftPx + destinationX, topPx + destinationY);
      }
    }
    return true;
  }

  WorldCollisionStorage build() {
    return WorldCollisionStorage._(
      widthCells: widthCells,
      heightCells: heightCells,
      tileWidthPx: tileWidthPx,
      tileHeightPx: tileHeightPx,
      tileCollisionCells: List<bool>.unmodifiable(tileCollisionCells),
      placedElementCollisionCells:
          List<bool>.unmodifiable(placedElementCollisionCells),
      // Copy the mutable construction chunks so a discarded builder can never
      // mutate storage already shared by later immutable world states.
      pixelMaskWordsByChunk: Map<(int, int), Uint32List>.unmodifiable(
        <(int, int), Uint32List>{
          for (final entry in _pixelMaskWordsByChunk.entries)
            entry.key: Uint32List.fromList(entry.value),
        },
      ),
    );
  }

  void _setPixel(int x, int y) {
    if (x < 0 || y < 0 || x >= widthPx || y >= heightPx) {
      return;
    }
    final key = (x ~/ chunkSize, y ~/ chunkSize);
    final words = _pixelMaskWordsByChunk.putIfAbsent(
      key,
      () => Uint32List(chunkSize),
    );
    words[y % chunkSize] |= 1 << (x % chunkSize);
  }
}

bool _valueAt(List<bool> values, int index) =>
    index >= 0 && index < values.length && values[index];
~~~~

### `packages/map_gameplay/test/benchmark/world_collision_scaling_cli_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('child mode emits a fingerprinted no-mask result', () async {
    final result = await _run(const <String>[
      '--child',
      'true',
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '8',
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload =
        jsonDecode('${result.stdout}'.trim()) as Map<String, Object?>;
    final measured =
        (payload['results']! as List<Object?>).single as Map<String, Object?>;
    expect(payload['schemaVersion'], 2);
    expect(measured['generatorVersion'], 1);
    expect(measured['datasetFingerprint'], isNotEmpty);
    expect(measured['allocatedPixelMaskChunks'], 0);
    expect(
      (measured['queries1000']! as Map<String, Object?>)['resultChecksum'],
      isNotEmpty,
    );
    final maskMeasured = (payload['maskResults']! as List<Object?>).single
        as Map<String, Object?>;
    expect(maskMeasured['allocatedPixelMaskChunks'], 4);
    expect(
      (maskMeasured['queries']! as Map<String, Object?>)['resultChecksum'],
      isNotEmpty,
    );
  });

  test('rejects a zero isolated run count and output escape', () async {
    final invalidRuns = await _run(const <String>[
      '--sizes',
      '8',
      '--isolated-size',
      '16',
      '--isolated-runs',
      '0',
      '--output',
      'build/test/world-collision.json',
    ]);
    final escaped = await _run(const <String>[
      '--sizes',
      '8',
      '--output',
      '../world-collision-escape.json',
    ]);

    expect(invalidRuns.exitCode, 64);
    expect('${invalidRuns.stderr}', contains('isolated-runs must be positive'));
    expect(escaped.exitCode, 64);
    expect(
      '${escaped.stderr}',
      contains('must stay inside packages/map_gameplay'),
    );
  });
}

Future<ProcessResult> _run(List<String> arguments) {
  return Process.run(
    Platform.resolvedExecutable,
    <String>['run', 'benchmark/world_collision_scaling.dart', ...arguments],
    workingDirectory: Directory.current.path,
  );
}
~~~~

### `packages/map_gameplay/test/gameplay_world_state_collision_storage_characterization_test.dart`

~~~~dart
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_gameplay/src/collision/world_collision_storage.dart';
import 'package:map_gameplay/src/gameplay_world_state.dart'
    show GameplayWorldStateCollisionStorageDiagnostics;
import 'package:test/test.dart';

void main() {
  group('GameplayWorldState collision storage', () {
    test('allocates no world-pixel chunks without an element mask', () {
      final collisions = List<bool>.filled(256 * 256, false);
      collisions[10 * 256 + 10] = true;
      final map = MapData(
        id: 'large-map',
        name: 'Large map',
        size: const GridSize(width: 256, height: 256),
        layers: <MapLayer>[
          CollisionLayer(
            id: 'collision',
            name: 'Collision',
            collisions: collisions,
          ),
        ],
        entities: const <MapEntity>[
          MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 2, y: 2),
            npc: MapEntityNpcData(),
            blocksMovement: true,
          ),
        ],
      );

      final world = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 0, y: 0),
      );

      expect(world.debugAllocatedPixelMaskChunkCount, 0);
      expect(world.debugAllocatedPixelMaskWordCount, 0);
      expect(
          world.isCellCenterBlockedLegacyForGridIndexedSystems(10, 10), isTrue);
      expect(
          world.isCellCenterBlockedLegacyForGridIndexedSystems(2, 2), isTrue);
    });

    test('shares static storage when a dynamic entity moves', () {
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'entity-map',
          name: 'Entity map',
          size: const GridSize(width: 256, height: 256),
          entities: const <MapEntity>[
            MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 2, y: 2),
              npc: MapEntityNpcData(),
              blocksMovement: true,
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
      );
      final staticStorage = world.debugStaticCollisionStorageToken;

      final withPlayer = world.withPlayer(
        world.player.copyWith(facing: Direction.east),
      );
      final withNpcVisibility =
          world.withNpcMapPresencePredicate((_, __) => true);
      final withWorldRules =
          world.withMapEntityPresencePredicate((_, __) => true);

      final moved = world.withEntityPosition(
        'npc',
        const GridPos(x: 200, y: 200),
      );

      expect(
        identical(moved.debugStaticCollisionStorageToken, staticStorage),
        isTrue,
      );
      expect(
        identical(withPlayer.debugStaticCollisionStorageToken, staticStorage),
        isTrue,
      );
      expect(
        identical(
          withNpcVisibility.debugStaticCollisionStorageToken,
          staticStorage,
        ),
        isTrue,
      );
      expect(
        identical(
            withWorldRules.debugStaticCollisionStorageToken, staticStorage),
        isTrue,
      );
      expect(
          moved.isCellCenterBlockedLegacyForGridIndexedSystems(2, 2), isFalse);
      expect(moved.isCellCenterBlockedLegacyForGridIndexedSystems(200, 200),
          isTrue);
    });

    test('allocates packed chunks only where a collision mask has solid bits',
        () {
      final pixels = List<bool>.filled(16 * 16, false)..[15 * 16] = true;
      final mask = ElementCollisionPixelMask(
        widthPx: 16,
        heightPx: 16,
        dataBase64: ElementCollisionMaskCodec.encodePackedBits(
          widthPx: 16,
          heightPx: 16,
          solidPixels: pixels,
        ),
      );
      final project = ProjectManifest(
        name: 'Mask project',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'tiles',
            name: 'Tiles',
            relativePath: 'tiles.png',
          ),
        ],
        elementCategories: const <ProjectElementCategory>[
          ProjectElementCategory(id: 'props', name: 'Props'),
        ],
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'masked',
            name: 'Masked',
            tilesetId: 'tiles',
            categoryId: 'props',
            frames: const <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
            collisionProfile: ElementCollisionProfile(
              collisionMask: mask,
            ),
          ),
        ],
        surfaceCatalog: ProjectSurfaceCatalog(),
      );
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'mask-map',
          name: 'Mask map',
          size: const GridSize(width: 64, height: 64),
          placedElements: const <MapPlacedElement>[
            MapPlacedElement(
              id: 'masked-1',
              elementId: 'masked',
              layerId: 'objects',
              pos: GridPos(x: 1, y: 1),
            ),
          ],
        ),
        playerPos: const GridPos(x: 0, y: 0),
        project: project,
      );

      expect(world.debugAllocatedPixelMaskChunkCount, 1);
      expect(world.debugAllocatedPixelMaskWordCount, 32);
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: 16,
            topPx: 31,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: 17,
            topPx: 31,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isFalse,
      );
    });

    test('keeps out-of-world pixels blocking', () {
      final world = GameplayWorldState.initial(
        map: MapData(
          id: 'bounds-map',
          name: 'Bounds map',
          size: const GridSize(width: 4, height: 4),
        ),
        playerPos: const GridPos(x: 0, y: 0),
      );

      expect(
        world.worldStaticObstaclesCollidePixelRect(
          const PixelRect(
            leftPx: -1,
            topPx: 0,
            widthPx: 1,
            heightPx: 1,
          ),
        ),
        isTrue,
      );
    });

    test('packs solid pixels across every 31/32 chunk boundary', () {
      final pixels = List<bool>.filled(64 * 64, false);
      for (final point in const <(int, int)>[
        (31, 31),
        (32, 31),
        (31, 32),
        (32, 32),
      ]) {
        pixels[point.$2 * 64 + point.$1] = true;
      }
      final storage = _buildMaskStorage(
        worldSize: const GridSize(width: 4, height: 4),
        maskSize: const GridSize(width: 64, height: 64),
        pixels: pixels,
      );

      expect(storage.allocatedPixelMaskChunkCount, 4);
      for (final point in const <(int, int)>[
        (31, 31),
        (32, 31),
        (31, 32),
        (32, 32),
      ]) {
        expect(_isBlocked(storage, point.$1, point.$2), isTrue);
      }
      expect(_isBlocked(storage, 30, 31), isFalse);
      expect(_isBlocked(storage, 33, 32), isFalse);
    });

    test('empty and fully clipped masks allocate no chunks', () {
      final empty = _buildMaskStorage(
        worldSize: const GridSize(width: 4, height: 4),
        maskSize: const GridSize(width: 64, height: 64),
        pixels: List<bool>.filled(64 * 64, false),
      );
      final clipped = _buildMaskStorage(
        worldSize: const GridSize(width: 4, height: 4),
        maskSize: const GridSize(width: 1, height: 1),
        pixels: const <bool>[true],
        leftPx: 80,
        topPx: 80,
      );

      expect(empty.allocatedPixelMaskChunkCount, 0);
      expect(clipped.allocatedPixelMaskChunkCount, 0);
      expect(
        empty.collidesPixelRect(
          const PixelRect(leftPx: 0, topPx: 0, widthPx: 0, heightPx: 0),
          isDynamicCellBlocked: (_) => false,
        ),
        isFalse,
      );
    });

    test('copies mutable cell inputs before sharing immutable storage', () {
      final tileCells = List<bool>.filled(4, false);
      final placedCells = List<bool>.filled(4, false);
      final builder = WorldCollisionStorageBuilder(
        widthCells: 2,
        heightCells: 2,
        tileWidthPx: 16,
        tileHeightPx: 16,
        tileCollisionCells: tileCells,
        placedElementCollisionCells: placedCells,
      );
      final storage = builder.build();

      tileCells[0] = true;
      placedCells[1] = true;

      expect(_isBlocked(storage, 8, 8), isFalse);
      expect(_isBlocked(storage, 24, 8), isFalse);
    });
  });
}

WorldCollisionStorage _buildMaskStorage({
  required GridSize worldSize,
  required GridSize maskSize,
  required List<bool> pixels,
  int leftPx = 0,
  int topPx = 0,
}) {
  final builder = WorldCollisionStorageBuilder(
    widthCells: worldSize.width,
    heightCells: worldSize.height,
    tileWidthPx: 16,
    tileHeightPx: 16,
    tileCollisionCells: List<bool>.filled(
      worldSize.width * worldSize.height,
      false,
    ),
    placedElementCollisionCells: List<bool>.filled(
      worldSize.width * worldSize.height,
      false,
    ),
  );
  final mask = ElementCollisionPixelMask(
    widthPx: maskSize.width,
    heightPx: maskSize.height,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: maskSize.width,
      heightPx: maskSize.height,
      solidPixels: pixels,
    ),
  );
  builder.stampPackedMask(
    leftPx: leftPx,
    topPx: topPx,
    mask: mask,
    transform: QuarterTurnPixelTransform(
      sourcePixelSize: maskSize,
      destinationPixelSize: maskSize,
      quarterTurns: 0,
    ),
  );
  return builder.build();
}

bool _isBlocked(WorldCollisionStorage storage, int x, int y) {
  return storage.collidesPixelRect(
    PixelRect(leftPx: x, topPx: y, widthPx: 1, heightPx: 1),
    isDynamicCellBlocked: (_) => false,
  );
}
~~~~

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-04-gameplay-collision.md`

~~~~markdown
# PERF-RM-04 — Plan d'implémentation collision gameplay en couches

**Scope :** séparer collision statique et occupancy dynamique ; représenter uniquement les pixels de masques par chunks bitset. Aucune règle métier, dépendance Flutter/Flame ou migration JSON.

## Audit initial

- `_buildPixelCollisionCache` alloue `mapWidth * tileWidth * mapHeight * tileHeight` booléens même sans masque.
- La bitmap fusionne collision statique et entités ; `withEntityPosition` et les changements de visibilité la reconstruisent entièrement.
- Les caches cellule tuiles/éléments et la map d'entités bloquantes existent déjà séparément.
- Les tests couvrent masque prioritaire, cellules legacy, rotations, visibilité PNJ, mouvement et reachability.

## Étapes test-first

- [ ] Créer `gameplay_world_state_collision_storage_characterization_test.dart` : grande map 256² sans masque, zéro chunk pixel, token statique partagé après move, collision cellule/dynamique identique, bounds.
- [ ] Étendre `gameplay_world_state_entity_move_test.dart` pour départ/arrivée et partage statique.
- [ ] Exécuter les tests et conserver RED sur les diagnostics/stockage absents.
- [ ] Créer `src/collision/world_collision_storage.dart` : cellules statiques immuables + chunks 32×32 packés alloués uniquement lors d'un bit masque solide.
- [ ] Construire le stockage une fois depuis layers/cellules/masques ; conserver les entités dans `_blockingEntityByPos` et les interroger dynamiquement lors des tests pixel.
- [ ] Faire partager le stockage dans `withPlayer`, visibilité, world rules et `withEntityPosition`; supprimer les rebuilds monde pixel.
- [ ] Préserver rotation/crop/hors-bounds des masques avec `QuarterTurnPixelTransform` et tests existants.
- [ ] Créer `benchmark/world_collision_scaling.dart` avec CLI validée, warmups/samples, tailles, move p50/p95/p99, compteurs chunks et JSON.
- [ ] Mesurer 32/64/128/256 et 512 isolé, puis relancer suite gameplay, runtime bridges, smokes et analyzers.

## Non-objectifs et risques

- Pas de changement de reachability : elle continue de consommer `GameplayWorldState`.
- Pas de compression des caches cellule dans ce lot ; ils sont O(nombre de cellules), pas O(nombre de pixels monde).
- Un masque dense peut allouer tous les chunks qu'il touche, mais jamais une bitmap monde en leur absence.

## Preuves attendues

- Aucun chunk pixel sans masque, stockage statique identique après déplacement.
- Move 256² p95 sous 5 ms AOT sur la machine de preuve ; RSS historique non requalifiée sans mesure fraîche comparable.
- Parité terrain, mask, legacy cells, entités, interaction, warp et reachability.
~~~~
