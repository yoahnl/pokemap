import 'package:flutter_test/flutter_test.dart';
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

    test('resizes a 1x1 draft to 2x2 placeholder cells', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
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
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('resizes a 2x2 draft back to 1x1 and clamps selection', () {
      final twoByTwo = resizePathStudioNewPathDraftCenter(
        draft: createInitialPathStudioNewPathDraft(),
        width: 2,
        height: 2,
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
