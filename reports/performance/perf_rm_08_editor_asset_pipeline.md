# Evidence Pack — PERF-RM-08 Pipeline d’assets éditeur

Date d’exécution : 1–2 août 2026 (Europe/Paris)
Branche / base : `main` à `1f5f4da3d`
Verdict : **DONE proposé (consolidé)** — cache projet, ownership et trois profils macOS dédiés prouvés ; mémoire native exacte déclarée indisponible.

> Consolidation finale du 2 août 2026 : trois processus
> `flutter drive --profile -d macos` couvrent chacun 100 éléments logiques issus
> de 10 tilesets partagés, 8 demandeurs concurrents, 10 erreurs et 10 cycles A/B.
> La croissance RSS stabilisée est de 6 848 512 (3,52 %), 7 077 888 (3,64 %)
> et 1 048 576 octets (0,52 %), donc chaque run respecte simultanément 50 Mio
> et 10 %. Les frame timings restent observationnels comme annoncé. Le partage
> de source, la propagation explicite de la racine/cache, le reload même chemin
> et la libération des leases Path/Tileset ont été ajoutés après la revue. Cette
> section et le rapport consolidé prévalent sur le verdict historique ci-dessous.

## Audit initial et objectif

La passe d’audit indépendante a confirmé que `EditorImageCache` était la bonne base, mais sans budget pondéré, crops partagés ni ownership sûr. Quatre consommateurs exécutaient encore des variantes de `File.*Sync`, decode/crop/encode ou cache statique depuis leurs chemins de rendu : vignettes Environment, Path Studio info/picker/panel et canvas Tileset Editor.

Le lot devait supprimer ces travaux synchrones de `build`, garantir single-flight par source/révision, pondérer le LRU en octets décodés et maintenir les images en vie tant qu’un consommateur les peint.

## Implémentation et zones modifiées

| Fichier | Zone | Changement |
|---|---|---|
| `packages/map_editor/lib/src/ui/assets/editor_image_cache.dart:75-672` | cache central | Budget 32 MiB RGBA, LRU pondéré, single-flight, crops, revision keys, leases, retry, oversize non retenu et diagnostics. |
| `packages/map_editor/lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart:15-160` | vignette | `ConsumerStatefulWidget`, `loadCrop`, loading/error/succès tokenisés, rejet des complétions stale et cleanup lease. |
| `packages/map_editor/lib/src/features/path_studio/path_pattern_tileset_image_info_loader.dart` | métadonnées | Chargement async via cache central, sans I/O synchrone. |
| `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart` | état panel | Read model async indexé par root et propriétés tileset. |
| `packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart` | previews | `ui.Image` louée et source rect ; suppression decode→crop→encode→`Image.memory`. |
| `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart:17` | canvas | Suppression du cache statique path-only, provider projet et lifecycle de lease. |
| tests ciblés existants | gardes | Single-flight, eviction, stale completion, erreurs, accessibilité et interdiction des anciens chemins synchrones. |

Fichiers créés :

- `packages/map_editor/test/environment_studio/environment_element_thumbnail_async_test.dart`
- `packages/map_editor/benchmark/editor_asset_cache_profile_test.dart`
- `reports/performance/plans/2026-08-01-pokemap-perf-rm-08-editor-asset-pipeline.md`

## Résultats

Profil Flutter test : 100 assets, 8 demandeurs concurrents, erreurs, deux projets et 10 cycles, trois processus :

| Run | Temps | Croissance RSS |
|---:|---:|---:|
| 1 | 1 246 623 µs | 16 744 448 octets |
| 2 | 764 643 µs | 10 108 928 octets |
| 3 | 769 560 µs | 15 056 896 octets |

Chaque run finit avec `residentDecodedBytes=32768`, `maximumDecodedBytes=32768`, 32 entrées, pic transitoire 33 792 octets, 968 évictions, `inFlight=0`, 10 fichiers manquants attendus et une entrée isolée dans le second cache. La croissance RSS reste sous 20 MiB, donc sous le budget idéal et très loin de la sortie acceptable 50 MiB.

## Vérifications exactes

