# Evidence Pack — PERF-RM-01 — Ownership assets runtime

Date : 2026-08-01  
Phase : 1 — Urgences P0  
Findings : `PERF-RT-02`, partie runtime de `PERF-ASSET-01` et `PERF-ASSET-02`  
Verdict proposé : **PARTIAL — implémentation et non-régression vertes, fermeture métrologique RM00 absente**

## Résumé exécutif

Le chargement des tilesets runtime utilise désormais un cache single-flight possédé par
`PlayableMapGame`, indexé par chemin absolu normalisé et couleur transparente RGB. Les
callers concurrents partagent la même future, les succès partiels restent cachés, et les
erreurs ou omissions restent retryables. Les codecs sont libérés en `finally` et les images
déjà décodées sont nettoyées si un chunk ou un tileset ultérieur échoue. Le cache, les
images terminées et les complétions tardives sont libérés lors du retrait du jeu.

Le retrait pendant `onLoad` est sécurisé : le cache reste vivant jusqu’à la fin du handoff
asynchrone, le boot s’interrompt avant le mount, puis les images sont disposées. Cela évite
qu’un loader déjà résolu transmette une image libérée à un composant encore en création.

L’overlay battle ne fait plus de lecture de fichier synchrone dans `build`. Il affiche le
fallback pendant loading/null/erreur, neutralise les résultats obsolètes A→B et conserve la
priorité de `itemIconBuilder`.

Le code fonctionnel satisfait les invariants du lot. Le statut reste `PARTIAL` au sens
strict de la roadmap, car la baseline `PERF-RM-00` et le reprofilage boot Selbrume ne sont
pas disponibles : l’absence d’une seconde séquence des cinq tilesets n’est donc pas prouvée
sur trois profils comparables.

## Scope et non-objectifs

- Scope respecté : `map_runtime` et teardown du host de référence ; aucun type
  Flutter/UIImage déplacé dans `map_core`.
- Contrat batch `RuntimeTilesetImageLoader` préservé.
- Cache local à une instance de jeu, jamais global.
- Aucune migration JSON, aucun changement authoring, aucune règle gameplay.
- Le cache expose un `dispose()` idempotent, appelé par `PlayableMapGame.onRemove` ; aucun
  cache global ni LRU transverse n’est introduit.
- Le lot ne prétend pas fermer `PERF-RT-01`.

## Audit initial

L’audit avait identifié deux chargements concurrents possibles des mêmes cinq tilesets et
une lecture/décodage synchrone de l’icône item dans le `build` de l’overlay battle. Les
seams d’injection existants permettaient d’ajouter le single-flight sans casser les tests
clients. Le risque principal était de retenir une future en erreur, de partager une image
entre deux clés non équivalentes, ou de laisser l’ancienne image A visible pendant le
chargement de B.

## État Git initial

HEAD : `7f35d44d9f777d25046c6b94d8974a2fdd850a78`

```text
?? reports/performance/pokemap_full_performance_audit.md
?? reports/performance/pokemap_performance_remediation_roadmap.md
?? skills/creating-pokemap-maps-from-reference/scripts/__pycache__/inventory_assets.cpython-314.pyc
```

Ces trois entrées étaient préexistantes. Elles n’ont pas été modifiées ni supprimées.

## Inventaire et zones modifiées

- `packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart`
  - ajout de `RuntimeTilesetImageSingleFlightCache` ;
  - normalisation de la clé chemin/couleur, réservations synchrones des slots en vol ;
  - fan-out des IDs aliasés et éviction par identité sur omission/erreur ;
  - `decodeFirstFrameAndDispose`, rollback batch et fermeture du cache, y compris les
    complétions tardives ;
  - disposal défensif des images retournées sous un ID non demandé par un loader injecté.
- `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`
  - ownership explicite de l’image et `dispose()` idempotent.
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - ownership du cache par l’instance de jeu ;
  - délégation du loader batch existant au cache ;
  - coordination `onLoad`/`onRemove`, abort aux frontières async et disposal différé.
- `packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart`
  - widget d’icône stateful et chargement asynchrone hors `build` ;
  - invalidation path/loader, fallback et protection contre snapshot stale ;
  - priorité de l’injection `itemIconBuilder` inchangée.
- `packages/map_runtime/test/tile_image_loader_singleflight_test.dart` (créé)
  - concurrence, alias intra/inter-batch, matrice de clés, omission partielle,
    erreur synchrone/asynchrone, retry, résultat extraneous et nouvelle instance.
- `packages/map_runtime/test/tile_image_loader_codec_disposal_test.dart` (créé)
  - dispose exact du codec, rollback chunk/batch, cache terminé et completion tardive.
- `packages/map_runtime/test/battle_mobile_command_overlay_asset_loading_test.dart` (créé)
  - loading/succès/null/erreur, A affiché→B pending, même chemin, unmount.
- `packages/map_runtime/test/playable_map_game_tileset_lifecycle_test.dart` (créé)
  - retrait déterministe après résolution des images mais avant leur handoff.
- `examples/playable_runtime_host/lib/main.dart`
  - `game.dispose()` explicite au reload, reset et teardown du widget host.
- `reports/performance/plans/2026-08-01-pokemap-perf-rm-01-runtime-asset-ownership.md`
  (créé) : plan TDD du lot.

## Implémentation et décisions

La clé de cache est une valeur et non un ID de tileset, afin que deux IDs pointant vers le
même fichier avec la même couleur partagent une seule future. Les nouvelles clés d’un même
caller restent envoyées en batch au loader injecté. Une valeur omise n’est pas convertie en
erreur : elle est retirée du cache et peut être redemandée. Une erreur complète est partagée
par tous les callers puis évincée par identité, ce qui évite qu’une ancienne completion
efface une future de remplacement. La fermeture interdit de nouveaux loads, libère les
images terminées et dispose aussi une image qui terminerait après `dispose()`.

L’overlay n’utilise l’image que lorsque la nouvelle future est terminée. Ce détail évite le
comportement de `FutureBuilder` qui peut conserver les anciennes données pendant le passage
à une nouvelle future.

## Preuves TDD

RED observés :

- `RuntimeTilesetImageSingleFlightCache` absent ;
- helpers de disposal/rollback absents ;
- surface d’overlay asynchrone absente ;
- scénario A déjà affiché→B pending en échec, car A restait visible.
- race `onRemove` après résolution d’image mais avant mount non protégé.

GREEN de la passe d’implémentation :

