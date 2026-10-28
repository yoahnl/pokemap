import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData _map({
  double spawnX = 2.5,
  double spawnZ = 4,
  List<SpatialBlockedArea> blocked = const [],
  List<MapEntity> entities = const [],
  List<int>? heights,
}) =>
    MapData(
      id: 'water-map',
      name: 'Water',
      size: const GridSize(width: 12, height: 8),
      spatialScene: MapSpatialScene(
        width: 12,
        depth: 8,
        heightLevels: heights ?? List.filled(96, 0),
        navigation: SpatialNavigationProfile(
          spawn: SpatialSpawn(x: spawnX, z: spawnZ),
          blockedAreas: blocked,
        ),
      ),
      entities: entities,
    );

bool _water(double x, double z) => x >= 4 && x < 8;

SpatialMovementController _player({
  MapData? map,
  MovementMode mode = MovementMode.walk,
  double speed = 4,
  bool waterEnabled = true,
}) =>
    SpatialMovementController.fromMap(
      map: map ?? _map(),
      models: const [],
      initialMovementMode: mode,
      surfSpeedCellsPerSecond: speed,
      waterPredicate: waterEnabled ? _water : null,
    );

void _move(SpatialMovementController player, int count,
    {int dx = 1, int dz = 0, bool run = false}) {
  player.setInput(x: dx, z: dz, run: run);
  for (var i = 0; i < count; i++) {
    player.update(.05);
  }
}

void main() {
  test('walking stops before water and reports a water bump', () {
    final player = _player();
    _move(player, 20);
    expect(player.x, lessThan(4));
    expect(player.bumpedCell?.x, 4);
    expect(player.movementMode, MovementMode.walk);
  });

  test('null water predicate preserves legacy spatial walking', () {
    final player = _player(waterEnabled: false);
    _move(player, 20);
    expect(player.x, greaterThan(4));
  });

  test('surfing enters water at configured speed without running', () {
    final player =
        _player(map: _map(spawnX: 3.5), mode: MovementMode.surf, speed: 5);
    _move(player, 4, run: true);
    expect(player.x, 4.5);
    expect(player.movementMode, MovementMode.surf);
    expect(player.running, isFalse);
    expect(player.isWaterAt(player.x, player.z), isTrue);
  });

  test('a successful step on land ends Surf and prevents reentry', () {
    final player = _player(map: _map(spawnX: 7.5), mode: MovementMode.surf);
    _move(player, 5);
    expect(player.x, greaterThanOrEqualTo(8));
    expect(player.movementMode, MovementMode.walk);
    _move(player, 10, dx: -1);
    expect(player.x, greaterThanOrEqualTo(8));
  });

  test('loading Surf on water validates with the restored movement mode', () {
    final player = _player(map: _map(spawnX: 5.5), mode: MovementMode.surf);
    expect(player.isPositionTraversable, isTrue);
    expect(player.movementMode, MovementMode.surf);
  });

  test('loading walking on water safely rejects the blocked spawn', () {
    expect(() => _player(map: _map(spawnX: 5.5)), throwsStateError);
  });

  test('Surf preserves authored blocked areas', () {
    final player = _player(
      map: _map(spawnX: 4.5, blocked: [
        SpatialBlockedArea(x: 6, z: 3, width: 1, depth: 2),
      ]),
      mode: MovementMode.surf,
    );
    _move(player, 20);
    expect(player.x, lessThan(6));
    expect(player.movementMode, MovementMode.surf);
  });

  test('Surf preserves terrain height collision', () {
    final player = _player(
      map: _map(spawnX: 4.5, heights: [
        for (var z = 0; z < 8; z++)
          for (var x = 0; x < 12; x++) x >= 6 ? 2 : 0,
      ]),
      mode: MovementMode.surf,
    );
    _move(player, 20);
    expect(player.x, lessThan(6));
  });

  test('player water policy does not alter NPC traversal', () {
    final player = _player();
    expect(player.canTraverseActor(3.5, 4, 4.5, 4), isTrue);
  });
  test('a walking ledge jump cannot bypass the Surf entry gate', () {
    final scene = MapSpatialScene(
      width: 12,
      depth: 8,
      navigation: SpatialNavigationProfile(
        spawn: SpatialSpawn(x: 3.5, z: 3.5),
        ledges: [
          SpatialLedge(
              id: 'drop', x: 3, z: 3, direction: SpatialRampDirection.east)
        ],
      ),
    );
    final player = SpatialMovementController(
        scene: scene, models: [], waterPredicate: _water);
    _move(player, 10);
    expect(player.x, lessThan(4));
    expect(player.isJumping, isFalse);
  });

  test('connected water traversal carries Surf and preserves return motion',
      () {
    final source = SpatialMovementController.fromMap(
      map: _map(spawnX: 10.5),
      models: [],
      initialMovementMode: MovementMode.surf,
      waterPredicate: (_, __) => true,
    );
    final target = SpatialMovementController.fromMap(
      map: _map(),
      models: [],
      validateSpawn: false,
      waterPredicate: (_, __) => true,
    );
    source.setConnectedNeighbors({
      MapConnectionDirection.east:
          SpatialMovementNeighbor(controller: target, offsetX: 12, offsetZ: 0),
    });
    source.setInput(x: 1, z: 0, run: true);
    for (var i = 0; i < 30 && source.connectionArrival == null; i++) {
      source.update(.05);
    }
    expect(source.connectionArrival, isNotNull);
    target.adoptConnectionMotion(source);
    expect(target.movementMode, MovementMode.surf);
    expect(target.isPositionTraversable, isTrue);
    expect(target.running, isFalse);
    final before = target.x;
    target.update(.05);
    expect(target.x, greaterThan(before));
  });

  test('Surf preserves NPC collision while crossing water', () {
    final player = _player(
      map: _map(spawnX: 4.5, spawnZ: 4.5, entities: [
        MapEntity(
          id: 'swimmer',
          kind: MapEntityKind.npc,
          pos: const GridPos(x: 6, y: 4),
          npc: const MapEntityNpcData(characterId: 'swimmer'),
        )
      ]),
      mode: MovementMode.surf,
    );
    _move(player, 20);
    expect(player.x, lessThan(6));
  });

  test('northward water blocking agrees with the persisted spatial anchor', () {
    final player = SpatialMovementController.fromMap(
      map: _map(spawnZ: 6.5),
      models: [],
      waterPredicate: (_, z) => z < 6,
    );
    _move(player, 10, dx: 0, dz: -1);
    expect(player.z, greaterThanOrEqualTo(6));
    expect(player.isWaterAt(player.x, player.z), isFalse);
  });
}
