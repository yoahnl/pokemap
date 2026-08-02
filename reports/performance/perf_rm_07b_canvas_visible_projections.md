# PERF-RM-07B — Evidence Pack des projections canvas visibles

Date : 2026-08-02
Phase : 3 — Fluidité éditeur
Lot : `PERF-RM-07B`
Verdict proposé : **DONE avec limite de suite globale documentée**
Base du reçu profilé : `44f6a85ac21b78dd165e6f955c7d442d306934fd`
Reçu machine non versionné : `packages/map_editor/build/performance/rm07b/editor_canvas_visible_projections.json`

> Ce rapport s'exclut lui-même de l'exigence de reproduction intégrale des fichiers créés afin d'éviter une récursion infinie. Les trois autres fichiers créés par le lot sont reproduits intégralement en annexe.

## 1. Audit initial

La source de vérité est `reports/performance/pokemap_performance_remediation_roadmap.md`, section `PERF-RM-07B — Projections canvas visibles`. L'audit a confirmé deux parcours proportionnels à la taille totale de la map avant peinture :

1. le painter appelait le resolver Smart Tile sans ses bornes `startX/startY/endX/endY` déjà disponibles ;
2. les instructions d'ombres statiques et projetées, ainsi que les éléments placés visibles, étaient reconstruits ou parcourus depuis la totalité de la map à chaque paint.

Contraintes retenues : viewport constant, géométrie exacte des ombres, aucun halo arbitraire, aucun `RepaintBoundary` généralisé, painter standard conservé comme contrôle, aucune modification de schéma ou de sémantique d'authoring.

### État Git au début du lot

```text
 M packages/map_authoring/lib/map_authoring.dart
 M packages/map_authoring/lib/src/api/authoring_read_api.dart
 M packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart
 M packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart
 M packages/map_authoring/lib/src/domains/maps/map_operations_batch.dart
 M packages/map_authoring/lib/src/domains/maps/semantic_map_action_support.dart
 M packages/map_authoring/lib/src/parity/full_authoring_parity.dart
 M packages/map_authoring/lib/src/transactions/authoring_plan.dart
 M packages/map_authoring/test/domains/maps/map_lifecycle_transaction_test.dart
 M packages/map_authoring/test/domains/maps/map_operations_batch_test.dart
 M packages/map_authoring/test/tooling/jsonl_worker_test.dart
 M packages/map_core/lib/src/exceptions/map_exceptions.dart
 M packages/map_core/lib/src/operations/smart_tile_layer_operations.dart
 M packages/map_core/lib/src/validation/validators.dart
 M packages/map_core/test/smart_tiles/smart_tile_layer_operations_test.dart
 M packages/map_editor/lib/src/features/editor/application/world_map_tool_activation.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart
 M packages/map_editor/test/features/editor/application/world_map_paint_layer_routing_test.dart
 M packages/map_editor/test/features/editor/application/world_map_tool_activation_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart
?? packages/map_authoring/lib/src/domains/maps/map_validation_diagnostics.dart
?? packages/map_authoring/lib/src/domains/maps/smart_tile_layer_actions.dart
?? packages/map_authoring/test/domains/maps/smart_tile_layer_actions_test.dart
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

Ces changements étaient préexistants et hors scope. Pendant la validation, un autre flux du workspace partagé a commité les changements authoring sous `44f6a85ac feat(authoring): add Smart Tile layer maintenance actions`. Le lot n'a ni modifié ni inclus ce commit. Les changements World Map et le `__pycache__` restés non commités ont été préservés.

## 2. Décision et implémentation

- Les bornes visibles existantes sont transmises aux deux passes du resolver Smart Tile.
- Une projection d'ombres est construite une fois par identité immuable `ProjectManifest` / `MapData` / dimensions de tuile / preset de lumière.
- Les géométries exactes sont indexées par buckets de taille tuile puis filtrées par intersection half-open.
- Les éléments placés sont eux aussi indexés par cellules de footprint, en conservant l'ordre source.
- Le cache est détenu par `_MapCanvasState` et vidé à la destruction du canvas.
- Les compteurs de debug rendent observable le travail visible Smart Tile, ombres statiques, ombres projetées et éléments placés.
- Le painter standard reste inchangé dans sa stratégie de composition ; aucun `RepaintBoundary` n'a été ajouté.
- Le resolver `map_core` possédait déjà les paramètres de bornes : aucune modification de `map_core` n'était nécessaire.

### Inventaire des fichiers du lot

Créés :

- `packages/map_editor/integration_test/editor_canvas_projection_journey_test.dart`
- `packages/map_editor/lib/src/application/shadow/editor_shadow_preview_projection_index.dart`
- `reports/performance/plans/2026-08-02-pokemap-perf-rm-07b-canvas-visible-projections.md`
- `reports/performance/perf_rm_07b_canvas_visible_projections.md` (ce rapport)

Modifiés :

- `packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart`
- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart`
- `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`
- `packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart`

### Statistique du patch avant ajout du présent rapport

```text
 .../editor_canvas_projection_journey_test.dart     | 452 +++++++++++++++++++++
 .../editor_projected_building_shadow_preview.dart  |  11 +
 .../editor_shadow_preview_projection_index.dart    | 287 +++++++++++++
 .../shadow/editor_static_shadow_preview.dart       |  63 +++
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |   7 +-
 .../src/ui/canvas/map_canvas/map_grid_painter.dart | 120 +++---
 ...tor_projected_building_shadow_preview_test.dart |  48 +++
 .../shadow/editor_static_shadow_preview_test.dart  | 141 +++++++
 .../world_map_large_map_performance_test.dart      | 123 ++++++
 ...kemap-perf-rm-07b-canvas-visible-projections.md |  38 ++
 10 files changed, 1238 insertions(+), 52 deletions(-)
```

## 3. Profil reproductible

Commande finale :

```bash
cd packages/map_editor
flutter drive --profile -d macos \
  --driver=test_driver/performance_driver.dart \
  --target=integration_test/editor_canvas_projection_journey_test.dart \
  --dart-define=POKEMAP_PERF_OUTPUT=build/performance/rm07b/editor_canvas_visible_projections.json
```

Résultat exact : exit 0, application Profile construite (33.1 MB), `All tests passed!`. Avertissement non bloquant : le driver a imprimé l'avertissement générique de détection `integration_test`, mais a reçu le rapport JSON et terminé avec succès.

Mesure : 8 warmups puis 90 échantillons par mode et par taille, viewport fixe 512×512 px, tuiles 32×32, enregistrement UI-thread du canvas ; rasterisation de la picture hors scope.

| Mode | p95 128² | p95 256² | p95 512² | p95 1 024² |
|---|---:|---:|---:|---:|
| Standard | 214 µs | 161 µs | 164 µs | 175 µs |
| Smart Tiles | 1 588 µs | 1 531 µs | 1 488 µs | 1 534 µs |
| Ombres | 96 µs | 114 µs | 95 µs | 130 µs |
| Combiné | 1 668 µs | 1 856 µs | 1 765 µs | 1 811 µs |

Gates :

- combiné 1 024² : **1,811 ms < 8 ms** ;
- ratio p95 combiné 1 024² / 128² : **1,0857 ≤ 1,5** ;
- contrôle standard 1 024² : **0,175 ms < plafond d'observation 4 ms** ;
- les trois gates du reçu sont `true`.

Travail observable constant à toutes les tailles :

- 289 cellules visibles ;
- 289 visites Smart Tile ;
- 1 instruction d'ombre statique ;
- 1 instruction d'ombre projetée ;
- 2 éléments placés visibles ;
- alors que les fixtures ombres/combinées passent de 65 à 4 097 éléments placés.

Reçu : tree fingerprint `46c547d7621ba5ce6af474f6104324b24b6496611d5278c73cb6b107e7afceeb`, tree state `dirty`, base `44f6a85ac`, Flutter `3.46.0-0.3.pre`, Dart `3.13.0-167.1.beta`, Flame `1.38.0`.

## 4. Vérifications et résultats exacts

### TDD RED

```bash
cd packages/map_editor
flutter test   test/application/shadow/editor_static_shadow_preview_test.dart   test/application/shadow/editor_projected_building_shadow_preview_test.dart   test/ui/world_map/world_map_large_map_performance_test.dart
```

