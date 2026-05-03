import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

TilesetVisualFrame _f(int x) =>
    TilesetVisualFrame(source: TilesetSourceRect(x: x, y: 0));

void main() {
  group('pickTerrainPresetVariantForMapCell', () {
    test('single variant is always returned', () {
      final v = TerrainPresetVariant(
        frames: [_f(0)],
        weight: 3,
      );
      expect(
        pickTerrainPresetVariantForMapCell(
          variants: [v],
          mapX: 99,
          mapY: -2,
          phase: 0,
        ),
        v,
      );
    });

    test('expands weights and indexes by map position and phase', () {
      final a = TerrainPresetVariant(frames: [_f(1)], weight: 2);
      final b = TerrainPresetVariant(frames: [_f(2)], weight: 1);
      // expanded: [a, a, b] — length 3
      expect(
        pickTerrainPresetVariantForMapCell(
          variants: [a, b],
          mapX: 0,
          mapY: 0,
          phase: 0,
        ),
        a,
      );
      expect(
        pickTerrainPresetVariantForMapCell(
          variants: [a, b],
          mapX: 1,
          mapY: 0,
          phase: 0,
        ),
        a,
      );
      expect(
        pickTerrainPresetVariantForMapCell(
          variants: [a, b],
          mapX: 2,
          mapY: 0,
          phase: 0,
        ),
        b,
      );
      expect(
        pickTerrainPresetVariantForMapCell(
          variants: [a, b],
          mapX: 3,
          mapY: 0,
          phase: 0,
        ),
        a,
      );
    });
  });
}
