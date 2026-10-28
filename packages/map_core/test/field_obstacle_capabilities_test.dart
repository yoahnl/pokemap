import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('strength and push animation wires round trip', () {
    for (final wire in ['strength', 'push']) {
      final animation = CharacterAnimation.fromJson({'state': wire, 'direction': 'south'});
      expect(animation.toJson()['state'], wire);
    }
  });

  test('persistent reset policy supports Strength and rejects Ice', () {
    expect(MapEntityFieldObstacleData.fromJson({'kind': 'strengthBoulder', 'resetPolicy': 'persistent'}).kind, FieldObstacleKind.strengthBoulder);
    for (final kind in [FieldObstacleKind.iceBlock]) {
      expect(() => MapEntityFieldObstacleData.fromJson({'kind': kind.name, 'resetPolicy': 'persistent'}), throwsFormatException);
    }
  });
  const project = ProjectManifest(
    name: 'Field actions',
    maps: [],
    tilesets: [],
  );
  final legacy = MapData(
    id: 'route',
    name: 'Route',
    size: const GridSize(width: 4, height: 4),
    entities: [
      const MapEntity(
        id: 'tree',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 1),
        fieldObstacle: MapEntityFieldObstacleData(),
      ),
    ],
  );

  test('extended obstacle capability isolates Strength and native push states', () {
    expect(FieldObstacleCapabilities.extendedCapabilityId, 'gameplay.field-obstacles@2');
    for (final kind in FieldObstacleKind.values) {
      for (final spatial in [false, true]) {
        for (final persistent in [false, true]) {
          if (kind == FieldObstacleKind.iceBlock && persistent) continue;
          final map = legacy.copyWith(spatialScene: spatial ? MapSpatialScene(width: 4, depth: 4) : null,
            entities: [legacy.entities.single.copyWith(fieldObstacle: MapEntityFieldObstacleData(kind: kind,
              resetPolicy: persistent ? FieldObstacleResetPolicy.persistent : FieldObstacleResetPolicy.mapInstance))]);
          expect(FieldObstacleCapabilities.requiresExtendedCapability(project, maps: [map]),
            kind == FieldObstacleKind.strengthBoulder && (spatial || persistent));
          expect(FieldObstacleCapabilities.requiresCapability(project, maps: [map]),
            ![FieldObstacleKind.strengthBoulder, FieldObstacleKind.iceBlock].contains(kind) && (spatial || persistent));
        }
      }
    }
    for (final state in [CharacterAnimationState.strength, CharacterAnimationState.push]) {
      final current = project.copyWith(characters: [ProjectCharacterEntry(id: 'hero', name: 'Hero', tilesetId: 'hero',
        animations: [CharacterAnimation(state: state, direction: EntityFacing.south)])]);
      expect(FieldObstacleCapabilities.requiresExtendedCapability(current, maps: []), isTrue);
      expect(FieldObstacleCapabilities.requiresCapability(current, maps: []), isFalse);
    }
  });

  test('spatial Strength accepts static bindings and rejects ice and lifts', () {
    final instance = SpatialModelInstance(id: 'boulder', modelId: 'rock', entityId: 'tree', blocksMovement: true,
      position: Model3dVector3(x: 1, y: 0, z: 1));
    final entity = legacy.entities.single.copyWith(fieldObstacle: const MapEntityFieldObstacleData(kind: FieldObstacleKind.strengthBoulder));
    final map = legacy.copyWith(entities: [entity], spatialScene: MapSpatialScene(width: 4, depth: 4, instances: [instance]));
    expect(isValidSpatialFieldObstacle(map, entity), isTrue);
    expect(isValidSpatialFieldObstacle(map, entity.copyWith(fieldObstacle: const MapEntityFieldObstacleData(kind: FieldObstacleKind.iceBlock))), isFalse);
    expect(isValidSpatialFieldObstacle(map.copyWith(spatialScene: map.spatialScene!.copyWith(lifts: [SpatialLiftDefinition(id: 'lift', name: 'Lift', instanceId: instance.id, x: 1, z: 1, width: 1, depth: 1, lowerHeight: 0, upperHeight: 1, durationMs: 1000)])), entity), isFalse);
    expect(isValidSpatialFieldObstacle(map.copyWith(spatialScene: map.spatialScene!.copyWith(instances: [instance.copyWith(animationIndex: 0)])), entity), isFalse);
  });
  test('legacy 2D instanced obstacles do not gain a capability', () {
    expect(
      FieldObstacleCapabilities.requiresCapability(project, maps: [legacy]),
      isFalse,
    );
    expect(
      FieldObstacleCapabilities.requiresCapability(
        project,
        maps: [
          legacy.copyWith(spatialScene: MapSpatialScene(width: 4, depth: 4)),
        ],
      ),
      isTrue,
    );
    expect(
      FieldObstacleCapabilities.requiresCapability(
        project,
        maps: [
          legacy.copyWith(
            entities: [
              legacy.entities.single.copyWith(
                fieldObstacle: const MapEntityFieldObstacleData(
                  resetPolicy: FieldObstacleResetPolicy.persistent,
                ),
              ),
            ],
          ),
        ],
      ),
      isTrue,
    );
  });
  for (final (state, wire) in [
    (CharacterAnimationState.cut, 'cut'),
    (CharacterAnimationState.rockSmash, 'rock_smash'),
  ]) {
    test('$wire native animation requires capability and round trips', () {
      final animation = CharacterAnimation(
        state: state,
        direction: EntityFacing.south,
      );
      expect(animation.toJson()['state'], wire);
      expect(CharacterAnimation.fromJson(animation.toJson()), animation);
      final current = project.copyWith(
        characters: [
          ProjectCharacterEntry(
            id: 'hero',
            name: 'Hero',
            tilesetId: 'hero-sheet',
            animations: [animation],
          ),
        ],
      );
      expect(
        FieldObstacleCapabilities.requiresCapability(current, maps: []),
        isTrue,
      );
    });
  }
  test('reset policy retains exact old wire and validates new wire', () {
    const legacy = MapEntityFieldObstacleData();
    expect(legacy.toJson(), {'kind': 'cutTree', 'resetPolicy': 'mapInstance'});
    expect(MapEntityFieldObstacleData.fromJson(legacy.toJson()), legacy);
    const persistent = MapEntityFieldObstacleData(
      resetPolicy: FieldObstacleResetPolicy.persistent,
    );
    expect(
      MapEntityFieldObstacleData.fromJson(persistent.toJson()),
      persistent,
    );
    expect(
      () => MapEntityFieldObstacleData.fromJson({
        'kind': 'cutTree',
        'resetPolicy': 'future',
      }),
      throwsFormatException,
    );
  });
  test(
    'persistent schema rejects malformed data and preserves old schema wire',
    () {
      const old = MapInstanceWorldState.empty();
      expect(
        MapInstanceWorldState.fromJson(old.toJson()).toJson(),
        old.toJson(),
      );
      for (final raw in [
        <String, dynamic>{
          'route': ['tree', 'tree'],
        },
        <String, dynamic>{
          'route': [2],
        },
        <String, dynamic>{
          ' route': ['tree'],
        },
        <String, dynamic>{
          'route': [' tree'],
        },
      ]) {
        expect(
          () => MapInstanceWorldState.fromJson({
            'schemaVersion': 7,
            'instancesByMapId': {},
            'persistentClearedObstacles': raw,
          }),
          throwsFormatException,
        );
      }
      expect(
        () => MapInstanceWorldState.fromJson({
          ...old.toJson(),
          'persistentClearedObstacles': {},
        }),
        throwsFormatException,
      );
      expect(
        () => MapInstanceWorldState.fromJson({
          ...old.toJson(),
          'schemaVersion': 8,
        }),
        throwsFormatException,
      );
    },
  );
}