Résultat attendu obtenu : exit 1 uniquement sur les contrats ajoutés (`EditorShadowPreviewViewport`, paramètre `viewport`, compteur `smartTileVisualVisits`) avant implémentation.

### TDD GREEN ciblé

Même commande après implémentation : exit 0, `+50: All tests passed!`.

```bash
cd packages/map_core
dart test test/smart_tiles/smart_tile_layer_visual_resolver_test.dart && dart analyze
```

Résultat : exit 0, `+3: All tests passed!`, puis `No issues found!`.

```bash
cd packages/map_editor
flutter test   test/editor_shell_page_smoke_test.dart   test/ui/world_map/world_map_rebuild_isolation_test.dart   test/map_grid_painter_test.dart   test/ui/world_map/world_map_large_map_performance_test.dart   test/ui/canvas/editor_static_shadow_preview_painter_test.dart   test/application/shadow/editor_static_shadow_preview_test.dart   test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Résultat : exit 0, `+106: All tests passed!`.

Après la correction de lint de la fixture Smart Tile :

```bash
cd packages/map_editor
flutter test test/ui/world_map/world_map_large_map_performance_test.dart
```

Résultat : exit 0, 8 tests, `All tests passed!`.

```bash
cd packages/map_editor
flutter analyze
```

Résultat final : exit 0, `No issues found! (ran in 5.7s)`.

```bash
cd packages/map_editor
dart format --output=none --set-exit-if-changed <9 fichiers Dart du lot>
```

Résultat : exit 0, `Formatted 9 files (0 changed) in 0.07 seconds.`.

```bash
git diff --check -- <fichiers du lot>
```

Résultat : exit 0, aucune sortie.

### Suite globale map_editor

```bash
cd packages/map_editor
flutter test
```

La commande a été lancée mais n'a pas pu produire un verdict complet. Après 10 min 21 s, elle était bloquée dans des tests hors des chemins RM-07B et avait déjà imprimé le compteur exact `+5234 ~6 -36`. Elle a été interrompue par SIGINT. La finalisation a indiqué `Some tests failed`, quatre tests nommés puis `... and 33 more`; le test courant `narrative_event_map_banner_test.dart` n'a pas terminé après l'interruption. Les premiers échecs concernaient notamment `pending_border_save_entry_points_test.dart`, `pending_border_save_notifier_test.dart` et `pokemap_right_inspector_resize_test.dart`, tous hors du patch RM-07B.

Conséquence : le lot dispose de preuves ciblées vertes, d'une analyse complète verte et d'un profil vert, mais **ne revendique pas une suite globale verte** sur l'état concurrent du workspace.

## 5. Parité, architecture et non-objectifs

- Parité PokeMap MCP : **N/A**. Le lot ne change ni donnée projet, ni commande d'authoring, ni validation, ni import/export, ni résultat visuel attendu ; il borne seulement le travail interne du painter. Aucun contrat `map_authoring` ou catalogue MCP à exposer.
- Roadmap gameplay `FG-*` : **N/A**, aucune mécanique fangame n'est modifiée.
- Frontières : changements limités à `map_editor`; `map_core` reste inchangé.
- Design system : **N/A**, aucun composant UI ou token couleur n'est ajouté.
- Non-objectifs respectés : pas de halo, pas de cache global, pas de changement de schéma, pas de préchargement, pas de `RepaintBoundary` généralisé.

## 6. Passes indépendantes et verdicts

| Passe | Verdict | Preuve |
|---|---|---|
| Audit / architecture | PASS | hotspot confirmé, bornes existantes du resolver réutilisées, cache local au canvas |
| Implémentation | PASS | index exact, invalidation étroite, ordre des éléments conservé |
| Tests | PASS ciblé / LIMIT global | +106 ciblés et +8 charge verts ; suite globale concurrente interrompue |
| Build / validation | PASS | profil macOS exit 0, gates verts, analyse complète verte |
| Auto-critique finale | PASS avec risques | risques résiduels explicités ci-dessous |

## 7. Auto-critique et risques résiduels

1. Le benchmark mesure l'enregistrement du canvas sur le UI thread, pas la rasterisation GPU ; il prouve la borne algorithmique demandée, pas toutes les sources de jank.
2. Les coutures de viewport sont couvertes par intersections half-open, bords exacts, éléments tournés, ordre de couches et tests painter existants ; aucune session de QA visuelle humaine ou golden raster dédiée n'a été ajoutée.
3. L'invalidation repose sur l'identité d'objets immuables. Elle est correcte avec le modèle actuel de remplacement de `MapData` / `ProjectManifest`; une future mutation in-place nécessiterait une révision explicite.
4. La projection complète est reconstruite lors d'une vraie révision sémantique. Ce coût ponctuel est intentionnel et exclu des repaints pan/zoom/animation ; il pourra être mesuré séparément si les maps dépassent durablement les fixtures 1 024².
5. La suite globale n'est pas verte sur l'état partagé observé. Les échecs et le blocage sont hors du patch, mais devront être résolus ou rejoués dans un arbre stabilisé.

## 8. État Git de remise attendu après le commit exact du lot

Le commit doit retirer uniquement les onze chemins RM-07B du working tree. L'état restant attendu et vérifié immédiatement après commit est :

```text
 M packages/map_editor/lib/src/features/editor/application/world_map_tool_activation.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_layers_inspector.dart
 M packages/map_editor/test/features/editor/application/world_map_paint_layer_routing_test.dart
 M packages/map_editor/test/features/editor/application/world_map_tool_activation_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_layers_inspector_test.dart
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

Aucun de ces chemins ne doit être stagé ou commité par ce lot.

## Annexe A — Diff intégral des fichiers modifiés

