import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_pattern_draft.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';
import 'package:map_editor/src/features/path_studio/path_studio_save_plan.dart';

void main() {
  group('PathStudioSavePlan', () {
    test('slugifies proposed ids with a stable fallback', () {
      expect(pathStudioSlugifyId('Nouveau chemin'), 'nouveau-chemin');
      expect(pathStudioSlugifyId('  Route   eau!! '), 'route-eau');
      expect(pathStudioSlugifyId('   '), 'path-pattern');
    });

    test('keeps a new path without tileset non-saveable', () {
      final plan = createPathStudioNewPathSavePlan(
        manifest: _manifest(),
        draft: createInitialPathStudioNewPathDraft(),
      );

      expect(plan.kind, PathStudioSaveFlowKind.newPath);
      expect(plan.proposedBasePathPresetId, 'nouveau-chemin');
      expect(plan.proposedPathPatternPresetId, 'nouveau-chemin-pattern');
      expect(plan.configuredCellCount, 0);
      expect(plan.centerCellCount, 1);
      expect(plan.centerPattern, isNull);
      expect(plan.canSaveNow, isFalse);
      expect(plan.issues, [
        PathStudioSaveIssueCode.tilesetRequired,
        PathStudioSaveIssueCode.centerCellsRequired,
        PathStudioSaveIssueCode.pathVariantMappingRequired,
      ]);
    });

    test('builds a local center pattern for a complete new path center', () {
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

      final plan = createPathStudioNewPathSavePlan(
        manifest: _manifest(),
        draft: draft,
      );

      expect(plan.centerPattern, isNotNull);
      expect(
          plan.centerPattern!.size, PathCenterPatternSize(width: 1, height: 1));
      expect(plan.centerPattern!.cellAt(0, 0).frames, [
        const TilesetVisualFrame(
          tilesetId: 'tileset-main',
          source: TilesetSourceRect(x: 2, y: 3),
          durationMs: 200,
        ),
      ]);
      expect(
        plan.issues,
        isNot(contains(PathStudioSaveIssueCode.centerCellsRequired)),
      );
      expect(
        plan.issues,
        contains(PathStudioSaveIssueCode.pathVariantMappingRequired),
      );
      expect(plan.canSaveNow, isFalse);
    });

    test('builds a row-major 2x2 local center pattern for new path', () {
      var draft = resizePathStudioNewPathDraftCenter(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        width: 2,
        height: 2,
      );
      draft = _assign(draft, localX: 0, localY: 0, sourceX: 1, sourceY: 0);
      draft = _assign(draft, localX: 1, localY: 0, sourceX: 2, sourceY: 0);
      draft = _assign(draft, localX: 0, localY: 1, sourceX: 3, sourceY: 0);
      draft = _assign(draft, localX: 1, localY: 1, sourceX: 4, sourceY: 0);

      final plan = createPathStudioNewPathSavePlan(
        manifest: _manifest(),
        draft: draft,
      );
      final pattern = plan.centerPattern!;

      expect(pattern.size, PathCenterPatternSize(width: 2, height: 2));
      expect(
        pattern.cells.map((cell) => (cell.localX, cell.localY)),
        [
          (0, 0),
          (1, 0),
          (0, 1),
          (1, 1),
        ],
      );
      expect(pattern.cellAt(0, 0).frames.single.source,
          const TilesetSourceRect(x: 1, y: 0));
      expect(pattern.cellAt(1, 0).frames.single.source,
          const TilesetSourceRect(x: 2, y: 0));
      expect(pattern.cellAt(0, 1).frames.single.source,
          const TilesetSourceRect(x: 3, y: 0));
      expect(pattern.cellAt(1, 1).frames.single.source,
          const TilesetSourceRect(x: 4, y: 0));
    });

    test('prepares a ProjectPathPatternPreset for a valid legacy draft', () {
      final base = _legacyPathPreset(id: 'legacy-water');
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(basePathPreset: base, sortOrder: 7),
        'Motif eau',
      );

      final plan = createPathStudioLegacyPathPatternSavePlan(
        manifest: _manifest(pathPresets: [base]),
        draft: draft,
      );

      expect(plan.kind, PathStudioSaveFlowKind.legacyPathPattern);
      expect(plan.proposedPathPatternPresetId, 'motif-eau');
      expect(plan.canSaveNow, isTrue);
      expect(plan.issues, isEmpty);
      expect(plan.request, isNotNull);
      expect(plan.request!.preset.id, 'motif-eau');
      expect(plan.request!.preset.name, 'Motif eau');
      expect(plan.request!.preset.basePathPresetId, 'legacy-water');
      expect(plan.request!.preset.centerPattern, draft.centerPattern);
      expect(plan.request!.preset.sortOrder, 7);
    });

    test('blocks a legacy draft with an empty name', () {
      final base = _legacyPathPreset(id: 'legacy-water');
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(basePathPreset: base),
        '   ',
      );

      final plan = createPathStudioLegacyPathPatternSavePlan(
        manifest: _manifest(pathPresets: [base]),
        draft: draft,
      );

      expect(plan.canSaveNow, isFalse);
      expect(plan.request, isNull);
      expect(plan.issues, contains(PathStudioSaveIssueCode.nameRequired));
    });

    test('blocks duplicate proposed PathPattern ids', () {
      final base = _legacyPathPreset(id: 'legacy-water');
      final draft = renamePathPatternDraft(
        createInitialPathPatternDraft(basePathPreset: base),
        'Motif eau',
      );

      final plan = createPathStudioLegacyPathPatternSavePlan(
        manifest: _manifest(
          pathPresets: [base],
          pathPatternPresets: [
            _pathPatternPreset(id: 'motif-eau', basePathPresetId: base.id),
          ],
        ),
        draft: draft,
      );

      expect(plan.canSaveNow, isFalse);
      expect(plan.request, isNull);
      expect(
        plan.issues,
        contains(PathStudioSaveIssueCode.duplicatePathPatternId),
      );
    });
  });
}

PathStudioNewPathDraft _assign(
  PathStudioNewPathDraft draft, {
  required int localX,
  required int localY,
  required int sourceX,
  required int sourceY,
}) {
  return assignPathStudioNewPathDraftCellTile(
    draft: draft,
    localX: localX,
    localY: localY,
    sourceX: sourceX,
    sourceY: sourceY,
  );
}

ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: ProjectSurfaceCatalog(),
  );
}

ProjectPathPreset _legacyPathPreset({
  required String id,
}) {
  return ProjectPathPreset(
    id: id,
    name: id,
    surfaceKind: PathSurfaceKind.water,
    variants: [
      PathPresetVariantMapping(
        variant: TerrainPathVariant.cross,
        frames: [_frame(0)],
      ),
    ],
  );
}

ProjectPathPatternPreset _pathPatternPreset({
  required String id,
  required String basePathPresetId,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: id,
    basePathPresetId: basePathPresetId,
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 1, height: 1),
      cells: [
        PathCenterPatternCell(localX: 0, localY: 0, frames: [_frame(0)]),
      ],
    ),
  );
}

TilesetVisualFrame _frame(int sourceX) {
  return TilesetVisualFrame(source: TilesetSourceRect(x: sourceX, y: 0));
}
