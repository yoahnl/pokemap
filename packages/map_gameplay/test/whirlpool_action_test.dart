import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/moving_platform_fixture.dart';
import 'support/moving_prop_fixture.dart';

MapGameplayZone whirlpoolZone() => MapGameplayZone.fromJson(jsonDecode(
    File('../map_core/test/fixtures/whirlpool_field_zone.json')
        .readAsStringSync()) as Map<String, dynamic>);

MapData whirlpoolMap({bool water = true}) => MapData(
        id: 'whirls',
        name: 'Whirls',
        size: const GridSize(width: 8, height: 8),
        gameplayZones: [
          whirlpoolZone(),
          if (water)
            const MapGameplayZone(
                id: 'water',
                kind: GameplayZoneKind.movement,
                area: MapRect(
                    pos: GridPos(x: 0, y: 0),
                    size: GridSize(width: 8, height: 8)),
                movement: MovementZonePayload(requiredMode: MovementMode.surf)),
        ]);

GameState whirlpoolReady() => const GameState(
    saveId: 'whirlpool',
    currentMapId: 'whirls',
    playerPosition: GridPos(x: 2, y: 4),
    playerFacing: EntityFacing.north,
    playerMovementMode: MovementMode.surf,
    party: PlayerParty(members: [
      PlayerPokemon(
          speciesId: 'totodile',
          natureId: 'hardy',
          abilityId: 'torrent',
          level: 20,
          currentHp: 30,
          knownMoveIds: ['whirlpool'],
          currentPpByMoveId: {'whirlpool': 0})
    ]),
    progression:
        PlayerProgression(unlockedFieldAbilities: [FieldAbility.whirlpool]));

GameplayWorldState whirlpoolWorld(MapData map, GameState state) =>
    GameplayWorldState.initial(
      map: map,
      playerPos: state.playerPosition,
      playerFacing: state.playerFacing.asDirection,
      playerMovementMode: state.playerMovementMode,
    );

