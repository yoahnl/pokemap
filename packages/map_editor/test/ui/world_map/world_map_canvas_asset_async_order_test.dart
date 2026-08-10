import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/editor/editor_asset_cache_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  testWidgets('newest canvas image batch wins when B resolves before stale A', (
    tester,
  ) async {
    final imageA = await _solidImage();
    final imageB = await _solidImage();
    final resultA = _CountingImageLoadResult(imageA);
    final resultB = _CountingImageLoadResult(imageB);
    final cache = _ControlledEditorImageCache();
    final harness = await _pumpCanvas(tester, cache);
    addTearDown(harness.dispose);

    expect(cache.requests, hasLength(1));
    expect(cache.requests.single.paths, contains('source-a'));

    harness.notifier.state = harness.notifier.state.copyWith(
      activeMap: _mapFor('source-b'),
    );
    await tester.pump();
    expect(cache.requests, hasLength(2));
    expect(cache.requests.last.paths, contains('source-b'));

    cache.requests.last.complete(<String, EditorImageLoadResult>{
      'source-b': resultB,
    });
    await tester.pump();
    expect(_canvasPainter(tester).tilesetImagesById['source-b'], same(imageB));

    cache.requests.first.complete(<String, EditorImageLoadResult>{
      'source-a': resultA,
    });
    await tester.pump();
    await tester.pump();

    final painter = _canvasPainter(tester);
    expect(painter.tilesetImagesById['source-b'], same(imageB));
    expect(painter.tilesetImagesById, isNot(contains('source-a')));
    expect(resultA.disposeCalls, 1);
    expect(resultB.disposeCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(resultA.disposeCalls, 1);
    expect(resultB.disposeCalls, 1);
  });

  testWidgets(
    'disposing between B and A resolution releases both batches once',
    (tester) async {
      final resultA = _CountingImageLoadResult(await _solidImage());
      final resultB = _CountingImageLoadResult(await _solidImage());
      final cache = _ControlledEditorImageCache();
      final harness = await _pumpCanvas(tester, cache);
      addTearDown(harness.dispose);

      harness.notifier.state = harness.notifier.state.copyWith(
        activeMap: _mapFor('source-b'),
      );
      await tester.pump();
      expect(cache.requests, hasLength(2));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      cache.requests.last.complete(<String, EditorImageLoadResult>{
        'source-b': resultB,
      });
      cache.requests.first.complete(<String, EditorImageLoadResult>{
        'source-a': resultA,
      });
      await tester.pump();
      await tester.pump();

      expect(resultA.disposeCalls, 1);
      expect(resultB.disposeCalls, 1);
    },
  );
}

MapGridPainter _canvasPainter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((widget) => widget.painter)
      .whereType<MapGridPainter>()
      .single;
}

Future<ui.Image> _solidImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 32, 32),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(32, 32);
  picture.dispose();
  return image;
}

class _CountingImageLoadResult extends EditorImageLoadResult {
  _CountingImageLoadResult(super.image) : super.success();

  int disposeCalls = 0;

  @override
  void dispose() {
    disposeCalls += 1;
    super.dispose();
  }
}

class _ControlledImageRequest {
  _ControlledImageRequest(this.paths);

  final Map<String, String> paths;
  final Completer<Map<String, EditorImageLoadResult>> _completer =
      Completer<Map<String, EditorImageLoadResult>>();

  Future<Map<String, EditorImageLoadResult>> get future => _completer.future;

  void complete(Map<String, EditorImageLoadResult> results) {
    _completer.complete(results);
  }
}

class _ControlledEditorImageCache extends EditorImageCache {
  _ControlledEditorImageCache() : super(sessionKey: 'controlled-canvas-assets');

  final List<_ControlledImageRequest> requests = <_ControlledImageRequest>[];

  @override
  Future<Map<String, EditorImageLoadResult>> loadMany(
    Map<String, String> paths, {
    String Function(String id)? variantKeyForId,
    int? targetWidth,
    int? targetHeight,
    bool allowUpscaling = true,
    EditorImageBytesTransform? Function(String id)? transformForId,
  }) {
    final request = _ControlledImageRequest(Map<String, String>.from(paths));
    requests.add(request);
    return request.future;
  }
}

class _CanvasHarness {
  const _CanvasHarness({required this.container, required this.subscription});

  final ProviderContainer container;
  final ProviderSubscription<EditorState> subscription;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  void dispose() {
    subscription.close();
    container.dispose();
  }
}

Future<_CanvasHarness> _pumpCanvas(
  WidgetTester tester,
  EditorImageCache cache,
) async {
  final container = ProviderContainer(
    overrides: <Override>[
      editorImageCacheProvider.overrideWith((ref, root) => cache),
    ],
  );
  final subscription = container.listen<EditorState>(
    editorNotifierProvider,
    (_, _) {},
    fireImmediately: true,
  );
  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: '/tmp/world-map-async-order',
    activeMapPath: '/tmp/world-map-async-order/maps/map.json',
    project: _project,
    activeMap: _mapFor('source-a'),
    activeLayerId: 'ground',
  );
  await tester.binding.setSurfaceSize(const Size(640, 480));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: PokeMapTheme.light(),
        home: const Scaffold(body: MapCanvas()),
      ),
    ),
  );
  await tester.pump();
  return _CanvasHarness(container: container, subscription: subscription);
}

const _project = ProjectManifest(
  name: 'Async canvas assets',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'source-a',
      name: 'Source A',
      relativePath: 'assets/a.png',
    ),
    ProjectTilesetEntry(
      id: 'source-b',
      name: 'Source B',
      relativePath: 'assets/b.png',
    ),
  ],
);

MapData _mapFor(String tilesetId) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      TileLayer(
        id: 'ground',
        name: 'Sol',
        palette: <TileLayerPaletteEntry>[
          TileLayerPaletteEntry(tilesetId: tilesetId, localTileId: 0),
        ],
        cells: const <int>[1, 0, 0, 0],
      ),
    ],
  );
}
