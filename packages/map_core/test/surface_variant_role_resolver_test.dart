import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveSurfaceVariantRoleForPlacement', () {
    test('resolves an isolated placement', () {
      const placements = [
        SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
      ];

      final role = resolveSurfaceVariantRoleForPlacement(
        placements: placements,
        x: 1,
        y: 1,
        surfacePresetId: 'water',
      );

      expect(role, SurfaceVariantRole.isolated);
    });

    test('resolves the middle of a horizontal line', () {
      const placements = [
        SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
      ];

      final role = resolveSurfaceVariantRoleForPlacement(
        placements: placements,
        x: 1,
        y: 1,
        surfacePresetId: 'water',
      );

      expect(role, SurfaceVariantRole.horizontal);
    });

    test('resolves the middle of a vertical line', () {
      const placements = [
        SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 2, surfacePresetId: 'water'),
      ];

      final role = resolveSurfaceVariantRoleForPlacement(
        placements: placements,
        x: 1,
        y: 1,
        surfacePresetId: 'water',
      );

      expect(role, SurfaceVariantRole.vertical);
    });

    test('resolves the center of a full 3x3 block as cross', () {
      const placements = [
        SurfaceCellPlacement(x: 0, y: 0, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 2, y: 0, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 0, y: 2, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 2, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 2, y: 2, surfacePresetId: 'water'),
      ];

      final role = resolveSurfaceVariantRoleForPlacement(
        placements: placements,
        x: 1,
        y: 1,
        surfacePresetId: 'water',
      );

      expect(role, SurfaceVariantRole.cross);
    });

    test('resolves a cardinal corner when two adjacent neighbors match', () {
      const placements = [
        SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
      ];

      final role = resolveSurfaceVariantRoleForPlacement(
        placements: placements,
        x: 1,
        y: 1,
        surfacePresetId: 'water',
      );

      expect(role, SurfaceVariantRole.cornerNE);
    });

    test('does not connect adjacent placements from another preset', () {
      const placements = [
        SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'lava'),
        SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'lava'),
        SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'lava'),
        SurfaceCellPlacement(x: 1, y: 2, surfacePresetId: 'lava'),
      ];

      final role = resolveSurfaceVariantRoleForPlacement(
        placements: placements,
        x: 1,
        y: 1,
        surfacePresetId: 'water',
      );

      expect(role, SurfaceVariantRole.isolated);
    });

    test('is independent from placement ordering', () {
      const ordered = [
        SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 1, y: 2, surfacePresetId: 'water'),
        SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
      ];
      final reversed = ordered.reversed.toList(growable: false);

      final fromOrdered = resolveSurfaceVariantRoleForPlacement(
        placements: ordered,
        x: 1,
        y: 1,
        surfacePresetId: 'water',
      );
      final fromReversed = resolveSurfaceVariantRoleForPlacement(
        placements: reversed,
        x: 1,
        y: 1,
        surfacePresetId: 'water',
      );

      expect(fromOrdered, SurfaceVariantRole.cross);
      expect(fromReversed, fromOrdered);
    });
  });
}