```text
cd packages/map_editor
flutter test <9 fichiers ciblés cache/environment/path/tileset>
=> exit 0 ; +121 ; All tests passed!

flutter test test/design_system_guardrail_test.dart
=> exit 0 ; +12 ; All tests passed!

flutter analyze
=> exit 0 ; No issues found!

flutter build macos --debug
=> exit 0 ; Built build/macos/Build/Products/Debug/PokeMap.app
=> avertissements tiers uniquement : video_player_avfoundation / API AVFoundation dépréciée
```

Le premier passage du garde design-system a détecté une nouvelle référence directe à `CupertinoColors.separator`; elle a été remplacée par `context.pokeMapColors.divider`, puis le garde est passé. Un info analyzer `use_super_parameters` dans le helper de test a également été corrigé avant l’analyse finale verte.

MCP parity : `N/A` sémantique. Le lot ne modifie ni modèle projet, action, validation, import/export ni format persistant ; la régression globale MCP a néanmoins été rejouée avec les lots RM-09A/B.

## État Git, non-objectifs et risques

Les cinq fichiers world-map déjà modifiés avant la phase ont été exclus de ce lot et conservés. Le `__pycache__` initial n’a pas été touché. Aucune écriture Git n’a été faite.

Non-objectifs respectés : pas de cache global supplémentaire, pas de partage runtime, pas de limite par nombre d’entrées, pas de préchargement intégral et aucun type Flutter ajouté à `map_core`.

Auto-critique : le harness mesure correctement ownership, RSS et diagnostics, mais tourne sous `flutter test` debug/JIT. Il ne fournit ni frame timings d’un vrai journey macOS profile, ni native-memory instrumentée. Le code et les tests satisfont les invariants ; le statut reste `PARTIAL` jusqu’à cette calibration plateforme.

## État Git final consolidé

`main@1f5f4da3d` ; 48 fichiers suivis modifiés au total (43 de phase, 5 world-map hors phase) et 25 fichiers non suivis (24 de phase, 1 `__pycache__` hors phase). `git diff --check` ne produit aucune erreur ; les fichiers Dart de phase passent `dart format --output=none --set-exit-if-changed` (`57 files`, `0 changed`).

## Annexe — contenu complet des fichiers créés

### `packages/map_editor/test/environment_studio/environment_element_thumbnail_async_test.dart`

````dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/widgets/environment_element_thumbnail.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows loading and ignores a stale A to B completion',
      (tester) async {
    final firstImage = await tester.runAsync(() => _image(1, 1));
    final secondImage = await tester.runAsync(() => _image(2, 1));
    addTearDown(firstImage!.dispose);
    addTearDown(secondImage!.dispose);
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);

    await tester.pumpWidget(
      _app(
        cache: cache,
        path: '/project/a.png',
        widgetKey: const Key('thumbnail'),
      ),
    );
    expect(
      find.byKey(const Key('environment-element-thumbnail-loading')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _app(
        cache: cache,
        path: '/project/b.png',
        widgetKey: const Key('thumbnail'),
      ),
    );
    final current = EditorImageLoadResult.success(secondImage.clone());
    cache.complete('/project/b.png', current);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('preview')), findsOneWidget);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 2);

    final stale = EditorImageLoadResult.success(firstImage.clone());
    cache.complete('/project/a.png', stale);
    await tester.pump();
    await tester.pump();

    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 2);
    expect(stale.image!.debugDisposed, isTrue);
  });

  testWidgets('renders the fallback after a typed missing-file result',
      (tester) async {
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);
    const path = '/project/missing.png';

    await tester.pumpWidget(_app(cache: cache, path: path));
    cache.complete(
      path,
      const EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.missingFile,
          path: path,
          message: 'missing',
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('fallback')), findsOneWidget);
    expect(find.byKey(const Key('preview')), findsNothing);
  });
}

