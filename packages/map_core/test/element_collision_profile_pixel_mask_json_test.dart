import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ElementCollisionProfile mask JSON', () {
    test('supports pixelMask', () {
      final mask = collisionMask(widthPx: 16, heightPx: 16);
      final profile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.generated,
        collisionMask: mask,
        padding: const WarpTriggerPadding(top: 1),
        cells: const [GridPos(x: 0, y: 0)],
      );
      final decoded = ElementCollisionProfile.fromJson(profile.toJson());
      expect(decoded.collisionMask, isNotNull);
      expect(decoded.collisionMask!.widthPx, 16);
      expect(decoded.padding.top, 1);
      expect(decoded.cells, const [GridPos(x: 0, y: 0)]);
    });

    test('ignores legacy non-map pixelMask while preserving cells', () {
      final profile = ElementCollisionProfile.fromJson(<String, dynamic>{
        'source': 'manual',
        'pixelMask': <int>[1, 0, 1],
        'cells': <Map<String, dynamic>>[
          <String, dynamic>{'x': 0, 'y': 1},
        ],
      });

      expect(profile.source, ElementCollisionProfileSource.manual);
      expect(profile.collisionMask, isNull);
      expect(profile.cells, const <GridPos>[GridPos(x: 0, y: 1)]);
    });

    test('keeps valid pixelMask map data intact', () {
      final dataBase64 = ElementCollisionMaskCodec.encodePackedBits(
        widthPx: 16,
        heightPx: 16,
        solidPixels: List<bool>.filled(256, true),
      );
      final profile = ElementCollisionProfile.fromJson(<String, dynamic>{
        'source': 'generated',
        'pixelMask': <String, dynamic>{
          'widthPx': 16,
          'heightPx': 16,
          'encoding': 'packed_bits_v1',
          'dataBase64': dataBase64,
        },
      });

      expect(profile.collisionMask, isNotNull);
      expect(profile.collisionMask!.widthPx, 16);
      expect(profile.collisionMask!.heightPx, 16);
      expect(
        profile.collisionMask!.encoding,
        ElementCollisionMaskEncoding.packedBitsV1,
      );
      expect(profile.collisionMask!.dataBase64, dataBase64);
    });

    test('ignores legacy non-map visual and occlusion masks', () {
      final profile = ElementCollisionProfile.fromJson(<String, dynamic>{
        'source': 'manual',
        'visualMask': <int>[1, 0, 1],
        'occlusionMask': <int>[0, 1, 0],
        'cells': <Map<String, dynamic>>[
          <String, dynamic>{'x': 1, 'y': 1},
        ],
      });

      expect(profile.visualMask, isNull);
      expect(profile.occlusionMask, isNull);
      expect(profile.cells, const <GridPos>[GridPos(x: 1, y: 1)]);
    });

    test('keeps valid visual and occlusion masks intact', () {
      final visual = collisionMask(widthPx: 8, heightPx: 8);
      final occlusion = collisionMask(widthPx: 4, heightPx: 4);

      final profile = ElementCollisionProfile.fromJson(<String, dynamic>{
        'source': 'generated',
        'visualMask': visual.toJson(),
        'occlusionMask': occlusion.toJson(),
      });

      expect(profile.visualMask, isNotNull);
      expect(profile.visualMask!.widthPx, 8);
      expect(profile.visualMask!.heightPx, 8);
      expect(profile.visualMask!.dataBase64, visual.dataBase64);
      expect(profile.occlusionMask, isNotNull);
      expect(profile.occlusionMask!.widthPx, 4);
      expect(profile.occlusionMask!.heightPx, 4);
      expect(profile.occlusionMask!.dataBase64, occlusion.dataBase64);
    });

    test('mask normalization does not affect authored cell lists', () {
      final profile = ElementCollisionProfile.fromJson(<String, dynamic>{
        'source': 'manual',
        'pixelMask': <int>[1, 0, 1],
        'cells': <Map<String, dynamic>>[
          <String, dynamic>{'x': 0, 'y': 0},
        ],
        'shapeCells': <Map<String, dynamic>>[
          <String, dynamic>{'x': 1, 'y': 0},
        ],
        'manualAddedCells': <Map<String, dynamic>>[
          <String, dynamic>{'x': 2, 'y': 0},
        ],
        'manualRemovedCells': <Map<String, dynamic>>[
          <String, dynamic>{'x': 3, 'y': 0},
        ],
      });

      expect(profile.collisionMask, isNull);
      expect(profile.cells, const <GridPos>[GridPos(x: 0, y: 0)]);
      expect(profile.shapeCells, const <GridPos>[GridPos(x: 1, y: 0)]);
      expect(profile.manualAddedCells, const <GridPos>[GridPos(x: 2, y: 0)]);
      expect(
        profile.manualRemovedCells,
        const <GridPos>[GridPos(x: 3, y: 0)],
      );
    });
  });
}

ElementCollisionPixelMask collisionMask({
  required int widthPx,
  required int heightPx,
}) {
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: List<bool>.filled(widthPx * heightPx, false),
    ),
  );
}
