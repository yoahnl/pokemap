import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'fishing_action_test.dart' as fixture;

MapData spatialMap({bool cliff = false}) => fixture.waterMap().copyWith(
      version: ProjectVersion.v9,
      spatialScene: MapSpatialScene(width: 8, depth: 8, heightLevels: [
        for (var z = 0; z < 8; z++)
          for (var x = 0; x < 8; x++) cliff && x >= 3 ? 2 : 0,
      ]),
    );

GameState spatialState() => fixture.state().copyWith(
      playerSpatialPosition: PlayerSpatialPosition(x: 2.75, z: 2.25),
    );

void main() {
  test(
      'half-unit lower water requires explicit fishing drop and keeps upper limit',
      () {
    final project = fixture.project(),
        item = fixture.rod(ProjectFishingRodKind.oldRod);
    for (final scenario in [
      (drop: .5, limit: .25, ready: false),
      (drop: .5, limit: .5, ready: true),
      (drop: .75, limit: .5, ready: false),
      (drop: -.5, limit: 4.0, ready: false),
    ]) {
      final source = spatialMap();
      final scene = source.spatialScene!;
      final map = source.copyWith(
          spatialScene: MapSpatialScene(
        width: scene.width,
        depth: scene.depth,
        heightLevels: [
          for (var z = 0; z < 8; z++)
            for (var x = 0; x < 8; x++)
              x >= 3 ? (4 - scenario.drop / .25).round() : 4
        ],
        levelHeight: .25,
        navigation: SpatialNavigationProfile.fromJson({
          ...scene.navigation.toJson(),
          'maximumFishingDropWorld': scenario.limit
        }),
      ));
      final state = spatialState();
      final evaluation = evaluateFishingAttempt(
          world: fixture.world(map, state),
          project: project,
          gameState: state,
          item: item);
      expect(evaluation.isReady, scenario.ready, reason: scenario.toString());
    }
  });
  for (final tileCollision in [false, true]) {
    test('native Surf water keeps imported walk blockers while allowing a half-unit cast tile=$tileCollision', () {
      final source = spatialMap();
      final navigation = source.spatialScene!.navigation.copyWith(maximumFishingDropWorld: .5,
        blockedAreas: [SpatialBlockedArea(x: 3, z: 2, width: 1, depth: 1)]);
      final map = source.copyWith(
        layers: [if (tileCollision) CollisionLayer(id: 'blocked-water', name: 'Blocked water', collisions: [for (var i = 0; i < 64; i++) i == 19])],
        spatialScene: MapSpatialScene(width: 8, depth: 8, levelHeight: .25,
          heightLevels: [for (var z = 0; z < 8; z++) for (var x = 0; x < 8; x++) x >= 3 ? 2 : 4], navigation: navigation));
      final state = spatialState().copyWith(playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.25));
      final project = fixture.project(), item = fixture.rod(ProjectFishingRodKind.oldRod);
      final movement = SpatialMovementController.fromMap(map: map, models: [], spatialArrival: state.playerSpatialPosition);
      expect(movement.canTraverseActor(3.5, 2.5, 3.5, 2.5), isFalse);
      final random = fixture.CountingRandom(1);
      final result = resolveFishingAttempt(ticket: fixture.ticket(map: map, current: state, manifest: project, item: item), world: fixture.world(map, state), project: project, gameState: state, item: item, currentStateRevision: 4, mapActivationId: 'activation-1', random: random, spatialMovement: movement);
      expect(result.reason, isNull);
      expect(result.encounterCheck?.triggered, isTrue);
      expect(random.doubleCalls, 1);
      expect(movement.canTraverseActor(3.5, 2.5, 3.5, 2.5), isFalse);
      expect(map.spatialScene!.navigation.blockedAreas, navigation.blockedAreas);
    });
  }

  test('fishing cast rechecks moving actors and model collision without RNG',
      () {
    final model = ProjectModel3dEntry(
        id: 'wall',
        name: 'Wall',
        sourceAssetId: 'wall',
        relativePath: 'assets/models3d/wall.glb',
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3(x: -.2, y: 0, z: -.2),
                max: Model3dVector3(x: .2, y: 2, z: .2)),
            meshCount: 1,
            triangleCount: 12));
    final actor = MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 5, y: 5),
        blocksMovement: true);
    final source = spatialMap();
    final state = spatialState().copyWith(playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.25));
    final map = source.copyWith(
        entities: [actor],
        layers: [CollisionLayer(id: 'water', name: 'Water', collisions: [for (var i = 0; i < 64; i++) i == 19])],
        spatialScene: source.spatialScene!.copyWith(navigation: source.spatialScene!.navigation.copyWith(blockedAreas: [SpatialBlockedArea(x: 3, z: 2, width: 1, depth: 1)]), instances: [
          SpatialModelInstance(
              id: 'wall-1',
              modelId: model.id,
              position: Model3dVector3(x: 3.25, y: 0, z: 2.25),
              blocksMovement: true),
        ]));
    final project = fixture.project().copyWith(models3d: [model]);
    final item = fixture.rod(ProjectFishingRodKind.oldRod);
    var blockingModel = false, blockingActor = false;
    final movement = SpatialMovementController.fromMap(
        map: map,
        models: [model],
        spatialArrival: state.playerSpatialPosition,
        modelStateProvider: (_) => SpatialModelRuntimeState(
            modelId: model.id,
            animationIndex: null,
            normalizedTime: 0,
            blocksMovement: blockingModel),
        actorStateProvider: (_) => SpatialActorRuntimeState(
            x: blockingActor ? 3.25 : 5.5,
            z: blockingActor ? 2.25 : 5.5,
            facing: EntityFacing.south));
    final ticket =
        fixture.ticket(map: map, current: state, manifest: project, item: item);
    FishingAttemptResult resolve(fixture.CountingRandom random) =>
        resolveFishingAttempt(
            ticket: ticket,
            world: fixture.world(map, state),
            project: project,
            gameState: state,
            item: item,
            currentStateRevision: 4,
            mapActivationId: 'activation-1',
            random: random,
            spatialMovement: movement);
    expect(
        evaluateFishingAttempt(
                world: fixture.world(map, state),
                project: project,
                gameState: state,
                item: item,
                spatialMovement: movement)
            .isReady,
        isTrue);
    for (final modelBlocked in [true, false]) {
      blockingModel = modelBlocked;
      blockingActor = !modelBlocked;
      final random = fixture.CountingRandom(1);
      expect(resolve(random).reason, FishingBlockReason.notWater);
      expect(random.doubleCalls + random.intCalls, 0);
    }
    blockingActor = false;
    expect(resolve(fixture.CountingRandom(1)).reason, isNull);
  });

  test(
      'configured drop still refuses barriers blocked regions nonwater and map exit',
      () {
    final source = spatialMap();
    final navigation =
        source.spatialScene!.navigation.copyWith(maximumFishingDropWorld: 4);
    final configured = source.copyWith(
        spatialScene: source.spatialScene!.copyWith(navigation: navigation));
    final ledge = SpatialLedge(
        id: 'bank', x: 2, z: 2, direction: SpatialRampDirection.east);
    final item = fixture.rod(ProjectFishingRodKind.oldRod),
        project = fixture.project();
    for (final entry in [
      (
        map: configured.copyWith(
            spatialScene: configured.spatialScene!
                .copyWith(navigation: navigation.copyWith(ledges: [ledge]))),
        state: spatialState()
      ),
      (
        map: configured.copyWith(
            spatialScene: configured.spatialScene!.copyWith(
                navigation: navigation.copyWith(blockedAreas: [
          SpatialBlockedArea(x: 2.875, z: 2, width: .375, depth: 1)
        ]))),
        state: spatialState()
      ),
      (map: configured.copyWith(gameplayZones: []), state: spatialState()),
      (
        map: configured,
        state: spatialState().copyWith(
            playerPosition: const GridPos(x: 7, y: 2),
            playerSpatialPosition: PlayerSpatialPosition(x: 7.75, z: 2.25))
      ),
    ]) {
      final random = fixture.CountingRandom(1);
      final result = resolveFishingAttempt(
          ticket: fixture.ticket(
              map: entry.map,
              current: entry.state,
              manifest: project,
              item: item),
          world: fixture.world(entry.map, entry.state),
          project: project,
          gameState: entry.state,
          item: item,
          currentStateRevision: 4,
          mapActivationId: 'activation-1',
          random: random);
      expect(result.reason, isNotNull);
      expect(random.doubleCalls + random.intCalls, 0);
    }
  });

  for (final kind in ProjectFishingRodKind.values) {
    test('3D $kind resolves front water with the existing encounter pipeline',
        () {
      final map = spatialMap(), state = spatialState();
      final project = fixture.project(), item = fixture.rod(kind);
      final random = fixture.CountingRandom(42);
      final result = resolveFishingAttempt(
        ticket: fixture.ticket(
            map: map, current: state, manifest: project, item: item),
        world: fixture.world(map, state),
        project: project,
        gameState: state,
        item: item,
        currentStateRevision: 4,
        mapActivationId: 'activation-1',
        random: random,
      );
      expect(result.reason, isNull);
      expect(result.encounterCheck?.triggered, isTrue);
      expect(result.encounterCheck?.encounter?.tableId, kind.name);
      expect(result.encounterCheck?.encounter?.playerPos, state.playerPosition);
      expect(random.doubleCalls, 1);
      expect(
          state.playerSpatialPosition, PlayerSpatialPosition(x: 2.75, z: 2.25));
      expect(state.bag, fixture.state().bag);
    });
  }

  test(
      '3D requires coherent continuous position and refuses a cliff before RNG',
      () {
    final project = fixture.project(),
        item = fixture.rod(ProjectFishingRodKind.oldRod);
    for (final entry in [
      (
        map: spatialMap(),
        state: spatialState().copyWith(playerSpatialPosition: null)
      ),
      (
        map: spatialMap(),
        state: spatialState().copyWith(
            playerSpatialPosition: PlayerSpatialPosition(x: 1.9, z: 2.25))
      ),
      (
        map: spatialMap(),
        state: spatialState().copyWith(
            playerSpatialPosition: PlayerSpatialPosition(x: 2.8, z: 2.25))
      ),
      (map: spatialMap(cliff: true), state: spatialState()),
      (
        map: spatialMap(),
        state: spatialState().copyWith(playerFacing: EntityFacing.west)
      ),
    ]) {
      final random = fixture.CountingRandom(1);
      final result = resolveFishingAttempt(
        ticket: fixture.ticket(
            map: entry.map,
            current: entry.state,
            manifest: project,
            item: item),
        world: fixture.world(entry.map, entry.state),
        project: project,
        gameState: entry.state,
        item: item,
        currentStateRevision: 4,
        mapActivationId: 'activation-1',
        random: random,
      );
      expect(result.reason, isNotNull);
      expect(random.doubleCalls + random.intCalls, 0);
    }
  });

  test(
      '3D movement or a replaced activation invalidates a reserved fishing ticket',
      () {
    final map = spatialMap(), state = spatialState();
    final project = fixture.project(),
        item = fixture.rod(ProjectFishingRodKind.oldRod);
    final ticket =
        fixture.ticket(map: map, current: state, manifest: project, item: item);
    final moved = state.copyWith(
        playerSpatialPosition: PlayerSpatialPosition(x: 2.8, z: 2.25));
    final random = fixture.CountingRandom(1);
    final result = resolveFishingAttempt(
        ticket: ticket,
        world: fixture.world(map, moved),
        project: project,
        gameState: moved,
        item: item,
        currentStateRevision: 4,
        mapActivationId: 'activation-1',
        random: random);
    expect(result.reason, FishingBlockReason.staleAttempt);
    expect(random.doubleCalls + random.intCalls, 0);
  });
}
