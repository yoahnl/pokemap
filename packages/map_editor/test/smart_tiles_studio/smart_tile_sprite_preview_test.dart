import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tile_sprite_preview.dart';
import 'package:map_editor/src/ui/assets/editor_image_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('crops the atlas cell the frame points at', (tester) async {
    final image = await tester.runAsync(() => _image(32, 32));
    addTearDown(image!.dispose);
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);

    await tester.pumpWidget(
      _app(
        cache: cache,
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 2, row: 1),
      ),
    );

    expect(
      find.byKey(const Key('smart-tile-sprite-preview-loading')),
      findsOneWidget,
    );
    expect(cache.requests.single.path, '/projects/demo/assets/tileset_01.png');
    expect(
      cache.requests.single.sourceRect,
      const ui.Rect.fromLTWH(64, 32, 32, 32),
    );

    cache.complete(EditorImageLoadResult.success(image!.clone()));
    await tester.pump();

    expect(find.byKey(const Key('preview')), findsOneWidget);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 32);
  });

  testWidgets('falls back when the frame cannot be resolved', (tester) async {
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);

    await tester.pumpWidget(
      _app(
        cache: cache,
        frame: const SmartTileFrameRef(atlasId: 'ghost', column: 0, row: 0),
      ),
    );

    expect(find.byKey(const Key('fallback')), findsOneWidget);
    expect(cache.requests, isEmpty);
  });

  testWidgets('falls back after a typed missing-file result', (tester) async {
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);

    await tester.pumpWidget(
      _app(
        cache: cache,
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
      ),
    );
    cache.complete(
      const EditorImageLoadResult.failure(
        EditorImageFailure(
          kind: EditorImageFailureKind.missingFile,
          path: '/projects/demo/assets/tileset_01.png',
          message: 'The image file does not exist.',
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('fallback')), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);
  });

  testWidgets('ignores a stale completion after the frame changed',
      (tester) async {
    final staleImage = await tester.runAsync(() => _image(8, 8));
    final freshImage = await tester.runAsync(() => _image(16, 16));
    addTearDown(staleImage!.dispose);
    addTearDown(freshImage!.dispose);
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);

    await tester.pumpWidget(
      _app(
        cache: cache,
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 0, row: 0),
      ),
    );
    await tester.pumpWidget(
      _app(
        cache: cache,
        frame: const SmartTileFrameRef(atlasId: 'atlas', column: 3, row: 0),
      ),
    );

    expect(cache.requests.length, 2);
    cache.completeAt(1, EditorImageLoadResult.success(freshImage!.clone()));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 16);

    final stale = EditorImageLoadResult.success(staleImage!.clone());
    cache.completeAt(0, stale);
    await tester.pump();
    await tester.pump();

    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 16);
    expect(stale.image!.debugDisposed, isTrue);
  });
}

Widget _app({
  required _QueuedImageCache cache,
  required SmartTileFrameRef frame,
}) {
  return CupertinoApp(
    home: CupertinoPageScaffold(
      child: Center(
        child: SmartTileSpritePreview(
          frame: frame,
          atlases: const <ProjectSmartTileAtlas>[_atlas],
          tilesets: const <ProjectTilesetEntry>[_tileset],
          projectRootPath: '/projects/demo',
          imageCache: cache,
          previewKey: const Key('preview'),
          fallbackKey: const Key('fallback'),
        ),
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

final class _CropRequest {
  _CropRequest({required this.path, required this.sourceRect});

  final String? path;
  final ui.Rect sourceRect;
  final Completer<EditorImageLoadResult> completer =
      Completer<EditorImageLoadResult>();
}

final class _QueuedImageCache extends EditorImageCache {
  _QueuedImageCache()
      : super(
          sessionKey: 'smart-tile-sprite-preview-test',
          retirementScheduler: (disposeImage) => disposeImage(),
        );

  final List<_CropRequest> requests = <_CropRequest>[];

  @override
  Future<EditorImageLoadResult> loadCrop(
    String? path, {
    required ui.Rect sourceRect,
    String variantKey = 'original',
    String sourceVariantKey = 'original',
    EditorImageBytesTransform? transformBytes,
  }) {
    final request = _CropRequest(path: path, sourceRect: sourceRect);
    requests.add(request);
    return request.completer.future;
  }

  void complete(EditorImageLoadResult result) => completeAt(
        requests.indexWhere((request) => !request.completer.isCompleted),
        result,
      );

  void completeAt(int index, EditorImageLoadResult result) =>
      requests[index].completer.complete(result);
}

const _atlas = ProjectSmartTileAtlas(
  id: 'atlas',
  name: 'Atlas',
  tilesetId: 'tileset-01',
  columns: 8,
  rows: 8,
);

const _tileset = ProjectTilesetEntry(
  id: 'tileset-01',
  name: 'Tileset 01',
  relativePath: 'assets/tileset_01.png',
);