```diff
diff --git a/packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart b/packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
index 8d4e21d27..1a1863d9a 100644
--- a/packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
+++ b/packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
@@ -8,11 +8,13 @@ List<EditorStaticShadowPreviewInstruction>
   required MapData map,
   required double tileWidth,
   required double tileHeight,
+  EditorShadowPreviewViewport? viewport,
 }) {
   if (!tileWidth.isFinite ||
       !tileHeight.isFinite ||
       tileWidth <= 0 ||
       tileHeight <= 0 ||
+      (viewport?.isEmpty ?? false) ||
       map.placedElements.isEmpty) {
     return const <EditorStaticShadowPreviewInstruction>[];
   }
@@ -84,6 +86,15 @@ List<EditorStaticShadowPreviewInstruction>
             ))
         .toList(growable: false);
     final bounds = _boundsFromEditorPreviewPoints(points);
+    if (viewport != null &&
+        !viewport.intersects(
+          left: bounds.left,
+          top: bounds.top,
+          width: bounds.width,
+          height: bounds.height,
+        )) {
+      continue;
+    }

     instructions.add(
       EditorStaticShadowPreviewInstruction(
diff --git a/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart b/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
index 1861eaec6..ff8821b2d 100644
--- a/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
+++ b/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
@@ -108,6 +108,58 @@ final class EditorStaticShadowPreviewInstruction {
       );
 }

+/// Half-open world-pixel bounds used to select editor shadow previews.
+///
+/// The intersection is evaluated against the resolved shadow geometry rather
+/// than the placed element anchor, so projected shadows remain visible at a
+/// viewport edge without relying on an arbitrary halo.
+final class EditorShadowPreviewViewport {
+  const EditorShadowPreviewViewport({
+    required this.left,
+    required this.top,
+    required this.right,
+    required this.bottom,
+  });
+
+  final double left;
+  final double top;
+  final double right;
+  final double bottom;
+
+  bool get isEmpty =>
+      !left.isFinite ||
+      !top.isFinite ||
+      !right.isFinite ||
+      !bottom.isFinite ||
+      right <= left ||
+      bottom <= top;
+
+  bool intersects({
+    required double left,
+    required double top,
+    required double width,
+    required double height,
+  }) {
+    if (isEmpty || width <= 0 || height <= 0) {
+      return false;
+    }
+    final candidateRight = left + width;
+    final candidateBottom = top + height;
+    return candidateRight > this.left &&
+        left < right &&
+        candidateBottom > this.top &&
+        top < bottom;
+  }
+
+  bool intersectsInstruction(EditorStaticShadowPreviewInstruction value) =>
+      intersects(
+        left: value.left,
+        top: value.top,
+        width: value.width,
+        height: value.height,
+      );
+}
+
 List<EditorStaticShadowPreviewInstruction>
     buildEditorStaticShadowPreviewInstructions({
   required ProjectManifest manifest,
@@ -115,11 +167,13 @@ List<EditorStaticShadowPreviewInstruction>
   required double tileWidth,
   required double tileHeight,
   EditorShadowLightPreviewPreset? lightPreviewPreset,
+  EditorShadowPreviewViewport? viewport,
 }) {
   if (!tileWidth.isFinite ||
       !tileHeight.isFinite ||
       tileWidth <= 0 ||
       tileHeight <= 0 ||
+      (viewport?.isEmpty ?? false) ||
       map.placedElements.isEmpty) {
     return const <EditorStaticShadowPreviewInstruction>[];
   }
@@ -212,6 +266,15 @@ List<EditorStaticShadowPreviewInstruction>
           );
     final points = _editorPreviewPointsFromProjection(projectedGeometry);
     final bounds = _boundsFromEditorPreviewPoints(points);
+    if (viewport != null &&
+        !viewport.intersects(
+          left: bounds.left,
+          top: bounds.top,
+          width: bounds.width,
+          height: bounds.height,
+        )) {
+      continue;
+    }

     instructions.add(
       EditorStaticShadowPreviewInstruction(
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
index 8ee69da5b..df94eaa4f 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
@@ -30,8 +30,8 @@ import '../../application/models/map_tool_preview.dart';
 import '../../application/models/path_autotile_set.dart';
 import '../../application/models/narrative_event_map_bridge_models.dart';
 import '../../application/models/narrative_event_spatial_source_creation_models.dart';
-import '../../application/shadow/editor_projected_building_shadow_preview.dart';
 import '../../application/shadow/editor_shadow_light_preview.dart';
+import '../../application/shadow/editor_shadow_preview_projection_index.dart';
 import '../../application/shadow/editor_static_shadow_preview.dart';
 import '../../application/services/environment_generated_placement_hover_resolver.dart';
 import '../../application/services/environment_mask_brush_footprint_resolver.dart';
@@ -469,6 +469,8 @@ class _MapCanvasState extends ConsumerState<MapCanvas>
       MapCanvasInteractionController();
   final SurfacePreviewLayerIndexOwner _surfacePreviewLayerIndexOwner =
       SurfacePreviewLayerIndexOwner();
+  final EditorShadowPreviewProjectionOwner _shadowPreviewProjectionOwner =
+      EditorShadowPreviewProjectionOwner();
   final Set<int> _pressedMapPointers = <int>{};
   final Set<LogicalKeyboardKey> _pressedContextMenuKeys =
       <LogicalKeyboardKey>{};
@@ -634,6 +636,7 @@ class _MapCanvasState extends ConsumerState<MapCanvas>
   @override
   void dispose() {
     _disposeOwnedRepaintResources();
+    _shadowPreviewProjectionOwner.clear();
     _releaseTilesetImagesFuture(_tilesetImagesFuture);
     _tilesetImagesFuture = null;
     _pressedMapPointers.clear();
@@ -1664,6 +1667,8 @@ class _MapCanvasState extends ConsumerState<MapCanvas>
                             painter: MapGridPainter(
                               map: activeMap,
                               surfaceIndexOwner: _surfacePreviewLayerIndexOwner,
+                              shadowProjectionOwner:
+                                  _shadowPreviewProjectionOwner,
                               zoom: state.zoom,
                               offset: state.panOffset,
                               hoveredTile:
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
index a1b089422..f572ec7fc 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
@@ -282,6 +282,9 @@ final class MapGridCullingDebugSnapshot {
     required this.collisionCellVisits,
     required this.terrainCellVisits,
     required this.pathCellVisits,
+    required this.smartTileVisualVisits,
+    required this.staticShadowInstructionVisits,
+    required this.projectedBuildingShadowInstructionVisits,
     required Set<String> placedElementIds,
     required this.placedElementPassVisits,
   }) : placedElementIds = Set<String>.unmodifiable(placedElementIds);
@@ -292,6 +295,9 @@ final class MapGridCullingDebugSnapshot {
   final int collisionCellVisits;
   final int terrainCellVisits;
   final int pathCellVisits;
+  final int smartTileVisualVisits;
+  final int staticShadowInstructionVisits;
+  final int projectedBuildingShadowInstructionVisits;
   final Set<String> placedElementIds;
   final int placedElementPassVisits;
 }
@@ -305,6 +311,9 @@ final class _MapGridCullingDebugCounter {
   int collisionCellVisits = 0;
   int terrainCellVisits = 0;
   int pathCellVisits = 0;
+  int smartTileVisualVisits = 0;
+  int staticShadowInstructionVisits = 0;
+  int projectedBuildingShadowInstructionVisits = 0;
   int placedElementPassVisits = 0;
 }

@@ -357,6 +366,7 @@ class MapGridPainter extends CustomPainter {
   final bool showEntityEditorChrome;
   final bool showEditorOverlays;
   final Map<SurfaceLayer, SurfacePreviewLayerIndex> _surfaceIndexByLayer;
+  final EditorShadowPreviewProjectionOwner _shadowProjectionOwner;

   /// Lot Environment-22 : surcouche semi-transparente des cellules masque actives.
   final EnvironmentAreaMask? environmentMaskOverlay;
@@ -369,6 +379,7 @@ class MapGridPainter extends CustomPainter {
   MapGridPainter({
     required this.map,
     SurfacePreviewLayerIndexOwner? surfaceIndexOwner,
+    EditorShadowPreviewProjectionOwner? shadowProjectionOwner,
     required this.zoom,
     required this.offset,
     this.hoveredTile,
@@ -417,6 +428,8 @@ class MapGridPainter extends CustomPainter {
   })  : _surfaceIndexByLayer =
             (surfaceIndexOwner ?? SurfacePreviewLayerIndexOwner())
                 .indexesFor(map.layers),
+        _shadowProjectionOwner =
+            shadowProjectionOwner ?? EditorShadowPreviewProjectionOwner(),
         _animationClock = animationClock,
         _staticAnimationMs = editorEntityAnimationMs,
         super(repaint: animationClock);
@@ -444,14 +457,32 @@ class MapGridPainter extends CustomPainter {
       tileWidth: tileWidth,
       tileHeight: tileHeight,
     );
-    final visiblePlacedElements = _visiblePlacedElements(visibleBounds);
     final cullingObserver = debugOnCulling;
     final cullingCounter =
         cullingObserver == null ? null : _MapGridCullingDebugCounter();
+    final projectContext = project;
+    final shadowProjection = projectContext == null
+        ? null
+        : _shadowProjectionOwner.projectionFor(
+            manifest: projectContext,
+            map: map,
+            tileWidth: tileWidth,
+            tileHeight: tileHeight,
+            lightPreviewPreset: shadowLightPreviewPreset,
+          );
+    final visiblePlacedElements = shadowProjection?.placedElementsIn(
+          EditorShadowPreviewCellViewport(
+            left: visibleBounds.left,
+            top: visibleBounds.top,
+            right: visibleBounds.right,
+            bottom: visibleBounds.bottom,
+          ),
+        ) ??
+        const <MapPlacedElement>[];

-    // Cell-backed layers and placed-element footprints have bounded geometry
-    // and are safe to cull. Shadows and editor overlays deliberately keep the
-    // full map input below because their visual extents can escape an anchor.
+    // Cell-backed layers and placed-element footprints use cell bounds. Shadow
+    // projections use their cached exact world-pixel geometry because their
+    // visual extents can escape the placed element anchor.

     final layerPaintOrderResult = buildEditorMapLayerPaintOrderResult(map);
     final layerPaintOrder = layerPaintOrderResult.order;
@@ -468,24 +499,24 @@ class MapGridPainter extends CustomPainter {
       project: project,
       placedElements: visiblePlacedElements,
     );
-    final projectContext = project;
-    final projectedBuildingShadowPreviewInstructions = projectContext == null
-        ? const <EditorStaticShadowPreviewInstruction>[]
-        : buildEditorProjectedBuildingShadowPreviewInstructions(
-            manifest: projectContext,
-            map: map,
-            tileWidth: tileWidth,
-            tileHeight: tileHeight,
-          );
-    final staticShadowPreviewInstructions = projectContext == null
-        ? const <EditorStaticShadowPreviewInstruction>[]
-        : buildEditorStaticShadowPreviewInstructions(
-            manifest: projectContext,
-            map: map,
-            tileWidth: tileWidth,
-            tileHeight: tileHeight,
-            lightPreviewPreset: shadowLightPreviewPreset,
-          );
+    final shadowViewport = EditorShadowPreviewViewport(
+      left: visibleBounds.left * tileWidth,
+      top: visibleBounds.top * tileHeight,
+      right: visibleBounds.right * tileWidth,
+      bottom: visibleBounds.bottom * tileHeight,
+    );
+    final projectedBuildingShadowPreviewInstructions =
+        shadowProjection?.projectedBuildingInstructionsIn(shadowViewport) ??
+            const <EditorStaticShadowPreviewInstruction>[];
+    final staticShadowPreviewInstructions =
+        shadowProjection?.staticInstructionsIn(shadowViewport) ??
+            const <EditorStaticShadowPreviewInstruction>[];
+    if (cullingCounter != null) {
+      cullingCounter.projectedBuildingShadowInstructionVisits +=
+          projectedBuildingShadowPreviewInstructions.length;
+      cullingCounter.staticShadowInstructionVisits +=
+          staticShadowPreviewInstructions.length;
+    }

     final borderCatalog = project?.borderCatalog;
     for (final step in compositionPlan.steps) {
@@ -529,6 +560,8 @@ class MapGridPainter extends CustomPainter {
             canvas,
             step.layer! as SmartTileLayer,
             pass: SmartTileVisualPass.background,
+            visibleBounds: visibleBounds,
+            cullingCounter: cullingCounter,
           );
         case MapVisualCompositionStepKind.tileBackgroundLayer:
           _paintTileLayer(
@@ -606,6 +639,8 @@ class MapGridPainter extends CustomPainter {
               canvas,
               smartLayer,
               pass: SmartTileVisualPass.foreground,
+              visibleBounds: visibleBounds,
+              cullingCounter: cullingCounter,
             );
           }
         case MapVisualCompositionStepKind.foregroundEntities:
@@ -716,6 +751,11 @@ class MapGridPainter extends CustomPainter {
           collisionCellVisits: cullingCounter.collisionCellVisits,
           terrainCellVisits: cullingCounter.terrainCellVisits,
           pathCellVisits: cullingCounter.pathCellVisits,
+          smartTileVisualVisits: cullingCounter.smartTileVisualVisits,
+          staticShadowInstructionVisits:
+              cullingCounter.staticShadowInstructionVisits,
+          projectedBuildingShadowInstructionVisits:
+              cullingCounter.projectedBuildingShadowInstructionVisits,
           placedElementIds: {
             for (final instance in visiblePlacedElements) instance.id,
           },
@@ -725,35 +765,6 @@ class MapGridPainter extends CustomPainter {
     }
   }

-  List<MapPlacedElement> _visiblePlacedElements(
-    EditorMapVisibleCellBounds visibleBounds,
-  ) {
-    final projectContext = project;
-    if (projectContext == null || visibleBounds.cellCount == 0) {
-      return const <MapPlacedElement>[];
-    }
-    final elementById = <String, ProjectElementEntry>{
-      for (final entry in projectContext.elements) entry.id: entry,
-    };
-    return <MapPlacedElement>[
-      for (final instance in map.placedElements)
-        if (elementById[instance.elementId] case final element?)
-          if (element.frames.isNotEmpty)
-            if (resolveMapPlacedElementFootprint(
-              instance: instance,
-              element: element,
-            ).destinationSize
-                case final footprint)
-              if (visibleBounds.intersectsCellArea(
-                x: instance.pos.x,
-                y: instance.pos.y,
-                width: footprint.width,
-                height: footprint.height,
-              ))
-                instance,
-    ];
-  }
-
   void _paintNarrativeEventBridgeHighlight(
     Canvas canvas,
     double gridWidth,
@@ -2718,6 +2729,8 @@ class MapGridPainter extends CustomPainter {
     Canvas canvas,
     SmartTileLayer layer, {
     required SmartTileVisualPass pass,
+    required EditorMapVisibleCellBounds visibleBounds,
+    _MapGridCullingDebugCounter? cullingCounter,
   }) {
     final catalog = project?.smartTileCatalog;
     if (catalog == null || catalog.isEmpty) return;
@@ -2727,7 +2740,12 @@ class MapGridPainter extends CustomPainter {
       catalog: catalog,
       pass: pass,
       elapsedMs: effectiveAnimationMs,
+      startX: visibleBounds.left,
+      startY: visibleBounds.top,
+      endX: visibleBounds.right,
+      endY: visibleBounds.bottom,
     );
+    cullingCounter?.smartTileVisualVisits += visuals.length;
     final pixelScaleX = sourceTileWidth > 0 ? tileWidth / sourceTileWidth : 1.0;
     final pixelScaleY =
         sourceTileHeight > 0 ? tileHeight / sourceTileHeight : 1.0;
diff --git a/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart b/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
index 2a7006d7d..76e7ee789 100644
--- a/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
+++ b/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
@@ -38,6 +38,54 @@ void main() {
       _expectPointClose(instruction.polygonPoints[3], x: 101.38, y: 147.36);
     });

+    test('filters exact shadow bounds after the caster leaves the viewport',
+        () {
+      final manifest = _manifest(
+        catalog: _catalog([_preset()]),
+        elements: [_element(projectedBuildingShadow: _config())],
+      );
+      final map = _map(placedElements: [_placed()]);
+      final unfiltered = buildEditorProjectedBuildingShadowPreviewInstructions(
+        manifest: manifest,
+        map: map,
+        tileWidth: 32,
+        tileHeight: 32,
+      ).single;
+      final viewport = EditorShadowPreviewViewport(
+        left: unfiltered.left + 1,
+        top: unfiltered.top + unfiltered.height - 1,
+        right: unfiltered.left + 2,
+        bottom: unfiltered.top + unfiltered.height + 1,
+      );
+
+      expect(viewport.top, greaterThan(160), reason: 'caster bottom edge');
+      expect(
+        buildEditorProjectedBuildingShadowPreviewInstructions(
+          manifest: manifest,
+          map: map,
+          tileWidth: 32,
+          tileHeight: 32,
+          viewport: viewport,
+        ),
+        hasLength(1),
+      );
+      expect(
+        buildEditorProjectedBuildingShadowPreviewInstructions(
+          manifest: manifest,
+          map: map,
+          tileWidth: 32,
+          tileHeight: 32,
+          viewport: EditorShadowPreviewViewport(
+            left: unfiltered.left + unfiltered.width,
+            top: unfiltered.top,
+            right: unfiltered.left + unfiltered.width + 8,
+            bottom: unfiltered.top + unfiltered.height,
+          ),
+        ),
+        isEmpty,
+      );
+    });
+
     test('uses rotated destination dimensions while preserving world direction',
         () {
       final manifest = _manifest(
diff --git a/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart b/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
index f09d662f0..ed3ca249b 100644
--- a/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
+++ b/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
@@ -1,6 +1,7 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/application/shadow/editor_shadow_light_preview.dart';
+import 'package:map_editor/src/application/shadow/editor_shadow_preview_projection_index.dart';
 import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

 void main() {
@@ -25,6 +26,146 @@ void main() {
       );
     });

+    test(
+        'filters by exact projected bounds and keeps an off-viewport caster shadow',
+        () {
+      final map = _map(
+        shadowOverride: MapPlacedElementShadowOverride(
+          mode: ShadowOverrideMode.custom,
+          offsetX: 128,
+        ),
+      );
+      final unfiltered = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(),
+        map: map,
+        tileWidth: 16,
+        tileHeight: 16,
+      ).single;
+      final viewport = EditorShadowPreviewViewport(
+        left: unfiltered.left + unfiltered.width - 1,
+        top: unfiltered.top + 1,
+        right: unfiltered.left + unfiltered.width + 1,
+        bottom: unfiltered.top + 2,
+      );
+
+      expect(viewport.left, greaterThan(48), reason: 'caster right edge');
+      expect(
+        buildEditorStaticShadowPreviewInstructions(
+          manifest: _manifest(),
+          map: map,
+          tileWidth: 16,
+          tileHeight: 16,
+          viewport: viewport,
+        ),
+        hasLength(1),
+      );
+      expect(
+        buildEditorStaticShadowPreviewInstructions(
+          manifest: _manifest(),
+          map: map,
+          tileWidth: 16,
+          tileHeight: 16,
+          viewport: EditorShadowPreviewViewport(
+            left: unfiltered.left + unfiltered.width,
+            top: unfiltered.top,
+            right: unfiltered.left + unfiltered.width + 8,
+            bottom: unfiltered.top + unfiltered.height,
+          ),
+        ),
+        isEmpty,
+        reason: 'touching the exact right edge is not an intersection',
+      );
+    });
+
+    test('returns no instructions for an empty viewport', () {
+      expect(
+        buildEditorStaticShadowPreviewInstructions(
+          manifest: _manifest(),
+          map: _map(),
+          tileWidth: 16,
+          tileHeight: 16,
+          viewport: const EditorShadowPreviewViewport(
+            left: 32,
+            top: 32,
+            right: 32,
+            bottom: 64,
+          ),
+        ),
+        isEmpty,
+      );
+    });
+
+    test('projection owner reuses revisions and indexes visible source order',
+        () {
+      final owner = EditorShadowPreviewProjectionOwner();
+      final map = _map(
+        placedElements: const <MapPlacedElement>[
+          MapPlacedElement(
+            id: 'near',
+            layerId: 'layer',
+            elementId: 'stand',
+            pos: GridPos(x: 1, y: 2),
+          ),
+          MapPlacedElement(
+            id: 'far',
+            layerId: 'layer',
+            elementId: 'stand',
+            pos: GridPos(x: 7, y: 7),
+          ),
+        ],
+      );
+      final manifest = _manifest();
+      final first = owner.projectionFor(
+        manifest: manifest,
+        map: map,
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+      final cached = owner.projectionFor(
+        manifest: manifest,
+        map: map,
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      expect(identical(cached, first), isTrue);
+      expect(first.staticInstructionCount, 2);
+      expect(
+        first
+            .placedElementsIn(
+              const EditorShadowPreviewCellViewport(
+                left: 0,
+                top: 0,
+                right: 4,
+                bottom: 6,
+              ),
+            )
+            .map((element) => element.id),
+        <String>['near'],
+      );
+      expect(
+        first
+            .staticInstructionsIn(
+              const EditorShadowPreviewViewport(
+                left: 0,
+                top: 0,
+                right: 64,
+                bottom: 96,
+              ),
+            )
+            .map((instruction) => instruction.instanceId),
+        <String>['near'],
+      );
+
+      final refreshed = owner.projectionFor(
+        manifest: manifest,
+        map: map.copyWith(name: 'Changed identity'),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+      expect(identical(refreshed, first), isFalse);
+    });
+
     test('uses the rotated destination footprint without rotating world light',
         () {
       final rotated = buildEditorStaticShadowPreviewInstructions(
diff --git a/packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart b/packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart
index 7098ee355..c4e58eb7e 100644
--- a/packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart
+++ b/packages/map_editor/test/ui/world_map/world_map_large_map_performance_test.dart
@@ -386,6 +386,18 @@ void main() {
       committedPosition,
     );
   });
+
+  test('smart tile work stays bounded to the same viewport from 128² to 1024²',
+      () {
+    final small = _paintSmartTileCullingFixture(mapExtent: 128);
+    final large = _paintSmartTileCullingFixture(mapExtent: 1024);
+
+    expect(
+        _boundsTuple(large.visibleBounds), _boundsTuple(small.visibleBounds));
+    expect(large.smartTileVisualVisits, small.smartTileVisualVisits);
+    expect(large.smartTileVisualVisits, large.visibleBounds.cellCount);
+    expect(large.smartTileVisualVisits, lessThan(large.totalMapCellCount));
+  });
 }

 EditorMapVisibleCellBounds _visibleBounds({
@@ -441,6 +453,61 @@ MapGridCullingDebugSnapshot _paintCullingFixture({
   return snapshot!;
 }

+MapGridCullingDebugSnapshot _paintSmartTileCullingFixture({
+  required int mapExtent,
+}) {
+  final cellCount = mapExtent * mapExtent;
+  final layer = SmartTileLayer(
+    id: 'smart-terrain',
+    name: 'Smart terrain',
+    presetId: 'smart-terrain',
+    usage: SmartTileUsage.terrain,
+    materialPalette: const <String>['', 'grass'],
+    materialCells: List<int>.filled(cellCount, 1, growable: false),
+    horizontalEdges:
+        List<int>.filled(mapExtent * (mapExtent + 1), 0, growable: false),
+    verticalEdges:
+        List<int>.filled((mapExtent + 1) * mapExtent, 0, growable: false),
+    corners: List<int>.filled(
+      (mapExtent + 1) * (mapExtent + 1),
+      0,
+      growable: false,
+    ),
+  );
+  final map = MapData(
+    id: 'smart-$mapExtent',
+    name: 'Smart $mapExtent',
+    version: ProjectVersion.v4,
+    size: GridSize(width: mapExtent, height: mapExtent),
+    layers: <MapLayer>[layer],
+  );
+  MapGridCullingDebugSnapshot? snapshot;
+  final recorder = ui.PictureRecorder();
+  final canvas = Canvas(recorder);
+  MapGridPainter(
+    map: map,
+    zoom: 1,
+    offset: Offset.zero,
+    tileWidth: 32,
+    tileHeight: 32,
+    tilesetImagesById: const <String, ui.Image?>{},
+    sourceTileWidth: 32,
+    sourceTileHeight: 32,
+    tilesPerRowById: const <String, int>{},
+    warps: const <MapWarp>[],
+    gameplayZones: const <MapGameplayZone>[],
+    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
+    pathAutotileSetsByPresetId: const {},
+    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
+    project: _smartTileProject,
+    showGrid: false,
+    showEditorOverlays: false,
+    debugOnCulling: (value) => snapshot = value,
+  ).paint(canvas, const Size(96, 96));
+  recorder.endRecording().dispose();
+  return snapshot!;
+}
+
 Future<ui.Image> _solidImage({
   required int width,
   required int height,
@@ -661,6 +728,62 @@ const _project = ProjectManifest(
   surfaceCatalog: ProjectSurfaceCatalog.empty(),
 );

+final _smartTileProject = ProjectManifest(
+  name: 'Smart tile performance',
+  maps: <ProjectMapEntry>[],
+  tilesets: <ProjectTilesetEntry>[],
+  surfaceCatalog: const ProjectSurfaceCatalog.empty(),
+  smartTileCatalog: ProjectSmartTileCatalog(
+    atlases: const <ProjectSmartTileAtlas>[
+      ProjectSmartTileAtlas(
+        id: 'smart-atlas',
+        name: 'Smart atlas',
+        tilesetId: 'tiles',
+        columns: 1,
+        rows: 1,
+      ),
+    ],
+    materials: const <ProjectSmartTileMaterial>[
+      ProjectSmartTileMaterial(
+        id: 'grass',
+        name: 'Grass',
+        connectionGroupId: 'grass',
+      ),
+    ],
+    presets: const <ProjectSmartTilePreset>[
+      ProjectSmartTilePreset(
+        id: 'smart-terrain',
+        name: 'Smart terrain',
+        usage: SmartTileUsage.terrain,
+        topology: SmartTileTopology.cardinal4,
+        defaultMaterialId: 'grass',
+        allowedMaterialIds: <String>['grass'],
+        rules: <SmartTileRule>[
+          SmartTileRule(
+            id: 'ground',
+            candidates: <SmartTileCandidate>[
+              SmartTileCandidate(
+                id: 'ground',
+                parts: <SmartTileVisualPart>[
+                  SmartTileVisualPart(
+                    source: SmartTileVisualSource.frame(
+                      frame: SmartTileFrameRef(
+                        atlasId: 'smart-atlas',
+                        column: 0,
+                        row: 0,
+                      ),
+                    ),
+                  ),
+                ],
+              ),
+            ],
+          ),
+        ],
+      ),
+    ],
+  ),
+);
+
 MapData _largeMap() {
   const size = GridSize(width: 128, height: 128);
   final cells = size.width * size.height;
```

