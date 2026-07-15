import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/border/border_runtime_asset_cache.dart';
import 'package:map_runtime/src/border/border_runtime_asset_collection.dart';
import 'package:map_runtime/src/border/border_runtime_draw_instruction.dart';
import 'package:map_runtime/src/border/border_runtime_renderer.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';

const _digest =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _snapshotId = 'border-snapshot-sha256:$_digest';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders a ground cell from its persisted source rect with no filtering',
      () async {
    final atlas = await _imageFromRows(<List<ui.Color>>[
      const <ui.Color>[
        ui.Color(0xffff0000),
        ui.Color(0xff00ff00),
        ui.Color(0xff0000ff),
      ],
    ]);
    final bundle = _bundle(
      <_FrameFixture>[
        _FrameFixture(
          image: atlas,
          sourceRect: BorderPixelRect(x: 1, y: 0, width: 1, height: 1),
          durationMs: 100,
        ),
      ],
    );
    final collection = _collection(
      <BorderRuntimeDrawInstruction>[
        BorderRuntimeGroundInstruction(
          featureId: 'feature',
          snapshotId: _snapshotId,
          cellX: 1,
          cellY: 0,
          worldBoundsPx: BorderPixelRect(x: 2, y: 0, width: 2, height: 2),
        ),
      ],
    );

    final rendered = await _render(collection, bundle, width: 4, height: 2);

    expect(await _rgbaAt(rendered, 1, 0), <int>[0, 0, 0, 0]);
    for (final point in <(int, int)>[(2, 0), (3, 0), (2, 1), (3, 1)]) {
      expect(
          await _rgbaAt(rendered, point.$1, point.$2), <int>[0, 255, 0, 255]);
    }
  });

  test('selects animation frames at exact persisted duration boundaries',
      () async {
    final red = await _solidImage(const ui.Color(0xffff0000));
    final green = await _solidImage(const ui.Color(0xff00ff00));
    final bundle = _bundle(
      <_FrameFixture>[
        _FrameFixture(
          image: red,
          sourceRect: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          durationMs: 100,
        ),
        _FrameFixture(
          image: green,
          sourceRect: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
          durationMs: 200,
        ),
      ],
    );
    final collection = _collection(<BorderRuntimeDrawInstruction>[
      _placement(
        topLeft: const BorderPixelPos(x: 0, y: 0),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
      ),
    ]);

    expect(await _renderedPixel(collection, bundle, elapsedMs: 99),
        <int>[255, 0, 0, 255]);
    expect(await _renderedPixel(collection, bundle, elapsedMs: 100),
        <int>[0, 255, 0, 255]);
    expect(await _renderedPixel(collection, bundle, elapsedMs: 299),
        <int>[0, 255, 0, 255]);
    expect(await _renderedPixel(collection, bundle, elapsedMs: 300),
        <int>[255, 0, 0, 255]);
  });

  test('applies layer opacity', () async {
    final red = await _solidImage(const ui.Color(0xffff0000));
    final bundle = _bundle(<_FrameFixture>[
      _FrameFixture(
        image: red,
        sourceRect: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        durationMs: 100,
      ),
    ]);
    final collection = _collection(
      <BorderRuntimeDrawInstruction>[
        _placement(
          topLeft: const BorderPixelPos(x: 0, y: 0),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
      opacity: 0.5,
    );

    final pixel = await _renderedPixel(collection, bundle);

    // rawRgba exposes the Canvas result premultiplied by alpha.
    expect(pixel[0], inInclusiveRange(127, 128));
    expect(pixel[1], 0);
    expect(pixel[2], 0);
    expect(pixel[3], inInclusiveRange(127, 128));
  });

  test('culls placements exclusively by persisted opaque world bounds',
      () async {
    final red = await _solidImage(const ui.Color(0xffff0000));
    final bundle = _bundle(<_FrameFixture>[
      _FrameFixture(
        image: red,
        sourceRect: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        durationMs: 100,
      ),
    ]);
    final collection = _collection(<BorderRuntimeDrawInstruction>[
      _placement(
        topLeft: const BorderPixelPos(x: 0, y: 0),
        opaqueBounds: BorderPixelRect(x: 20, y: 20, width: 1, height: 1),
      ),
    ]);

    final rendered = await _render(
      collection,
      bundle,
      width: 1,
      height: 1,
      viewport: const ui.Rect.fromLTWH(0, 0, 1, 1),
    );

    expect(await _rgbaAt(rendered, 0, 0), <int>[0, 0, 0, 0]);
  });

  test('does not render an invisible layer collection', () async {
    final red = await _solidImage(const ui.Color(0xffff0000));
    final bundle = _bundle(<_FrameFixture>[
      _FrameFixture(
        image: red,
        sourceRect: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        durationMs: 100,
      ),
    ]);
    final collection = _collection(
      <BorderRuntimeDrawInstruction>[
        _placement(
          topLeft: const BorderPixelPos(x: 0, y: 0),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        ),
      ],
      isVisible: false,
    );

    expect(await _renderedPixel(collection, bundle), <int>[0, 0, 0, 0]);
  });

  test('surfaces missing snapshots and invalid persisted source rectangles',
      () async {
    final red = await _solidImage(const ui.Color(0xffff0000));
    final validBundle = _bundle(<_FrameFixture>[
      _FrameFixture(
        image: red,
        sourceRect: BorderPixelRect(x: 1, y: 0, width: 1, height: 1),
        durationMs: 100,
      ),
    ]);
    final missingBundle = BorderRuntimeAssetBundle(
      snapshots: const <BorderRuntimeLoadedSnapshot>[],
    );
    final collection = _collection(<BorderRuntimeDrawInstruction>[
      _placement(
        topLeft: const BorderPixelPos(x: 0, y: 0),
        opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
      ),
    ]);

    expect(
      () => _record(collection, missingBundle),
      throwsA(isA<AssetNotFoundException>()),
    );
    expect(
      () => _record(collection, validBundle),
      throwsA(
        isA<AssetNotFoundException>().having(
          (error) => error.toString(),
          'message',
          contains('source rectangle'),
        ),
      ),
    );
  });

  test('renders flip then clockwise quarter turn for all eight transforms',
      () async {
    const source = <List<ui.Color>>[
      <ui.Color>[ui.Color(0xffff0000), ui.Color(0xff00ff00)],
      <ui.Color>[ui.Color(0xff0000ff), ui.Color(0xffffff00)],
      <ui.Color>[ui.Color(0xffff00ff), ui.Color(0xff00ffff)],
    ];
    final image = await _imageFromRows(source);
    final bundle = _bundle(<_FrameFixture>[
      _FrameFixture(
        image: image,
        sourceRect: BorderPixelRect(x: 0, y: 0, width: 2, height: 3),
        durationMs: 100,
      ),
    ]);

    for (var quarterTurns = 0; quarterTurns < 4; quarterTurns += 1) {
      for (final flipX in <bool>[false, true]) {
        final destinationWidth = quarterTurns.isEven ? 2 : 3;
        final destinationHeight = quarterTurns.isEven ? 3 : 2;
        final collection = _collection(<BorderRuntimeDrawInstruction>[
          _placement(
            topLeft: const BorderPixelPos(x: 1, y: 1),
            opaqueBounds: BorderPixelRect(
              x: 1,
              y: 1,
              width: destinationWidth,
              height: destinationHeight,
            ),
            transform: BorderSpriteTransform(
              quarterTurns: quarterTurns,
              flipX: flipX,
            ),
          ),
        ]);

        final rendered = await _render(
          collection,
          bundle,
          width: 5,
          height: 5,
        );

        for (var sourceY = 0; sourceY < 3; sourceY += 1) {
          for (var sourceX = 0; sourceX < 2; sourceX += 1) {
            final destination = _transformedPoint(
              sourceX: sourceX,
              sourceY: sourceY,
              width: 2,
              height: 3,
              flipX: flipX,
              quarterTurns: quarterTurns,
            );
            expect(
              await _rgbaAt(
                rendered,
                1 + destination.$1,
                1 + destination.$2,
              ),
              _rgba(source[sourceY][sourceX]),
              reason: 'quarterTurns=$quarterTurns flipX=$flipX '
                  'source=($sourceX,$sourceY)',
            );
          }
        }
      }
    }
  });

  test('scales native ground bounds into runtime display pixels', () async {
    final red = await _solidImage(const ui.Color(0xffff0000));
    final bundle = _bundle(<_FrameFixture>[
      _FrameFixture(
        image: red,
        sourceRect: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        durationMs: 100,
      ),
    ]);
    final collection = _collection(<BorderRuntimeDrawInstruction>[
      BorderRuntimeGroundInstruction(
        featureId: 'feature',
        snapshotId: _snapshotId,
        cellX: 1,
        cellY: 1,
        worldBoundsPx: BorderPixelRect(x: 1, y: 1, width: 1, height: 1),
      ),
    ]);

    final rendered = await _render(
      collection,
      bundle,
      width: 4,
      height: 4,
      displayScale: 2,
    );

    expect(await _rgbaAt(rendered, 1, 1), <int>[0, 0, 0, 0]);
    for (final point in <(int, int)>[(2, 2), (3, 2), (2, 3), (3, 3)]) {
      expect(
          await _rgbaAt(rendered, point.$1, point.$2), <int>[255, 0, 0, 255]);
    }
  });

  test(
    'scales transformed placements without leaking transforms to the next '
    'instruction',
    () async {
      const source = <List<ui.Color>>[
        <ui.Color>[ui.Color(0xffff0000), ui.Color(0xff00ff00)],
        <ui.Color>[ui.Color(0xff0000ff), ui.Color(0xffffff00)],
        <ui.Color>[ui.Color(0xffff00ff), ui.Color(0xff00ffff)],
      ];
      final image = await _imageFromRows(source);
      final bundle = _bundle(<_FrameFixture>[
        _FrameFixture(
          image: image,
          sourceRect: BorderPixelRect(x: 0, y: 0, width: 2, height: 3),
          durationMs: 100,
        ),
      ]);
      final collection = _collection(<BorderRuntimeDrawInstruction>[
        _placement(
          topLeft: const BorderPixelPos(x: 0, y: 0),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 3, height: 2),
          transform: BorderSpriteTransform(quarterTurns: 1, flipX: true),
        ),
        _placement(
          topLeft: const BorderPixelPos(x: 4, y: 0),
          opaqueBounds: BorderPixelRect(x: 4, y: 0, width: 2, height: 3),
        ),
      ]);

      final rendered = await _render(
        collection,
        bundle,
        width: 12,
        height: 6,
        displayScale: 2,
      );

      // The first source pixel is flipped and rotated to native (2, 1), then
      // expanded to a 2x2 nearest-neighbor block.
      for (final point in <(int, int)>[(4, 2), (5, 2), (4, 3), (5, 3)]) {
        expect(
            await _rgbaAt(rendered, point.$1, point.$2), <int>[255, 0, 0, 255]);
      }
      // The second placement must begin untransformed at native x=4. This
      // also proves the first placement's scale/rotation/flip were restored.
      for (final point in <(int, int)>[(8, 0), (9, 0), (8, 1), (9, 1)]) {
        expect(
            await _rgbaAt(rendered, point.$1, point.$2), <int>[255, 0, 0, 255]);
      }
      expect(await _rgbaAt(rendered, 10, 0), <int>[0, 255, 0, 255]);
    },
  );

  test('culls persisted opaque bounds in display-scaled world coordinates',
      () async {
    final red = await _solidImage(const ui.Color(0xffff0000));
    final bundle = _bundle(<_FrameFixture>[
      _FrameFixture(
        image: red,
        sourceRect: BorderPixelRect(x: 0, y: 0, width: 1, height: 1),
        durationMs: 100,
      ),
    ]);
    final collection = _collection(<BorderRuntimeDrawInstruction>[
      _placement(
        topLeft: const BorderPixelPos(x: 2, y: 0),
        opaqueBounds: BorderPixelRect(x: 2, y: 0, width: 1, height: 1),
      ),
    ]);

    final rendered = await _render(
      collection,
      bundle,
      width: 6,
      height: 2,
      displayScale: 2,
      viewport: const ui.Rect.fromLTWH(4, 0, 2, 2),
    );

    for (final point in <(int, int)>[(4, 0), (5, 0), (4, 1), (5, 1)]) {
      expect(
          await _rgbaAt(rendered, point.$1, point.$2), <int>[255, 0, 0, 255]);
    }
  });
}

