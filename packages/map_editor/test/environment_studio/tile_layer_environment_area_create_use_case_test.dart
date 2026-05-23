import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart';

void main() {
  group('CreateTileLayerEnvironmentAreaUseCase', () {
    test('crée une EnvironmentArea dans l’EnvironmentLayer attaché', () {
      final result = _useCase.execute(
        _mapWithAttachment(),
        manifest: _manifest(),
        tileLayerId: 'tiles',
        presetId: 'forest',
      );

      expect(result.created, isTrue);
      expect(result.tileLayerId, 'tiles');
      expect(result.environmentLayerId, 'env');
      expect(result.presetId, 'forest');
      expect(result.areaId, 'env_area_forest');

      final envLayer = result.map.layers.whereType<EnvironmentLayer>().single;
      final area = envLayer.content.areas.single;
      expect(area.id, result.areaId);
      expect(area.name, 'Forêt');
      expect(area.presetId, 'forest');
      expect(area.mask.width, 3);
      expect(area.mask.height, 2);
      expect(area.mask.activeCellCount, 0);
      expect(area.mask.cells.length, 6);
      expect(area.generatedPlacementIds, isEmpty);
      expect(area.paramsOverride, isNull);
      expect(area.seed, 0);
      expect(result.map.placedElements, isEmpty);
    });

    test('génère un id unique et garde un nom lisible', () {
      final result = _useCase.execute(
        _mapWithAttachment(
          areas: [_area(id: 'env_area_forest', presetId: 'forest')],
        ),
        manifest: _manifest(),
        tileLayerId: 'tiles',
        presetId: 'forest',
      );

      final envLayer = result.map.layers.whereType<EnvironmentLayer>().single;
      expect(result.areaId, 'env_area_forest_2');
      expect(envLayer.content.areas.map((area) => area.id), [
        'env_area_forest',
        'env_area_forest_2',
      ]);
      expect(envLayer.content.areas.last.name, 'Forêt');
    });

    test('refuse tileLayerId vide', () {
      expect(
        () => _useCase.execute(
          _mapWithAttachment(),
          manifest: _manifest(),
          tileLayerId: ' ',
          presetId: 'forest',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('refuse TileLayer introuvable', () {
      expect(
        () => _useCase.execute(
          _mapWithAttachment(),
          manifest: _manifest(),
          tileLayerId: 'missing',
          presetId: 'forest',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('refuse layer non TileLayer', () {
      expect(
        () => _useCase.execute(
          _mapWithAttachment(
            layers: const [
              ObjectLayer(id: 'objects', name: 'Objects'),
            ],
          ),
          manifest: _manifest(),
          tileLayerId: 'objects',
          presetId: 'forest',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('refuse absence d’EnvironmentLayer attaché', () {
      expect(
        () => _useCase.execute(
          _mapWithAttachment(
            layers: const [
              TileLayer(id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0, 0, 0]),
            ],
          ),
          manifest: _manifest(),
          tileLayerId: 'tiles',
          presetId: 'forest',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('refuse presetId vide ou absent du manifest', () {
      expect(
        () => _useCase.execute(
          _mapWithAttachment(),
          manifest: _manifest(),
          tileLayerId: 'tiles',
          presetId: ' ',
        ),
        throwsA(isA<EditorValidationException>()),
      );
      expect(
        () => _useCase.execute(
          _mapWithAttachment(),
          manifest: _manifest(),
          tileLayerId: 'tiles',
          presetId: 'missing',
        ),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('préserve les autres layers et les placedElements', () {
      const placed = MapPlacedElement(
        id: 'placed',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      );
      final map = _mapWithAttachment(
        placedElements: [placed],
        layers: [
          const TileLayer(
              id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0, 0, 0]),
          MapLayer.environment(
            id: 'env',
            name: 'Environment',
            content: EnvironmentLayerContent(targetTileLayerId: 'tiles'),
          ),
          const ObjectLayer(id: 'objects', name: 'Objects'),
        ],
      );

      final result = _useCase.execute(
        map,
        manifest: _manifest(),
        tileLayerId: 'tiles',
        presetId: 'forest',
      );

      expect(result.map.layers.first, map.layers.first);
      expect(result.map.layers.last, map.layers.last);
      expect(result.map.placedElements, [placed]);
      expect(result.map.placedElements.length, 1);
    });

    test('ajoute dans le premier EnvironmentLayer attaché selon l’ordre', () {
      final result = _useCase.execute(
        _mapWithAttachment(
          layers: [
            const TileLayer(
                id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0, 0, 0]),
            MapLayer.environment(
              id: 'env_a',
              name: 'Environment A',
              content: EnvironmentLayerContent(targetTileLayerId: 'tiles'),
            ),
            MapLayer.environment(
              id: 'env_b',
              name: 'Environment B',
              content: EnvironmentLayerContent(targetTileLayerId: 'tiles'),
            ),
          ],
        ),
        manifest: _manifest(),
        tileLayerId: 'tiles',
        presetId: 'forest',
      );

      final envA = result.map.layers.whereType<EnvironmentLayer>().first;
      final envB = result.map.layers.whereType<EnvironmentLayer>().last;
      expect(result.environmentLayerId, 'env_a');
      expect(envA.content.areas.length, 1);
      expect(envB.content.areas, isEmpty);
    });
  });
}

final _useCase = CreateTileLayerEnvironmentAreaUseCase();

MapData _mapWithAttachment({
  List<EnvironmentArea> areas = const [],
  List<MapLayer>? layers,
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 2),
    layers: layers ??
        [
          const TileLayer(
              id: 'tiles', name: 'Ground', tiles: [0, 0, 0, 0, 0, 0]),
          MapLayer.environment(
            id: 'env',
            name: 'Environment',
            content: EnvironmentLayerContent(
              targetTileLayerId: 'tiles',
              areas: areas,
            ),
          ),
        ],
    placedElements: placedElements,
  );
}

ProjectManifest _manifest({
  List<EnvironmentPreset>? presets,
}) {
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
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    environmentPresets: presets ?? [_preset(id: 'forest', name: 'Forêt')],
  );
}

EnvironmentPreset _preset({required String id, required String name}) {
  return EnvironmentPreset(
    id: id,
    name: name,
    templateId: id,
    palette: [
      EnvironmentPaletteItem(elementId: 'tree', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams(
      density: 1,
      variation: 0,
      edgeDensity: 1,
      minSpacingCells: 0,
    ),
    sortOrder: 0,
  );
}

EnvironmentArea _area({
  required String id,
  required String presetId,
}) {
  return EnvironmentArea(
    id: id,
    name: 'Existing',
    presetId: presetId,
    mask: EnvironmentAreaMask(
      width: 3,
      height: 2,
      cells: List<bool>.filled(6, false),
    ),
    seed: 0,
  );
}
