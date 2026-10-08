import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapSpatialScene plateau(
        {double spawnX = 8, List<SpatialModelInstance> instances = const []}) =>
    MapSpatialScene(
        width: 16,
        depth: 14,
        heightLevels: [
          for (var z = 0; z < 14; z++)
            for (var x = 0; x < 16; x++)
              z < 6
                  ? 2
                  : z == 6
                      ? 1
                      : 0
        ],
        instances: instances,
        navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: spawnX, z: 11),
            ramps: [
              SpatialRamp(
                  id: 'upper',
                  x: 7.3125,
                  z: 6,
                  width: 1.375,
                  depth: 1,
                  lowLevel: 1,
                  highLevel: 2,
                  direction: SpatialRampDirection.north),
              SpatialRamp(
                  id: 'lower',
                  x: 7.3125,
                  z: 7,
                  width: 1.375,
                  depth: 1,
                  lowLevel: 0,
                  highLevel: 1,
                  direction: SpatialRampDirection.north)
            ],
            blockedAreas: [
              SpatialBlockedArea(x: 0, z: 6, width: 7.3125, depth: 2),
              SpatialBlockedArea(x: 8.6875, z: 6, width: 7.3125, depth: 2)
            ]));
void steps(SpatialMovementController player, int count,
    {int x = 0, int z = -1, bool run = false}) {
  player.setInput(x: x, z: z, run: run);
  for (var i = 0; i < count; i++) {
    player.update(.05);
  }
}

