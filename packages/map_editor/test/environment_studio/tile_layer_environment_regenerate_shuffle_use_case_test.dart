import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_regenerate_use_cases.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart';

void main() {
  group('TileLayer environment regenerate / shuffle use cases', () {
    test('regenerate clear puis génère avec le même seed', () {
      final map = _map();
      final result = RegenerateTileLayerEnvironmentAreaPlacementsUseCase()
          .execute(map,
              manifest: _manifest(), tileLayerId: 'tiles', areaId: 'area');

      expect(result.tileLayerId, 'tiles');
      expect(result.environmentLayerId, 'env');
      expect(result.areaId, 'area');
      expect(result.previousSeed, 7);
      expect(result.currentSeed, 7);
      expect(result.seedChanged, isFalse);
      expect(result.removedPlacementCount, 2);
      expect(result.clearedReferenceCount, 3);
      expect(result.generatedPlacementCount, greaterThan(0));

      final area = _areaById(result.map, 'area');
      expect(area.seed, 7);
      expect(area.generatedPlacementIds, result.generatedPlacementIds);
      expect(area.generatedPlacementIds, isNot(contains('old_a')));
      expect(area.generatedPlacementIds, isNot(contains('old_b')));
      expect(area.mask, _areaById(map, 'area').mask);
      expect(area.paramsOverride, _params);
      expect(area.presetId, 'forest');
      expect(result.map.placedElements.any((e) => e.id == 'manual'), isTrue);
      expect(
        result.map.placedElements.any((e) => e.id == 'other_generated'),
        isTrue,
      );
      expect(
        _areaById(result.map, 'other').generatedPlacementIds,
        const ['other_generated'],
      );
    });

    test('shuffle clear puis change seed et génère', () {
      final result = ShuffleTileLayerEnvironmentAreaPlacementsUseCase().execute(
        _map(),
        manifest: _manifest(),
        tileLayerId: 'tiles',
        areaId: 'area',
      );

      final expectedSeed = nextEnvironmentAreaSeed(7);
      final area = _areaById(result.map, 'area');
      expect(result.previousSeed, 7);
      expect(result.currentSeed, expectedSeed);
      expect(result.seedChanged, isTrue);
      expect(area.seed, expectedSeed);
      expect(area.generatedPlacementIds, result.generatedPlacementIds);
      expect(result.generatedPlacementCount, greaterThan(0));
      expect(area.paramsOverride, _params);
      expect(area.presetId, 'forest');
      expect(result.map.placedElements.any((e) => e.id == 'manual'), isTrue);
      expect(
        result.map.placedElements.any((e) => e.id == 'other_generated'),
        isTrue,
      );
    });

    test('regenerate peut finir sans nouveaux candidats après clear', () {
      final map = _map(params: _zeroParams);
      final result = RegenerateTileLayerEnvironmentAreaPlacementsUseCase()
          .execute(map,
              manifest: _manifest(), tileLayerId: 'tiles', areaId: 'area');

      final area = _areaById(result.map, 'area');
      expect(result.removedPlacementCount, 2);
      expect(result.generatedPlacementCount, 0);
      expect(area.generatedPlacementIds, isEmpty);
      expect(result.map.placedElements.any((e) => e.id == 'old_a'), isFalse);
      expect(result.map.placedElements.any((e) => e.id == 'manual'), isTrue);
    });

    test('refuse les entrées invalides sans mutation', () {
      final useCase = RegenerateTileLayerEnvironmentAreaPlacementsUseCase();
      final manifest = _manifest();
      final map = _map();

      expect(
        () => useCase.execute(
          map,
          manifest: manifest,
          tileLayerId: 'missing',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _mapWithNonTileActiveLayer(),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _mapWithoutEnvironmentAttachment(),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          map,
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'missing',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _map(areaPresetId: 'missing'),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _map(cells: List<bool>.filled(4, false)),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _map(generatedPlacementIds: const []),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(_areaById(map, 'area').generatedPlacementIds, hasLength(3));
      expect(map.placedElements.length, 4);
    });
  });
}

final _params = EnvironmentGenerationParams(
  density: 1,
  variation: 0,
  edgeDensity: 1,
  minSpacingCells: 0,
);

final _zeroParams = EnvironmentGenerationParams(
  density: 0,
  variation: 0,
  edgeDensity: 0,
  minSpacingCells: 0,
);

MapData _map({
  List<String> generatedPlacementIds = const [
    'old_a',
    'old_b',
    'missing_old',
  ],
  List<bool>? cells,
  String areaPresetId = 'forest',
  EnvironmentGenerationParams? params,
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [0, 0, 0, 0],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            EnvironmentArea(
              id: 'area',
              name: 'Zone',
              presetId: areaPresetId,
              mask: EnvironmentAreaMask(
                width: 2,
                height: 2,
                cells: cells ?? List<bool>.filled(4, true),
              ),
              seed: 7,
              paramsOverride: params ?? _params,
              generatedPlacementIds: generatedPlacementIds,
            ),
            EnvironmentArea(
              id: 'other',
              name: 'Other',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 2,
                height: 2,
                cells: List<bool>.filled(4, true),
              ),
              seed: 3,
              generatedPlacementIds: const ['other_generated'],
            ),
          ],
        ),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'manual',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
      ),
      MapPlacedElement(
        id: 'old_a',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 1),
      ),
      MapPlacedElement(
        id: 'old_b',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 0),
      ),
      MapPlacedElement(
        id: 'other_generated',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  );
}

MapData _mapWithoutEnvironmentAttachment() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 2, height: 2),
    tilesetId: 'nature',
    layers: [
      TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [0, 0, 0, 0],
      ),
    ],
  );
}

MapData _mapWithNonTileActiveLayer() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'nature',
    layers: [
      const MapLayer.object(id: 'tiles', name: 'Objects'),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(targetTileLayerId: 'tiles'),
      ),
    ],
  );
}

EnvironmentArea _areaById(MapData map, String areaId) {
  return map.layers
      .whereType<EnvironmentLayer>()
      .single
      .content
      .areas
      .singleWhere((area) => area.id == areaId);
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
        ],
        defaultParams: _params,
        sortOrder: 0,
      ),
    ],
  );
}
