import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  BattleStatsSnapshot? stats,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    stats: stats ?? _stats(),
    moves: moves,
  );
}

final class _LastLegalFightPolicy implements BattleOpponentPolicy {
  List<BattleActionFight>? lastLegalFightActions;

  @override
  BattleActionFight chooseFightAction({
    required List<BattleActionFight> legalFightActions,
  }) {
    lastLegalFightActions = legalFightActions;
    return legalFightActions.last;
  }
}

void main() {
  group('BattleOpponentPolicy seam', () {
    test(
        'battleOpponentPolicyForDifficulty maps product difficulty 1..10 to a small set of internal policies',
        () {
      expect(
        battleOpponentPolicyForDifficulty(null),
        isA<BattleFirstLegalOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(0),
        isA<BattleFirstLegalOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(3),
        isA<BattleFirstLegalOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(4),
        isA<BattleHighestPowerOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(7),
        isA<BattleHighestPowerOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(8),
        isA<BattleHighestExpectedPowerOpponentPolicy>(),
      );
      expect(
        battleOpponentPolicyForDifficulty(42),
        isA<BattleHighestExpectedPowerOpponentPolicy>(),
      );
    });

    test('BattleFirstLegalOpponentPolicy picks the first legal fight action',
        () {
      const firstMove = BattleMove(
        id: 'first',
        name: 'First',
        power: 10,
      );
      const secondMove = BattleMove(
        id: 'second',
        name: 'Second',
        power: 20,
      );
      const firstAction = BattleActionFight(
        firstMove,
        moveIndex: 0,
      );
      const secondAction = BattleActionFight(
        secondMove,
        moveIndex: 1,
      );
      const policy = BattleFirstLegalOpponentPolicy();

      final chosenAction = policy.chooseFightAction(
        legalFightActions: const <BattleActionFight>[
          firstAction,
          secondAction,
        ],
      );

      expect(chosenAction.move.id, equals('first'));
      expect(chosenAction.moveIndex, equals(0));
    });

    test(
        'higher internal policies stay fight-only but choose stronger or more reliable damaging moves',
        () {
      const setupMove = BattleMove(
        id: 'growl',
        name: 'Growl',
        power: 0,
        category: BattleMoveCategory.status,
        target: BattleMoveTarget.opponent,
        accuracy: BattleMoveAccuracy.alwaysHits(),
      );
      const heavyButRiskyMove = BattleMove(
        id: 'mega_punch',
        name: 'Mega Punch',
        power: 100,
        accuracy: BattleMoveAccuracy.percent(value: 50),
      );
      const reliableMove = BattleMove(
        id: 'swift_strike',
        name: 'Swift Strike',
        power: 60,
        accuracy: BattleMoveAccuracy.percent(value: 100),
      );
      const legalFightActions = <BattleActionFight>[
        BattleActionFight(setupMove, moveIndex: 0),
        BattleActionFight(heavyButRiskyMove, moveIndex: 1),
        BattleActionFight(reliableMove, moveIndex: 2),
      ];

      final lowDifficultyChoice = battleOpponentPolicyForDifficulty(2)
          .chooseFightAction(legalFightActions: legalFightActions);
      final midDifficultyChoice = battleOpponentPolicyForDifficulty(5)
          .chooseFightAction(legalFightActions: legalFightActions);
      final highDifficultyChoice = battleOpponentPolicyForDifficulty(9)
          .chooseFightAction(legalFightActions: legalFightActions);

      expect(lowDifficultyChoice.moveIndex, equals(0));
      expect(midDifficultyChoice.moveIndex, equals(1));
      expect(highDifficultyChoice.moveIndex, equals(2));
    });

    test(
        'BattleSession delegates enemy move selection to the injected opponent policy using only legal fight actions',
        () {
      final policy = _LastLegalFightPolicy();
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: _combatant(
            speciesId: 'player',
            lineupIndex: 0,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'wait',
                name: 'Wait',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
                accuracy: BattleMoveAccuracy.alwaysHits(),
              ),
            ],
          ),
          enemyPokemon: _combatant(
            speciesId: 'enemy',
            lineupIndex: 0,
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'empty',
                name: 'Empty',
                power: 5,
                pp: 10,
                currentPp: 0,
              ),
              BattleMoveData(
                id: 'weak',
                name: 'Weak',
                power: 5,
                pp: 10,
                currentPp: 10,
              ),
              BattleMoveData(
                id: 'strong',
                name: 'Strong',
                power: 20,
                pp: 10,
                currentPp: 10,
              ),
            ],
          ),
          isTrainerBattle: true,
          trainerId: 'trainer',
        ),
        opponentPolicy: policy,
        rng: const BattleScriptedRng(<int>[2, 2]),
      );

      final resolved = session.applyChoice(const PlayerBattleChoiceFight(0));
      final enemyAction = resolved.state.currentTurn!.enemyAction;

      expect(enemyAction, isA<BattleActionFight>());
      expect((enemyAction as BattleActionFight).move.id, equals('strong'));
      expect(enemyAction.moveIndex, equals(2));
      expect(policy.lastLegalFightActions, isNotNull);
      expect(
        policy.lastLegalFightActions!
            .map((action) => action.moveIndex)
            .toList(growable: false),
        orderedEquals(<int>[1, 2]),
      );
    });
  });
}
