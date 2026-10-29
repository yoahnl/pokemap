import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'field_obstacle_action_test.dart' as fixture;

final strengthModel = ProjectModel3dEntry(
    id: 'boulder',
    name: 'Boulder',
    sourceAssetId: 'boulder-source',
    relativePath: 'assets/models3d/boulder.glb',
    inspection: Model3dInspection(
        bounds: Model3dBounds(
            min: Model3dVector3(x: -.3, y: 0, z: -.3),
            max: Model3dVector3(x: .3, y: 1, z: .3)),
        meshCount: 1,
        triangleCount: 1));

MapData strengthMap(
    {FieldObstacleResetPolicy policy = FieldObstacleResetPolicy.mapInstance}) {
  final map = fixture.obstacleMap(FieldObstacleKind.strengthBoulder);
  return map.copyWith(
      version: ProjectVersion.v9,
      entities: [
        map.entities.single.copyWith(
            fieldObstacle: MapEntityFieldObstacleData(
                kind: FieldObstacleKind.strengthBoulder, resetPolicy: policy))
      ],
      spatialScene: MapSpatialScene(width: 6, depth: 4, instances: [
        SpatialModelInstance(
            id: 'rock-model',
            modelId: strengthModel.id,
            entityId: 'rock',
            position: Model3dVector3(x: 2.5, y: 0, z: 1.5))
      ]));
}

GameState activeStrength({double x = 1.5, double z = 1.5}) {
  final state = fixture.ready(FieldAbility.strength);
  return state.copyWith(
      playerSpatialPosition: PlayerSpatialPosition(x: x, z: z),
      mapInstanceWorldState: state.mapInstanceWorldState
          .activateStrength(state.mapInstanceWorldState.instanceRef('route')!));
}

SpatialStrengthPushTicket? pushTicket(MapData map, GameState state,
        {Iterable<ProjectModel3dEntry>? models,
        bool Function(String)? entityIsPresent}) =>
    issueSpatialStrengthPushTicket(
        map: map,
        gameState: state,
        models: models ?? [strengthModel],
        entityId: 'rock',
        x: state.playerSpatialPosition!.x,
        z: state.playerSpatialPosition!.z,
        facing: state.playerFacing,
        stateRevision: 4,
        entityIsPresent: entityIsPresent);

FieldObstacleCommit push(
        SpatialStrengthPushTicket ticket, MapData map, GameState state,
        {Iterable<ProjectModel3dEntry>? models,
        int revision = 4,
        ProjectSettings? settings,
        bool Function(String)? entityIsPresent,
        SpatialActorRuntimeState? Function(String)? actorStateProvider}) =>
    commitSpatialStrengthPush(
        ticket: ticket,
        map: map,
        gameState: state,
        models: models ?? [strengthModel],
        currentStateRevision: revision,
        projectSettings: settings,
        entityIsPresent: entityIsPresent,
        actorStateProvider: actorStateProvider);

ProjectModel3dEntry wallModel({double minY = 0, double maxY = 1}) =>
    ProjectModel3dEntry(
        id: 'wall',
        name: 'Wall',
        sourceAssetId: 'wall-source',
        relativePath: 'assets/models3d/wall.glb',
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3(x: -.01, y: minY, z: -.1),
                max: Model3dVector3(x: .01, y: maxY, z: .1)),
            meshCount: 1,
            triangleCount: 1));