## Annexe B — Contenu complet du plan créé

Chemin : `reports/performance/plans/2026-08-02-pokemap-perf-rm-07b-canvas-visible-projections.md`

````markdown
# PERF-RM-07B — Plan d’implémentation des projections canvas visibles

## Objectif

Rendre le coût du canvas éditeur dépendant du viewport et non de la taille totale de la map, sans modifier le rendu, l’ordre des couches ni les données sérialisées.

## Périmètre

- transmettre les bornes cellulaires visibles déjà calculées par `MapGridPainter` au resolver smart-tile ;
- filtrer les instructions d’ombres statiques et projetées par intersection avec leurs bounds géométriques exactes ;
- conserver le painter standard comme contrôle ;
- couvrir les viewports invalides/hors map, les bords, l’animation, l’ordre des couches et les éléments tournés ;
- documenter le profil 128²→1 024² et la décision Go/No-Go dans l’Evidence Pack du lot.

## Plan TDD

1. Ajouter des tests qui exigent un viewport explicite pour les builders d’ombres et prouvent qu’une ombre intersectante reste visible même si son ancre est hors viewport, tandis qu’une ombre sans intersection est exclue.
2. Ajouter une observation déterministe au snapshot de culling du painter et un test qui compare 128² à 1 024² à viewport constant pour les smart tiles et les ombres.
3. Exécuter les tests ciblés et conserver la preuve rouge avant toute modification de production.
4. Introduire un type de bounds pixel pur Dart partagé par les deux builders d’ombres, puis filtrer après calcul de la géométrie exacte.
5. Passer les bornes visibles aux deux passes smart-tile et les bounds pixel aux deux builders d’ombres.
6. Rerun les tests ciblés, le profil reproductible, les tests de non-régression demandés et `flutter analyze`.
7. Produire `reports/performance/perf_rm_07b_canvas_visible_projections.md`, auditer le diff, puis créer un commit dédié au lot.