Widget _app({
  required _QueuedImageCache cache,
  required String path,
  Key? widgetKey,
}) {
  return CupertinoApp(
    home: CupertinoPageScaffold(
      child: EnvironmentElementThumbnail(
        key: widgetKey,
        manifest: _manifest,
        element: _element,
        elementId: _element.id,
        resolveTilesetPathById: (_) => path,
        imageCache: cache,
        previewKey: const Key('preview'),
        fallbackKey: const Key('fallback'),
      ),
    ),
  );
}

Future<ui.Image> _image(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xff55aa55),
  );
  final picture = recorder.endRecording();
  try {
    return await picture.toImage(width, height);
  } finally {
    picture.dispose();
  }
}

final class _QueuedImageCache extends EditorImageCache {
  _QueuedImageCache()
      : super(
          sessionKey: 'environment-thumbnail-test',
          retirementScheduler: (disposeImage) => disposeImage(),
        );

  final Map<String, Completer<EditorImageLoadResult>> _requests = {};

  @override
  Future<EditorImageLoadResult> loadCrop(
    String? path, {
    required ui.Rect sourceRect,
    String variantKey = 'original',
    EditorImageBytesTransform? transformBytes,
  }) {
    return (_requests[path!] ??= Completer<EditorImageLoadResult>()).future;
  }

  void complete(String path, EditorImageLoadResult result) {
    _requests[path]!.complete(result);
  }
}

const _manifest = ProjectManifest(
  name: 'Environment thumbnail',
  settings: ProjectSettings(tileWidth: 1, tileHeight: 1),
  maps: [],
  tilesets: [
    ProjectTilesetEntry(
      id: 'tiles',
      name: 'Tiles',
      relativePath: 'tiles.png',
    ),
  ],
);

const _element = ProjectElementEntry(
  id: 'grass',
  name: 'Grass',
  tilesetId: 'tiles',
  categoryId: 'nature',
  frames: [
    TilesetVisualFrame(
      tilesetId: 'tiles',
      source: TilesetSourceRect(x: 0, y: 0),
    ),
  ],
);
````

### `packages/map_editor/benchmark/editor_asset_cache_profile_test.dart`

````dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profiles 100 assets across duplicates failures and ten cycles',
      (tester) async {
    final receipt = await tester.runAsync(() async {
      final sandbox = await Directory.systemTemp.createTemp(
        'pokemap_editor_asset_profile_',
      );
      try {
        final roots = <Directory>[
          await Directory('${sandbox.path}/project_a').create(),
          await Directory('${sandbox.path}/project_b').create(),
        ];
        final paths = <String>[];
        for (var index = 0; index < 100; index++) {
          final path = '${roots.first.path}/asset_$index.png';
          await File(path).writeAsBytes(_png(index), flush: true);
          paths.add(path);
        }

        const budget = 32 * 1024;
        final cache = EditorImageCache(
          sessionKey: roots.first.path,
          maximumDecodedBytes: budget,
          retirementScheduler: _disposeImmediately,
        );
        final otherProjectCache = EditorImageCache(
          sessionKey: roots.last.path,
          maximumDecodedBytes: budget,
          retirementScheduler: _disposeImmediately,
        );
        final rssBefore = ProcessInfo.currentRss;
        final stopwatch = Stopwatch()..start();

        final duplicates = await Future.wait([
          for (var index = 0; index < 8; index++) cache.load(paths.first),
        ]);
        for (final result in duplicates) {
          expect(result.image, isNotNull);
          result.dispose();
        }

        final rssByCycle = <int>[];
        for (var cycle = 0; cycle < 10; cycle++) {
          for (final path in paths) {
            final result = await cache.load(path);
            expect(result.image, isNotNull);
            result.dispose();
          }
          final missing = await cache.load(
            '${roots.first.path}/missing_$cycle.png',
          );
          expect(
            missing.failure?.kind,
            EditorImageFailureKind.missingFile,
          );
          rssByCycle.add(ProcessInfo.currentRss);
        }

        final isolated = await otherProjectCache.load(paths.first);
        expect(isolated.image, isNotNull);
        isolated.dispose();
        stopwatch.stop();

        final diagnostics = cache.diagnostics;
        expect(diagnostics.residentDecodedBytes, lessThanOrEqualTo(budget));
        expect(diagnostics.inFlightLoads, 0);
        expect(diagnostics.evictions, greaterThan(0));
        expect(diagnostics.missingFiles, 10);
        expect(otherProjectCache.diagnostics.entries, 1);

        final result = <String, Object?>{
          'schemaVersion': 1,
          'benchmark': 'editor_asset_cache',
          'assets': paths.length,
          'duplicateCallers': duplicates.length,
          'cycles': 10,
          'elapsedUs': stopwatch.elapsedMicroseconds,
          'rssBeforeBytes': rssBefore,
          'rssAfterBytes': ProcessInfo.currentRss,
          'rssByCycleBytes': rssByCycle,
          'cache': _diagnosticsJson(diagnostics),
          'otherProjectCache': _diagnosticsJson(otherProjectCache.diagnostics),
        };
        cache.dispose();
        otherProjectCache.dispose();
        return result;
      } finally {
        await sandbox.delete(recursive: true);
      }
    });

    // Keep one machine-readable line for the Evidence Pack runner.
    // ignore: avoid_print
    print(jsonEncode(receipt));
  }, timeout: const Timeout(Duration(minutes: 2)));
}