void main() {
  test('3D Strength uses the canonical ability gate', () {
    final state = fixture.ready(FieldAbility.strength);
    expect(
        evaluateSpatialFieldObstacleAttempt(
            map: strengthMap(),
            gameState: state,
            models: [strengthModel],
            entityId: 'rock',
            x: 1.5,
            z: 1.5,
            facing: EntityFacing.east),
        isA<CanUseFieldObstacle>());
  });

  test('activation is gated, scoped, and never destroys the Strength boulder',
      () {
    final map = strengthMap(), state = fixture.ready(FieldAbility.strength);
    final ticket = issueSpatialFieldObstacleTicket(
        map: map,
        gameState: state,
        models: [strengthModel],
        entityId: 'rock',
        x: 1.5,
        z: 1.5,
        facing: EntityFacing.east,
        stateRevision: 4)!;
    FieldObstacleCommit activate(GameState current,
            {ProjectSettings? settings}) =>
        commitSpatialStrengthActivation(
            ticket: ticket,
            map: map,
            gameState: current,
            models: [strengthModel],
            x: 1.5,
            z: 1.5,
            facing: EntityFacing.east,
            currentStateRevision: 4,
            confirmedEntityId: 'rock',
            projectSettings: settings);
    expect(
        activate(state,
            settings: ProjectSettings(
                fieldAbilities: ProjectFieldAbilitiesSettings(
                    disabledAbilities: [FieldAbility.strength]))),
        isA<FieldObstacleRefused>());
    expect(activate(state.copyWith(party: const PlayerParty())),
        isA<FieldObstacleRefused>());
    expect(activate(state.copyWith(progression: const PlayerProgression())),
        isA<FieldObstacleRefused>());
    expect(
        commitSpatialDestructibleFieldObstacleAction(
            ticket: ticket,
            map: map,
            gameState: state,
            models: [strengthModel],
            x: 1.5,
            z: 1.5,
            facing: EntityFacing.east,
            currentStateRevision: 4,
            confirmedEntityId: 'rock'),
        isA<FieldObstacleRefused>());
    final result = activate(state) as FieldObstacleApplied;
    expect(
        result.gameState.mapInstanceWorldState
            .isStrengthActive(ticket.instance),
        isTrue);
    expect(
        result.gameState.mapInstanceWorldState
            .isFieldObstacleCleared(ticket.instance, 'rock'),
        isFalse);
    expect(activate(result.gameState), isA<FieldObstacleRefused>());
    expect(result.gameState.playerPosition, state.playerPosition);
  });

  for (final policy in FieldObstacleResetPolicy.values) {
    test(
        'two pushes preserve subcell and authored pose with $policy save policy',
        () {
      final map = strengthMap(policy: policy), before = map.toJson();
      var state = activeStrength(x: 1.625, z: 1.5);
      final instance = state.mapInstanceWorldState.instanceRef(map.id)!;
      final originalModels = state.spatialWorldState;
      for (var i = 0; i < 2; i++) {
        final ticket = pushTicket(map, state)!;
        expect(ticket.from, GridPos(x: 2 + i, y: 1));
        expect(ticket.to, GridPos(x: 3 + i, y: 1));
        expect(ticket.playerTo.x, 2.625 + i);
        final result = push(ticket, map, state) as FieldObstacleApplied;
        expect(
            push(ticket, map, result.gameState), isA<FieldObstacleRefused>());
        state = result.gameState;
        expect(state.playerSpatialPosition!.x, 2.625 + i);
        expect(state.playerPosition, GridPos(x: 2 + i, y: 1));
        expect(
            state.mapInstanceWorldState.fieldObstaclePosition(instance, 'rock'),
            GridPos(x: 3 + i, y: 1));
        expect(state.spatialWorldState, originalModels);
      }
      state = GameState.fromJson(state.toJson());
      validateSpatialStrengthSavedPositions(
          map: map, gameState: state, models: [strengthModel]);
      expect(map.toJson(), before);
      final reset = setupDifferentMapInstance(
          state: state.mapInstanceWorldState,
          targetMapId: map.id,
          allocateId: (_) => 'return');
      expect(
          reset.fieldObstaclePositionForMap(map.id, 'rock'),
          policy == FieldObstacleResetPolicy.persistent
              ? const GridPos(x: 4, y: 1)
              : null);
      expect(reset.isStrengthActive(reset.instanceRef(map.id)!), isFalse);
    });
  }

  test(
      'push requires active Strength and revalidates revision, gate, poses and binding',
      () {
    final map = strengthMap(), state = activeStrength();
    expect(
        pushTicket(
            map,
            fixture.ready(FieldAbility.strength).copyWith(
                playerSpatialPosition: PlayerSpatialPosition(x: 1.5, z: 1.5))),
        isNull);
    final ticket = pushTicket(map, state)!;
    for (final current in [
      state.copyWith(party: const PlayerParty()),
      state.copyWith(progression: const PlayerProgression()),
      state.copyWith(playerPosition: const GridPos(x: 0, y: 1)),
      state.copyWith(playerPixelPosition: const PixelOffset(x: 1, y: 1)),
      state.copyWith(
          playerSpatialPosition: PlayerSpatialPosition(x: 1.625, z: 1.5)),
      state.copyWith(playerFacing: EntityFacing.north),
      state.copyWith(
          mapInstanceWorldState: setupDifferentMapInstance(
              state: state.mapInstanceWorldState,
              targetMapId: map.id,
              allocateId: (_) => 'new'))
    ]) {
      expect(push(ticket, map, current), isA<FieldObstacleRefused>());
    }
    expect(push(ticket, map, state, revision: 5), isA<FieldObstacleRefused>());
    expect(
        push(ticket, map, state,
            settings: ProjectSettings(
                fieldAbilities: ProjectFieldAbilitiesSettings(
                    disabledAbilities: [FieldAbility.strength]))),
        isA<FieldObstacleRefused>());
    expect(
        push(
            ticket,
            map.copyWith(
                spatialScene: map.spatialScene!.copyWith(instances: [
              map.spatialScene!.instances.single.copyWith(rotationDegrees: 90)
            ])),
            state),
        isA<FieldObstacleRefused>());
    expect(push(ticket, map, state, entityIsPresent: (_) => false),
        isA<FieldObstacleRefused>());
  });

  test('current actor poses block the swept boulder and hero route', () {
    final map = strengthMap().copyWith(entities: [
      ...strengthMap().entities,
      const MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 5, y: 3),
          npc: MapEntityNpcData(characterId: 'walker'))
    ]);
    final state = activeStrength();
    for (final x in [2.9, 3.5]) {
      final ticket = pushTicket(map, state)!;
      expect(
          push(ticket, map, state,
              actorStateProvider: (_) => SpatialActorRuntimeState(
                  x: x, z: 1.5, facing: EntityFacing.south)),
          isA<FieldObstacleRefused>());
    }
    expect(
        push(pushTicket(map, state)!, map, state,
            entityIsPresent: (id) => id != 'npc',
            actorStateProvider: (_) => SpatialActorRuntimeState(
                x: 3.5, z: 1.5, facing: EntityFacing.south)),
        isA<FieldObstacleApplied>());
  });

  test(
      'save validation rejects invalid endpoints without mutating source bytes',
      () {
    final map = strengthMap(), state = activeStrength();
    for (final pos in [const GridPos(x: 8, y: 1), const GridPos(x: 3, y: 1)]) {
      final changed = state.copyWith(
          mapInstanceWorldState: state.mapInstanceWorldState.moveFieldObstacle(
              state.mapInstanceWorldState.instanceRef(map.id)!, 'rock', pos));
      final blocked = map.copyWith(entities: [
        ...map.entities,
        const MapEntity(
            id: 'blocker', kind: MapEntityKind.custom, pos: GridPos(x: 3, y: 1))
      ]);
      final before = changed.toJson();
      expect(
          () => validateSpatialStrengthSavedPositions(
              map: blocked, gameState: changed, models: [strengthModel]),
          throwsStateError);
      expect(changed.toJson(), before);
    }
  });
  test('push refuses surfing even when Strength was previously activated', () {
    final state =
        activeStrength().copyWith(playerMovementMode: MovementMode.surf);
    expect(pushTicket(strengthMap(), state), isNull);
  });

  test(
      'save endpoints may have reached their position around historical obstacles',
      () {
    final map = strengthMap(policy: FieldObstacleResetPolicy.persistent)
        .copyWith(entities: [
      ...strengthMap(policy: FieldObstacleResetPolicy.persistent).entities,
      const MapEntity(
          id: 'historic-wall',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 3, y: 1))
    ]);
    final state = activeStrength();
    final saved = state.copyWith(
        mapInstanceWorldState: state.mapInstanceWorldState.moveFieldObstacle(
            state.mapInstanceWorldState.instanceRef(map.id)!,
            'rock',
            const GridPos(x: 4, y: 1),
            resetPolicy: FieldObstacleResetPolicy.persistent));
    expect(
        () => validateSpatialStrengthSavedPositions(
            map: map, gameState: saved, models: [strengthModel]),
        returnsNormally);
  });

  test(
      'activation ticket rejects a boulder moved during the prompt at the same revision',
      () {
    final map = strengthMap(), state = fixture.ready(FieldAbility.strength);
    final ticket = issueSpatialFieldObstacleTicket(
        map: map,
        gameState: state,
        models: [strengthModel],
        entityId: 'rock',
        x: 1.5,
        z: 1.5,
        facing: EntityFacing.east,
        stateRevision: 4)!;
    final moved = state.copyWith(
        mapInstanceWorldState: state.mapInstanceWorldState.moveFieldObstacle(
            state.mapInstanceWorldState.instanceRef(map.id)!,
            'rock',
            const GridPos(x: 2, y: 2)));
    expect(
        commitSpatialStrengthActivation(
            ticket: ticket,
            map: map,
            gameState: moved,
            models: [strengthModel],
            x: 1.5,
            z: 1.5,
            facing: EntityFacing.east,
            currentStateRevision: 4,
            confirmedEntityId: 'rock'),
        isA<FieldObstacleRefused>());
  });
  test('swept volume rejects a thin blocker between nonoverlapping endpoints',
      () {
    final state = activeStrength(), source = strengthMap(), wall = wallModel();
    MapData sceneWith(SpatialModelInstance instance) => source.copyWith(
        spatialScene: source.spatialScene!.copyWith(
            instances: [...source.spatialScene!.instances, instance]));
    final blocked = sceneWith(SpatialModelInstance(
        id: 'thin',
        modelId: wall.id,
        position: Model3dVector3(x: 3.05, y: 0, z: 1.5)));
    expect(pushTicket(blocked, state, models: [strengthModel, wall]), isNull);
    final floating = sceneWith(SpatialModelInstance(
        id: 'thin',
        modelId: wall.id,
        position: Model3dVector3(x: 3.05, y: 3, z: 1.5)));
    expect(
        pushTicket(floating, state, models: [strengthModel, wall]), isNotNull);
    final distant = sceneWith(SpatialModelInstance(
        id: 'thin',
        modelId: wall.id,
        position: Model3dVector3(x: 5.5, y: 0, z: 1.5)));
    final ticket = pushTicket(distant, state, models: [strengthModel, wall])!;
    final moved = state.copyWith(
        spatialWorldState: state.spatialWorldState.setModelState(
            source.id,
            'thin',
            SpatialModelRuntimeState(
                modelId: wall.id,
                animationIndex: null,
                normalizedTime: 0,
                blocksMovement: true,
                translationX: -2.45)));
    expect(push(ticket, distant, moved, models: [strengthModel, wall]),
        isA<FieldObstacleRefused>());
  });

  test(
      'persistent pushes reserve resettable authored blockers despite absence or movement',
      () {
    for (final policy in FieldObstacleResetPolicy.values) {
      for (final kind in [
        FieldObstacleKind.cutTree,
        FieldObstacleKind.strengthBoulder
      ]) {
        final source = strengthMap(policy: policy);
        final temporary = MapEntity(
            id: 'temporary',
            kind: MapEntityKind.custom,
            pos: const GridPos(x: 3, y: 1),
            fieldObstacle: MapEntityFieldObstacleData(kind: kind));
        final map = source.copyWith(
            entities: [...source.entities, temporary],
            spatialScene: source.spatialScene!.copyWith(instances: [
              ...source.spatialScene!.instances,
              SpatialModelInstance(
                  id: 'temporary-model',
                  modelId: strengthModel.id,
                  entityId: temporary.id,
                  position: Model3dVector3(x: 3.5, y: 0, z: 1.5))
            ]));
        var state = activeStrength();
        final scope = state.mapInstanceWorldState.instanceRef(map.id)!;
        state = state.copyWith(
            mapInstanceWorldState: kind == FieldObstacleKind.cutTree
                ? state.mapInstanceWorldState
                    .clearFieldObstacle(scope, temporary.id)
                : state.mapInstanceWorldState.moveFieldObstacle(
                    scope, temporary.id, const GridPos(x: 4, y: 2)));
        expect(pushTicket(map, state),
            policy == FieldObstacleResetPolicy.persistent ? isNull : isNotNull,
            reason: '$policy / $kind');
      }
    }
  });

  test('persistent reset reservations use actual authored model height', () {
    final source = strengthMap(policy: FieldObstacleResetPolicy.persistent);
    final map = source.copyWith(
        entities: [
          ...source.entities,
          const MapEntity(
              id: 'above', kind: MapEntityKind.custom, pos: GridPos(x: 3, y: 1))
        ],
        spatialScene: source.spatialScene!.copyWith(instances: [
          ...source.spatialScene!.instances,
          SpatialModelInstance(
              id: 'above-model',
              modelId: strengthModel.id,
              entityId: 'above',
              position: Model3dVector3(x: 3.5, y: 3, z: 1.5))
        ]));
    expect(
        pushTicket(map, activeStrength(),
            entityIsPresent: (id) => id != 'above'),
        isNotNull);
  });

  test('flat terrain rejects holes, steps, water and blocked navigation', () {
    final source = strengthMap();
    for (final map in [
      source.copyWith(
          spatialScene: source.spatialScene!.copyWith(
              heightLevels: [for (var i = 0; i < 24; i++) i == 9 ? 1 : 0])),
      source.copyWith(
          spatialScene: source.spatialScene!.copyWith(
              navigation: SpatialNavigationProfile(blockedAreas: [
        SpatialBlockedArea(x: 3, z: 1, width: 1, depth: 1)
      ]))),
      source.copyWith(gameplayZones: [
        const MapGameplayZone(
            id: 'water',
            kind: GameplayZoneKind.movement,
            area: MapRect(
                pos: GridPos(x: 3, y: 1), size: GridSize(width: 1, height: 1)),
            movement: MovementZonePayload(requiredMode: MovementMode.surf))
      ]),
    ]) {
      expect(pushTicket(map, activeStrength()), isNull);
    }
  });

  test('push rejects inconsistent canonical grid and spatial source pose', () {
    final state =
        activeStrength().copyWith(playerPosition: const GridPos(x: 0, y: 1));
    expect(pushTicket(strengthMap(), state), isNull);
  });

  test(
      'activation captures the saved target pose even when both poses are in range',
      () {
    final model = ProjectModel3dEntry(
        id: 'boulder',
        name: 'Wide',
        sourceAssetId: 'boulder-source',
        relativePath: 'assets/models3d/boulder.glb',
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3(x: -.3, y: 0, z: -.8),
                max: Model3dVector3(x: .3, y: 1, z: .8)),
            meshCount: 1,
            triangleCount: 1));
    final map = strengthMap(), state = fixture.ready(FieldAbility.strength);
    final ticket = issueSpatialFieldObstacleTicket(
        map: map,
        gameState: state,
        models: [model],
        entityId: 'rock',
        x: 1.5,
        z: 1.5,
        facing: EntityFacing.east,
        stateRevision: 4)!;
    final moved = state.copyWith(
        mapInstanceWorldState: state.mapInstanceWorldState.moveFieldObstacle(
            state.mapInstanceWorldState.instanceRef(map.id)!,
            'rock',
            const GridPos(x: 2, y: 2)));
    expect(
        commitSpatialStrengthActivation(
            ticket: ticket,
            map: map,
            gameState: moved,
            models: [model],
            x: 1.5,
            z: 1.5,
            facing: EntityFacing.east,
            currentStateRevision: 4,
            confirmedEntityId: 'rock'),
        isA<FieldObstacleRefused>());
  });

  test(
      'rotated pivot footprints preserve the anchor and catch off-center collisions and borders',
      () {
    final model = ProjectModel3dEntry(
        id: 'boulder',
        name: 'Asymmetric',
        sourceAssetId: 'boulder-source',
        relativePath: 'assets/models3d/boulder.glb',
        pivot: Model3dVector3(x: .2, y: 0, z: .1),
        inspection: Model3dInspection(
            bounds: Model3dBounds(
                min: Model3dVector3(x: -.2, y: 0, z: -.5),
                max: Model3dVector3(x: .2, y: 1, z: .6)),
            meshCount: 1,
            triangleCount: 1));
    final source = strengthMap();
    final map = source.copyWith(
        spatialScene: source.spatialScene!.copyWith(instances: [
      source.spatialScene!.instances.single.copyWith(rotationDegrees: 90)
    ]));
    final state = activeStrength();
    final before = map.toJson(), modelBefore = model.toJson();
    final ticket = pushTicket(map, state, models: [model])!;
    final result =
        push(ticket, map, state, models: [model]) as FieldObstacleApplied;
    expect(map.toJson(), before);
    expect(model.toJson(), modelBefore);
    final pose = spatialFieldObstacleModelPose(
        mapId: map.id,
        entity: map.entities.single,
        instance: map.spatialScene!.instances.single,
        world: result.gameState.mapInstanceWorldState)!;
    final geometry = spatialModelWorldGeometry(
        map.spatialScene!.instances.single, model,
        useCollisionBounds: true, runtimeState: pose);
    expect(geometry.polygon.map((p) => p.x).reduce((a, b) => a < b ? a : b),
        closeTo(2.9, .000001));
    final wall = wallModel();
    final blocked = map.copyWith(
        spatialScene: map.spatialScene!.copyWith(instances: [
      ...map.spatialScene!.instances,
      SpatialModelInstance(
          id: 'off-center',
          modelId: wall.id,
          position: Model3dVector3(x: 3.5, y: 0, z: 1.85))
    ]));
    expect(pushTicket(blocked, state, models: [model, wall]), isNull);
    final edge = map.copyWith(
        entities: [
          map.entities.single.copyWith(pos: const GridPos(x: 4, y: 1))
        ],
        spatialScene: map.spatialScene!.copyWith(instances: [
          map.spatialScene!.instances.single
              .copyWith(position: Model3dVector3(x: 4.5, y: 0, z: 1.5))
        ]));
    final edgeState = state.copyWith(
        playerPosition: const GridPos(x: 3, y: 1),
        playerSpatialPosition: PlayerSpatialPosition(x: 3.5, z: 1.5));
    final large = model.copyWith(pivot: Model3dVector3(x: .2, y: 0, z: -.2));
    expect(pushTicket(edge, edgeState, models: [large]), isNull);
  });

  test(
      'hidden bound occluders and moved target poses use current model geometry',
      () {
    final map = strengthMap().copyWith(
        entities: [
          ...strengthMap().entities,
          const MapEntity(
              id: 'hidden',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 1, y: 1))
        ],
        spatialScene: strengthMap().spatialScene!.copyWith(instances: [
          ...strengthMap().spatialScene!.instances,
          SpatialModelInstance(
              id: 'hidden-model',
              modelId: strengthModel.id,
              entityId: 'hidden',
              position: Model3dVector3(x: 1.95, y: 0, z: 1.5))
        ]));
    final state = activeStrength();
    expect(pushTicket(map, state), isNull);
    expect(pushTicket(map, state, entityIsPresent: (id) => id != 'hidden'),
        isNotNull);
    final clear = strengthMap();
    final applied =
        push(pushTicket(clear, state)!, clear, state) as FieldObstacleApplied;
    expect(
        findSpatialFieldObstacleTarget(
                map: clear,
                gameState: applied.gameState,
                models: [strengthModel],
                x: 2.5,
                z: 1.5,
                facing: EntityFacing.east)
            ?.id,
        'rock');
    expect(
        findSpatialFieldObstacleTarget(
            map: clear,
            gameState: applied.gameState,
            models: [strengthModel],
            x: 1.5,
            z: 1.5,
            facing: EntityFacing.east),
        isNull);
  });
  test('Strength activation rejects models that provide ramps', () {
    final model = strengthModel.copyWith(
        rampProfile: Model3dRampProfile(
            x: 0,
            z: 0,
            width: 1,
            depth: 1,
            lowHeight: 0,
            highHeight: 1,
            direction: SpatialRampDirection.east));
    expect(
        issueSpatialFieldObstacleTicket(
            map: strengthMap(),
            gameState: fixture.ready(FieldAbility.strength),
            models: [model],
            entityId: 'rock',
            x: 1.5,
            z: 1.5,
            facing: EntityFacing.east,
            stateRevision: 4),
        isNull);
  });

  test(
      'live NPC footprints remain blocking when the NPC also owns a bound model',
      () {
    final source = strengthMap();
    final map = source.copyWith(
        entities: [
          ...source.entities,
          const MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 5, y: 3),
              npc: MapEntityNpcData(characterId: 'walker'))
        ],
        spatialScene: source.spatialScene!.copyWith(instances: [
          ...source.spatialScene!.instances,
          SpatialModelInstance(
              id: 'npc-model',
              modelId: strengthModel.id,
              entityId: 'npc',
              position: Model3dVector3(x: 5.5, y: 0, z: 3.5))
        ]));
    final state = activeStrength();
    expect(
        push(pushTicket(map, state)!, map, state,
            actorStateProvider: (_) => SpatialActorRuntimeState(
                x: 3.5, z: 1.5, facing: EntityFacing.south)),
        isA<FieldObstacleRefused>());
  });
  test(
      'hidden lower surfaces do not invalidate an effectively flat upper floor',
      () {
    BorderGroundFootprint footprint(double width, double depth) =>
        BorderGroundFootprint(points: [
          BorderGroundPoint(x: 0, z: 0),
          BorderGroundPoint(x: width, z: 0),
          BorderGroundPoint(x: width, z: depth),
          BorderGroundPoint(x: 0, z: depth)
        ]);
    final upper = SpatialTerrainSurface(
        id: 'upper', x: 0, z: 0, height: 2, footprints: [footprint(6, 4)]);
    final lower = SpatialTerrainSurface(
        id: 'lower', x: 0, z: 0, height: 0, footprints: [footprint(6, 4)]);
    final source = strengthMap();
    MapData map(List<SpatialTerrainSurface> surfaces) => source.copyWith(
            spatialScene: source.spatialScene!.copyWith(
                terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: surfaces),
                instances: [
              source.spatialScene!.instances.single
                  .copyWith(position: Model3dVector3(x: 2.5, y: 2, z: 1.5))
            ]));
    final state = activeStrength();
    expect(pushTicket(map([upper]), state), isNotNull);
    expect(pushTicket(map([lower, upper]), state), isNotNull);
    expect(pushTicket(map([upper, lower]), state), isNotNull);
  });

  test(
      'effective floor coverage catches off-center holes inside a union of flat supports',
      () {
    SpatialTerrainSurface rectangle(
            String id, double x, double z, double width, double depth,
            {double height = 2, double gradientX = 0}) =>
        SpatialTerrainSurface(
            id: id,
            x: x,
            z: z,
            height: height,
            gradientX: gradientX,
            footprints: [
              BorderGroundFootprint(points: [
                BorderGroundPoint(x: 0, z: 0),
                BorderGroundPoint(x: width, z: 0),
                BorderGroundPoint(x: width, z: depth),
                BorderGroundPoint(x: 0, z: depth)
              ])
            ]);
    final lower = rectangle('lower', 0, 0, 6, 4, height: 0, gradientX: .1);
    final source = strengthMap();
    MapData map(List<SpatialTerrainSurface> surfaces) => source.copyWith(
            spatialScene: source.spatialScene!.copyWith(
                terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: surfaces),
                instances: [
              source.spatialScene!.instances.single
                  .copyWith(position: Model3dVector3(x: 2.5, y: 2, z: 1.5))
            ]));
    final supports = [
      lower,
      rectangle('left', 0, 0, 3.1, 4),
      rectangle('right', 3.2, 0, 2.8, 4),
      rectangle('top', 3.1, 0, .1, 1.3),
      rectangle('bottom', 3.1, 1.4, .1, 2.6)
    ];
    expect(map(supports).spatialScene!.worldHeightAt(3.4, 1.5), 2);
    expect(map(supports).spatialScene!.worldHeightAt(3.15, 1.35),
        closeTo(.315, .000001));
    expect(pushTicket(map(supports), activeStrength()), isNull);
    final covered = [...supports, rectangle('fill', 3.1, 1.3, .1, .1)];
    expect(pushTicket(map(covered), activeStrength()), isNotNull);
    expect(pushTicket(map(covered.reversed.toList()), activeStrength()),
        isNotNull);
  });
}
