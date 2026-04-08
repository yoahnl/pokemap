import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/element_collision_authoring_service.dart';
import 'package:map_editor/src/application/services/element_collision_base_cells_from_padding_service.dart';
import 'package:map_editor/src/application/services/element_collision_cells_overlay_service.dart';

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
    const service = ElementCollisionAuthoringService();
    const source = TilesetSourceRect(x: 0, y: 0, width: 3, height: 2);

    test('rebuilds a coherent final profile with no overrides', () {
      final profile = service.rebuild(
        source: source,
        tileWidth: 16,
        tileHeight: 16,
        padding: const WarpTriggerPadding(right: 16),
      );

      expect(profile.source, ElementCollisionProfileSource.generated);
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
  });
}
