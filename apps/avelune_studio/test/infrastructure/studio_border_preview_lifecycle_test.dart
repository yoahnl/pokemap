import 'dart:async';

import 'package:avelune_studio/platform/rendering/studio_border_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/map_runtime_authoring.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'invalidation releases the previous decoded image after a frame',
    (tester) async {
      final image = _image();
      final cache = BorderRuntimeAssetCache(
        imageLoader: (_, {transparentColor}) async => image,
      );
      final preview = StudioBorderPreview(
        projectRoot: '.',
        changed: () {},
        cache: cache,
      );
      try {
        await cache.loadFrame(projectRoot: '.', frame: _frame);

        preview.invalidate(_manifest, _map);

        expect(image.debugDisposed, isFalse);
        await tester.pump();
        await tester.pump();
        expect(image.debugDisposed, isTrue);
      } finally {
        await preview.dispose();
      }
    },
  );

  testWidgets('invalidation releases an image that finishes decoding later', (
    tester,
  ) async {
    final image = _image();
    final decoded = Completer<RuntimeTilesetImage>();
    final cache = BorderRuntimeAssetCache(
      imageLoader: (_, {transparentColor}) => decoded.future,
    );
    final preview = StudioBorderPreview(
      projectRoot: '.',
      changed: () {},
      cache: cache,
    );
    try {
      final loading = cache.loadFrame(projectRoot: '.', frame: _frame);

      preview.invalidate(_manifest, _map);
      await tester.pump();
      expect(image.debugDisposed, isFalse);

      decoded.complete(image);
      await loading;
      await tester.pump();
      expect(image.debugDisposed, isTrue);
    } finally {
      if (!decoded.isCompleted) decoded.complete(image);
      await preview.dispose();
    }
  });

  testWidgets('switching maps releases the previous map image', (tester) async {
    final image = _image();
    final cache = BorderRuntimeAssetCache(
      imageLoader: (_, {transparentColor}) async => image,
    );
    final preview = StudioBorderPreview(
      projectRoot: '.',
      changed: () {},
      cache: cache,
    );
    try {
      await cache.loadFrame(projectRoot: '.', frame: _frame);
      preview.setActiveMap(_manifest, _map);

      preview.setActiveMap(_manifest, _map.copyWith(id: 'next'));

      expect(image.debugDisposed, isFalse);
      await tester.pump();
      await tester.pump();
      expect(image.debugDisposed, isTrue);
    } finally {
      await preview.dispose();
    }
  });
}

const _manifest = ProjectManifest(name: 'Borders', maps: [], tilesets: []);
const _map = MapData(
  id: 'map',
  name: 'Map',
  size: GridSize(width: 1, height: 1),
);
final _frame = BorderRuntimeFrameRequest(
  snapshotId:
      'border-snapshot-sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  frameIndex: 0,
  relativeAssetPath: 'assets/borders/snapshot.png',
  sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
  durationMs: 100,
  transparentColorArgb: null,
);

RuntimeTilesetImage _image() => RuntimeTilesetImage(
  images: const [],
  chunks: const [],
  width: 1,
  height: 1,
);
