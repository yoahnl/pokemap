import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('generic battle items v0', () {
    test('heals an explicit reserve party target', () {
      final session = _session(reserve: _combatant(id: 'reserve', hp: 20));

      final result = session.submit(
        const BattleDecision.item(
          itemId: 'battle-tonic',
          target: psdkPlayerSlot,
          targetPartyIndex: 1,
          effect: PsdkBattleHpHealItemEffect.flat(20),
          highPriority: true,
        ),
      );

      expect(
        result.state.psdkState.partyForBank(psdkPlayerSlot.bank)[1].currentHp,
        40,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(80));
      expect(
        result.timeline.events
            .whereType<BattleItemTimelineEvent>()
            .single
            .itemId,
        'battle-tonic',
      );
    });

    test('cures a compatible major status on an explicit target', () {
      final session = _session(playerStatus: PsdkBattleMajorStatus.poison);

      final result = session.submit(
        const BattleDecision.item(
          itemId: 'toxin-sponge',
          target: psdkPlayerSlot,
          targetPartyIndex: 0,
          effect: PsdkBattleStatusCureItemEffect.only(<PsdkBattleMajorStatus>{
            PsdkBattleMajorStatus.poison,
          }),
          highPriority: true,
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
        result.timeline.events.whereType<BattleItemTimelineEvent>(),
        hasLength(1),
      );
    });

    test('revives a fainted reserve to the requested HP percentage', () {
      final session = _session(reserve: _combatant(id: 'reserve', hp: 0));

      final result = session.submit(
        const BattleDecision.item(
          itemId: 'dawn-feather',
          target: psdkPlayerSlot,
          targetPartyIndex: 1,
          effect: PsdkBattleReviveItemEffect(percent: 50),
          highPriority: true,
        ),
      );

      expect(
        result.state.psdkState.partyForBank(psdkPlayerSlot.bank)[1].currentHp,
        40,
      );
      expect(
        result.timeline.events.whereType<BattleItemTimelineEvent>(),
        hasLength(1),
      );
    });

    test('rejects an invalid item target before the turn mutates', () {
      final session = _session();

      expect(
        () => session.submit(
          const BattleDecision.item(
            itemId: 'battle-tonic',
            target: psdkPlayerSlot,
            targetPartyIndex: 8,
            effect: PsdkBattleHpHealItemEffect.flat(20),
            highPriority: true,
          ),
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.turnNumber, 0);
    });

    test('rejects a no-effect item atomically', () {
      final session = _session(playerHp: 80);

      expect(
        () => session.submit(
          const BattleDecision.item(
            itemId: 'battle-tonic',
            target: psdkPlayerSlot,
            targetPartyIndex: 0,
            effect: PsdkBattleHpHealItemEffect.flat(20),
            highPriority: true,
          ),
        ),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.turnNumber, 0);
      expect(session.state.battlerAt(psdkPlayerSlot).currentHp, 80);
    });
  });
}

BattleSessionFacade _session({
  int playerHp = 80,
  PsdkBattleMajorStatus? playerStatus,
  PsdkBattleCombatantSetup? reserve,
}) {
  return BattleSessionFacade.fromPsdkSetup(
    setup: PsdkBattleSetup.singles(
      player: _combatant(id: 'player', hp: playerHp, status: playerStatus),
      playerReserves: <PsdkBattleCombatantSetup>[if (reserve != null) reserve],
      opponent: _combatant(id: 'opponent', hp: 80),
      isTrainerBattle: true,
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  PsdkBattleMajorStatus? status,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 80,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    majorStatus: status,
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: '$id-move',
        dbSymbol: '$id-move',
        name: '$id-move',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 10,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}