void main() {
  for (final obstacle in ['prop', 'platform']) {
    for (final onRoute in [false, true]) {
      for (final waterfall in [false, true]) {
        test(
            'fallback keeps saved $obstacle ${onRoute ? 'on' : 'off'} route for ${waterfall ? 'Cascade' : 'Whirlpool'}',
            () {
          final (map, project, authoredState) =
              _savedObstacleScene(obstacle, onRoute);
          final ability =
              waterfall ? FieldAbility.waterfall : FieldAbility.whirlpool;
          final source = map.gameplayZones.first;
          final selected = waterfall
              ? map.copyWith(gameplayZones: [
                  source.copyWith(
                      fieldAction: FieldActionZonePayload(
                          actionKind: FieldActionZoneKind.waterfall,
                          waterfall: WaterfallZonePayload(
                              entry: source.fieldAction!.whirlpool!.entry,
                              path: source.fieldAction!.whirlpool!.path,
                              exit: source.fieldAction!.whirlpool!.exit,
                              direction:
                                  source.fieldAction!.whirlpool!.direction))),
                  ...map.gameplayZones.skip(1),
                ])
              : map;
          final state = gameStateFromStrictSaveJson(
              strictGameStateSaveJson(authoredState.copyWith(
            party: PlayerParty(members: [
              authoredState.party.members.single.copyWith(
                  knownMoveIds: [ability.moveId],
                  currentPpByMoveId: {ability.moveId: 0})
            ]),
            progression: PlayerProgression(unlockedFieldAbilities: [ability]),
          )));
          final live = GameplayWorldState.initial(
              map: selected,
              project: project,
              gameState: state,
              movingPlatformWorldState: state.movingPlatformWorldState,
              playerPos: state.playerPosition,
              playerFacing: state.playerFacing.asDirection,
              playerMovementMode: state.playerMovementMode);
          final expected = (obstacle == 'prop' ? onRoute : !onRoute)
              ? FieldTraversalBlockReason.obstructed
              : null;
          for (final world in [live, null]) {
            expect(
                evaluateFieldTraversalAttempt(
                        ability: ability,
                        kind: waterfall
                            ? FieldActionZoneKind.waterfall
                            : FieldActionZoneKind.whirlpool,
                        map: selected,
                        gameState: state,
                        zoneId: source.id,
                        project: project,
                        world: world)
                    .reason,
                expected,
                reason: world == null ? 'saved fallback' : 'live world');
          }
        });
      }
    }
  }
  test('ordinary forced player movement cannot cross a Whirlpool body', () {
    final state = whirlpoolReady(), map = whirlpoolMap();
    expect(
        planActorRouteMove(
            world: whirlpoolWorld(map, state),
            target: SceneActorTarget.player(mapId: map.id),
            direction: EntityFacing.north,
            through: false),
        isNull);
  });

  test(
      'Whirlpool traverses the finite canonical water route while retaining Surf and PP',
      () {
    final state = whirlpoolReady(), map = whirlpoolMap();
    final result = evaluateWhirlpoolAttempt(
        map: map, gameState: state, zoneId: 'whirlpool') as CanUseWhirlpool;
    expect(result.cells,
        const [GridPos(x: 2, y: 3), GridPos(x: 2, y: 2), GridPos(x: 2, y: 1)]);
    var world = whirlpoolWorld(map, state);
    for (final cell in result.cells) {
      final plan = planActorRouteMove(
          world: world,
          target: SceneActorTarget.player(mapId: map.id),
          direction: EntityFacing.north,
          through: false,
          fieldTraversalZone: map.gameplayZones.first)!;
      expect(plan.to, cell);
      world = world.withPlayer(plan.playerState!);
      expect(world.player.movementMode, MovementMode.surf);
    }
    expect(state.party.members.single.currentPpByMoveId!['whirlpool'], 0);
    expect(world.map.gameplayZones, map.gameplayZones);
  });

  for (final failure in [
    'land',
    'walk',
    'move',
    'fainted',
    'unlock',
    'direction',
    'wall',
    'npc',
    'reservation',
    'dynamic'
  ]) {
    test('Whirlpool explicitly refuses $failure before any traversal commits',
        () {
      var state = whirlpoolReady();
      var map = whirlpoolMap(water: failure != 'land');
      var expected = WhirlpoolBlockReason.obstructed;
      switch (failure) {
        case 'land':
          expected = WhirlpoolBlockReason.requiresWater;
        case 'walk':
          state = state.copyWith(playerMovementMode: MovementMode.walk);
          expected = WhirlpoolBlockReason.requiresSurf;
        case 'move':
          state = state.copyWith(party: const PlayerParty());
          expected = WhirlpoolBlockReason.missingMove;
        case 'fainted':
          state = state.copyWith(
              party: PlayerParty(members: [
            state.party.members.single.copyWith(currentHp: 0)
          ]));
          expected = WhirlpoolBlockReason.missingMove;
        case 'unlock':
          state = state.copyWith(progression: const PlayerProgression());
          expected = WhirlpoolBlockReason.locked;
        case 'direction':
          state = state.copyWith(playerFacing: EntityFacing.south);
          expected = WhirlpoolBlockReason.wrongDirection;
        case 'wall':
          map = map.copyWith(layers: [
            MapLayer.collision(
                id: 'wall',
                name: 'Wall',
                collisions: List.generate(64, (i) => i == 10))
          ]);
        case 'npc':
          map = map.copyWith(entities: const [
            MapEntity(
                id: 'block',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 2, y: 1),
                npc: MapEntityNpcData())
          ]);
      }
      final before = state.toJson();
      final result = evaluateWhirlpoolAttempt(
          map: map,
          gameState: state,
          zoneId: 'whirlpool',
          dynamicBlockedCells:
              failure == 'dynamic' ? const [GridPos(x: 2, y: 1)] : const [],
          characterReservations: failure == 'reservation'
              ? const [
                  PixelRect(leftPx: 40, topPx: 30, widthPx: 1, heightPx: 1)
                ]
              : const []);
      expect((result as WhirlpoolUnavailable).reason, expected);
      expect(state.toJson(), before);
    });
  }

  test(
      'native badge unlock survives strict save without hardcoded source badges',
      () {
    var state =
        whirlpoolReady().copyWith(progression: const PlayerProgression());
    const badge = BadgeDefinition(
        id: 'native-whirl',
        label: 'Native Whirl',
        fieldAbilityUnlock: FieldAbility.whirlpool);
    state = const GameStateMutations().applyBattleRewards(state,
        reward: BattleReward(
            sourceKind: BattleRewardSourceKind.trainer,
            trainerId: 'guard',
            badgeId: badge.id,
            fieldAbilityUnlock: badge.fieldAbilityUnlock));
    expect(state.trainerProfile.badgeIds, contains('native-whirl'));
    final restored =
        gameStateFromStrictSaveJson(strictGameStateSaveJson(state));
    expect(
        evaluateWhirlpoolAttempt(
            map: whirlpoolMap(), gameState: restored, zoneId: 'whirlpool'),
        isA<CanUseWhirlpool>());
  });

  test(
      'Whirlpool tickets refuse stale state, replaced instances, moved players and changed routes',
      () {
    final state = whirlpoolReady(), map = whirlpoolMap();
    final ticket = WhirlpoolActionTicket(
        fieldAction: FieldActionTicket(
            ability: FieldAbility.whirlpool,
            targetCell: state.playerPosition,
            issuedAtStateRevision: 3),
        zone: map.gameplayZones.first,
        entryState: state,
        instance: null);
    expect(
        validateWhirlpoolTicket(
            ticket: ticket,
            map: map,
            gameState: state,
            currentStateRevision: 4),
        FieldActionRefusal.staleStateRevision);
    expect(
        validateWhirlpoolTicket(
            ticket: ticket,
            map: map,
            gameState:
                state.copyWith(playerPosition: const GridPos(x: 2, y: 3)),
            currentStateRevision: 3),
        FieldActionRefusal.targetChanged);
    expect(
        validateWhirlpoolTicket(
            ticket: ticket,
            map: map.copyWith(gameplayZones: []),
            gameState: state,
            currentStateRevision: 3),
        FieldActionRefusal.targetChanged);
    final replaced = state.copyWith(
        mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
      'whirls': MapInstanceRuntimeState(instanceId: 'new')
    }));
    expect(
        validateWhirlpoolTicket(
            ticket: ticket,
            map: map,
            gameState: replaced,
            currentStateRevision: 3),
        FieldActionRefusal.targetChanged);
  });

  test(
      'Whirlpool permission is bound to one next route cell and rejects arbitrary bypass',
      () {
    final state = whirlpoolReady(), map = whirlpoolMap();
    final world = whirlpoolWorld(map, state);
    for (final direction in [
      EntityFacing.south,
      EntityFacing.east,
      EntityFacing.west
    ]) {
      expect(
          planActorRouteMove(
              world: world,
              target: SceneActorTarget.player(mapId: map.id),
              direction: direction,
              through: false,
              fieldTraversalZone: map.gameplayZones.first),
          isNull);
    }
    expect(
        planActorRouteMove(
            world: world,
            target: SceneActorTarget.player(mapId: map.id),
            direction: EntityFacing.north,
            through: true,
            fieldTraversalZone: map.gameplayZones.first),
        isNull);
  });
}

