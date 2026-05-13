import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_area_management_use_cases.dart';

void main() {
  group('RenameTileLayerEnvironmentAreaUseCase', () {
    test('renames only the selected area name and trims input', () {
      final map = _map();
      final beforeArea = _areaById(map, 'area_a');
      final beforeOtherArea = _areaById(map, 'area_b');
      final beforePlacedElements = map.placedElements;

      final result = RenameTileLayerEnvironmentAreaUseCase().execute(
        map,
        tileLayerId: 'tile_layer',
        areaId: 'area_a',
        name: '  Bosquet plage  ',
      );

      final renamedArea = _areaById(result.map, 'area_a');
      final otherArea = _areaById(result.map, 'area_b');

      expect(result.tileLayerId, 'tile_layer');
      expect(result.environmentLayerId, 'environment_layer');
      expect(result.areaId, 'area_a');
      expect(result.name, 'Bosquet plage');
      expect(renamedArea.name, 'Bosquet plage');
      expect(renamedArea.id, beforeArea.id);
      expect(renamedArea.presetId, beforeArea.presetId);
      expect(renamedArea.mask, beforeArea.mask);
      expect(renamedArea.seed, beforeArea.seed);
      expect(renamedArea.paramsOverride, beforeArea.paramsOverride);
      expect(
          renamedArea.generatedPlacementIds, beforeArea.generatedPlacementIds);
      expect(otherArea, beforeOtherArea);
      expect(result.map.placedElements, beforePlacedElements);
    });

    test('refuses an empty name', () {
      expect(
        () => RenameTileLayerEnvironmentAreaUseCase().execute(
          _map(),
          tileLayerId: 'tile_layer',
          areaId: 'area_a',
          name: '   ',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('refuses a missing TileLayer', () {
      expect(
        () => RenameTileLayerEnvironmentAreaUseCase().execute(
          _map(),
          tileLayerId: 'missing_layer',
          areaId: 'area_a',
          name: 'Bosquet plage',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('refuses a missing area', () {
      expect(
        () => RenameTileLayerEnvironmentAreaUseCase().execute(
          _map(),
          tileLayerId: 'tile_layer',
          areaId: 'missing_area',
          name: 'Bosquet plage',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });
  });

  group('DeleteTileLayerEnvironmentAreaUseCase', () {
    test('deletes the area and its generated placements only', () {
      final result = DeleteTileLayerEnvironmentAreaUseCase().execute(
        _map(),
        tileLayerId: 'tile_layer',
        areaId: 'area_a',
      );

      final environmentLayer = _environmentLayer(result.map);

      expect(result.tileLayerId, 'tile_layer');
      expect(result.environmentLayerId, 'environment_layer');
      expect(result.deletedAreaId, 'area_a');
      expect(result.removedPlacementIds, ['generated_a', 'generated_b']);
      expect(result.removedPlacementCount, 2);
      expect(result.clearedReferenceCount, 3);
      expect(environmentLayer.content.targetTileLayerId, 'tile_layer');
      expect(environmentLayer.content.areaById('area_a'), isNull);
      expect(environmentLayer.content.areaById('area_b'), isNotNull);
      expect(_placedElementIds(result.map), ['manual', 'other_generated']);
      expect(
        environmentLayer.content.areaById('area_b')!.generatedPlacementIds,
        ['other_generated'],
      );
    });

    test(
        'preserves manual placements and generated placements from other areas',
        () {
      final result = DeleteTileLayerEnvironmentAreaUseCase().execute(
        _map(),
        tileLayerId: 'tile_layer',
        areaId: 'area_a',
      );

      final manual = result.map.placedElements.singleWhere(
        (placement) => placement.id == 'manual',
      );
      final otherGenerated = result.map.placedElements.singleWhere(
        (placement) => placement.id == 'other_generated',
      );

      expect(manual.layerId, 'tile_layer');
      expect(manual.elementId, 'tree');
      expect(otherGenerated.layerId, 'tile_layer');
      expect(otherGenerated.elementId, 'rock');
    });

    test('deleting the last area keeps the EnvironmentLayer attached', () {
      final map = _map(
        areas: [
          _area(
            id: 'area_a',
            generatedPlacementIds: ['generated_a'],
          ),
        ],
        placedElements: [
          _placement(id: 'generated_a', elementId: 'tree'),
          _placement(
            id: 'manual',
            elementId: 'tree',
            pos: const GridPos(x: 3, y: 3),
          ),
        ],
      );

      final result = DeleteTileLayerEnvironmentAreaUseCase().execute(
        map,
        tileLayerId: 'tile_layer',
        areaId: 'area_a',
      );

      final environmentLayer = _environmentLayer(result.map);

      expect(environmentLayer.content.targetTileLayerId, 'tile_layer');
      expect(environmentLayer.content.areas, isEmpty);
      expect(_placedElementIds(result.map), ['manual']);
    });

    test('accepts dead generated placement ids', () {
      final map = _map(
        areas: [
          _area(
            id: 'area_a',
            generatedPlacementIds: ['missing_generated'],
          ),
        ],
        placedElements: [
          _placement(id: 'manual', elementId: 'tree'),
        ],
      );

      final result = DeleteTileLayerEnvironmentAreaUseCase().execute(
        map,
        tileLayerId: 'tile_layer',
        areaId: 'area_a',
      );

      expect(result.removedPlacementIds, isEmpty);
      expect(result.removedPlacementCount, 0);
      expect(result.clearedReferenceCount, 1);
      expect(_environmentLayer(result.map).content.areas, isEmpty);
      expect(_placedElementIds(result.map), ['manual']);
    });

    test('refuses a missing TileLayer', () {
      expect(
        () => DeleteTileLayerEnvironmentAreaUseCase().execute(
          _map(),
          tileLayerId: 'missing_layer',
          areaId: 'area_a',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('refuses a missing area', () {
      expect(
        () => DeleteTileLayerEnvironmentAreaUseCase().execute(
          _map(),
          tileLayerId: 'tile_layer',
          areaId: 'missing_area',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });
  });
}

MapData _map({
  List<EnvironmentArea>? areas,
  List<MapPlacedElement>? placedElements,
}) {
  final resolvedAreas = areas ??
      [
        _area(
          id: 'area_a',
          generatedPlacementIds: ['generated_a', 'generated_b', 'dead_ref'],
        ),
        _area(
          id: 'area_b',
          name: 'Zone B',
          generatedPlacementIds: ['other_generated'],
        ),
      ];
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 8, height: 8),
    layers: [
      TileLayer(
        id: 'tile_layer',
        name: 'Décor',
        tiles: [
          for (var index = 0; index < 64; index++) 0,
        ],
      ),
      EnvironmentLayer(
        id: 'environment_layer',
        name: 'Environnement',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tile_layer',
          areas: resolvedAreas,
        ),
      ),
    ],
    placedElements: placedElements ??
        [
          _placement(id: 'manual', elementId: 'tree'),
          _placement(
            id: 'generated_a',
            elementId: 'tree',
            pos: const GridPos(x: 1, y: 1),
          ),
          _placement(
            id: 'generated_b',
            elementId: 'tree',
            pos: const GridPos(x: 2, y: 1),
          ),
          _placement(
            id: 'other_generated',
            elementId: 'rock',
            pos: const GridPos(x: 4, y: 4),
          ),
        ],
  );
}

EnvironmentArea _area({
  required String id,
  String name = 'Zone A',
  List<String> generatedPlacementIds = const [],
}) {
  return EnvironmentArea(
    id: id,
    name: name,
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 8,
      height: 8,
      cells: [
        for (var index = 0; index < 64; index++) index == 9 || index == 17,
      ],
    ),
    seed: 42,
    paramsOverride: EnvironmentGenerationParams(
      density: 0.7,
      edgeDensity: 0.3,
      variation: 0.4,
      minSpacingCells: 2,
    ),
    generatedPlacementIds: generatedPlacementIds,
  );
}

MapPlacedElement _placement({
  required String id,
  required String elementId,
  GridPos pos = const GridPos(x: 2, y: 2),
}) {
  return MapPlacedElement(
    id: id,
    layerId: 'tile_layer',
    elementId: elementId,
    pos: pos,
  );
}

EnvironmentLayer _environmentLayer(MapData map) {
  return map.layers.whereType<EnvironmentLayer>().single;
}

EnvironmentArea _areaById(MapData map, String id) {
  return _environmentLayer(map).content.areaById(id)!;
}

List<String> _placedElementIds(MapData map) {
  return [for (final placement in map.placedElements) placement.id];
}
