import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('queryMapRegion', () {
    test('returns clipped grid rows and intersecting spatial resources', () {
      final result = queryMapRegion(
        _map(),
        const MapRegionQuery(x: 1, y: 1, width: 2, height: 2),
      );
      final json = result.toJson();
      final layers = (json['layers']! as List).cast<Map<String, Object?>>();

      expect(json['mapId'], 'region-map');
      expect(json['bounds'], {
        'x': 1,
        'y': 1,
        'width': 2,
        'height': 2,
      });
      expect(layers[0]['rows'], [
        [5, 6],
        [9, 10],
      ]);
      expect(layers[1]['rows'], [
        [false, true],
        [true, false],
      ]);
      expect(
        (json['entities']! as List)
            .cast<Map<String, Object?>>()
            .map((entity) => entity['id']),
        ['inside-entity'],
      );
      expect(
        (json['placedElements']! as List)
            .cast<Map<String, Object?>>()
            .map((element) => element['id']),
        ['inside-element'],
      );
      expect(
        (json['warps']! as List)
            .cast<Map<String, Object?>>()
            .map((warp) => warp['id']),
        ['inside-warp'],
      );
      expect(
        (json['triggers']! as List)
            .cast<Map<String, Object?>>()
            .map((trigger) => trigger['id']),
        ['inside-trigger'],
      );
      expect(
        (json['gameplayZones']! as List)
            .cast<Map<String, Object?>>()
            .map((zone) => zone['id']),
        ['inside-zone'],
      );
    });

    test('returns metadata-only object layers', () {
      final result = queryMapRegion(
        _map(),
        const MapRegionQuery(x: 1, y: 1, width: 2, height: 2),
      );
      final layers =
          (result.toJson()['layers']! as List).cast<Map<String, Object?>>();
      final object = layers.singleWhere((layer) => layer['type'] == 'object');

      expect(object['encoding'], 'metadata_only');
      expect(object, isNot(contains('content')));
    });

    test('is materially smaller than the full map detail', () {
      final map = _map();
      final result = queryMapRegion(
        map,
        const MapRegionQuery(x: 1, y: 1, width: 1, height: 1),
      );

      expect(
        jsonEncode(result.toJson()).length,
        lessThan(jsonEncode(map.toJson()).length),
      );
    });

    test('rejects non-positive and out-of-bounds regions', () {
      expect(
        () => queryMapRegion(
          _map(),
          const MapRegionQuery(x: 0, y: 0, width: 0, height: 1),
        ),
        throwsA(
          isA<MapRegionQueryException>().having(
            (error) => error.code,
            'code',
            'map.region_size_invalid',
          ),
        ),
      );
      expect(
        () => queryMapRegion(
          _map(),
          const MapRegionQuery(x: 3, y: 2, width: 2, height: 2),
        ),
        throwsA(
          isA<MapRegionQueryException>().having(
            (error) => error.code,
            'code',
            'map.region_out_of_bounds',
          ),
        ),
      );
    });

    test('round-trips the strict region request JSON', () {
      const query = MapRegionQuery(x: 1, y: 2, width: 3, height: 4);

      expect(MapRegionQuery.fromJson(query.toJson()), query);
      expect(
        () => MapRegionQuery.fromJson({
          ...query.toJson(),
          'unknown': true,
        }),
        throwsFormatException,
      );
    });
  });
}

MapData _map() {
  return MapData(
    id: 'region-map',
    name: 'Region Map',
    size: const GridSize(width: 4, height: 3),
    version: ProjectVersion.v6,
    layers: [
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        cells: List.generate(12, (index) => index),
      ),
      const MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: [
          false,
          false,
          false,
          false,
          false,
          false,
          true,
          false,
          false,
          true,
          false,
          false,
        ],
      ),
      const MapLayer.smartTile(
        id: 'forest-surface',
        name: 'Forest surface',
        presetId: 'forest',
        usage: SmartTileUsage.forestSurface,
        materialPalette: <String>['', 'flowers', 'grass', 'water'],
        field: SmartTileField.cell(
          semanticCells: <int>[3, 0, 0, 0, 0, 0, 2, 0, 0, 1, 0, 0],
        ),
      ),
      const MapLayer.object(id: 'objects', name: 'Objects'),
    ],
    entities: const [
      MapEntity(
        id: 'inside-entity',
        name: 'Inside',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 2),
      ),
      MapEntity(
        id: 'outside-entity',
        name: 'Outside',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 0),
      ),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'inside-element',
        layerId: 'objects',
        elementId: 'tree',
        pos: GridPos(x: 1, y: 1),
      ),
      MapPlacedElement(
        id: 'outside-element',
        layerId: 'objects',
        elementId: 'rock',
        pos: GridPos(x: 0, y: 0),
      ),
    ],
    warps: const [
      MapWarp(
        id: 'inside-warp',
        pos: GridPos(x: 2, y: 1),
        targetMapId: 'other',
        targetPos: GridPos(x: 0, y: 0),
      ),
      MapWarp(
        id: 'outside-warp',
        pos: GridPos(x: 0, y: 0),
        targetMapId: 'other',
        targetPos: GridPos(x: 0, y: 0),
      ),
    ],
    triggers: const [
      MapTrigger(
        id: 'inside-trigger',
        type: TriggerType.custom,
        area: MapRect(
          pos: GridPos(x: 2, y: 2),
          size: GridSize(width: 1, height: 1),
        ),
      ),
      MapTrigger(
        id: 'outside-trigger',
        type: TriggerType.custom,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ],
    gameplayZones: const [
      MapGameplayZone(
        id: 'inside-zone',
        kind: GameplayZoneKind.custom,
        area: MapRect(
          pos: GridPos(x: 1, y: 2),
          size: GridSize(width: 2, height: 1),
        ),
      ),
      MapGameplayZone(
        id: 'outside-zone',
        kind: GameplayZoneKind.custom,
        area: MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
      ),
    ],
  );
}