BorderRuntimeDrawInstructionCollection _collection(
  List<BorderRuntimeDrawInstruction> instructions, {
  bool isVisible = true,
  double opacity = 1,
}) {
  return BorderRuntimeDrawInstructionCollection(
    layerId: 'border',
    isVisible: isVisible,
    opacity: opacity,
    instructions: instructions,
  );
}

BorderRuntimePlacementInstruction _placement({
  required BorderPixelPos topLeft,
  required BorderPixelRect opaqueBounds,
  BorderSpriteTransform? transform,
}) {
  return BorderRuntimePlacementInstruction(
    featureId: 'feature',
    placementId: 'placement',
    snapshotId: _snapshotId,
    topLeftWorldPx: topLeft,
    opaqueWorldBoundsPx: opaqueBounds,
    transform: transform ??
        BorderSpriteTransform(
          quarterTurns: 0,
          flipX: false,
        ),
  );
}

BorderRuntimeAssetBundle _bundle(List<_FrameFixture> fixtures) {
  return BorderRuntimeAssetBundle(
    snapshots: <BorderRuntimeLoadedSnapshot>[
      BorderRuntimeLoadedSnapshot(
        snapshotId: _snapshotId,
        frames: <BorderRuntimeLoadedFrame>[
          for (var index = 0; index < fixtures.length; index += 1)
            BorderRuntimeLoadedFrame(
              request: BorderRuntimeFrameRequest(
                snapshotId: _snapshotId,
                frameIndex: index,
                relativeAssetPath:
                    'assets/borders/snapshots/$_digest/frame_$index.png',
                sourceRectPx: fixtures[index].sourceRect,
                durationMs: fixtures[index].durationMs,
                transparentColorArgb: null,
              ),
              image: _runtimeImage(fixtures[index].image),
            ),
        ],
      ),
    ],
  );
}

