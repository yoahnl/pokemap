# Evidence Pack — PERF-RM-03 — Topologie Surface O(P)

Date : 2026-08-01  
Phase : 1 — Urgences P0  
Finding : `PERF-SURFACE-01`  
Verdict proposé : **PARTIAL — topologie AOT <5 ms et parité verte, gates d’intégration non mesurées**

## Résumé exécutif

`SurfacePlacementTopology` construit en un passage l’occupation par preset et résout les
voisins en O(1). Editor, runtime et authoring réutilisent cette topologie au lieu de
rescanner tous les placements par cellule. Des indexes de lignes rendent uniquement
viewport + halo et sont attachés à l’identité exacte de la couche, ce qui empêche un cache
stale lorsqu’une nouvelle couche réutilise le même ID.

Le benchmark AOT à 2 500 placements donne un p95 de 0,707 à 1,008 ms selon la fixture, sous
le seuil de 5 ms. Les comparaisons de complexité à 400 placements passent d’environ
13,0–13,6 ms pour l’adapter legacy émulé à 0,103–0,147 ms pour la topologie. Les checksums
de rôles sont identiques entre modes. Les tests de parité, presets, trous, duplicats,
invalides, viewport et goldens sont verts.

Le statut reste `PARTIAL` : le painter de référence <8 ms et le ratio p95
1 024²/128² ≤1,5 à viewport constant n’ont pas été mesurés dans le harness RM00.

## Scope et non-objectifs

- Topologie pure dans `map_core`.
- Ownership/invalidation/viewport localisés dans editor et runtime.
- Aucune sémantique Surface, JSON ou API authoring modifiée.
- Pas de cache global mutable.
- Préservation de l’ordre authoring visible et de l’identité exacte des couches.

## Audit initial

Le resolver recherchait les voisins avec des scans répétés de placements, donnant une
complexité proche de O(P²) et près de 0,8 s à 2 500 placements selon l’audit. Les principaux
risques étaient les divergences editor/runtime, les coutures de viewport, les presets
croisés, l’ordre d’auteur et un index stale après remplacement/undo.

## État Git initial

HEAD : `7f35d44d9f777d25046c6b94d8974a2fdd850a78`

```text
?? reports/performance/pokemap_full_performance_audit.md
?? reports/performance/pokemap_performance_remediation_roadmap.md
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

## Inventaire et zones modifiées

- `packages/map_core/lib/src/operations/surface_variant_role_resolver.dart`
  - `SurfacePlacementTopology`, index preset/coordonnée et adapter legacy compatible.
- `packages/map_core/test/surface_variant_role_resolver_test.dart`
  - fixtures centre/bords/coins, trous, presets, duplicats, invalides et iterable lazy.
- `packages/map_authoring/lib/src/domains/maps/autotile_actions.dart`
  - construction d’une topologie unique pour l’action.
- `packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart`
  - `SurfacePreviewLayerIndex`, row index, viewport clamp, ordre authoring ;
  - `SurfacePreviewLayerIndexOwner`, réutilisation par identité et invalidation same-ID.
- `packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart`
  - rôle/topologie précomputé après validations catalog/preset.
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
  - ownership persistant des indexes Surface sur la durée de vie du canvas.
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
  - consommation de l’owner persistant et viewport + halo, sans reconstruction sur hover.
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart`
  - topologie unique pour le rendu cinématique.
- tests editor Surface : index stale même ID, viewport immense, ordre authoring, voisins halo.
- `packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart`
  - `SurfaceRuntimeLayerIndex`, row index, full topology et clamp.
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
  - indexes runtime par identité et marge historique de trois cellules.
- `packages/map_runtime/test/surface/surface_runtime_resolver_test.dart`
  - stale même ID, clamp et voisins de viewport.
- `packages/map_core/benchmark/surface_role_scaling.dart` (créé)
  - benchmark schema v2, JIT/AOT, fixtures et distributions p50/p95/p99.
- `packages/map_core/test/benchmark/surface_role_scaling_cli_test.dart` (créé)
  - validation CLI, output confiné, symlink et métadonnées.
- `reports/performance/plans/2026-08-01-pokemap-perf-rm-03-surface-topology.md`
  (créé) : plan TDD du lot.

## Résultats AOT

Commande de construction et d’exécution :

```bash
cd packages/map_core
dart compile exe benchmark/surface_role_scaling.dart -o build/performance/surface_role_scaling
build/performance/surface_role_scaling --warmups 5 --samples 30 --sizes 100,400,1024,2500 --fixtures dense,hole,line,sparse,mixed --modes topology --output build/performance/surface_role_scaling.json
build/performance/surface_role_scaling --warmups 5 --samples 10 --sizes 100,400 --fixtures dense,hole,mixed --modes legacy,topology --output build/performance/surface_role_comparison.json
```

Résultats p95 AOT, 2 500 placements :

| Fixture | p50 | p95 | p99 |
|---|---:|---:|---:|
| dense | 838 µs | 1 008 µs | 1 055 µs |
| hole | 854 µs | 986 µs | 1 014 µs |
| line | 577 µs | 992 µs | 1 173 µs |
| sparse | 573 µs | 707 µs | 729 µs |
| mixed | 580 µs | 719 µs | 736 µs |

Comparaison 400 placements p95 :

| Fixture | adapter legacy émulé | topologie |
|---|---:|---:|
| dense | 13 554 µs | 147 µs |
| hole | 13 067 µs | 141 µs |
| mixed | 13 034 µs | 103 µs |

La colonne legacy force l’adapter courant pour chaque placement sur la même fixture ; elle
reproduit la classe de complexité antérieure, mais n’est pas un binaire historique RM00.
Les checksums FNV sont stables et identiques entre legacy/topologie pour chaque fixture.

## Preuves TDD et validation

Les RED ont caractérisé le nombre d’énumérations, les presets, la déduplication,
l’identité de couche et le viewport. Les GREEN ciblés comprennent :

```text
map_core : resolver + CLI benchmark, +15.
map_authoring : actions Surface, +4.
map_editor : Surface ciblé post-owner, +45 ; cinématique, +1.
map_runtime : Surface/goldens inclus dans la matrice ciblée runtime.
Analyses statiques des packages : No issues found.
```

La validation indépendante a confirmé 15 tests core, 4 authoring, 43 tests editor Surface
initiaux plus un test cinématique, ainsi que les tests runtime Surface inclus dans sa
matrice. Après ajout de l’owner persistant, la passe racine produit 45 succès editor ciblés ;
la contre-validation post-fix produit 37 succès incluant owner, painter et smoke MapCanvas.
Les analyzers core, authoring, editor et runtime sont sans diagnostic. Les deux builds
macOS debug sont verts.

La suite globale editor, lancée à forte concurrence, termine en échec à
`+5198 ~6 -35` après 6 min 16 s. Les échecs listés concernent notamment les transactions
Border et un receipt narratif Selbrume stale, sans modification de ces fichiers par RM03.
Une relance de trois fichiers concernés confirme `+7 -7`, et le test narratif isolé
confirme `+0 -1` (`freshPass` attendu, `stale` reçu). Ce signal est consigné comme dette de
suite existante ; les 45 tests directement affectés et l’analyse restent verts.

La critique finale confirme l’owner persistant, la réutilisation par identité exacte et
l’invalidation same-ID/new identity. Le MCP final passe 23/23 tests séquentiels ; parité
authoring `N/A` car aucune sémantique ni contrat n’a changé.

Parité MCP : `N/A — sémantique et contrat inchangés`. Le catalogue live
`pokemap_describe` répond `ok: true` sans nouvelle ressource/action.

## Verdict des passes

- Audit / Architecture : **GO**, sous réserve d’ownership local et de tests stale/viewport.
- Implémentation : **GREEN**, topologie partagée et indexes locaux.
- Tests : **PASS ciblé / suite editor globale non verte hors zones modifiées**.
- Build / Validation : **PASS** — analyzers et builds verts ; gates RM00 manquantes.
- Critique finale : **PASS fonctionnel / PARTIAL roadmap**.

## Limites, auto-critique et risques

- Pas de mesure painter Surface de référence ni ratio de tailles à viewport constant.
- Le benchmark legacy est une émulation de complexité, pas une mesure pre-patch RM00.
- Toute future mutation in-place de layer devra conserver l’immuabilité actuelle ou
  expliciter une révision. L’owner persistant invalide déjà une nouvelle identité portant
  le même ID et retire les couches disparues.

