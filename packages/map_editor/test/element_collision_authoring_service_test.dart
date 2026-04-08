import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/element_collision_authoring_service.dart';
import 'package:map_editor/src/application/services/element_collision_base_cells_from_padding_service.dart';
import 'package:map_editor/src/application/services/element_collision_cells_overlay_service.dart';
import 'package:map_editor/src/application/services/element_collision_shape_rasterizer_service.dart';

void main() {
  group('ElementCollisionBaseCellsFromPaddingService', () {
    const service = ElementCollisionBaseCellsFromPaddingService();
    const source = TilesetSourceRect(x: 0, y: 0, width: 2, height: 2);

    test('derives full base when padding is zero', () {
      final cells = service.derive(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        padding: const WarpTriggerPadding(),
      );

      expect(
        cells,
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );
    });

    test('removes cells fully trimmed by padding', () {
      final cells = service.derive(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        padding: const WarpTriggerPadding(left: 16),
      );

      expect(
        cells,
        const <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 1),
        ],
      );
    });

    test('returns empty when padding fully trims the source', () {
      final cells = service.derive(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        padding: const WarpTriggerPadding(left: 32),
      );

      expect(cells, isEmpty);
    });
  });

  group('ElementCollisionCellsOverlayService', () {
    const service = ElementCollisionCellsOverlayService();

    test('adds manual cells to base', () {
      final finalCells = service.apply(
        baseCells: const <GridPos>[GridPos(x: 0, y: 0)],
        manualAddedCells: const <GridPos>[GridPos(x: 1, y: 0)],
      );

      expect(
        finalCells,
        const <GridPos>[GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
      );
    });

    test('removes cells from base', () {
      final finalCells = service.apply(
        baseCells: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
        ],
        manualRemovedCells: const <GridPos>[GridPos(x: 1, y: 0)],
      );

      expect(finalCells, const <GridPos>[GridPos(x: 0, y: 0)]);
    });

    test('combines add and remove with stable unique ordering', () {
      final finalCells = service.apply(
        baseCells: const <GridPos>[
          GridPos(x: 1, y: 1),
          GridPos(x: 0, y: 0),
          GridPos(x: 0, y: 0),
        ],
        manualAddedCells: const <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 1, y: 0),
        ],
        manualRemovedCells: const <GridPos>[
          GridPos(x: 1, y: 1),
          GridPos(x: 5, y: 5),
        ],
      );

      expect(
        finalCells,
        const <GridPos>[GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
      );
    });
  });

  group('ElementCollisionAuthoringService', () {
    const service = ElementCollisionAuthoringService(
      shapeRasterizerService: ElementCollisionShapeRasterizerService(),
    );
    const source = TilesetSourceRect(x: 0, y: 0, width: 3, height: 2);

    test('rebuilds a coherent final profile with no overrides', () {
      final profile = service.rebuild(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        padding: const WarpTriggerPadding(right: 16),
      );

      expect(profile.source, ElementCollisionProfileSource.generated);
      expect(profile.shapeCells, isEmpty);
      expect(profile.manualAddedCells, isEmpty);
      expect(profile.manualRemovedCells, isEmpty);
      expect(
        profile.cells,
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );
    });

    test('recalculates after padding change while preserving overrides', () {
      final initial = service.rebuild(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        padding: const WarpTriggerPadding(),
        manualAddedCells: const <GridPos>[GridPos(x: 2, y: 0)],
        manualRemovedCells: const <GridPos>[GridPos(x: 0, y: 0)],
      );

      final updated = service.recalculateFromPadding(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        padding: const WarpTriggerPadding(left: 16),
        current: initial,
      );

      expect(updated.manualAddedCells, initial.manualAddedCells);
      expect(updated.manualRemovedCells, initial.manualRemovedCells);
      expect(
        updated.cells,
        const <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ],
      );
    });

    test('empty overrides behave like no overrides', () {
      final profile = service.rebuild(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        manualAddedCells: const <GridPos>[],
        manualRemovedCells: const <GridPos>[],
      );

      expect(profile.source, ElementCollisionProfileSource.generated);
      expect(profile.cells.length, 6);
    });

    test('shape-authored rebuild uses shape cells as the real base', () {
      final profile = service.rebuild(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        sourceMode: ElementCollisionProfileSource.manual,
        padding: const WarpTriggerPadding(),
        shapeCells: const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );

      expect(profile.source, ElementCollisionProfileSource.manual);
      expect(
        profile.shapeCells,
        const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );
      expect(
        profile.cells,
        const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );
    });

    test('reset overrides restores the base only', () {
      final current = service.rebuild(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        manualAddedCells: const <GridPos>[GridPos(x: 2, y: 0)],
        manualRemovedCells: const <GridPos>[GridPos(x: 0, y: 0)],
      );

      final reset = service.resetOverrides(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        current: current,
      );

      expect(reset.manualAddedCells, isEmpty);
      expect(reset.manualRemovedCells, isEmpty);
      expect(reset.cells.length, 6);
    });

    test('add mode mutates manual additions', () {
      final profile = service.applyAddModeTap(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        cell: const GridPos(x: 2, y: 0),
        current: service.clearAllCollision(
          source: source,
          tileWidth: 16,
          tileHeight: 16,
        ),
      );

      expect(profile.manualAddedCells, const <GridPos>[GridPos(x: 2, y: 0)]);
      expect(profile.cells, const <GridPos>[GridPos(x: 2, y: 0)]);
    });

    test('remove mode mutates manual removals', () {
      final profile = service.applyRemoveModeTap(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        cell: const GridPos(x: 1, y: 0),
        current: service.rebuild(
          source: source,
          tileWidth: 16,
          tileHeight: 16,
        ),
      );

      expect(profile.manualRemovedCells, const <GridPos>[GridPos(x: 1, y: 0)]);
      expect(
        profile.cells,
        isNot(contains(const GridPos(x: 1, y: 0))),
      );
    });

    test('clear all empties the final collision while keeping a valid profile',
        () {
      final profile = service.clearAllCollision(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
      );

      expect(profile.cells, isEmpty);
      expect(profile.manualAddedCells, isEmpty);
      expect(profile.manualRemovedCells.length, source.width * source.height);
    });

    test('applyCells combines add and remove deterministically', () {
      final initial = service.rebuild(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
      );

      final removed = service.applyCells(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        cells: const <GridPos>[GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
        operation: ElementCollisionAuthoringOperation.remove,
        current: initial,
      );
      final addedBack = service.applyCells(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        cells: const <GridPos>[GridPos(x: 1, y: 0)],
        operation: ElementCollisionAuthoringOperation.add,
        current: removed,
      );

      expect(
        addedBack.cells,
        isNot(contains(const GridPos(x: 0, y: 0))),
      );
      expect(
        addedBack.cells,
        contains(const GridPos(x: 1, y: 0)),
      );
    });

    test('applyPolygon adds a rasterized polygon to the final profile', () {
      final profile = service.applyPolygon(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        vertices: const <Offset>[
          Offset(0, 0),
          Offset(3, 0),
          Offset(3, 1),
          Offset(0, 1),
        ],
        operation: ElementCollisionAuthoringOperation.add,
        current: service.clearAllCollision(
          source: source,
          tileWidth: 16,
          tileHeight: 16,
        ),
      );

      expect(
        profile.cells,
        const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
        ],
      );
      expect(profile.source, ElementCollisionProfileSource.manual);
      expect(profile.shapeCells, profile.cells);
      expect(profile.manualAddedCells, isEmpty);
      expect(profile.manualRemovedCells, isEmpty);
    });

    test('applyBrushStroke removes cells crossed by the stroke', () {
      final profile = service.applyBrushStroke(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        points: const <Offset>[
          Offset(0.2, 0.2),
          Offset(2.7, 0.2),
        ],
        operation: ElementCollisionAuthoringOperation.remove,
        current: service.rebuild(
          source: source,
          tileWidth: 16,
          tileHeight: 16,
        ),
      );

      expect(
        profile.cells,
        isNot(contains(const GridPos(x: 0, y: 0))),
      );
      expect(
        profile.cells,
        isNot(contains(const GridPos(x: 1, y: 0))),
      );
      expect(
        profile.cells,
        isNot(contains(const GridPos(x: 2, y: 0))),
      );
    });

    test(
        'legacy manual profile with full padding base is migrated to shape base',
        () {
      const buggyLegacyProfile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        padding: WarpTriggerPadding(),
        cells: <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
        ],
        manualAddedCells: <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );

      final snapshot = service.describe(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        profile: buggyLegacyProfile,
      );

      expect(snapshot.source, ElementCollisionProfileSource.manual);
      expect(
        snapshot.shapeCells,
        const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );
      expect(snapshot.manualAddedCells, isEmpty);
      expect(snapshot.manualRemovedCells, isEmpty);
      expect(
        snapshot.finalCells,
        const <GridPos>[
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
        ],
      );
    });

    test(
        'real legacy house profile no longer resolves to the full 6x7 padding base',
        () {
      const houseSource = TilesetSourceRect(x: 0, y: 0, width: 6, height: 7);
      const legacyHouseProfile = ElementCollisionProfile(
        source: ElementCollisionProfileSource.manual,
        padding: WarpTriggerPadding(),
        cells: <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 2, y: 0),
          GridPos(x: 3, y: 0),
          GridPos(x: 4, y: 0),
          GridPos(x: 5, y: 0),
          GridPos(x: 0, y: 1),
          GridPos(x: 1, y: 1),
          GridPos(x: 2, y: 1),
          GridPos(x: 3, y: 1),
          GridPos(x: 4, y: 1),
          GridPos(x: 5, y: 1),
          GridPos(x: 0, y: 2),
          GridPos(x: 1, y: 2),
          GridPos(x: 2, y: 2),
          GridPos(x: 3, y: 2),
          GridPos(x: 4, y: 2),
          GridPos(x: 5, y: 2),
          GridPos(x: 0, y: 3),
          GridPos(x: 1, y: 3),
          GridPos(x: 2, y: 3),
          GridPos(x: 3, y: 3),
          GridPos(x: 4, y: 3),
          GridPos(x: 5, y: 3),
          GridPos(x: 0, y: 4),
          GridPos(x: 1, y: 4),
          GridPos(x: 2, y: 4),
          GridPos(x: 3, y: 4),
          GridPos(x: 4, y: 4),
          GridPos(x: 5, y: 4),
          GridPos(x: 0, y: 5),
          GridPos(x: 1, y: 5),
          GridPos(x: 2, y: 5),
          GridPos(x: 3, y: 5),
          GridPos(x: 4, y: 5),
          GridPos(x: 5, y: 5),
          GridPos(x: 0, y: 6),
          GridPos(x: 1, y: 6),
          GridPos(x: 2, y: 6),
          GridPos(x: 3, y: 6),
          GridPos(x: 4, y: 6),
          GridPos(x: 5, y: 6),
        ],
        manualAddedCells: <GridPos>[
          GridPos(x: 0, y: 3),
          GridPos(x: 1, y: 3),
          GridPos(x: 2, y: 3),
          GridPos(x: 3, y: 3),
          GridPos(x: 4, y: 3),
          GridPos(x: 5, y: 3),
          GridPos(x: 1, y: 4),
          GridPos(x: 2, y: 4),
          GridPos(x: 3, y: 4),
          GridPos(x: 4, y: 4),
          GridPos(x: 1, y: 5),
          GridPos(x: 2, y: 5),
          GridPos(x: 3, y: 5),
          GridPos(x: 4, y: 5),
        ],
      );

      final snapshot = service.describe(
        source: houseSource,
        tileWidth: 16,
        tileHeight: 16,
        profile: legacyHouseProfile,
      );

      expect(snapshot.source, ElementCollisionProfileSource.manual);
      expect(snapshot.finalCells.length, 14);
      expect(snapshot.finalCells, equals(snapshot.shapeCells));
      expect(
        snapshot.finalCells,
        const <GridPos>[
          GridPos(x: 0, y: 3),
          GridPos(x: 1, y: 3),
          GridPos(x: 2, y: 3),
          GridPos(x: 3, y: 3),
          GridPos(x: 4, y: 3),
          GridPos(x: 5, y: 3),
          GridPos(x: 1, y: 4),
          GridPos(x: 2, y: 4),
          GridPos(x: 3, y: 4),
          GridPos(x: 4, y: 4),
          GridPos(x: 1, y: 5),
          GridPos(x: 2, y: 5),
          GridPos(x: 3, y: 5),
          GridPos(x: 4, y: 5),
        ],
      );
    });

    test(
        'polygon on a 6x7 source with zero padding does not rebuild to the full grid',
        () {
      const houseSource = TilesetSourceRect(x: 0, y: 0, width: 6, height: 7);
      final profile = service.applyPolygon(
        source: houseSource,
        tileWidth: 16,
        tileHeight: 16,
        vertices: const <Offset>[
          Offset(0.2, 3.0),
          Offset(5.8, 3.0),
          Offset(4.8, 5.8),
          Offset(1.2, 5.8),
        ],
        operation: ElementCollisionAuthoringOperation.add,
      );

      expect(profile.padding, const WarpTriggerPadding());
      expect(profile.source, ElementCollisionProfileSource.manual);
      expect(profile.cells, isNotEmpty);
      expect(profile.cells.length,
          lessThan(houseSource.width * houseSource.height));
      expect(profile.cells, equals(profile.shapeCells));
    });
  });
}
