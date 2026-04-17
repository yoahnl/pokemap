import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _topologyStats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

const _topologyMove = BattleMove(
  id: 'wait',
  name: 'Wait',
  power: 0,
);

BattleCombatant _combatant({
  required String speciesId,
  required int lineupIndex,
}) {
  return BattleCombatant(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    currentHp: 40,
    maxHp: 40,
    stats: _topologyStats,
    moves: const <BattleMove>[_topologyMove],
  );
}

void main() {
  group('BattleState Phase D side topology', () {
    test('legacy flat construction materializes canonical sides and slots', () {
      final state = BattleState(
        phase: BattlePhase.playerChoice,
        player: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
        ),
        playerReserve: <BattleCombatant>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
          ),
        ],
        enemy: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
        ),
        enemyReserve: <BattleCombatant>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
          ),
        ],
      );

      expect(state.playerSide.id, equals(BattleSideId.player));
      expect(state.playerSide.activeSlot.ref,
          equals(const BattleSlotRef.active(BattleSideId.player)));
      expect(state.playerSide.active.speciesId, equals('lead_player'));
      expect(state.playerSide.reserve.single.speciesId, equals('bench_player'));

      expect(state.enemySide.id, equals(BattleSideId.enemy));
      expect(state.enemySide.activeSlot.ref,
          equals(const BattleSlotRef.active(BattleSideId.enemy)));
      expect(state.enemySide.active.speciesId, equals('lead_enemy'));
      expect(state.enemySide.reserve.single.speciesId, equals('bench_enemy'));

      // Compatibilité volontaire Phase D :
      // la topologie canonique change, mais le vieux chemin de lecture
      // `player/enemy/playerReserve/enemyReserve` reste encore disponible pour
      // limiter le blast radius runtime tant que Phase D ne demande pas plus.
      expect(state.player.speciesId, equals('lead_player'));
      expect(state.playerReserve.single.speciesId, equals('bench_player'));
      expect(state.enemy.speciesId, equals('lead_enemy'));
      expect(state.enemyReserve.single.speciesId, equals('bench_enemy'));
    });

    test('side-backed construction keeps the legacy getters coherent', () {
      final playerSide = BattleSideState.player(
        active: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
        ),
        reserve: <BattleCombatant>[
          _combatant(
            speciesId: 'bench_player',
            lineupIndex: 1,
          ),
        ],
      );
      final enemySide = BattleSideState.enemy(
        active: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
        ),
        reserve: <BattleCombatant>[
          _combatant(
            speciesId: 'bench_enemy',
            lineupIndex: 1,
          ),
        ],
      );

      final state = BattleState(
        phase: BattlePhase.playerChoice,
        playerSide: playerSide,
        enemySide: enemySide,
      );

      expect(state.side(BattleSideId.player), same(playerSide));
      expect(state.side(BattleSideId.enemy), same(enemySide));
      expect(state.player, same(playerSide.active));
      expect(state.playerReserve, same(playerSide.reserve));
      expect(state.enemy, same(enemySide.active));
      expect(state.enemyReserve, same(enemySide.reserve));
    });

    test('rejects swapped canonical side identities', () {
      final swappedPlayerSide = BattleSideState.enemy(
        active: _combatant(
          speciesId: 'wrong_player_side',
          lineupIndex: 0,
        ),
      );
      final enemySide = BattleSideState.enemy(
        active: _combatant(
          speciesId: 'lead_enemy',
          lineupIndex: 0,
        ),
      );

      expect(
        () => BattleState(
          phase: BattlePhase.playerChoice,
          playerSide: swappedPlayerSide,
          enemySide: enemySide,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects mixing canonical sides and legacy flat inputs', () {
      final playerSide = BattleSideState.player(
        active: _combatant(
          speciesId: 'lead_player',
          lineupIndex: 0,
        ),
      );

      expect(
        () => BattleState(
          phase: BattlePhase.playerChoice,
          playerSide: playerSide,
          player: _combatant(
            speciesId: 'legacy_player',
            lineupIndex: 0,
          ),
          enemy: _combatant(
            speciesId: 'lead_enemy',
            lineupIndex: 0,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