## Parité et non-objectifs

- PokeMap MCP : N/A attendu, car le lot ne change aucune sémantique auteur, commande, donnée projet, validation, import/export ou résultat visuel ; il réduit uniquement le travail hors viewport.
- Aucun changement de schéma, JSON, design system, `RepaintBoundary` généralisé ou halo arbitraire.
- `map_core` reste inchangé sauf si les tests révèlent un défaut du resolver borné existant.

## Validation prévue

```bash
cd packages/map_core && dart test test/smart_tiles/smart_tile_layer_visual_resolver_test.dart && dart analyze
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart test/application/shadow/editor_projected_building_shadow_preview_test.dart test/map_grid_painter_test.dart test/ui/world_map/world_map_large_map_performance_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test test/editor_shell_page_smoke_test.dart test/ui/world_map/world_map_rebuild_isolation_test.dart test/map_grid_painter_test.dart test/ui/world_map/world_map_large_map_performance_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test && flutter analyze
```
````

## Annexe C — Contenu complet de l'index créé

Chemin : `packages/map_editor/lib/src/application/shadow/editor_shadow_preview_projection_index.dart`

````dart
import 'package:map_core/map_core.dart';

import 'editor_projected_building_shadow_preview.dart';
import 'editor_shadow_light_preview.dart';
import 'editor_static_shadow_preview.dart';

