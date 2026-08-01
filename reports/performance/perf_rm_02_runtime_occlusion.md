# Evidence Pack — PERF-RM-02 — Occlusion runtime immutable et culling caméra

Date : 2026-08-01  
Phase : 1 — Urgences P0  
Finding : `PERF-RT-01`  
Verdict proposé : **PARTIAL — correctif structurel et goldens verts, gate profil Selbrume non mesuré**

## Résumé exécutif

La géométrie d’occlusion statique est maintenant enregistrée une seule fois dans un
`ui.Picture` possédé par le composant. Le steady-state rejoue ce draw plan sans
rééchantillonner le masque pixel. Les patches hors `camera.visibleWorldRect` sont cullés
avec halo ; la position traduite courante est prise en compte. Le lifecycle dispose le
picture une seule fois et ne dispose jamais le tileset partagé.

La création du display list est également exception-safe : un enregistrement invalide est
terminé puis disposé. Le compteur de resampling reflète désormais les lectures réellement
effectuées pendant la préparation et reste stable au fil des renders.

Les 23 tests renderer/composant/golden ciblés, le golden battle et la suite runtime complète
sont verts. Le statut reste `PARTIAL` car les trois profils
`selbrume.healing-service`, le p95 frame/raster et la comparaison mémoire RM00 n’existent
pas dans cet arbre.

## Scope et non-objectifs

- Représentation immutable locale au composant ; aucun cache global.
- Pas de réécriture du moteur Flame ni de règle gameplay.
- Ownership du `ui.Picture` explicite ; tileset partagé non possédé.
- Le changement de `PlayableMapGame` se limite au provider du viewport caméra.
- Rendu, ordre de profondeur et diagnostic historique des runs préservés.

## Audit initial

Le composant recalculait les runs et rééchantillonnait le masque à chaque frame, même hors
viewport. L’audit mesurait un build runtime p50/p95 de 97,889/126,005 ms et 150/155 frames
au-dessus de 33,3 ms, mais la baseline RM00 reproductible n’a pas été matérialisée dans le
repo. La documentation Flame n’a pas fourni de résultat exploitable ; l’implémentation est
donc restée alignée sur Flame 1.37.0 et les patterns existants.

## État Git initial

HEAD : `7f35d44d9f777d25046c6b94d8974a2fdd850a78`

