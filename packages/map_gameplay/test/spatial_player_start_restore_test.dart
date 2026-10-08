import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData spatialMap({
  SpatialNavigationProfile? navigation,
  List<MapEntity> entities = const [],
  String? defaultSpawnId,
  Iterable<int>? levels,
}) =>
    MapData(
      id: 'spatial-start',
      name: 'Spatial start',
      size: const GridSize(width: 8, height: 8),
      mapMetadata: MapMetadata(defaultSpawnId: defaultSpawnId),
      entities: entities,
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        heightLevels: levels,
        navigation: navigation ??
            SpatialNavigationProfile(spawn: SpatialSpawn(x: 2.8125, z: 4.4375)),
      ),
    );

const authoredSpawns = [
  MapEntity(
    id: 'default',
    kind: MapEntityKind.spawn,
    pos: GridPos(x: 1, y: 2),
    spawn: MapEntitySpawnData(
      spawnKey: 'default',
      role: EntitySpawnRole.playerStart,
      facing: EntityFacing.west,
    ),
  ),
  MapEntity(
    id: 'preferred',
    kind: MapEntityKind.spawn,
    pos: GridPos(x: 5, y: 6),
    spawn: MapEntitySpawnData(
      spawnKey: 'preferred',
      role: EntitySpawnRole.playerStart,
      facing: EntityFacing.east,
    ),
  ),
];

ProjectManifest spatialProject({String? startSpawnId}) => ProjectManifest(
      name: 'Spatial game',
      version: ProjectVersion.v9,
      tilesets: const [],
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
        tileWidth: 32,
        tileHeight: 24,
      ),
      maps: const [
        ProjectMapEntry(
          id: 'spatial-start',
          name: 'Spatial start',
          relativePath: 'maps/start.json',
        ),
      ],
      newGame: ProjectNewGameConfig(
        enabled: true,
        startMapId: 'spatial-start',
        startSpawnId: startSpawnId,
      ),
    );