RuntimeTilesetImage _runtimeImage(ui.Image image) {
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(
        top: 0,
        height: image.height,
        width: image.width,
      ),
    ],
    width: image.width,
    height: image.height,
  );
}

Future<ui.Image> _render(
  BorderRuntimeDrawInstructionCollection collection,
  BorderRuntimeAssetBundle bundle, {
  required int width,
  required int height,
  int elapsedMs = 0,
  ui.Rect? viewport,
  double displayScale = 1,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const BorderRuntimeRenderer().renderCollection(
    canvas,
    collection: collection,
    assets: bundle,
    elapsedMs: elapsedMs,
    viewport: viewport,
    displayScale: displayScale,
  );
  return recorder.endRecording().toImage(width, height);
}

ui.Picture _record(
  BorderRuntimeDrawInstructionCollection collection,
  BorderRuntimeAssetBundle bundle,
) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const BorderRuntimeRenderer().renderCollection(
    canvas,
    collection: collection,
    assets: bundle,
    elapsedMs: 0,
    displayScale: 1,
  );
  return recorder.endRecording();
}

Future<List<int>> _renderedPixel(
  BorderRuntimeDrawInstructionCollection collection,
  BorderRuntimeAssetBundle bundle, {
  int elapsedMs = 0,
}) async {
  final rendered = await _render(
    collection,
    bundle,
    width: 1,
    height: 1,
    elapsedMs: elapsedMs,
  );
  return _rgbaAt(rendered, 0, 0);
}

