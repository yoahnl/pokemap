import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

MapData darkMap() => MapData(
      id: 'cave',
      name: 'Cave',
      size: const GridSize(width: 6, height: 4),
      gameplayZones: const [
        MapGameplayZone(
            id: 'dark',
            kind: GameplayZoneKind.fieldAction,
            area: MapRect(
                pos: GridPos(x: 1, y: 1), size: GridSize(width: 3, height: 2)),
            fieldAction: FieldActionZonePayload(
                actionKind: FieldActionZoneKind.darkness,
                darkness: DarknessZonePayload(opacity: .85))),
      ],
    );
GameState flashReady() => GameState(
      saveId: 'flash',
      currentMapId: 'cave',
      playerPosition: const GridPos(x: 1, y: 1),
      party: const PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'pikachu',
          natureId: 'hardy',
          abilityId: 'static',
          level: 20,
          currentHp: 30,
          knownMoveIds: ['flash'],
          currentPpByMoveId: {'flash': 0},
        )
      ]),
      progression:
          const PlayerProgression(unlockedFieldAbilities: [FieldAbility.flash]),
      mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
        'cave': MapInstanceRuntimeState(instanceId: 'cave-1'),
      }),
    );
FlashActionTicket flashTicket(GameState state) => FlashActionTicket(
      fieldAction: FieldActionTicket(
          ability: FieldAbility.flash,
          targetCell: state.playerPosition,
          issuedAtStateRevision: 4),
      instance: state.mapInstanceWorldState.instanceRef('cave')!,
      zone: darkMap().gameplayZones.single,
      playerPixelPosition: state.playerPixelPosition,
    );