void main() {
  for (final elevated in [false, true]) {
    for (final direction in [
      (name: 'north', x: 0, z: -1, spawnX: 2.5, spawnZ: 4.5),
      (name: 'south', x: 0, z: 1, spawnX: 2.5, spawnZ: 1.5),
      (name: 'east', x: 1, z: 0, spawnX: 1.5, spawnZ: 2.5),
      (name: 'west', x: -1, z: 0, spawnX: 4.5, spawnZ: 2.5),
    ]) {
      test(
          'the full footprint stops at a ${direction.name} cliff from '
          '${elevated ? 'above' : 'below'}', () {
        final scene = MapSpatialScene(
          width: 6,
          depth: 6,
          heightLevels: [
            for (var z = 0; z < 6; z++)
              for (var x = 0; x < 6; x++)
                (direction.x > 0
                            ? x >= 3
                            : direction.x < 0
                                ? x < 3
                                : direction.z > 0
                                    ? z >= 3
                                    : z < 3) !=
                        elevated
                    ? 3
                    : 0,
          ],
          navigation: SpatialNavigationProfile(
            spawn: SpatialSpawn(x: direction.spawnX, z: direction.spawnZ),
          ),
        );
        final player = SpatialMovementController(scene: scene, models: []);
        steps(player, 50, x: direction.x, z: direction.z, run: true);
        switch (direction.name) {
          case 'north':
            expect(player.z, greaterThanOrEqualTo(3.4375));
            expect(player.z, lessThan(direction.spawnZ));
          case 'south':
            expect(player.z, lessThanOrEqualTo(2.9375));
            expect(player.z, greaterThan(direction.spawnZ));
          case 'east':
            expect(player.x, lessThanOrEqualTo(2.625));
            expect(player.x, greaterThan(direction.spawnX));
          case 'west':
            expect(player.x, greaterThanOrEqualTo(3.375));
            expect(player.x, lessThan(direction.spawnX));
        }
        expect(player.y, elevated ? 3 : 0);
        expect(player.moving, isFalse);
      });
    }
  }

  test('adjacent steep ramps carry a footprint across their shared seam', () {
    final scene = MapSpatialScene(
      width: 6,
      depth: 6,
      heightLevels: [
        for (var z = 0; z < 6; z++)
          for (var x = 0; x < 6; x++) z < 2 ? 5 : 0,
      ],
      navigation: SpatialNavigationProfile(
        spawn: SpatialSpawn(x: 3, z: 4.5),
        ramps: [
          for (final x in [2.0, 3.0])
            SpatialRamp(
              id: 'ramp-${x.toInt()}',
              x: x,
              z: 2,
              width: 1,
              depth: 1,
              lowLevel: 0,
              highLevel: 5,
              direction: SpatialRampDirection.north,
            ),
        ],
      ),
    );
    final player = SpatialMovementController(scene: scene, models: []);
    final midway = SpatialMovementController(
      scene: scene.copyWith(
        navigation: scene.navigation.copyWith(
          spawn: SpatialSpawn(x: 3, z: 2.5),
        ),
      ),
      models: [],
    );
    expect(midway.y, 2.5);
    steps(player, 20);
    expect(player.y, 5);
    expect(player.z, lessThan(2));
    steps(player, 20, z: 1);
    expect(player.y, 0);
    expect(player.z, greaterThan(3));
  });

  test('a diagonal approach slides along a cliff without clipping its corner',
      () {
    final player = SpatialMovementController(
      scene: MapSpatialScene(
        width: 6,
        depth: 6,
        heightLevels: [
          for (var z = 0; z < 6; z++)
            for (var x = 0; x < 6; x++) x >= 3 && z >= 3 ? 2 : 0,
        ],
        navigation: SpatialNavigationProfile(
          allowDiagonalMovement: true,
          spawn: SpatialSpawn(x: 2.5, z: 2.5),
        ),
      ),
      models: [],
    );
    steps(player, 25, x: 1, z: 1, run: true);
    expect(player.y, 0);
    expect(player.x + .375 <= 3 || player.z + .0625 <= 3, isTrue);
    expect(player.x, greaterThan(3));
  });

  test('a spawn whose footprint crosses a cliff is rejected', () {
    final scene = MapSpatialScene(
      width: 6,
      depth: 6,
      heightLevels: [
        for (var z = 0; z < 6; z++)
          for (var x = 0; x < 6; x++) x >= 3 ? 1 : 0,
      ],
      navigation: SpatialNavigationProfile(
        spawn: SpatialSpawn(x: 2.8125, z: 2.5),
      ),
    );
    expect(() => SpatialMovementController(scene: scene, models: []),
        throwsStateError);
  });

  test(
      'a validated five-level ramp stays traversable while its side cliff blocks',
      () {
    final scene = MapSpatialScene(
        width: 6,
        depth: 6,
        heightLevels: [
          for (var z = 0; z < 6; z++)
            for (var x = 0; x < 6; x++) z < 2 ? 5 : 0
        ],
        navigation:
            SpatialNavigationProfile(spawn: SpatialSpawn(x: 3, z: 5), ramps: [
          SpatialRamp(
              id: 'steep',
              x: 2,
              z: 2,
              width: 2,
              depth: 1,
              lowLevel: 0,
              highLevel: 5,
              direction: SpatialRampDirection.north)
        ]));
    final player = SpatialMovementController(scene: scene, models: []);
    steps(player, 25);
    expect(player.y, 5);
    expect(player.z, closeTo(1.25, .1));
    steps(player, 25, z: 1);
    expect(player.y, 0);
    expect(player.z, closeTo(5, .1));
    steps(player, 17);
    expect(player.y, greaterThan(0));
    expect(player.y, lessThan(5));
    final height = player.y;
    steps(player, 25, x: -1, z: 0);
    expect(player.x, greaterThanOrEqualTo(2));
    expect(player.y, height);
    final cliff = SpatialMovementController(
        scene: scene.copyWith(
            navigation:
                scene.navigation.copyWith(spawn: SpatialSpawn(x: 1, z: 5))),
        models: []);
    steps(cliff, 30);
    expect(cliff.y, 0);
    expect(cliff.z, greaterThanOrEqualTo(2));
  });

  test('two north ramps connect spawn to upper plateau and back', () {
    final player = SpatialMovementController(scene: plateau(), models: []);
    expect(player.y, 0);
    steps(player, 45);
    expect(player.z, closeTo(4.25, .1));
    expect(player.y, 2);
    expect(player.facing, EntityFacing.north);
    expect(player.moving, isTrue);
    expect(player.animationSeconds, greaterThan(0));
    steps(player, 45, z: 1);
    expect(player.z, closeTo(11, .1));
    expect(player.y, 0);
    player.reset();
    expect(player.z, 11);
    expect(player.moving, isFalse);
  });
  test('ramp interpolation and cliff boundaries block leaving the corridor',
      () {
    final scene = plateau();
    expect(scene.worldHeightAt(8, 6.5), 1.5);
    expect(scene.worldHeightAt(8, 7.5), .5);
    final player =
        SpatialMovementController(scene: plateau(spawnX: 4), models: []);
    steps(player, 70);
    expect(player.z, greaterThanOrEqualTo(8));
    expect(player.y, 0);
    final cliff = SpatialMovementController(
        scene: MapSpatialScene(
            width: 4,
            depth: 4,
            heightLevels: [
              for (var z = 0; z < 4; z++)
                for (var x = 0; x < 4; x++) z < 2 ? 2 : 0
            ],
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 2, z: 3))),
        models: []);
    steps(cliff, 30);
    expect(cliff.z, greaterThanOrEqualTo(2));
    expect(cliff.y, 0);
  });
  test('model collision respects yaw, scale, pivot and blocksMovement', () {
    final model = ProjectModel3dEntry(
        id: 'house',
        name: 'House',
        sourceAssetId: 'house-source',
        relativePath: 'assets/models3d/house.glb',
        pivot: Model3dVector3(x: 1, y: 0, z: 0),
        scale: 2,
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3(x: -1, y: 0, z: -.5),
                max: Model3dVector3(x: 1, y: 2, z: .5)),
            meshCount: 1,
            triangleCount: 1));
    final instance = SpatialModelInstance(
        id: 'house-1',
        modelId: 'house',
        position: Model3dVector3(x: 8, y: 0, z: 8),
        rotationDegrees: 90,
        scale: .5);
    final player = SpatialMovementController(
        scene: plateau(instances: [instance]), models: [model]);
    steps(player, 30);
    expect(player.z, greaterThanOrEqualTo(10.4));
    final decoration = SpatialMovementController(
        scene: plateau(instances: [instance.copyWith(blocksMovement: false)]),
        models: [model]);
    steps(decoration, 30);
    expect(decoration.z, lessThan(7));
  });
  test('diagonal setting, running, pause and dt clamp are input safe', () {
    final player = SpatialMovementController(scene: plateau(), models: []);
    steps(player, 1, x: 1, z: -1);
    expect(player.x, 8);
    expect(player.z, lessThan(11));
    player.setDiagonalMovement(true);
    final beforeX = player.x;
    steps(player, 5, x: 1, z: -1, run: true);
    expect(player.x, greaterThan(beforeX));
    expect(player.running, isTrue);
    player.setPaused(true);
    final frozenX = player.x;
    player.update(1);
    expect(player.x, frozenX);
    player.setPaused(false);
    player.update(1);
    expect(player.x, frozenX);
    player.reset();
    player.setInput(x: 0, z: 1);
    player.update(100);
    expect(player.z - 11, lessThan(.2));
    player.releaseInput();
    expect(player.running, isFalse);
    player.update(double.nan);
    expect(player.z.isFinite, isTrue);
  });

  test('a live door opens and closes without clearing held input', () {
    var doorState = _doorState(true);
    final player = SpatialMovementController(
        scene: _doorScene(authoredBlocking: false),
        models: [_doorModel()],
        modelStateProvider: (_) => doorState);
    player.setInput(x: 1, z: 0, run: true);
    final epoch = player.inputEpoch;
    for (var i = 0; i < 20; i++) {
      player.update(.05);
    }
    expect(player.x, lessThan(2.5));
    expect(player.moving, isFalse);
    doorState = _doorState(false);
    for (var i = 0; i < 10; i++) {
      player.update(.05);
    }
    expect(player.x, greaterThan(3.5));
    expect(player.running, isTrue);
    expect(player.inputEpoch, epoch);
    doorState = _doorState(true);
    player.setInput(x: -1, z: 0, run: true);
    for (var i = 0; i < 20; i++) {
      player.update(.05);
    }
    expect(player.x, greaterThan(3.5));
    expect(player.moving, isFalse);
    expect(player.inputEpoch, epoch);
  });

  test(
      'a moved NPC blocks its current position and frees its authored position',
      () {
    var actorState =
        SpatialActorRuntimeState(x: 3.5, z: 2.5, facing: EntityFacing.south);
    final player = SpatialMovementController.fromMap(
        map: MapData(
            id: 'village',
            name: 'Village',
            size: const GridSize(width: 8, height: 8),
            spatialScene: _doorScene(),
            entities: [_npc('guide', 3, 2)]),
        models: [_doorModel()],
        modelStateProvider: (_) => _doorState(false),
        actorStateProvider: (_) => actorState);
    player.setInput(x: 1, z: 0);
    final epoch = player.inputEpoch;
    for (var i = 0; i < 30; i++) {
      player.update(.05);
    }
    expect(player.x, lessThan(3.5));
    actorState =
        SpatialActorRuntimeState(x: 6.5, z: 2.5, facing: EntityFacing.south);
    for (var i = 0; i < 30; i++) {
      player.update(.05);
    }
    expect(player.x, greaterThan(4));
    expect(player.x, lessThan(6.5));
    expect(player.moving, isFalse);
    actorState =
        SpatialActorRuntimeState(x: 6.5, z: 5.5, facing: EntityFacing.south);
    for (var i = 0; i < 10; i++) {
      player.update(.05);
    }
    expect(player.x, greaterThan(6.5));
    expect(player.inputEpoch, epoch);
  });

  test('actor traversal ignores only its own current entity identity', () {
    var otherPresent = true;
    final player = SpatialMovementController(
        scene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 1.5, z: 5))),
        models: [],
        entities: [_npc('guide', 3, 2), _npc('other', 5, 2)],
        actorStateProvider: (id) => id == 'guide'
            ? SpatialActorRuntimeState(
                x: 1.5, z: 2.5, facing: EntityFacing.south)
            : null,
        entityPresencePredicate: (entity) =>
            entity.id != 'other' || otherPresent);
    final position = player.spatialPosition;
    final epoch = player.inputEpoch;
    expect(player.canTraverseActor(1.5, 2.5, 2.5, 2.5), isFalse);
    expect(
        player.canTraverseActor(1.5, 2.5, 2.5, 2.5, ignoredEntityId: 'guide'),
        isTrue);
    expect(
        player.canTraverseActor(1.5, 2.5, 6.5, 2.5, ignoredEntityId: 'guide'),
        isFalse);
    otherPresent = false;
    expect(
        player.canTraverseActor(1.5, 2.5, 6.5, 2.5, ignoredEntityId: 'guide'),
        isTrue);
    expect(player.spatialPosition, position);
    expect(player.inputEpoch, epoch);
  });

  test('actor routes follow ramps and read live decor blocking', () {
    var state = _doorState(true);
    final scene = plateau(instances: [
      SpatialModelInstance(
          id: 'door',
          modelId: 'door-model',
          position: Model3dVector3(x: 8, y: 0, z: 9)),
    ]);
    final player = SpatialMovementController(
        scene: scene, models: [_doorModel()], modelStateProvider: (_) => state);
    expect(player.canTraverseActor(8, 11, 8, 4.25), isFalse);
    state = _doorState(false);
    expect(player.canTraverseActor(8, 11, 8, 4.25), isTrue);
    expect(player.canTraverseActor(8, 4.25, 8, 11), isTrue);
    expect(player.canTraverseActor(4, 11, 4, 4.25), isFalse);
    expect(player.x, 8);
    expect(player.z, 11);
  });

  test('actor route catches a thin obstacle between valid endpoints', () {
    final player = SpatialMovementController(
        scene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation: SpatialNavigationProfile(
                spawn: SpatialSpawn(x: 1.5, z: 2.5),
                blockedAreas: [
                  SpatialBlockedArea(x: 2.15, z: 2.4, width: .05, depth: .2),
                ])),
        models: []);
    expect(player.canTraverseActor(1.5, 2.5, 4.5, 2.5), isFalse);
    expect(player.canTraverseActor(4.5, 2.5, 4.5, 2.5), isTrue);
  });

  test('actor route preserves collision layers and rejects invalid coordinates',
      () {
    final player = SpatialMovementController.fromMap(
        map: MapData(
            id: 'village',
            name: 'Village',
            size: const GridSize(width: 8, height: 8),
            spatialScene: _doorScene(authoredBlocking: false),
            layers: [
              CollisionLayer(id: 'collision', name: 'Collision', collisions: [
                for (var z = 0; z < 8; z++)
                  for (var x = 0; x < 8; x++) x == 4,
              ]),
            ]),
        models: [_doorModel()]);
    expect(player.canTraverseActor(1.5, 2.5, 5.5, 2.5), isFalse);
    expect(player.canTraverseActor(1.5, 2.5, double.nan, 2.5), isFalse);
    expect(player.canTraverseActor(1.5, 2.5, double.infinity, 2.5), isFalse);
    expect(player.canTraverseActor(-1, 2.5, 1.5, 2.5), isFalse);
    expect(player.canTraverseActor(1.5, 2.5, 8, 2.5), isFalse);
  });

  test(
      'a closure overlap check ignores the current open state without mutation',
      () {
    final player = SpatialMovementController(
        scene: _doorScene(authoredBlocking: false),
        models: [_doorModel()],
        modelStateProvider: (_) => _doorState(false));
    player.setInput(x: 1, z: 0, run: true);
    final epoch = player.inputEpoch;
    expect(player.wouldModelBlockActor('door', 3, 2.5), isTrue);
    expect(player.wouldModelBlockActor('door', 2.125, 2.5), isFalse);
    expect(player.wouldModelBlockActor('door', 2.13, 2.5), isTrue);
    expect(player.wouldModelBlockActor('door', 1.5, 2.5), isFalse);
    expect(player.wouldModelBlockActor('door', 3, 3.5), isFalse);
    expect(player.inputEpoch, epoch);
    expect(player.x, 1.5);
    player.update(.05);
    expect(player.running, isTrue);
  });

  test('a closure overlap check respects world height and missing identities',
      () {
    final scene = _doorScene(authoredBlocking: false).copyWith(heightLevels: [
      for (var z = 0; z < 8; z++)
        for (var x = 0; x < 8; x++) x >= 2 ? 3 : 0,
    ]);
    final player =
        SpatialMovementController(scene: scene, models: [_doorModel()]);
    expect(player.wouldModelBlockActor('door', 3, 2.5), isFalse);
    expect(
        () => player.wouldModelBlockActor('missing', 3, 2.5), throwsStateError);
  });

  test('runtime provider attachment preserves held input and can be removed',
      () {
    final player =
        SpatialMovementController(scene: _doorScene(), models: [_doorModel()]);
    player.setInput(x: 1, z: 0, run: true);
    final epoch = player.inputEpoch;
    for (var i = 0; i < 20; i++) {
      player.update(.05);
    }
    final blockedX = player.x;
    player.setRuntimeStateProviders(
        modelStateProvider: (_) => _doorState(false));
    for (var i = 0; i < 10; i++) {
      player.update(.05);
    }
    expect(player.x, greaterThan(blockedX));
    expect(player.running, isTrue);
    expect(player.inputEpoch, epoch);
    player.setRuntimeStateProviders();
    expect(player.canTraverseActor(1.5, 2.5, 5.5, 2.5), isFalse);
    player.update(.05);
    expect(player.running, isTrue);
    expect(player.inputEpoch, epoch);
  });

  test('actor traversal preserves a fractional endpoint footprint', () {
    final player =
        SpatialMovementController(scene: _doorScene(), models: [_doorModel()]);
    expect(player.canTraverseActor(1.5, 2.5, 2.125, 2.5), isTrue);
    expect(player.canTraverseActor(1.5, 2.5, 2.13, 2.5), isFalse);
  });

  test(
      'NPC traversal can collide with the hero without blocking the hero itself',
      () {
    final player = SpatialMovementController(
        scene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 3.5, z: 2.5))),
        models: []);
    expect(player.canTraverseActor(1.5, 2.5, 5.5, 2.5), isTrue);
    expect(player.canTraverseActor(1.5, 2.5, 5.5, 2.5, collideWithPlayer: true),
        isFalse);
    expect(player.canTraverseActor(1.5, 2.5, 3.5, 2.5, collideWithPlayer: true),
        isFalse);
    expect(player.canTraverseActor(1.5, 4, 5.5, 4, collideWithPlayer: true),
        isTrue);
    expect(player.x, 3.5);
    expect(player.z, 2.5);
  });

  test('NPC routes collide with the current cinematic hero override', () {
    final player = SpatialMovementController(
        scene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 3.5, z: 2.5))),
        models: []);
    final hero = PlayerSpatialPosition(x: 5.5, z: 4);
    expect(
        player.canTraverseActor(1.5, 2.5, 5.5, 2.5,
            collideWithPlayer: true, playerPosition: hero),
        isTrue);
    expect(
        player.canTraverseActor(1.5, 4, 5.5, 4,
            collideWithPlayer: true, playerPosition: hero),
        isFalse);
    expect(
        player.canTraverseActor(1.5, 4, 5.5, 4, playerPosition: hero), isTrue);
    expect(
        player.canTraverseActor(4, 4, 4.75, 4,
            collideWithPlayer: true,
            playerPosition: PlayerSpatialPosition(x: 5.498, z: 4)),
        isFalse);
    expect(
        player.canTraverseActor(4, 4, 4.75, 4,
            collideWithPlayer: true,
            playerPosition: PlayerSpatialPosition(x: 5.503, z: 4)),
        isTrue);
    expect(player.x, 3.5);
    expect(player.z, 2.5);
  });

  test(
      'a traversal query can override NPC poses without changing live providers',
      () {
    final player = SpatialMovementController(
        scene: MapSpatialScene(
            width: 8,
            depth: 8,
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 1.5, z: 5))),
        models: [],
        entities: [_npc('guide', 3, 2)],
        actorStateProvider: (_) => SpatialActorRuntimeState(
            x: 3.5, z: 2.5, facing: EntityFacing.south));
    expect(
        player.canTraverseActor(1.5, 2.5, 5.5, 2.5,
            actorStateProvider: (_) => SpatialActorRuntimeState(
                x: 3.5, z: 4.5, facing: EntityFacing.south)),
        isTrue);
    expect(player.canTraverseActor(1.5, 2.5, 5.5, 2.5), isFalse);
    expect(
        player.canTraverseActor(1.5, 2.5, 5.5, 2.5,
            actorStateProvider: (_) => null),
        isFalse);
    expect(player.x, 1.5);
    expect(player.z, 5);
  });
}

