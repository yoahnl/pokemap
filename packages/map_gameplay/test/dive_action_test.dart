import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData diveMap(String id, DiveZoneRole role, {bool linked = true}) => MapData(
        id: id,
        name: id,
        size: const GridSize(width: 6, height: 6),
        entities: [
          MapEntity(
              id: '$id-spawn',
              kind: MapEntityKind.spawn,
              pos: const GridPos(x: 2, y: 2),
              spawn: const MapEntitySpawnData())
        ],
        gameplayZones: [
          MapGameplayZone(
              id: 'terrain',
              kind: GameplayZoneKind.movement,
              area: const MapRect(
                  pos: GridPos(x: 1, y: 1),
                  size: GridSize(width: 4, height: 4)),
              movement: MovementZonePayload(
                  requiredMode: role == DiveZoneRole.surface
                      ? MovementMode.surf
                      : MovementMode.dive)),
          MapGameplayZone(
              id: 'point',
              kind: GameplayZoneKind.fieldAction,
              area: const MapRect(
                  pos: GridPos(x: 2, y: 2),
                  size: GridSize(width: 1, height: 1)),
              fieldAction: FieldActionZonePayload(
                  actionKind: FieldActionZoneKind.dive,
                  dive: DiveZonePayload(
                      role: role,
                      arrivalSpawnId: '$id-spawn',
                      link: linked
                          ? DiveZoneLink(
                              mapId: id == 'sea' ? 'deep' : 'sea',
                              zoneId: 'point')
                          : null))),
        ]);
GameState diveReady({bool underwater = false}) => GameState(
    saveId: 'dive',
    currentMapId: underwater ? 'deep' : 'sea',
    playerPosition: const GridPos(x: 2, y: 2),
    playerMovementMode: underwater ? MovementMode.dive : MovementMode.surf,
    party: const PlayerParty(members: [
      PlayerPokemon(
          speciesId: 'pikachu',
          natureId: 'hardy',
          abilityId: 'static',
          level: 20,
          currentHp: 30,
          knownMoveIds: ['dive'],
          currentPpByMoveId: {'dive': 0})
    ]),
    progression:
        const PlayerProgression(unlockedFieldAbilities: [FieldAbility.dive]));
