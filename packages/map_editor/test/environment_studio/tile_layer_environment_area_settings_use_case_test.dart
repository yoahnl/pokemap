import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart';

void main() {
  group('TileLayerEnvironmentAreaSettingsUseCases', () {
    test('set paramsOverride sur l’area ciblée seulement', () {
      final map = _mapWithAreas(
        placedElements: const [
          MapPlacedElement(
            id: 'placed_tree',
            layerId: 'tiles',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      final params = _params(
        density: 0.8,
        variation: 0.25,
        edgeDensity: 0.6,
        minSpacingCells: 3,
      );

      final updated =
          SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
        map,
        tileLayerId: 'tiles',
        areaId: 'area_a',
        paramsOverride: params,
      );

      final env = _environmentLayer(updated);
      final areaA = _areaById(env, 'area_a');
      final areaB = _areaById(env, 'area_b');
      expect(areaA.paramsOverride, params);
      expect(areaA.seed, 11);
      expect(areaA.mask, _areaById(_environmentLayer(map), 'area_a').mask);
      expect(areaA.generatedPlacementIds, const ['generated_a']);
      expect(areaB.paramsOverride, isNull);
      expect(updated.placedElements, map.placedElements);
      expect(updated.placedElements, hasLength(1));
    });

    test('reset paramsOverride à null sans changer seed masque ni placements',
        () {
      final override = _params(
        density: 0.7,
        variation: 0.1,
        edgeDensity: 0.9,
        minSpacingCells: 2,
      );
      final map = _mapWithAreas(
        areaAParamsOverride: override,
        areaASeed: 42,
      );

      final updated =
          ResetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
        map,
        tileLayerId: 'tiles',
        areaId: 'area_a',
      );

      final area = _areaById(_environmentLayer(updated), 'area_a');
      expect(area.paramsOverride, isNull);
      expect(area.seed, 42);
      expect(area.mask, _areaById(_environmentLayer(map), 'area_a').mask);
      expect(area.generatedPlacementIds, const ['generated_a']);
      expect(updated.placedElements, map.placedElements);
    });

    test('set seed sans changer paramsOverride masque ni placements', () {
      final override = _params(
        density: 0.7,
        variation: 0.1,
        edgeDensity: 0.9,
        minSpacingCells: 2,
      );
      final map = _mapWithAreas(areaAParamsOverride: override);

      final updated =
          SetTileLayerEnvironmentAreaSeedForTileLayerUseCase().execute(
        map,
        tileLayerId: 'tiles',
        areaId: 'area_a',
        seed: 123,
      );

      final area = _areaById(_environmentLayer(updated), 'area_a');
      expect(area.seed, 123);
      expect(area.paramsOverride, override);
      expect(area.mask, _areaById(_environmentLayer(map), 'area_a').mask);
      expect(area.generatedPlacementIds, const ['generated_a']);
      expect(updated.placedElements, map.placedElements);
    });

    test('refuse les entrées invalides', () {
      final map = _mapWithAreas();
      final params = _params(
        density: 0.5,
        variation: 0.5,
        edgeDensity: 0.5,
        minSpacingCells: 1,
      );

      expect(
        () => SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          map,
          tileLayerId: '   ',
          areaId: 'area_a',
          paramsOverride: params,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          map,
          tileLayerId: 'missing',
          areaId: 'area_a',
          paramsOverride: params,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          _mapWithNonTileTarget(),
          tileLayerId: 'objects',
          areaId: 'area_a',
          paramsOverride: params,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          _mapWithoutAttachment(),
          tileLayerId: 'tiles',
          areaId: 'area_a',
          paramsOverride: params,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          map,
          tileLayerId: 'tiles',
          areaId: '   ',
          paramsOverride: params,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => SetTileLayerEnvironmentAreaParamsOverrideUseCase().execute(
          map,
          tileLayerId: 'tiles',
          areaId: 'missing',
          paramsOverride: params,
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => SetTileLayerEnvironmentAreaSeedForTileLayerUseCase().execute(
          map,
          tileLayerId: 'tiles',
          areaId: 'area_a',
          seed: -1,
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });
  });
}

MapData _mapWithAreas({
  EnvironmentGenerationParams? areaAParamsOverride,
  int areaASeed = 11,
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            _area(
              id: 'area_a',
              seed: areaASeed,
              activeIndexes: const [0, 4],
              paramsOverride: areaAParamsOverride,
              generatedPlacementIds: const ['generated_a'],
            ),
            _area(
              id: 'area_b',
              seed: 22,
              activeIndexes: const [8],
            ),
          ],
        ),
      ),
    ],
    placedElements: placedElements,
  );
}

MapData _mapWithoutAttachment() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 3, height: 3),
    layers: [
      TileLayer(
        id: 'tiles',
        name: 'Ground',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
  );
}

MapData _mapWithNonTileTarget() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const MapLayer.object(id: 'objects', name: 'Objects'),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'objects',
          areas: [_area(id: 'area_a')],
        ),
      ),
    ],
  );
}

EnvironmentArea _area({
  required String id,
  int seed = 0,
  List<int> activeIndexes = const [],
  EnvironmentGenerationParams? paramsOverride,
  List<String> generatedPlacementIds = const [],
}) {
  final cells = List<bool>.filled(9, false);
  for (final index in activeIndexes) {
    cells[index] = true;
  }
  return EnvironmentArea(
    id: id,
    name: 'Zone $id',
    presetId: 'forest',
    mask: EnvironmentAreaMask(width: 3, height: 3, cells: cells),
    seed: seed,
    paramsOverride: paramsOverride,
    generatedPlacementIds: generatedPlacementIds,
  );
}

EnvironmentLayer _environmentLayer(MapData map) {
  return map.layers.whereType<EnvironmentLayer>().single;
}

EnvironmentArea _areaById(EnvironmentLayer layer, String id) {
  return layer.content.areas.singleWhere((area) => area.id == id);
}

EnvironmentGenerationParams _params({
  required double density,
  required double variation,
  required double edgeDensity,
  required int minSpacingCells,
}) {
  return EnvironmentGenerationParams(
    density: density,
    variation: variation,
    edgeDensity: edgeDensity,
    minSpacingCells: minSpacingCells,
  );
}