```text
cd packages/map_runtime
flutter test test/runtime_tileset_image_test.dart test/tile_image_loader_singleflight_test.dart test/tile_image_loader_codec_disposal_test.dart test/playable_map_game_tileset_lifecycle_test.dart test/battle_mobile_command_overlay_asset_loading_test.dart test/battle_mobile_command_overlay_test.dart test/quarter_turn_pixel_renderer_test.dart test/placed_element_occlusion_patch_component_test.dart test/runtime_occlusion_visual_smoke_test.dart test/building_runtime_occlusion_golden_slice_test.dart test/phase_a_golden_battle_slice_smoke_test.dart
Résultat final ciblé Phase 1 runtime : +72, All tests passed.

flutter test
Résultat final post-corrections : +2315 ~1, All tests passed.

flutter analyze
Résultat : No issues found!
```

La recherche `existsSync|readAsBytesSync` dans l’overlay ne retourne aucun résultat.

## Validation indépendante, build et parité MCP

La passe indépendante de validation a d’abord exécuté 120 tests runtime ciblés, puis une
suite runtime complète à `+2309 ~1`, tous verts. Après les corrections de critique, elle a
rejoué 48 tests runtime, puis 7 tests strictement centrés sur le compteur et le lifecycle ;
tous sont verts et `flutter analyze` ne rapporte aucun diagnostic.

La passe racine finale a exécuté :

```text
Matrice Phase 1 runtime : +72, All tests passed.
Suite runtime complète post-lifecycle : +2315 ~1, All tests passed.
Cache extraneous + codec + lifecycle sur le diff ultime : +17, All tests passed.
Host golden slice : +1, All tests passed.
```

Les builds macOS debug de `PokeMap.app` et `PokeMap Selbrume.app` réussissent. Le build MCP
TypeScript et les 23 tests MCP séquentiels réussissent (`pass 23`, `fail 0`, durée
62 207 ms). La passe de critique finale classe RM01 **PASS fonctionnel** et `PARTIAL`
roadmap ; elle a confirmé le rollback, le disposal des résultats tardifs, le race
`onLoad/onRemove` et le teardown du host.

Parité MCP : `N/A — contrat authoring et format projet inchangés`. Le catalogue live
`pokemap_describe` a répondu `ok: true`, avec 5 resource kinds et 5 query operations ;
aucune nouvelle sémantique n’a été publiée.

## Verdict des passes

- Audit / Architecture : **GO code**, sous réserve de caractériser omission partielle,
  équivalence RGB, retry et transition A→B ; ces cas sont maintenant couverts.
- Implémentation : **GREEN**, cache et overlay livrés en TDD.
- Tests : **PASS** sur le code livré ; profils RM00 non couverts.
- Build / Validation : **PASS** — analyze runtime/host et deux builds macOS verts.
- Critique finale : **PASS fonctionnel / PARTIAL roadmap**.

## Limites, auto-critique et risques

- Le cache n’est pas borné par un LRU ; il reste borné fonctionnellement par la durée de vie
  d’une instance de jeu et le nombre de clés effectivement chargées, puis il est disposé.
- Le profil mémoire réel du boot Selbrume n’a pas été refait.
- Les compteurs/baselines RM00 manquent ; le quick win ne peut pas être quantifié de façon
  comparable.
- `BattleMobileItemIcon` reste sous `lib/src` et n’est pas exporté par le barrel public.

Auto-critique : le code ferme les causes locales visibles et la suite runtime complète est
verte, mais transformer cela en `DONE` confondrait conformité fonctionnelle et preuve de
performance. La prochaine étape est uniquement métrologique : exécuter RM00, puis trois
boots Selbrume comparables. Aucun nouveau refactor n’est recommandé avant cette mesure.

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

