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

  testWidgets('reloads the same path when the project manifest is replaced',
      (tester) async {
    final firstImage = await tester.runAsync(() => _image(1, 1));
    final secondImage = await tester.runAsync(() => _image(2, 1));
    addTearDown(firstImage!.dispose);
    addTearDown(secondImage!.dispose);
    final cache = _QueuedImageCache();
    addTearDown(cache.dispose);
    const path = '/project/revisioned.png';

    await tester.pumpWidget(_app(cache: cache, path: path));
    cache.complete(path, EditorImageLoadResult.success(firstImage.clone()));
    await tester.pump();
    expect(cache.requestCount(path), 1);
    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 1);

    await tester.pumpWidget(
      _app(
        cache: cache,
        path: path,
        manifest: _manifestRevision2,
      ),
    );

    expect(cache.requestCount(path), 2);
    cache.complete(path, EditorImageLoadResult.success(secondImage.clone()));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 2);
  });
}

Widget _app({
  required _QueuedImageCache cache,
  required String path,
  Key? widgetKey,
  ProjectManifest manifest = _manifest,
}) {
  return CupertinoApp(
    home: CupertinoPageScaffold(
      child: EnvironmentElementThumbnail(
        key: widgetKey,
        manifest: manifest,
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

  final Map<String, List<Completer<EditorImageLoadResult>>> _requests = {};

  @override
  Future<EditorImageLoadResult> loadCrop(
    String? path, {
    required ui.Rect sourceRect,
    String variantKey = 'original',
    String sourceVariantKey = 'original',
    EditorImageBytesTransform? transformBytes,
  }) {
    final request = Completer<EditorImageLoadResult>();
    (_requests[path!] ??= <Completer<EditorImageLoadResult>>[]).add(request);
    return request.future;
  }

  void complete(String path, EditorImageLoadResult result) {
    final requests = _requests[path]!;
    requests.firstWhere((request) => !request.isCompleted).complete(result);
  }

  int requestCount(String path) => _requests[path]?.length ?? 0;
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

const _manifestRevision2 = ProjectManifest(
  name: 'Environment thumbnail revision 2',
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
