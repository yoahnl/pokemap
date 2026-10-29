import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'field_obstacle_action_test.dart' as fixture;

MapData traversalMap(
        {FieldAbility ability = FieldAbility.waterfall,
        bool steep = false,
        bool water = true,
        bool requiresSurf = true}) =>
    MapData(
        id: 'route',
        name: 'Route',
        version: ProjectVersion.v9,
        size: const GridSize(width: 6, height: 4),
        spatialScene: MapSpatialScene(width: 6, depth: 4, heightLevels: [
          for (var z = 0; z < 4; z++)
            for (var x = 0; x < 6; x++) steep && x >= 2 ? x - 1 : 0
        ]),
        gameplayZones: [
          MapGameplayZone(
              id: 'passage',
              kind: GameplayZoneKind.fieldAction,
              area: const MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 4, height: 1)),
              fieldAction: FieldActionZonePayload(
                  actionKind: ability == FieldAbility.waterfall
                      ? FieldActionZoneKind.waterfall
                      : FieldActionZoneKind.whirlpool,
                  waterfall: ability == FieldAbility.waterfall
                      ? WaterfallZonePayload(
                          entry: const GridPos(x: 0, y: 0),
                          path: const [
                            GridPos(x: 1, y: 0),
                            GridPos(x: 2, y: 0)
                          ],
                          exit: const GridPos(x: 3, y: 0),
                          direction: MapConnectionDirection.east,
                          requiresSurf: requiresSurf)
                      : null,
                  whirlpool: ability == FieldAbility.whirlpool
                      ? const WhirlpoolZonePayload(
                          entry: GridPos(x: 0, y: 0),
                          path: [GridPos(x: 1, y: 0), GridPos(x: 2, y: 0)],
                          exit: GridPos(x: 3, y: 0),
                          direction: MapConnectionDirection.east)
                      : null)),
          if (water)
            const MapGameplayZone(
                id: 'water',
                kind: GameplayZoneKind.movement,
                area: MapRect(
                    pos: GridPos(x: 0, y: 0),
                    size: GridSize(width: 6, height: 4)),
                movement: MovementZonePayload(requiredMode: MovementMode.surf)),
        ]);

GameState traversalReady({FieldAbility ability = FieldAbility.waterfall}) =>
    fixture.ready(ability).copyWith(
        playerSpatialPosition: PlayerSpatialPosition(x: 1.5, z: 1.5),
        playerMovementMode: MovementMode.surf);

FieldTraversalEvaluation evaluate(MapData map, GameState state,
        {FieldAbility ability = FieldAbility.waterfall,
        ProjectSettings? settings}) =>
    evaluateSpatialFieldTraversalAttempt(
        ability: ability,
        map: map,
        gameState: state,
        models: const [],
        zoneId: 'passage',
        projectSettings: settings);

SpatialFieldTraversalTicket? ticket(MapData map, GameState state,
        {FieldAbility ability = FieldAbility.waterfall}) =>
    issueSpatialFieldTraversalTicket(
        ability: ability,
        map: map,
        gameState: state,
        models: const [],
        zoneId: 'passage',
        stateRevision: 4);

SpatialFieldTraversalStep? plan(
        SpatialFieldTraversalTicket issued, MapData map, GameState state,
        {int index = 0, int revision = 4}) =>
    planSpatialFieldTraversalStep(
        ticket: issued,
        map: map,
        gameState: state,
        models: const [],
        routeIndex: index,
        currentStateRevision: revision);