Future<ui.Image> _solidImage(ui.Color color) {
  return _imageFromRows(<List<ui.Color>>[
    <ui.Color>[color],
  ]);
}

Future<ui.Image> _imageFromRows(List<List<ui.Color>> rows) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..isAntiAlias = false;
  for (var y = 0; y < rows.length; y += 1) {
    for (var x = 0; x < rows[y].length; x += 1) {
      paint.color = rows[y][x];
      canvas.drawRect(
        ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
        paint,
      );
    }
  }
  return recorder.endRecording().toImage(rows.first.length, rows.length);
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

List<int> _rgba(ui.Color color) => <int>[
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
      (color.a * 255).round(),
    ];

(int, int) _transformedPoint({
  required int sourceX,
  required int sourceY,
  required int width,
  required int height,
  required bool flipX,
  required int quarterTurns,
}) {
  final x = flipX ? width - 1 - sourceX : sourceX;
  return switch (quarterTurns) {
    0 => (x, sourceY),
    1 => (height - 1 - sourceY, x),
    2 => (width - 1 - x, height - 1 - sourceY),
    3 => (sourceY, width - 1 - x),
    _ => throw StateError('invalid quarterTurns'),
  };
}

final class _FrameFixture {
  const _FrameFixture({
    required this.image,
    required this.sourceRect,
    required this.durationMs,
  });

  final ui.Image image;
  final BorderPixelRect sourceRect;
  final int durationMs;
}
