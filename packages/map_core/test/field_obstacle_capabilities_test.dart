import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('persistent reset policy is limited to destructible obstacles', () {
    for (final kind in [FieldObstacleKind.strengthBoulder, FieldObstacleKind.iceBlock]) {
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