void main() {
  test('Whirlpool retains the native height of ordinary traversable terrain', () {
    final base = traversalMap(ability: FieldAbility.whirlpool);
    final map = base.copyWith(spatialScene: MapSpatialScene(width: 6, depth: 4, levelHeight: .2,
      heightLevels: [for (var z = 0; z < 4; z++) for (var x = 0; x < 6; x++) x >= 2 ? 1 : 0]));
    final state = traversalReady(ability: FieldAbility.whirlpool);
    validateFieldActionZone(map, map.gameplayZones.first);
    final issued = ticket(map, state, ability: FieldAbility.whirlpool)!;
    final step = plan(issued, map, state)!;
    expect(step.groundYAt(1.75, 1.5), map.spatialScene!.worldHeightAt(1.75, 1.5));
    expect(step.groundYAt(2.125, 1.5), map.spatialScene!.worldHeightAt(2.125, 1.5));
  });
  for (final ability in [FieldAbility.waterfall, FieldAbility.whirlpool]) {
    test(
        '3D ${ability.name} follows every physical route endpoint without consuming PP',
        () {
      final map = traversalMap(
          ability: ability, steep: ability == FieldAbility.waterfall);
      var state = traversalReady(ability: ability);
      final before = state, issued = ticket(map, state, ability: ability)!;
      expect(evaluate(map, state, ability: ability).reason, isNull);
      expect(() => issued.route.add(const GridPos(x: 5, y: 1)),
          throwsUnsupportedError);
      for (var i = 0; i < 3; i++) {
        final step = plan(issued, map, state, index: i, revision: 4 + i)!;
        expect(step.from, state.playerSpatialPosition);
        final result = commitSpatialFieldTraversalStep(
            step: step,
            map: map,
            gameState: state,
            models: const [],
            currentStateRevision: 4 + i);
        state = (result as SpatialFieldTraversalApplied).gameState;
        expect(state.playerPosition, GridPos(x: 2 + i, y: 1));
        expect(state.playerSpatialPosition,
            PlayerSpatialPosition(x: 2.5 + i, z: 1.5));
      }
      expect(state.party, before.party);
      expect(state.playerMovementMode, MovementMode.surf);
      expect(GameState.fromJson(state.toJson()), state);
    });
  }

  test('step permission binds one map and a monotonic canonical segment', () {
    final map = traversalMap(steep: true), state = traversalReady();
    final step = plan(ticket(map, state)!, map, state)!;
    expect(step.permits(map, 1.5, 1.5, 2, 1.5), isTrue);
    expect(step.permits(map, 2, 1.5, 2.5, 1.5), isTrue);
    expect(step.permits(map, 2, 1.5, 1.75, 1.5), isFalse);
    expect(step.permits(map, 1.5, 1.5, 3.5, 1.5), isFalse);
    expect(step.permits(map, 1.5, 1.5, 2, 1.6), isFalse);
    expect(step.permits(map, double.nan, 1.5, 2, 1.5), isFalse);
    expect(
        step.permits(map.copyWith(name: 'changed'), 1.5, 1.5, 2, 1.5), isFalse);
    expect(step.groundYAt(1.5, 1.5), step.fromGroundY);
    expect(step.groundYAt(2, 1.5), (step.fromGroundY + step.toGroundY) / 2);
    expect(step.groundYAt(3, 1.5), step.toGroundY);
  });

  for (final direction in MapConnectionDirection.values) {
    test(
        'native routes preserve ${direction.name} direction and negative-axis interpolation',
        () {
      final horizontal = direction == MapConnectionDirection.east ||
          direction == MapConnectionDirection.west;
      final forward = direction == MapConnectionDirection.east ||
          direction == MapConnectionDirection.south;
      GridPos cell(int index) =>
          horizontal ? GridPos(x: index, y: 0) : GridPos(x: 0, y: index);
      final order = forward ? [0, 1, 2, 3] : [3, 2, 1, 0];
      final base = traversalMap();
      final zone = base.gameplayZones.first.copyWith(
          area: MapRect(
              pos: const GridPos(x: 1, y: 0),
              size: GridSize(
                  width: horizontal ? 4 : 1, height: horizontal ? 1 : 4)),
          fieldAction: FieldActionZonePayload(
              actionKind: FieldActionZoneKind.waterfall,
              waterfall: WaterfallZonePayload(
                  entry: cell(order[0]),
                  path: [cell(order[1]), cell(order[2])],
                  exit: cell(order[3]),
                  direction: direction)));
      final map = base.copyWith(gameplayZones: [zone, base.gameplayZones.last]);
      final route = fieldTraversalRouteCells(zone);
      final facing = switch (direction) {
        MapConnectionDirection.north => EntityFacing.north,
        MapConnectionDirection.south => EntityFacing.south,
        MapConnectionDirection.east => EntityFacing.east,
        MapConnectionDirection.west => EntityFacing.west,
      };
      final state = traversalReady().copyWith(
          playerPosition: route.first,
          playerSpatialPosition: PlayerSpatialPosition(
              x: route.first.x + .5, z: route.first.y + .5),
          playerFacing: facing);
      final step = plan(ticket(map, state)!, map, state)!;
      final midX = (step.from.x + step.to.x) / 2,
          midZ = (step.from.z + step.to.z) / 2;
      expect(step.permits(map, step.from.x, step.from.z, midX, midZ), isTrue);
      expect(step.permits(map, midX, midZ, step.from.x, step.from.z), isFalse);
      expect(
          step.groundYAt(midX, midZ), (step.fromGroundY + step.toGroundY) / 2);
    });
  }

  for (final reason in [
    'move',
    'ko',
    'egg',
    'unlock',
    'surf',
    'direction',
    'position',
    'instance',
    'map',
    'water'
  ]) {
    test('spatial traversal refuses $reason before issuing a ticket', () {
      var map = traversalMap(water: reason != 'water'),
          state = traversalReady();
      final expected = switch (reason) {
        'move' || 'ko' || 'egg' => FieldTraversalBlockReason.missingMove,
        'unlock' => FieldTraversalBlockReason.locked,
        'surf' => FieldTraversalBlockReason.requiresSurf,
        'direction' => FieldTraversalBlockReason.wrongDirection,
        'water' => FieldTraversalBlockReason.requiresWater,
        _ => FieldTraversalBlockReason.invalidTarget,
      };
      switch (reason) {
        case 'move':
          state = state.copyWith(party: const PlayerParty());
        case 'ko':
          state = state.copyWith(
              party: PlayerParty(members: [
            state.party.members.single.copyWith(currentHp: 0)
          ]));
        case 'egg':
          state = state.copyWith(
              party: PlayerParty(
                  members: [state.party.members.single.copyWith(isEgg: true)]));
        case 'unlock':
          state = state.copyWith(progression: const PlayerProgression());
        case 'surf':
          state = state.copyWith(playerMovementMode: MovementMode.walk);
        case 'direction':
          state = state.copyWith(playerFacing: EntityFacing.west);
        case 'position':
          state = state.copyWith(
              playerSpatialPosition: PlayerSpatialPosition(x: 1.25, z: 1.5));
        case 'instance':
          state = state.copyWith(
              mapInstanceWorldState:
                  MapInstanceWorldState(instancesByMapId: const {}));
        case 'map':
          state = state.copyWith(currentMapId: 'other');
      }
      expect(evaluate(map, state).reason, expected);
      expect(ticket(map, state), isNull);
    });
  }

  test('non-Surf Cascade preserves the existing optional Surf contract', () {
    final map = traversalMap(requiresSurf: false, water: false);
    final state =
        traversalReady().copyWith(playerMovementMode: MovementMode.walk);
    expect(evaluate(map, state).reason, isNull);
  });

  test('project ability activation is rechecked before every step and commit',
      () {
    final map = traversalMap(), state = traversalReady();
    final settings = ProjectSettings(
        fieldAbilities: ProjectFieldAbilitiesSettings(
            disabledAbilities: [FieldAbility.waterfall]));
    expect(evaluate(map, state, settings: settings).reason,
        FieldTraversalBlockReason.disabled);
    final issued = ticket(map, state)!;
    final first = plan(issued, map, state)!;
    expect(
        commitSpatialFieldTraversalStep(
            step: first,
            map: map,
            gameState: state,
            models: const [],
            currentStateRevision: 4,
            projectSettings: settings),
        isA<SpatialFieldTraversalRefused>());
    final next = (commitSpatialFieldTraversalStep(
            step: first,
            map: map,
            gameState: state,
            models: const [],
            currentStateRevision: 4) as SpatialFieldTraversalApplied)
        .gameState;
    expect(
        planSpatialFieldTraversalStep(
            ticket: issued,
            map: map,
            gameState: next,
            models: const [],
            routeIndex: 1,
            currentStateRevision: 5,
            projectSettings: settings),
        isNull);
  });

  test(
      'steps cannot skip their committed source endpoint or replay at a different pose',
      () {
    final map = traversalMap(),
        state = traversalReady(),
        issued = ticket(traversalMap(), traversalReady())!;
    expect(plan(issued, map, state, index: 1), isNull);
    expect(plan(issued, map, state, index: -1), isNull);
    expect(plan(issued, map, state, index: 3), isNull);
    expect(plan(issued, map, state, revision: 3), isNull);
    final first = plan(issued, map, state)!;
    final next = (commitSpatialFieldTraversalStep(
            step: first,
            map: map,
            gameState: state,
            models: const [],
            currentStateRevision: 4) as SpatialFieldTraversalApplied)
        .gameState;
    expect(
        commitSpatialFieldTraversalStep(
            step: first,
            map: map,
            gameState: next,
            models: const [],
            currentStateRevision: 4),
        isA<SpatialFieldTraversalRefused>());
  });

  test('Whirlpool cannot borrow Cascade elevation permission', () {
    final map = traversalMap(ability: FieldAbility.whirlpool, steep: true);
    final state = traversalReady(ability: FieldAbility.whirlpool);
    expect(evaluate(map, state, ability: FieldAbility.whirlpool).reason,
        FieldTraversalBlockReason.obstructed);
  });

  test(
      'Cascade model collisions use interpolated elevation across the footprint',
      () {
    final base = traversalMap(steep: true), state = traversalReady();
    for (final elevation in [.025, 1.0, 2.8]) {
      final model = ProjectModel3dEntry(
          id: 'wall',
          name: 'Wall',
          sourceAssetId: 'wall-source',
          relativePath: 'assets/models3d/wall.glb',
          inspection: Model3dInspection(
              bounds: Model3dBounds(
                  min: Model3dVector3(x: -.001, y: elevation, z: -.1),
                  max: Model3dVector3(x: .001, y: elevation + .025, z: .1)),
              meshCount: 1,
              triangleCount: 1));
      final map = base.copyWith(
          spatialScene: MapSpatialScene(
              width: 6,
              depth: 4,
              heightLevels: base.spatialScene!.heightLevels,
              instances: [
            SpatialModelInstance(
                id: 'wall-instance',
                modelId: 'wall',
                position: Model3dVector3(x: 1.99, y: 0, z: 1.5))
          ]));
      final result = evaluateSpatialFieldTraversalAttempt(
          ability: FieldAbility.waterfall,
          map: map,
          gameState: state,
          models: [model],
          zoneId: 'passage');
      expect(result.reason,
          elevation == 1 ? FieldTraversalBlockReason.obstructed : isNull,
          reason: 'wall elevation $elevation');
    }
  });

  test('a blocked exit rejects the whole traversal before it starts', () {
    final map = traversalMap().copyWith(entities: const [
      MapEntity(
          id: 'blocker', kind: MapEntityKind.custom, pos: GridPos(x: 4, y: 1))
    ]);
    expect(evaluate(map, traversalReady()).reason,
        FieldTraversalBlockReason.obstructed);
  });

  test(
      'step commit rejects stale revisions, changed gates, changed maps and source pose',
      () {
    final map = traversalMap(), state = traversalReady();
    final step = plan(ticket(map, state)!, map, state)!;
    for (final check in [
      (map, state, 5, FieldActionRefusal.staleStateRevision),
      (
        map.copyWith(name: 'changed'),
        state,
        4,
        FieldActionRefusal.targetChanged
      ),
      (
        map,
        state.copyWith(
            playerSpatialPosition: PlayerSpatialPosition(x: 1.25, z: 1.5)),
        4,
        FieldActionRefusal.targetChanged
      ),
      (
        map,
        state.copyWith(progression: const PlayerProgression()),
        4,
        FieldActionRefusal.noLongerAvailable
      ),
    ]) {
      final result = commitSpatialFieldTraversalStep(
          step: step,
          map: check.$1,
          gameState: check.$2,
          models: const [],
          currentStateRevision: check.$3);
      expect((result as SpatialFieldTraversalRefused).refusal, check.$4);
    }
  });

  test('a live actor obstructing a previously valid step prevents its commit',
      () {
    final map = traversalMap().copyWith(entities: const [
      MapEntity(
          id: 'blocker', kind: MapEntityKind.npc, pos: GridPos(x: 5, y: 2))
    ]);
    final state = traversalReady(),
        step = plan(ticket(map, traversalReady())!, map, traversalReady())!;
    final result = commitSpatialFieldTraversalStep(
        step: step,
        map: map,
        gameState: state,
        models: const [],
        currentStateRevision: 4,
        actorStateProvider: (_) => SpatialActorRuntimeState(
            x: 2.5, z: 1.5, facing: EntityFacing.south));
    expect(result, isA<SpatialFieldTraversalRefused>());
  });
}