void main() {
  test(
      'explicit Scene through bypasses Surf only and never enters or leaves underwater terrain',
      () {
    for (final entry in [
      (MovementMode.walk, 2),
      (MovementMode.surf, 2),
      (MovementMode.dive, 1)
    ]) {
      final world = GameplayWorldState.initial(
          map: diveMap('deep', DiveZoneRole.underwater),
          playerPos: GridPos(x: entry.$2, y: 2),
          playerMovementMode: entry.$1);
      final before = world.player;
      expect(
          planActorRouteMove(
              world: world,
              target: SceneActorTarget.player(mapId: 'deep'),
              direction: entry.$1 == MovementMode.dive
                  ? EntityFacing.west
                  : EntityFacing.east,
              through: true),
          isNull);
      expect(world.player, before);
    }
  });
  test(
      'coincident Dive points refuse direct descent and ascent regardless of priority',
      () {
    for (final underwater in [false, true]) {
      final source = diveMap(underwater ? 'deep' : 'sea',
          underwater ? DiveZoneRole.underwater : DiveZoneRole.surface);
      final target = diveMap(underwater ? 'sea' : 'deep',
          underwater ? DiveZoneRole.surface : DiveZoneRole.underwater);
      for (final duplicateSource in [true, false]) {
        MapData duplicate(MapData map) => map.copyWith(gameplayZones: [
              ...map.gameplayZones,
              map.gameplayZones.last.copyWith(id: 'second', priority: 10),
            ]);
        final a = duplicateSource ? duplicate(source) : source;
        final b = duplicateSource ? target : duplicate(target);
        final state = diveReady(underwater: underwater);
        if (duplicateSource) {
          expect(findDiveTarget(map: a, gameState: state), isNull);
        }
        expect(
            evaluateDiveAttempt(
                sourceMap: a, targetMap: b, gameState: state, zoneId: 'point'),
            isA<DiveUnavailable>().having((value) => value.reason, 'reason',
                DiveBlockReason.inactivePair));
        expect(
            divePairHasSafeArrivals(
                sourceMap: a,
                sourceZoneId: 'point',
                targetMap: b,
                targetZoneId: 'point'),
            isFalse);
      }
    }
  });
  test('Dive descends and returns immediately with real modes and zero PP', () {
    final sea = diveMap('sea', DiveZoneRole.surface);
    final deep = diveMap('deep', DiveZoneRole.underwater);
    final state = diveReady();
    final descent = evaluateDiveAttempt(
        sourceMap: sea,
        targetMap: deep,
        gameState: state,
        zoneId: 'point') as CanUseDive;
    expect(descent.arrivalMovementMode, MovementMode.dive);
    final submerged = state.copyWith(
        currentMapId: deep.id,
        playerPosition: descent.position,
        playerFacing: descent.facing,
        playerMovementMode: descent.arrivalMovementMode);
    final cold = GameState.fromJson(
        jsonDecode(jsonEncode(submerged.toJson())) as Map<String, dynamic>);
    final ascent = evaluateDiveAttempt(
        sourceMap: deep,
        targetMap: sea,
        gameState: cold,
        zoneId: 'point') as CanUseDive;
    expect(ascent.arrivalMovementMode, MovementMode.surf);
    expect(ascent.position, state.playerPosition);
    expect(cold.party.members.single.currentPpByMoveId!['dive'], 0);
  });
  test(
      'Dive gate, prepared endpoint, blocked return and stale ticket fail closed',
      () {
    final sea = diveMap('sea', DiveZoneRole.surface);
    final deep = diveMap('deep', DiveZoneRole.underwater);
    final ready = diveReady();
    for (final entry in [
      (ready.copyWith(party: const PlayerParty()), DiveBlockReason.missingMove),
      (
        ready.copyWith(progression: const PlayerProgression()),
        DiveBlockReason.locked
      ),
      (
        ready.copyWith(playerMovementMode: MovementMode.walk),
        DiveBlockReason.wrongMode
      ),
      (
        ready.copyWith(
            party: PlayerParty(
                members: [ready.party.members.single.copyWith(currentHp: 0)])),
        DiveBlockReason.missingMove
      )
    ]) {
      expect(
          (evaluateDiveAttempt(
                  sourceMap: sea,
                  targetMap: deep,
                  gameState: entry.$1,
                  zoneId: 'point') as DiveUnavailable)
              .reason,
          entry.$2);
    }
    expect(
        evaluateDiveAttempt(
            sourceMap: diveMap('sea', DiveZoneRole.surface, linked: false),
            targetMap: deep,
            gameState: ready,
            zoneId: 'point'),
        isA<DiveUnavailable>());
    final blocked = sea.copyWith(entities: [
      ...sea.entities,
      const MapEntity(
          id: 'rock',
          kind: MapEntityKind.sign,
          pos: GridPos(x: 2, y: 2),
          blocksMovement: true)
    ]);
    expect(
        evaluateDiveAttempt(
            sourceMap: deep,
            targetMap: blocked,
            gameState: diveReady(underwater: true),
            zoneId: 'point'),
        isA<DiveUnavailable>());
    final evaluation = evaluateDiveAttempt(
        sourceMap: sea,
        targetMap: deep,
        gameState: ready,
        zoneId: 'point') as CanUseDive;
    final ticket = DiveActionTicket(
        evaluation: evaluation,
        gameState: ready,
        sourceMap: sea,
        targetMap: deep,
        issuedAtStateRevision: 3);
    expect(
        validateDiveTicket(
            ticket: ticket,
            sourceMap: sea,
            targetMap: deep,
            gameState: ready,
            currentStateRevision: 3),
        isNull);
    expect(
        validateDiveTicket(
            ticket: ticket,
            sourceMap: sea,
            targetMap: deep,
            gameState: ready,
            currentStateRevision: 4),
        FieldActionRefusal.staleStateRevision);
    expect(
        validateDiveTicket(
            ticket: ticket,
            sourceMap: sea,
            targetMap: deep.copyWith(entities: [
              deep.entities.single.copyWith(pos: const GridPos(x: 3, y: 2))
            ]),
            gameState: ready,
            currentStateRevision: 3),
        FieldActionRefusal.targetChanged);
    expect(
        validateDiveTicket(
            ticket: ticket,
            sourceMap: sea,
            targetMap: deep,
            gameState: ready.copyWith(
                playerPixelPosition: const PixelOffset(x: 1, y: 2)),
            currentStateRevision: 3),
        FieldActionRefusal.staleStateRevision);
  });
  test('one terrain verdict applies to ordinary, forced and warp movement', () {
    for (final role in DiveZoneRole.values) {
      final map = diveMap(role.name, role);
      for (final mode in [
        MovementMode.walk,
        MovementMode.surf,
        MovementMode.dive
      ]) {
        final world = GameplayWorldState.initial(
            map: map,
            playerPos: const GridPos(x: 2, y: 2),
            playerMovementMode: mode);
        final allowed = mode ==
            (role == DiveZoneRole.surface
                ? MovementMode.surf
                : MovementMode.dive);
        expect(world.isBlocked(2, 3), !allowed,
            reason: '${role.name}/${mode.name}');
        expect(stepGameplayWorld(world, const MoveIntent(Direction.south)),
            allowed ? isA<Moved>() : isA<Blocked>());
        expect(
            planActorRouteMove(
                world: world,
                target: SceneActorTarget.player(mapId: map.id),
                direction: EntityFacing.south,
                through: false),
            allowed ? isNotNull : isNull);
      }
    }
  });
  test('Dive cannot leave underwater terrain and survives cold state JSON', () {
    final state = diveReady(underwater: true);
    expect(
        GameState.fromJson(
                jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>)
            .playerMovementMode,
        MovementMode.dive);
    final world = GameplayWorldState.initial(
        map: diveMap('deep', DiveZoneRole.underwater),
        playerPos: const GridPos(x: 1, y: 2),
        playerMovementMode: MovementMode.dive);
    expect(stepGameplayWorld(world, const MoveIntent(Direction.west)),
        isA<Blocked>());
  });
}
