import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'spatial_movement_controller_test.dart' show plateau;

void main() {
  group('spatial occupied target interaction', () {
    const guide = MapEntity(
      id: 'guide', kind: MapEntityKind.npc, pos: GridPos(x: 4, y: 3),
      npc: MapEntityNpcData(characterId: 'actor'),
    );
    const hidden = MapEntity(
      id: 'buried-item', kind: MapEntityKind.item, pos: GridPos(x: 4, y: 3),
      blocksMovement: false,
      item: MapEntityItemData(gameItemId: 'resource', visibility: MapEntityItemVisibility.hidden),
    );
    MapSpatialScene field({bool blockedTarget = true, bool barrier = false,
        bool cliff = false, bool north = false}) => MapSpatialScene(
      width: 10, depth: 10, levelHeight: .5,
      heightLevels: [for (var i = 0; i < 100; i++) cliff && i == 34 ? 8 : 4],
      navigation: SpatialNavigationProfile(blockedAreas: [
        if (blockedTarget) SpatialBlockedArea(x: 4, z: 3, width: 2, depth: 1),
        if (barrier && north) SpatialBlockedArea(x: 4, z: 2.9375, width: 1, depth: .0625),
        if (barrier && !north) SpatialBlockedArea(x: 3.9375, z: 3, width: .0625, depth: 1),
      ]),
    );
    MapEntity? target(Iterable<MapEntity> entities, MapSpatialScene scene, {bool north = false}) =>
        findSpatialEntityInteraction(scene: scene, entities: entities,
            x: north ? 4.4375 : 3.5625, z: north ? 2.5625 : 3.4375,
            facing: north ? EntityFacing.south : EntityFacing.east);
    for (final north in [false, true]) {
      final side = north ? 'north' : 'west';
      test('NPC on a blocked target cell remains reachable from $side', () {
        final scene = field();
        expect(scene.worldHeightAt(4.5, 3.5), 2);
        expect(target([guide], scene, north: north)?.id, guide.id);
      });
      test('an intermediate navigation barrier remains opaque from $side', () {
        expect(target([guide], field(barrier: true, north: north), north: north), isNull);
      });
      test('a target cell exemption never bypasses a cliff from $side', () {
        expect(target([guide], field(cliff: true), north: north), isNull);
      });
    }
    for (final itemFirst in [false, true]) {
      test('a visible NPC takes priority over a co-located hidden item with itemFirst=$itemFirst', () {
        expect(target(itemFirst ? [hidden, guide] : [guide, hidden],
            field(blockedTarget: false))?.id, guide.id);
      });
    }
    test('hidden pickup on a blocked cell remains available after its co-located NPC disappears', () {
      final found = target([hidden], field());
      expect(found?.id, hidden.id);
      final picked = executeSpatialItemPickup(gameState: const GameState(saveId: 'save'),
          mapId: 'field', entity: found!);
      expect(picked.outcome, SpatialItemPickupOutcome.received);
      expect(picked.gameState.bag.entries.single.itemId, 'resource');
      expect(picked.gameState.bag.entries.single.quantity, 1);
      expect(spatialItemIsCollected(gameState: picked.gameState, mapId: 'field', entity: hidden), isTrue);
    });
  });

  test('runtime geometry offsets compose once after pivot rotation and scale', () {
    final model = ProjectModel3dEntry(id: 'rock', name: 'Rock', sourceAssetId: 'rock',
      relativePath: 'assets/models3d/rock.glb', scale: 2,
      pivot: Model3dVector3(x: .25, y: .5, z: -.25),
      collisionBounds: Model3dBounds(min: Model3dVector3(x: -.1, y: 0, z: -.2), max: Model3dVector3(x: .2, y: .5, z: .3)),
      inspection: Model3dInspection(meshCount: 1, triangleCount: 1,
        bounds: Model3dBounds(min: Model3dVector3(x: -.5, y: 0, z: -.5), max: Model3dVector3(x: .5, y: 1, z: .5))));
    final instance = SpatialModelInstance(id: 'rock', modelId: model.id, position: Model3dVector3(x: 4, y: 1, z: 5),
      rotationDegrees: 37, scale: 1.5);
    final pose = SpatialModelRuntimeState(modelId: model.id, animationIndex: null, normalizedTime: 0, blocksMovement: true,
      translationX: 2, translationY: 3, translationZ: -1);
    for (final collision in [false, true]) {
      final original = spatialModelWorldGeometry(instance, model, useCollisionBounds: collision);
      final shifted = spatialModelWorldGeometry(instance, model, useCollisionBounds: collision, runtimeState: pose);
      for (var i = 0; i < original.polygon.length; i++) {
        expect(shifted.polygon[i].x, closeTo(original.polygon[i].x + 2, .000001));
        expect(shifted.polygon[i].z, closeTo(original.polygon[i].z - 1, .000001));
      }
      expect(shifted.minY, original.minY + 3);
      expect(shifted.maxY, original.maxY + 3);
      expect(shifted.cos, original.cos);
      expect(shifted.sin, original.sin);
    }
  });

  test('model interaction follows translated target and translated occluder geometry', () {
    final model = ProjectModel3dEntry(id: 'rock', name: 'Rock', sourceAssetId: 'rock',
      relativePath: 'assets/models3d/rock.glb', inspection: Model3dInspection(meshCount: 1, triangleCount: 1,
        bounds: Model3dBounds(min: Model3dVector3(x: -.2, y: 0, z: -.2), max: Model3dVector3(x: .2, y: 1, z: .2))));
    final target = SpatialModelInstance(id: 'target', modelId: model.id,
      position: Model3dVector3(x: 6.5, y: 0, z: 2.5));
    final blocker = SpatialModelInstance(id: 'blocker', modelId: model.id,
      position: Model3dVector3(x: 4.5, y: 0, z: 4.5), blocksMovement: true);
    final pose = SpatialModelRuntimeState(modelId: model.id, animationIndex: null, normalizedTime: 0,
      blocksMovement: true, translationX: -3);
    final scene = MapSpatialScene(width: 10, depth: 10, instances: [target, blocker]);
    SpatialModelInstance? find(Map<String, SpatialModelRuntimeState> poses) => findSpatialModelInteraction(
      scene: scene, models: [model], instances: [target], x: 2.5, z: 2.5, facing: EntityFacing.east,
      modelStateProvider: (id) => poses[id]);
    expect(find({}), isNull);
    expect(find({'target': pose}), target);
    expect(find({'target': pose.copyWith(translationY: 3)}), isNull);
    expect(find({'target': pose, 'blocker': pose.copyWith(translationX: -1.5, translationZ: -2)}), isNull);
    expect(find({'target': pose, 'blocker': pose.copyWith(translationX: -1.5, translationZ: -2, translationY: 3)}), target);
  });

  SpatialMovementController recoveryFixture({List<SpatialBlockedArea> blocked = const [],
      List<MapEntity> others = const [], MapEntity? owner,
      List<ProjectModel3dEntry> models = const [], List<SpatialModelInstance> instances = const [],
      PlayerSpatialPosition? arrival}) {
    final npc = owner ?? MapEntity(id: 'contact', kind: MapEntityKind.npc,
        pos: const GridPos(x: 4, y: 4), properties: const {'collision.width': '1', 'collision.height': '1'},
        npc: const MapEntityNpcData(characterId: 'actor'));
    return SpatialMovementController.fromMap(map: MapData(id: 'map', name: 'Map',
        size: const GridSize(width: 10, height: 10), entities: [npc, ...others],
        spatialScene: MapSpatialScene(width: 10, depth: 10, instances: instances,
            navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 1.5, z: 1.5), blockedAreas: blocked))),
        models: models, spatialArrival: arrival ?? PlayerSpatialPosition(x: 4.5, z: 5), validateSpawn: false);
  }
  test('NPC footprint recovery reaches the enclosed one cell northern exit', () {
    final movement = recoveryFixture(blocked: [
      SpatialBlockedArea(x: 0, z: 5.125, width: 10, depth: 1),
      SpatialBlockedArea(x: 3.9375, z: 3, width: .0625, depth: 2.125),
      SpatialBlockedArea(x: 5, z: 3, width: .0625, depth: 2.125),
    ]);
    expect(movement.findNpcOverlapRecovery(), PlayerSpatialPosition(x: 4.5, z: 3.9375));
  });
  test('NPC footprint recovery reaches a four cell actor lateral exit', () {
    final movement = recoveryFixture(owner: MapEntity(id: 'large', kind: MapEntityKind.npc,
        pos: const GridPos(x: 3, y: 3), size: const GridSize(width: 4, height: 4),
        properties: const {'collision.width': '4', 'collision.height': '4'},
        npc: const MapEntityNpcData(characterId: 'actor')),
        arrival: PlayerSpatialPosition(x: 5, z: 7),
        blocked: [SpatialBlockedArea(x: 0, z: 7.125, width: 10, depth: 1)]);
    expect(movement.findNpcOverlapRecovery(), PlayerSpatialPosition(x: 2.625, z: 7));
  });
  test('NPC arrival recovery finds the nearest free pixel without mutating movement', () {
    final movement = recoveryFixture();
    expect(movement.findNpcOverlapRecovery(), PlayerSpatialPosition(x: 4.5, z: 5.4375));
    expect(movement.findNpcOverlapRecovery(), PlayerSpatialPosition(x: 4.5, z: 5.4375));
    expect(movement.spatialPosition, PlayerSpatialPosition(x: 4.5, z: 5));
    expect(movement.isPositionTraversable, isFalse);
  });
  test('NPC arrival recovery follows current poses and ignores absent actors', () {
    final movement = recoveryFixture();
    movement.setRuntimeStateProviders(actorStateProvider: (_) =>
        SpatialActorRuntimeState(x: 4.5, z: 5.5, facing: EntityFacing.south));
    expect(movement.findNpcOverlapRecovery(), PlayerSpatialPosition(x: 4.5, z: 4.9375));
    movement.setEntityPresencePredicate((_) => false);
    expect(movement.isPositionTraversable, isTrue);
    expect(movement.findNpcOverlapRecovery(), isNull);
  });
  test('NPC arrival recovery never ignores a model collision', () {
    final model = ProjectModel3dEntry(id: 'block', name: 'Block', sourceAssetId: 'block',
        relativePath: 'assets/models3d/block.glb', inspection: Model3dInspection(meshCount: 1, triangleCount: 1,
            bounds: Model3dBounds(min: Model3dVector3(x: -.1, y: 0, z: -.1),
                max: Model3dVector3(x: .1, y: 1, z: .1))));
    final movement = recoveryFixture(models: [model], instances: [SpatialModelInstance(
        id: 'block', modelId: model.id, position: Model3dVector3(x: 4.5, y: 0, z: 5), blocksMovement: true)]);
    expect(movement.findNpcOverlapRecovery(), isNull);
  });
  test('NPC arrival recovery refuses a static overlap', () {
    final movement = recoveryFixture(blocked: [SpatialBlockedArea(x: 4, z: 4, width: 1, depth: 2)]);
    expect(movement.findNpcOverlapRecovery(), isNull);
  });
  test('NPC arrival recovery cannot cross a static wall to the nearest endpoint', () {
    final movement = recoveryFixture(blocked: [SpatialBlockedArea(x: 4, z: 5.0625, width: 1, depth: .0625)]);
    expect(movement.findNpcOverlapRecovery(), PlayerSpatialPosition(x: 3.625, z: 5));
  });
  test('NPC arrival recovery keeps other NPCs solid around an enclosed actor', () {
    final movement = recoveryFixture(blocked: [SpatialBlockedArea(x: 4, z: 5.0625, width: 1, depth: .0625),
          SpatialBlockedArea(x: 4, z: 3.9375, width: 1, depth: .0625)],
        others: [for (final x in [3, 5]) MapEntity(id: 'side-$x', kind: MapEntityKind.npc,
          pos: GridPos(x: x, y: 4), size: const GridSize(width: 1, height: 2),
          properties: const {'collision.width': '1', 'collision.height': '2'},
          npc: const MapEntityNpcData(characterId: 'actor'))]);
    expect(movement.findNpcOverlapRecovery(), isNull);
  });
  test('NPC arrival recovery follows the actual large footprint bounds', () {
    final movement = recoveryFixture(owner: MapEntity(id: 'large', kind: MapEntityKind.npc,
        pos: const GridPos(x: 2, y: 2), size: const GridSize(width: 6, height: 6),
        properties: const {'collision.width': '6', 'collision.height': '6'},
        npc: const MapEntityNpcData(characterId: 'actor')));
    expect(movement.findNpcOverlapRecovery(), PlayerSpatialPosition(x: 1.625, z: 5));
  });

  test('explicit NPC collision retains its authored cell and runtime offset', () {
    final npc = MapEntity(id: 'explicit', kind: MapEntityKind.npc,
        pos: const GridPos(x: 4, y: 4),
        properties: const {'collision.width': '1', 'collision.height': '1'},
        npc: const MapEntityNpcData(characterId: 'actor'));
    final movement = SpatialMovementController(
        scene: MapSpatialScene(width: 10, depth: 10,
            navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 1.5, z: 1.5))),
        models: [], entities: [npc]);
    expect(movement.canTraverseActor(2.5, 3.5, 6.5, 3.5), isTrue);
    expect(movement.canTraverseActor(2.5, 5, 6.5, 5), isFalse);
    movement.setRuntimeStateProviders(actorStateProvider: (_) =>
        SpatialActorRuntimeState(x: 5.5, z: 6.5, facing: EntityFacing.north));
    expect(movement.canTraverseActor(3.5, 5.5, 7.5, 5.5), isTrue);
    expect(movement.canTraverseActor(3.5, 7, 7.5, 7), isFalse);
  });
  test('default NPC contact shares the actor inclusive feet anchor', () {
    final npc = MapEntity(id: 'contact', kind: MapEntityKind.npc,
        pos: const GridPos(x: 4, y: 4),
        npc: const MapEntityNpcData(characterId: 'actor'));
    final movement = SpatialMovementController(
        scene: MapSpatialScene(width: 10, depth: 10,
            navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 1.5, z: 1.5))),
        models: [], entities: [npc]);
    expect(movement.canTraverseActor(4.5, 3, 4.5, 4), isTrue);
    expect(movement.canTraverseActor(4.5, 3, 4.5, 4.0625), isFalse);
    expect(movement.canTraverseActor(4.5, 6, 4.5, 5), isTrue);
    expect(movement.canTraverseActor(4.5, 6, 4.5, 4.9375), isFalse);
    expect(movement.canTraverseActor(3, 4.5, 3.75, 4.5), isTrue);
    expect(movement.canTraverseActor(3, 4.5, 3.8125, 4.5), isFalse);
    expect(movement.canTraverseActor(6, 4.5, 5.25, 4.5), isTrue);
    expect(movement.canTraverseActor(6, 4.5, 5.1875, 4.5), isFalse);
  });

  final npc = MapEntity(
      id: 'npc',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 3, y: 2),
      npc: MapEntityNpcData(characterId: 'hero'));
  final scene = MapSpatialScene(
      width: 8,
      depth: 8,
      heightLevels: List.filled(64, 0),
      navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 3.5, z: 4)));
  test('static NPC collision stops a running hero and release clears sprint',
      () {
    final player =
        SpatialMovementController(scene: scene, models: [], entities: [npc]);
    player.setInput(x: 0, z: -1, run: true);
    for (var i = 0; i < 20; i++) {
      player.update(.05);
    }
    expect(player.z, greaterThanOrEqualTo(2.5));
    expect(player.z, lessThan(4));
    player.releaseInput();
    expect(player.running, isFalse);
  });
  test('NPC on a continuous ramp blocks movement and remains talkable', () {
    final ramp = MapSpatialScene(
        width: 8,
        depth: 8,
        heightLevels: [
          for (var z = 0; z < 8; z++)
            for (var x = 0; x < 8; x++) z < 2 ? 2 : 0
        ],
        navigation:
            SpatialNavigationProfile(spawn: SpatialSpawn(x: 3.5, z: 4), ramps: [
          SpatialRamp(
              id: 'ramp',
              x: 3,
              z: 2,
              width: 1,
              depth: 2,
              lowLevel: 0,
              highLevel: 2,
              direction: SpatialRampDirection.north)
        ]));
    final player =
        SpatialMovementController(scene: ramp, models: [], entities: [npc]);
    player.setInput(x: 0, z: -1, run: true);
    for (var i = 0; i < 20; i++) {
      player.update(.05);
    }
    expect(player.z, greaterThan(3));
    expect(player.z, lessThan(4));
    expect((player.y - ramp.worldHeightAt(3.5, 2.5)).abs(), greaterThan(.1));
    expect(
        findSpatialNpcInteraction(
                scene: ramp,
                entities: [npc],
                x: player.x,
                z: player.z,
                facing: EntityFacing.north)
            ?.id,
        npc.id);
    final unobstructed = SpatialMovementController(scene: ramp, models: []);
    unobstructed.setInput(x: 0, z: -1);
    for (var i = 0; i < 16; i++) {
      unobstructed.update(.05);
    }
    expect(unobstructed.z, lessThan(2.5));
  });
  test(
      'lower plateau ramp permits interaction across different terrain heights',
      () {
    final map = plateau();
    final rampNpc = npc.copyWith(pos: GridPos(x: 7, y: 7));
    expect(map.worldHeightAt(7.5, 8.5), 0);
    expect(map.worldHeightAt(7.5, 7.5), .5);
    expect(
        findSpatialNpcInteraction(
                scene: map,
                entities: [rampNpc],
                x: 7.5,
                z: 8.5,
                facing: EntityFacing.north)
            ?.id,
        npc.id);
    final player = SpatialMovementController(
        scene: map.copyWith(
            navigation:
                map.navigation.copyWith(spawn: SpatialSpawn(x: 8, z: 8.5))),
        models: [],
        entities: [rampNpc]);
    player.setInput(x: 0, z: -1, run: true);
    for (var i = 0; i < 20; i++) {
      player.update(.05);
    }
    expect(player.z, greaterThan(7.5));
    expect(player.z, lessThan(8.5));
    expect(
        findSpatialNpcInteraction(
                scene: map,
                entities: [rampNpc],
                x: player.x,
                z: player.z,
                facing: EntityFacing.north)
            ?.id,
        npc.id);
    final cliff = map.copyWith(heightLevels: [
      for (var i = 0; i < map.heightLevels.length; i++)
        i == 7 * map.width + 7 ? 1 : map.heightLevels[i]
    ], navigation: map.navigation.copyWith(ramps: []));
    expect(
        findSpatialNpcInteraction(
            scene: cliff,
            entities: [rampNpc],
            x: 7.5,
            z: 8.5,
            facing: EntityFacing.north),
        isNull);
  });
  test('interaction requires facing, cardinal reach and traversable terrain',
      () {
    MapEntity? target(double x, double z, EntityFacing facing,
            {MapSpatialScene? map}) =>
        findSpatialNpcInteraction(
            scene: map ?? scene, entities: [npc], x: x, z: z, facing: facing);
    expect(target(3.5, 3.5, EntityFacing.north)?.id, 'npc');
    expect(target(3.5, 3.5, EntityFacing.south), isNull);
    expect(target(3.5, 4, EntityFacing.north), isNull);
    expect(target(4.2, 3.5, EntityFacing.north), isNull);
    final raised = scene
        .copyWith(heightLevels: [for (var i = 0; i < 64; i++) i == 19 ? 2 : 0]);
    expect(target(3.5, 3.5, EntityFacing.north, map: raised), isNull);
    expect(spatialNpcFacingPlayer(npc, x: 3.5, z: 3.5), EntityFacing.south);
  });

  test('a moved NPC is reached at its exact fractional runtime position', () {
    final displaced = npc.copyWith(pos: GridPos(x: 6, y: 6));
    final state = SpatialActorRuntimeState(
        x: 3.625, z: 2.625, facing: EntityFacing.south);
    MapEntity? find(EntityFacing facing) => findSpatialNpcInteraction(
        scene: scene,
        entities: [displaced],
        x: 3.625,
        z: 3.875,
        facing: facing,
        actorStateProvider: (_) => state);
    expect(find(EntityFacing.north)?.id, npc.id);
    expect(find(EntityFacing.south), isNull);
    expect(
        spatialNpcFacingPlayer(displaced,
            x: 4.625, z: 2.625, actorState: state),
        EntityFacing.east);
    expect(
        findSpatialNpcInteraction(
            scene: scene,
            entities: [displaced],
            x: 6.5,
            z: 7.5,
            facing: EntityFacing.north,
            actorStateProvider: (_) => state),
        isNull);
  });

  test('dynamic entity interaction checks terrain at the current position', () {
    final raised = scene.copyWith(heightLevels: [
      for (var z = 0; z < 8; z++)
        for (var x = 0; x < 8; x++) z == 2 ? 2 : 0,
    ]);
    final state =
        SpatialActorRuntimeState(x: 3.5, z: 2.5, facing: EntityFacing.south);
    expect(
        findSpatialEntityInteraction(
            scene: raised,
            entities: [npc],
            x: 3.5,
            z: 4.5,
            facing: EntityFacing.north,
            actorStateProvider: (_) => SpatialActorRuntimeState(
                x: 3.5, z: 3.5, facing: EntityFacing.south))?.id,
        npc.id);
    expect(
        findSpatialEntityInteraction(
            scene: raised,
            entities: [npc.copyWith(pos: GridPos(x: 3, y: 4))],
            x: 3.5,
            z: 3.5,
            facing: EntityFacing.north,
            actorStateProvider: (_) => state),
        isNull);
  });
}
