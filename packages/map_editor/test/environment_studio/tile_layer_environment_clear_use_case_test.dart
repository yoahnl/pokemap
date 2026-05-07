import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_clear_use_cases.dart';

void main() {
  group('ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase', () {
    test('efface les placements générés de l’area ciblée seulement', () {
      final map = _map();
      final result = ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase()
          .execute(map, tileLayerId: 'tiles', areaId: 'area');

      expect(result.tileLayerId, 'tiles');
      expect(result.environmentLayerId, 'env');
      expect(result.areaId, 'area');
      expect(result.removedPlacementCount, 2);
      expect(result.clearedReferenceCount, 3);
      expect(
        result.map.placedElements.map((element) => element.id).toList(),
        const ['manual', 'other_generated'],
      );

      final clearedArea = _areaById(result.map, 'area');
      expect(clearedArea.generatedPlacementIds, isEmpty);
      expect(clearedArea.mask, _areaById(map, 'area').mask);
      expect(clearedArea.paramsOverride, _params);
      expect(clearedArea.seed, 11);
      expect(clearedArea.presetId, 'forest');

      final otherArea = _areaById(result.map, 'other');
      expect(otherArea.generatedPlacementIds, const ['other_generated']);
      expect(
        result.map.placedElements
            .singleWhere(
              (element) => element.id == 'other_generated',
            )
            .layerId,
        'tiles',
      );
    });

    test('generatedPlacementIds vide retourne un no-op clair', () {
      final map = _map(areaGeneratedPlacementIds: const []);
      final result = ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase()
          .execute(map, tileLayerId: 'tiles', areaId: 'area');

      expect(identical(result.map, map), isTrue);
      expect(result.removedPlacementCount, 0);
      expect(result.clearedReferenceCount, 0);
    });

    test('refuse les entrées invalides sans mutation', () {
      final useCase = ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase();
      final map = _map();

      expect(
        () => useCase.execute(map, tileLayerId: '', areaId: 'area'),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(map, tileLayerId: 'missing', areaId: 'area'),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _mapWithNonTileActiveLayer(),
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _mapWithoutEnvironmentAttachment(),
          tileLayerId: 'tiles',
          areaId: 'area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(map, tileLayerId: 'tiles', areaId: ''),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(map, tileLayerId: 'tiles', areaId: 'missing'),
        throwsA(isA<EditorValidationException>()),
      );
      expect(map.placedElements.length, 4);
      expect(_areaById(map, 'area').generatedPlacementIds, hasLength(3));
    });
  });
}

final _params = EnvironmentGenerationParams(
  density: 0.7,
  variation: 0.2,
  edgeDensity: 0.8,
  minSpacingCells: 1,
);

MapData _map({
  List<String> areaGeneratedPlacementIds = const [
    'generated_a',
    'generated_b',
    'missing_generated',
  ],
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
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 2,
                height: 2,
                cells: List<bool>.filled(4, true),
              ),
              seed: 11,
              paramsOverride: _params,
              generatedPlacementIds: areaGeneratedPlacementIds,
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
        id: 'generated_a',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 1),
      ),
      MapPlacedElement(
        id: 'generated_b',
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
