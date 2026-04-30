import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';

void main() {
  group('PathStudioNewPathDraft', () {
    test('creates an initial draft without a legacy ProjectPathPreset', () {
      final draft = createInitialPathStudioNewPathDraft();

      expect(draft.id, 'draft-new-path');
      expect(draft.name, 'Nouveau chemin');
      expect(draft.centerWidth, 1);
      expect(draft.centerHeight, 1);
      expect(draft.centerPatternLabel, '1×1');
      expect(draft.centerCellCount, 1);
      expect(draft.tilesetId, isNull);
      expect(draft.selectedCellX, 0);
      expect(draft.selectedCellY, 0);
      expect(draft.isDirty, isTrue);
      expect(draft.cells.map((cell) => cell.label), ['A']);
      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.tilesetNotConfigured,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('selects a tileset while preserving center size and selection', () {
      final draft = createInitialPathStudioNewPathDraft();

      final selected = selectPathStudioNewPathDraftTileset(
        draft,
        'tileset-main',
      );

      expect(selected.tilesetId, 'tileset-main');
      expect(selected.issues, [
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
      expect(selected.centerPatternLabel, '1×1');
      expect(selected.selectedCellX, 0);
      expect(selected.selectedCellY, 0);
      expect(selected.isDirty, isTrue);
    });

    test('assigns one V0 tile to the 1x1 cell and clears cell issue', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
      );

      final assigned = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      expect(assigned.configuredCellCount, 1);
      expect(assigned.issues, isEmpty);
      expect(
        assigned.selectedCell.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 2,
          sourceY: 3,
        ),
      );
      expect(
        assigned.selectedCell.tile!.toFrame(),
        const TilesetVisualFrame(
          tilesetId: 'tileset-main',
          source: TilesetSourceRect(x: 2, y: 3),
        ),
      );
    });

    test('keeps cells issue until every 2x2 cell has one tile', () {
      var draft = resizePathStudioNewPathDraftCenter(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        width: 2,
        height: 2,
      );

      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );
      expect(draft.configuredCellCount, 1);
      expect(
        draft.issues,
        contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured),
      );

      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 1,
        localY: 0,
        sourceX: 1,
        sourceY: 0,
      );
      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 1,
        sourceX: 0,
        sourceY: 1,
      );
      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 1,
        localY: 1,
        sourceX: 1,
        sourceY: 1,
      );

      expect(draft.configuredCellCount, 4);
      expect(
        draft.issues,
        isNot(contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured)),
      );
    });

    test('replaces a configured cell instead of adding a second frame', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
      );
      final first = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );

      final replaced = assignPathStudioNewPathDraftCellTile(
        draft: first,
        localX: 0,
        localY: 0,
        sourceX: 4,
        sourceY: 2,
      );

      expect(replaced.configuredCellCount, 1);
      expect(
        replaced.selectedCell.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 4,
          sourceY: 2,
        ),
      );
    });

    test('clears a configured required cell and restores cell issue', () {
      final assigned = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final cleared = clearPathStudioNewPathDraftCell(
        draft: assigned,
        localX: 0,
        localY: 0,
      );

      expect(cleared.configuredCellCount, 0);
      expect(cleared.selectedCell.tile, isNull);
      expect(
        cleared.issues,
        contains(PathStudioNewPathDraftIssueCode.cellsNotConfigured),
      );
    });

    test('resizes a 1x1 draft to 2x2 while preserving cell A only', () {
      final draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: draft,
        width: 2,
        height: 2,
      );

      expect(resized.tilesetId, 'tileset-main');
      expect(resized.centerPatternLabel, '2×2');
      expect(resized.centerCellCount, 4);
      expect(
        resized.cells.map((cell) => (cell.localX, cell.localY, cell.label)),
        [
          (0, 0, 'A'),
          (1, 0, 'B'),
          (0, 1, 'C'),
          (1, 1, 'D'),
        ],
      );
      expect(
        resized.cells.first.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 2,
          sourceY: 3,
        ),
      );
      expect(resized.cells.skip(1).every((cell) => cell.tile == null), isTrue);
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('resizes a 2x2 draft back to 1x1 and keeps only cell A', () {
      var twoByTwo = resizePathStudioNewPathDraftCenter(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        width: 2,
        height: 2,
      );
      twoByTwo = assignPathStudioNewPathDraftCellTile(
        draft: twoByTwo,
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );
      twoByTwo = assignPathStudioNewPathDraftCellTile(
        draft: twoByTwo,
        localX: 1,
        localY: 1,
        sourceX: 4,
        sourceY: 4,
      );
      final selected = selectPathStudioNewPathDraftCell(
        draft: twoByTwo,
        localX: 1,
        localY: 1,
      );

      final resized = resizePathStudioNewPathDraftCenter(
        draft: selected,
        width: 1,
        height: 1,
      );

      expect(resized.centerWidth, 1);
      expect(resized.centerHeight, 1);
      expect(resized.centerCellCount, 1);
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
      expect(
        resized.selectedCell.tile,
        const PathStudioNewPathDraftTile(
          tilesetId: 'tileset-main',
          sourceX: 0,
          sourceY: 0,
        ),
      );
      expect(resized.configuredCellCount, 1);
    });

    test('selecting another tileset clears cell assignments deterministically',
        () {
      final assigned = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 2,
        sourceY: 3,
      );

      final changed = selectPathStudioNewPathDraftTileset(
        assigned,
        'tileset-extra',
      );

      expect(changed.tilesetId, 'tileset-extra');
      expect(changed.configuredCellCount, 0);
      expect(changed.selectedCell.tile, isNull);
      expect(changed.issues, [
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('renames the draft locally', () {
      final draft = renamePathStudioNewPathDraft(
        selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        'Route claire',
      );

      expect(draft.name, 'Route claire');
      expect(draft.tilesetId, 'tileset-main');
      expect(draft.isDirty, isTrue);
    });

    test('empty name after tileset selection exposes only remaining issues',
        () {
      final draft = renamePathStudioNewPathDraft(
        selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        '   ',
      );

      expect(draft.issues, [
        PathStudioNewPathDraftIssueCode.nameRequired,
        PathStudioNewPathDraftIssueCode.cellsNotConfigured,
      ]);
    });

    test('selects a placeholder cell by exact local coordinates', () {
      final draft = resizePathStudioNewPathDraftCenter(
        draft: createInitialPathStudioNewPathDraft(),
        width: 2,
        height: 2,
      );

      final selected = selectPathStudioNewPathDraftCell(
        draft: draft,
        localX: 1,
        localY: 0,
      );

      expect(selected.selectedCellX, 1);
      expect(selected.selectedCellY, 0);
      expect(selected.selectedCell.label, 'B');
    });
  });
}
