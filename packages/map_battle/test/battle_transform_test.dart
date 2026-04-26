import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _dittoStats = BattleStatsSnapshot(
  attack: 48,
  defense: 48,
  specialAttack: 48,
  specialDefense: 48,
  speed: 48,
);

const _targetStats = BattleStatsSnapshot(
  attack: 84,
  defense: 78,
  specialAttack: 109,
  specialDefense: 85,
  speed: 100,
);

void main() {
  group('BattleSession Transform', () {
    test('copies target battle form, stats, ability, stages and moves', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'ditto',
            level: 50,
            currentHp: 72,
            maxHp: 100,
            stats: _dittoStats,
            typing: const BattleTypingSnapshot(primaryType: 'normal'),
            abilityId: 'limber',
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'transform',
                name: 'Transform',
                power: 0,
                type: 'normal',
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
                accuracy: BattleMoveAccuracy.alwaysHits(),
                pp: 10,
                copiesTargetOnHit: true,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'charizard',
            level: 50,
            maxHp: 150,
            stats: _targetStats,
            typing: const BattleTypingSnapshot(
              primaryType: 'fire',
              secondaryType: 'flying',
            ),
            abilityId: 'blaze',
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'roar',
                name: 'Roar',
                power: 0,
                type: 'normal',
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
                pp: 20,
              ),
              BattleMoveData(
                id: 'splash',
                name: 'Splash',
                power: 0,
                type: 'normal',
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
                pp: 40,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final transformed = afterTurn.state.player;

      expect(transformed.speciesId, equals('charizard'));
      expect(transformed.currentHp, equals(72));
      expect(transformed.maxHp, equals(100));
      expect(transformed.stats, equals(_targetStats));
      expect(transformed.typing?.primaryType, equals('fire'));
      expect(transformed.typing?.secondaryType, equals('flying'));
      expect(transformed.abilityId, equals('blaze'));
      expect(transformed.moves.map((move) => move.id), <String>[
        'roar',
        'splash',
      ]);
      expect(transformed.moves.map((move) => move.pp), <int>[5, 5]);
      expect(transformed.moves.map((move) => move.currentPp), <int>[5, 5]);
      final transformExecution = afterTurn.state.currentTurn!.executions
          .singleWhere((execution) => execution.move.id == 'transform');
      expect(transformExecution.damage, 0);
    });
  });
}