Auto-critique : le seuil principal topologique et la pente sont convaincants, mais les deux
gates d’intégration manquent. Prochaine étape : brancher le benchmark sur le harness RM00,
mesurer painter/runtime à viewport constant, puis seulement proposer `DONE`.

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
diff --git a/packages/map_authoring/lib/src/domains/maps/autotile_actions.dart b/packages/map_authoring/lib/src/domains/maps/autotile_actions.dart
index bb6972231..be8957cbb 100644
--- a/packages/map_authoring/lib/src/domains/maps/autotile_actions.dart
+++ b/packages/map_authoring/lib/src/domains/maps/autotile_actions.dart
@@ -358,6 +358,7 @@ final class SemanticAutotileResolver {
         }
       case SurfaceLayer surface:
         layerKind = 'surface';
+        final topology = SurfacePlacementTopology(surface.placements);
         final placements = surface.placements.toList()
           ..sort((left, right) {
             final y = left.y.compareTo(right.y);
@@ -379,8 +380,7 @@ final class SemanticAutotileResolver {
             );
             continue;
           }
-          final role = resolveSurfaceVariantRoleForPlacement(
-            placements: surface.placements,
+          final role = topology.roleAt(
             x: placement.x,
             y: placement.y,
             surfacePresetId: placement.surfacePresetId,
diff --git a/packages/map_core/lib/src/operations/surface_variant_role_resolver.dart b/packages/map_core/lib/src/operations/surface_variant_role_resolver.dart
index 51671f4ee..a2c882d93 100644
--- a/packages/map_core/lib/src/operations/surface_variant_role_resolver.dart
+++ b/packages/map_core/lib/src/operations/surface_variant_role_resolver.dart
@@ -2,6 +2,65 @@ import '../exceptions/map_exceptions.dart';
 import '../models/map_layer.dart';
 import '../models/surface.dart';
 
+/// Immutable occupancy index for one Surface placement collection.
+///
+/// Building the index is O(P). Every subsequent role lookup probes at most the
+/// eight neighboring coordinates, so editor/runtime callers can resolve a
+/// whole layer without repeatedly enumerating the same placements.
+///
+/// The index deliberately owns no application cache or revision policy. Those
+/// concerns stay in the editor/runtime packages that know when a layer changes.
+final class SurfacePlacementTopology {
+  SurfacePlacementTopology(Iterable<SurfaceCellPlacement> placements) {
+    final mutableCoordinatesByPresetId = <String, Set<(int, int)>>{};
+    for (final placement in placements) {
+      final presetId = placement.surfacePresetId.trim();
+      if (presetId.isEmpty) {
+        // An empty preset never matched the validated query adapter before the
+        // optimization, so retaining it would only create unreachable state.
+        continue;
+      }
+      mutableCoordinatesByPresetId
+          .putIfAbsent(presetId, () => <(int, int)>{})
+          .add((placement.x, placement.y));
+    }
+
+    _coordinatesByPresetId = Map<String, Set<(int, int)>>.unmodifiable(
+      <String, Set<(int, int)>>{
+        for (final entry in mutableCoordinatesByPresetId.entries)
+          entry.key: Set<(int, int)>.unmodifiable(entry.value),
+      },
+    );
+    occupiedCoordinateCount = _coordinatesByPresetId.values.fold<int>(
+      0,
+      (total, coordinates) => total + coordinates.length,
+    );
+  }
+
+  late final Map<String, Set<(int, int)>> _coordinatesByPresetId;
+
+  /// Number of unique `(preset, x, y)` occupancy entries held by the index.
+  late final int occupiedCoordinateCount;
+
+  /// Resolves a role from the already-indexed occupancy domain.
+  SurfaceVariantRole roleAt({
+    required int x,
+    required int y,
+    required String surfacePresetId,
+  }) {
+    _requireNonNegativeCoordinate(x: x, y: y);
+    final normalizedPresetId = _requireSurfacePresetId(surfacePresetId);
+    final matchingCoordinates =
+        _coordinatesByPresetId[normalizedPresetId] ?? const <(int, int)>{};
+
+    return resolveSurfaceVariantRoleAt(
+      x: x,
+      y: y,
+      matchesAt: (nextX, nextY) => matchingCoordinates.contains((nextX, nextY)),
+    );
+  }
+}
+
 /// Resolves the V0 visual role for a sparse Surface placement.
 ///
 /// The resolver is deliberately pure and read-only: it computes a derived
@@ -17,20 +76,10 @@ SurfaceVariantRole resolveSurfaceVariantRoleForPlacement({
 }) {
   _requireNonNegativeCoordinate(x: x, y: y);
   final normalizedPresetId = _requireSurfacePresetId(surfacePresetId);
-  final matchingCoordinates = <String>{
-    for (final placement in placements)
-      if (placement.surfacePresetId.trim() == normalizedPresetId)
-        _coordinateKey(placement.x, placement.y),
-  };
-
-  bool matchesAt(int nextX, int nextY) {
-    return matchingCoordinates.contains(_coordinateKey(nextX, nextY));
-  }
-
-  return resolveSurfaceVariantRoleAt(
+  return SurfacePlacementTopology(placements).roleAt(
     x: x,
     y: y,
-    matchesAt: matchesAt,
+    surfacePresetId: normalizedPresetId,
   );
 }
 
@@ -134,5 +183,3 @@ String _requireSurfacePresetId(String surfacePresetId) {
   }
   return normalized;
 }
-
-String _coordinateKey(int x, int y) => '$x:$y';
diff --git a/packages/map_core/test/surface_variant_role_resolver_test.dart b/packages/map_core/test/surface_variant_role_resolver_test.dart
index 09204b943..090e8d696 100644
--- a/packages/map_core/test/surface_variant_role_resolver_test.dart
+++ b/packages/map_core/test/surface_variant_role_resolver_test.dart
@@ -181,4 +181,108 @@ void main() {
       expect(fromReversed, fromOrdered);
     });
   });
