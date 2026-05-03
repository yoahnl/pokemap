import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

MapData _minimalMap({
  required List<MapLayer> layers,
  List<MapPlacedElement>? placedElements,
}) {
  return MapData(
    id: 'm_test',
    name: 'Test',
    size: const GridSize(width: 10, height: 8),
    tilesetId: 'ts',
    layers: layers,
    placedElements: placedElements ?? const [],
  );
}

EnvironmentArea _areaFor1024({
  required String id,
  String presetId = 'preset_a',
}) {
  final cells = List<bool>.filled(10 * 8, false);
  return EnvironmentArea(
    id: id,
    name: 'n$id',
    presetId: presetId,
    mask: EnvironmentAreaMask(width: 10, height: 8, cells: cells),
    seed: 0,
  );
}

void main() {
  group('MapLayer.environment', () {
    test('valeurs par défaut et content vide', () {
      const layer = MapLayer.environment(id: 'e1', name: 'Env');
      final env = layer as EnvironmentLayer;
      expect(env.isVisible, isTrue);
      expect(env.opacity, 1.0);
      expect(env.content, EnvironmentLayerContent.emptyContent);
      expect(env.properties, isEmpty);
    });

    test('toJson/fromJson roundtrip', () {
      final layer = MapLayer.environment(
        id: 'env1',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles_main',
          areas: [_areaFor1024(id: 'z1')],
        ),
        properties: {'k': 'v'},
      );
      final json = layer.toJson();
      final decoded = MapLayer.fromJson(json);
      expect(decoded, layer);
    });

    test('fromJson sans content => content vide', () {
      final decoded = MapLayer.fromJson(<String, dynamic>{
        'runtimeType': 'environment',
        'id': 'e',
        'name': 'E',
        'isVisible': true,
        'opacity': 1.0,
        'properties': <String, String>{},
      });
      expect(decoded, isA<EnvironmentLayer>());
      expect((decoded as EnvironmentLayer).content,
          EnvironmentLayerContent.emptyContent);
    });

    test('copyWith préserve content et properties si non passés', () {
      final layer = MapLayer.environment(
        id: 'e',
        name: 'Old',
        content: EnvironmentLayerContent(targetTileLayerId: 't', areas: null),
        properties: {'a': 'b'},
      );
      final next = layer.copyWith(name: 'New') as EnvironmentLayer;
      expect(next.name, 'New');
      expect(next.content.targetTileLayerId, 't');
      expect(next.properties, {'a': 'b'});
    });
  });

  group('addMapLayer MapLayerKind.environment', () {
    test('crée EnvironmentLayer avec ids normalisés et content vide', () {
      final map = _minimalMap(layers: []);
      final updated = addMapLayer(
        map,
        kind: MapLayerKind.environment,
        id: '  my_env  ',
        name: '  Meta  ',
      );
      expect(updated.layers, hasLength(1));
      final layer = updated.layers.single as EnvironmentLayer;
      expect(layer.id, 'my_env');
      expect(layer.name, 'Meta');
      expect(layer.content, EnvironmentLayerContent.emptyContent);
      expect(layer.content.targetTileLayerId, isNull);
      expect(updated.placedElements, isEmpty);
    });

    test('insertIndex comme autres layers non-path', () {
      final base = _minimalMap(layers: [
        MapLayer.tile(
          id: 't1',
          name: 'T',
          tiles: List<int>.filled(80, 0),
        ),
      ]);
      final updated = addMapLayer(
        base,
        kind: MapLayerKind.environment,
        id: 'env',
        name: 'Env',
        insertIndex: 0,
      );
      expect(updated.layers.first.id, 'env');
      expect(updated.layers[1].id, 't1');
    });
  });

  group('setEnvironmentLayerContent', () {
    test('remplace content et conserve méta', () {
      final env =
          MapLayer.environment(id: 'e', name: 'N', properties: {'x': 'y'});
      final map = _minimalMap(layers: [env]);
      final nextContent = EnvironmentLayerContent(
        targetTileLayerId: 'tiles_main',
        areas: [_areaFor1024(id: 'a1')],
      );
      final out = setEnvironmentLayerContent(
        map,
        layerId: 'e',
        content: nextContent,
      );
      final layer = out.layers.single as EnvironmentLayer;
      expect(layer.content, nextContent);
      expect(layer.name, 'N');
      expect(layer.isVisible, isTrue);
      expect(layer.opacity, 1.0);
      expect(layer.properties, {'x': 'y'});
    });

    test('refuse layerId vide', () {
      expect(
        () => setEnvironmentLayerContent(
          _minimalMap(layers: []),
          layerId: '   ',
          content: EnvironmentLayerContent.emptyContent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuse layer inconnu', () {
      expect(
        () => setEnvironmentLayerContent(
          _minimalMap(layers: []),
          layerId: 'x',
          content: EnvironmentLayerContent.emptyContent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('refuse layer non EnvironmentLayer', () {
      final map = _minimalMap(layers: [
        MapLayer.tile(
          id: 't',
          name: 'T',
          tiles: List<int>.filled(80, 0),
        ),
      ]);
      expect(
        () => setEnvironmentLayerContent(
          map,
          layerId: 't',
          content: EnvironmentLayerContent.emptyContent,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('ne modifie pas placedElements', () {
      final placed = MapPlacedElement(
        id: 'pe1',
        layerId: 't',
        elementId: 'elm',
        pos: const GridPos(x: 0, y: 0),
      );
      final map = _minimalMap(
        layers: [
          MapLayer.environment(id: 'e', name: 'E'),
          MapLayer.tile(
            id: 't',
            name: 'T',
            tiles: List<int>.filled(80, 0),
          ),
        ],
        placedElements: [placed],
      );
      final out = setEnvironmentLayerContent(
        map,
        layerId: 'e',
        content: EnvironmentLayerContent(targetTileLayerId: 't', areas: null),
      );
      expect(out.placedElements, map.placedElements);
    });
  });

  group('MapValidator EnvironmentLayer', () {
    test('map valide avec EnvironmentLayer vide', () {
      final map = _minimalMap(layers: [
        MapLayer.environment(id: 'e', name: 'E'),
      ]);
      expect(() => MapValidator.validate(map), returnsNormally);
    });

    test('targetTileLayerId valide si TileLayer existe', () {
      final map = _minimalMap(layers: [
        MapLayer.tile(
          id: 'decor',
          name: 'D',
          tiles: List<int>.filled(80, 0),
        ),
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'decor',
            areas: null,
          ),
        ),
      ]);
      expect(() => MapValidator.validate(map), returnsNormally);
    });

    test('invalide si targetTileLayerId inconnu', () {
      final map = _minimalMap(layers: [
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'missing',
            areas: null,
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
        'invalide si targetTileLayerId pointe vers le layer environment lui-même',
        () {
      final map = _minimalMap(layers: [
        MapLayer.tile(
          id: 'decor',
          name: 'D',
          tiles: List<int>.filled(80, 0),
        ),
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'e',
            areas: null,
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test('invalide si target pointe vers non-TileLayer', () {
      final map = _minimalMap(layers: [
        MapLayer.object(id: 'o', name: 'O'),
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            targetTileLayerId: 'o',
            areas: null,
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });

    test('invalide si masque ne correspond pas à la taille carte', () {
      final badMask = EnvironmentAreaMask(
        width: 2,
        height: 2,
        cells: List<bool>.filled(4, false),
      );
      final map = _minimalMap(layers: [
        MapLayer.environment(
          id: 'e',
          name: 'E',
          content: EnvironmentLayerContent(
            areas: [
              EnvironmentArea(
                id: 'z',
                name: 'Z',
                presetId: 'p',
                mask: badMask,
                seed: 0,
              ),
            ],
          ),
        ),
      ]);
      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('MapLayer.environment JSON edge cases', () {
    test('fromJson avec content null => emptyContent', () {
      final decoded = MapLayer.fromJson(<String, dynamic>{
        'runtimeType': 'environment',
        'id': 'e',
        'name': 'E',
        'content': null,
        'properties': <String, String>{},
      });
      expect((decoded as EnvironmentLayer).content,
          EnvironmentLayerContent.emptyContent);
    });

    test('properties roundtrip', () {
      final layer = MapLayer.environment(
        id: 'e',
        name: 'E',
        properties: {'k': 'v', 'x': 'y'},
      );
      final back = MapLayer.fromJson(layer.toJson()) as EnvironmentLayer;
      expect(back.properties, {'k': 'v', 'x': 'y'});
    });
  });

  group('resizeMapData EnvironmentLayer', () {
    test('agrandit la carte : masque redimensionné, métadonnées conservées',
        () {
      final envLayer = MapLayer.environment(
        id: 'env',
        name: 'Env',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            EnvironmentArea(
              id: 'z',
              name: 'Z',
              presetId: 'p',
              mask: EnvironmentAreaMask(
                width: 2,
                height: 2,
                cells: [true, false, false, false],
              ),
              seed: 3,
              paramsOverride: EnvironmentGenerationParams(
                density: 0.5,
                variation: 0.5,
                edgeDensity: 0.5,
                minSpacingCells: 2,
              ),
              generatedPlacementIds: ['p1'],
            ),
          ],
        ),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'ts',
        layers: [envLayer],
      );
      final resized = resizeMapData(map, width: 3, height: 3);
      final env = resized.layers.single as EnvironmentLayer;
      expect(env.content.targetTileLayerId, 'tiles');
      final area = env.content.areas.single;
      expect(area.id, 'z');
      expect(area.name, 'Z');
      expect(area.presetId, 'p');
      expect(area.seed, 3);
      expect(area.paramsOverride, isNotNull);
      expect(area.generatedPlacementIds, ['p1']);
      expect(area.mask.width, 3);
      expect(area.mask.height, 3);
      expect(area.mask.cells, hasLength(9));
      expect(area.mask.cells[0], isTrue);
      expect(area.mask.cells[8], isFalse);
    });

    test('rétrécit la carte : cellules hors carte supprimées', () {
      final cells = List<bool>.filled(9, false);
      cells[8] = true;
      final envLayer = MapLayer.environment(
        id: 'env',
        name: 'Env',
        content: EnvironmentLayerContent(
          areas: [
            EnvironmentArea(
              id: 'z',
              name: 'Z',
              presetId: 'p',
              mask: EnvironmentAreaMask(
                width: 3,
                height: 3,
                cells: cells,
              ),
              seed: 0,
            ),
          ],
        ),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 3, height: 3),
        tilesetId: 'ts',
        layers: [envLayer],
      );
      final resized = resizeMapData(map, width: 2, height: 2);
      final area =
          (resized.layers.single as EnvironmentLayer).content.areas.single;
      expect(area.mask.width, 2);
      expect(area.mask.height, 2);
      expect(area.mask.cells, everyElement(isFalse));
    });
  });
}
