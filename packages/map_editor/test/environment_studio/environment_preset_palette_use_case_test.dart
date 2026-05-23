import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/environment_studio/authoring/environment_preset_palette_use_cases.dart';

void main() {
  group('UpdateEnvironmentPresetPaletteUseCase', () {
    const useCase = UpdateEnvironmentPresetPaletteUseCase();

    test('update palette modifie uniquement le preset ciblé', () {
      final project = _project();
      final updated = useCase(
        manifest: project,
        presetId: 'forest',
        palette: [
          EnvironmentPaletteItem(
            elementId: 'grass_b',
            weight: 7,
            collisionMode: EnvironmentCollisionMode.forceEnabled,
            tags: {'haut'},
          ),
        ],
      ).manifest;

      final preset = findProjectEnvironmentPresetById(updated, 'forest')!;
      expect(preset.palette.map((item) => item.elementId), ['grass_b']);
      expect(preset.palette.single.weight, 7);
      expect(preset.palette.single.collisionMode,
          EnvironmentCollisionMode.forceEnabled);
      expect(preset.palette.single.tags, {'haut'});
      expect(preset.id, 'forest');
      expect(preset.name, 'Forêt');
      expect(preset.templateId, 'forest_dense');
      expect(preset.categoryId, 'nature');
      expect(preset.defaultParams, _forestParams);
      expect(preset.sortOrder, 4);
      expect(findProjectEnvironmentPresetById(updated, 'props')!.palette,
          findProjectEnvironmentPresetById(project, 'props')!.palette);
    });

    test('préserve les autres presets et ne mute pas le project original', () {
      final project = _project();
      final originalPalette =
          findProjectEnvironmentPresetById(project, 'forest')!.palette;

      final updated = useCase(
        manifest: project,
        presetId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'grass_b', weight: 3),
        ],
      ).manifest;

      expect(identical(updated, project), isFalse);
      expect(findProjectEnvironmentPresetById(project, 'forest')!.palette,
          originalPalette);
      expect(findProjectEnvironmentPresetById(updated, 'props')!.name, 'Props');
    });

    test('refuse presetId vide', () {
      expect(
        () => useCase(
          manifest: _project(),
          presetId: ' ',
          palette: [
            EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('refuse preset introuvable', () {
      expect(
        () => useCase(
          manifest: _project(),
          presetId: 'missing',
          palette: [
            EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
          ],
        ),
        throwsStateError,
      );
    });

    test('refuse élément introuvable', () {
      expect(
        () => useCase(
          manifest: _project(),
          presetId: 'forest',
          palette: [
            EnvironmentPaletteItem(elementId: 'missing', weight: 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('refuse palette mélangeant deux tilesets', () {
      expect(
        () => useCase(
          manifest: _project(),
          presetId: 'forest',
          palette: [
            EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
            EnvironmentPaletteItem(elementId: 'rock_a', weight: 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('refuse élément sans tileset source', () {
      expect(
        () => useCase(
          manifest: _project(elements: [
            _element(id: 'unknown', tilesetId: ''),
          ]),
          presetId: 'forest',
          palette: [
            EnvironmentPaletteItem(elementId: 'unknown', weight: 1),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('refuse poids zéro avant toute mutation', () {
      final project = _project();
      var reachedUseCase = false;

      expect(
        () {
          final item = EnvironmentPaletteItem(elementId: 'grass_a', weight: 0);
          reachedUseCase = true;
          useCase(
            manifest: project,
            presetId: 'forest',
            palette: [item],
          );
        },
        throwsArgumentError,
      );

      expect(reachedUseCase, isFalse);
      _expectOriginalProjectUnchanged(project);
    });

    test('refuse poids négatif avant toute mutation', () {
      final project = _project();
      var reachedUseCase = false;

      expect(
        () {
          final item = EnvironmentPaletteItem(elementId: 'grass_a', weight: -1);
          reachedUseCase = true;
          useCase(
            manifest: project,
            presetId: 'forest',
            palette: [item],
          );
        },
        throwsArgumentError,
      );

      expect(reachedUseCase, isFalse);
      _expectOriginalProjectUnchanged(project);
    });

    test('refuse palette vide car EnvironmentPreset map_core la rejette', () {
      final project = _project();

      expect(
        () => useCase(
          manifest: project,
          presetId: 'forest',
          palette: const [],
        ),
        throwsArgumentError,
      );
      _expectOriginalProjectUnchanged(project);
    });

    test('accepte poids positif et plusieurs éléments du même tileset', () {
      final result = useCase(
        manifest: _project(),
        presetId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
          EnvironmentPaletteItem(elementId: 'grass_b', weight: 2),
        ],
      );

      expect(result.updatedPreset.palette.map((item) => item.elementId),
          ['grass_a', 'grass_b']);
      expect(result.sourceTilesetId, 'grass');
    });
  });
}

void _expectOriginalProjectUnchanged(ProjectManifest project) {
  expect(findProjectEnvironmentPresetById(project, 'forest')!.palette
      .map((item) => item.elementId), ['grass_a']);
  expect(findProjectEnvironmentPresetById(project, 'props')!.palette
      .map((item) => item.elementId), ['rock_a']);
}

final _forestParams = EnvironmentGenerationParams(
  density: 0.2,
  variation: 0.3,
  edgeDensity: 0.4,
  minSpacingCells: 2,
);

ProjectManifest _project({
  List<ProjectElementEntry>? elements,
}) {
  return ProjectManifest(
    name: 'palette-use-case',
    maps: const [],
    tilesets: const [],
    elements: elements ??
        [
          _element(id: 'grass_a', tilesetId: 'grass'),
          _element(id: 'grass_b', tilesetId: 'grass'),
          _element(id: 'rock_a', tilesetId: 'rocks'),
        ],
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest_dense',
        categoryId: 'nature',
        palette: [
          EnvironmentPaletteItem(elementId: 'grass_a', weight: 1),
        ],
        defaultParams: _forestParams,
        sortOrder: 4,
      ),
      EnvironmentPreset(
        id: 'props',
        name: 'Props',
        templateId: 'props',
        categoryId: 'decor',
        palette: [
          EnvironmentPaletteItem(elementId: 'rock_a', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 9,
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

ProjectElementEntry _element({
  required String id,
  required String tilesetId,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'El $id',
    tilesetId: tilesetId,
    categoryId: 'cat',
    frames: const [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
  );
}
