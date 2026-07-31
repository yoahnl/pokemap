import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Smart Tile canonical templates', () {
    test('Edge 16 exposes every cardinal combination exactly once', () {
      final masks = smartTileCanonicalMasks(SmartTileTemplateHint.edge16);

      expect(masks, hasLength(16));
      expect(masks.toSet(), <int>{for (var mask = 0; mask < 16; mask++) mask});
    });

    test('Corner 16 exposes every corner combination exactly once', () {
      final masks = smartTileCanonicalMasks(SmartTileTemplateHint.corner16);

      expect(masks, hasLength(16));
      expect(
        masks.toSet(),
        <int>{
          for (var mask = 0; mask < 16; mask++)
            ((mask & 0x1) << 4) |
                ((mask & 0x2) << 4) |
                ((mask & 0x4) << 4) |
                ((mask & 0x8) << 4),
        },
      );
    });

    test('Corner 12 exposes the connected ERW corner signatures', () {
      final masks = smartTileCanonicalMasks(SmartTileTemplateHint.corner12);

      expect(
        masks,
        <int>[
          0x10,
          0x20,
          0x30,
          0x40,
          0x60,
          0x70,
          0x80,
          0x90,
          0xB0,
          0xC0,
          0xD0,
          0xE0,
        ],
      );
      expect(masks, isNot(containsAll(<int>[0x00, 0x50, 0xA0, 0xF0])));
    });

    test('Blob 47 normalizes all 256 neighborhoods into 47 signatures', () {
      final canonical = smartTileCanonicalMasks(
        SmartTileTemplateHint.blob47,
      );
      final normalized = <int>{
        for (var mask = 0; mask < 256; mask++) normalizeSmartTileBlobMask(mask),
      };

      expect(canonical, hasLength(47));
      expect(canonical.toSet(), normalized);
      expect(
        normalizeSmartTileBlobMask(
          smartTileNorthWestBit | smartTileNorthBit,
        ),
        smartTileNorthBit,
        reason: 'a diagonal is gated unless both adjacent edges connect',
      );
      expect(
        normalizeSmartTileBlobMask(
          smartTileNorthWestBit | smartTileNorthBit | smartTileWestBit,
        ),
        smartTileNorthWestBit | smartTileNorthBit | smartTileWestBit,
      );
    });

    test('Mixed 256 preserves every eight-neighbor combination', () {
      final masks = smartTileCanonicalMasks(SmartTileTemplateHint.mixed256);

      expect(masks, hasLength(256));
      expect(masks.toSet(), <int>{for (var mask = 0; mask < 256; mask++) mask});
    });

    test('mask signature uses same and different matches deterministically',
        () {
      final signature = smartTileSignatureForMask(
        smartTileNorthBit | smartTileEastBit | smartTileNorthEastBit,
        topology: SmartTileTopology.blob8,
      );

      expect(signature.northEdge.kind, SmartTileMatchKind.same);
      expect(signature.eastEdge.kind, SmartTileMatchKind.same);
      expect(signature.southEdge.kind, SmartTileMatchKind.different);
      expect(signature.westEdge.kind, SmartTileMatchKind.different);
      expect(signature.northEastCorner.kind, SmartTileMatchKind.same);
      expect(signature.southEastCorner.kind, SmartTileMatchKind.different);
    });

    test('Free and Legacy 20 do not invent canonical native mappings', () {
      expect(smartTileCanonicalMasks(SmartTileTemplateHint.free), isEmpty);
      expect(smartTileCanonicalMasks(SmartTileTemplateHint.legacy20), isEmpty);
    });
  });
}
