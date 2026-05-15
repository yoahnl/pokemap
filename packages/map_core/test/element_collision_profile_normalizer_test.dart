import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeElementCollisionProfile', () {
    test('collisionMask wins over contradictory legacy cells', () {
      final mask = _mask(
        widthPx: 4,
        heightPx: 4,
        solidPixels: _pixels(
          widthPx: 4,
          heightPx: 4,
          solidPoints: const [GridPos(x: 0, y: 2)],
        ),
      );
      final profile = ElementCollisionProfile(
        collisionMask: mask,
        cells: const [
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(normalized.collisionMask, same(mask));
      expect(normalized.cells, const [GridPos(x: 0, y: 1)]);
    });

    test('collisionMask preserves visualMask and occlusionMask', () {
      final collision = _solidMask(widthPx: 2, heightPx: 2);
      final visual = _solidMask(widthPx: 4, heightPx: 4);
      final occlusion = _solidMask(widthPx: 6, heightPx: 6);
      final profile = ElementCollisionProfile(
        collisionMask: collision,
        visualMask: visual,
        occlusionMask: occlusion,
        cells: const [GridPos(x: 3, y: 3)],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(normalized.visualMask, same(visual));
      expect(normalized.occlusionMask, same(occlusion));
      expect(normalized.collisionMask, same(collision));
      expect(normalized.cells, const [GridPos(x: 0, y: 0)]);
    });

    test('visualMask does not create collision cells', () {
      final profile = ElementCollisionProfile(
        visualMask: _solidMask(widthPx: 4, heightPx: 4),
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(normalized.cells, isEmpty);
    });

    test('occlusionMask does not create collision cells', () {
      final profile = ElementCollisionProfile(
        occlusionMask: _solidMask(widthPx: 4, heightPx: 4),
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(normalized.cells, isEmpty);
    });

    test('legacy manualAddedCells rebuild cells when shapeCells is empty', () {
      const manualAdded = [
        GridPos(x: 4, y: 5),
        GridPos(x: 0, y: 3),
        GridPos(x: 2, y: 4),
      ];
      final profile = ElementCollisionProfile(
        cells: _legacyFullCells(width: 6, height: 7),
        manualAddedCells: manualAdded,
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 16,
      );

      expect(
        normalized.cells,
        const [
          GridPos(x: 0, y: 3),
          GridPos(x: 2, y: 4),
          GridPos(x: 4, y: 5),
        ],
      );
      expect(normalized.manualAddedCells, manualAdded);
    });

    test('legacy shapeCells plus manualAddedCells minus manualRemovedCells',
        () {
      const profile = ElementCollisionProfile(
        shapeCells: [
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 0),
        ],
        cells: [
          GridPos(x: 9, y: 9),
        ],
        manualAddedCells: [
          GridPos(x: 1, y: 1),
          GridPos(x: 0, y: 0),
        ],
        manualRemovedCells: [
          GridPos(x: 1, y: 0),
        ],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 16,
      );

      expect(
        normalized.cells,
        const [
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 1),
        ],
      );
    });

    test('keeps cells unchanged when no legacy authoring intent exists', () {
      const profile = ElementCollisionProfile(
        cells: [
          GridPos(x: 2, y: 0),
          GridPos(x: 0, y: 0),
        ],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 16,
      );

      expect(normalized.cells, profile.cells);
    });

    test('sorts rebuilt legacy cells by y then x', () {
      const profile = ElementCollisionProfile(
        manualAddedCells: [
          GridPos(x: 2, y: 2),
          GridPos(x: 1, y: 1),
          GridPos(x: 0, y: 1),
        ],
      );

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 16,
      );

      expect(
        normalized.cells,
        const [
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 2),
        ],
      );
    });

    test('rejects non-positive tileSize', () {
      expect(
        () => normalizeElementCollisionProfile(
          const ElementCollisionProfile(),
          tileSize: 0,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('does not mutate original profile', () {
      final mask = _solidMask(widthPx: 2, heightPx: 2);
      final profile = ElementCollisionProfile(
        collisionMask: mask,
        cells: const [GridPos(x: 3, y: 3)],
      );
      final originalCells = profile.cells;

      final normalized = normalizeElementCollisionProfile(
        profile,
        tileSize: 2,
      );

      expect(identical(normalized, profile), isFalse);
      expect(profile.cells, originalCells);
      expect(normalized.cells, const [GridPos(x: 0, y: 0)]);
    });
  });
}

ElementCollisionPixelMask _solidMask({
  required int widthPx,
  required int heightPx,
}) {
  return _mask(
    widthPx: widthPx,
    heightPx: heightPx,
    solidPixels: List<bool>.filled(widthPx * heightPx, true),
  );
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  required List<bool> solidPixels,
}) {
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: solidPixels,
    ),
  );
}

List<bool> _pixels({
  required int widthPx,
  required int heightPx,
  required List<GridPos> solidPoints,
}) {
  final pixels = List<bool>.filled(widthPx * heightPx, false);
  for (final point in solidPoints) {
    pixels[point.y * widthPx + point.x] = true;
  }
  return pixels;
}

List<GridPos> _legacyFullCells({
  required int width,
  required int height,
}) {
  return [
    for (var y = 0; y < height; y++)
      for (var x = 0; x < width; x++) GridPos(x: x, y: y),
  ];
}