Uint8List _png(int seed) {
  final image = img.Image(width: 16, height: 16);
  img.fill(
    image,
    color: img.ColorRgba8(
      seed % 255,
      (seed * 3) % 255,
      (seed * 7) % 255,
      255,
    ),
  );
  return Uint8List.fromList(img.encodePng(image));
}

Map<String, Object?> _diagnosticsJson(
  EditorImageCacheDiagnostics diagnostics,
) =>
    {
      'entries': diagnostics.entries,
      'hits': diagnostics.hits,
      'misses': diagnostics.misses,
      'invalidations': diagnostics.invalidations,
      'missingFiles': diagnostics.missingFiles,
      'decodeFailures': diagnostics.decodeFailures,
      'disposedImages': diagnostics.disposedImages,
      'maximumDecodedBytes': diagnostics.maximumDecodedBytes,
      'residentDecodedBytes': diagnostics.residentDecodedBytes,
      'peakDecodedBytes': diagnostics.peakDecodedBytes,
      'evictions': diagnostics.evictions,
      'inFlightLoads': diagnostics.inFlightLoads,
    };

void _disposeImmediately(void Function() disposeImage) => disposeImage();
````

### `reports/performance/plans/2026-08-01-pokemap-perf-rm-08-editor-asset-pipeline.md`

````markdown
# PERF-RM-08 Editor Asset Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` or `executing-plans` task by task. Every behavior change follows red → green → refactor.

**Goal:** Remove synchronous image I/O/decode from editor build paths and bound project-scoped decoded image memory with safe leases and revision-aware LRU eviction.

**Architecture:** Extend the existing `EditorImageCache`; do not create another global cache. One project-scoped service owns async metadata/read/decode, full sources and crops, single-flight futures, decoded-byte accounting, and post-frame retirement. Widgets own cloned consumer handles and render design-system loading/error states.

**Tech Stack:** Flutter `dart:ui`, Riverpod family provider, PokeMap design system, widget tests and macOS profile driver.

---

### Task 1: Characterize cache ownership and weighted eviction

**Files:**
- Modify: `packages/map_editor/test/editor_image_cache_test.dart`

- [ ] Add injected gated file probe, byte reader, decoder, and cropper; assert two concurrent callers perform each stage once.
- [ ] Add weighted A/B/touch-A/C LRU, oversize non-retention, safe acquired clone after eviction, failure retry, same-path revision replacement, crop single-flight, in-flight dispose, and project isolation cases.
- [ ] Assert `residentDecodedBytes <= maximumDecodedBytes`, peak bytes, evictions, and in-flight counts.
- [ ] Run the focused test and retain the expected red failures before production changes.

### Task 2: Extend the one canonical editor cache

**Files:**
- Modify: `packages/map_editor/lib/src/ui/assets/editor_image_cache.dart`
- Modify: `packages/map_editor/lib/src/app/providers/editor/editor_asset_cache_providers.dart`

