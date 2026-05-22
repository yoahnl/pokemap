import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK spread self-stat moves', () {
    test('s_self_stat damages each adjacent foe and drops user stat once', () {
      final result = _executeSpreadSelfStat(
        _move(
          id: 'clanging_scales',
          type: 'dragon',
          category: PsdkBattleMoveCategory.special,
          power: 110,
          target: PsdkBattleMoveTarget.allAdjacentFoes,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(stat: 'defense', stages: -1, chance: 100),
          ],
        ),
      );

      expect(
        _damageEvents(
          result,
          moveId: 'clanging_scales',
        ).map((event) => event.target),
        <PsdkBattleSlotRef>[psdkOpponentSlot, _opponentRightSlot],
      );
      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('defense'),
        -1,
      );
      expect(
        result.events.whereType<PsdkBattleStatStageEvent>().single.target,
        psdkPlayerSlot,
      );
    });

    test('s_self_stat spread stat chance rolls once for the user effect', () {
      final initialRng = BattleRngStreams.fromSeeds(
        moveDamageSeed: 1,
        moveCriticalSeed: 99999,
        moveAccuracySeed: 3,
        genericSeed: 49,
      );
      final result = _executeSpreadSelfStat(
        _move(
          id: 'diamond_storm',
          type: 'rock',
          power: 100,
          target: PsdkBattleMoveTarget.allAdjacentFoes,
          effectChance: 50,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(stat: 'defense', stages: 2, chance: 100),
          ],
        ),
        rng: initialRng,
      );

      expect(_damageEvents(result, moveId: 'diamond_storm'), hasLength(2));
      expect(
        result.state.battlerAt(psdkPlayerSlot).statStages.valueOf('defense'),
        2,
      );
      expect(
          result.rng.seeds.generic, initialRng.generic.nextPercent().next.seed);
    });
  });
}

BattleMoveBehaviorResolution _executeSpreadSelfStat(
  PsdkBattleMoveData move, {
  BattleRngStreams? rng,
}) {
  return const PsdkBattleMoveExecutor().execute(
    PsdkBattleMoveRequest(
      state: _doublesState(move),
      rng: rng ??
          BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
      turn: 1,
      user: psdkPlayerSlot,
      target: psdkOpponentSlot,
      moveId: move.id,
      battleEngineMethod: move.battleEngineMethod,
      studioMove: move,
    ),
  );
}

List<PsdkBattleDamageEvent> _damageEvents(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

PsdkBattleState _doublesState(PsdkBattleMoveData move) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'player', move: move),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'opponent', move: _move(id: 'opponent_wait', power: 0)),
      ),
      _opponentRightSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent_ally',
          move: _move(id: 'opponent_ally_wait', power: 0),
        ),
      ),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  int? effectChance,
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_self_stat',
    target: target,
    effectChance: effectChance,
    stageMods: stageMods,
  );
}

const _opponentRightSlot = PsdkBattleSlotRef(bank: 1, position: 1);
