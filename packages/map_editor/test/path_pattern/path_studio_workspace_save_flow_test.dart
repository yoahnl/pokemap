import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/path_studio/path_studio_save_flow.dart';

/// Helper pour créer un manifest de test.
/// Basé sur le pattern utilisé dans path_pattern_editor_read_model_test.dart
ProjectManifest _manifest({
  List<ProjectPathPreset> pathPresets = const [],
  List<ProjectPathPatternPreset> pathPatternPresets = const [],
  List<ProjectTilesetEntry> tilesets = const [],
  ProjectSettings settings = const ProjectSettings(),
}) {
  return ProjectManifest(
    name: 'Test Project',
    settings: settings,
    maps: const [],
    tilesets: tilesets,
    pathPresets: pathPresets,
    pathPatternPresets: pathPatternPresets,
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

/// Helper pour créer un PathPreset legacy de test.
ProjectPathPreset _legacyPathPreset({
  required String id,
  String name = 'Legacy Water',
  String tilesetId = 'tileset-water',
  PathSurfaceKind surfaceKind = PathSurfaceKind.water,
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    tilesetId: tilesetId,
    surfaceKind: surfaceKind,
    variants: const [],
  );
}

/// Helper pour créer un PathCenterPattern simple 1x1
PathCenterPattern _singleCellPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: const [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
            durationMs: null,
          ),
        ],
      ),
    ],
  );
}

/// Helper pour créer un ProjectPathPatternPreset de test
ProjectPathPatternPreset _pathPatternPreset({
  required String id,
  required String name,
  required String basePathPresetId,
  PathCenterPattern? pattern,
  int sortOrder = 0,
}) {
  return ProjectPathPatternPreset(
    id: id,
    name: name,
    basePathPresetId: basePathPresetId,
    centerPattern: pattern ?? _singleCellPattern(),
    transparentColor: null,
    categoryId: null,
    sortOrder: sortOrder,
  );
}

void main() {
  group('Lot 20-ter — Real Save Handler Proof', () {
    
    group('applyLegacyPathPatternSaveToManifest (helper de PRODUCTION)', () {
      late ProjectManifest initialManifest;

      setUp(() {
        initialManifest = _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [],
        );
      });

      test('ajoute un preset dans un manifest vide', () {
        final preset = _pathPatternPreset(
          id: 'test-pattern',
          name: 'Test Pattern',
          basePathPresetId: 'legacy-water',
        );

        // Test du helper DE PRODUCTION, pas une copie locale
        final updated = applyLegacyPathPatternSaveToManifest(
          manifest: initialManifest,
          preset: preset,
        );

        // Preuve 1: Le preset a bien été ajouté
        expect(updated.pathPatternPresets, hasLength(1));
        expect(updated.pathPatternPresets.first.id, 'test-pattern');
        expect(updated.pathPatternPresets.first.name, 'Test Pattern');
        expect(
          updated.pathPatternPresets.first.basePathPresetId,
          'legacy-water',
        );
        
        // Preuve 2: Le manifest original est préservé (autres champs)
        expect(updated.name, initialManifest.name);
        expect(updated.pathPresets, hasLength(1));
        expect(updated.pathPresets.first.id, 'legacy-water');
        
        // Preuve 3: Le manifest original n'est pas muté
        expect(initialManifest.pathPatternPresets, isEmpty);
      });

      test('remplace un preset existant avec même id (upsert)', () {
        // Manifest avec un preset existant
        final manifestWithPreset = _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'water-pattern',
              name: 'Water V1',
              basePathPresetId: 'legacy-water',
            ),
          ],
        );

        final presetV2 = _pathPatternPreset(
          id: 'water-pattern', // Même id pour remplacer
          name: 'Water V2',
          basePathPresetId: 'legacy-water',
          pattern: PathCenterPattern(
            size: PathCenterPatternSize(width: 2, height: 2),
            cells: [
              PathCenterPatternCell(
                localX: 0,
                localY: 0,
                frames: const [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
                    durationMs: null,
                  ),
                ],
              ),
              PathCenterPatternCell(
                localX: 1,
                localY: 0,
                frames: const [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 1, y: 0, width: 1, height: 1),
                    durationMs: null,
                  ),
                ],
              ),
              PathCenterPatternCell(
                localX: 0,
                localY: 1,
                frames: const [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 0, y: 1, width: 1, height: 1),
                    durationMs: null,
                  ),
                ],
              ),
              PathCenterPatternCell(
                localX: 1,
                localY: 1,
                frames: const [
                  TilesetVisualFrame(
                    source: TilesetSourceRect(x: 1, y: 1, width: 1, height: 1),
                    durationMs: null,
                  ),
                ],
              ),
            ],
          ),
          sortOrder: 0,
        );

        final updated = applyLegacyPathPatternSaveToManifest(
          manifest: manifestWithPreset,
          preset: presetV2,
        );

        // Preuve: Le preset a bien été remplacé (upsert)
        expect(updated.pathPatternPresets, hasLength(1));
        expect(updated.pathPatternPresets.first.id, 'water-pattern');
        expect(updated.pathPatternPresets.first.name, 'Water V2');
        expect(
          updated.pathPatternPresets.first.centerPattern.size.width,
          2,
        );
        expect(
          updated.pathPatternPresets.first.centerPattern.size.height,
          2,
        );
        
        // Preuve: L'ancien manifest n'est pas muté
        expect(manifestWithPreset.pathPatternPresets.first.name, 'Water V1');
      });

      test('preserve les autres presets lors de l\'ajout', () {
        final manifestWithExisting = _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [
            _pathPatternPreset(
              id: 'existing-pattern',
              name: 'Existing',
              basePathPresetId: 'legacy-water',
            ),
          ],
        );

        final newPreset = _pathPatternPreset(
          id: 'new-pattern',
          name: 'New Pattern',
          basePathPresetId: 'legacy-water',
        );

        final updated = applyLegacyPathPatternSaveToManifest(
          manifest: manifestWithExisting,
          preset: newPreset,
        );

        // Preuve: Les deux presets sont présents
        expect(updated.pathPatternPresets, hasLength(2));
        expect(updated.pathPatternPresets.map((p) => p.id).toList(), 
            containsAll(['existing-pattern', 'new-pattern']));
      });
    });

    group('upsertProjectPathPatternPreset direct', () {
      test('ajoute un preset dans un manifest vide', () {
        final manifest = _manifest(
          pathPresets: [_legacyPathPreset(id: 'legacy-water')],
          pathPatternPresets: [],
        );

        final preset = _pathPatternPreset(
          id: 'test-pattern',
          name: 'Test Pattern',
          basePathPresetId: 'legacy-water',
        );

        final updated = upsertProjectPathPatternPreset(
          manifest: manifest,
          preset: preset,
        );

        expect(updated.pathPatternPresets, hasLength(1));
        expect(updated.pathPatternPresets.first.id, 'test-pattern');
      });
    });
  });
}