- [ ] Add injectable async file/decode seams whose defaults use `File` and `ui.instantiateImageCodec` with codec disposal in `finally`.
- [ ] Add a 32 MiB initial decoded-byte budget, insertion-ordered LRU touch, `width * height * 4` weights, and diagnostics.
- [ ] Add `loadCrop` backed by the same source master and cache budget.
- [ ] Track pending acquisitions so eviction/invalidations never dispose a master before all waiting consumers clone it.
- [ ] Serve an entry larger than the budget once without retaining it; remove failed futures so retry remains possible.

### Task 3: Make Environment thumbnails fully async

**Files:**
- Modify: `packages/map_editor/lib/src/features/environment_studio/widgets/environment_element_thumbnail.dart`
- Modify wiring only where a project root/cache must be supplied in `packages/map_editor/lib/src/features/environment_studio/widgets/`
- Create: `packages/map_editor/test/environment_studio/environment_element_thumbnail_async_test.dart`

- [ ] Replace `existsSync`, `readAsBytesSync`, `img.decodeImage`, `copyCrop`, pixel painter, and the static crop cache with `EditorImageCache.loadCrop`.
- [ ] Hold/release one lease per displayed result and ignore/release late results after widget updates.
- [ ] Render tokenized loading, missing/decode error, and success states with accessible semantics.
- [ ] Test slow read/decode, success, error, stale A→B completion, rebuild single-flight, and disposal.

### Task 4: Make Path Studio loaders and previews async

**Files:**
- Modify: `packages/map_editor/lib/src/features/path_studio/path_pattern_tileset_image_info_loader.dart`
- Modify: `packages/map_editor/lib/src/features/path_studio/path_studio_tileset_image_picker.dart`
- Modify: `packages/map_editor/lib/src/features/path_studio/path_studio_panel.dart`
- Modify: `packages/map_editor/test/path_pattern/path_studio_tileset_image_picker_test.dart`
- Create focused loader/panel tests beside the existing Path Studio tests.

- [ ] Stop calling the image-info loader synchronously from `build`; expose an async read model keyed by project root plus tileset revisions.
- [ ] Derive dimensions from the central decoded image, not `package:image` on the UI isolate.
- [ ] Include transparent color in the variant key and offload any required PNG transform before decode.
- [ ] Paint full/tile previews from leased `ui.Image` source rects; remove decode→crop→encode→`Image.memory` cycles from `build`.
- [ ] Cover missing root/file, invalid grid, loading, transparent variant, late result, file revision, and lease cleanup.

### Task 5: Remove the Tileset Editor static cache

**Files:**
- Modify: `packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart`
- Add or modify its focused widget test.

- [ ] Replace `_TilesetEditorImageCache` with `editorImageCacheProvider(projectRoot)` and a state owner for its consumer lease.
- [ ] Distinguish loading from typed error, invalidate on file revision, and release the old image after handoff.
- [ ] Delete the static path-only future map and prove the codec and images are retired.

### Task 6: Profile and regress the shared cache

- [ ] Re-run palette/world-map async-order tests because they already consume `EditorImageCache`.
- [ ] Add a profile journey for 100 assets, duplicates, failures, project switch, and ten cycles; capture frame timings, cache diagnostics, RSS, and native memory in three runs.
- [ ] Require zero synchronous I/O/decode in `build`, one decode per source/revision in flight, safe eviction, non-stale previews, and stabilized growth at most 50 MiB or 10%.

**Verification:**

```bash
cd packages/map_editor && flutter test test/editor_image_cache_test.dart test/environment_studio/environment_element_thumbnail_async_test.dart test/path_pattern/path_studio_tileset_image_picker_test.dart
cd packages/map_editor && flutter test && flutter analyze && flutter build macos --debug
```

**MCP parity:** N/A for new semantics: this lot changes presentation performance and ownership only. Project data, authoring actions, validation, import/export and persistence formats remain unchanged.

**Non-goals:** runtime cache sharing, preload-all, cache limits by entry count, raw product colors, removing previews, canvas viewport work from `RM-07B`, or unrelated synchronous file checks outside the four audited consumers.
````
