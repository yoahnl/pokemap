import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
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

  test(
    'default loader reads a real snapshot without source element or Surface '
    'metadata',
    () async {
      final fixture = await _writeAsymmetricSnapshot();
      final cache = BorderRuntimeAssetCache();

      final loaded = await cache.loadFrame(
        projectRoot: fixture.projectRoot,
        frame: fixture.frame,
      );

      expect(loaded.width, 4);
      expect(loaded.height, 3);
      expect(loaded.chunkCount, 1);
      expect(
        File(p.join(fixture.projectRoot, fixture.frame.relativeAssetPath))
            .existsSync(),
        isTrue,
      );
      // The fixture deliberately contains only the immutable snapshot file.
      // Loading therefore cannot fall back to ProjectElementEntry source
      // metadata or a Surface preset/source asset.
      expect(
        Directory(p.join(fixture.projectRoot, 'assets', 'source')).existsSync(),
        isFalse,
      );
    },
  );

  test(
    'real snapshot drawing preserves source rect, RGB key, and nearest pixels',
    () async {
      final fixture = await _writeAsymmetricSnapshot();
      final cache = BorderRuntimeAssetCache();
      final bundle = await cache.loadCollection(
        projectRoot: fixture.projectRoot,
        collection: BorderRuntimeAssetCollection(
          snapshots: <BorderRuntimeSnapshotRequest>[
            BorderRuntimeSnapshotRequest(
              snapshotId: fixture.frame.snapshotId,
              frames: <BorderRuntimeFrameRequest>[fixture.frame],
            ),
          ],
        ),
      );
      final loadedFrame =
          bundle.snapshotById(fixture.frame.snapshotId).frames[0];

      final rendered = await _drawFrameNearest(
        loadedFrame,
        width: 4,
        height: 4,
      );

      const red = <int>[255, 0, 0, 255];
      const green = <int>[0, 255, 0, 255];
      const transparent = <int>[0, 0, 0, 0];
      const blue = <int>[0, 0, 255, 255];
      for (final point in <(int, int)>[(0, 0), (1, 0), (0, 1), (1, 1)]) {
        expect(await _rgbaAt(rendered, point.$1, point.$2), red);
      }
      for (final point in <(int, int)>[(2, 0), (3, 0), (2, 1), (3, 1)]) {
        expect(await _rgbaAt(rendered, point.$1, point.$2), green);
      }
      for (final point in <(int, int)>[(0, 2), (1, 2), (0, 3), (1, 3)]) {
        expect(await _rgbaAt(rendered, point.$1, point.$2), transparent);
      }
      for (final point in <(int, int)>[(2, 2), (3, 2), (2, 3), (3, 3)]) {
        expect(await _rgbaAt(rendered, point.$1, point.$2), blue);
      }
    },
  );

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

Future<({String projectRoot, BorderRuntimeFrameRequest frame})>
    _writeAsymmetricSnapshot() async {
  final projectRoot = Directory.systemTemp.createTempSync(
    'border_runtime_real_snapshot',
  );
  addTearDown(() async {
    if (await projectRoot.exists()) {
      await projectRoot.delete(recursive: true);
    }
  });
  const relativePath = 'assets/borders/snapshots/$_digest/frame_asymmetric.png';
  final file = File(p.join(projectRoot.path, relativePath));
  await file.parent.create(recursive: true);

  final image = img.Image(width: 4, height: 3, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(255, 128, 0, 255));
  image
    ..setPixelRgba(1, 0, 255, 0, 0, 255)
    ..setPixelRgba(2, 0, 0, 255, 0, 255)
    ..setPixelRgba(1, 1, 10, 11, 12, 255)
    ..setPixelRgba(2, 1, 0, 0, 255, 255)
    ..setPixelRgba(3, 2, 255, 0, 255, 255);
  await file.writeAsBytes(img.encodePng(image, level: 0));

  return (
    projectRoot: projectRoot.path,
    frame: BorderRuntimeFrameRequest(
      snapshotId: 'border-snapshot-sha256:$_digest',
      frameIndex: 0,
      relativeAssetPath: relativePath,
      sourceRectPx: BorderPixelRect(x: 1, y: 0, width: 2, height: 2),
      durationMs: 100,
      // The alpha byte is intentionally non-canonical: runtime matching uses
      // only the effective low-24 RGB value 0x0a0b0c.
      transparentColorArgb: 0x120a0b0c,
    ),
  );
}

Future<ui.Image> _drawFrameNearest(
  BorderRuntimeLoadedFrame frame, {
  required int width,
  required int height,
}) {
  final source = frame.request.sourceRectPx;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  frame.image.drawImageRect(
    canvas,
    ui.Rect.fromLTWH(
      source.x.toDouble(),
      source.y.toDouble(),
      source.width.toDouble(),
      source.height.toDouble(),
    ),
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()
      ..isAntiAlias = false
      ..filterQuality = ui.FilterQuality.none,
  );
  return recorder.endRecording().toImage(width, height);
}

Future<List<int>> _rgbaAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return <int>[
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}