final class EditorShadowPreviewCellViewport {
  const EditorShadowPreviewCellViewport({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  bool get isEmpty => right <= left || bottom <= top;
}

/// Cached shadow projection for one immutable map/project revision.
///
/// Geometry is resolved once, then exact instruction bounds are indexed in
/// tile-sized buckets. Repaints caused by pan, zoom, overlays, or animation
/// only enumerate buckets intersecting the visible world rectangle.
final class EditorShadowPreviewProjection {
  EditorShadowPreviewProjection._({
    required ProjectManifest manifest,
    required MapData map,
    required List<EditorStaticShadowPreviewInstruction> staticInstructions,
    required List<EditorStaticShadowPreviewInstruction>
        projectedBuildingInstructions,
    required double bucketWidth,
    required double bucketHeight,
  })  : _placedElementIndex = _EditorPlacedElementViewportIndex(
          manifest: manifest,
          map: map,
        ),
        _staticIndex = _EditorShadowPreviewInstructionIndex(
          instructions: staticInstructions,
          bucketWidth: bucketWidth,
          bucketHeight: bucketHeight,
        ),
        _projectedBuildingIndex = _EditorShadowPreviewInstructionIndex(
          instructions: projectedBuildingInstructions,
          bucketWidth: bucketWidth,
          bucketHeight: bucketHeight,
        );

  final _EditorPlacedElementViewportIndex _placedElementIndex;
  final _EditorShadowPreviewInstructionIndex _staticIndex;
  final _EditorShadowPreviewInstructionIndex _projectedBuildingIndex;

  int get staticInstructionCount => _staticIndex.length;

  int get projectedBuildingInstructionCount => _projectedBuildingIndex.length;

  List<MapPlacedElement> placedElementsIn(
    EditorShadowPreviewCellViewport viewport,
  ) =>
      _placedElementIndex.elementsIn(viewport);

  List<EditorStaticShadowPreviewInstruction> staticInstructionsIn(
    EditorShadowPreviewViewport viewport,
  ) =>
      _staticIndex.instructionsIn(viewport);

  List<EditorStaticShadowPreviewInstruction> projectedBuildingInstructionsIn(
    EditorShadowPreviewViewport viewport,
  ) =>
      _projectedBuildingIndex.instructionsIn(viewport);
}

/// Retains the projection index while map and project value identities stay
/// unchanged. PokeMap editor state replaces immutable values on semantic edits,
/// so identity is the narrow invalidation boundary needed here.
final class EditorShadowPreviewProjectionOwner {
  MapData? _map;
  ProjectManifest? _manifest;
  double? _tileWidth;
  double? _tileHeight;
  EditorShadowLightPreviewPreset? _lightPreviewPreset;
  EditorShadowPreviewProjection? _projection;

  EditorShadowPreviewProjection projectionFor({
    required ProjectManifest manifest,
    required MapData map,
    required double tileWidth,
    required double tileHeight,
    EditorShadowLightPreviewPreset? lightPreviewPreset,
  }) {
    final resolvedLightPreviewPreset =
        lightPreviewPreset ?? neutralEditorShadowLightPreviewPreset;
    final cached = _projection;
    if (cached != null &&
        identical(_map, map) &&
        identical(_manifest, manifest) &&
        _tileWidth == tileWidth &&
        _tileHeight == tileHeight &&
        _lightPreviewPreset == resolvedLightPreviewPreset) {
      return cached;
    }

    final next = EditorShadowPreviewProjection._(
      manifest: manifest,
      map: map,
      staticInstructions: buildEditorStaticShadowPreviewInstructions(
        manifest: manifest,
        map: map,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        lightPreviewPreset: resolvedLightPreviewPreset,
      ),
      projectedBuildingInstructions:
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: manifest,
        map: map,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      ),
      bucketWidth: tileWidth,
      bucketHeight: tileHeight,
    );
    _map = map;
    _manifest = manifest;
    _tileWidth = tileWidth;
    _tileHeight = tileHeight;
    _lightPreviewPreset = resolvedLightPreviewPreset;
    _projection = next;
    return next;
  }

  void clear() {
    _map = null;
    _manifest = null;
    _tileWidth = null;
    _tileHeight = null;
    _lightPreviewPreset = null;
    _projection = null;
  }
}

final class _EditorPlacedElementViewportIndex {
  _EditorPlacedElementViewportIndex({
    required ProjectManifest manifest,
    required MapData map,
  })  : _elements = List<MapPlacedElement>.unmodifiable(map.placedElements),
        _elementIndicesByCell = _indexPlacedElements(
          manifest: manifest,
          map: map,
        );