MapEntity _npc(String id, int x, int z) => MapEntity(
    id: id,
    kind: MapEntityKind.npc,
    pos: GridPos(x: x, y: z),
    npc: MapEntityNpcData(characterId: 'guide'));

SpatialModelRuntimeState _doorState(bool blocks) => SpatialModelRuntimeState(
    modelId: 'door-model',
    animationIndex: null,
    normalizedTime: 0,
    blocksMovement: blocks);

ProjectModel3dEntry _doorModel() => ProjectModel3dEntry(
    id: 'door-model',
    name: 'Door',
    sourceAssetId: 'door-source',
    relativePath: 'assets/models3d/door-model.glb',
    inspection: Model3dInspection(
        bounds: Model3dBounds(
            min: Model3dVector3(x: -.5, y: 0, z: -.25),
            max: Model3dVector3(x: .5, y: 2, z: .25)),
        meshCount: 1,
        triangleCount: 1));

MapSpatialScene _doorScene({bool authoredBlocking = true}) => MapSpatialScene(
        width: 8,
        depth: 8,
        navigation:
            SpatialNavigationProfile(spawn: SpatialSpawn(x: 1.5, z: 2.5)),
        instances: [
          SpatialModelInstance(
              id: 'door',
              modelId: 'door-model',
              position: Model3dVector3(x: 3, y: 0, z: 2.5),
              blocksMovement: authoredBlocking),
        ]);
