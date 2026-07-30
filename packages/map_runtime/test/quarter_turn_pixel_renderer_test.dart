import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/quarter_turn_pixel_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses one draw run for pure q0-q3 pixel rotations', () async {
    const sourceSize = GridSize(width: 3, height: 2);
    final atlas = await _atlas(sourceSize);
    addTearDown(atlas.image.dispose);

    for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
      final destinationSize = quarterTurns.isEven
          ? sourceSize
          : const GridSize(width: 2, height: 3);
      final rendered = await _render(
        atlas.runtimeImage,
        sourceSize: sourceSize,
        destinationSize: destinationSize,
        quarterTurns: quarterTurns,
      );
      final bytes = (await rendered.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final transform = QuarterTurnPixelTransform(
        sourcePixelSize: sourceSize,
        destinationPixelSize: destinationSize,
        quarterTurns: quarterTurns,
      );

      expect(rendered.result.drawRunCount, 1);
      for (var y = 0; y < destinationSize.height; y++) {
        for (var x = 0; x < destinationSize.width; x++) {
          final source = transform.destinationPixelToSourcePixel(
            GridPos(x: x, y: y),
          );
          expect(
            _rgbaAt(bytes, width: destinationSize.width, x: x, y: y),
            _sourceRgba(source.x, source.y),
            reason: 'q$quarterTurns destination ($x, $y)',
          );
        }
      }
      rendered.image.dispose();
    }
  });

  test('falls back to exact QTP sampling for unequal rotated axes', () async {
    const sourceSize = GridSize(width: 6, height: 2);
    const destinationSize = GridSize(width: 3, height: 4);
    final atlas = await _atlas(sourceSize);
    addTearDown(atlas.image.dispose);
    final rendered = await _render(
      atlas.runtimeImage,
      sourceSize: sourceSize,
      destinationSize: destinationSize,
      quarterTurns: 1,
    );
    final bytes = (await rendered.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    final transform = QuarterTurnPixelTransform(
      sourcePixelSize: sourceSize,
      destinationPixelSize: destinationSize,
      quarterTurns: 1,
    );

    expect(rendered.result.drawRunCount, greaterThan(1));
    for (var y = 0; y < destinationSize.height; y++) {
      for (var x = 0; x < destinationSize.width; x++) {
        final source = transform.destinationPixelToSourcePixel(
          GridPos(x: x, y: y),
        );
        expect(
          _rgbaAt(bytes, width: destinationSize.width, x: x, y: y),
          _sourceRgba(source.x, source.y),
          reason: 'unequal-axis destination ($x, $y)',
        );
      }
    }
    rendered.image.dispose();
  });

  test('clips pure rotations with a source predicate and skips empty masks',
      () async {
    const sourceSize = GridSize(width: 3, height: 2);
    const destinationSize = GridSize(width: 2, height: 3);
    const includedSource = GridPos(x: 1, y: 0);
    final atlas = await _atlas(sourceSize);
    addTearDown(atlas.image.dispose);
    final filtered = await _render(
      atlas.runtimeImage,
      sourceSize: sourceSize,
      destinationSize: destinationSize,
      quarterTurns: 1,
      includeSourcePixel: (source) => source == includedSource,
    );
    final filteredBytes = (await filtered.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    final transform = QuarterTurnPixelTransform(
      sourcePixelSize: sourceSize,
      destinationPixelSize: destinationSize,
      quarterTurns: 1,
    );

    expect(filtered.result.drawRunCount, 1);
    expect(filtered.result.includedDestinationPixelCount, 1);
    for (var y = 0; y < destinationSize.height; y++) {
      for (var x = 0; x < destinationSize.width; x++) {
        final source = transform.destinationPixelToSourcePixel(
          GridPos(x: x, y: y),
        );
        expect(
          _rgbaAt(filteredBytes, width: destinationSize.width, x: x, y: y)[3],
          source == includedSource ? 255 : 0,
        );
      }
    }

    final empty = await _render(
      atlas.runtimeImage,
      sourceSize: sourceSize,
      destinationSize: destinationSize,
      quarterTurns: 1,
      includeSourcePixel: (_) => false,
    );
    final emptyBytes = (await empty.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    expect(empty.result.drawRunCount, 0);
    expect(empty.result.includedDestinationPixelCount, 0);
    for (var offset = 3; offset < emptyBytes.lengthInBytes; offset += 4) {
      expect(emptyBytes.getUint8(offset), 0);
    }

    filtered.image.dispose();
    empty.image.dispose();
  });
}

Future<({ui.Image image, RuntimeTilesetImage runtimeImage})> _atlas(
  GridSize size,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  for (var y = 0; y < size.height; y++) {
    for (var x = 0; x < size.width; x++) {
      final rgba = _sourceRgba(x, y);
      canvas.drawRect(
        ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
        ui.Paint()
          ..color = ui.Color.fromARGB(
            rgba[3],
            rgba[0],
            rgba[1],
            rgba[2],
          ),
      );
    }
  }
  final image = await recorder.endRecording().toImage(size.width, size.height);
  return (
    image: image,
    runtimeImage: RuntimeTilesetImage(
      images: <ui.Image>[image],
      chunks: <RuntimeTilesetChunk>[
        RuntimeTilesetChunk(
          top: 0,
          height: size.height,
          width: size.width,
        ),
      ],
      width: size.width,
      height: size.height,
    ),
  );
}

Future<
    ({
      ui.Image image,
      QuarterTurnPixelDrawResult result,
    })> _render(
  RuntimeTilesetImage atlas, {
  required GridSize sourceSize,
  required GridSize destinationSize,
  required int quarterTurns,
  QuarterTurnSourcePixelPredicate? includeSourcePixel,
}) async {
  final recorder = ui.PictureRecorder();
  final result = drawQuarterTurnPixels(
    ui.Canvas(recorder),
    image: atlas,
    sourceRect: ui.Rect.fromLTWH(
      0,
      0,
      sourceSize.width.toDouble(),
      sourceSize.height.toDouble(),
    ),
    destinationRect: ui.Rect.fromLTWH(
      0,
      0,
      destinationSize.width.toDouble(),
      destinationSize.height.toDouble(),
    ),
    sourcePixelSize: sourceSize,
    destinationPixelSize: destinationSize,
    quarterTurns: quarterTurns,
    paint: ui.Paint()
      ..isAntiAlias = false
      ..filterQuality = ui.FilterQuality.none,
    includeSourcePixel: includeSourcePixel,
  );
  final image = await recorder.endRecording().toImage(
        destinationSize.width,
        destinationSize.height,
      );
  return (image: image, result: result);
}

List<int> _sourceRgba(int x, int y) {
  return <int>[30 + x * 30, 40 + y * 80, 60 + x * 15 + y * 20, 255];
}

List<int> _rgbaAt(
  ByteData bytes, {
  required int width,
  required int x,
  required int y,
}) {
  final offset = (y * width + x) * 4;
  return <int>[
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  ];
}