  final List<MapPlacedElement> _elements;
  final Map<(int, int), List<int>> _elementIndicesByCell;

  List<MapPlacedElement> elementsIn(
    EditorShadowPreviewCellViewport viewport,
  ) {
    if (viewport.isEmpty || _elements.isEmpty) {
      return const <MapPlacedElement>[];
    }
    final candidateIndices = <int>{};
    for (var y = viewport.top; y < viewport.bottom; y += 1) {
      for (var x = viewport.left; x < viewport.right; x += 1) {
        final cell = _elementIndicesByCell[(x, y)];
        if (cell != null) {
          candidateIndices.addAll(cell);
        }
      }
    }
    if (candidateIndices.isEmpty) {
      return const <MapPlacedElement>[];
    }
    final orderedIndices = candidateIndices.toList()..sort();
    return List<MapPlacedElement>.unmodifiable(
      orderedIndices.map((index) => _elements[index]),
    );
  }
}

final class _EditorShadowPreviewInstructionIndex {
  _EditorShadowPreviewInstructionIndex({
    required List<EditorStaticShadowPreviewInstruction> instructions,
    required this.bucketWidth,
    required this.bucketHeight,
  })  : assert(bucketWidth.isFinite && bucketWidth > 0),
        assert(bucketHeight.isFinite && bucketHeight > 0),
        _instructions = List<EditorStaticShadowPreviewInstruction>.unmodifiable(
          instructions,
        ),
        _instructionIndicesByBucket = _indexInstructions(
          instructions: instructions,
          bucketWidth: bucketWidth,
          bucketHeight: bucketHeight,
        );

  final double bucketWidth;
  final double bucketHeight;
  final List<EditorStaticShadowPreviewInstruction> _instructions;
  final Map<(int, int), List<int>> _instructionIndicesByBucket;

  int get length => _instructions.length;

  List<EditorStaticShadowPreviewInstruction> instructionsIn(
    EditorShadowPreviewViewport viewport,
  ) {
    if (viewport.isEmpty || _instructions.isEmpty) {
      return const <EditorStaticShadowPreviewInstruction>[];
    }
    final startX = (viewport.left / bucketWidth).floor();
    final endX = (viewport.right / bucketWidth).ceil();
    final startY = (viewport.top / bucketHeight).floor();
    final endY = (viewport.bottom / bucketHeight).ceil();
    final candidateIndices = <int>{};
    for (var y = startY; y < endY; y += 1) {
      for (var x = startX; x < endX; x += 1) {
        final bucket = _instructionIndicesByBucket[(x, y)];
        if (bucket != null) {
          candidateIndices.addAll(bucket);
        }
      }
    }
    if (candidateIndices.isEmpty) {
      return const <EditorStaticShadowPreviewInstruction>[];
    }
    final orderedIndices = candidateIndices.toList()..sort();
    return List<EditorStaticShadowPreviewInstruction>.unmodifiable(
      orderedIndices
          .map((index) => _instructions[index])
          .where(viewport.intersectsInstruction),
    );
  }
}

Map<(int, int), List<int>> _indexInstructions({
  required List<EditorStaticShadowPreviewInstruction> instructions,
  required double bucketWidth,
  required double bucketHeight,
}) {
  final result = <(int, int), List<int>>{};
  for (var index = 0; index < instructions.length; index += 1) {
    final instruction = instructions[index];
    final startX = (instruction.left / bucketWidth).floor();
    final endX = ((instruction.left + instruction.width) / bucketWidth).ceil();
    final startY = (instruction.top / bucketHeight).floor();
    final endY = ((instruction.top + instruction.height) / bucketHeight).ceil();
    for (var y = startY; y < endY; y += 1) {
      for (var x = startX; x < endX; x += 1) {
        result.putIfAbsent((x, y), () => <int>[]).add(index);
      }
    }
  }
  return result;
}

Map<(int, int), List<int>> _indexPlacedElements({
  required ProjectManifest manifest,
  required MapData map,
}) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final result = <(int, int), List<int>>{};
  for (var index = 0; index < map.placedElements.length; index += 1) {
    final instance = map.placedElements[index];
    final element = elementById[instance.elementId];
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    final footprint = resolveMapPlacedElementFootprint(
      instance: instance,
      element: element,
    ).destinationSize;
    for (var y = instance.pos.y;
        y < instance.pos.y + footprint.height;
        y += 1) {
      for (var x = instance.pos.x;
          x < instance.pos.x + footprint.width;
          x += 1) {
        result.putIfAbsent((x, y), () => <int>[]).add(index);
      }
    }
  }
  return result;
}
````

## Annexe D — Contenu complet du benchmark créé

Chemin : `packages/map_editor/integration_test/editor_canvas_projection_journey_test.dart`

````dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_shadow_preview_projection_index.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

const _requestedOutputPath = String.fromEnvironment('POKEMAP_PERF_OUTPUT');
const _target = 'integration_test/editor_canvas_projection_journey_test.dart';
const _viewportSize = ui.Size(512, 512);
const _warmups = 8;
const _samples = 90;
const _extents = <int>[128, 256, 512, 1024];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'profiles visible standard smart shadow and combined canvas projections',
    (tester) async {
      final tileImage = await _solidTileImage();
      addTearDown(tileImage.dispose);
      final results = <Map<String, Object?>>[];

      for (final mode in _CanvasProfileMode.values) {
        for (final extent in _extents) {
          final fixture = _CanvasProfileFixture.create(
            mode: mode,
            extent: extent,
          );
          results.add(
            _measurePainter(
              fixture: fixture,
              tileImage: tileImage,
            ),
          );
          await tester.pump();
        }
      }

      Map<String, Object?> resultFor(_CanvasProfileMode mode, int extent) =>
          results.singleWhere(
            (result) =>
                result['mode'] == mode.name && result['extent'] == extent,
          );

      final standard1024 = resultFor(_CanvasProfileMode.standard, 1024);
      final combined128 = resultFor(_CanvasProfileMode.combined, 128);
      final combined1024 = resultFor(_CanvasProfileMode.combined, 1024);
      final standard1024P95 = standard1024['p95Us']! as int;
      final combined128P95 = combined128['p95Us']! as int;
      final combined1024P95 = combined1024['p95Us']! as int;
      final combinedScaleRatio =
          combined1024P95 / (combined128P95 == 0 ? 1 : combined128P95);

      binding.reportData = <String, dynamic>{
        'schemaVersion': 2,
        'generatorVersion': 1,
        'benchmark': 'editor_canvas_visible_projections',
        'target': _target,
        'requestedOutputPath': _requestedOutputPath,
        'executionMode': const bool.fromEnvironment('dart.vm.profile')
            ? 'flutter-profile'
            : 'flutter-debug',
        'fixture': 'synthetic-visible-projections-128-to-1024',
        'warmups': _warmups,
        'sampleCountPerModeAndExtent': _samples,
        'viewport': <String, int>{
          'widthPx': _viewportSize.width.toInt(),
          'heightPx': _viewportSize.height.toInt(),
          'tileWidthPx': 32,
          'tileHeightPx': 32,
        },
        'measurementScope': <String, Object?>{
          'uiThreadCanvasRecord': true,
          'pictureRasterization': false,
          'shadowProjectionWarmupExcluded': true,
          'constantViewport': true,
        },
        'results': results,
        'summary': <String, Object?>{
          'standard1024P95Us': standard1024P95,
          'combined128P95Us': combined128P95,
          'combined1024P95Us': combined1024P95,
          'combined1024To128P95Ratio': combinedScaleRatio,
          'rssBytesAfterRun': ProcessInfo.currentRss,
        },
        'performanceGates': <String, Object?>{
          'combined1024P95BudgetUs': 8000,
          'combined1024To128P95RatioBudget': 1.5,
          'standard1024P95ObservationCeilingUs': 4000,
          'combined1024P95Pass': combined1024P95 < 8000,
          'combinedScaleRatioPass': combinedScaleRatio <= 1.5,
          'standardControlPass': standard1024P95 < 4000,
        },
      };

      expect(combined1024P95, lessThan(8000));
      expect(combinedScaleRatio, lessThanOrEqualTo(1.5));
      expect(standard1024P95, lessThan(4000));
      expect(tester.takeException(), isNull);
    },
  );
}