`git diff --check` : exit 0, aucune sortie. Les trois entrées audit/roadmap/pycache présentes à l’état initial restent préservées ; aucun Git write n’a été exécuté.

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
diff --git a/packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart b/packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
index 8a3df47fc..8fe8b5617 100644
--- a/packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
+++ b/packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart
@@ -121,7 +121,6 @@ List<RuntimeTilesetDrawSlice> resolveRuntimeTilesetDrawSlices({
   return slices;
 }
 
-@immutable
 final class RuntimeTilesetImage {
   RuntimeTilesetImage({
     required List<ui.Image> images,
@@ -137,10 +136,14 @@ final class RuntimeTilesetImage {
   final List<RuntimeTilesetChunk> chunks;
   final int width;
   final int height;
+  bool _isDisposed = false;
 
   @visibleForTesting
   int get chunkCount => chunks.length;
 
+  @visibleForTesting
+  bool get debugDisposed => _isDisposed;
+
   bool containsSourceRect(ui.Rect sourceRect) {
     return sourceRect.left >= 0 &&
         sourceRect.top >= 0 &&
@@ -156,6 +159,9 @@ final class RuntimeTilesetImage {
     ui.Rect destinationRect,
     ui.Paint paint,
   ) {
+    if (_isDisposed) {
+      throw StateError('RuntimeTilesetImage is disposed.');
+    }
     final slices = resolveRuntimeTilesetDrawSlices(
       sourceRect: sourceRect,
       destinationRect: destinationRect,
@@ -170,4 +176,16 @@ final class RuntimeTilesetImage {
       );
     }
   }
+
+  /// Releases every UI image owned by this tileset exactly once.
+  ///
+  /// Callers may share this wrapper through the runtime single-flight cache;
+  /// disposal therefore belongs to that cache's game-scoped lifecycle.
+  void dispose() {
+    if (_isDisposed) return;
+    _isDisposed = true;
+    for (final image in _images) {
+      image.dispose();
+    }
+  }
 }
diff --git a/packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart b/packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart
index fbd5b228b..934ce42d1 100644
--- a/packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart
+++ b/packages/map_runtime/lib/src/infrastructure/tile_image_loader.dart
@@ -1,12 +1,238 @@
+import 'dart:async';
 import 'dart:io';
 import 'dart:typed_data';
 import 'dart:ui' as ui;
 
 import 'package:image/image.dart' as img;
 import 'package:map_core/map_core.dart';
+import 'package:path/path.dart' as p;
 
 import 'runtime_tileset_image.dart';
 
+typedef RuntimeTilesetImageBatchLoader
+    = Future<Map<String, RuntimeTilesetImage>> Function(
+  Map<String, String> absolutePathByTilesetId, {
+  Map<String, TilesetTransparentColor> transparentColorByTilesetId,
+});
+typedef RuntimeUiImageDecoder = Future<ui.Image> Function(Uint8List bytes);
+typedef RuntimeTilesetImageFileLoader = Future<RuntimeTilesetImage> Function(
+  String absolutePath, {
+  TilesetTransparentColor? transparentColor,
+});
+
+final class RuntimeTilesetImageSingleFlightCache {
+  RuntimeTilesetImageSingleFlightCache({
+    required RuntimeTilesetImageBatchLoader loader,
+  }) : _loader = loader;
+
+  final RuntimeTilesetImageBatchLoader _loader;
+  final Map<_RuntimeTilesetImageCacheKey, RuntimeTilesetImage> _completed =
+      <_RuntimeTilesetImageCacheKey, RuntimeTilesetImage>{};
+  final Map<_RuntimeTilesetImageCacheKey, Future<RuntimeTilesetImage?>>
+      _inFlight =
+      <_RuntimeTilesetImageCacheKey, Future<RuntimeTilesetImage?>>{};
+  bool _isDisposed = false;
+
+  Future<Map<String, RuntimeTilesetImage>> loadById(
+    Map<String, String> absolutePathByTilesetId, {
+    Map<String, TilesetTransparentColor> transparentColorByTilesetId =
+        const <String, TilesetTransparentColor>{},
+  }) {
+    if (_isDisposed) {
+      return Future<Map<String, RuntimeTilesetImage>>.error(
+        StateError('RuntimeTilesetImageSingleFlightCache is disposed.'),
+      );
+    }
+    if (absolutePathByTilesetId.isEmpty) {
+      return Future<Map<String, RuntimeTilesetImage>>.value(
+        const <String, RuntimeTilesetImage>{},
+      );
+    }
+
+    final imageFutureById = <String, Future<RuntimeTilesetImage?>>{};
+    final newSlotByKey =
+        <_RuntimeTilesetImageCacheKey, _RuntimeTilesetImageLoadSlot>{};
+    for (final entry in absolutePathByTilesetId.entries) {
+      final key = _RuntimeTilesetImageCacheKey(
+        normalizedAbsolutePath: p.normalize(p.absolute(entry.value)),
+        transparentColor: transparentColorByTilesetId[entry.key],
+      );
+      final completed = _completed[key];
+      if (completed != null) {
+        imageFutureById[entry.key] =
+            Future<RuntimeTilesetImage?>.value(completed);
+        continue;
+      }
+      final inFlight = _inFlight[key];
+      if (inFlight != null) {
+        imageFutureById[entry.key] = inFlight;
+        continue;
+      }
+      final existingNewSlot = newSlotByKey[key];
+      if (existingNewSlot != null) {
+        imageFutureById[entry.key] = existingNewSlot.completer.future;
+        continue;
+      }
+
+      final completer = Completer<RuntimeTilesetImage?>();
+      final slot = _RuntimeTilesetImageLoadSlot(
+        tilesetId: entry.key,
+        absolutePath: entry.value,
+        transparentColor: transparentColorByTilesetId[entry.key],
+        completer: completer,
+      );
+      newSlotByKey[key] = slot;
+      _inFlight[key] = completer.future;
+      imageFutureById[entry.key] = completer.future;
+    }
+
+    if (newSlotByKey.isNotEmpty) {
+      _startBatch(newSlotByKey);
+    }
+    return _collectLoadedImages(imageFutureById);
+  }
+
+  Future<Map<String, RuntimeTilesetImage>> _collectLoadedImages(
+    Map<String, Future<RuntimeTilesetImage?>> imageFutureById,
+  ) async {
+    final entries = imageFutureById.entries.toList(growable: false);
+    final images = await Future.wait<RuntimeTilesetImage?>(
+      entries.map((entry) => entry.value),
+    );
+    return <String, RuntimeTilesetImage>{
+      for (var index = 0; index < entries.length; index += 1)
+        if (images[index] != null) entries[index].key: images[index]!,
+    };
+  }
+
+  void _startBatch(
+    Map<_RuntimeTilesetImageCacheKey, _RuntimeTilesetImageLoadSlot> slotByKey,
+  ) {
+    final pathById = <String, String>{
+      for (final slot in slotByKey.values) slot.tilesetId: slot.absolutePath,
+    };
+    final transparentColorById = <String, TilesetTransparentColor>{
+      for (final slot in slotByKey.values)
+        if (slot.transparentColor != null)
+          slot.tilesetId: slot.transparentColor!,
+    };
+    Future<Map<String, RuntimeTilesetImage>>.sync(
+      () => _loader(
+        pathById,
+        transparentColorByTilesetId: transparentColorById,
+      ),
+    ).then<void>(
+      (loadedById) {
+        if (_isDisposed) {
+          final uniqueImages = Set<RuntimeTilesetImage>.identity()
+            ..addAll(loadedById.values);
+          for (final image in uniqueImages) {
+            image.dispose();
+          }
+          final error = StateError(
+            'RuntimeTilesetImageSingleFlightCache was disposed while loading.',
+          );
+          for (final entry in slotByKey.entries) {
+            final key = entry.key;
+            final completer = entry.value.completer;
+            if (identical(_inFlight[key], completer.future)) {
+              _inFlight.remove(key);
+            }
+            completer.completeError(error);
+          }
+          return;
+        }
+        final requestedImages = Set<RuntimeTilesetImage>.identity();
+        for (final slot in slotByKey.values) {
+          final image = loadedById[slot.tilesetId];
+          if (image != null) {
+            requestedImages.add(image);
+          }
+        }
+        final returnedImages = Set<RuntimeTilesetImage>.identity()
+          ..addAll(loadedById.values);
+        for (final image in returnedImages) {
+          if (!requestedImages.contains(image)) {
+            image.dispose();
+          }
+        }
+        for (final entry in slotByKey.entries) {
+          final key = entry.key;
+          final slot = entry.value;
+          final image = loadedById[slot.tilesetId];
+          if (image != null) {
+            _completed[key] = image;
+          }
+          if (identical(_inFlight[key], slot.completer.future)) {
+            _inFlight.remove(key);
+          }
+          slot.completer.complete(image);
+        }
+      },
+      onError: (Object error, StackTrace stackTrace) {
+        for (final entry in slotByKey.entries) {
+          final key = entry.key;
+          final completer = entry.value.completer;
+          if (identical(_inFlight[key], completer.future)) {
+            _inFlight.remove(key);
+          }
+          completer.completeError(error, stackTrace);
+        }
+      },
+    );
+  }
+
+  /// Releases completed images owned by this game-scoped cache.
+  ///
+  /// In-flight batches cannot be cancelled. Their completion path observes the
+  /// disposed state, releases late images, and fails waiting callers.
+  void dispose() {
+    if (_isDisposed) return;
+    _isDisposed = true;
+    final uniqueImages = Set<RuntimeTilesetImage>.identity()
+      ..addAll(_completed.values);
+    _completed.clear();
+    for (final image in uniqueImages) {
+      image.dispose();
+    }
+  }
+}
+
+final class _RuntimeTilesetImageLoadSlot {
+  const _RuntimeTilesetImageLoadSlot({
+    required this.tilesetId,
+    required this.absolutePath,
+    required this.transparentColor,
+    required this.completer,
+  });
+
+  final String tilesetId;
+  final String absolutePath;
+  final TilesetTransparentColor? transparentColor;
+  final Completer<RuntimeTilesetImage?> completer;
+}
+
+final class _RuntimeTilesetImageCacheKey {
+  const _RuntimeTilesetImageCacheKey({
+    required this.normalizedAbsolutePath,
+    required this.transparentColor,
+  });
+
+  final String normalizedAbsolutePath;
+  final TilesetTransparentColor? transparentColor;
+
+  @override
+  bool operator ==(Object other) {
+    return identical(this, other) ||
+        other is _RuntimeTilesetImageCacheKey &&
+            normalizedAbsolutePath == other.normalizedAbsolutePath &&
+            transparentColor == other.transparentColor;
+  }
+
+  @override
+  int get hashCode => Object.hash(normalizedAbsolutePath, transparentColor);
+}
+
 Future<ui.Image> loadImageFromFilePath(String absolutePath) async {
   final file = File(absolutePath);
   if (!await file.exists()) {
@@ -14,8 +240,34 @@ Future<ui.Image> loadImageFromFilePath(String absolutePath) async {
   }
   final bytes = await file.readAsBytes();
   final codec = await ui.instantiateImageCodec(bytes);
-  final frame = await codec.getNextFrame();
-  return frame.image;
+  return decodeFirstFrameAndDispose(codec);
+}
+
+Future<ui.Image> decodeFirstFrameAndDispose(ui.Codec codec) async {
+  try {
+    final frame = await codec.getNextFrame();
+    return frame.image;
+  } finally {
+    codec.dispose();
+  }
+}
+
+Future<List<ui.Image>> decodeRuntimeTilesetChunks(
+  Iterable<Uint8List> encodedChunks, {
+  RuntimeUiImageDecoder decoder = _decodeUiImageFromBytes,
+}) async {
+  final images = <ui.Image>[];
+  try {
+    for (final bytes in encodedChunks) {
+      images.add(await decoder(bytes));
+    }
+    return images;
+  } catch (_) {
+    for (final image in images) {
+      image.dispose();
+    }
+    rethrow;
+  }
 }
 
 Future<RuntimeTilesetImage> loadTilesetImageFromFilePath(
@@ -63,8 +315,7 @@ Future<RuntimeTilesetImage> loadTilesetImageFromFilePath(
     );
   }
 
-  final images = <ui.Image>[];
-  for (final chunk in chunks) {
+  final images = await decodeRuntimeTilesetChunks(chunks.map((chunk) {
     final cropped = img.copyCrop(
       displayImage,
       x: 0,
@@ -73,8 +324,8 @@ Future<RuntimeTilesetImage> loadTilesetImageFromFilePath(
       height: chunk.height,
     );
     final chunkBytes = Uint8List.fromList(img.encodePng(cropped, level: 0));
-    images.add(await _decodeUiImageFromBytes(chunkBytes));
-  }
+    return chunkBytes;
+  }));
   return RuntimeTilesetImage(
     images: images,
     chunks: chunks,
@@ -112,20 +363,30 @@ img.Image _applyTransparentColor(
 
 Future<ui.Image> _decodeUiImageFromBytes(Uint8List bytes) async {
   final codec = await ui.instantiateImageCodec(bytes);
-  final frame = await codec.getNextFrame();
-  return frame.image;
+  return decodeFirstFrameAndDispose(codec);
 }
 
 Future<Map<String, RuntimeTilesetImage>> loadTilesetImagesById(
   Map<String, String> absolutePathByTilesetId, {
   Map<String, TilesetTransparentColor> transparentColorByTilesetId = const {},
+  RuntimeTilesetImageFileLoader? loader,
 }) async {
+  final load = loader ?? loadTilesetImageFromFilePath;
   final out = <String, RuntimeTilesetImage>{};
-  for (final e in absolutePathByTilesetId.entries) {
-    out[e.key] = await loadTilesetImageFromFilePath(
-      e.value,
-      transparentColor: transparentColorByTilesetId[e.key],
-    );
+  try {
+    for (final e in absolutePathByTilesetId.entries) {
+      out[e.key] = await load(
+        e.value,
+        transparentColor: transparentColorByTilesetId[e.key],
+      );
+    }
+    return out;
+  } catch (_) {
+    final uniqueImages = Set<RuntimeTilesetImage>.identity()
+      ..addAll(out.values);
+    for (final image in uniqueImages) {
+      image.dispose();
+    }
+    rethrow;
   }
-  return out;
 }
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
diff --git a/packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart b/packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart
index 194ac522e..7557408a0 100644
--- a/packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart
+++ b/packages/map_runtime/lib/src/presentation/flutter/battle_mobile_command_overlay.dart
@@ -1,4 +1,5 @@
 import 'dart:io';
+import 'dart:typed_data';
 
 import 'package:flutter/material.dart';
 import 'package:flutter/rendering.dart';
@@ -7,6 +8,9 @@ import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
 import 'battle_command_overlay_snapshot.dart';
 
 typedef BattleMobileItemIconBuilder = Widget Function(String imagePath);
+typedef BattleMobileItemIconBytesLoader = Future<Uint8List?> Function(
+  String imagePath,
+);
 
 /// Chrome battle Flutter rendue au-dessus du `GameWidget`.
 ///
@@ -1542,7 +1546,9 @@ class _BattleBagTile extends StatelessWidget {
                       child: KeyedSubtree(
                         key: Key('battle-mobile-entry-icon-${entry.index}'),
                         child: itemIconBuilder?.call(entry.iconAssetPath!) ??
-                            _BattleItemIcon(imagePath: entry.iconAssetPath!),
+                            BattleMobileItemIcon(
+                              imagePath: entry.iconAssetPath!,
+                            ),
                       ),
                     ),
                   Expanded(
@@ -1688,7 +1694,7 @@ class _BattleEntryTile extends StatelessWidget {
                                   'battle-mobile-entry-icon-${entry.index}'),
                               child:
                                   itemIconBuilder?.call(entry.iconAssetPath!) ??
-                                      _BattleItemIcon(
+                                      BattleMobileItemIcon(
                                         imagePath: entry.iconAssetPath!,
                                       ),
                             ),
@@ -1844,12 +1850,43 @@ class _BattleEntryTile extends StatelessWidget {
   }
 }
 
-class _BattleItemIcon extends StatelessWidget {
-  const _BattleItemIcon({
+class BattleMobileItemIcon extends StatefulWidget {
+  const BattleMobileItemIcon({
+    super.key,
     required this.imagePath,
+    this.bytesLoader = _loadBattleMobileItemIconBytes,
   });
 
   final String imagePath;
+  final BattleMobileItemIconBytesLoader bytesLoader;
+
+  @override
+  State<BattleMobileItemIcon> createState() => _BattleMobileItemIconState();
+}
+
+class _BattleMobileItemIconState extends State<BattleMobileItemIcon> {
+  late Future<Uint8List?> _imageBytesFuture;
+
+  @override
+  void initState() {
+    super.initState();
+    _imageBytesFuture = _loadImageBytes();
+  }
+
+  @override
+  void didUpdateWidget(covariant BattleMobileItemIcon oldWidget) {
+    super.didUpdateWidget(oldWidget);
+    if (oldWidget.imagePath != widget.imagePath ||
+        !identical(oldWidget.bytesLoader, widget.bytesLoader)) {
+      _imageBytesFuture = _loadImageBytes();
+    }
+  }
+
+  Future<Uint8List?> _loadImageBytes() {
+    return Future<Uint8List?>.sync(
+      () => widget.bytesLoader(widget.imagePath),
+    );
+  }
 
   @override
   Widget build(BuildContext context) {
@@ -1867,35 +1904,40 @@ class _BattleItemIcon extends StatelessWidget {
       );
     }
 
-    final imageBytes = () {
-      try {
-        final file = File(imagePath);
-        if (!file.existsSync()) {
-          return null;
-        }
-        return file.readAsBytesSync();
-      } catch (_) {
-        return null;
-      }
-    }();
-
     return ClipRRect(
       borderRadius: BorderRadius.circular(10),
       child: SizedBox(
         width: 32,
         height: 32,
-        child: imageBytes == null
-            ? buildFallback()
-            : Image.memory(
-                imageBytes,
-                fit: BoxFit.contain,
-                errorBuilder: (_, __, ___) => buildFallback(),
-              ),
+        child: FutureBuilder<Uint8List?>(
+          future: _imageBytesFuture,
+          builder: (context, snapshot) {
+            final imageBytes = snapshot.data;
+            if (snapshot.connectionState != ConnectionState.done ||
+                snapshot.hasError ||
+                imageBytes == null) {
+              return buildFallback();
+            }
+            return Image.memory(
+              imageBytes,
+              fit: BoxFit.contain,
+              errorBuilder: (_, __, ___) => buildFallback(),
+            );
+          },
+        ),
       ),
     );
   }
 }
 
+Future<Uint8List?> _loadBattleMobileItemIconBytes(String imagePath) async {
+  try {
+    return await File(imagePath).readAsBytes();
+  } catch (_) {
+    return null;
+  }
+}
+
 class _BattleCircleButton extends StatelessWidget {
   const _BattleCircleButton({
     super.key,
~~~~

## Annexe B — Contenu complet des fichiers créés

Les Evidence Packs ne s’auto-dupliquent pas. Tous les autres fichiers créés par ce lot sont
reproduits intégralement ci-dessous.

### `packages/map_runtime/test/battle_mobile_command_overlay_asset_loading_test.dart`

~~~~dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flutter/battle_mobile_command_overlay.dart';

Future<Uint8List> _pngBytes(ui.Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(2, 2);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

Widget _hostedIcon({
  required String imagePath,
  required BattleMobileItemIconBytesLoader bytesLoader,
}) {
  return MaterialApp(
    home: Center(
      child: BattleMobileItemIcon(
        key: const Key('item-icon'),
        imagePath: imagePath,
        bytesLoader: bytesLoader,
      ),
    ),
  );
}

void main() {
  testWidgets('keeps fallback while async bytes are pending then shows image',
      (tester) async {
    final imageBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFF55AAFF)),
    );
    final pending = Completer<Uint8List?>();
    var loadCount = 0;

    await tester.pumpWidget(
      _hostedIcon(
        imagePath: '/tmp/potion.png',
        bytesLoader: (_) {
          loadCount += 1;
          return pending.future;
        },
      ),
    );

    expect(loadCount, equals(1));
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    pending.complete(imageBytes!);
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('keeps fallback when async bytes loading fails', (tester) async {
    final pending = Completer<Uint8List?>();

    await tester.pumpWidget(
      _hostedIcon(
        imagePath: '/tmp/missing.png',
        bytesLoader: (_) => pending.future,
      ),
    );
    pending.completeError(StateError('missing'));
    await tester.pump();

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps fallback when async bytes loader returns null',
      (tester) async {
    var loadCount = 0;

    await tester.pumpWidget(
      _hostedIcon(
        imagePath: '/tmp/missing.png',
        bytesLoader: (_) async {
          loadCount += 1;
          return null;
        },
      ),
    );
    await tester.pump();

    expect(loadCount, equals(1));
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('path change ignores stale A after B finishes first',
      (tester) async {
    final aBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFFFF5533)),
    );
    final bBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFF3366FF)),
    );
    final pendingByPath = <String, Completer<Uint8List?>>{};
    final loadedPaths = <String>[];
    Future<Uint8List?> loader(String path) {
      loadedPaths.add(path);
      return (pendingByPath[path] ??= Completer<Uint8List?>()).future;
    }

    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/a.png', bytesLoader: loader),
    );
    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/b.png', bytesLoader: loader),
    );

    pendingByPath['/tmp/b.png']!.complete(bBytes!);
    await tester.pumpAndSettle();
    var image = tester.widget<Image>(find.byType(Image));
    expect((image.image as MemoryImage).bytes, same(bBytes));

    pendingByPath['/tmp/a.png']!.complete(aBytes!);
    await tester.pump();
    image = tester.widget<Image>(find.byType(Image));

    expect(loadedPaths, equals(<String>['/tmp/a.png', '/tmp/b.png']));
    expect((image.image as MemoryImage).bytes, same(bBytes));
  });

  testWidgets('path change replaces a displayed image with pending fallback',
      (tester) async {
    final aBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFFFF5533)),
    );
    final pendingB = Completer<Uint8List?>();
    final loadedPaths = <String>[];
    Future<Uint8List?> loader(String path) {
      loadedPaths.add(path);
      if (path == '/tmp/a.png') {
        return Future<Uint8List?>.value(aBytes);
      }
      return pendingB.future;
    }

    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/a.png', bytesLoader: loader),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/a.png', bytesLoader: loader),
    );
    expect(loadedPaths, equals(<String>['/tmp/a.png']));

    await tester.pumpWidget(
      _hostedIcon(imagePath: '/tmp/b.png', bytesLoader: loader),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('completion after unmount does not update disposed state',
      (tester) async {
    final imageBytes = await tester.runAsync(
      () => _pngBytes(const ui.Color(0xFF55AAFF)),
    );
    final pending = Completer<Uint8List?>();

    await tester.pumpWidget(
      _hostedIcon(
        imagePath: '/tmp/potion.png',
        bytesLoader: (_) => pending.future,
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(imageBytes!);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
~~~~

### `packages/map_runtime/test/playable_map_game_tileset_lifecycle_test.dart`

~~~~dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/application/runtime_player_pokemon_progression_hydrator.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('removal waits for the onLoad image handoff before disposal', () async {
    final imagesReady = Completer<void>();
    final releaseLoad = Completer<void>();
    RuntimeTilesetImage? loadedTileset;
    final game = PlayableMapGame(
      bundle: _bundle(),
      projectFilePath: '/tmp/tileset-lifecycle/project.json',
      runtimePlayerPokemonProgressionCatalogLoader: ({
        required gameState,
        required projectRootDirectory,
        required pokemonConfig,
      }) async {
        return const RuntimePlayerPokemonProgressionCatalogs(
          growthRateIdBySpeciesId: <String, String>{},
          maxPpByMoveId: <String, int>{},
        );
      },
      runtimeTilesetImageLoader: (
        absolutePathByTilesetId, {
        transparentColorByTilesetId = const <String, TilesetTransparentColor>{},
      }) async {
        final image = await _runtimeTilesetImage();
        loadedTileset = image;
        return <String, RuntimeTilesetImage>{'player': image};
      },
      afterInitialTilesetImagesLoaded: () async {
        imagesReady.complete();
        await releaseLoad.future;
      },
    );

    game.onGameResize(Vector2(128, 96));
    final load = game.onLoad();
    await imagesReady.future;

    game.onRemove();

    expect(loadedTileset!.debugDisposed, isFalse);
    releaseLoad.complete();
    await load;

    expect(loadedTileset!.debugDisposed, isTrue);
    expect(game.world.children, isEmpty);
  });
}

RuntimeMapBundle _bundle() {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Tileset lifecycle test',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'player',
          name: 'Player',
          relativePath: 'tilesets/player.png',
        ),
      ],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      characters: const <ProjectCharacterEntry>[
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 1,
          frameHeight: 2,
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
    ),
    map: const MapData(
      id: 'tileset-lifecycle-map',
      name: 'Tileset lifecycle map',
      size: GridSize(width: 4, height: 4),
      entities: <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/tileset-lifecycle',
    tilesetAbsolutePathsById: const <String, String>{
      'player': '/tmp/tileset-lifecycle/player.png',
    },
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 16, 32),
    ui.Paint()..color = const ui.Color(0xFF4060FF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(16, 32);
  picture.dispose();
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: 32, width: 16),
    ],
    width: 16,
    height: 32,
  );
}
~~~~

### `packages/map_runtime/test/tile_image_loader_codec_disposal_test.dart`

~~~~dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';

Future<Uint8List> _pngBytes() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xFF8844CC),
  );
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(2, 2);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

final class _TrackingCodec implements ui.Codec {
  _TrackingCodec(this.delegate);

  final ui.Codec delegate;
  int disposeCount = 0;

  @override
  int get frameCount => delegate.frameCount;

  @override
  int get repetitionCount => delegate.repetitionCount;

  @override
  Future<ui.FrameInfo> getNextFrame() => delegate.getNextFrame();

  @override
  void dispose() {
    disposeCount += 1;
    delegate.dispose();
  }
}

final class _FailingCodec implements ui.Codec {
  int disposeCount = 0;

  @override
  int get frameCount => 1;

  @override
  int get repetitionCount => 0;

  @override
  Future<ui.FrameInfo> getNextFrame() {
    return Future<ui.FrameInfo>.error(StateError('decode failed'));
  }

  @override
  void dispose() {
    disposeCount += 1;
  }
}

Future<ui.Image> _fakeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint()..color = const ui.Color(0xFF33AA77),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(2, 2);
  } finally {
    picture.dispose();
  }
}

RuntimeTilesetImage _runtimeImage(ui.Image image) {
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: image.height, width: image.width),
    ],
    width: image.width,
    height: image.height,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decodeFirstFrameAndDispose disposes codec after success', () async {
    final codec = _TrackingCodec(
      await ui.instantiateImageCodec(await _pngBytes()),
    );

    final image = await decodeFirstFrameAndDispose(codec);

    expect(codec.disposeCount, equals(1));
    expect(image.debugDisposed, isFalse);
    image.dispose();
  });

  test('decodeFirstFrameAndDispose disposes codec after decode error',
      () async {
    final codec = _FailingCodec();

    await expectLater(
      decodeFirstFrameAndDispose(codec),
      throwsStateError,
    );

    expect(codec.disposeCount, equals(1));
  });

  test('chunk decode failure disposes images from earlier chunks', () async {
    final firstImage = await _fakeImage();
    addTearDown(() {
      if (!firstImage.debugDisposed) {
        firstImage.dispose();
      }
    });
    var decodeCount = 0;

    await expectLater(
      decodeRuntimeTilesetChunks(
        <Uint8List>[Uint8List(1), Uint8List(1)],
        decoder: (_) async {
          decodeCount += 1;
          if (decodeCount == 1) {
            return firstImage;
          }
          throw StateError('later chunk failed');
        },
      ),
      throwsStateError,
    );

    expect(firstImage.debugDisposed, isTrue);
  });

  test('batch file load failure disposes tilesets loaded earlier', () async {
    final firstImage = await _fakeImage();
    addTearDown(() {
      if (!firstImage.debugDisposed) firstImage.dispose();
    });
    var loadCount = 0;

    await expectLater(
      loadTilesetImagesById(
        const <String, String>{
          'first': '/tmp/first.png',
          'second': '/tmp/second.png',
        },
        loader: (
          path, {
          transparentColor,
        }) async {
          loadCount += 1;
          if (loadCount == 1) return _runtimeImage(firstImage);
          throw StateError('later tileset failed');
        },
      ),
      throwsStateError,
    );

    expect(firstImage.debugDisposed, isTrue);
  });

  test('single-flight cache dispose releases completed images once', () async {
    final image = await _fakeImage();
    addTearDown(() {
      if (!image.debugDisposed) image.dispose();
    });
    final runtimeImage = _runtimeImage(image);
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async =>
          <String, RuntimeTilesetImage>{paths.keys.single: runtimeImage},
    );
    await cache.loadById(
      const <String, String>{'water': '/tmp/water.png'},
    );

    cache.dispose();
    cache.dispose();

    expect(image.debugDisposed, isTrue);
    await expectLater(
      cache.loadById(
        const <String, String>{'water': '/tmp/water.png'},
      ),
      throwsStateError,
    );
  });

  test('cache disposed in flight releases the late image', () async {
    final image = await _fakeImage();
    addTearDown(() {
      if (!image.debugDisposed) image.dispose();
    });
    final runtimeImage = _runtimeImage(image);
    final load = Completer<Map<String, RuntimeTilesetImage>>();
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) =>
          load.future,
    );
    final pending = cache.loadById(
      const <String, String>{'water': '/tmp/water.png'},
    );

    cache.dispose();
    load.complete(<String, RuntimeTilesetImage>{'water': runtimeImage});

    await expectLater(pending, throwsStateError);
    expect(image.debugDisposed, isTrue);
  });
}
~~~~

