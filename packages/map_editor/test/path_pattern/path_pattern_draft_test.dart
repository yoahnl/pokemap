import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_draft.dart';

void main() {
  group('PathPatternDraft', () {
    test('creates an initial draft from the legacy cross center', () {
      final draft = createInitialPathPatternDraft(
        basePathPreset: _legacyPathPreset(id: 'legacy-water', crossSourceX: 7),
      );

      expect(draft.id, 'draft-path-pattern');
      expect(draft.name, 'Nouveau motif de chemin');
      expect(draft.basePathPresetId, 'legacy-water');
      expect(
          draft.centerPattern.size, PathCenterPatternSize(width: 1, height: 1));
      expect(draft.centerPattern.cellAt(0, 0).frames, [_frame(7)]);
      expect(draft.isDirty, isTrue);
      expect(draft.selectedCellX, 0);
      expect(draft.selectedCellY, 0);
      expect(draft.issues, isEmpty);
    });

    test('returns null when a manifest has no legacy base path preset', () {
      final draft = createInitialPathPatternDraftFromManifest(
        manifest: ProjectManifest(
          name: 'Project',
          maps: const [],
          tilesets: const [],
          surfaceCatalog: ProjectSurfaceCatalog(),
        ),
      );

      expect(draft, isNull);
    });

    test('resizes a 1x1 draft to a 2x2 center with copied cross frames', () {
      final base = _legacyPathPreset(id: 'legacy-water', crossSourceX: 3);
      final draft = createInitialPathPatternDraft(basePathPreset: base);

      final resized = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: base,
        width: 2,
        height: 2,
      );

      expect(resized.centerPattern.size,
          PathCenterPatternSize(width: 2, height: 2));
      expect(
          resized.centerPattern.cells.map((cell) => (cell.localX, cell.localY)),
          [
            (0, 0),
            (1, 0),
            (0, 1),
            (1, 1),
          ]);
      for (final cell in resized.centerPattern.cells) {
        expect(cell.frames, [_frame(3)]);
      }
    });

    test('resizes a 2x2 draft back to a valid 1x1 center', () {
      final base = _legacyPathPreset(id: 'legacy-water');
      final draft = resizePathPatternDraftCenter(
        draft: createInitialPathPatternDraft(basePathPreset: base),
        basePathPreset: base,
        width: 2,
        height: 2,
      );

      final resized = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: base,
        width: 1,
        height: 1,
      );

      expect(resized.centerPattern.size,
          PathCenterPatternSize(width: 1, height: 1));
      expect(resized.centerPattern.cells, hasLength(1));
      expect(resized.selectedCellX, 0);
      expect(resized.selectedCellY, 0);
    });

    test('changes base while preserving name and current size', () {
      final water = _legacyPathPreset(id: 'legacy-water', crossSourceX: 1);
      final sand = _legacyPathPreset(id: 'legacy-sand', crossSourceX: 9);
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(basePathPreset: water),
        'Nom conservé',
      );
      final twoByTwo = resizePathPatternDraftCenter(
        draft: draft,
        basePathPreset: water,
        width: 2,
        height: 2,
      );

      final changed = changePathPatternDraftBase(
        draft: twoByTwo,
        basePathPreset: sand,
      );

      expect(changed.name, 'Nom conservé');
      expect(changed.basePathPresetId, 'legacy-sand');
      expect(changed.centerPattern.size,
          PathCenterPatternSize(width: 2, height: 2));
      expect(changed.centerPattern.cellAt(1, 1).frames, [_frame(9)]);
    });

    test('empty draft name exposes a local nameRequired issue', () {
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(
            basePathPreset: _legacyPathPreset(id: 'legacy-water')),
        '   ',
      );

      expect(draft.issues, [PathPatternDraftIssueCode.nameRequired]);
    });
  });
}

ProjectPathPreset _legacyPathPreset({
  required String id,
  int crossSourceX = 0,
}) {
  return ProjectPathPreset(
    id: id,
    name: id,
    surfaceKind: PathSurfaceKind.water,
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [_frame(crossSourceX)],
      ),
    ],
  );
}

TilesetVisualFrame _frame(int sourceX) {
  return TilesetVisualFrame(
    source: TilesetSourceRect(x: sourceX, y: 0),
  );
}
