import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

void main() {
  group('RuntimePsdkBattleSessionAdapter', () {
    test('uses PSDK AI by default so opponents can choose a damaging move', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(_setup());

      final result =
          session.submitPlayerChoice(const PlayerBattleChoiceFight(0));
      final displaySession = session.createLegacyDisplaySession(
        isTrainerBattle: false,
      );

      expect(
        result.timeline.events
            .whereType<BattleMoveDeclaredTimelineEvent>()
            .where((event) =>
                event.user.bank == psdkOpponentSlot.bank &&
                event.user.position == psdkOpponentSlot.position)
            .map((event) => event.moveId),
        contains('tackle'),
      );
      expect(
        result.state.psdkState.battlerAt(psdkPlayerSlot).currentHp,
        lessThan(120),
      );
      expect(displaySession.state.player.currentHp, lessThan(120));
      expect(
        displaySession.state.currentTurn!.executions.where(
          (execution) => execution.attackerSide == BattleSideId.enemy,
        ),
        isNotEmpty,
      );
      expect(displaySession.state.currentTurn!.enemyAction,
          isA<BattleActionFight>());
      expect(
        (displaySession.state.currentTurn!.enemyAction as BattleActionFight)
            .move
            .id,
        equals('tackle'),
      );
    });
  });
}

PsdkBattleSetup _setup() {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      hp: 120,
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'wait',
          category: PsdkBattleMoveCategory.status,
          power: 0,
        ),
      ],
    ),
    opponent: _combatant(
      id: 'opponent',
      hp: 120,
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'growl',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(stat: 'attack', stages: -1),
          ],
        ),
        _move(id: 'tackle', power: 40),
      ],
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 1,
      generic: 1,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: hp,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: power,
    accuracy: 100,
    pp: 15,
    priority: 0,
    battleEngineMethod:
        category == PsdkBattleMoveCategory.status ? 's_status' : 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    stageMods: stageMods,
  );
}
