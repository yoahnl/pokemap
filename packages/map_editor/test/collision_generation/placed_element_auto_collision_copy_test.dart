import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/collision_generation/placed_element_auto_collision_generator.dart';
import 'package:map_editor/src/application/collision_generation/placed_element_collision_params.dart';

void main() {
  group('PlacedElementAutoCollisionGenerator', () {
    test('creates visual collision and occlusion masks from alpha heuristics',
        () async {
      final dir = Directory.systemTemp.createTempSync('collision_generation_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final imagePath = await _writePng(
        dir,
        width: 4,
        height: 4,
        opaquePixels: const [
          _P(0, 0),
          _P(1, 0),
          _P(2, 0),
          _P(3, 0),
          _P(0, 1),
          _P(1, 1),
          _P(2, 1),
          _P(3, 1),
          _P(0, 2),
          _P(1, 2),
          _P(2, 2),
          _P(3, 2),
          // Sparse bottom row: visual shadow only, not blocking collision.
          _P(0, 3),
        ],
      );

      final profile =
          await const PlacedElementAutoCollisionGenerator().generate(
        tilesetImagePath: imagePath,
        source: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        tileWidth: 4,
        tileHeight: 4,
      );

      expect(profile.source, ElementCollisionProfileSource.generated);
      expect(profile.padding, const WarpTriggerPadding());
      expect(profile.visualMask, isNotNull);
      expect(profile.collisionMask, isNotNull);
      expect(profile.occlusionMask, isNotNull);

      final visual = _decode(profile.visualMask!);
      final collision = _decode(profile.collisionMask!);
      final occlusion = _decode(profile.occlusionMask!);

      expect(visual[_idx(0, 3, width: 4)], isTrue);
      expect(collision[_idx(0, 3, width: 4)], isFalse);
      expect(collision.where((solid) => solid), hasLength(12));
      expect(occlusion.where((solid) => solid), hasLength(4));
      expect(occlusion[_idx(0, 0, width: 4)], isTrue);
      expect(occlusion[_idx(0, 1, width: 4)], isFalse);
    });

    test('projects generated collisionMask into legacy cells', () async {
      final dir = Directory.systemTemp.createTempSync('collision_generation_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final imagePath = await _writePng(
        dir,
        width: 4,
        height: 4,
        opaquePixels: {
          for (var y = 0; y < 4; y++)
            for (var x = 0; x < 4; x++) _P(x, y),
        },
      );

      final profile =
          await const PlacedElementAutoCollisionGenerator().generate(
        tilesetImagePath: imagePath,
        source: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        tileWidth: 4,
        tileHeight: 4,
      );

      expect(profile.collisionMask, isNotNull);
      expect(
        profile.cells,
        ElementCollisionMaskCodec.cellsFromPixelMask(
          mask: profile.collisionMask!,
          tileWidth: 4,
          tileHeight: 4,
          sourceWidthInTiles: 1,
          sourceHeightInTiles: 1,
        ),
      );
      expect(profile.cells, const [GridPos(x: 0, y: 0)]);
    });

    test('respects padding before deriving masks from alpha', () async {
      final dir = Directory.systemTemp.createTempSync('collision_generation_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final imagePath = await _writePng(
        dir,
        width: 4,
        height: 4,
        opaquePixels: {
          for (var y = 0; y < 4; y++)
            for (var x = 0; x < 4; x++) _P(x, y),
        },
      );

      final profile =
          await const PlacedElementAutoCollisionGenerator().generate(
        tilesetImagePath: imagePath,
        source: const TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
        tileWidth: 4,
        tileHeight: 4,
        padding: const WarpTriggerPadding(left: 1, right: 1, top: 1, bottom: 1),
      );

      final visual = _decode(profile.visualMask!);
      final collision = _decode(profile.collisionMask!);

      expect(visual[_idx(0, 0, width: 4)], isFalse);
      expect(visual[_idx(1, 1, width: 4)], isTrue);
      expect(collision[_idx(1, 1, width: 4)], isTrue);
      expect(collision[_idx(0, 0, width: 4)], isFalse);
    });

    test('documents alpha threshold as visual occupancy input', () {
      expect(
          PlacedElementCollisionGenerationParams.defaults.alphaThreshold, 24);
    });
  });
}

Future<String> _writePng(
  Directory dir, {
  required int width,
  required int height,
  required Iterable<_P> opaquePixels,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final paint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  for (final p in opaquePixels) {
    canvas.drawRect(
      ui.Rect.fromLTWH(p.x.toDouble(), p.y.toDouble(), 1, 1),
      paint,
    );
  }
  final image = await recorder.endRecording().toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('Unable to encode PNG test image');
  }
  final file = File('${dir.path}/tileset.png');
  await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
  return file.path;
}

List<bool> _decode(ElementCollisionPixelMask mask) {
  return ElementCollisionMaskCodec.decodePackedBits(
    widthPx: mask.widthPx,
    heightPx: mask.heightPx,
    dataBase64: mask.dataBase64,
  );
}

int _idx(int x, int y, {required int width}) => y * width + x;

class _P {
  const _P(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) => other is _P && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