```text
?? reports/performance/pokemap_full_performance_audit.md
?? reports/performance/pokemap_performance_remediation_roadmap.md
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

## Inventaire et zones modifiées

- `packages/map_runtime/lib/src/presentation/flame/quarter_turn_pixel_renderer.dart`
  - `QuarterTurnPixelDrawPlan.record`, replay, métrique mémoire et dispose idempotent ;
  - distinction entre draw GPU et nombre de destination runs diagnostiques ;
  - cleanup du `ui.Picture` de rebut si la validation lève une exception.
- `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`
  - préparation unique du draw plan ;
  - culling viewport + halo, compteurs réels de préparation/draw/cull/resampling ;
  - lifecycle terminal après `onRemove`.
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - injection de `() => camera.visibleWorldRect`.
- `packages/map_runtime/test/quarter_turn_pixel_renderer_test.dart`
  - replay pixel-identique, ownership/dispose et distinction segment/draw en resampling.
- `packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart`
  - préparation unique, double render, culling/halo/translation et disposal.
- `reports/performance/plans/2026-08-01-pokemap-perf-rm-02-runtime-occlusion.md`
  (créé) : plan TDD du lot.
- `examples/playable_runtime_host/lib/main.dart`
  - teardown récursif explicite du jeu lors d’un reload, reset ou retrait du host.

## Implémentation et décisions

`QuarterTurnPixelDrawPlan` capture la séquence exacte de sampling dans un display list.
La préparation et le diagnostic `includedDestinationRunCount` proviennent du même passage,
sans seconde construction de runs. Le premier RED révélait que le diagnostic golden
historique attendait 48 runs alors qu’un `ui.Picture` représente un draw GPU ; les deux
concepts ont été séparés sans restaurer le double sampling.

Le culling utilise le rect absolu calculé depuis la position actuelle et l’inflate d’un
pixel monde pour conserver les bords de rotation/scale.

Une passe de critique a identifié le recorder non fermé sur erreur et un compteur de
sampling constant. Les deux défauts ont reçu un RED dédié, puis un GREEN couvrant le
picture de rebut disposé et un compteur strictement positif, stable après plusieurs draws.

## Preuves TDD et commandes

RED observés : le test golden voyait `debugDrawRunCount == 1` au lieu de 48 après
l’introduction du picture ; un resampling q1 rapportait 2 segments au lieu d’un car il
confondait draws source et segments de masque. Les correctifs restaurent le diagnostic sans
dupliquer le sampling.

```text
cd packages/map_runtime
flutter test test/quarter_turn_pixel_renderer_test.dart test/placed_element_occlusion_patch_component_test.dart test/building_runtime_occlusion_golden_slice_test.dart
Résultat final : +23, All tests passed.
```

Les tests couvrent préparation unique, plusieurs renders, masque/rotation par les suites
existantes, culling hors viewport, halo, translation, dispose idempotent et maintien du
tileset partagé.

## Validation indépendante et build

La validation indépendante a exécuté le premier ensemble runtime de 120 tests, puis 48
tests post-corrections. La contre-validation finale a rejoué les 6 tests du renderer et le
test lifecycle RM01 associé au teardown : 7 succès, aucun diagnostic analyzer. La passe
racine focalisée renderer/composant/golden produit `+23`, puis la matrice Phase 1 runtime
`+72`. La suite runtime complète finale produit `+2315 ~1`, sans échec.

Le host appelle désormais `game.dispose()` au reload, reset et teardown ; son golden slice,
son analyse et son build macOS debug sont verts. Le build éditeur macOS debug est également
vert. La critique finale confirme la fermeture de ses findings recorder, compteur réel,
segments non-purs et teardown récursif. Le MCP final passe 23/23 tests en série.

## Verdict des passes

- Audit / Architecture : **GO structurel** sur un draw plan local et owned.
- Implémentation : **GREEN fonctionnel**.
- Tests : **PASS** — `+23` focalisés, `+72` Phase 1, `+2315 ~1` complets.
- Build / Validation : **PASS** — analyzers, goldens et deux builds macOS verts.
- Critique finale : **PASS fonctionnel / PARTIAL roadmap**.

## Limites, auto-critique et risques

- Un `ui.Picture` est un display list, pas une preuve de réduction mémoire en production.
- Aucun profil Selbrume avant/après comparable n’a été exécuté.
- Les gates p95 ≤20 ms, <1 % de frames >33,3 ms et raster ≤+20 % restent non évalués.
- La correctness du culling est couverte par tests/goldens, mais pas par une capture appareil.

Auto-critique : le hotspot algorithmique par-frame est retiré et l’ownership est explicite,
mais les critères Go de performance runtime sont volontairement laissés ouverts. La
prochaine étape est RM00 puis trois profils non intrusifs ; ne pas optimiser davantage sans
ces traces.

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
diff --git a/examples/playable_runtime_host/lib/main.dart b/examples/playable_runtime_host/lib/main.dart
index 59b92e017..46dae4e25 100644
--- a/examples/playable_runtime_host/lib/main.dart
+++ b/examples/playable_runtime_host/lib/main.dart
@@ -115,9 +115,16 @@ class _ProjectLoaderPageState extends State<_ProjectLoaderPage> {
     _gamepadPresenceTimer?.cancel();
     _runtimeGamepadSubscription?.cancel();
     unawaited(_disposeInteractiveBridge());
+    _disposeCurrentGame();
     super.dispose();
   }
 
+  void _disposeCurrentGame() {
+    final game = _game;
+    _game = null;
+    game?.dispose();
+  }
+
   bool get _supportsTouchControls =>
       !kIsWeb &&
       (defaultTargetPlatform == TargetPlatform.iOS ||
@@ -570,10 +577,10 @@ class _ProjectLoaderPageState extends State<_ProjectLoaderPage> {
     );
     await _disposeInteractiveBridge();
     if (!mounted) return;
+    _disposeCurrentGame();
     setState(() {
       _loading = true;
       _error = null;
-      _game = null;
     });
 
     try {
@@ -726,9 +733,9 @@ class _ProjectLoaderPageState extends State<_ProjectLoaderPage> {
   Future<void> _reset() async {
     await _disposeInteractiveBridge();
     if (!mounted) return;
+    _disposeCurrentGame();
     setState(() {
       _stopRuntimeInfoTicker();
-      _game = null;
       _error = null;
       _saveLoadStatus = null;
       _saveLoadError = null;
diff --git a/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart b/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
index 78457377e..f1d58b4cc 100644
--- a/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
@@ -10,33 +10,85 @@ class PlacedElementOcclusionPatchComponent extends PositionComponent {
   PlacedElementOcclusionPatchComponent({
     required this.instruction,
     required this.tilesetImage,
+    this.visibleWorldRectProvider,
   })  : _currentDepthSortY = instruction.depthSortY,
         super(
           anchor: Anchor.topLeft,
           position: Vector2(instruction.worldLeft, instruction.worldTop),
           size: Vector2(instruction.visualWidth, instruction.visualHeight),
         ) {
-    _pixelTransform = _resolvePixelTransform(instruction);
-    _maskPixels = _decodeMask(instruction.occlusionMask);
-    _drawRuns = _buildDrawRuns(
-      instruction,
-      pixelTransform: _pixelTransform,
-      pixels: _maskPixels,
-    );
+    final maskPixels = _decodeMask(instruction.occlusionMask);
+    final mask = instruction.occlusionMask;
+    final canPrepare = instruction.opacity > 0 &&
+        instruction.visualWidth > 0 &&
+        instruction.visualHeight > 0 &&
+        mask.widthPx == instruction.sourceWidthPx &&
+        mask.heightPx == instruction.sourceHeightPx;
+    try {
+      if (!canPrepare) {
+        throw ArgumentError('Occlusion patch cannot produce a render plan.');
+      }
+      final paint = Paint()
+        ..isAntiAlias = false
+        ..filterQuality = FilterQuality.none;
+      if (instruction.opacity < 1) {
+        paint.color = Color.fromRGBO(255, 255, 255, instruction.opacity);
+      }
+      final sourceSize = GridSize(
+        width: instruction.sourceWidthPx,
+        height: instruction.sourceHeightPx,
+      );
+      final destinationSize = GridSize(
+        width: instruction.destinationWidthPx,
+        height: instruction.destinationHeightPx,
+      );
+      final sourceWidth = sourceSize.width;
+      _renderPlan = QuarterTurnPixelDrawPlan.record(
+        image: tilesetImage,
+        sourceRect: Rect.fromLTWH(
+          instruction.sourceLeftPx.toDouble(),
+          instruction.sourceTopPx.toDouble(),
+          sourceSize.width.toDouble(),
+          sourceSize.height.toDouble(),
+        ),
+        destinationRect: Rect.fromLTWH(
+          0,
+          0,
+          instruction.visualWidth,
+          instruction.visualHeight,
+        ),
+        sourcePixelSize: sourceSize,
+        destinationPixelSize: destinationSize,
+        quarterTurns: instruction.quarterTurns,
+        paint: paint,
+        includeSourcePixel: (source) {
+          final index = source.y * sourceWidth + source.x;
+          return index >= 0 && index < maskPixels.length && maskPixels[index];
+        },
+      );
+      _renderPlanPreparationCount = 1;
+    } on ArgumentError {
+      _renderPlan = null;
+    }
+    _drawRunCount = _renderPlan?.result.includedDestinationRunCount ?? 0;
     priority = instruction.flamePriority;
   }
 
   final StaticPlacedElementOcclusionPatchInstruction instruction;
   final RuntimeTilesetImage tilesetImage;
-  late final QuarterTurnPixelTransform? _pixelTransform;
-  late final List<bool> _maskPixels;
-  late final List<_OcclusionPixelRun> _drawRuns;
+  final Rect Function()? visibleWorldRectProvider;
+  QuarterTurnPixelDrawPlan? _renderPlan;
+  late final int _drawRunCount;
   double _currentDepthSortY;
   int _lastQuarterTurnDrawRunCount = 0;
   int _lastIncludedDestinationPixelCount = 0;
+  int _renderPlanPreparationCount = 0;
+  int _renderPlanDrawCount = 0;
+  int _culledRenderCount = 0;
+  bool _didRemove = false;
 
   @visibleForTesting
-  int get debugDrawRunCount => _drawRuns.length;
+  int get debugDrawRunCount => _drawRunCount;
 
   @visibleForTesting
   int get debugQuarterTurnDrawRunCount => _lastQuarterTurnDrawRunCount;
@@ -45,6 +97,26 @@ class PlacedElementOcclusionPatchComponent extends PositionComponent {
   int get debugIncludedDestinationPixelCount =>
       _lastIncludedDestinationPixelCount;
 
+  @visibleForTesting
+  int get debugRenderPlanPreparationCount => _renderPlanPreparationCount;
+
+  @visibleForTesting
+  int get debugRenderPlanDrawCount => _renderPlanDrawCount;
+
+  @visibleForTesting
+  int get debugCulledRenderCount => _culledRenderCount;
+
+  @visibleForTesting
+  int get debugQuarterTurnResampleCount =>
+      _renderPlan?.sourcePixelSampleCount ?? 0;
+
+  @visibleForTesting
+  bool get debugRenderPlanDisposed => _renderPlan?.isDisposed ?? true;
+
+  @visibleForTesting
+  int get debugRenderPlanApproximateBytesUsed =>
+      _renderPlan?.approximateBytesUsed ?? 0;
+
   void translateByMapOriginDelta(Vector2 delta) {
     position = position + delta;
     _currentDepthSortY += delta.y;
@@ -55,108 +127,35 @@ class PlacedElementOcclusionPatchComponent extends PositionComponent {
   void render(Canvas canvas) {
     _lastQuarterTurnDrawRunCount = 0;
     _lastIncludedDestinationPixelCount = 0;
-    final transform = _pixelTransform;
-    if (instruction.opacity <= 0 || _drawRuns.isEmpty || transform == null) {
+    final plan = _renderPlan;
+    if (instruction.opacity <= 0 ||
+        _drawRunCount == 0 ||
+        plan == null ||
+        plan.isDisposed) {
       return;
     }
-    final paint = Paint()
-      ..isAntiAlias = false
-      ..filterQuality = FilterQuality.none;
-    if (instruction.opacity < 1) {
-      paint.color = Color.fromRGBO(255, 255, 255, instruction.opacity);
+    final visibleWorldRect = visibleWorldRectProvider?.call();
+    if (visibleWorldRect != null &&
+        !toAbsoluteRect().inflate(1).overlaps(visibleWorldRect)) {
+      _culledRenderCount += 1;
+      return;
     }
 
-    final sourceWidth = transform.sourcePixelSize.width;
-    final result = drawQuarterTurnPixels(
-      canvas,
-      image: tilesetImage,
-      sourceRect: Rect.fromLTWH(
-        instruction.sourceLeftPx.toDouble(),
-        instruction.sourceTopPx.toDouble(),
-        transform.sourcePixelSize.width.toDouble(),
-        transform.sourcePixelSize.height.toDouble(),
-      ),
-      destinationRect: Rect.fromLTWH(
-        0,
-        0,
-        instruction.visualWidth,
-        instruction.visualHeight,
-      ),
-      sourcePixelSize: transform.sourcePixelSize,
-      destinationPixelSize: transform.destinationPixelSize,
-      quarterTurns: transform.quarterTurns,
-      paint: paint,
-      includeSourcePixel: (source) {
-        final index = source.y * sourceWidth + source.x;
-        return index >= 0 && index < _maskPixels.length && _maskPixels[index];
-      },
-    );
+    plan.draw(canvas);
+    _renderPlanDrawCount += 1;
+    final result = plan.result;
     _lastQuarterTurnDrawRunCount = result.drawRunCount;
     _lastIncludedDestinationPixelCount = result.includedDestinationPixelCount;
   }
 
-  static List<_OcclusionPixelRun> _buildDrawRuns(
-    StaticPlacedElementOcclusionPatchInstruction instruction, {
-    required QuarterTurnPixelTransform? pixelTransform,
-    required List<bool> pixels,
-  }) {
-    final mask = instruction.occlusionMask;
-    if (pixelTransform == null ||
-        mask.widthPx <= 0 ||
-        mask.heightPx <= 0 ||
-        instruction.visualWidth <= 0 ||
-        instruction.visualHeight <= 0 ||
-        mask.widthPx != pixelTransform.sourcePixelSize.width ||
-        mask.heightPx != pixelTransform.sourcePixelSize.height) {
-      return const [];
-    }
-
-    if (pixels.isEmpty) {
-      return const [];
-    }
-
-    final destinationSize = pixelTransform.destinationPixelSize;
-    final sourceWidth = pixelTransform.sourcePixelSize.width;
-    final runs = <_OcclusionPixelRun>[];
-    for (var y = 0; y < destinationSize.height; y++) {
-      int? runStart;
-      for (var x = 0; x <= destinationSize.width; x++) {
-        var isSolid = false;
-        if (x < destinationSize.width) {
-          final source = pixelTransform.destinationPixelToSourcePixel(
-            GridPos(x: x, y: y),
-          );
-          isSolid = pixels[source.y * sourceWidth + source.x];
-        }
-        if (isSolid && runStart == null) {
-          runStart = x;
-        } else if (!isSolid && runStart != null) {
-          runs.add(_OcclusionPixelRun(x: runStart, y: y, width: x - runStart));
-          runStart = null;
-        }
-      }
-    }
-    return List<_OcclusionPixelRun>.unmodifiable(runs);
-  }
-
-  static QuarterTurnPixelTransform? _resolvePixelTransform(
-    StaticPlacedElementOcclusionPatchInstruction instruction,
-  ) {
-    try {
-      return QuarterTurnPixelTransform(
-        sourcePixelSize: GridSize(
-          width: instruction.sourceWidthPx,
-          height: instruction.sourceHeightPx,
-        ),
-        destinationPixelSize: GridSize(
-          width: instruction.destinationWidthPx,
-          height: instruction.destinationHeightPx,
-        ),
-        quarterTurns: instruction.quarterTurns,
-      );
-    } on ArgumentError {
-      return null;
-    }
+  /// A removed patch is terminal; Flame must construct a new component if the
+  /// same instruction is mounted again.
+  @override
+  void onRemove() {
+    if (_didRemove) return;
+    _didRemove = true;
+    _renderPlan?.dispose();
+    super.onRemove();
   }
 
   static List<bool> _decodeMask(ElementCollisionPixelMask mask) {
@@ -173,16 +172,3 @@ class PlacedElementOcclusionPatchComponent extends PositionComponent {
     }
   }
 }
-
-@immutable
-final class _OcclusionPixelRun {
-  const _OcclusionPixelRun({
-    required this.x,
-    required this.y,
-    required this.width,
-  });
-
-  final int x;
-  final int y;
-  final int width;
-}
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index 54a689f1b..e8452098b 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -226,6 +226,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     @visibleForTesting this.afterNarrativeAuthorityPreparation,
     @visibleForTesting this.beforeBattleHandoffPreparation,
     @visibleForTesting this.beforeLoadCommitCompletion,
+    @visibleForTesting this.afterInitialTilesetImagesLoaded,
     GameCompletionRequestEmitter? gameCompletionEmitter,
     this.defeatRecoveryCheckpointEmitter,
     @visibleForTesting this.defeatRecoveryCapsLoader,
@@ -365,6 +366,9 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     _cinematicRuntimeController = CinematicRuntimePlaybackController(
       sink: _cinematicRuntimeSink,
     );
+    _tilesetImageCache = RuntimeTilesetImageSingleFlightCache(
+      loader: _runtimeTilesetImageLoader,
+    );
   }
 
   final String projectFilePath;
@@ -391,6 +395,8 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   @visibleForTesting
   final Future<void> Function()? beforeLoadCommitCompletion;
   @visibleForTesting
+  final Future<void> Function()? afterInitialTilesetImagesLoaded;
+  @visibleForTesting
   final RuntimePostBattleOverlayMounter? postBattleOverlayMounter;
   @visibleForTesting
   final VoidCallback? beforePostBattleStateCommit;
@@ -479,6 +485,9 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   final RuntimeDialogueSessionLoader _dialogueSessionLoader;
   final RuntimeMapBundleLoader _runtimeMapBundleLoader;
   final RuntimeTilesetImageLoader _runtimeTilesetImageLoader;
+  late final RuntimeTilesetImageSingleFlightCache _tilesetImageCache;
+  bool _isRemoved = false;
+  bool _onLoadInProgress = false;
   final RuntimePlayerPokemonProgressionCatalogLoader
       _runtimePlayerPokemonProgressionCatalogLoader;
   final Map<String, RuntimeMapBundle> _runtimeBundleByMapId =
@@ -489,8 +498,6 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       <String, Future<void>>{};
   final Map<String, Future<void>> _prewarmedBattleDataFutureByKey =
       <String, Future<void>>{};
-  final Map<String, RuntimeTilesetImage> _cachedTilesetImagesByPath =
-      <String, RuntimeTilesetImage>{};
   final BorderRuntimeAssetCache _borderRuntimeAssetCache =
       BorderRuntimeAssetCache();
 
@@ -2985,50 +2992,15 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     final transparentColors = _transparentColorByTilesetId(
       manifest ?? _bundle.manifest,
     );
-    final result = <String, RuntimeTilesetImage>{};
-    final missing = <String, String>{};
+    final result = await _tilesetImageCache.loadById(
+      absolutePathByTilesetId,
+      transparentColorByTilesetId: transparentColors,
+    );
     for (final entry in absolutePathByTilesetId.entries) {
-      final cacheKey = _tilesetImageCacheKey(
-        entry.value,
-        transparentColors[entry.key],
-      );
-      final cached = _cachedTilesetImagesByPath[cacheKey];
-      if (cached != null) {
-        debugPrint('[runtime_game] tileset cache hit id=${entry.key}');
-        result[entry.key] = cached;
-      } else {
+      if (!result.containsKey(entry.key)) {
         debugPrint(
-          '[runtime_game] tileset cache miss id=${entry.key} path=${entry.value}',
+          '[runtime_game] tileset image loader returned no image id=${entry.key} path=${entry.value}',
         );
-        missing[entry.key] = entry.value;
-      }
-    }
-    if (missing.isNotEmpty) {
-      debugPrint(
-        '[runtime_game] tileset image loader start missing=${missing.length}',
-      );
-      final loaded = await _runtimeTilesetImageLoader(
-        missing,
-        transparentColorByTilesetId: <String, TilesetTransparentColor>{
-          for (final tilesetId in missing.keys)
-            if (transparentColors[tilesetId] != null)
-              tilesetId: transparentColors[tilesetId]!,
-        },
-      );
-      for (final entry in missing.entries) {
-        final image = loaded[entry.key];
-        if (image == null) {
-          debugPrint(
-            '[runtime_game] tileset image loader returned no image id=${entry.key} path=${entry.value}',
-          );
-          continue;
-        }
-        debugPrint('[runtime_game] tileset image loaded id=${entry.key}');
-        _cachedTilesetImagesByPath[_tilesetImageCacheKey(
-          entry.value,
-          transparentColors[entry.key],
-        )] = image;
-        result[entry.key] = image;
       }
     }
     debugPrint(
@@ -3062,13 +3034,6 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     };
   }
 
-  String _tilesetImageCacheKey(
-    String path,
-    TilesetTransparentColor? transparentColor,
-  ) {
-    return '$path#${transparentColor?.toHexRgb() ?? ''}';
-  }
-
   Future<T> _traceAsync<T>(
     String domain,
     String label,
@@ -3389,96 +3354,81 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     _applyDebugTileMarker();
   }
 
+  @override
+  void onRemove() {
+    _isRemoved = true;
+    if (!_onLoadInProgress) {
+      _tilesetImageCache.dispose();
+    }
+    super.onRemove();
+  }
+
   @override
   Future<void> onLoad() async {
-    if (initialMapActivationReason == MapActivationReason.saveRestore) {
-      final restoredMapId = _gameState.currentMapId.trim();
-      if (restoredMapId.isEmpty) {
-        throw StateError(
-          'An explicit saveRestore boot requires a non-empty saved map id.',
-        );
-      }
-      if (restoredMapId != _bundle.map.id) {
-        _bundle = await _loadRuntimeMapBundleCached(restoredMapId);
-      }
-    }
-    _bundle = await prepareBorderRuntimeBundle(_bundle);
-    _runtimeBundleByMapId[_bundle.map.id] = _bundle;
-    final hydratedGameState = _hydrateOwnedPlayerPokemonProgression(_gameState);
-    final rootBorderAssets = _loadBorderRuntimeAssets(_bundle);
-    debugPrint('[runtime_game] tileset image load start map=${_bundle.map.id}');
-    final tilesetImages =
-        _loadTilesetImagesCached(_bundle.tilesetAbsolutePathsById);
-    final bootResources = await Future.wait<Object?>(
-      <Future<Object?>>[
-        hydratedGameState,
-        rootBorderAssets,
-        tilesetImages,
-      ],
-      eagerError: false,
-    );
-    _gameState = bootResources[0]! as GameState;
-    final loadedRootBorderAssets =
-        bootResources[1]! as BorderRuntimeAssetBundle;
-    final images = bootResources[2]! as Map<String, RuntimeTilesetImage>;
-    // The coordinator was constructed before asynchronous catalogue loading.
-    // Publish the hydrated snapshot before any map-enter dispatch can observe
-    // the game as playable.
-    await _narrativeStateTransactions.transact<void>((_) {
-      return NarrativeEventStateTransaction.commit(_gameState, null);
-    });
-    final activation = _createMapActivation(
-      mapId: _bundle.map.id,
-      reason: initialMapActivationReason,
-    );
-    debugPrint(
-      '[runtime_game] onLoad start map=${_bundle.map.id} projectFilePath=$projectFilePath tilesets=${_bundle.tilesetAbsolutePathsById.length}',
-    );
-    if (initialMapActivationReason == MapActivationReason.saveRestore) {
-      if (!_isWithinMapBounds(_bundle.map, _gameState.playerPosition)) {
-        throw StateError(
-          'Saved player position is outside map "${_bundle.map.id}".',
-        );
+    _onLoadInProgress = true;
+    try {
+      if (_isRemoved) return;
+      if (initialMapActivationReason == MapActivationReason.saveRestore) {
+        final restoredMapId = _gameState.currentMapId.trim();
+        if (restoredMapId.isEmpty) {
+          throw StateError(
+            'An explicit saveRestore boot requires a non-empty saved map id.',
+          );
+        }
+        if (restoredMapId != _bundle.map.id) {
+          _bundle = await _loadRuntimeMapBundleCached(restoredMapId);
+          if (_isRemoved) return;
+        }
       }
-      _world = GameplayWorldState.initial(
-        map: _bundle.map,
-        playerPos: _gameState.playerPosition,
-        playerFacing: _gameState.playerFacing.asDirection,
-        playerMovementMode: _gameState.playerMovementMode,
-        project: _bundle.manifest,
-        tileWidth: _bundle.manifest.settings.tileWidth,
-        tileHeight: _bundle.manifest.settings.tileHeight,
-        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
-        mapEntityPresencePredicate:
-            _mapEntityPresencePredicateFor(_bundle.manifest),
-      );
+      _bundle = await prepareBorderRuntimeBundle(_bundle);
+      if (_isRemoved) return;
+      _runtimeBundleByMapId[_bundle.map.id] = _bundle;
+      final hydratedGameState =
+          _hydrateOwnedPlayerPokemonProgression(_gameState);
+      final rootBorderAssets = _loadBorderRuntimeAssets(_bundle);
       debugPrint(
-        '[runtime] Save restored on map ${_bundle.map.id} at '
-        '(${_world.player.pos.x}, ${_world.player.pos.y})',
-      );
-    } else if (_isProjectNewGameBoot) {
-      _world = GameplayWorldState.initial(
-        map: _bundle.map,
-        playerPos: _gameState.playerPosition,
-        playerFacing: _gameState.playerFacing.asDirection,
-        playerMovementMode: _gameState.playerMovementMode,
-        project: _bundle.manifest,
-        tileWidth: _bundle.manifest.settings.tileWidth,
-        tileHeight: _bundle.manifest.settings.tileHeight,
-        npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
-        mapEntityPresencePredicate:
-            _mapEntityPresencePredicateFor(_bundle.manifest),
+          '[runtime_game] tileset image load start map=${_bundle.map.id}');
+      final tilesetImages =
+          _loadTilesetImagesCached(_bundle.tilesetAbsolutePathsById);
+      final bootResources = await Future.wait<Object?>(
+        <Future<Object?>>[
+          hydratedGameState,
+          rootBorderAssets,
+          tilesetImages,
+        ],
+        eagerError: false,
+      );
+      _gameState = bootResources[0]! as GameState;
+      final loadedRootBorderAssets =
+          bootResources[1]! as BorderRuntimeAssetBundle;
+      final images = bootResources[2]! as Map<String, RuntimeTilesetImage>;
+      await afterInitialTilesetImagesLoaded?.call();
+      if (_isRemoved) return;
+      // The coordinator was constructed before asynchronous catalogue loading.
+      // Publish the hydrated snapshot before any map-enter dispatch can observe
+      // the game as playable.
+      await _narrativeStateTransactions.transact<void>((_) {
+        return NarrativeEventStateTransaction.commit(_gameState, null);
+      });
+      if (_isRemoved) return;
+      final activation = _createMapActivation(
+        mapId: _bundle.map.id,
+        reason: initialMapActivationReason,
       );
       debugPrint(
-        '[runtime] New game created from project contract on '
-        '${_bundle.map.id} at '
-        '(${_world.player.pos.x}, ${_world.player.pos.y})',
+        '[runtime_game] onLoad start map=${_bundle.map.id} projectFilePath=$projectFilePath tilesets=${_bundle.tilesetAbsolutePathsById.length}',
       );
-    } else {
-      try {
-        debugPrint('[runtime_game] world build start map=${_bundle.map.id}');
-        _world = GameplayWorldState.fromMap(
-          _bundle.map,
+      if (initialMapActivationReason == MapActivationReason.saveRestore) {
+        if (!_isWithinMapBounds(_bundle.map, _gameState.playerPosition)) {
+          throw StateError(
+            'Saved player position is outside map "${_bundle.map.id}".',
+          );
+        }
+        _world = GameplayWorldState.initial(
+          map: _bundle.map,
+          playerPos: _gameState.playerPosition,
+          playerFacing: _gameState.playerFacing.asDirection,
+          playerMovementMode: _gameState.playerMovementMode,
           project: _bundle.manifest,
           tileWidth: _bundle.manifest.settings.tileWidth,
           tileHeight: _bundle.manifest.settings.tileHeight,
@@ -3487,14 +3437,15 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
               _mapEntityPresencePredicateFor(_bundle.manifest),
         );
         debugPrint(
-          '[runtime] Map loaded: ${_bundle.map.id}, spawn at (${_world.player.pos.x}, ${_world.player.pos.y})',
+          '[runtime] Save restored on map ${_bundle.map.id} at '
+          '(${_world.player.pos.x}, ${_world.player.pos.y})',
         );
-      } on GameplaySpawnResolutionException catch (e) {
-        debugPrint(
-            '[runtime] Spawn resolution failed ($e), falling back to (0,0)');
+      } else if (_isProjectNewGameBoot) {
         _world = GameplayWorldState.initial(
           map: _bundle.map,
-          playerPos: const GridPos(x: 0, y: 0),
+          playerPos: _gameState.playerPosition,
+          playerFacing: _gameState.playerFacing.asDirection,
+          playerMovementMode: _gameState.playerMovementMode,
           project: _bundle.manifest,
           tileWidth: _bundle.manifest.settings.tileWidth,
           tileHeight: _bundle.manifest.settings.tileHeight,
@@ -3502,53 +3453,95 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
           mapEntityPresencePredicate:
               _mapEntityPresencePredicateFor(_bundle.manifest),
         );
+        debugPrint(
+          '[runtime] New game created from project contract on '
+          '${_bundle.map.id} at '
+          '(${_world.player.pos.x}, ${_world.player.pos.y})',
+        );
+      } else {
+        try {
+          debugPrint('[runtime_game] world build start map=${_bundle.map.id}');
+          _world = GameplayWorldState.fromMap(
+            _bundle.map,
+            project: _bundle.manifest,
+            tileWidth: _bundle.manifest.settings.tileWidth,
+            tileHeight: _bundle.manifest.settings.tileHeight,
+            npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
+            mapEntityPresencePredicate:
+                _mapEntityPresencePredicateFor(_bundle.manifest),
+          );
+          debugPrint(
+            '[runtime] Map loaded: ${_bundle.map.id}, spawn at (${_world.player.pos.x}, ${_world.player.pos.y})',
+          );
+        } on GameplaySpawnResolutionException catch (e) {
+          debugPrint(
+              '[runtime] Spawn resolution failed ($e), falling back to (0,0)');
+          _world = GameplayWorldState.initial(
+            map: _bundle.map,
+            playerPos: const GridPos(x: 0, y: 0),
+            project: _bundle.manifest,
+            tileWidth: _bundle.manifest.settings.tileWidth,
+            tileHeight: _bundle.manifest.settings.tileHeight,
+            npcMapPresencePredicate: _npcPresencePredicateFor(_bundle.manifest),
+            mapEntityPresencePredicate:
+                _mapEntityPresencePredicateFor(_bundle.manifest),
+          );
+        }
+      }
+      debugPrint(
+        '[runtime_game] tileset image load ok count=${images.length} map=${_bundle.map.id}',
+      );
+      _activeMapId = _bundle.map.id;
+      debugPrint('[runtime_game] mount root map start map=$_activeMapId');
+      final rootMap = await _mountLoadedMap(
+        bundle: _bundle,
+        tileImagesById: images,
+        borderAssets: loadedRootBorderAssets,
+        originCellX: 0,
+        originCellY: 0,
+      );
+      if (_isRemoved) return;
+      debugPrint('[runtime_game] mount root map ok map=$_activeMapId');
+      final playerChar = _resolvePlayerCharacter(_bundle);
+      _player = PlayerComponent(
+        bundle: _bundle,
+        state: _world.player,
+        characterEntry: playerChar,
+        tileImages: images,
+        mapOrigin: _originPixelsOf(rootMap),
+      );
+      await world.add(_player);
+      if (_isRemoved) return;
+      _actorContactShadowRuntimeReady = true;
+      _refreshActorContactShadowCollection();
+      _syncGameStateFromWorld();
+      _configureCameraViewport();
+      _syncCameraToPlayer();
+      _preloadActiveMapConnections();
+      _prewarmActiveMapWarpTargets();
+      _prewarmActiveMapBattleData();
+      _ensureBehaviorDebugOverlay();
+      _ensureFpsOverlay();
+      _applyDebugTileMarker();
+      _resetScriptedNpcMovementController();
+      _resetTriggerEnterOccupancy();
+      _setFlowPhase(_RuntimeFlowPhase.overworld);
+      _installMapActivation(activation);
+      await super.onLoad();
+      if (_isRemoved) return;
+      _runDetachedNarrativeTask(
+        operation: 'mapEnter.initialBoot',
+        task: () async {
+          await _dispatchCompletedMapActivation(activation);
+        },
+      );
+      debugPrint('[runtime_game] onLoad completed activeMapId=$_activeMapId');
+    } finally {
+      _onLoadInProgress = false;
+      if (_isRemoved) {
+        _tilesetImageCache.dispose();
       }
     }
-    debugPrint(
-      '[runtime_game] tileset image load ok count=${images.length} map=${_bundle.map.id}',
-    );
-    _activeMapId = _bundle.map.id;
-    debugPrint('[runtime_game] mount root map start map=$_activeMapId');
-    final rootMap = await _mountLoadedMap(
-      bundle: _bundle,
-      tileImagesById: images,
-      borderAssets: loadedRootBorderAssets,
-      originCellX: 0,
-      originCellY: 0,
-    );
-    debugPrint('[runtime_game] mount root map ok map=$_activeMapId');
-    final playerChar = _resolvePlayerCharacter(_bundle);
-    _player = PlayerComponent(
-      bundle: _bundle,
-      state: _world.player,
-      characterEntry: playerChar,
-      tileImages: images,
-      mapOrigin: _originPixelsOf(rootMap),
-    );
-    await world.add(_player);
-    _actorContactShadowRuntimeReady = true;
-    _refreshActorContactShadowCollection();
-    _syncGameStateFromWorld();
-    _configureCameraViewport();
-    _syncCameraToPlayer();
-    _preloadActiveMapConnections();
-    _prewarmActiveMapWarpTargets();
-    _prewarmActiveMapBattleData();
-    _ensureBehaviorDebugOverlay();
-    _ensureFpsOverlay();
-    _applyDebugTileMarker();
-    _resetScriptedNpcMovementController();
-    _resetTriggerEnterOccupancy();
-    _setFlowPhase(_RuntimeFlowPhase.overworld);
-    _installMapActivation(activation);
-    await super.onLoad();
-    _runDetachedNarrativeTask(
-      operation: 'mapEnter.initialBoot',
-      task: () async {
-        await _dispatchCompletedMapActivation(activation);
-      },
-    );
-    debugPrint('[runtime_game] onLoad completed activeMapId=$_activeMapId');
   }
 
   @override
@@ -12012,6 +12005,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       final patch = PlacedElementOcclusionPatchComponent(
         instruction: instruction,
         tilesetImage: tilesetImage,
+        visibleWorldRectProvider: () => camera.visibleWorldRect,
       );
       occlusionPatches.add(patch);
       await world.add(patch);
diff --git a/packages/map_runtime/lib/src/presentation/flame/quarter_turn_pixel_renderer.dart b/packages/map_runtime/lib/src/presentation/flame/quarter_turn_pixel_renderer.dart
index c26273c32..cf9f59b44 100644
--- a/packages/map_runtime/lib/src/presentation/flame/quarter_turn_pixel_renderer.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/quarter_turn_pixel_renderer.dart
@@ -15,6 +15,7 @@ final class QuarterTurnPixelDrawResult {
   const QuarterTurnPixelDrawResult({
     required this.drawRunCount,
     required this.includedDestinationPixelCount,
+    this.includedDestinationRunCount = 0,
   });
 
   static const empty = QuarterTurnPixelDrawResult(
@@ -24,6 +25,98 @@ final class QuarterTurnPixelDrawResult {
 
   final int drawRunCount;
   final int includedDestinationPixelCount;
+
+  /// Horizontal mask segments encountered during the same sampling pass.
+  /// This remains distinct from [drawRunCount], because a pure rotation can
+  /// replay many clipped segments with one image draw.
+  final int includedDestinationRunCount;
+}
+
+/// Component-owned display list for static quarter-turn pixels.
+///
+/// Recording performs the exact discrete sampling once. Steady-state draws
+/// only replay the resulting local [ui.Picture]. The plan never owns or
+/// disposes the shared [RuntimeTilesetImage] used while it is recorded.
+final class QuarterTurnPixelDrawPlan {
+  QuarterTurnPixelDrawPlan._({
+    required ui.Picture picture,
+    required this.result,
+    required this.sourcePixelSampleCount,
+  }) : _picture = picture;
+
+  factory QuarterTurnPixelDrawPlan.record({
+    required RuntimeTilesetImage image,
+    required ui.Rect sourceRect,
+    required ui.Rect destinationRect,
+    required GridSize sourcePixelSize,
+    required GridSize destinationPixelSize,
+    required int quarterTurns,
+    required ui.Paint paint,
+    QuarterTurnSourcePixelPredicate? includeSourcePixel,
+    void Function(ui.Picture picture)? debugOnDiscardedPicture,
+  }) {
+    final recorder = ui.PictureRecorder();
+    var sourcePixelSampleCount = 0;
+    final trackedPredicate = includeSourcePixel == null
+        ? null
+        : (GridPos sourcePixel) {
+            sourcePixelSampleCount += 1;
+            return includeSourcePixel(sourcePixel);
+          };
+    ui.Picture? picture;
+    try {
+      final result = drawQuarterTurnPixels(
+        ui.Canvas(recorder),
+        image: image,
+        sourceRect: sourceRect,
+        destinationRect: destinationRect,
+        sourcePixelSize: sourcePixelSize,
+        destinationPixelSize: destinationPixelSize,
+        quarterTurns: quarterTurns,
+        paint: paint,
+        includeSourcePixel: trackedPredicate,
+      );
+      picture = recorder.endRecording();
+      return QuarterTurnPixelDrawPlan._(
+        picture: picture,
+        result: result,
+        sourcePixelSampleCount: sourcePixelSampleCount,
+      );
+    } catch (_) {
+      final discardedPicture = picture ?? recorder.endRecording();
+      try {
+        debugOnDiscardedPicture?.call(discardedPicture);
+      } finally {
+        discardedPicture.dispose();
+      }
+      rethrow;
+    }
+  }
+
+  final ui.Picture _picture;
+  final QuarterTurnPixelDrawResult result;
+
+  /// Number of source-mask predicate calls made during recording.
+  ///
+  /// Replaying the plan never increments this value.
+  final int sourcePixelSampleCount;
+  bool _isDisposed = false;
+
+  bool get isDisposed => _isDisposed;
+  int get approximateBytesUsed => _picture.approximateBytesUsed;
+
+  void draw(ui.Canvas canvas) {
+    if (_isDisposed) {
+      throw StateError('QuarterTurnPixelDrawPlan is disposed.');
+    }
+    canvas.drawPicture(_picture);
+  }
+
+  void dispose() {
+    if (_isDisposed) return;
+    _isDisposed = true;
+    _picture.dispose();
+  }
 }
 
 /// Draws a quarter-turned bitmap with the exact discrete sampling from core.
@@ -61,6 +154,7 @@ QuarterTurnPixelDrawResult drawQuarterTurnPixels(
       drawRunCount: 1,
       includedDestinationPixelCount:
           destinationPixelSize.width * destinationPixelSize.height,
+      includedDestinationRunCount: 1,
     );
   }
 
@@ -73,8 +167,10 @@ QuarterTurnPixelDrawResult drawQuarterTurnPixels(
   if (isPurePixelRotation) {
     var includedDestinationPixelCount =
         destinationPixelSize.width * destinationPixelSize.height;
+    var includedDestinationRunCount = 1;
     if (includeSourcePixel != null) {
       includedDestinationPixelCount = 0;
+      includedDestinationRunCount = 0;
       final destinationPixelWidth =
           destinationRect.width / destinationPixelSize.width;
       final destinationPixelHeight =
@@ -102,6 +198,7 @@ QuarterTurnPixelDrawResult drawQuarterTurnPixels(
                 destinationPixelHeight,
               ),
             );
+            includedDestinationRunCount += 1;
             runStart = null;
           }
         }
@@ -136,6 +233,7 @@ QuarterTurnPixelDrawResult drawQuarterTurnPixels(
     return QuarterTurnPixelDrawResult(
       drawRunCount: 1,
       includedDestinationPixelCount: includedDestinationPixelCount,
+      includedDestinationRunCount: includedDestinationRunCount,
     );
   }
 
@@ -147,19 +245,26 @@ QuarterTurnPixelDrawResult drawQuarterTurnPixels(
       destinationRect.height / destinationPixelSize.height;
   var drawRunCount = 0;
   var includedDestinationPixelCount = 0;
+  var includedDestinationRunCount = 0;
 
   for (var destinationY = 0;
       destinationY < destinationPixelSize.height;
       destinationY++) {
     var destinationX = 0;
+    var previousDestinationPixelIncluded = false;
     while (destinationX < destinationPixelSize.width) {
       final source = transform.destinationPixelToSourcePixel(
         GridPos(x: destinationX, y: destinationY),
       );
       if (includeSourcePixel != null && !includeSourcePixel(source)) {
+        previousDestinationPixelIncluded = false;
         destinationX += 1;
         continue;
       }
+      if (includeSourcePixel != null && !previousDestinationPixelIncluded) {
+        includedDestinationRunCount += 1;
+      }
+      previousDestinationPixelIncluded = true;
 
       var runEnd = destinationX + 1;
       while (runEnd < destinationPixelSize.width) {
@@ -216,6 +321,8 @@ QuarterTurnPixelDrawResult drawQuarterTurnPixels(
   return QuarterTurnPixelDrawResult(
     drawRunCount: drawRunCount,
     includedDestinationPixelCount: includedDestinationPixelCount,
+    includedDestinationRunCount:
+        includeSourcePixel == null ? drawRunCount : includedDestinationRunCount,
   );
 }
 
diff --git a/packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart b/packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
index db6898547..42149aa9e 100644
--- a/packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
+++ b/packages/map_runtime/test/placed_element_occlusion_patch_component_test.dart
@@ -177,6 +177,108 @@ void main() {
       expect(component.position.y, 200);
       expect(component.priority, 1216);
     });
+
+    test('prepares once and replays the same plan across steady-state renders',
+        () async {
+      final component = PlacedElementOcclusionPatchComponent(
+        instruction: _instruction(
+          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {0, 3}),
+        ),
+        tilesetImage: await _runtimeTilesetImage2x2(),
+      );
+      addTearDown(component.onRemove);
+      final preparationSamples = component.debugQuarterTurnResampleCount;
+      final first = ui.PictureRecorder();
+      component.render(Canvas(first));
+      first.endRecording().dispose();
+      final second = ui.PictureRecorder();
+      component.render(Canvas(second));
+      second.endRecording().dispose();
+
+      expect(component.debugRenderPlanPreparationCount, 1);
+      expect(component.debugRenderPlanDrawCount, 2);
+      expect(preparationSamples, greaterThan(0));
+      expect(component.debugQuarterTurnResampleCount, preparationSamples);
+    });
+
+    test('culls outside the camera and keeps the one-pixel edge halo',
+        () async {
+      var visibleRect = const Rect.fromLTWH(20, 20, 2, 2);
+      final component = PlacedElementOcclusionPatchComponent(
+        instruction: _instruction(
+          worldLeft: 10,
+          worldTop: 10,
+          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {0}),
+        ),
+        tilesetImage: await _runtimeTilesetImage2x2(),
+        visibleWorldRectProvider: () => visibleRect,
+      );
+      addTearDown(component.onRemove);
+      final outside = ui.PictureRecorder();
+      component.render(Canvas(outside));
+      outside.endRecording().dispose();
+
+      expect(component.debugRenderPlanDrawCount, 0);
+      expect(component.debugCulledRenderCount, 1);
+
+      visibleRect = const Rect.fromLTWH(8.5, 10, 0.75, 1);
+      final edge = ui.PictureRecorder();
+      component.render(Canvas(edge));
+      edge.endRecording().dispose();
+
+      expect(component.debugRenderPlanDrawCount, 1);
+      expect(component.debugCulledRenderCount, 1);
+    });
+
+    test('culling follows the current position after an origin translation',
+        () async {
+      final component = PlacedElementOcclusionPatchComponent(
+        instruction: _instruction(
+          worldLeft: 10,
+          worldTop: 10,
+          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {0}),
+        ),
+        tilesetImage: await _runtimeTilesetImage2x2(),
+        visibleWorldRectProvider: () => const Rect.fromLTWH(109, 9, 4, 4),
+      );
+      addTearDown(component.onRemove);
+      final before = ui.PictureRecorder();
+      component.render(Canvas(before));
+      before.endRecording().dispose();
+      expect(component.debugRenderPlanDrawCount, 0);
+
+      component.translateByMapOriginDelta(Vector2(100, 0));
+      final after = ui.PictureRecorder();
+      component.render(Canvas(after));
+      after.endRecording().dispose();
+
+      expect(component.debugRenderPlanDrawCount, 1);
+      expect(component.debugCulledRenderCount, 1);
+    });
+
+    test('disposes its render plan idempotently without owning the tileset',
+        () async {
+      final tileset = await _runtimeTilesetImage2x2();
+      final component = PlacedElementOcclusionPatchComponent(
+        instruction: _instruction(),
+        tilesetImage: tileset,
+      );
+
+      component.onRemove();
+      component.onRemove();
+
+      expect(component.debugRenderPlanDisposed, isTrue);
+      final recorder = ui.PictureRecorder();
+      tileset.drawImageRect(
+        Canvas(recorder),
+        const Rect.fromLTWH(0, 0, 1, 1),
+        const Rect.fromLTWH(0, 0, 1, 1),
+        Paint(),
+      );
+      final image = await recorder.endRecording().toImage(1, 1);
+      addTearDown(image.dispose);
+      expect(await pixelAt(image, 0, 0), rgba(255, 0, 0, 255));
+    });
   });
 }
 
diff --git a/packages/map_runtime/test/quarter_turn_pixel_renderer_test.dart b/packages/map_runtime/test/quarter_turn_pixel_renderer_test.dart
index 4768284e8..eb24f4eec 100644
--- a/packages/map_runtime/test/quarter_turn_pixel_renderer_test.dart
+++ b/packages/map_runtime/test/quarter_turn_pixel_renderer_test.dart
@@ -86,6 +86,26 @@ void main() {
     rendered.image.dispose();
   });
 
+  test('counts mask segments independently from non-pure sampling draws',
+      () async {
+    const sourceSize = GridSize(width: 6, height: 2);
+    const destinationSize = GridSize(width: 3, height: 4);
+    final atlas = await _atlas(sourceSize);
+    addTearDown(atlas.image.dispose);
+    final rendered = await _render(
+      atlas.runtimeImage,
+      sourceSize: sourceSize,
+      destinationSize: destinationSize,
+      quarterTurns: 1,
+      includeSourcePixel: (source) => source.x == 0,
+    );
+    addTearDown(rendered.image.dispose);
+
+    expect(rendered.result.includedDestinationPixelCount, 3);
+    expect(rendered.result.drawRunCount, 2);
+    expect(rendered.result.includedDestinationRunCount, 1);
+  });
+
   test('clips pure rotations with a source predicate and skips empty masks',
       () async {
     const sourceSize = GridSize(width: 3, height: 2);
@@ -142,6 +162,69 @@ void main() {
     filtered.image.dispose();
     empty.image.dispose();
   });
+
+  test('records an immutable draw plan once and replays exact pixels',
+      () async {
+    const sourceSize = GridSize(width: 3, height: 2);
+    final atlas = await _atlas(sourceSize);
+    addTearDown(atlas.image.dispose);
+    final plan = QuarterTurnPixelDrawPlan.record(
+      image: atlas.runtimeImage,
+      sourceRect: const ui.Rect.fromLTWH(0, 0, 3, 2),
+      destinationRect: const ui.Rect.fromLTWH(0, 0, 3, 2),
+      sourcePixelSize: sourceSize,
+      destinationPixelSize: sourceSize,
+      quarterTurns: 0,
+      paint: ui.Paint()..filterQuality = ui.FilterQuality.none,
+      includeSourcePixel: (source) => source.x == source.y,
+    );
+    addTearDown(plan.dispose);
+
+    final first = ui.PictureRecorder();
+    plan.draw(ui.Canvas(first));
+    final firstImage = await first.endRecording().toImage(3, 2);
+    final second = ui.PictureRecorder();
+    plan.draw(ui.Canvas(second));
+    final secondImage = await second.endRecording().toImage(3, 2);
+    addTearDown(firstImage.dispose);
+    addTearDown(secondImage.dispose);
+
+    expect(plan.result.includedDestinationPixelCount, 2);
+    final firstBytes = (await firstImage.toByteData(
+      format: ui.ImageByteFormat.rawRgba,
+    ))!;
+    final secondBytes = (await secondImage.toByteData(
+      format: ui.ImageByteFormat.rawRgba,
+    ))!;
+    expect(
+      firstBytes.buffer.asUint8List(),
+      orderedEquals(secondBytes.buffer.asUint8List()),
+    );
+  });
+
+  test('disposes the partial picture when plan recording fails', () async {
+    const validSize = GridSize(width: 2, height: 2);
+    final atlas = await _atlas(validSize);
+    addTearDown(atlas.image.dispose);
+    ui.Picture? discarded;
+
+    expect(
+      () => QuarterTurnPixelDrawPlan.record(
+        image: atlas.runtimeImage,
+        sourceRect: const ui.Rect.fromLTWH(0, 0, 2, 2),
+        destinationRect: const ui.Rect.fromLTWH(0, 0, 2, 2),
+        sourcePixelSize: const GridSize(width: 0, height: 2),
+        destinationPixelSize: validSize,
+        quarterTurns: 0,
+        paint: ui.Paint(),
+        debugOnDiscardedPicture: (picture) => discarded = picture,
+      ),
+      throwsArgumentError,
+    );
+
+    expect(discarded, isNotNull);
+    expect(discarded!.debugDisposed, isTrue);
+  });
 }
 
 Future<({ui.Image image, RuntimeTilesetImage runtimeImage})> _atlas(
~~~~

## Annexe B — Contenu complet des fichiers créés

Les Evidence Packs ne s’auto-dupliquent pas. Le plan créé est reproduit intégralement.

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-02-runtime-occlusion.md`

