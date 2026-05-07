import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_generation_use_cases.dart';

void main() {
  group('GenerateTileLayerEnvironmentAreaPlacementsUseCase', () {
    test('génère des placements depuis le TileLayer ciblé', () {
      final map = _map();
      final manifest = _manifest();
      final result = GenerateTileLayerEnvironmentAreaPlacementsUseCase()
          .execute(map,
              manifest: manifest, tileLayerId: 'tiles', areaId: 'area');

      expect(result.tileLayerId, 'tiles');
      expect(result.environmentLayerId, 'env');
      expect(result.areaId, 'area');
      expect(result.generatedPlacementCount, greaterThan(0));
      expect(result.generatedPlacementIds, isNotEmpty);

      final outArea = _areaById(result.map, 'area');
      expect(outArea.generatedPlacementIds, result.generatedPlacementIds);
      expect(outArea.mask, _areaById(map, 'area').mask);
      expect(outArea.paramsOverride, _overrideParams);
      expect(outArea.seed, 7);

      final manual = result.map.placedElements.singleWhere(
        (element) => element.id == 'manual',
      );
      expect(manual.layerId, 'tiles');
      for (final id in result.generatedPlacementIds) {
        final placed = result.map.placedElements.singleWhere(
          (element) => element.id == id,
        );
        expect(placed.layerId, 'tiles');
        expect(placed.elementId, 'tree');
      }
      expect(manifest.environmentPresets.single.defaultParams, _defaultParams);
    });

    test('refuse les entrées invalides sans créer de placement', () {
      final useCase = GenerateTileLayerEnvironmentAreaPlacementsUseCase();
      final manifest = _manifest();
      final map = _map();

      expect(
        () => useCase.execute(
          map,
          manifest: manifest,
          tileLayerId: '',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
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
          areaId: '',
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
          _map(generatedPlacementIds: const ['old']),
          manifest: manifest,
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(map.placedElements.length, 1);
    });
  });
}

final _defaultParams = EnvironmentGenerationParams(
  density: 1,
  variation: 0,
  edgeDensity: 1,
  minSpacingCells: 0,
);

final _overrideParams = EnvironmentGenerationParams(
  density: 1,
  variation: 0,
  edgeDensity: 1,
  minSpacingCells: 0,
);

MapData _map({
  List<bool>? cells,
  String areaPresetId = 'forest',
  List<String> generatedPlacementIds = const [],
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
            _area(
              id: 'area',
              presetId: areaPresetId,
              cells: cells,
              generatedPlacementIds: generatedPlacementIds,
            ),
            _area(id: 'other', presetId: 'forest'),
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

EnvironmentArea _area({
  required String id,
  required String presetId,
  List<bool>? cells,
  List<String> generatedPlacementIds = const [],
}) {
  return EnvironmentArea(
    id: id,
    name: 'Zone $id',
    presetId: presetId,
    mask: EnvironmentAreaMask(
      width: 2,
      height: 2,
      cells: cells ?? List<bool>.filled(4, true),
    ),
    seed: 7,
    paramsOverride: _overrideParams,
    generatedPlacementIds: generatedPlacementIds,
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
        defaultParams: _defaultParams,
        sortOrder: 0,
      ),
    ],
  );
}