void main() {
  test('restores the exact feet anchor on a ramp through canonical save JSON',
      () {
    final map = spatialMap(
      levels: [
        for (var z = 0; z < 8; z++)
          for (var x = 0; x < 8; x++) z < 4 ? 1 : 0,
      ],
      navigation: SpatialNavigationProfile(
        spawn: SpatialSpawn(x: 3.5, z: 6.5),
        ramps: [
          SpatialRamp(
            id: 'ramp',
            x: 2,
            z: 4,
            width: 3,
            depth: 1,
            lowLevel: 0,
            highLevel: 1,
            direction: SpatialRampDirection.north,
          ),
        ],
      ),
    );
    final exact = PlayerSpatialPosition(x: 3.3125, z: 4.5625);
    final state = GameState(
      saveId: 'spatial-save',
      currentMapId: map.id,
      playerPosition: const GridPos(x: 3, y: 4),
      playerSpatialPosition: exact,
      playerFacing: EntityFacing.north,
    );
    final saved = gameStateFromStrictSaveJson(strictGameStateSaveJson(state));
    final controller = SpatialMovementController.fromMap(
      map: map,
      models: [],
      spatialArrival: saved.playerSpatialPosition,
      facing: saved.playerFacing,
    );
    expect(controller.spatialPosition, exact);
    expect(controller.facing, EntityFacing.north);
    expect(controller.y, map.spatialScene!.worldHeightAt(exact.x, exact.z));
    expect(controller.y, inExclusiveRange(0, 1));
    controller.update(.05);
    expect(controller.spatialPosition, exact);
  });

  test('grid and continuous arrivals are mutually exclusive', () {
    expect(
      () => SpatialMovementController.fromMap(
        map: spatialMap(),
        models: [],
        arrival: const GridPos(x: 2, y: 4),
        spatialArrival: PlayerSpatialPosition(x: 2.5, z: 4.5),
      ),
      throwsArgumentError,
    );
  });

  for (final position in [
    PlayerSpatialPosition(x: 8, z: 4),
    PlayerSpatialPosition(x: 2, z: 8),
    PlayerSpatialPosition(x: 2.81, z: 4.4375),
    PlayerSpatialPosition(x: 2.8125, z: 4.44),
  ]) {
    test('rejects an outside or unrepresentable arrival ${position.toJson()}',
        () {
      expect(
        () => SpatialMovementController.fromMap(
          map: spatialMap(),
          models: [],
          spatialArrival: position,
        ),
        throwsStateError,
      );
    });
  }

  test('rejects an exact arrival whose footprint crosses a cliff', () {
    final map = spatialMap(levels: [
      for (var z = 0; z < 8; z++)
        for (var x = 0; x < 8; x++) x >= 3 ? 1 : 0,
    ]);
    expect(
      () => SpatialMovementController.fromMap(
        map: map,
        models: [],
        spatialArrival: PlayerSpatialPosition(x: 2.8125, z: 4.5),
      ),
      throwsStateError,
    );
  });

  test('rejects an arrival in authored navigation obstacles', () {
    final map = spatialMap(
      navigation: SpatialNavigationProfile(
        spawn: SpatialSpawn(x: 5.5, z: 5.5),
        blockedAreas: [SpatialBlockedArea(x: 2, z: 4, width: 1, depth: 1)],
      ),
    );
    expect(
      () => SpatialMovementController.fromMap(
        map: map,
        models: [],
        spatialArrival: PlayerSpatialPosition(x: 2.5, z: 4.5),
      ),
      throwsStateError,
    );
  });

  test(
      'new game uses the native continuous spawn with non-square project tiles',
      () {
    final state = createNewGameStateFromProject(
      project: spatialProject(),
      startMap: spatialMap(),
      tileWidthPx: 32,
      tileHeightPx: 24,
    );
    expect(state.playerSpatialPosition,
        PlayerSpatialPosition(x: 2.8125, z: 4.4375));
    expect(state.playerPosition, const GridPos(x: 2, y: 4));
    expect(state.playerFacing, EntityFacing.south);
    final moved = SpatialMovementController.fromMap(
      map: spatialMap(),
      models: [],
      spatialArrival: state.playerSpatialPosition,
    );
    expect(moved.spatialPosition, state.playerSpatialPosition);
  });

  for (final preferred in [false, true]) {
    test('new game respects ${preferred ? 'configured' : 'default'} spawn', () {
      final map = spatialMap(
        entities: authoredSpawns,
        defaultSpawnId: 'default',
      );
      final state = createNewGameStateFromProject(
        project: spatialProject(startSpawnId: preferred ? 'preferred' : null),
        startMap: map,
        tileWidthPx: 32,
        tileHeightPx: 24,
      );
      expect(state.playerPosition,
          preferred ? const GridPos(x: 5, y: 6) : const GridPos(x: 1, y: 2));
      expect(
        state.playerSpatialPosition,
        preferred
            ? PlayerSpatialPosition(x: 5.5, z: 6.5)
            : PlayerSpatialPosition(x: 1.5, z: 2.5),
      );
      expect(state.playerFacing,
          preferred ? EntityFacing.east : EntityFacing.west);
    });
  }

  test('role spawn precedes native navigation and missing explicit spawn fails',
      () {
    final map = spatialMap(entities: authoredSpawns);
    final state = createNewGameStateFromProject(
      project: spatialProject(),
      startMap: map,
    );
    expect(state.playerSpatialPosition, PlayerSpatialPosition(x: 1.5, z: 2.5));
    expect(
      () => createNewGameStateFromProject(
        project: spatialProject(startSpawnId: 'missing'),
        startMap: map,
      ),
      throwsA(isA<GameplaySpawnResolutionException>()),
    );
  });

  test('teleport clears continuous coordinates of the previous map', () {
    final state = GameState(
      saveId: 'warp-save',
      currentMapId: 'source',
      playerPosition: const GridPos(x: 2, y: 4),
      playerSpatialPosition: PlayerSpatialPosition(x: 2.8125, z: 4.4375),
    );
    final warped = const GameStateMutations().warpPlayer(state, 'target', 3, 5);
    expect(warped.playerSpatialPosition, isNull);
    expect(warped.playerPosition, const GridPos(x: 3, y: 5));
    expect(() => strictGameStateSaveJson(warped), returnsNormally);
  });

  test('defeat recovery clears continuous coordinates before host relocation',
      () {
    final state = GameState(
      saveId: 'defeat-save',
      currentMapId: 'source',
      playerPosition: const GridPos(x: 2, y: 4),
      playerSpatialPosition: PlayerSpatialPosition(x: 2.8125, z: 4.4375),
      party: const PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'bulbasaur',
          natureId: 'hardy',
          abilityId: 'overgrow',
          currentHp: 0,
        ),
      ]),
    );
    final result = applyPlayerDefeatRecovery(
      state: state,
      fallbackPoint: const PlayerRecoveryPoint(
        mapId: 'center',
        position: GridPos(x: 3, y: 5),
        facing: EntityFacing.south,
      ),
      maxHpByPartyIndex: const {0: 20},
    );
    expect(result.state.playerSpatialPosition, isNull);
    expect(result.state.currentMapId, 'center');
    expect(() => strictGameStateSaveJson(result.state), returnsNormally);
  });
}