~~~~markdown
# PERF-RM-02 — Plan d'implémentation occlusion runtime

**Scope :** déplacer la préparation immuable hors de `render` et culler les patches hors caméra. Aucun changement de masque, rotation, profondeur ou collision gameplay.

## Audit initial

- Le composant décode déjà le masque et calcule `_drawRuns` une fois, mais `render` reconstruit encore transform, prédicat et `Path` via `drawQuarterTurnPixels` à chaque frame.
- `PlayableMapGame` instancie chaque patch et possède `camera.visibleWorldRect`.
- Les tests couvrent rotations 0–3, masques asymétriques, opacité, translation et goldens d'ordre de profondeur.
- La recherche Flame configurée n'a retourné aucune documentation exploitable ; l'implémentation reste sur Flame 1.37.0 et les patterns du dépôt.

## Étapes test-first

- [ ] Étendre `quarter_turn_pixel_renderer_test.dart` avec un plan immuable préparé une fois et dessiné plusieurs fois sans nouvelle préparation.
- [ ] Étendre `placed_element_occlusion_patch_component_test.dart` : deux renders réutilisent le plan ; patch hors viewport produit zéro draw ; intersection bord/halo reste visible.
- [ ] Exécuter les tests et conserver RED sur les compteurs/API absents.
- [ ] Ajouter dans le renderer un plan local immuable qui enregistre une fois les commandes pixel exactes et conserve le résultat de préparation ; lifecycle explicite de sa `Picture`.
- [ ] Remplacer le rééchantillonnage du composant par le dessin du plan ; conserver les compteurs de diagnostic et les sorties pixel exactes.
- [ ] Injecter un provider de visible-world-rect ; `PlayableMapGame` fournit `camera.visibleWorldRect`. Le rectangle monde du composant inclut sa taille transformée et un halo d'un pixel monde.
- [ ] Disposer le plan lors du retrait du composant sans disposer le tileset partagé.
- [ ] Relancer rotations, masques vide/invalide, opacity, goldens, smoke runtime et analyseur.

## Non-objectifs et risques

- Pas de cache global de `Picture`, pas de désactivation de l'occlusion, pas de modification de `map_core`.
- Le culling doit utiliser la position courante après translation d'origine, pas les coordonnées initiales de l'instruction.
- La ressource enregistrée ne doit pas survivre au composant.

## Preuves attendues

- Préparation exactement une fois, plusieurs renders ; zéro dessin hors viewport.
- Pixels/rotations et ordre acteur-toit identiques.
- Profil Selbrume trois runs seulement si le runner profile contractuel est disponible ; sinon gate explicitement non prouvée.
~~~~
