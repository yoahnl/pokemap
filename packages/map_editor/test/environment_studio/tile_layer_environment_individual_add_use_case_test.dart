import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart';

void main() {
  group('AddTileLayerEnvironmentGeneratedPlacementAtUseCase', () {
    test('ajoute un placement généré à une position valide', () {
      final map = _map();
      final result =
          AddTileLayerEnvironmentGeneratedPlacementAtUseCase().execute(
        map,
        manifest: _manifest(),
        tileLayerId: 'tiles',
        areaId: 'area',
        elementId: 'big_tree',
        pos: const GridPos(x: 2, y: 2),
      );

      expect(result.added, isTrue);
      expect(result.addedPlacementId, 'env_gen_area_2_2_big_tree');
      expect(result.tileLayerId, 'tiles');
      expect(result.environmentLayerId, 'env');
      expect(result.areaId, 'area');

      final added = result.map.placedElements.singleWhere(
        (element) => element.id == result.addedPlacementId,
      );
      expect(added.layerId, 'tiles');
      expect(added.elementId, 'big_tree');
      expect(added.pos, const GridPos(x: 2, y: 2));
      expect(added.applyCollision, isFalse);

      final area = _areaById(result.map, 'area');
      expect(area.generatedPlacementIds, const [
        'generated_a',
        'env_gen_area_2_2_big_tree',
      ]);
      expect(area.mask, _areaById(map, 'area').mask);
      expect(area.paramsOverride, _params);
      expect(area.seed, 11);
      expect(area.presetId, 'forest');
      expect(
        result.map.placedElements.map((element) => element.id),
        containsAll(const ['manual', 'generated_a', 'other_generated']),
      );
      expect(
        _areaById(result.map, 'other').generatedPlacementIds,
        const ['other_generated'],
      );
    });

    test('génère un id suffixé si l’id stable est déjà utilisé', () {
      final map = _map(
        extraPlacedElements: const [
          MapPlacedElement(
            id: 'env_gen_area_2_2_tree',
            layerId: 'tiles',
            elementId: 'tree',
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      );

      final result =
          AddTileLayerEnvironmentGeneratedPlacementAtUseCase().execute(
        map,
        manifest: _manifest(),
        tileLayerId: 'tiles',
        areaId: 'area',
        elementId: 'tree',
        pos: const GridPos(x: 2, y: 2),
      );

      expect(result.addedPlacementId, 'env_gen_area_2_2_tree_2');
      expect(_areaById(result.map, 'area').generatedPlacementIds,
          contains('env_gen_area_2_2_tree_2'));
    });

    test('refuse les entrées et positions invalides sans mutation', () {
      final useCase = AddTileLayerEnvironmentGeneratedPlacementAtUseCase();
      final map = _map();

      for (final action in <void Function()>[
        () => useCase.execute(
              map,
              manifest: _manifest(),
              tileLayerId: '',
              areaId: 'area',
              elementId: 'tree',
              pos: const GridPos(x: 1, y: 1),
            ),
        () => useCase.execute(
              map,
              manifest: _manifest(),
              tileLayerId: 'missing',
              areaId: 'area',
              elementId: 'tree',
              pos: const GridPos(x: 1, y: 1),
            ),
        () => useCase.execute(
              _mapWithNonTileActiveLayer(),
              manifest: _manifest(),
              tileLayerId: 'tiles',
              areaId: 'area',
              elementId: 'tree',
              pos: const GridPos(x: 1, y: 1),
            ),
        () => useCase.execute(
              _mapWithoutEnvironmentAttachment(),
              manifest: _manifest(),
              tileLayerId: 'tiles',
              areaId: 'area',
              elementId: 'tree',
              pos: const GridPos(x: 1, y: 1),
            ),
        () => useCase.execute(
              map,
              manifest: _manifest(),
              tileLayerId: 'tiles',
              areaId: '',
              elementId: 'tree',
              pos: const GridPos(x: 1, y: 1),
            ),
        () => useCase.execute(
              map,
              manifest: _manifest(),
              tileLayerId: 'tiles',
              areaId: 'missing',
              elementId: 'tree',
              pos: const GridPos(x: 1, y: 1),
            ),
        () => useCase.execute(
              _map(generatedPlacementIds: const []),
              manifest: _manifest(),
              tileLayerId: 'tiles',
              areaId: 'area',
              elementId: 'tree',
              pos: const GridPos(x: 1, y: 1),
            ),
        () => useCase.execute(
              map,
              manifest: _manifest(),
              tileLayerId: 'tiles',
              areaId: 'area',
              elementId: 'rock',
              pos: const GridPos(x: 1, y: 1),
            ),
        () => useCase.execute(
              map,
              manifest: _manifest(missingBigTree: true),
              tileLayerId: 'tiles',
              areaId: 'area',
              elementId: 'big_tree',
              pos: const GridPos(x: 1, y: 1),
            ),
        () => useCase.execute(
              map,
              manifest: _manifest(),
              tileLayerId: 'tiles',
              areaId: 'area',
              elementId: 'big_tree',
              pos: const GridPos(x: -1, y: 1),
            ),
        () => useCase.execute(
              map,
              manifest: _manifest(),
              tileLayerId: 'tiles',
              areaId: 'area',
              elementId: 'big_tree',
              pos: const GridPos(x: 4, y: 4),
            ),
      ]) {
        expect(action, throwsA(isA<EditorValidationException>()));
      }

      expect(map.placedElements.length, 3);
      expect(
          _areaById(map, 'area').generatedPlacementIds, const ['generated_a']);
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
  List<String> generatedPlacementIds = const ['generated_a'],
  List<MapPlacedElement> extraPlacedElements = const [],
}) {
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
              generatedPlacementIds: generatedPlacementIds,
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
    placedElements: [
      const MapPlacedElement(
        id: 'manual',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
      ),
      const MapPlacedElement(
        id: 'generated_a',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 2),
      ),
      const MapPlacedElement(
        id: 'other_generated',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 4, y: 4),
      ),
      ...extraPlacedElements,
    ],
  );
}

MapData _mapWithoutEnvironmentAttachment() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 5, height: 5),
    tilesetId: 'nature',
    layers: [
      TileLayer(
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
    ],
  );
}

MapData _mapWithNonTileActiveLayer() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 5, height: 5),
    tilesetId: 'nature',
    layers: [
      const MapLayer.object(id: 'tiles', name: 'Objects'),
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
              generatedPlacementIds: const ['generated_a'],
            ),
          ],
        ),
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

ProjectManifest _manifest({bool missingBigTree = false}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: [
      const ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
      if (!missingBigTree)
        const ProjectElementEntry(
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
      const ProjectElementEntry(
        id: 'rock',
        name: 'Rock',
        tilesetId: 'nature',
        categoryId: 'rocks',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forest',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
          EnvironmentPaletteItem(
            elementId: 'big_tree',
            weight: 1,
            collisionMode: EnvironmentCollisionMode.forceDisabled,
          ),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          variation: 0,
          edgeDensity: 1,
          minSpacingCells: 0,
        ),
        sortOrder: 0,
      ),
    ],
  );
}
