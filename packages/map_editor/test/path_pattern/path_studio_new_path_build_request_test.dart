import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_build_request.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';

void main() {
  group('PathStudioNewPathBuildPlan', () {
    test('variants partiels produisent un warning non bloquant', () {
      var draft = _readyCenterDraft();
      draft = assignPathStudioNewPathDraftVariantTile(
        draft: draft,
        variant: PathStudioNewPathDraft.requiredVariants.first,
        sourceX: 1,
        sourceY: 1,
      );

      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: draft,
      );

      expect(plan.blockingIssues, isEmpty);
      expect(plan.canBuildRequest, isTrue);
      expect(
        plan.warnings.any(
          (issue) =>
              issue.code == PathStudioNewPathBuildIssueCode.partialVariantCoverage,
        ),
        isTrue,
      );
    });

    test('tous les variants configurés suppriment le warning partiel', () {
      var draft = _readyCenterDraft();
      for (var i = 0; i < PathStudioNewPathDraft.requiredVariants.length; i += 1) {
        draft = assignPathStudioNewPathDraftVariantTile(
          draft: draft,
          variant: PathStudioNewPathDraft.requiredVariants[i],
          sourceX: i,
          sourceY: 0,
        );
      }

      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: draft,
      );

      expect(plan.blockingIssues, isEmpty);
      expect(plan.canBuildRequest, isTrue);
      expect(
        plan.warnings.any(
          (issue) =>
              issue.code == PathStudioNewPathBuildIssueCode.partialVariantCoverage,
        ),
        isFalse,
      );
    });

    test('zéro variant configuré autorise la requête avec warning fort', () {
      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: _readyCenterDraft(),
      );

      expect(plan.blockingIssues, isEmpty);
      expect(plan.canBuildRequest, isTrue);
      expect(
        plan.warnings.any(
          (issue) =>
              issue.code ==
              PathStudioNewPathBuildIssueCode.noVariantMappingsConfigured,
        ),
        isTrue,
      );
    });

    test('cross est exclu et documenté en warning', () {
      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: _readyCenterDraft(),
      );

      expect(
        plan.warnings.any(
          (issue) =>
              issue.code ==
              PathStudioNewPathBuildIssueCode.crossHandledByCenterPattern,
        ),
        isTrue,
      );
    });

    test('nom manquant est bloquant', () {
      final draft = renamePathStudioNewPathDraft(_readyCenterDraft(), '  ');
      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: draft,
      );
      expect(
        plan.blockingIssues.any(
          (issue) => issue.code == PathStudioNewPathBuildIssueCode.nameRequired,
        ),
        isTrue,
      );
      expect(plan.canBuildRequest, isFalse);
    });

    test('tileset manquant est bloquant', () {
      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: createInitialPathStudioNewPathDraft(),
      );
      expect(
        plan.blockingIssues.any(
          (issue) =>
              issue.code == PathStudioNewPathBuildIssueCode.tilesetRequired,
        ),
        isTrue,
      );
    });

    test('centre incomplet est bloquant', () {
      final draft = selectPathStudioNewPathDraftTileset(
        createInitialPathStudioNewPathDraft(),
        'tileset-main',
      );
      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: draft,
      );
      expect(
        plan.blockingIssues.any(
          (issue) =>
              issue.code == PathStudioNewPathBuildIssueCode.centerCellsRequired,
        ),
        isTrue,
      );
    });

    test('collision id base path est bloquante', () {
      final draft = _readyCenterDraft();
      final manifest = _manifest(
        pathPresets: [
          const ProjectPathPreset(id: 'nouveau-chemin', name: 'used'),
        ],
      );
      final plan = createPathStudioNewPathBuildPlan(
        manifest: manifest,
        draft: draft,
      );
      expect(
        plan.blockingIssues.any(
          (issue) =>
              issue.code ==
              PathStudioNewPathBuildIssueCode.duplicateBasePathPresetId,
        ),
        isTrue,
      );
    });

    test('collision id path pattern est bloquante', () {
      final draft = _readyCenterDraft();
      final manifest = _manifest(
        pathPatternPresets: [
          ProjectPathPatternPreset(
            id: 'nouveau-chemin-pattern',
            name: 'used',
            basePathPresetId: 'legacy',
            centerPattern: _singleCellPattern(),
          ),
        ],
      );
      final plan = createPathStudioNewPathBuildPlan(
        manifest: manifest,
        draft: draft,
      );
      expect(
        plan.blockingIssues.any(
          (issue) =>
              issue.code ==
              PathStudioNewPathBuildIssueCode.duplicatePathPatternPresetId,
        ),
        isTrue,
      );
    });

    test('build request construit les deux presets sans muter le manifest', () {
      final manifest = _manifest();
      final plan = createPathStudioNewPathBuildPlan(
        manifest: manifest,
        draft: _readyCenterDraft(),
      );
      final request = plan.buildRequest;
      expect(request, isNotNull);
      expect(plan.canBuildRequest, isTrue);
      expect(request!.basePathPreset.id, 'nouveau-chemin');
      expect(request.pathPatternPreset.basePathPresetId, 'nouveau-chemin');
      expect(request.basePathPreset.variants, isEmpty);
      expect(manifest.pathPresets, isEmpty);
      expect(manifest.pathPatternPresets, isEmpty);
    });

    test('basePathPreset inclut seulement les variants configurés', () {
      var draft = _readyCenterDraft();
      draft = assignPathStudioNewPathDraftVariantTile(
        draft: draft,
        variant: PathStudioNewPathDraft.requiredVariants[0],
        sourceX: 3,
        sourceY: 2,
      );
      draft = assignPathStudioNewPathDraftVariantTile(
        draft: draft,
        variant: PathStudioNewPathDraft.requiredVariants[1],
        sourceX: 4,
        sourceY: 2,
      );

      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: draft,
      );
      final variants = plan.buildRequest!.basePathPreset.variants;
      expect(variants.length, 2);
      expect(variants[0].frames.single.source, const TilesetSourceRect(x: 3, y: 2));
      expect(variants[1].frames.single.source, const TilesetSourceRect(x: 4, y: 2));
      expect(
        variants.any((mapping) => mapping.variant == TerrainPathVariant.cross),
        isFalse,
      );
    });

    test('build request conserve toutes les frames animées du centre', () {
      var draft = _readyCenterDraft();
      draft = appendPathStudioNewPathDraftCenterFrame(
        draft: draft,
        localX: 0,
        localY: 0,
      );
      draft = assignPathStudioNewPathDraftCellTile(
        draft: draft,
        localX: 0,
        localY: 0,
        sourceX: 7,
        sourceY: 5,
      );
      draft = updatePathStudioNewPathDraftCenterFrameDuration(
        draft: draft,
        localX: 0,
        localY: 0,
        frameIndex: 0,
        durationMs: 110,
      );
      draft = updatePathStudioNewPathDraftCenterFrameDuration(
        draft: draft,
        localX: 0,
        localY: 0,
        frameIndex: 1,
        durationMs: 220,
      );

      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: draft,
      );
      final frames = plan.buildRequest!.pathPatternPreset.centerPattern.cells.first.frames;

      expect(frames.length, 2);
      expect(frames[0].source, const TilesetSourceRect(x: 2, y: 3));
      expect(frames[1].source, const TilesetSourceRect(x: 7, y: 5));
      expect(frames[0].durationMs, 110);
      expect(frames[1].durationMs, 220);
      expect(frames[0].tilesetId, 'tileset-main');
      expect(frames[1].tilesetId, 'tileset-main');
    });

    test('assistant séquence: centerPattern porte 4 frames stepX=3 sans perte', () {
      var draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 0,
        sourceY: 0,
      );
      draft = switch (generatePathStudioCenterAnimationSequence(
        draft: draft,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 4,
        stepX: 3,
        stepY: 0,
        durationMs: 200,
      )) {
        PathStudioCenterAnimationSequenceSuccess(:final draft) => draft,
        PathStudioCenterAnimationSequenceFailure(:final message) =>
          throw StateError(message),
      };

      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: draft,
      );
      final frames =
          plan.buildRequest!.pathPatternPreset.centerPattern.cells.single.frames;
      expect(frames.length, 4);
      expect(frames.map((f) => f.source.x), equals([0, 3, 6, 9]));
      expect(frames.every((f) => f.durationMs == 200), isTrue);
      expect(frames.every((f) => f.tilesetId == 'tileset-main'), isTrue);
    });
  });
}

PathStudioNewPathDraft _readyCenterDraft() {
  return assignPathStudioNewPathDraftCellTile(
    draft: selectPathStudioNewPathDraftTileset(
      createInitialPathStudioNewPathDraft(),
      'tileset-main',
    ),
    localX: 0,
    localY: 0,
    sourceX: 2,
    sourceY: 3,
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

PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [
          const TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
  );
}