Map<String, Object?> _measurePainter({
  required _CanvasProfileFixture fixture,
  required ui.Image tileImage,
}) {
  final projectionOwner = EditorShadowPreviewProjectionOwner();
  final painter = _painter(
    fixture: fixture,
    tileImage: tileImage,
    projectionOwner: projectionOwner,
  );
  for (var index = 0; index < _warmups; index += 1) {
    _recordPaint(painter);
  }

  final samplesUs = <int>[];
  for (var index = 0; index < _samples; index += 1) {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final stopwatch = Stopwatch()..start();
    painter.paint(canvas, _viewportSize);
    stopwatch.stop();
    samplesUs.add(stopwatch.elapsedMicroseconds);
    recorder.endRecording().dispose();
  }

  MapGridCullingDebugSnapshot? debugSnapshot;
  _recordPaint(
    _painter(
      fixture: fixture,
      tileImage: tileImage,
      projectionOwner: projectionOwner,
      debugOnCulling: (snapshot) => debugSnapshot = snapshot,
    ),
  );
  final sorted = List<int>.of(samplesUs)..sort();
  final snapshot = debugSnapshot!;
  return <String, Object?>{
    'mode': fixture.mode.name,
    'extent': fixture.extent,
    'mapCellCount': fixture.extent * fixture.extent,
    'placedElementCount': fixture.map.placedElements.length,
    'samplesUs': samplesUs,
    'p50Us': _percentile(sorted, 0.50),
    'p95Us': _percentile(sorted, 0.95),
    'p99Us': _percentile(sorted, 0.99),
    'maxUs': sorted.last,
    'visibleCellCount': snapshot.visibleBounds.cellCount,
    'tileCellVisits': snapshot.tileCellVisits,
    'smartTileVisualVisits': snapshot.smartTileVisualVisits,
    'staticShadowInstructionVisits': snapshot.staticShadowInstructionVisits,
    'projectedBuildingShadowInstructionVisits':
        snapshot.projectedBuildingShadowInstructionVisits,
    'visiblePlacedElementCount': snapshot.placedElementIds.length,
    'rssBytesAfterFixture': ProcessInfo.currentRss,
  };
}

MapGridPainter _painter({
  required _CanvasProfileFixture fixture,
  required ui.Image tileImage,
  required EditorShadowPreviewProjectionOwner projectionOwner,
  MapGridCullingDebugObserver? debugOnCulling,
}) {
  return MapGridPainter(
    map: fixture.map,
    shadowProjectionOwner: projectionOwner,
    zoom: 1,
    offset: ui.Offset.zero,
    activeLayerId: 'base',
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: <String, ui.Image?>{'tiles': tileImage},
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesPerRowById: const <String, int>{'tiles': 1},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const {},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    project: _profileProject,
    editorEntityAnimationMs: 220,
    showGrid: false,
    showEntityEditorChrome: false,
    showEditorOverlays: false,
    debugOnCulling: debugOnCulling,
  );
}

void _recordPaint(MapGridPainter painter) {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), _viewportSize);
  recorder.endRecording().dispose();
}

int _percentile(List<int> sorted, double percentile) {
  final index = (percentile * sorted.length).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)];
}

Future<ui.Image> _solidTileImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 32),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(32, 32);
  } finally {
    picture.dispose();
  }
}

enum _CanvasProfileMode {
  standard,
  smart,
  shadows,
  combined;

  bool get includesStandard =>
      this == _CanvasProfileMode.standard ||
      this == _CanvasProfileMode.combined;

  bool get includesSmart =>
      this == _CanvasProfileMode.smart || this == _CanvasProfileMode.combined;

  bool get includesShadows =>
      this == _CanvasProfileMode.shadows || this == _CanvasProfileMode.combined;
}

final class _CanvasProfileFixture {
  const _CanvasProfileFixture({
    required this.mode,
    required this.extent,
    required this.map,
  });

  final _CanvasProfileMode mode;
  final int extent;
  final MapData map;

  factory _CanvasProfileFixture.create({
    required _CanvasProfileMode mode,
    required int extent,
  }) {
    final cellCount = extent * extent;
    final layers = <MapLayer>[];
    if (mode.includesStandard || mode.includesShadows) {
      layers.add(
        TileLayer(
          id: 'base',
          name: 'Base',
          tilesetId: 'tiles',
          tiles: List<int>.filled(
            cellCount,
            mode.includesStandard ? 1 : 0,
            growable: false,
          ),
        ),
      );
    }
    if (mode.includesSmart) {
      layers.add(
        SmartTileLayer(
          id: 'smart',
          name: 'Smart',
          presetId: 'smart-terrain',
          usage: SmartTileUsage.terrain,
          materialPalette: const <String>['', 'grass'],
          materialCells: List<int>.filled(cellCount, 1, growable: false),
          horizontalEdges:
              List<int>.filled(extent * (extent + 1), 0, growable: false),
          verticalEdges:
              List<int>.filled((extent + 1) * extent, 0, growable: false),
          corners: List<int>.filled(
            (extent + 1) * (extent + 1),
            0,
            growable: false,
          ),
        ),
      );
    }

    final placedElements = <MapPlacedElement>[];
    if (mode.includesShadows) {
      placedElements.add(
        const MapPlacedElement(
          id: 'visible-projected-building',
          layerId: 'base',
          elementId: 'building-caster',
          pos: GridPos(x: 8, y: 8),
          quarterTurns: 1,
        ),
      );
      var index = 0;
      for (var y = 4; y < extent; y += 16) {
        for (var x = 4; x < extent; x += 16) {
          placedElements.add(
            MapPlacedElement(
              id: 'placed-$index',
              layerId: 'base',
              elementId: index.isEven ? 'static-caster' : 'building-caster',
              pos: GridPos(x: x, y: y),
              quarterTurns: index % 4,
            ),
          );
          index += 1;
        }
      }
    }

    return _CanvasProfileFixture(
      mode: mode,
      extent: extent,
      map: MapData(
        id: '${mode.name}-$extent',
        name: '${mode.name} $extent',
        version: ProjectVersion.v4,
        size: GridSize(width: extent, height: extent),
        layers: layers,
        placedElements: placedElements,
      ),
    );
  }
}

final _profileProject = ProjectManifest(
  name: 'Canvas projection profile',
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[],
  surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'smart-atlas',
        name: 'Smart atlas',
        tilesetId: 'tiles',
        columns: 1,
        rows: 1,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'smart-terrain',
        name: 'Smart terrain',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.cardinal4,
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'ground',
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'ground',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'smart-atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  shadowCatalog: ProjectShadowCatalog(
    profiles: <ProjectShadowProfile>[
      ProjectShadowProfile(
        id: 'static-shadow',
        name: 'Static shadow',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
      ),
    ],
  ),
  projectedBuildingShadowCatalog: ProjectBuildingShadowPresetCatalog(
    presets: <ProjectBuildingShadowPreset>[
      ProjectBuildingShadowPreset(
        id: 'building-shadow',
        name: 'Building shadow',
        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0.32,
          nearWidthRatio: 0.9,
          farWidthRatio: 0.72,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: 0.3,
          colorHexRgb: '606060',
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
      ),
    ],
  ),
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'static-caster',
      name: 'Static caster',
      tilesetId: 'tiles',
      categoryId: 'profile',
      frames: <TilesetVisualFrame>[
        const TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
        ),
      ],
      shadow: ProjectElementShadowConfig(
        castsShadow: true,
        shadowProfileId: 'static-shadow',
      ),
    ),
    ProjectElementEntry(
      id: 'building-caster',
      name: 'Building caster',
      tilesetId: 'tiles',
      categoryId: 'profile',
      frames: <TilesetVisualFrame>[
        const TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 4),
        ),
      ],
      projectedBuildingShadow: ProjectElementProjectedBuildingShadowConfig(
        enabled: true,
        presetId: 'building-shadow',
        anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
        localOffset: ProjectedShadowOffset(x: 0, y: 0),
      ),
    ),
  ],
);
````
