import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_build_request.dart';
import 'package:map_editor/src/features/path_studio/path_studio_new_path_draft.dart';
import 'package:map_editor/src/features/path_studio/path_studio_save_flow.dart';

void main() {
  group('applyNewPathBuildRequestToManifest', () {
    test('ajoute basePathPreset et pathPatternPreset en fin de liste', () {
      final manifest = _manifest(
        pathPresets: [
          const ProjectPathPreset(id: 'existing-base', name: 'Existing base'),
        ],
        pathPatternPresets: [
          _patternPreset(
              id: 'existing-pattern', basePathPresetId: 'existing-base'),
        ],
      );
      final request = _request(baseId: 'new-base', patternId: 'new-pattern');

      final updated = applyNewPathBuildRequestToManifest(
        manifest: manifest,
        request: request,
      );

      expect(
          updated.pathPresets.map((e) => e.id), ['existing-base', 'new-base']);
      expect(
        updated.pathPatternPresets.map((e) => e.id),
        ['existing-pattern', 'new-pattern'],
      );
    });

    test('préserve les entrées existantes inchangées', () {
      const existingBase =
          ProjectPathPreset(id: 'existing-base', name: 'Existing base');
      final existingPattern = _patternPreset(
          id: 'existing-pattern', basePathPresetId: 'existing-base');
      final manifest = _manifest(
        pathPresets: [existingBase],
        pathPatternPresets: [existingPattern],
      );

      final updated = applyNewPathBuildRequestToManifest(
        manifest: manifest,
        request: _request(baseId: 'new-base', patternId: 'new-pattern'),
      );

      expect(updated.pathPresets.first, same(existingBase));
      expect(updated.pathPatternPresets.first, same(existingPattern));
    });

    test('ne mute pas le manifest source', () {
      final manifest = _manifest();
      final updated = applyNewPathBuildRequestToManifest(
        manifest: manifest,
        request: _request(baseId: 'new-base', patternId: 'new-pattern'),
      );

      expect(manifest.pathPresets, isEmpty);
      expect(manifest.pathPatternPresets, isEmpty);
      expect(updated.pathPresets, isNot(same(manifest.pathPresets)));
      expect(
          updated.pathPatternPresets, isNot(same(manifest.pathPatternPresets)));
    });

    test('collision base path id lève une erreur', () {
      final manifest = _manifest(
        pathPresets: [
          const ProjectPathPreset(id: 'new-base', name: 'Existing base'),
        ],
      );

      expect(
        () => applyNewPathBuildRequestToManifest(
          manifest: manifest,
          request: _request(baseId: 'new-base', patternId: 'new-pattern'),
        ),
        throwsArgumentError,
      );
    });

    test('collision path pattern id lève une erreur', () {
      final manifest = _manifest(
        pathPatternPresets: [
          _patternPreset(id: 'new-pattern', basePathPresetId: 'existing-base'),
        ],
      );

      expect(
        () => applyNewPathBuildRequestToManifest(
          manifest: manifest,
          request: _request(baseId: 'new-base', patternId: 'new-pattern'),
        ),
        throwsArgumentError,
      );
    });

    test('conserve une couverture partielle des variants telle quelle', () {
      final request = _request(
        baseId: 'new-base',
        patternId: 'new-pattern',
        variants: [
          const PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 1)),
            ],
          ),
        ],
      );

      final updated = applyNewPathBuildRequestToManifest(
        manifest: _manifest(),
        request: request,
      );

      expect(updated.pathPresets.single.variants.length, 1);
      expect(
        updated.pathPresets.single.variants.single.variant,
        TerrainPathVariant.endNorth,
      );
    });

    test('n ajoute aucun variant manquant', () {
      final request = _request(
        baseId: 'new-base',
        patternId: 'new-pattern',
        variants: const [],
      );

      final updated = applyNewPathBuildRequestToManifest(
        manifest: _manifest(),
        request: request,
      );

      expect(updated.pathPresets.single.variants, isEmpty);
    });

    test('n ajoute jamais cross automatiquement', () {
      final request = _request(
        baseId: 'new-base',
        patternId: 'new-pattern',
        variants: [
          const PathPresetVariantMapping(
            variant: TerrainPathVariant.endNorth,
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 2, y: 2)),
            ],
          ),
        ],
      );

      final updated = applyNewPathBuildRequestToManifest(
        manifest: _manifest(),
        request: request,
      );

      expect(
        updated.pathPresets.single.variants
            .any((mapping) => mapping.variant == TerrainPathVariant.cross),
        isFalse,
      );
    });

    test('conserve centerPattern animé dans le manifest mis à jour', () {
      const basePathPreset = ProjectPathPreset(
        id: 'new-base',
        name: 'New Base',
        tilesetId: 'tileset-main',
      );
      final animatedRequest = PathStudioNewPathBuildRequest(
        basePathPreset: basePathPreset,
        pathPatternPreset: ProjectPathPatternPreset(
          id: 'new-pattern',
          name: 'new-pattern',
          basePathPresetId: 'new-base',
          centerPattern: PathCenterPattern(
            size: PathCenterPatternSize(width: 1, height: 1),
            cells: [
              PathCenterPatternCell(
                localX: 0,
                localY: 0,
                frames: const [
                  TilesetVisualFrame(
                    tilesetId: 'tileset-main',
                    source: TilesetSourceRect(x: 1, y: 1),
                    durationMs: 120,
                  ),
                  TilesetVisualFrame(
                    tilesetId: 'tileset-main',
                    source: TilesetSourceRect(x: 2, y: 1),
                    durationMs: 240,
                  ),
                ],
              ),
            ],
          ),
        ),
        configuredVariants: const [],
        missingVariants: const [],
        warnings: const [],
      );

      final updated = applyNewPathBuildRequestToManifest(
        manifest: _manifest(),
        request: animatedRequest,
      );
      final frames = updated.pathPatternPresets.single.centerPattern.cells.first.frames;
      expect(frames.length, 2);
      expect(frames[0].durationMs, 120);
      expect(frames[1].durationMs, 240);
    });

    test('roundtrip JSON conserve une séquence générée par l’assistant', () {
      var draft = assignPathStudioNewPathDraftCellTile(
        draft: selectPathStudioNewPathDraftTileset(
          createInitialPathStudioNewPathDraft(),
          'tileset-main',
        ),
        localX: 0,
        localY: 0,
        sourceX: 1,
        sourceY: 2,
      );
      draft = switch (generatePathStudioCenterAnimationSequence(
        draft: draft,
        target: PathStudioCenterAnimationSequenceTarget.selectedCell,
        frameCount: 3,
        stepX: 2,
        stepY: -1,
        durationMs: 88,
      )) {
        PathStudioCenterAnimationSequenceSuccess(:final draft) => draft,
        PathStudioCenterAnimationSequenceFailure(:final message) =>
          throw StateError(message),
      };

      final plan = createPathStudioNewPathBuildPlan(
        manifest: _manifest(),
        draft: draft,
      );
      final request = plan.buildRequest!;

      final updated = applyNewPathBuildRequestToManifest(
        manifest: _manifest(),
        request: request,
      );
      final raw = jsonEncode(updated.toJson());
      final roundtrip = ProjectManifest.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      final persisted =
          roundtrip.pathPatternPresets.single.centerPattern.cells.single.frames;
      expect(persisted.length, 3);
      expect(persisted[0].source, const TilesetSourceRect(x: 1, y: 2));
      expect(persisted[1].source, const TilesetSourceRect(x: 3, y: 1));
      expect(persisted[2].source, const TilesetSourceRect(x: 5, y: 0));
      expect(persisted.every((f) => f.durationMs == 88), isTrue);
    });
  });
}

PathStudioNewPathBuildRequest _request({
  required String baseId,
  required String patternId,
  List<PathPresetVariantMapping> variants = const [],
}) {
  return PathStudioNewPathBuildRequest(
    basePathPreset: ProjectPathPreset(
      id: baseId,
      name: 'New Base',
      tilesetId: 'tileset-main',
      variants: variants,
    ),
    pathPatternPreset: _patternPreset(id: patternId, basePathPresetId: baseId),
    configuredVariants: const [],
    missingVariants: const [],
    warnings: const [],
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

ProjectPathPatternPreset _patternPreset({
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
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
    ),
  );
}