### `packages/map_runtime/test/tile_image_loader_singleflight_test.dart`

~~~~dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';

Future<RuntimeTilesetImage> _fakeRuntimeTilesetImage(ui.Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(4, 4);
    final runtimeImage = RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: const <RuntimeTilesetChunk>[
        RuntimeTilesetChunk(top: 0, height: 4, width: 4),
      ],
      width: 4,
      height: 4,
    );
    addTearDown(() {
      if (!runtimeImage.debugDisposed) {
        runtimeImage.dispose();
      }
    });
    return runtimeImage;
  } finally {
    picture.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('overlapping callers share normalized paths and preserve batch load',
      () async {
    final batchCompleter = Completer<Map<String, RuntimeTilesetImage>>();
    final requestedBatches = <Map<String, String>>[];
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) {
        requestedBatches.add(Map<String, String>.of(paths));
        return batchCompleter.future;
      },
    );

    final firstFuture = cache.loadById(<String, String>{
      'water': '/tmp/project/tilesets/water.png',
      'grass': '/tmp/project/tilesets/grass.png',
    });
    final aliasFuture = cache.loadById(<String, String>{
      'waterAlias': '/tmp/project/tilesets/./water.png',
    });
    final thirdFuture = cache.loadById(<String, String>{
      'thirdWaterAlias': '/tmp/project/tilesets/../tilesets/water.png',
    });

    expect(
      requestedBatches,
      equals(<Map<String, String>>[
        <String, String>{
          'water': '/tmp/project/tilesets/water.png',
          'grass': '/tmp/project/tilesets/grass.png',
        },
      ]),
    );

    final water = await _fakeRuntimeTilesetImage(const ui.Color(0xFF3366FF));
    final grass = await _fakeRuntimeTilesetImage(const ui.Color(0xFF33AA55));
    batchCompleter.complete(<String, RuntimeTilesetImage>{
      'water': water,
      'grass': grass,
    });

    final first = await firstFuture;
    final alias = await aliasFuture;
    final third = await thirdFuture;
    expect(identical(first['water'], water), isTrue);
    expect(identical(first['grass'], grass), isTrue);
    expect(identical(alias['waterAlias'], water), isTrue);
    expect(identical(third['thirdWaterAlias'], water), isTrue);
  });

  test('ids sharing one key inside a batch converge on one loader id',
      () async {
    Map<String, String>? requestedPaths;
    final water = await _fakeRuntimeTilesetImage(const ui.Color(0xFF3366FF));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        requestedPaths = Map<String, String>.of(paths);
        return <String, RuntimeTilesetImage>{paths.keys.single: water};
      },
    );

    final result = await cache.loadById(<String, String>{
      'water': '/tmp/project/tilesets/water.png',
      'waterAlias': '/tmp/project/tilesets/./water.png',
    });

    expect(
      requestedPaths,
      equals(<String, String>{
        'water': '/tmp/project/tilesets/water.png',
      }),
    );
    expect(identical(result['water'], water), isTrue);
    expect(identical(result['waterAlias'], water), isTrue);
  });

  test('same path with different transparent colors uses distinct cache keys',
      () async {
    final redImage = await _fakeRuntimeTilesetImage(const ui.Color(0xFFFF0000));
    final blueImage =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF0000FF));
    Map<String, TilesetTransparentColor>? requestedColors;
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        requestedColors = Map<String, TilesetTransparentColor>.of(
          transparentColorByTilesetId,
        );
        return <String, RuntimeTilesetImage>{
          'red': redImage,
          'blue': blueImage,
        };
      },
    );
    final red = TilesetTransparentColor(red: 255, green: 0, blue: 0);
    final blue = TilesetTransparentColor(red: 0, green: 0, blue: 255);

    final result = await cache.loadById(
      <String, String>{
        'red': '/tmp/project/tilesets/shared.png',
        'blue': '/tmp/project/tilesets/shared.png',
      },
      transparentColorByTilesetId: <String, TilesetTransparentColor>{
        'red': red,
        'blue': blue,
      },
    );

    expect(
        requestedColors,
        equals(<String, TilesetTransparentColor>{
          'red': red,
          'blue': blue,
        }));
    expect(identical(result['red'], redImage), isTrue);
    expect(identical(result['blue'], blueImage), isTrue);
  });

  test('omitted ids stay omitted and are retried by a later request', () async {
    var loadCount = 0;
    final recovered =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF22CC88));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        loadCount += 1;
        if (loadCount == 1) {
          return const <String, RuntimeTilesetImage>{};
        }
        return <String, RuntimeTilesetImage>{'water': recovered};
      },
    );

    final omitted = await cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );
    final retried = await cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );

    expect(omitted, isEmpty);
    expect(loadCount, equals(2));
    expect(identical(retried['water'], recovered), isTrue);
  });

  test('partial batch success caches success and retries only omitted id',
      () async {
    final loaded = await _fakeRuntimeTilesetImage(const ui.Color(0xFF44AA66));
    final recovered =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFFAA6644));
    final requestedBatches = <Map<String, String>>[];
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        requestedBatches.add(Map<String, String>.of(paths));
        if (requestedBatches.length == 1) {
          return <String, RuntimeTilesetImage>{'loaded': loaded};
        }
        return <String, RuntimeTilesetImage>{'missing': recovered};
      },
    );

    final first = await cache.loadById(const <String, String>{
      'loaded': '/tmp/project/loaded.png',
      'missing': '/tmp/project/missing.png',
    });
    final second = await cache.loadById(const <String, String>{
      'loaded': '/tmp/project/loaded.png',
      'missing': '/tmp/project/missing.png',
    });

    expect(first.keys, orderedEquals(<String>['loaded']));
    expect(
      requestedBatches,
      equals(<Map<String, String>>[
        <String, String>{
          'loaded': '/tmp/project/loaded.png',
          'missing': '/tmp/project/missing.png',
        },
        <String, String>{'missing': '/tmp/project/missing.png'},
      ]),
    );
    expect(identical(second['loaded'], loaded), isTrue);
    expect(identical(second['missing'], recovered), isTrue);
  });

  test('disposes loader images returned for ids outside the requested batch',
      () async {
    final requested =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF3366AA));
    final extraneous =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFFAA6633));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        return <String, RuntimeTilesetImage>{
          paths.keys.single: requested,
          'not-requested': extraneous,
        };
      },
    );

    final result = await cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );

    expect(identical(result['water'], requested), isTrue);
    expect(requested.debugDisposed, isFalse);
    expect(extraneous.debugDisposed, isTrue);
    cache.dispose();
  });

  test('equivalent RGB values share the transparent-color cache key', () async {
    var loadCount = 0;
    final image = await _fakeRuntimeTilesetImage(const ui.Color(0xFF778899));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) async {
        loadCount += 1;
        return <String, RuntimeTilesetImage>{paths.keys.single: image};
      },
    );

    final first = await cache.loadById(
      const <String, String>{'first': '/tmp/project/shared.png'},
      transparentColorByTilesetId: <String, TilesetTransparentColor>{
        'first': TilesetTransparentColor(red: 12, green: 34, blue: 56),
      },
    );
    final second = await cache.loadById(
      const <String, String>{'second': '/tmp/project/shared.png'},
      transparentColorByTilesetId: <String, TilesetTransparentColor>{
        'second': TilesetTransparentColor(red: 12, green: 34, blue: 56),
      },
    );

    expect(loadCount, equals(1));
    expect(identical(first['first'], image), isTrue);
    expect(identical(second['second'], image), isTrue);
  });

  test('batch errors are shared by concurrent callers and allow retry',
      () async {
    final failedBatch = Completer<Map<String, RuntimeTilesetImage>>();
    final recovered =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFFFFAA33));
    var loadCount = 0;
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) {
        loadCount += 1;
        if (loadCount == 1) {
          return failedBatch.future;
        }
        return Future<Map<String, RuntimeTilesetImage>>.value(
          <String, RuntimeTilesetImage>{'retry': recovered},
        );
      },
    );

    final first = cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );
    final overlapping = cache.loadById(
      const <String, String>{
        'waterAlias': '/tmp/project/./water.png',
      },
    );
    final firstExpectation = expectLater(first, throwsStateError);
    final overlappingExpectation = expectLater(overlapping, throwsStateError);
    failedBatch.completeError(StateError('decode failed'));

    await Future.wait<void>(<Future<void>>[
      firstExpectation,
      overlappingExpectation,
    ]);
    final retried = await cache.loadById(
      const <String, String>{'retry': '/tmp/project/water.png'},
    );

    expect(loadCount, equals(2));
    expect(identical(retried['retry'], recovered), isTrue);
  });

  test('synchronous loader errors do not poison later retries', () async {
    var loadCount = 0;
    final recovered =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFFCC8844));
    final cache = RuntimeTilesetImageSingleFlightCache(
      loader: (
        paths, {
        transparentColorByTilesetId = const {},
      }) {
        loadCount += 1;
        if (loadCount == 1) {
          throw StateError('synchronous failure');
        }
        return Future<Map<String, RuntimeTilesetImage>>.value(
          <String, RuntimeTilesetImage>{paths.keys.single: recovered},
        );
      },
    );

    await expectLater(
      cache.loadById(
        const <String, String>{'water': '/tmp/project/water.png'},
      ),
      throwsStateError,
    );
    final retry = await cache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );

    expect(loadCount, equals(2));
    expect(identical(retry['water'], recovered), isTrue);
  });

  test('a fresh cache instance reloads the same image path', () async {
    var loadCount = 0;
    final firstImage =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF112233));
    final secondImage =
        await _fakeRuntimeTilesetImage(const ui.Color(0xFF445566));

    Future<Map<String, RuntimeTilesetImage>> loader(
      Map<String, String> paths, {
      Map<String, TilesetTransparentColor> transparentColorByTilesetId =
          const {},
    }) async {
      loadCount += 1;
      return <String, RuntimeTilesetImage>{
        paths.keys.single: loadCount == 1 ? firstImage : secondImage,
      };
    }

    final firstCache = RuntimeTilesetImageSingleFlightCache(loader: loader);
    final first = await firstCache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );
    final reloadedCache = RuntimeTilesetImageSingleFlightCache(loader: loader);
    final reloaded = await reloadedCache.loadById(
      const <String, String>{'water': '/tmp/project/water.png'},
    );

    expect(loadCount, equals(2));
    expect(identical(first['water'], firstImage), isTrue);
    expect(identical(reloaded['water'], secondImage), isTrue);
  });
}
~~~~

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-01-runtime-asset-ownership.md`

~~~~markdown
# PERF-RM-01 — Plan d'implémentation assets runtime

**Scope :** single-flight des tilesets par `(absolutePath, transparentColor)`, ownership des codecs et chargement asynchrone des icônes de sac battle. Aucun changement de format projet, de sémantique authoring ou de rendu attendu.

## Audit initial

- `PlayableMapGame._loadTilesetImagesCached` ne mémorise que les résultats terminés : deux callers concurrents peuvent charger la même clé.
- `tile_image_loader.dart` crée des codecs sans `dispose()`.
- `_BattleItemIcon.build` appelle `existsSync` puis `readAsBytesSync`.
- `BattleFxBundleCache` fournit le pattern local de future en vol avec éviction après erreur.

## Étapes test-first

- [ ] Ajouter `tile_image_loader_singleflight_test.dart` : N callers identiques, couleurs distinctes, chemins distincts, erreur puis retry, fermeture/reload.
- [ ] Exécuter le test et conserver l'échec RED dû à l'API/cache absent.
- [ ] Introduire un cache runtime possédé et borné au cycle de vie de `PlayableMapGame`, clé valeur `(path, transparentColor)` ; stocker la future avant le premier `await`, évincer uniquement la future identique en échec, conserver le résultat réussi.
- [ ] Faire charger chaque clé manquante indépendamment pour que des ids différents partageant le même chemin convergent vers la même future.
- [ ] Ajouter `try/finally { codec.dispose(); }` sur chaque codec créé, sans disposer l'image remise au caller.
- [ ] Ajouter `battle_mobile_command_overlay_asset_loading_test.dart` : le premier build n'exécute pas de lecture, succès async, fichier absent/erreur, changement de chemin recharge.
- [ ] Exécuter le test et conserver l'échec RED sur le loader asynchrone absent.
- [ ] Convertir l'icône privée en widget stateful possédant une seule future par chemin ; effectuer `File.exists/readAsBytes` uniquement hors `build`, exprimer loading/error par le fallback existant.
- [ ] Relancer tests ciblés, suite `map_runtime`, analyseur, smoke host.

## Non-objectifs et risques

- Pas de cache global, LRU cross-project, watcher de fichier ni nouvelle API authoring.
- Les `ui.Image` restent détenues par le runtime ; seule la ressource codec temporaire est fermée.
- Le cache doit distinguer strictement la couleur transparente et ne jamais retenir une erreur.

## Preuves attendues

- Un seul appel loader pour N appels concurrents identiques ; retry après erreur.
- Recherche source : aucun `existsSync/readAsBytesSync` dans l'overlay.
- Tests visuels/battle existants inchangés.
~~~~