+
+  group('SurfacePlacementTopology', () {
+    test('legacy adapter validates a query before enumerating placements', () {
+      var enumerated = false;
+
+      Iterable<SurfaceCellPlacement> placements() sync* {
+        enumerated = true;
+        throw StateError('must not enumerate invalid queries');
+      }
+
+      expect(
+        () => resolveSurfaceVariantRoleForPlacement(
+          placements: placements(),
+          x: -1,
+          y: 0,
+          surfacePresetId: 'water',
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(enumerated, isFalse);
+    });
+
+    test('indexes its source once and reuses occupancy for every role lookup',
+        () {
+      var visitedPlacements = 0;
+      final placements = <SurfaceCellPlacement>[
+        for (var y = 0; y < 50; y++)
+          for (var x = 0; x < 50; x++)
+            SurfaceCellPlacement(
+              x: x,
+              y: y,
+              surfacePresetId: 'water',
+            ),
+      ];
+
+      Iterable<SurfaceCellPlacement> countedPlacements() sync* {
+        for (final placement in placements) {
+          visitedPlacements += 1;
+          yield placement;
+        }
+      }
+
+      final topology = SurfacePlacementTopology(countedPlacements());
+      expect(visitedPlacements, placements.length);
+
+      for (final placement in placements) {
+        expect(
+          topology.roleAt(
+            x: placement.x,
+            y: placement.y,
+            surfacePresetId: placement.surfacePresetId,
+          ),
+          isA<SurfaceVariantRole>(),
+        );
+      }
+
+      expect(
+        visitedPlacements,
+        placements.length,
+        reason: 'Role lookup must not enumerate the source placements again.',
+      );
+      expect(topology.occupiedCoordinateCount, placements.length);
+    });
+
+    test('keeps presets isolated and normalizes ids without changing roles',
+        () {
+      final topology = SurfacePlacementTopology(
+        const <SurfaceCellPlacement>[
+          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: ' water '),
+          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'lava'),
+        ],
+      );
+
+      expect(
+        topology.roleAt(x: 1, y: 1, surfacePresetId: ' water '),
+        SurfaceVariantRole.horizontal,
+      );
+      expect(
+        topology.roleAt(x: 1, y: 0, surfacePresetId: 'lava'),
+        SurfaceVariantRole.isolated,
+      );
+    });
+
+    test('deduplicates occupancy and retains validation guards', () {
+      final topology = SurfacePlacementTopology(
+        const <SurfaceCellPlacement>[
+          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
+        ],
+      );
+
+      expect(topology.occupiedCoordinateCount, 1);
+      expect(
+        () => topology.roleAt(x: -1, y: 0, surfacePresetId: 'water'),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => topology.roleAt(x: 0, y: 0, surfacePresetId: '   '),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+  });
 }
diff --git a/packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart b/packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
index 7152460f0..49cbfec4b 100644
--- a/packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
+++ b/packages/map_editor/lib/src/features/surface_painter/surface_layer_static_preview.dart
@@ -1,3 +1,4 @@
+import 'dart:collection';
 import 'dart:ui'
     show Canvas, Color, FilterQuality, Image, Paint, PaintingStyle, Rect;
 
@@ -6,6 +7,138 @@ import 'package:map_core/map_core.dart';
 
 import 'surface_tile_preview_resolver.dart';
 
+/// Half-open cell bounds for the editor Surface preview.
+///
+/// The full topology is still used for role resolution; these bounds only
+/// limit cells that reach the painter, avoiding seams at viewport edges.
+final class SurfacePreviewCellViewport {
+  const SurfacePreviewCellViewport({
+    required this.left,
+    required this.top,
+    required this.right,
+    required this.bottom,
+  });
+
+  final int left;
+  final int top;
+  final int right;
+  final int bottom;
+
+  bool contains(SurfaceCellPlacement placement) =>
+      placement.x >= left &&
+      placement.x < right &&
+      placement.y >= top &&
+      placement.y < bottom;
+}
+
+/// Editor-owned row index for one immutable Surface layer.
+///
+/// The complete topology is retained for neighbour roles, while viewport
+/// queries enumerate only indexed rows and then restore authoring order for
+/// visually overlapping duplicate placements.
+final class SurfacePreviewLayerIndex {
+  SurfacePreviewLayerIndex._({
+    required SurfaceLayer sourceLayer,
+    required List<SurfaceCellPlacement> placements,
+  })  : _sourceLayer = sourceLayer,
+        _placements = placements,
+        topology = SurfacePlacementTopology(placements),
+        _placementsByRow = _indexPreviewPlacementsByRow(placements) {
+    if (placements.isEmpty) {
+      _firstIndexedRow = null;
+      _lastIndexedRow = null;
+    } else {
+      var first = placements.first.y;
+      var last = first;
+      for (final placement in placements.skip(1)) {
+        if (placement.y < first) first = placement.y;
+        if (placement.y > last) last = placement.y;
+      }
+      _firstIndexedRow = first;
+      _lastIndexedRow = last;
+    }
+  }
+
+  factory SurfacePreviewLayerIndex.fromLayer(SurfaceLayer layer) {
+    return SurfacePreviewLayerIndex._(
+      sourceLayer: layer,
+      placements: List<SurfaceCellPlacement>.unmodifiable(layer.placements),
+    );
+  }
+
+  final SurfaceLayer _sourceLayer;
+  final List<SurfaceCellPlacement> _placements;
+  final Map<int, List<_IndexedSurfacePreviewPlacement>> _placementsByRow;
+  final SurfacePlacementTopology topology;
+  late final int? _firstIndexedRow;
+  late final int? _lastIndexedRow;
+
+  bool belongsTo(SurfaceLayer layer) => identical(_sourceLayer, layer);
+
+  Iterable<SurfaceCellPlacement> placementsIn(
+    SurfacePreviewCellViewport? viewport,
+  ) sync* {
+    if (viewport == null) {
+      yield* _placements;
+      return;
+    }
+    if (_placements.isEmpty ||
+        viewport.right <= viewport.left ||
+        viewport.bottom <= viewport.top) {
+      return;
+    }
+    final firstIndexedRow = _firstIndexedRow!;
+    final lastIndexedRow = _lastIndexedRow!;
+    final startRow =
+        viewport.top > firstIndexedRow ? viewport.top : firstIndexedRow;
+    final endRowExclusive = viewport.bottom < lastIndexedRow + 1
+        ? viewport.bottom
+        : lastIndexedRow + 1;
+    final visible = <_IndexedSurfacePreviewPlacement>[];
+    for (var y = startRow; y < endRowExclusive; y += 1) {
+      final row = _placementsByRow[y];
+      if (row == null) continue;
+      for (final indexed in row) {
+        final x = indexed.placement.x;
+        if (x >= viewport.left && x < viewport.right) {
+          visible.add(indexed);
+        }
+      }
+    }
+    visible.sort((a, b) => a.authoringIndex.compareTo(b.authoringIndex));
+    for (final indexed in visible) {
+      yield indexed.placement;
+    }
+  }
+}
+
+/// Owns Surface preview indexes across editor rebuilds.
+///
+/// Surface layers are immutable value objects in the editor state. Reusing the
+/// exact layer instance therefore means its placements are unchanged; replacing
+/// it (including with the same authoring id) rebuilds only that layer's index.
+/// Stale layers are dropped on every synchronization.
+final class SurfacePreviewLayerIndexOwner {
+  Map<SurfaceLayer, SurfacePreviewLayerIndex> _indexes =
+      Map<SurfaceLayer, SurfacePreviewLayerIndex>.identity();
+
+  Map<SurfaceLayer, SurfacePreviewLayerIndex> indexesFor(
+    Iterable<MapLayer> layers,
+  ) {
+    final next = Map<SurfaceLayer, SurfacePreviewLayerIndex>.identity();
+    for (final layer in layers.whereType<SurfaceLayer>()) {
+      next[layer] =
+          _indexes[layer] ?? SurfacePreviewLayerIndex.fromLayer(layer);
+    }
+    _indexes = next;
+    return UnmodifiableMapView<SurfaceLayer, SurfacePreviewLayerIndex>(next);
+  }
+
+  void clear() {
+    _indexes = Map<SurfaceLayer, SurfacePreviewLayerIndex>.identity();
+  }
+}
+
 /// One editor-only preview cell for a sparse Surface placement.
 ///
 /// The preview carries the resolved role so the editor can already show that
@@ -30,6 +163,9 @@ final class SurfaceLayerStaticPreviewCell {
 List<SurfaceLayerStaticPreviewCell> buildSurfaceLayerStaticPreviewCells({
   required SurfaceLayer layer,
   required GridSize mapSize,
+  SurfacePlacementTopology? topology,
+  SurfacePreviewLayerIndex? layerIndex,
+  SurfacePreviewCellViewport? viewport,
 }) {
   if (!layer.isVisible ||
       layer.opacity <= 0 ||
@@ -39,19 +175,38 @@ List<SurfaceLayerStaticPreviewCell> buildSurfaceLayerStaticPreviewCells({
     return const <SurfaceLayerStaticPreviewCell>[];
   }
 
+  if (layerIndex != null && !layerIndex.belongsTo(layer)) {
+    throw ArgumentError.value(
+      layer.id,
+      'layerIndex',
+      'must belong to the provided SurfaceLayer instance',
+    );
+  }
+  if (topology != null && layerIndex != null) {
+    throw ArgumentError('Provide topology or layerIndex, not both.');
+  }
+
+  final resolvedTopology = topology ??
+      layerIndex?.topology ??
+      SurfacePlacementTopology(layer.placements);
   final cells = <SurfaceLayerStaticPreviewCell>[];
-  for (final placement in layer.placements) {
+  final placements = layerIndex?.placementsIn(viewport) ?? layer.placements;
+  for (final placement in placements) {
     if (placement.x < 0 ||
         placement.y < 0 ||
         placement.x >= mapSize.width ||
         placement.y >= mapSize.height) {
       continue;
     }
+    if (layerIndex == null &&
+        viewport != null &&
+        !viewport.contains(placement)) {
+      continue;
+    }
     cells.add(
       SurfaceLayerStaticPreviewCell(
         placement: placement,
-        role: resolveSurfaceVariantRoleForPlacement(
-          placements: layer.placements,
+        role: resolvedTopology.roleAt(
           x: placement.x,
           y: placement.y,
           surfacePresetId: placement.surfacePresetId,
@@ -88,6 +243,9 @@ void paintSurfaceLayerStaticPreview({
   required double tileWidth,
   required double tileHeight,
   required double zoom,
+  SurfacePlacementTopology? topology,
+  SurfacePreviewLayerIndex? layerIndex,
+  SurfacePreviewCellViewport? viewport,
 }) {
   if (tileWidth <= 0 || tileHeight <= 0 || zoom <= 0) {
     return;
@@ -96,6 +254,9 @@ void paintSurfaceLayerStaticPreview({
   final cells = buildSurfaceLayerStaticPreviewCells(
     layer: layer,
     mapSize: mapSize,
+    topology: topology,
+    layerIndex: layerIndex,
+    viewport: viewport,
   );
   if (cells.isEmpty) {
     return;
@@ -133,6 +294,9 @@ void paintSurfaceLayerAtlasTilePreview({
   required double tileHeight,
   required double zoom,
   int elapsedMs = 0,
+  SurfacePlacementTopology? topology,
+  SurfacePreviewLayerIndex? layerIndex,
+  SurfacePreviewCellViewport? viewport,
 }) {
   if (tileWidth <= 0 || tileHeight <= 0 || zoom <= 0) {
     return;
@@ -141,6 +305,9 @@ void paintSurfaceLayerAtlasTilePreview({
   final cells = buildSurfaceLayerStaticPreviewCells(
     layer: layer,
     mapSize: mapSize,
+    topology: topology,
+    layerIndex: layerIndex,
+    viewport: viewport,
   );
   if (cells.isEmpty) {
     return;
@@ -168,6 +335,7 @@ void paintSurfaceLayerAtlasTilePreview({
         catalog: catalog,
         availableTilesetIds: availableTilesetIds,
         elapsedMs: elapsedMs,
+        precomputedRole: cell.role,
       );
     }
     final image =
@@ -198,6 +366,39 @@ void paintSurfaceLayerAtlasTilePreview({
   }
 }
 
+Map<int, List<_IndexedSurfacePreviewPlacement>> _indexPreviewPlacementsByRow(
+    List<SurfaceCellPlacement> placements) {
+  final rows = <int, List<_IndexedSurfacePreviewPlacement>>{};
+  for (var index = 0; index < placements.length; index += 1) {
+    final placement = placements[index];
+    rows
+        .putIfAbsent(placement.y, () => <_IndexedSurfacePreviewPlacement>[])
+        .add(
+          _IndexedSurfacePreviewPlacement(
+            authoringIndex: index,
+            placement: placement,
+          ),
+        );
+  }
+  return Map<int, List<_IndexedSurfacePreviewPlacement>>.unmodifiable(
+    <int, List<_IndexedSurfacePreviewPlacement>>{
+      for (final entry in rows.entries)
+        entry.key:
+            List<_IndexedSurfacePreviewPlacement>.unmodifiable(entry.value),
+    },
+  );
+}
+
+final class _IndexedSurfacePreviewPlacement {
+  const _IndexedSurfacePreviewPlacement({
+    required this.authoringIndex,
+    required this.placement,
+  });
+
+  final int authoringIndex;
+  final SurfaceCellPlacement placement;
+}
+
 Rect _surfaceCellRect(
   SurfaceLayerStaticPreviewCell cell, {
   required double tileWidth,
diff --git a/packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart b/packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
index 84b6fa6de..a40cbae3e 100644
--- a/packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
+++ b/packages/map_editor/lib/src/features/surface_painter/surface_tile_preview_resolver.dart
@@ -43,6 +43,8 @@ SurfaceTilePreviewInstruction? resolveSurfaceTilePreviewInstruction({
   required ProjectSurfaceCatalog catalog,
   required Set<String> availableTilesetIds,
   int elapsedMs = 0,
+  SurfaceVariantRole? precomputedRole,
+  SurfacePlacementTopology? topology,
 }) {
   if (!layer.isVisible || layer.opacity <= 0) {
     return null;
@@ -57,12 +59,17 @@ SurfaceTilePreviewInstruction? resolveSurfaceTilePreviewInstruction({
     return null;
   }
 
-  final role = resolveSurfaceVariantRoleForPlacement(
-    placements: layer.placements,
-    x: placement.x,
-    y: placement.y,
-    surfacePresetId: presetId,
-  );
+  final role = precomputedRole ??
+      topology?.roleAt(
+        x: placement.x,
+        y: placement.y,
+        surfacePresetId: presetId,
+      ) ??
+      resolveSurfaceVariantRoleForPlacement(
+          placements: layer.placements,
+          x: placement.x,
+          y: placement.y,
+          surfacePresetId: presetId);
   final animationId = _resolveAnimationId(preset, role);
   if (animationId == null) {
     return null;
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
index 391de0978..d9f7b894b 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
@@ -738,12 +738,14 @@ int _appendSurfaceInstructions({
     for (final entry in tilesets.entries)
       if (entry.value.isAvailable) entry.key,
   };
+  final topology = SurfacePlacementTopology(layer.placements);
   for (final placement in layer.placements) {
     final resolved = resolveSurfaceTilePreviewInstruction(
       layer: layer,
       placement: placement,
       catalog: manifest.surfaceCatalog,
       availableTilesetIds: availableTilesetIds,
+      topology: topology,
     );
     if (resolved == null) {
       _addDiagnostic(
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
index 3a498dee0..8ee69da5b 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
@@ -467,6 +467,8 @@ class _MapCanvasState extends ConsumerState<MapCanvas>
   );
   final MapCanvasInteractionController _interactionController =
       MapCanvasInteractionController();
+  final SurfacePreviewLayerIndexOwner _surfacePreviewLayerIndexOwner =
+      SurfacePreviewLayerIndexOwner();
   final Set<int> _pressedMapPointers = <int>{};
   final Set<LogicalKeyboardKey> _pressedContextMenuKeys =
       <LogicalKeyboardKey>{};
@@ -1661,6 +1663,7 @@ class _MapCanvasState extends ConsumerState<MapCanvas>
                             size: Size.infinite,
                             painter: MapGridPainter(
                               map: activeMap,
+                              surfaceIndexOwner: _surfacePreviewLayerIndexOwner,
                               zoom: state.zoom,
                               offset: state.panOffset,
                               hoveredTile:
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
index dcde290f4..a1b089422 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
@@ -356,6 +356,7 @@ class MapGridPainter extends CustomPainter {
   final bool showGrid;
   final bool showEntityEditorChrome;
   final bool showEditorOverlays;
+  final Map<SurfaceLayer, SurfacePreviewLayerIndex> _surfaceIndexByLayer;
 
   /// Lot Environment-22 : surcouche semi-transparente des cellules masque actives.
   final EnvironmentAreaMask? environmentMaskOverlay;
@@ -367,6 +368,7 @@ class MapGridPainter extends CustomPainter {
 
   MapGridPainter({
     required this.map,
+    SurfacePreviewLayerIndexOwner? surfaceIndexOwner,
     required this.zoom,
     required this.offset,
     this.hoveredTile,
@@ -412,7 +414,10 @@ class MapGridPainter extends CustomPainter {
     this.environmentGeneratedDeletePreviewId,
     this.borderPreview,
     this.borderDiagnosticOverlayPalette,
-  })  : _animationClock = animationClock,
+  })  : _surfaceIndexByLayer =
+            (surfaceIndexOwner ?? SurfacePreviewLayerIndexOwner())
+                .indexesFor(map.layers),
+        _animationClock = animationClock,
         _staticAnimationMs = editorEntityAnimationMs,
         super(repaint: animationClock);
 
@@ -511,6 +516,13 @@ class MapGridPainter extends CustomPainter {
             tileHeight: tileHeight,
             zoom: zoom,
             elapsedMs: effectiveAnimationMs,
+            layerIndex: _surfaceIndexByLayer[layer],
+            viewport: SurfacePreviewCellViewport(
+              left: visibleBounds.left,
+              top: visibleBounds.top,
+              right: visibleBounds.right,
+              bottom: visibleBounds.bottom,
+            ),
           );
         case MapVisualCompositionStepKind.smartTileLayer:
           _paintSmartTileLayer(
diff --git a/packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart b/packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
index c3c5ea1af..6f0028653 100644
--- a/packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
+++ b/packages/map_editor/test/surface_painter/surface_layer_static_preview_test.dart
@@ -7,6 +7,59 @@ import 'package:map_editor/src/features/surface_painter/surface_layer_static_pre
 
 void main() {
   group('SurfaceLayer static preview', () {
+    test('owner reuses indexes for unchanged layer identities', () {
+      const layer = SurfaceLayer(
+        id: 'surface',
+        name: 'Surface',
+        placements: <SurfaceCellPlacement>[
+          SurfaceCellPlacement(
+            x: 1,
+            y: 1,
+            surfacePresetId: 'water',
+          ),
+        ],
+      );
+      final owner = SurfacePreviewLayerIndexOwner();
+
+      final first = owner.indexesFor(const <MapLayer>[layer]);
+      final second = owner.indexesFor(const <MapLayer>[layer]);
+
+      expect(identical(first[layer], second[layer]), isTrue);
+    });
+
+    test('owner rebuilds a replacement layer with the same id', () {
+      const original = SurfaceLayer(
+        id: 'surface',
+        name: 'Surface',
+        placements: <SurfaceCellPlacement>[
+          SurfaceCellPlacement(
+            x: 1,
+            y: 1,
+            surfacePresetId: 'water',
+          ),
+        ],
+      );
+      const replacement = SurfaceLayer(
+        id: 'surface',
+        name: 'Surface',
+        placements: <SurfaceCellPlacement>[
+          SurfaceCellPlacement(
+            x: 2,
+            y: 2,
+            surfacePresetId: 'water',
+          ),
+        ],
+      );
+      final owner = SurfacePreviewLayerIndexOwner();
+      final first = owner.indexesFor(const <MapLayer>[original]);
+
+      final second = owner.indexesFor(const <MapLayer>[replacement]);
+
+      expect(second.containsKey(original), isFalse);
+      expect(second[replacement], isNotNull);
+      expect(identical(first[original], second[replacement]), isFalse);
+    });
+
     test('builds preview cells for visible in-bounds placements', () {
       const layer = SurfaceLayer(
         id: 'surface-main',
@@ -90,6 +143,78 @@ void main() {
       expect(water.role, SurfaceVariantRole.isolated);
     });
 
+    test('limits preview cells to the viewport without losing neighbour roles',
+        () {
+      const layer = SurfaceLayer(
+        id: 'surface-main',
+        name: 'Surfaces',
+        placements: [
+          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 20, y: 20, surfacePresetId: 'water'),
+        ],
+      );
+
+      final cells = buildSurfaceLayerStaticPreviewCells(
+        layer: layer,
+        mapSize: const GridSize(width: 32, height: 32),
+        layerIndex: SurfacePreviewLayerIndex.fromLayer(layer),
+        viewport: const SurfacePreviewCellViewport(
+          left: 1,
+          top: 1,
+          right: 2,
+          bottom: 2,
+        ),
+      );
+
+      expect(cells, hasLength(1));
+      expect(cells.single.placement.x, 1);
+      expect(cells.single.role, SurfaceVariantRole.horizontal);
+    });
+
+    test('layer index preserves authoring order and rejects a stale layer', () {
+      const indexedLayer = SurfaceLayer(
+        id: 'surface-main',
+        name: 'Indexed',
+        placements: [
+          SurfaceCellPlacement(x: 2, y: 2, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
+        ],
+      );
+      const staleLayer = SurfaceLayer(
+        id: 'surface-main',
+        name: 'Stale',
+        placements: [
+          SurfaceCellPlacement(x: 9, y: 9, surfacePresetId: 'water'),
+        ],
+      );
+      final index = SurfacePreviewLayerIndex.fromLayer(indexedLayer);
+
+      final cells = buildSurfaceLayerStaticPreviewCells(
+        layer: indexedLayer,
+        mapSize: const GridSize(width: 16, height: 16),
+        layerIndex: index,
+        viewport: const SurfacePreviewCellViewport(
+          left: -1000000000,
+          top: -1000000000,
+          right: 1000000000,
+          bottom: 1000000000,
+        ),
+      );
+
+      expect(cells.map((cell) => cell.placement).toList(),
+          indexedLayer.placements);
+      expect(
+        () => buildSurfaceLayerStaticPreviewCells(
+          layer: staleLayer,
+          mapSize: const GridSize(width: 16, height: 16),
+          layerIndex: index,
+        ),
+        throwsArgumentError,
+      );
+    });
+
     test('uses deterministic colors per surfacePresetId', () {
       final first = surfaceStaticPreviewColorForPresetId('water');
       final second = surfaceStaticPreviewColorForPresetId('water');
diff --git a/packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart b/packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart
index 07d2e3e93..62fe25c2c 100644
--- a/packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart
+++ b/packages/map_editor/test/surface_painter/surface_tile_preview_resolver_test.dart
@@ -301,6 +301,7 @@ void main() {
           ),
           catalog: catalog,
           availableTilesetIds: const {'water-tileset'},
+          topology: SurfacePlacementTopology(layer.placements),
         ),
         isNull,
       );
diff --git a/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart b/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
index dba16bdb0..f755ee9a2 100644
--- a/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
@@ -21,6 +21,16 @@ import 'runtime_path_autotile.dart';
 
 const int _kEntityFrameDurationFallbackMs = 200;
 
+Map<SurfaceLayer, SurfaceRuntimeLayerIndex> _buildSurfaceLayerIndices(
+  Iterable<MapLayer> layers,
+) {
+  final result = Map<SurfaceLayer, SurfaceRuntimeLayerIndex>.identity();
+  for (final layer in layers.whereType<SurfaceLayer>()) {
+    result[layer] = SurfaceRuntimeLayerIndex.fromLayer(layer);
+  }
+  return result;
+}
+
 enum MapLayerRenderPass {
   background,
   foreground,
@@ -96,6 +106,8 @@ class MapLayersComponent extends PositionComponent {
   final Map<String, Set<int>> _foregroundTileCellIndicesByLayerId;
   final Map<String, Map<int, _AnimatedPlacedCell>>
       _animatedPlacedCellsByLayerId;
+  late final Map<SurfaceLayer, SurfaceRuntimeLayerIndex>
+      _surfaceLayerIndexByLayer = _buildSurfaceLayerIndices(bundle.map.layers);
   late final Map<String, _AnimatedPlacedInstanceSpec> _animatedInstanceById;
   final Map<String, bool> _animationEnabledOverrideByInstanceId =
       <String, bool>{};
@@ -472,10 +484,18 @@ class MapLayersComponent extends PositionComponent {
   }
 
   void _paintSurfaceLayer(Canvas canvas, SurfaceLayer layer) {
+    final visibleCells = _visibleCellRange();
     final instructions = resolveSurfaceRuntimeRenderInstructions(
       layer: layer,
       catalog: bundle.manifest.surfaceCatalog,
       elapsedMs: (_animElapsed * 1000).toInt(),
+      layerIndex: _surfaceLayerIndexByLayer[layer],
+      viewport: SurfaceRuntimeCellViewport(
+        left: visibleCells.startX,
+        top: visibleCells.startY,
+        right: visibleCells.endX,
+        bottom: visibleCells.endY,
+      ),
     );
     if (instructions.isEmpty) {
       return;
diff --git a/packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart b/packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart
index 77f1c079d..70f52564c 100644
--- a/packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart
+++ b/packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart
@@ -2,6 +2,102 @@ import 'package:map_core/map_core.dart';
 
 import 'surface_runtime_render_instruction.dart';
 
+/// Half-open cell bounds used to keep Surface instruction work near the
+/// camera. The topology itself remains complete, so cells on a viewport edge
+/// still see neighbors just outside these bounds.
+final class SurfaceRuntimeCellViewport {
+  const SurfaceRuntimeCellViewport({
+    required this.left,
+    required this.top,
+    required this.right,
+    required this.bottom,
+  });
+
+  final int left;
+  final int top;
+  final int right;
+  final int bottom;
+
+  bool get isEmpty => right <= left || bottom <= top;
+
+  bool contains(SurfaceCellPlacement placement) =>
+      !isEmpty &&
+      placement.x >= left &&
+      placement.x < right &&
+      placement.y >= top &&
+      placement.y < bottom;
+}
+
+/// Runtime-owned cache for one immutable Surface layer.
+///
+/// Core owns only [SurfacePlacementTopology]. This wrapper owns the sorted
+/// render order and row index needed by Flame's viewport, and is rebuilt when
+/// a new immutable layer instance is mounted.
+final class SurfaceRuntimeLayerIndex {
+  SurfaceRuntimeLayerIndex._({
+    required SurfaceLayer sourceLayer,
+    required List<SurfaceCellPlacement> placements,
+  })  : _sourceLayer = sourceLayer,
+        _placements = placements,
+        _topology = SurfacePlacementTopology(placements),
+        _placementsByRow = _indexPlacementsByRow(placements);
+
+  factory SurfaceRuntimeLayerIndex.fromLayer(SurfaceLayer layer) {
+    return SurfaceRuntimeLayerIndex._(
+      sourceLayer: layer,
+      placements: _runtimeResolvablePlacements(layer.placements),
+    );
+  }
+
+  final SurfaceLayer _sourceLayer;
+  final List<SurfaceCellPlacement> _placements;
+  final SurfacePlacementTopology _topology;
+  final Map<int, List<SurfaceCellPlacement>> _placementsByRow;
+
+  int get indexedPlacementCount => _placements.length;
+
+  Iterable<SurfaceCellPlacement> placementsIn(
+    SurfaceRuntimeCellViewport? viewport,
+  ) sync* {
+    if (viewport == null) {
+      yield* _placements;
+      return;
+    }
+    if (viewport.isEmpty) {
+      return;
+    }
+    if (_placements.isEmpty) {
+      return;
+    }
+    final firstIndexedRow = _placements.first.y;
+    final lastIndexedRowExclusive = _placements.last.y + 1;
+    final startRow =
+        viewport.top > firstIndexedRow ? viewport.top : firstIndexedRow;
+    final endRow = viewport.bottom < lastIndexedRowExclusive
+        ? viewport.bottom
+        : lastIndexedRowExclusive;
+    for (var y = startRow; y < endRow; y += 1) {
+      final row = _placementsByRow[y];
+      if (row == null) {
+        continue;
+      }
+      for (final placement in row) {
+        if (placement.x >= viewport.left && placement.x < viewport.right) {
+          yield placement;
+        }
+      }
+    }
+  }
+
+  SurfaceVariantRole roleFor(SurfaceCellPlacement placement) {
+    return _topology.roleAt(
+      x: placement.x,
+      y: placement.y,
+      surfacePresetId: placement.surfacePresetId,
+    );
+  }
+}
+
 /// Resolves Surface placements into pure runtime render instructions.
 ///
 /// This is the runtime counterpart of the editor preview resolver, minus any
@@ -11,30 +107,34 @@ List<SurfaceRuntimeRenderInstruction> resolveSurfaceRuntimeRenderInstructions({
   required SurfaceLayer layer,
   required ProjectSurfaceCatalog catalog,
   int elapsedMs = 0,
+  SurfaceRuntimeLayerIndex? layerIndex,
+  SurfaceRuntimeCellViewport? viewport,
 }) {
   if (!layer.isVisible || layer.opacity <= 0) {
     return const <SurfaceRuntimeRenderInstruction>[];
   }
 
-  final placements = _runtimeResolvablePlacements(layer.placements);
-  if (placements.isEmpty) {
+  final index = layerIndex ?? SurfaceRuntimeLayerIndex.fromLayer(layer);
+  if (!identical(index._sourceLayer, layer)) {
+    throw ArgumentError.value(
+      index._sourceLayer.id,
+      'layerIndex',
+      'must belong to the provided SurfaceLayer instance ${layer.id}',
+    );
+  }
+  if (index.indexedPlacementCount == 0 || viewport?.isEmpty == true) {
     return const <SurfaceRuntimeRenderInstruction>[];
   }
 
   final instructions = <SurfaceRuntimeRenderInstruction>[];
-  for (final placement in placements) {
+  for (final placement in index.placementsIn(viewport)) {
     final presetId = placement.surfacePresetId.trim();
     final preset = catalog.presetById(presetId);
     if (preset == null) {
       continue;
     }
 
-    final role = resolveSurfaceVariantRoleForPlacement(
-      placements: placements,
-      x: placement.x,
-      y: placement.y,
-      surfacePresetId: presetId,
-    );
+    final role = index.roleFor(placement);
     final animationId = _resolveAnimationId(preset, role);
     if (animationId == null) {
       continue;
@@ -80,6 +180,23 @@ List<SurfaceRuntimeRenderInstruction> resolveSurfaceRuntimeRenderInstructions({
   return List<SurfaceRuntimeRenderInstruction>.unmodifiable(instructions);
 }
 
+Map<int, List<SurfaceCellPlacement>> _indexPlacementsByRow(
+  List<SurfaceCellPlacement> placements,
+) {
+  final rows = <int, List<SurfaceCellPlacement>>{};
+  for (final placement in placements) {
+    rows
+        .putIfAbsent(placement.y, () => <SurfaceCellPlacement>[])
+        .add(placement);
+  }
+  return Map<int, List<SurfaceCellPlacement>>.unmodifiable(
+    <int, List<SurfaceCellPlacement>>{
+      for (final entry in rows.entries)
+        entry.key: List<SurfaceCellPlacement>.unmodifiable(entry.value),
+    },
+  );
+}
+
 List<SurfaceCellPlacement> _runtimeResolvablePlacements(
   Iterable<SurfaceCellPlacement> placements,
 ) {
diff --git a/packages/map_runtime/test/surface/surface_runtime_resolver_test.dart b/packages/map_runtime/test/surface/surface_runtime_resolver_test.dart
index 5f39f8edd..62678e7d4 100644
--- a/packages/map_runtime/test/surface/surface_runtime_resolver_test.dart
+++ b/packages/map_runtime/test/surface/surface_runtime_resolver_test.dart
@@ -303,6 +303,116 @@ void main() {
 
       expect(keys, ['0:0', '1:0', '2:1']);
     });
+
+    test('reuses a layer index and resolves only viewport placements', () {
+      const layer = SurfaceLayer(
+        id: 'surface',
+        name: 'Surfaces',
+        placements: [
+          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
+          SurfaceCellPlacement(x: 40, y: 40, surfacePresetId: 'water'),
+        ],
+      );
+      final index = SurfaceRuntimeLayerIndex.fromLayer(layer);
+
+      final instructions = resolveSurfaceRuntimeRenderInstructions(
+        layer: layer,
+        catalog: _simpleWaterCatalog(),
+        layerIndex: index,
+        viewport: const SurfaceRuntimeCellViewport(
+          left: 1,
+          top: 1,
+          right: 2,
+          bottom: 2,
+        ),
+      );
+
+      expect(instructions, hasLength(1));
+      expect(instructions.single.x, 1);
+      expect(instructions.single.y, 1);
+      expect(
+        instructions.single.resolvedRole,
+        SurfaceVariantRole.horizontal,
+        reason: 'Off-viewport neighbours must remain in topology.',
+      );
+      expect(index.indexedPlacementCount, layer.placements.length);
+    });
+
+    test('an empty viewport performs no placement resolution', () {
+      const layer = SurfaceLayer(
+        id: 'surface',
+        name: 'Surfaces',
+        placements: [
+          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
+        ],
+      );
+
+      expect(
+        resolveSurfaceRuntimeRenderInstructions(
+          layer: layer,
+          catalog: _simpleWaterCatalog(),
+          viewport: const SurfaceRuntimeCellViewport(
+            left: 2,
+            top: 2,
+            right: 2,
+            bottom: 2,
+          ),
+        ),
+        isEmpty,
+      );
+    });
+
+    test('rejects an index built for another layer instance with the same id',
+        () {
+      const indexedLayer = SurfaceLayer(
+        id: 'surface',
+        name: 'Indexed',
+        placements: [
+          SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
+        ],
+      );
+      const requestedLayer = SurfaceLayer(
+        id: 'surface',
+        name: 'Requested',
+        placements: [
+          SurfaceCellPlacement(x: 9, y: 9, surfacePresetId: 'water'),
+        ],
+      );
+
+      expect(
+        () => resolveSurfaceRuntimeRenderInstructions(
+          layer: requestedLayer,
+          catalog: _simpleWaterCatalog(),
+          layerIndex: SurfaceRuntimeLayerIndex.fromLayer(indexedLayer),
+        ),
+        throwsArgumentError,
+      );
+    });
+
+    test('clamps a very large viewport to indexed rows', () {
+      const layer = SurfaceLayer(
+        id: 'surface',
+        name: 'Surfaces',
+        placements: [
+          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
+        ],
+      );
+
+      final instructions = resolveSurfaceRuntimeRenderInstructions(
+        layer: layer,
+        catalog: _simpleWaterCatalog(),
+        viewport: const SurfaceRuntimeCellViewport(
+          left: -1000000000,
+          top: -1000000000,
+          right: 1000000000,
+          bottom: 1000000000,
+        ),
+      );
+
+      expect(instructions, hasLength(1));
+    });
   });
 }
~~~~

## Annexe B — Contenu complet des fichiers créés

Les Evidence Packs ne s’auto-dupliquent pas. Tous les autres fichiers créés par ce lot sont
reproduits intégralement.

### `packages/map_core/benchmark/surface_role_scaling.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

const _schemaVersion = 2;
const _generatorVersion = 1;
const _knownFixtures = <String>{'dense', 'hole', 'line', 'sparse', 'mixed'};
const _knownModes = <String>{'legacy', 'topology'};

Future<void> main(List<String> arguments) async {
  try {
    final options = _Options.parse(arguments);
    final results = <Map<String, Object?>>[];
    for (final fixture in options.fixtures) {
      for (final size in options.sizes) {
        final placements = _placements(fixture, size);
        final fingerprint = _fingerprint(placements);
        String? expectedRoleChecksum;
        for (final mode in options.modes) {
          for (var i = 0; i < options.warmups; i += 1) {
            _measure(mode, placements);
          }
          final measurements = <({int elapsedUs, String roleChecksum})>[
            for (var i = 0; i < options.samples; i += 1)
              _measure(mode, placements),
          ];
          final roleChecksum = measurements.first.roleChecksum;
          if (measurements.any(
            (measurement) => measurement.roleChecksum != roleChecksum,
          )) {
            throw StateError('Unstable role checksum for $fixture/$size.');
          }
          expectedRoleChecksum ??= roleChecksum;
          if (expectedRoleChecksum != roleChecksum) {
            throw StateError(
              'Role mismatch between benchmark modes for $fixture/$size.',
            );
          }
          final samples = measurements
              .map((measurement) => measurement.elapsedUs)
              .toList(growable: false)
            ..sort();
          results.add(<String, Object?>{
            'mode': mode,
            'fixture': fixture,
            'generatorVersion': _generatorVersion,
            'datasetFingerprint': fingerprint,
            'roleChecksum': roleChecksum,
            'placementCount': placements.length,
            'samplesUs': samples,
            'p50Us': _percentile(samples, 0.50),
            'p95Us': _percentile(samples, 0.95),
            'p99Us': _percentile(samples, 0.99),
          });
        }
      }
    }

    final output = <String, Object?>{
      'schemaVersion': _schemaVersion,
      'benchmark': 'surface_role_scaling',
      'executionMode': const bool.fromEnvironment('dart.vm.product')
          ? 'dart-aot'
          : 'dart-jit',
      'sdk': Platform.version,
      'os': Platform.operatingSystem,
      'architecture': _architectureLabel(),
      'commit': await _gitValue(<String>['rev-parse', 'HEAD']),
      'treeState': (await _gitValue(<String>['status', '--porcelain'])).isEmpty
          ? 'clean'
          : 'dirty',
      'warmups': options.warmups,
      'sampleCount': options.samples,
      'fixtures': options.fixtures,
      'modes': options.modes,
      'results': results,
    };
    final outputFile = _validatedOutputFile(options.outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(output)}\n',
    );
    stdout.writeln(jsonEncode(output));
  } on FormatException catch (error) {
    stderr.writeln('surface_role_scaling: ${error.message}');
    exitCode = 64;
  }
}

({int elapsedUs, String roleChecksum}) _measure(
  String mode,
  List<SurfaceCellPlacement> placements,
) {
  final stopwatch = Stopwatch()..start();
  var checksum = 0x811c9dc5;
  if (mode == 'legacy') {
    for (final placement in placements) {
      final role = resolveSurfaceVariantRoleForPlacement(
        placements: placements,
        x: placement.x,
        y: placement.y,
        surfacePresetId: placement.surfacePresetId,
      );
      checksum = ((checksum ^ role.index) * 0x01000193) & 0xffffffff;
    }
  } else {
    final topology = SurfacePlacementTopology(placements);
    for (final placement in placements) {
      final role = topology.roleAt(
        x: placement.x,
        y: placement.y,
        surfacePresetId: placement.surfacePresetId,
      );
      checksum = ((checksum ^ role.index) * 0x01000193) & 0xffffffff;
    }
  }
  stopwatch.stop();
  return (
    elapsedUs: stopwatch.elapsedMicroseconds,
    roleChecksum: checksum.toRadixString(16).padLeft(8, '0'),
  );
}

String _fingerprint(List<SurfaceCellPlacement> placements) {
  final encoded = placements
      .map((placement) =>
          '${placement.x}:${placement.y}:${placement.surfacePresetId}')
      .join('|');
  return sha256.convert(utf8.encode(encoded)).toString();
}

List<SurfaceCellPlacement> _placements(String fixture, int count) {
  final width = math.max(1, math.sqrt(count).ceil());
  final out = <SurfaceCellPlacement>[];
  for (var index = 0; index < count; index += 1) {
    final x = switch (fixture) {
      'line' => index,
      'sparse' => index * 2,
      _ => index % width,
    };
    final y = switch (fixture) {
      'line' || 'sparse' => 0,
      _ => index ~/ width,
    };
    if (fixture == 'hole' &&
        x == width ~/ 2 &&
        y == math.max(1, count ~/ width) ~/ 2) {
      // Move the center occupancy far away while retaining an exact count.
      out.add(
        SurfaceCellPlacement(
          x: width + index,
          y: width + index,
          surfacePresetId: 'water',
        ),
      );
      continue;
    }
    out.add(
      SurfaceCellPlacement(
        x: x,
        y: y,
        surfacePresetId: fixture == 'mixed' && index.isOdd ? 'lava' : 'water',
      ),
    );
  }
  // Reverse a stable subset so the index cannot rely on authoring order.
  return List<SurfaceCellPlacement>.unmodifiable(out.reversed);
}

int _percentile(List<int> sortedSamples, double percentile) {
  final index = (percentile * sortedSamples.length).ceil() - 1;
  return sortedSamples[index.clamp(0, sortedSamples.length - 1)];
}

File _validatedOutputFile(String path) {
  final packageRoot = Directory(Directory.current.resolveSymbolicLinksSync());
  final requested = File.fromUri(
    packageRoot.uri.resolveUri(Uri.file(path)),
  ).absolute;
  var existingAncestor = requested.parent;
  final missingDirectories = <String>[];
  while (!existingAncestor.existsSync()) {
    final segments = existingAncestor.uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty ||
        existingAncestor.parent.path == existingAncestor.path) {
      throw const FormatException('output parent cannot be resolved');
    }
    missingDirectories.add(segments.last);
    existingAncestor = existingAncestor.parent;
  }
  final canonicalAncestor =
      Directory(existingAncestor.resolveSymbolicLinksSync());
  if (!_isWithin(packageRoot.uri, canonicalAncestor.uri)) {
    throw const FormatException('output must stay inside packages/map_core');
  }
  var canonicalParent = canonicalAncestor.uri;
  for (final directory in missingDirectories.reversed) {
    canonicalParent = canonicalParent.resolve('$directory/');
  }
  final fileName = requested.uri.pathSegments.last;
  final canonicalFile = File.fromUri(canonicalParent.resolve(fileName));
  if (!_isWithin(packageRoot.uri, canonicalFile.uri)) {
    throw const FormatException('output must stay inside packages/map_core');
  }
  if (FileSystemEntity.typeSync(
        canonicalFile.path,
        followLinks: false,
      ) ==
      FileSystemEntityType.link) {
    throw const FormatException('output must not be a symbolic link');
  }
  if (canonicalFile.existsSync()) {
    final canonicalExisting =
        Uri.file(canonicalFile.resolveSymbolicLinksSync());
    if (!_isWithin(packageRoot.uri, canonicalExisting)) {
      throw const FormatException('output symlink leaves packages/map_core');
    }
  }
  return canonicalFile;
}

bool _isWithin(Uri root, Uri candidate) =>
    candidate.path == root.path || candidate.path.startsWith(root.path);

Future<String> _gitValue(List<String> arguments) async {
  final result = await Process.run('git', arguments);
  return result.exitCode == 0 ? '${result.stdout}'.trim() : 'unknown';
}

String _architectureLabel() {
  final executable = Platform.resolvedExecutable.toLowerCase();
  if (executable.contains('arm64')) return 'arm64';
  if (executable.contains('x64') || executable.contains('x86_64')) return 'x64';
  return Platform.version.contains('arm64') ? 'arm64' : 'unknown';
}

final class _Options {
  const _Options({
    required this.warmups,
    required this.samples,
    required this.sizes,
    required this.fixtures,
    required this.modes,
    required this.outputPath,
  });

  final int warmups;
  final int samples;
  final List<int> sizes;
  final List<String> fixtures;
  final List<String> modes;
  final String outputPath;

  static _Options parse(List<String> arguments) {
    final values = <String, String>{};
    for (var i = 0; i < arguments.length; i += 1) {
      final argument = arguments[i];
      if (!argument.startsWith('--') || i + 1 >= arguments.length) {
        throw FormatException('invalid argument: $argument');
      }
      values[argument.substring(2)] = arguments[++i];
    }
    const allowed = <String>{
      'warmups',
      'samples',
      'sizes',
      'fixtures',
      'modes',
      'output',
    };
    final unknown = values.keys.where((key) => !allowed.contains(key));
    if (unknown.isNotEmpty) {
      throw FormatException('unknown option --${unknown.first}');
    }
    final warmups = int.tryParse(values['warmups'] ?? '5');
    final samples = int.tryParse(values['samples'] ?? '30');
    if (warmups == null || warmups < 0) {
      throw const FormatException('warmups must be non-negative');
    }
    if (samples == null || samples <= 0) {
      throw const FormatException('samples must be positive');
    }
    final sizes = _positiveInts(values['sizes'] ?? '100,400,1024,2500');
    final fixtures = (values['fixtures'] ?? 'dense,hole,line,sparse,mixed')
        .split(',')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (fixtures.isEmpty) {
      throw const FormatException('fixtures must not be empty');
    }
    for (final fixture in fixtures) {
      if (!_knownFixtures.contains(fixture)) {
        throw FormatException('unknown fixture: $fixture');
      }
    }
    final modes = (values['modes'] ?? 'topology')
        .split(',')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (modes.isEmpty) {
      throw const FormatException('modes must not be empty');
    }
    for (final mode in modes) {
      if (!_knownModes.contains(mode)) {
        throw FormatException('unknown mode: $mode');
      }
    }
    final output = values['output'];
    if (output == null || output.trim().isEmpty) {
      throw const FormatException('--output is required');
    }
    return _Options(
      warmups: warmups,
      samples: samples,
      sizes: sizes,
      fixtures: List<String>.unmodifiable(fixtures),
      modes: List<String>.unmodifiable(modes),
      outputPath: output,
    );
  }

  static List<int> _positiveInts(String raw) {
    final tokens = raw.split(',');
    final values = <int>[];
    for (final token in tokens) {
      final value = int.tryParse(token);
      if (value == null) {
        throw FormatException('invalid size: $token');
      }
      values.add(value);
    }
    if (values.isEmpty || values.any((value) => value <= 0)) {
      throw const FormatException('sizes must contain positive integers');
    }
    return List<int>.unmodifiable(values);
  }
}
~~~~

### `packages/map_core/test/benchmark/surface_role_scaling_cli_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('writes comparable legacy and topology results for one dataset',
      () async {
    await Directory('build/test').create(recursive: true);
    final outputDirectory = await Directory('build/test').createTemp(
      'surface_role_cli_',
    );
    addTearDown(() => outputDirectory.delete(recursive: true));
    final outputPath = '${outputDirectory.path}/result.json';

    final result = await _run(<String>[
      '--warmups',
      '0',
      '--samples',
      '1',
      '--sizes',
      '9',
      '--fixtures',
      'dense',
      '--modes',
      'legacy,topology',
      '--output',
      outputPath,
    ]);

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final payload = jsonDecode(await File(outputPath).readAsString())
        as Map<String, Object?>;
    final results = payload['results']! as List<Object?>;
    expect(payload['schemaVersion'], 2);
    expect(results, hasLength(2));
    final legacy = results.first as Map<String, Object?>;
    final topology = results.last as Map<String, Object?>;
    expect(legacy['mode'], 'legacy');
    expect(topology['mode'], 'topology');
    expect(legacy['datasetFingerprint'], topology['datasetFingerprint']);
    expect(legacy['roleChecksum'], isNotEmpty);
    expect(legacy['roleChecksum'], topology['roleChecksum']);
  });

  test('rejects malformed size tokens and output paths outside the package',
      () async {
    final malformed = await _run(const <String>[
      '--sizes',
      '9,bad',
      '--output',
      'build/test/malformed.json',
    ]);
    final escaped = await _run(const <String>[
      '--sizes',
      '9',
      '--output',
      '../surface-role-escape.json',
    ]);

    expect(malformed.exitCode, 64);
    expect('${malformed.stderr}', contains('invalid size: bad'));
    expect(escaped.exitCode, 64);
    expect('${escaped.stderr}', contains('must stay inside packages/map_core'));
  });
}

Future<ProcessResult> _run(List<String> arguments) {
  return Process.run(
    Platform.resolvedExecutable,
    <String>['run', 'benchmark/surface_role_scaling.dart', ...arguments],
    workingDirectory: Directory.current.path,
  );
}
~~~~

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-03-surface-topology.md`

~~~~markdown
# PERF-RM-03 — Plan d'implémentation topologie Surface O(P)

**Scope :** topologie pure partagée dans `map_core`, consommée une fois par résolution editor/runtime, avec filtrage viewport côté runtime. JSON, rôles et catalogues restent inchangés.

## Audit initial

- `resolveSurfaceVariantRoleForPlacement` reconstruit un `Set<String>` en parcourant toutes les placements à chaque cellule.
- Le runtime et les deux chemins preview éditeur appellent cet adapter dans une boucle, produisant O(P²).
- `resolveSurfaceVariantRoleAt` est déjà une primitive O(1) correcte et testée.
- `MapLayersComponent` possède déjà un rectangle local visible mais ne le transmet qu'après la création de toutes les instructions.

## Étapes test-first

- [ ] Étendre `surface_variant_role_resolver_test.dart` avec `SurfacePlacementTopology` : rôles par preset, trous/diagonales, duplicats, ordre, coordonnées invalides et iterable compté parcouru une seule fois.
- [ ] Exécuter le test et conserver RED sur le type absent.
- [ ] Construire en un passage une occupation groupée par preset avec clés coordonnées non allouantes ; exposer `roleAt` pur et conserver l'adapter historique pour compatibilité.
- [ ] Modifier runtime et preview statique pour construire une topologie par layer/résolution, puis l'injecter au resolver de tuile éditeur.
- [ ] Ajouter un viewport cellule optionnel au resolver runtime ; calculer les bornes depuis `_visibleLocalRect` avec halo d'une cellule.
- [ ] Ajouter/adapter tests editor/runtime pour égalité des rôles, catalog/atlas manquant, layer caché et exclusion viewport sans couture.
- [ ] Créer le benchmark AOT contractuel `benchmark/surface_role_scaling.dart`, avec CLI validée, warmups/samples, tailles et JSON dans le package.
- [ ] Mesurer 100/400/1024/2500 puis relancer tests complets/analyzers des trois packages.

## Non-objectifs et risques

- Aucun cache global mutable ni clé fondée sur l'identité d'objet ; la topologie vit le temps d'une résolution.
- Pas de nouvelle sémantique de peinture Surface, donc parité PMCP/JSONL/MCP : `N/A — contrat inchangé`.
- Le filtre viewport ne doit pas modifier la topologie : les voisins hors viewport restent présents dans l'index.

## Preuves attendues

- Iterable source parcouru une fois ; rôle identique sur fixtures existantes.
- 2 500 placements sous 5 ms p95 AOT sur la machine de preuve, pente documentée.
- Goldens editor/runtime inchangés et catalogue MCP live inchangé si vérifiable.
~~~~
