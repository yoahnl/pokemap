import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_edit_path_build_request.dart';
import 'package:map_editor/src/features/path_studio/path_studio_save_flow.dart';

void main() {
  group('applyPathPatternEditRequestToManifest', () {
    test('remplace base et pattern en place sans append', () {
      final manifest = _manifest(
        pathPresets: const [
          ProjectPathPreset(id: 'base-a', name: 'Base A'),
          ProjectPathPreset(id: 'base-b', name: 'Base B'),
        ],
        pathPatternPresets: [
          _pattern(id: 'pattern-a', baseId: 'base-a'),
          _pattern(id: 'pattern-b', baseId: 'base-b'),
        ],
      );
      final request = _request(
        originalBaseId: 'base-a',
        originalPatternId: 'pattern-a',
        updatedBase:
            const ProjectPathPreset(id: 'base-a', name: 'Base A edited'),
        updatedPattern: _pattern(
            id: 'pattern-a', baseId: 'base-a', name: 'Pattern A edited'),
      );

      final updated = applyPathPatternEditRequestToManifest(
        manifest: manifest,
        request: request,
      );

      expect(updated.pathPresets.map((e) => e.id), ['base-a', 'base-b']);
      expect(updated.pathPatternPresets.map((e) => e.id),
          ['pattern-a', 'pattern-b']);
      expect(updated.pathPresets[0].name, 'Base A edited');
      expect(updated.pathPatternPresets[0].name, 'Pattern A edited');
    });

    test('préserve ordre des listes', () {
      final manifest = _manifest(
        pathPresets: const [
          ProjectPathPreset(id: 'base-1', name: '1'),
          ProjectPathPreset(id: 'base-2', name: '2'),
          ProjectPathPreset(id: 'base-3', name: '3'),
        ],
        pathPatternPresets: [
          _pattern(id: 'pattern-1', baseId: 'base-1'),
          _pattern(id: 'pattern-2', baseId: 'base-2'),
          _pattern(id: 'pattern-3', baseId: 'base-3'),
        ],
      );
      final updated = applyPathPatternEditRequestToManifest(
        manifest: manifest,
        request: _request(
          originalBaseId: 'base-2',
          originalPatternId: 'pattern-2',
          updatedBase: const ProjectPathPreset(id: 'base-2', name: 'Edited'),
          updatedPattern:
              _pattern(id: 'pattern-2', baseId: 'base-2', name: 'Edited'),
        ),
      );

      expect(
          updated.pathPresets.map((e) => e.id), ['base-1', 'base-2', 'base-3']);
      expect(
        updated.pathPatternPresets.map((e) => e.id),
        ['pattern-1', 'pattern-2', 'pattern-3'],
      );
    });

    test('ne mute pas le manifest source', () {
      final manifest = _manifest(
        pathPresets: const [ProjectPathPreset(id: 'base-a', name: 'Base A')],
        pathPatternPresets: [_pattern(id: 'pattern-a', baseId: 'base-a')],
      );
      final updated = applyPathPatternEditRequestToManifest(
        manifest: manifest,
        request: _request(
          originalBaseId: 'base-a',
          originalPatternId: 'pattern-a',
          updatedBase:
              const ProjectPathPreset(id: 'base-a', name: 'Base A edited'),
          updatedPattern:
              _pattern(id: 'pattern-a', baseId: 'base-a', name: 'Edited'),
        ),
      );

      expect(manifest.pathPresets.single.name, 'Base A');
      expect(manifest.pathPatternPresets.single.name, 'pattern-a');
      expect(updated.pathPresets.single.name, 'Base A edited');
    });

    test('collision base id avec autre item => erreur', () {
      final manifest = _manifest(
        pathPresets: const [
          ProjectPathPreset(id: 'base-a', name: 'Base A'),
          ProjectPathPreset(id: 'base-b', name: 'Base B'),
        ],
        pathPatternPresets: [_pattern(id: 'pattern-a', baseId: 'base-a')],
      );
      expect(
        () => applyPathPatternEditRequestToManifest(
          manifest: manifest,
          request: _request(
            originalBaseId: 'base-a',
            originalPatternId: 'pattern-a',
            updatedBase:
                const ProjectPathPreset(id: 'base-b', name: 'Conflict'),
            updatedPattern: _pattern(id: 'pattern-a', baseId: 'base-b'),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('collision pattern id avec autre item => erreur', () {
      final manifest = _manifest(
        pathPresets: const [ProjectPathPreset(id: 'base-a', name: 'Base A')],
        pathPatternPresets: [
          _pattern(id: 'pattern-a', baseId: 'base-a'),
          _pattern(id: 'pattern-b', baseId: 'base-a'),
        ],
      );
      expect(
        () => applyPathPatternEditRequestToManifest(
          manifest: manifest,
          request: _request(
            originalBaseId: 'base-a',
            originalPatternId: 'pattern-a',
            updatedBase: const ProjectPathPreset(id: 'base-a', name: 'Edited'),
            updatedPattern: _pattern(id: 'pattern-b', baseId: 'base-a'),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('original base introuvable => erreur', () {
      final manifest = _manifest(
        pathPresets: const [ProjectPathPreset(id: 'base-a', name: 'Base A')],
        pathPatternPresets: [_pattern(id: 'pattern-a', baseId: 'base-a')],
      );
      expect(
        () => applyPathPatternEditRequestToManifest(
          manifest: manifest,
          request: _request(
            originalBaseId: 'absent',
            originalPatternId: 'pattern-a',
            updatedBase: const ProjectPathPreset(id: 'base-a', name: 'Edited'),
            updatedPattern: _pattern(id: 'pattern-a', baseId: 'base-a'),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('original pattern introuvable => erreur', () {
      final manifest = _manifest(
        pathPresets: const [ProjectPathPreset(id: 'base-a', name: 'Base A')],
        pathPatternPresets: [_pattern(id: 'pattern-a', baseId: 'base-a')],
      );
      expect(
        () => applyPathPatternEditRequestToManifest(
          manifest: manifest,
          request: _request(
            originalBaseId: 'base-a',
            originalPatternId: 'absent',
            updatedBase: const ProjectPathPreset(id: 'base-a', name: 'Edited'),
            updatedPattern: _pattern(id: 'pattern-a', baseId: 'base-a'),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('n append pas de doublon', () {
      final manifest = _manifest(
        pathPresets: const [ProjectPathPreset(id: 'base-a', name: 'Base A')],
        pathPatternPresets: [_pattern(id: 'pattern-a', baseId: 'base-a')],
      );
      final updated = applyPathPatternEditRequestToManifest(
        manifest: manifest,
        request: _request(
          originalBaseId: 'base-a',
          originalPatternId: 'pattern-a',
          updatedBase: const ProjectPathPreset(id: 'base-a', name: 'Edited'),
          updatedPattern: _pattern(id: 'pattern-a', baseId: 'base-a'),
        ),
      );

      expect(updated.pathPresets.length, 1);
      expect(updated.pathPatternPresets.length, 1);
    });
  });
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

ProjectPathPatternPreset _pattern({
  required String id,
  required String baseId,
  String? name,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name ?? id,
    basePathPresetId: baseId,
    centerPattern: PathCenterPattern(
      size: PathCenterPatternSize(width: 1, height: 1),
      cells: [
        PathCenterPatternCell(
          localX: 0,
          localY: 0,
          frames: const [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))
          ],
        ),
      ],
    ),
  );
}

PathStudioEditPathBuildRequest _request({
  required String originalBaseId,
  required String originalPatternId,
  required ProjectPathPreset updatedBase,
  required ProjectPathPatternPreset updatedPattern,
}) {
  return PathStudioEditPathBuildRequest(
    updatedBasePathPreset: updatedBase,
    updatedPathPatternPreset: updatedPattern,
    originalBasePathPresetId: originalBaseId,
    originalPathPatternPresetId: originalPatternId,
    warnings: const [],
    blockingIssues: const [],
  );
}
