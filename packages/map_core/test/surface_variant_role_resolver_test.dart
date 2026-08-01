import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveSurfaceVariantRoleAt', () {
    test('uses the callback for cardinal and diagonal connectivity', () {
      const occupied = <(int, int)>{
        (0, 0),
        (1, 0),
        (0, 1),
        (1, 1),
        (2, 1),
        (0, 2),
        (1, 2),
        (2, 2),
      };

      expect(
        resolveSurfaceVariantRoleAt(
          x: 1,
          y: 1,
          matchesAt: (x, y) => occupied.contains((x, y)),
        ),
        SurfaceVariantRole.innerCornerNE,
      );
    });

    test('rejects only a negative queried center, not neighbor probes', () {
      expect(
        resolveSurfaceVariantRoleAt(
          x: 0,
          y: 0,
          matchesAt: (x, y) => x == 0 && y == 0,
        ),
        SurfaceVariantRole.isolated,
      );
      expect(
        () => resolveSurfaceVariantRoleAt(
          x: -1,
          y: 0,
          matchesAt: (_, __) => false,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

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

  group('SurfacePlacementTopology', () {
    test('legacy adapter validates a query before enumerating placements', () {
      var enumerated = false;

      Iterable<SurfaceCellPlacement> placements() sync* {
        enumerated = true;
        throw StateError('must not enumerate invalid queries');
      }

      expect(
        () => resolveSurfaceVariantRoleForPlacement(
          placements: placements(),
          x: -1,
          y: 0,
          surfacePresetId: 'water',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(enumerated, isFalse);
    });

    test('indexes its source once and reuses occupancy for every role lookup',
        () {
      var visitedPlacements = 0;
      final placements = <SurfaceCellPlacement>[
        for (var y = 0; y < 50; y++)
          for (var x = 0; x < 50; x++)
            SurfaceCellPlacement(
              x: x,
              y: y,
              surfacePresetId: 'water',
            ),
      ];

      Iterable<SurfaceCellPlacement> countedPlacements() sync* {
        for (final placement in placements) {
          visitedPlacements += 1;
          yield placement;
        }
      }

      final topology = SurfacePlacementTopology(countedPlacements());
      expect(visitedPlacements, placements.length);

      for (final placement in placements) {
        expect(
          topology.roleAt(
            x: placement.x,
            y: placement.y,
            surfacePresetId: placement.surfacePresetId,
          ),
          isA<SurfaceVariantRole>(),
        );
      }

      expect(
        visitedPlacements,
        placements.length,
        reason: 'Role lookup must not enumerate the source placements again.',
      );
      expect(topology.occupiedCoordinateCount, placements.length);
    });

    test('keeps presets isolated and normalizes ids without changing roles',
        () {
      final topology = SurfacePlacementTopology(
        const <SurfaceCellPlacement>[
          SurfaceCellPlacement(x: 0, y: 1, surfacePresetId: ' water '),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 2, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 1, y: 0, surfacePresetId: 'lava'),
        ],
      );

      expect(
        topology.roleAt(x: 1, y: 1, surfacePresetId: ' water '),
        SurfaceVariantRole.horizontal,
      );
      expect(
        topology.roleAt(x: 1, y: 0, surfacePresetId: 'lava'),
        SurfaceVariantRole.isolated,
      );
    });

    test('deduplicates occupancy and retains validation guards', () {
      final topology = SurfacePlacementTopology(
        const <SurfaceCellPlacement>[
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
          SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
        ],
      );

      expect(topology.occupiedCoordinateCount, 1);
      expect(
        () => topology.roleAt(x: -1, y: 0, surfacePresetId: 'water'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => topology.roleAt(x: 0, y: 0, surfacePresetId: '   '),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
