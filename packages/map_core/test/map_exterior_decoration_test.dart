import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ExteriorDecorationSector sector({
  String id = 'west',
  int x = -4,
  int z = 0,
  int width = 4,
  int depth = 4,
  MapSpatialScene? scene,
  List<MapLayer> layers = const [],
}) => ExteriorDecorationSector(
  id: id,
  originX: x,
  originZ: z,
  scene: scene ?? MapSpatialScene(width: width, depth: depth),
  layers: layers,
);

MapExteriorDecoration document({
  List<ExteriorDecorationSector>? sectors,
  int west = 4,
}) => MapExteriorDecoration(
  mapId: 'route_30',
  playableWidth: 8,
  playableDepth: 8,
  west: west,
  east: 4,
  north: 4,
  south: 4,
  sectors: sectors ?? [sector()],
);

void main() {
  test('roundtrips signed sectors and immutable native visual layers', () {
    final layers = <MapLayer>[
      MapLayer.smartTile(
        id: 'ground',
        name: 'Ground',
        presetId: 'grass',
        usage: SmartTileUsage.terrain,
        materialPalette: ['', 'grass'],
        field: SmartTileField.cell(semanticCells: List.filled(16, 1)),
      ),
      const MapLayer.border(id: 'shore', name: 'Shore'),
      const MapLayer.environment(id: 'trees', name: 'Trees'),
    ];
    final source = document(sectors: [sector(layers: layers)]);
    final reopened = MapExteriorDecoration.fromJson(
      jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>,
    );
    expect(reopened, source);
    expect(reopened.hashCode, source.hashCode);
    expect(reopened.sectors.single.originX, -4);
    expect(reopened.sectors.single.layers, layers);
    expect(() => reopened.sectors.clear(), throwsUnsupportedError);
    expect(
      () => reopened.sectors.single.layers.clear(),
      throwsUnsupportedError,
    );
  });

  test('256 by 256 playable map keeps all four margins in sparse sectors', () {
    final sectors = <ExteriorDecorationSector>[];
    for (var index = 0; index < 8; index++) {
      sectors.addAll([
        sector(id: 'w$index', x: -32, z: index * 32, width: 32, depth: 32),
        sector(id: 'e$index', x: 256, z: index * 32, width: 32, depth: 32),
        sector(id: 'n$index', x: index * 32, z: -32, width: 32, depth: 32),
        sector(id: 's$index', x: index * 32, z: 256, width: 32, depth: 32),
      ]);
    }
    final source = MapExteriorDecoration(
      mapId: 'large',
      playableWidth: 256,
      playableDepth: 256,
      west: 32,
      east: 32,
      north: 32,
      south: 32,
      sectors: sectors,
    );
    expect(source.outerBounds.width, 320);
    expect(source.outerBounds.depth, 320);
    expect(MapExteriorDecoration.fromJson(source.toJson()), source);
    expect(() => MapSpatialScene(width: 257, depth: 1), throwsFormatException);
  });

  test('projects only visual data into an unregistered v9 map', () {
    final source = sector();
    final projection = source.asVisualMap();
    expect(projection.version, ProjectVersion.v9);
    expect(projection.spatialScene, same(source.scene));
    expect(projection.size, const GridSize(width: 4, height: 4));
    expect(projection.entities, isEmpty);
    expect(projection.connections, isEmpty);
    expect(projection.warps, isEmpty);
    expect(projection.events, isEmpty);
    expect(projection.triggers, isEmpty);
    expect(projection.gameplayZones, isEmpty);
    expect(MapData.fromJson(projection.toJson()), projection);
  });

  test('masks central and real neighbors using half-open world bounds', () {
    final source = document(sectors: [sector(x: -2)]);
    final neighbor = ExteriorDecorationRect(x: -4, z: 0, width: 2, depth: 8);
    expect(source.isExcluded(0, 0), isTrue);
    expect(source.isExcluded(7.9, 7.9), isTrue);
    expect(source.isExcluded(8, 0), isFalse);
    expect(source.isExcluded(-1, 0), isFalse);
    expect(source.isExcluded(-3, 2, neighborBounds: [neighbor]), isTrue);
    expect(source.isExcluded(-2, 2, neighborBounds: [neighbor]), isFalse);
    expect(source.outerBounds.contains(-4, -4), isTrue);
    expect(source.outerBounds.contains(12, 0), isFalse);
  });

  test('validates attached map identity dimensions and v9 scene', () {
    final map = MapData(
      id: 'route_30',
      name: 'Route 30',
      size: const GridSize(width: 8, height: 8),
      version: ProjectVersion.v9,
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    );
    expect(() => document().validateForMap(map), returnsNormally);
    for (final other in [
      map.copyWith(id: 'other'),
      map.copyWith(size: const GridSize(width: 9, height: 8)),
      map.copyWith(version: ProjectVersion.v8, spatialScene: null),
    ]) {
      expect(() => document().validateForMap(other), throwsFormatException);
    }
    expect(MapData.fromJson(map.toJson()), map);
    expect(map.toJson().containsKey('exteriorDecoration'), isFalse);
  });

  test('rejects unsupported versions missing fields and hidden gameplay', () {
    for (final json in [
      {...document().toJson(), 'schemaVersion': 2},
      {...document().toJson(), 'schemaVersion': 1.0},
      {...document().toJson()}..remove('mapId'),
      {...document().toJson(), 'warps': []},
      {...document().toJson(), 'sectors': null},
      {...document().toJson(), 'west': '4'},
    ]) {
      expect(() => MapExteriorDecoration.fromJson(json), throwsFormatException);
    }
    final rawSector = sector().toJson();
    expect(
      () => ExteriorDecorationSector.fromJson({...rawSector, 'entities': []}),
      throwsFormatException,
    );
    expect(
      () => ExteriorDecorationSector.fromJson({
        ...rawSector,
        'scene': {...sector().scene.toJson(), 'events': []},
      }),
      throwsFormatException,
    );
  });

  test('rejects unsafe identities invalid margins bounds and overlap', () {
    for (final id in ['', '../escape', 'a/b', 'a b', 'a' * 129]) {
      expect(() => sector(id: id), throwsFormatException);
      expect(
        () => MapExteriorDecoration(
          mapId: id,
          playableWidth: 8,
          playableDepth: 8,
        ),
        throwsFormatException,
      );
    }
    for (final margin in [-1, 65]) {
      expect(() => document(west: margin), throwsFormatException);
    }
    expect(() => document(sectors: [sector(x: -5)]), throwsFormatException);
    expect(() => document(sectors: [sector(z: 10)]), throwsFormatException);
    expect(
      () => document(sectors: [sector(), sector()]),
      throwsFormatException,
    );
    expect(
      () => document(
        sectors: [
          sector(),
          sector(id: 'other', x: -3),
        ],
      ),
      throwsFormatException,
    );
    expect(() => sector(width: 33), throwsFormatException);
    expect(
      () => MapExteriorDecoration(
        mapId: 'map',
        playableWidth: 257,
        playableDepth: 8,
      ),
      throwsFormatException,
    );
  });

  test('enforces finite sector and aggregate instance quotas', () {
    expect(
      () => document(sectors: List.generate(257, (i) => sector(id: 's$i'))),
      throwsFormatException,
    );
    MapSpatialScene dense(int count) => MapSpatialScene(
      width: 4,
      depth: 4,
      instances: List.generate(
        count,
        (i) => SpatialModelInstance(
          id: 'tree$i',
          modelId: 'tree',
          position: Model3dVector3.zero,
        ),
      ),
    );
    expect(
      () => document(
        sectors: [
          sector(scene: dense(5001)),
          sector(id: 'east', x: 8, scene: dense(5000)),
        ],
      ),
      throwsFormatException,
    );
  });

  test('rejects authored navigation entity bindings and gameplay layers', () {
    for (final navigation in [
      SpatialNavigationProfile(spawn: SpatialSpawn(x: 1, z: 1)),
      SpatialNavigationProfile(allowDiagonalMovement: true),
      SpatialNavigationProfile(
        blockedAreas: [SpatialBlockedArea(x: 0, z: 0, width: 1, depth: 1)],
      ),
      SpatialNavigationProfile(
        ramps: [
          SpatialRamp(
            id: 'ramp',
            x: 0,
            z: 0,
            width: 1,
            depth: 1,
            lowLevel: 0,
            highLevel: 1,
            direction: SpatialRampDirection.north,
            surfaceInstanceId: 'support',
          ),
        ],
      ),
    ]) {
      final instances = navigation.ramps.isEmpty
          ? <SpatialModelInstance>[]
          : [
              SpatialModelInstance(
                id: 'support',
                modelId: 'ramp',
                position: Model3dVector3.zero,
                blocksMovement: false,
              ),
            ];
      expect(
        () => sector(
          scene: MapSpatialScene(
            width: 4,
            depth: 4,
            navigation: navigation,
            instances: instances,
          ),
        ),
        throwsFormatException,
      );
    }
    expect(
      () => sector(
        scene: MapSpatialScene(
          width: 4,
          depth: 4,
          instances: [
            SpatialModelInstance(
              id: 'npc',
              modelId: 'npc',
              entityId: 'actor',
              position: Model3dVector3.zero,
            ),
          ],
        ),
      ),
      throwsFormatException,
    );
    for (final layer in <MapLayer>[
      const MapLayer.collision(id: 'collision', name: 'Collision'),
      const MapLayer.tile(id: 'tile', name: 'Tile'),
      const MapLayer.object(id: 'object', name: 'Object'),
      const MapLayer.smartTile(
        id: 'forest',
        name: 'Forest',
        presetId: 'tree',
        usage: SmartTileUsage.forestSurface,
        field: SmartTileField.cell(),
      ),
    ]) {
      expect(() => sector(layers: [layer]), throwsFormatException);
    }
  });

  test('rejects malformed native field grids and encounter semantics', () {
    final layer =
        MapLayer.smartTile(
              id: 'ground',
              name: 'Ground',
              presetId: 'grass',
              usage: SmartTileUsage.terrain,
              field: const SmartTileField.cell(),
            )
            as SmartTileLayer;
    expect(() => sector(layers: [layer]), throwsFormatException);
    expect(
      () => sector(
        layers: [
          layer.copyWith(
            field: SmartTileField.cell(semanticCells: List.filled(16, 1)),
          ),
        ],
      ),
      throwsFormatException,
    );
    final valid = layer.copyWith(
      field: SmartTileField.cell(semanticCells: List.filled(16, 0)),
    );
    expect(
      () => sector(
        layers: [
          valid.copyWith(
            encounterBehavior: const SmartTileEncounterBehavior(
              materialId: 'grass',
              encounter: EncounterZonePayload(),
            ),
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => sector(
        layers: [
          valid.copyWith(
            animationActivation: SmartTileAnimationActivation.onEnter,
          ),
        ],
      ),
      throwsFormatException,
    );
  });

  test(
    'bounds native Border geometry and counts native pattern references',
    () {
      final border = MapLayer.border(
        id: 'border',
        name: 'Border',
        content: BorderLayerContent(
          features: [
            BorderFeature(
              id: 'shore',
              name: 'Shore',
              blueprintId: 'shore',
              seed: BorderSignedInt64.zero,
              overrides: [],
              keepOutRegions: [],
              geometry: BorderRegionGeometry(
                width: 5,
                height: 4,
                cells: List.filled(20, true),
              ),
            ),
          ],
        ),
      );
      expect(() => sector(layers: [border]), throwsFormatException);
      final ground = MapLayer.smartTile(
        id: 'ground',
        name: 'Ground',
        presetId: 'grass',
        usage: SmartTileUsage.terrain,
        field: SmartTileField.cell(semanticCells: List.filled(16, 0)),
        patternStrokes: [
          const SmartTilePatternStroke(
            id: 'stroke',
            patternId: 'path-pattern',
            cells: [GridPos(x: 0, y: 0)],
          ),
        ],
      );
      expect(
        sector(layers: [ground]).resourceReferenceIds,
        contains('path-pattern'),
      );
    },
  );

  test('decoration priority is stable by persistent owner identity', () {
    final a = document();
    final b = MapExteriorDecoration(
      mapId: 'zzz',
      playableWidth: 8,
      playableDepth: 8,
    );
    expect(MapExteriorDecoration.compareVisualPriority(a, b), lessThan(0));
    expect(MapExteriorDecoration.compareVisualPriority(b, a), greaterThan(0));
    expect(MapExteriorDecoration.compareVisualPriority(a, a), 0);
  });

  test('bounds direct resource references across all sectors', () {
    MapSpatialScene models(int first, int count) => MapSpatialScene(
      width: 4,
      depth: 4,
      instances: List.generate(
        count,
        (i) => SpatialModelInstance(
          id: 'tree$i',
          modelId: 'model_${first + i}',
          position: Model3dVector3.zero,
        ),
      ),
    );
    final west = sector(scene: models(0, 600));
    expect(west.resourceReferenceIds, hasLength(600));
    expect(() => west.resourceReferenceIds.clear(), throwsUnsupportedError);
    expect(
      () => document(
        sectors: [
          west,
          sector(id: 'east', x: 8, scene: models(600, 425)),
        ],
      ),
      throwsFormatException,
    );
    expect(
      document(
        sectors: [
          west,
          sector(id: 'east', x: 8, scene: models(0, 600)),
        ],
      ).sectors,
      hasLength(2),
    );
  });

  test('rejects nested fields that native codecs would otherwise discard', () {
    final scene = sector().scene.toJson();
    final camera = Map<String, dynamic>.from(scene['camera'] as Map);
    expect(
      () => ExteriorDecorationSector.fromJson({
        ...sector().toJson(),
        'scene': {
          ...scene,
          'camera': {...camera, 'futureCameraMode': true},
        },
      }),
      throwsFormatException,
    );
    final navigation = Map<String, dynamic>.from(scene['navigation'] as Map);
    expect(
      () => ExteriorDecorationSector.fromJson({
        ...sector().toJson(),
        'scene': {
          ...scene,
          'navigation': {
            ...navigation,
            'spawn': {'x': 0.5, 'z': 0.5, 'actorId': 'npc'},
          },
        },
      }),
      throwsFormatException,
    );
  });
}
