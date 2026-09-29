import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/quarter_turn_pixel_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bounded fallback reuses visible tiles and releases evicted plans',
      () async {
    const source = GridSize(width: 3, height: 2);
    final atlas = await _atlas(source);
    addTearDown(atlas.image.dispose);
    final cache = QuarterTurnPixelPlanCache(maxEntries: 1, maxBytes: 64);
    addTearDown(cache.dispose);
    var samples = 0;
    final plan = cache.obtain(
        image: atlas.runtimeImage,
        sourceRect: const ui.Rect.fromLTWH(0, 0, 3, 2),
        sourceSize: source,
        destinationSize: const GridSize(width: 1, height: 1048576),
        quarterTurns: 3,
        maskKey: 'all',
        includeSourcePixel: (_) {
          samples++;
          return true;
        });
    expect(cache.bytes, lessThanOrEqualTo(64));
    Future<void> draw() async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)
        ..clipRect(const ui.Rect.fromLTWH(0, 0, 1, 4));
      plan.draw(canvas);
      final picture = recorder.endRecording();
      final image = await picture.toImage(1, 4);
      picture.dispose();
      expect(
          (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
              .getUint8(3),
          255);
      image.dispose();
    }

    await draw();
    final first = samples;
    await draw();
    expect(samples, first);
    expect(cache.preparationCount, 1);
    cache.obtain(
        image: atlas.runtimeImage,
        sourceRect: const ui.Rect.fromLTWH(0, 0, 3, 2),
        sourceSize: source,
        destinationSize: const GridSize(width: 2, height: 3),
        quarterTurns: 1);
    expect(plan.isDisposed, isTrue);
    expect(cache.bytes, lessThanOrEqualTo(64));
    cache.dispose();
    expect(cache.bytes, 0);
  });

  test('odd reduction and mixed axes match every exact source sample',
      () async {
    const source = GridSize(width: 7, height: 5);
    final atlas = await _atlas(source);
    addTearDown(atlas.image.dispose);
    for (final target in const [
      GridSize(width: 2, height: 1),
      GridSize(width: 3, height: 11),
      GridSize(width: 13, height: 2)
    ]) {
      for (var q = 0; q < 4; q++) {
        final rendered = await _render(atlas.runtimeImage,
            sourceSize: source,
            destinationSize: target,
            quarterTurns: q,
            includeSourcePixel: (p) => (p.x + p.y).isEven);
        final bytes = (await rendered.image
            .toByteData(format: ui.ImageByteFormat.rawRgba))!;
        final transform = QuarterTurnPixelTransform(
            sourcePixelSize: source,
            destinationPixelSize: target,
            quarterTurns: q);
        for (var y = 0; y < target.height; y++) {
          for (var x = 0; x < target.width; x++) {
            final p =
                transform.destinationPixelToSourcePixel(GridPos(x: x, y: y));
            expect(_rgbaAt(bytes, width: target.width, x: x, y: y),
                (p.x + p.y).isEven ? _sourceRgba(p.x, p.y) : [0, 0, 0, 0],
                reason: '$target q$q ($x,$y)');
          }
        }
        rendered.image.dispose();
      }
    }
  });

  test('upscale sampling work follows source partitions', () async {
    const sourceSize = GridSize(width: 3, height: 2);
    final atlas = await _atlas(sourceSize);
    addTearDown(atlas.image.dispose);
    var samples = 0;
    final rendered = await _render(atlas.runtimeImage,
        sourceSize: sourceSize,
        destinationSize: const GridSize(width: 127, height: 129),
        quarterTurns: 1, includeSourcePixel: (_) {
      samples++;
      return true;
    });
    addTearDown(rendered.image.dispose);
    expect(samples, lessThanOrEqualTo(6));
    expect(rendered.result.drawRunCount, lessThanOrEqualTo(6));
    expect(rendered.result.includedDestinationPixelCount, 127 * 129);
  });

  test('project pixel sampling survives display zoom for every rotation',
      () async {
    const sourceSize = GridSize(width: 3, height: 2);
    const target = GridSize(width: 5, height: 3);
    final atlas = await _atlas(sourceSize);
    addTearDown(atlas.image.dispose);
    for (final zoom in [.5, 1.5, 2.0, 3.0]) {
      final width = (target.width * zoom).ceil();
      final height = (target.height * zoom).ceil();
      for (var q = 0; q < 4; q++) {
        final recorder = ui.PictureRecorder();
        drawQuarterTurnPixels(ui.Canvas(recorder),
            image: atlas.runtimeImage,
            sourceRect: const ui.Rect.fromLTWH(0, 0, 3, 2),
            destinationRect: ui.Rect.fromLTWH(
                0, 0, target.width * zoom, target.height * zoom),
            sourcePixelSize: sourceSize,
            destinationPixelSize: target,
            quarterTurns: q,
            paint: ui.Paint()
              ..isAntiAlias = false
              ..filterQuality = ui.FilterQuality.none);
        final picture = recorder.endRecording();
        final image = await picture.toImage(width, height);
        picture.dispose();
        final bytes =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        final transform = QuarterTurnPixelTransform(
            sourcePixelSize: sourceSize,
            destinationPixelSize: target,
            quarterTurns: q);
        final projectRecorder = ui.PictureRecorder();
        final projectCanvas = ui.Canvas(projectRecorder);
        for (var py = 0; py < target.height; py++) {
          for (var px = 0; px < target.width; px++) {
            final source =
                transform.destinationPixelToSourcePixel(GridPos(x: px, y: py));
            final rgba = _sourceRgba(source.x, source.y);
            projectCanvas.drawRect(
                ui.Rect.fromLTWH(px.toDouble(), py.toDouble(), 1, 1),
                ui.Paint()
                  ..isAntiAlias = false
                  ..color =
                      ui.Color.fromARGB(rgba[3], rgba[0], rgba[1], rgba[2]));
          }
        }
        final projectPicture = projectRecorder.endRecording();
        final projectImage =
            await projectPicture.toImage(target.width, target.height);
        projectPicture.dispose();
        final zoomRecorder = ui.PictureRecorder();
        ui.Canvas(zoomRecorder).drawImageRect(
            projectImage,
            ui.Rect.fromLTWH(
                0, 0, target.width.toDouble(), target.height.toDouble()),
            ui.Rect.fromLTWH(0, 0, target.width * zoom, target.height * zoom),
            ui.Paint()
              ..isAntiAlias = false
              ..filterQuality = ui.FilterQuality.none);
        final zoomPicture = zoomRecorder.endRecording();
        final reference = await zoomPicture.toImage(width, height);
        zoomPicture.dispose();
        projectImage.dispose();
        final expected =
            (await reference.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            expect(_rgbaAt(bytes, width: width, x: x, y: y),
                _rgbaAt(expected, width: width, x: x, y: y),
                reason: 'zoom$zoom q$q ($x,$y)');
          }
        }
        reference.dispose();
        image.dispose();
      }
    }
  });

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

  test('counts mask segments independently from non-pure sampling draws',
      () async {
    const sourceSize = GridSize(width: 6, height: 2);
    const destinationSize = GridSize(width: 3, height: 4);
    final atlas = await _atlas(sourceSize);
    addTearDown(atlas.image.dispose);
    final rendered = await _render(
      atlas.runtimeImage,
      sourceSize: sourceSize,
      destinationSize: destinationSize,
      quarterTurns: 1,
      includeSourcePixel: (source) => source.x == 0,
    );
    addTearDown(rendered.image.dispose);

    expect(rendered.result.includedDestinationPixelCount, 3);
    expect(rendered.result.drawRunCount, 2);
    expect(rendered.result.includedDestinationRunCount, 1);
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

  test('records an immutable draw plan once and replays exact pixels',
      () async {
    const sourceSize = GridSize(width: 3, height: 2);
    final atlas = await _atlas(sourceSize);
    addTearDown(atlas.image.dispose);
    final plan = QuarterTurnPixelDrawPlan.record(
      image: atlas.runtimeImage,
      sourceRect: const ui.Rect.fromLTWH(0, 0, 3, 2),
      destinationRect: const ui.Rect.fromLTWH(0, 0, 3, 2),
      sourcePixelSize: sourceSize,
      destinationPixelSize: sourceSize,
      quarterTurns: 0,
      paint: ui.Paint()..filterQuality = ui.FilterQuality.none,
      includeSourcePixel: (source) => source.x == source.y,
    );
    addTearDown(plan.dispose);

    final first = ui.PictureRecorder();
    plan.draw(ui.Canvas(first));
    final firstImage = await first.endRecording().toImage(3, 2);
    final second = ui.PictureRecorder();
    plan.draw(ui.Canvas(second));
    final secondImage = await second.endRecording().toImage(3, 2);
    addTearDown(firstImage.dispose);
    addTearDown(secondImage.dispose);

    expect(plan.result.includedDestinationPixelCount, 2);
    final firstBytes = (await firstImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    final secondBytes = (await secondImage.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    expect(
      firstBytes.buffer.asUint8List(),
      orderedEquals(secondBytes.buffer.asUint8List()),
    );
  });

  test('disposes the partial picture when plan recording fails', () async {
    const validSize = GridSize(width: 2, height: 2);
    final atlas = await _atlas(validSize);
    addTearDown(atlas.image.dispose);
    ui.Picture? discarded;

    expect(
      () => QuarterTurnPixelDrawPlan.record(
        image: atlas.runtimeImage,
        sourceRect: const ui.Rect.fromLTWH(0, 0, 2, 2),
        destinationRect: const ui.Rect.fromLTWH(0, 0, 2, 2),
        sourcePixelSize: const GridSize(width: 0, height: 2),
        destinationPixelSize: validSize,
        quarterTurns: 0,
        paint: ui.Paint(),
        debugOnDiscardedPicture: (picture) => discarded = picture,
      ),
      throwsArgumentError,
    );

    expect(discarded, isNotNull);
    expect(discarded!.debugDisposed, isTrue);
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
  return <int>[
    (30 + x * 30) % 256,
    (40 + y * 80) % 256,
    (60 + x * 15 + y * 20) % 256,
    255
  ];
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