void main() {
  test(
      'overlapping darkness keeps each zone independent and applies the strongest remaining veil',
      () {
    final original = flashReady();
    final first = darkMap().gameplayZones.single;
    final other = first.copyWith(
        id: 'other-darkness',
        priority: 2,
        fieldAction: const FieldActionZonePayload(
            actionKind: FieldActionZoneKind.darkness,
            darkness: DarknessZonePayload(opacity: .7)));
    final map = darkMap().copyWith(gameplayZones: [first, other]);
    expect(findFlashTarget(map: map, gameState: original), other);
    expect(resolveDarknessOpacity(map: map, gameState: original), .85);
    final originalTicket = flashTicket(original);
    final firstResult = commitFlashAction(
        ticket: FlashActionTicket(
            fieldAction: originalTicket.fieldAction,
            instance: originalTicket.instance,
            zone: other,
            playerPixelPosition: original.playerPixelPosition),
        map: map,
        gameState: original,
        currentStateRevision: 4) as FlashApplied;
    final state = firstResult.gameState;
    expect(
        state
            .mapInstanceWorldState.instancesByMapId['cave']!.illuminatedZoneIds,
        {'other-darkness'});
    expect(resolveDarknessOpacity(map: map, gameState: state), .85);
    expect(findFlashTarget(map: map, gameState: state), first);
    final secondResult = commitFlashAction(
        ticket: originalTicket,
        map: map,
        gameState: state,
        currentStateRevision: 4) as FlashApplied;
    expect(
        secondResult.gameState.mapInstanceWorldState.instancesByMapId['cave']!
            .illuminatedZoneIds,
        {'dark', 'other-darkness'});
    expect(
        resolveDarknessOpacity(map: map, gameState: secondResult.gameState), 0);
    expect(secondResult.gameState.party, original.party);
  });
  test(
      'Flash illuminates only its zone without spending PP and survives cold state',
      () {
    final map = darkMap(), state = flashReady();
    expect(evaluateFlashAttempt(map: map, gameState: state, zoneId: 'dark'),
        isA<CanUseFlash>());
    expect(resolveDarknessOpacity(map: map, gameState: state), .85);
    final applied = commitFlashAction(
        ticket: flashTicket(state),
        map: map,
        gameState: state,
        currentStateRevision: 4) as FlashApplied;
    final restored = GameState.fromJson(applied.gameState.toJson());
    expect(restored.party, state.party);
    expect(resolveDarknessOpacity(map: map, gameState: restored), 0);
    expect(
        evaluateFlashAttempt(map: map, gameState: restored, zoneId: 'dark'),
        isA<FlashUnavailable>().having(
            (e) => e.reason, 'reason', FlashBlockReason.alreadyIlluminated));
    expect(
        commitFlashAction(
            ticket: flashTicket(state),
            map: map,
            gameState: restored,
            currentStateRevision: 4),
        isA<FlashRefused>());
    expect(
        state
            .mapInstanceWorldState.instancesByMapId['cave']!.illuminatedZoneIds,
        isEmpty);
    final outside = state.copyWith(playerPosition: const GridPos(x: 0, y: 1));
    expect(resolveDarknessOpacity(map: map, gameState: outside), 0);
    expect(resolveDarknessOpacity(map: map, gameState: state), .85);
    final reset = setupDifferentMapInstance(
        state: restored.mapInstanceWorldState,
        targetMapId: 'cave',
        allocateId: (_) => 'cave-2');
    expect(
        resolveDarknessOpacity(
            map: map,
            gameState: restored.copyWith(mapInstanceWorldState: reset)),
        .85);
  });

  for (final mode in [
    'missing',
    'fainted',
    'locked',
    'outside',
    'noInstance',
    '3d'
  ]) {
    test('Flash refuses $mode before confirmation', () {
      var state = flashReady();
      var map = darkMap();
      if (mode == 'missing') state = state.copyWith(party: const PlayerParty());
      if (mode == 'fainted') {
        state = state.copyWith(
            party: PlayerParty(
                members: [state.party.members.single.copyWith(currentHp: 0)]));
      }
      if (mode == 'locked') {
        state = state.copyWith(progression: const PlayerProgression());
      }
      if (mode == 'outside') {
        state = state.copyWith(playerPosition: const GridPos(x: 0, y: 1));
      }
      if (mode == 'noInstance') {
        state = state.copyWith(
            mapInstanceWorldState: const MapInstanceWorldState.empty());
      }
      if (mode == '3d') map = map.copyWith(version: ProjectVersion.v9);
      expect(evaluateFlashAttempt(map: map, gameState: state, zoneId: 'dark'),
          isA<FlashUnavailable>());
    });
  }

  for (final mode in [
    'revision',
    'moved',
    'pixelMoved',
    'fainted',
    'locked',
    'instance',
    'zoneChanged',
    'ability'
  ]) {
    test('Flash confirmation revalidates $mode without partial mutation', () {
      final original = flashReady();
      var state = original;
      var map = darkMap();
      var ticket = flashTicket(original);
      if (mode == 'moved') {
        state = state.copyWith(playerPosition: const GridPos(x: 2, y: 1));
      }
      if (mode == 'pixelMoved') {
        state = state.copyWith(
            playerPixelPosition: const PixelOffset(x: 17, y: 16));
      }
      if (mode == 'fainted') state = state.copyWith(party: const PlayerParty());
      if (mode == 'locked') {
        state = state.copyWith(progression: const PlayerProgression());
      }
      if (mode == 'instance') {
        state = state.copyWith(
            mapInstanceWorldState: MapInstanceWorldState(instancesByMapId: {
          'cave': MapInstanceRuntimeState(instanceId: 'other')
        }));
      }
      if (mode == 'zoneChanged') {
        map = map.copyWith(
            gameplayZones: [map.gameplayZones.single.copyWith(priority: 2)]);
      }
      if (mode == 'ability') {
        ticket = FlashActionTicket(
            fieldAction: const FieldActionTicket(
                ability: FieldAbility.cut,
                targetCell: GridPos(x: 1, y: 1),
                issuedAtStateRevision: 4),
            instance: ticket.instance,
            zone: ticket.zone);
      }
      final before = state.toJson();
      expect(
          commitFlashAction(
              ticket: ticket,
              map: map,
              gameState: state,
              currentStateRevision: mode == 'revision' ? 5 : 4),
          isA<FlashRefused>());
      expect(state.toJson(), before);
    });
  }
}
