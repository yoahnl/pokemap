import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'field_obstacle_action_test.dart' as fixture;

void main() {
  final model = ProjectModel3dEntry(
      id: 'tree',
      name: 'Tree',
      sourceAssetId: 'tree-source',
      relativePath: 'assets/models3d/tree.glb',
      inspection: Model3dInspection(
          bounds: Model3dBounds(
              min: Model3dVector3(x: -.3, y: 0, z: -.3),
              max: Model3dVector3(x: .3, y: 2, z: .3)),
          meshCount: 1,
          triangleCount: 1));
  for (final kind in [
    FieldObstacleKind.cutTree,
    FieldObstacleKind.rockSmashRock
  ]) {
    final ability = MapEntityFieldObstacleData(kind: kind).ability!;
    final source = fixture.obstacleMap(kind).copyWith(
        version: ProjectVersion.v9,
        spatialScene: MapSpatialScene(width: 6, depth: 4, instances: [
          SpatialModelInstance(
              id: 'tree-instance',
              modelId: model.id,
              entityId: 'rock',
              position: Model3dVector3(x: 2.5, y: 0, z: 1.5))
        ]));
    final state = fixture.ready(ability);
    test('$kind hidden bound models stop occluding the target', () {
      final map = source.copyWith(
          entities: [
            ...source.entities,
            const MapEntity(
                id: 'hidden',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 2, y: 1))
          ],
          spatialScene: source.spatialScene!.copyWith(instances: [
            ...source.spatialScene!.instances,
            SpatialModelInstance(
                id: 'hidden-instance',
                modelId: model.id,
                entityId: 'hidden',
                position: Model3dVector3(x: 2, y: 0, z: 1.5))
          ]));
      expect(
          findSpatialFieldObstacleTarget(
              map: map,
              gameState: state,
              models: [model],
              x: 1.5,
              z: 1.5,
              facing: EntityFacing.east),
          isNull);
      expect(
          findSpatialFieldObstacleTarget(
              map: map,
              gameState: state,
              models: [model],
              x: 1.5,
              z: 1.5,
              facing: EntityFacing.east,
              entityIsPresent: (id) => id != 'hidden')?.id,
          'rock');
    });
    test(
        '$kind ignores spawn markers and hidden blockers but never targets hidden obstacles',
        () {
      final map = source.copyWith(entities: [
        ...source.entities,
        const MapEntity(
            id: 'start',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 1, y: 1),
            spawn: MapEntitySpawnData()),
        const MapEntity(
            id: 'walker',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 1, y: 1),
            npc: MapEntityNpcData(characterId: 'walker'))
      ]);
      expect(
          findSpatialFieldObstacleTarget(
              map: map,
              gameState: state,
              models: [model],
              x: 1.5,
              z: 1.5,
              facing: EntityFacing.east,
              entityIsPresent: (id) => id != 'walker')?.id,
          'rock');
      expect(
          findSpatialFieldObstacleTarget(
              map: map,
              gameState: state,
              models: [model],
              x: 1.5,
              z: 1.5,
              facing: EntityFacing.east,
              entityIsPresent: (id) => id != 'rock'),
          isNull);
    });
    test('$kind uses live actor poses to block the action ray', () {
      final map = source.copyWith(entities: [
        ...source.entities,
        const MapEntity(
            id: 'walker',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 5, y: 3),
            npc: MapEntityNpcData(characterId: 'walker'))
      ]);
      expect(
          findSpatialFieldObstacleTarget(
                  map: map,
                  gameState: state,
                  models: [model],
                  x: 1.5,
                  z: 1.5,
                  facing: EntityFacing.east)
              ?.id,
          'rock');
      expect(
          findSpatialFieldObstacleTarget(
              map: map,
              gameState: state,
              models: [model],
              x: 1.5,
              z: 1.5,
              facing: EntityFacing.east,
              actorStateProvider: (_) => SpatialActorRuntimeState(
                  x: 2, z: 1.5, facing: EntityFacing.west)),
          isNull);
    });
    SpatialFieldObstacleTicket issue() => issueSpatialFieldObstacleTicket(
        map: source,
        gameState: state,
        models: [model],
        entityId: 'rock',
        x: 1.5,
        z: 1.5,
        facing: EntityFacing.east,
        stateRevision: 4)!;
    FieldObstacleCommit commit(SpatialFieldObstacleTicket ticket,
            {MapData? map,
            GameState? current,
            double x = 1.5,
            int revision = 4,
            EntityFacing facing = EntityFacing.east}) =>
        commitSpatialDestructibleFieldObstacleAction(
            ticket: ticket,
            map: map ?? source,
            gameState: current ?? state,
            models: [model],
            x: x,
            z: 1.5,
            facing: facing,
            currentStateRevision: revision,
            confirmedEntityId: 'rock');
    test('$kind commits once without modifying source map', () {
      final ticket = issue();
      final result = commit(ticket) as FieldObstacleApplied;
      expect(
          result.gameState.mapInstanceWorldState
              .isFieldObstacleCleared(ticket.instance, 'rock'),
          isTrue);
      expect(commit(ticket, current: result.gameState),
          isA<FieldObstacleRefused>());
      expect(source.entities, hasLength(1));
      expect(source.spatialScene!.instances, hasLength(1));
    });
    test('$kind revalidates revision pose facing permission and model', () {
      final ticket = issue();
      for (final result in [
        commit(ticket, revision: 5),
        commit(ticket, x: 1.51),
        commit(ticket, facing: EntityFacing.north),
        commit(ticket,
            current: state.copyWith(progression: const PlayerProgression())),
        commit(ticket, current: state.copyWith(party: const PlayerParty())),
        commit(ticket,
            current: state.copyWith(
                spatialWorldState: state.spatialWorldState.setModelState(
                    'route',
                    'tree-instance',
                    SpatialModelRuntimeState(
                        modelId: model.id,
                        animationIndex: null,
                        normalizedTime: 0,
                        blocksMovement: false)))),
        commit(ticket,
            map: source.copyWith(
                spatialScene: source.spatialScene!.copyWith(instances: [
              source.spatialScene!.instances.single.copyWith(scale: 2)
            ]))),
      ]) {
        expect(result, isA<FieldObstacleRefused>());
      }
    });
    test('$kind rejects canonical GameState pose changes at the same revision',
        () {
      final ticket = issue();
      for (final changed in [
        state.copyWith(playerPosition: const GridPos(x: 2, y: 1)),
        state.copyWith(playerPixelPosition: const PixelOffset(x: 1, y: 0)),
        state.copyWith(
            playerSpatialPosition: PlayerSpatialPosition(x: 1.5, z: 1.5)),
      ]) {
        expect(commit(ticket, current: changed), isA<FieldObstacleRefused>());
      }
      expect(
          evaluateSpatialFieldObstacleAttempt(
              map: source,
              gameState: state,
              models: [model],
              entityId: 'rock',
              x: 1.51,
              z: 1.5,
              facing: EntityFacing.east),
          isA<FieldObstacleUnavailable>());
    });
    test(
        '$kind captures grid and pixel pose even with an explicit spatial pose',
        () {
      final positioned = state.copyWith(
          playerSpatialPosition: PlayerSpatialPosition(x: 1.6, z: 1.5),
          playerPixelPosition: const PixelOffset(x: 16, y: 16));
      final ticket = issueSpatialFieldObstacleTicket(
          map: source,
          gameState: positioned,
          models: [model],
          entityId: 'rock',
          x: 1.6,
          z: 1.5,
          facing: EntityFacing.east,
          stateRevision: 4)!;
      expect(commit(ticket, current: positioned, x: 1.6),
          isA<FieldObstacleApplied>());
      for (final changed in [
        positioned.copyWith(playerPosition: const GridPos(x: 2, y: 1)),
        positioned.copyWith(
            playerPixelPosition: const PixelOffset(x: 17, y: 16)),
        positioned.copyWith(playerSpatialPosition: null),
      ]) {
        expect(commit(ticket, current: changed, x: 1.6),
            isA<FieldObstacleRefused>());
      }
    });
    test('$kind refuses wall range and ambiguous binding', () {
      final wall = SpatialModelInstance(
          id: 'wall',
          modelId: model.id,
          position: Model3dVector3(x: 1.95, y: 0, z: 1.5));
      for (final map in [
        source.copyWith(
            spatialScene: source.spatialScene!.copyWith(
                instances: [...source.spatialScene!.instances, wall])),
        source.copyWith(
            spatialScene: source.spatialScene!.copyWith(instances: [
          ...source.spatialScene!.instances,
          SpatialModelInstance(
              id: 'duplicate',
              modelId: model.id,
              entityId: 'rock',
              position: Model3dVector3(x: 2.5, y: 0, z: 1.5))
        ])),
      ]) {
        expect(
            evaluateSpatialFieldObstacleAttempt(
                map: map,
                gameState: state,
                models: [model],
                entityId: 'rock',
                x: 1.5,
                z: 1.5,
                facing: EntityFacing.east),
            isA<FieldObstacleUnavailable>());
      }
      expect(
          evaluateSpatialFieldObstacleAttempt(
              map: source,
              gameState: state,
              models: [model],
              entityId: 'rock',
              x: .5,
              z: 1.5,
              facing: EntityFacing.east),
          isA<FieldObstacleUnavailable>());
    });
    test('$kind refuses a live NPC moved into the interaction path', () {
      final withNpc = source.copyWith(entities: [
        ...source.entities,
        const MapEntity(
            id: 'npc',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 4, y: 2),
            npc: MapEntityNpcData(displayName: 'Walker'))
      ]);
      final current = state.copyWith(
          spatialWorldState: state.spatialWorldState.setActorState(
              'route',
              'npc',
              SpatialActorRuntimeState(
                  x: 1.9, z: 1.5, facing: EntityFacing.south)));
      expect(
          evaluateSpatialFieldObstacleAttempt(
              map: withNpc,
              gameState: current,
              models: [model],
              entityId: 'rock',
              x: 1.5,
              z: 1.5,
              facing: EntityFacing.east),
          isA<FieldObstacleUnavailable>());
    });
  }
  test(
      'persistent clearing survives lifecycle and serialization without leaking IDs',
      () {
    var state = fixture.ready(FieldAbility.cut).mapInstanceWorldState;
    final first = state.instanceRef('route')!;
    state = state.clearFieldObstacle(first, 'rock',
        resetPolicy: FieldObstacleResetPolicy.persistent);
    state = setupDifferentMapInstance(
        state: state, targetMapId: 'other', allocateId: (_) => 'other-1');
    expect(state.isFieldObstacleCleared(state.instanceRef('other')!, 'rock'),
        isFalse);
    state = MapInstanceWorldState.fromJson(state.toJson());
    state = setupDifferentMapInstance(
        state: state, targetMapId: 'route', allocateId: (_) => 'route-2');
    expect(state.isFieldObstacleCleared(state.instanceRef('route')!, 'rock'),
        isTrue);
    expect(() => state.clearFieldObstacle(first, 'rock'), throwsStateError);
    expect(const MapInstanceWorldState.empty().persistentClearedObstacles,
        isEmpty);
    expect(state.toJson()['schemaVersion'], 7);
    expect(const MapInstanceWorldState.empty().toJson(),
        {'schemaVersion': 6, 'instancesByMapId': {}});
  });
  test('3D validation requires a single static bound model and rejects Ice',
      () {
    MapData map(FieldObstacleKind kind, List<SpatialModelInstance> instances) =>
        fixture.obstacleMap(kind).copyWith(
            version: ProjectVersion.v9,
            spatialScene:
                MapSpatialScene(width: 6, depth: 4, instances: instances));
    final bound = SpatialModelInstance(
        id: 'bound',
        modelId: model.id,
        entityId: 'rock',
        position: Model3dVector3(x: 2.5, y: 0, z: 1.5));
    expect(() => MapValidator.validate(map(FieldObstacleKind.cutTree, [bound])),
        returnsNormally);
    expect(
        () => MapValidator.validate(
            map(FieldObstacleKind.strengthBoulder, [bound])),
        returnsNormally);
    for (final bad in [
      map(FieldObstacleKind.cutTree, []),
      map(FieldObstacleKind.cutTree, [bound.copyWith(animationIndex: 0)]),
      map(FieldObstacleKind.iceBlock, [bound]),
    ]) {
      expect(() => MapValidator.validate(bad),
          throwsA(isA<ValidationException>()));
    }
  });
  test('cleared bound models stop occluding the next destructible target', () {
    final state = fixture.ready(FieldAbility.cut);
    final map = fixture.obstacleMap(FieldObstacleKind.cutTree).copyWith(
        version: ProjectVersion.v9,
        entities: [
          ...fixture.obstacleMap(FieldObstacleKind.cutTree).entities,
          const MapEntity(
              id: 'near',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 1, y: 1),
              fieldObstacle: MapEntityFieldObstacleData()),
        ],
        spatialScene: MapSpatialScene(width: 6, depth: 4, instances: [
          SpatialModelInstance(
              id: 'far-model',
              modelId: model.id,
              entityId: 'rock',
              position: Model3dVector3(x: 2.5, y: 0, z: 1.5)),
          SpatialModelInstance(
              id: 'near-model',
              modelId: model.id,
              entityId: 'near',
              position: Model3dVector3(x: 1.6, y: 0, z: 1.5)),
        ]));
    MapEntity? find(GameState current) => findSpatialFieldObstacleTarget(
        map: map,
        gameState: current,
        models: [model],
        x: 1,
        z: 1.5,
        facing: EntityFacing.east);
    expect(find(state)?.id, 'near');
    final cleared = state.copyWith(
        mapInstanceWorldState: state.mapInstanceWorldState.clearFieldObstacle(
            state.mapInstanceWorldState.instanceRef('route')!, 'near'));
    expect(find(cleared)?.id, 'rock');
    expect(map.spatialScene!.instances, hasLength(2));
  });
  for (final kind in [
    FieldObstacleKind.cutTree,
    FieldObstacleKind.rockSmashRock
  ]) {
    test(
        '2D $kind persistent commit survives save and reentry with source immutable',
        () {
      final ability = MapEntityFieldObstacleData(kind: kind).ability!;
      final before = fixture.ready(ability);
      final authored = fixture.obstacleMap(kind).copyWith(entities: [
        fixture.obstacleMap(kind).entities.single.copyWith(
            fieldObstacle: MapEntityFieldObstacleData(
                kind: kind, resetPolicy: FieldObstacleResetPolicy.persistent))
      ]);
      final result = commitDestructibleFieldObstacleAction(
          ticket: fixture.ticket(before, ability),
          map: authored,
          gameState: before,
          currentStateRevision: 4,
          confirmedEntityId: 'rock') as FieldObstacleApplied;
      final saved = GameState.fromJson(result.gameState.toJson());
      var instances = setupDifferentMapInstance(
          state: saved.mapInstanceWorldState,
          targetMapId: 'elsewhere',
          allocateId: (_) => 'elsewhere-1');
      instances = setupDifferentMapInstance(
          state: instances, targetMapId: 'route', allocateId: (_) => 'route-2');
      final projected = applyFieldObstacleWorldStateToMap(
          map: authored,
          instances: instances,
          instance: instances.instanceRef('route')!);
      expect(projected.entities, isEmpty);
      expect(authored.entities, hasLength(1));
      expect(before.mapInstanceWorldState.persistentClearedObstacles, isEmpty);
      expect(() => instances.persistentClearedObstacles['route']!.clear(),
          throwsUnsupportedError);
    });
  }
  test('persistent state survives all setters and retained-map lifecycle', () {
    var state = fixture.ready(FieldAbility.cut).mapInstanceWorldState;
    final scope = state.instanceRef('route')!;
    state = state
        .clearFieldObstacle(scope, 'persistent',
            resetPolicy: FieldObstacleResetPolicy.persistent)
        .clearFieldObstacle(scope, 'local')
        .setEventBoolean(scope, 'event', 'A', true)
        .activateStrength(scope)
        .moveFieldObstacle(scope, 'boulder', const GridPos(x: 3, y: 1))
        .illuminateZone(scope, 'dark')
        .consumeInteractiveEncounter(scope, 'encounter')
        .setNpcPoses(scope, {
      'npc': MapInstanceNpcPose(
          position: const GridPos(x: 1, y: 2), facing: EntityFacing.south)
    });
    state = retainMapInstance(
        state: state, mapId: 'neighbor', allocateId: (_) => 'neighbor-1');
    state = updateMapInstanceRetention(
        state: state,
        activeMap: MapInstanceMapGeometry(
            mapId: 'neighbor',
            originTiles: const GridPos(x: 0, y: 0),
            sizeTiles: const GridSize(width: 6, height: 4)),
        directConnectedMaps: [],
        logicalViewport: MapInstanceLogicalViewport(leftTiles: 0, topTiles: 0),
        policy: MapInstanceRetentionPolicy(
            viewportWidthTiles: 6, viewportHeightTiles: 4, marginTiles: 1),
        settled: true,
        allocateId: (_) => 'unused');
    expect(state.instancesByMapId, isNot(contains('route')));
    state = retainMapInstance(
        state: state, mapId: 'route', allocateId: (_) => 'route-2');
    final current = state.instanceRef('route')!;
    expect(state.isFieldObstacleCleared(current, 'persistent'), isTrue);
    expect(state.isFieldObstacleCleared(current, 'local'), isFalse);
    expect(state.instancesByMapId['route']!.fieldObstaclePositions, isEmpty);
    expect(() => state.isFieldObstacleCleared(scope, 'persistent'),
        throwsStateError);
  });
}
