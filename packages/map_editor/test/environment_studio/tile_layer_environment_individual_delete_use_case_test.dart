import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart';

void main() {
  group('DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase', () {
    test('supprime un placement généré cliqué dans son footprint', () {
      final map = _map();
      final result =
          DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase().execute(
        map,
        manifest: _manifest(),
        tileLayerId: 'tiles',
        areaId: 'area',
        pos: const GridPos(x: 2, y: 2),
      );

      expect(result.removed, isTrue);
      expect(result.removedPlacementId, 'generated_big');
      expect(result.tileLayerId, 'tiles');
      expect(result.environmentLayerId, 'env');
      expect(result.areaId, 'area');
      expect(
        result.map.placedElements.map((element) => element.id).toList(),
        const ['manual', 'generated_a', 'other_generated'],
      );

      final area = _areaById(result.map, 'area');
      expect(area.generatedPlacementIds, const ['generated_a', 'missing_ref']);
      expect(area.mask, _areaById(map, 'area').mask);
      expect(area.paramsOverride, _params);
      expect(area.seed, 11);
      expect(area.presetId, 'forest');

      final other = _areaById(result.map, 'other');
      expect(other.generatedPlacementIds, const ['other_generated']);
    });

    test('préserve les placements manuels et les placements d’une autre area',
        () {
      final map = _map();
      final useCase = DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase();

      final manualResult = useCase.execute(
        map,
        manifest: _manifest(),
        tileLayerId: 'tiles',
        areaId: 'area',
        pos: const GridPos(x: 0, y: 0),
      );
      expect(identical(manualResult.map, map), isTrue);
      expect(manualResult.removed, isFalse);

      final otherAreaResult = useCase.execute(
        map,
        manifest: _manifest(),
        tileLayerId: 'tiles',
        areaId: 'area',
        pos: const GridPos(x: 4, y: 4),
      );
      expect(identical(otherAreaResult.map, map), isTrue);
      expect(otherAreaResult.removed, isFalse);
      expect(
        otherAreaResult.map.placedElements.map((element) => element.id),
        containsAll(const ['manual', 'other_generated']),
      );
      expect(
        _areaById(otherAreaResult.map, 'other').generatedPlacementIds,
        const ['other_generated'],
      );
    });

    test('refuse les entrées invalides sans mutation', () {
      final useCase = DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase();
      final map = _map();

      expect(
        () => useCase.execute(
          map,
          manifest: _manifest(),
          tileLayerId: '',
          areaId: 'area',
          pos: const GridPos(x: 1, y: 1),
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          map,
          manifest: _manifest(),
          tileLayerId: 'missing',
          areaId: 'area',
          pos: const GridPos(x: 1, y: 1),
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _mapWithNonTileActiveLayer(),
          manifest: _manifest(),
          tileLayerId: 'tiles',
          areaId: 'area',
          pos: const GridPos(x: 1, y: 1),
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          _mapWithoutEnvironmentAttachment(),
          manifest: _manifest(),
          tileLayerId: 'tiles',
          areaId: 'area',
          pos: const GridPos(x: 1, y: 1),
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          map,
          manifest: _manifest(),
          tileLayerId: 'tiles',
          areaId: '',
          pos: const GridPos(x: 1, y: 1),
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => useCase.execute(
          map,
          manifest: _manifest(),
          tileLayerId: 'tiles',
          areaId: 'missing',
          pos: const GridPos(x: 1, y: 1),
        ),
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

MapData _map() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 5, height: 5),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tilesetId: 'nature',
        tiles: [
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
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
                width: 5,
                height: 5,
                cells: List<bool>.filled(25, true),
              ),
              seed: 11,
              paramsOverride: _params,
              generatedPlacementIds: const [
                'generated_a',
                'generated_big',
                'missing_ref',
              ],
            ),
            EnvironmentArea(
              id: 'other',
              name: 'Other',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 5,
                height: 5,
                cells: List<bool>.filled(25, true),
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
        pos: GridPos(x: 0, y: 2),
      ),
      MapPlacedElement(
        id: 'generated_big',
        layerId: 'tiles',
        elementId: 'big_tree',
        pos: GridPos(x: 1, y: 1),
      ),
      MapPlacedElement(
        id: 'other_generated',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 4, y: 4),
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
      ProjectElementEntry(
        id: 'big_tree',
        name: 'Big Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
          ),
        ],
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
          EnvironmentPaletteItem(elementId: 'big_tree', weight: 1),
        ],
        defaultParams: _params,
        sortOrder: 0,
      ),
    ],
  );
}
