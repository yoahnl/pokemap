import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const waterfallZone = MapGameplayZone(
  id: 'fall',
  kind: GameplayZoneKind.fieldAction,
  area: MapRect(pos: GridPos(x: 2, y: 1), size: GridSize(width: 1, height: 4)),
  fieldAction: FieldActionZonePayload(
      actionKind: FieldActionZoneKind.waterfall,
      waterfall: WaterfallZonePayload(
          entry: GridPos(x: 0, y: 3),
          path: [GridPos(x: 0, y: 2), GridPos(x: 0, y: 1)],
          exit: GridPos(x: 0, y: 0),
          direction: MapConnectionDirection.north)),
);
MapData waterfallMap() => MapData(
    id: 'falls',
    name: 'Falls',
    size: const GridSize(width: 8, height: 8),
    gameplayZones: const [waterfallZone]);
GameState waterfallReady() => const GameState(
    saveId: 'waterfall',
    currentMapId: 'falls',
    playerPosition: GridPos(x: 2, y: 4),
    playerFacing: EntityFacing.north,
    playerMovementMode: MovementMode.surf,
    party: PlayerParty(members: [
      PlayerPokemon(
          speciesId: 'pikachu',
          natureId: 'hardy',
          abilityId: 'static',
          level: 20,
          currentHp: 30,
          knownMoveIds: ['waterfall'],
          currentPpByMoveId: {'waterfall': 0})
    ]),
    progression:
        PlayerProgression(unlockedFieldAbilities: [FieldAbility.waterfall]));

void main() {
  test('waterfall is a finite validated route without PP consumption', () {
    final state = waterfallReady();
    final result = evaluateWaterfallAttempt(
        map: waterfallMap(), gameState: state, zoneId: 'fall');
    expect(result, isA<CanUseWaterfall>());
    expect((result as CanUseWaterfall).cells,
        const [GridPos(x: 2, y: 3), GridPos(x: 2, y: 2), GridPos(x: 2, y: 1)]);
    expect(state.party.members.single.currentPpByMoveId!['waterfall'], 0);
  });
  test(
      'wrong direction, missing move, locked and missing Surf are explicit refusals',
      () {
    final state = waterfallReady();
    for (final pair in [
      (
        state.copyWith(playerFacing: EntityFacing.south),
        WaterfallBlockReason.wrongDirection
      ),
      (
        state.copyWith(party: const PlayerParty()),
        WaterfallBlockReason.missingMove
      ),
      (
        state.copyWith(progression: const PlayerProgression()),
        WaterfallBlockReason.locked
      ),
      (
        state.copyWith(playerMovementMode: MovementMode.walk),
        WaterfallBlockReason.requiresSurf
      ),
    ]) {
      expect(
          (evaluateWaterfallAttempt(
                  map: waterfallMap(),
                  gameState: pair.$1,
                  zoneId: 'fall') as WaterfallUnavailable)
              .reason,
          pair.$2);
    }
  });
  test(
      'ordinary forced routes cannot enter cascade body while validated Cascade can',
      () {
    final state = waterfallReady();
    final world = GameplayWorldState.initial(
        map: waterfallMap(),
        playerPos: state.playerPosition,
        playerFacing: Direction.north,
        playerMovementMode: state.playerMovementMode);
    expect(
        planActorRouteMove(
            world: world,
            target: SceneActorTarget.player(mapId: 'falls'),
            direction: EntityFacing.north,
            through: false),
        isNull);
  });
  test('occupied exit rejects the complete route before it starts', () {
    final map = waterfallMap().copyWith(entities: const [
      MapEntity(
          id: 'block',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 1),
          npc: MapEntityNpcData())
    ]);
    expect(
        (evaluateWaterfallAttempt(
                map: map,
                gameState: waterfallReady(),
                zoneId: 'fall') as WaterfallUnavailable)
            .reason,
        WaterfallBlockReason.obstructed);
  });
  test(
      'optional Surf, fainted users, dynamic occupancy and stale confirmation use the same pure gate',
      () {
    final ready = waterfallReady();
    final base = waterfallMap();
    final zone = base.gameplayZones.single;
    final dry = base.copyWith(gameplayZones: [
      zone.copyWith(
          fieldAction: zone.fieldAction!.copyWith(
              waterfall:
                  zone.fieldAction!.waterfall!.copyWith(requiresSurf: false)))
    ]);
    expect(
        evaluateWaterfallAttempt(
            map: dry,
            gameState: ready.copyWith(playerMovementMode: MovementMode.walk),
            zoneId: 'fall'),
        isA<CanUseWaterfall>());
    final fainted = ready.copyWith(
        party: PlayerParty(
            members: [ready.party.members.single.copyWith(currentHp: 0)]));
    expect(
        (evaluateWaterfallAttempt(map: base, gameState: fainted, zoneId: 'fall')
                as WaterfallUnavailable)
            .reason,
        WaterfallBlockReason.missingMove);
    expect(
        (evaluateWaterfallAttempt(
                    map: base,
                    gameState: ready,
                    zoneId: 'fall',
                    dynamicBlockedCells: const [GridPos(x: 2, y: 1)])
                as WaterfallUnavailable)
            .reason,
        WaterfallBlockReason.obstructed);
    final ticket = WaterfallActionTicket(
        fieldAction: FieldActionTicket(
            ability: FieldAbility.waterfall,
            targetCell: ready.playerPosition,
            issuedAtStateRevision: 3),
        zone: zone,
        entryState: ready,
        instance: null);
    expect(
        validateWaterfallTicket(
            ticket: ticket,
            map: base,
            gameState: ready,
            currentStateRevision: 4),
        FieldActionRefusal.staleStateRevision);
    expect(
        validateWaterfallTicket(
            ticket: ticket,
            map: base,
            gameState: ready.copyWith(playerFacing: EntityFacing.south),
            currentStateRevision: 3),
        FieldActionRefusal.targetChanged);
    expect(
        validateWaterfallTicket(
            ticket: ticket,
            map: dry,
            gameState: ready,
            currentStateRevision: 3),
        FieldActionRefusal.targetChanged);
  });
}