(MapData, ProjectManifest, GameState) _savedObstacleScene(
    String obstacle, bool onRoute) {
  final base = whirlpoolMap();
  if (obstacle == 'prop') {
    final fixture = MovingPropFixture(props: [
      MovingPropFixture.prop(
          'gate', onRoute ? 80 : 32, 32, onRoute ? 32 : 80, 32,
          width: 16, height: 16)
    ]);
    final map = base.copyWith(
        layers: fixture.map.layers,
        placedElements: fixture.map.placedElements,
        movingProps: fixture.map.movingProps);
    return (
      map,
      fixture.project.copyWith(
          settings: const ProjectSettings(tileWidth: 16, tileHeight: 16)),
      whirlpoolReady().copyWith(
          movingPropWorldState: const MovingPropWorldState.empty().withProp(
              mapId: base.id, propId: 'gate', state: MovingPropState.open))
    );
  }
  final fixture = MovingPlatformFixture();
  final definition = MovingPlatformDefinition.fromJson({
    ...fixture.definition.toJson(),
    'initialPose': {
      'leftPx': onRoute ? 80 : 32,
      'topPx': 32,
      'quarterTurns': 0
    },
    'lattice': {
      'widthPx': 16,
      'heightPx': 16,
      'originLeftPx': 0,
      'originTopPx': 0,
      'cellOffsetLeftPx': 0,
      'cellOffsetTopPx': 0
    },
    'travelCells': [
      for (var x = 2; x <= 5; x++) {'x': x, 'y': 2}
    ],
    'variants': [
      for (final variant in fixture.definition.variants)
        {
          ...variant.toJson(),
          'anchorOffsetPx': {'x': 0, 'y': 0}
        }
    ],
  });
  final map = base.copyWith(
      movingPlatforms: [definition],
      placedElements: fixture.map.placedElements,
      layers: [
        MapLayer.tile(
            id: 'magma',
            name: 'Magma',
            palette: const [
              TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 0)
            ],
            cells: List.generate(64, (index) => index == 18 ? 1 : 0))
      ]);
  final state = const MovingPlatformWorldState.empty().withPlatform(
      mapId: base.id,
      platformId: 'bridge',
      pose: MovingPlatformPose(
          leftPx: onRoute ? 32 : 80, topPx: 32, quarterTurns: 0));
  return (
    map,
    fixture.project.copyWith(
        settings: const ProjectSettings(tileWidth: 16, tileHeight: 16)),
    whirlpoolReady().copyWith(movingPlatformWorldState: state)
  );
}
