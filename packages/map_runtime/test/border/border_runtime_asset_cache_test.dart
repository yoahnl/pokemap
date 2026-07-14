import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/border/border_runtime_asset_cache.dart';
import 'package:map_runtime/src/border/border_runtime_asset_collection.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:path/path.dart' as p;

const _digest =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalizes cache key path and ARGB to its low 24 RGB bits', () async {
    final calls = <({String path, String? rgb})>[];
    final image = await _runtimeImage();
    final cache = BorderRuntimeAssetCache(
      imageLoader: (absolutePath, {transparentColor}) async {
        calls.add(
          (path: absolutePath, rgb: transparentColor?.toHexRgb()),
        );
        return image;
      },
    );
    final frameA = _frame(transparentColorArgb: 0x12aabbcc);
    final frameB = _frame(transparentColorArgb: 0xffaabbcc);
    final root = p.join(p.current, 'project', 'nested', '..');

    final first = cache.loadFrame(projectRoot: root, frame: frameA);
    final second = cache.loadFrame(projectRoot: root, frame: frameB);

    expect(await first, same(await second));
    expect(calls, hasLength(1));
    expect(calls.single.rgb, 'aabbcc');
    expect(
      calls.single.path,
      p.normalize(
        p.absolute(p.join(root, frameA.relativeAssetPath)),
      ),
    );
  });

  test('coalesces concurrent loads for one normalized key', () async {
    final completer = Completer<RuntimeTilesetImage>();
    var loadCount = 0;
    final cache = BorderRuntimeAssetCache(
      imageLoader: (absolutePath, {transparentColor}) {
        loadCount += 1;
        return completer.future;
      },
    );
    final frame = _frame();

    final first = cache.loadFrame(projectRoot: p.current, frame: frame);
    final second = cache.loadFrame(projectRoot: p.current, frame: frame);
    await Future<void>.delayed(Duration.zero);

    expect(loadCount, 1);
    final image = await _runtimeImage();
    completer.complete(image);
    expect(await first, same(image));
    expect(await second, same(image));
  });

  test('evicts a failed load so a later request retries', () async {
    var loadCount = 0;
    final image = await _runtimeImage();
    final cache = BorderRuntimeAssetCache(
      imageLoader: (absolutePath, {transparentColor}) async {
        loadCount += 1;
        if (loadCount == 1) {
          throw AssetNotFoundException('Image not found: $absolutePath');
        }
        return image;
      },
    );
    final frame = _frame();

    await expectLater(
      cache.loadFrame(projectRoot: p.current, frame: frame),
      throwsA(isA<AssetNotFoundException>()),
    );
    expect(
      await cache.loadFrame(projectRoot: p.current, frame: frame),
      same(image),
    );
    expect(loadCount, 2);
  });

  test('default file loader preserves the controlled missing-asset failure',
      () async {
    final missingRoot = Directory.systemTemp.createTempSync(
      'border_runtime_missing_asset',
    );
    addTearDown(() async {
      if (await missingRoot.exists()) {
        await missingRoot.delete(recursive: true);
      }
    });
    final cache = BorderRuntimeAssetCache();

    await expectLater(
      cache.loadFrame(projectRoot: missingRoot.path, frame: _frame()),
      throwsA(
        isA<AssetNotFoundException>().having(
          (error) => error.toString(),
          'message',
          contains('Image not found:'),
        ),
      ),
    );
  });

  test('loads every ordered frame into a snapshot bundle', () async {
    final image = await _runtimeImage();
    final paths = <String>[];
    final cache = BorderRuntimeAssetCache(
      imageLoader: (absolutePath, {transparentColor}) async {
        paths.add(absolutePath);
        return image;
      },
    );
    final request = BorderRuntimeSnapshotRequest(
      snapshotId: 'border-snapshot-sha256:$_digest',
      frames: <BorderRuntimeFrameRequest>[
        _frame(frameIndex: 0, fileName: 'frame_0000.png'),
        _frame(frameIndex: 1, fileName: 'frame_0001.png'),
      ],
    );

    final bundle = await cache.loadCollection(
      projectRoot: p.current,
      collection: BorderRuntimeAssetCollection(
        snapshots: <BorderRuntimeSnapshotRequest>[request],
      ),
    );

    expect(bundle.snapshotById(request.snapshotId).frames, hasLength(2));
    expect(
      bundle
          .snapshotById(request.snapshotId)
          .frames
          .map((frame) => frame.request.frameIndex),
      <int>[0, 1],
    );
    expect(paths[0], endsWith('frame_0000.png'));
    expect(paths[1], endsWith('frame_0001.png'));
  });
}

BorderRuntimeFrameRequest _frame({
  int frameIndex = 0,
  String fileName = 'frame.png',
  int? transparentColorArgb,
}) {
  return BorderRuntimeFrameRequest(
    snapshotId: 'border-snapshot-sha256:$_digest',
    frameIndex: frameIndex,
    relativeAssetPath: 'assets/borders/snapshots/$_digest/$fileName',
    sourceRectPx: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
    durationMs: 100,
    transparentColorArgb: transparentColorArgb,
  );
}

Future<RuntimeTilesetImage> _runtimeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 1, 1),
    ui.Paint()..color = const ui.Color(0xffff0000),
  );
  final image = await recorder.endRecording().toImage(1, 1);
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: 1, width: 1),
    ],
    width: 1,
    height: 1,
  );
}
