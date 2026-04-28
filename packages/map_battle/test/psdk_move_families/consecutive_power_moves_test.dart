import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK consecutive-power move families', () {
    test('s_fury_cutter doubles after consecutive successful uses', () {
      final first = _runMove(
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );
      final third = _runMove(
        playerMoveHistory: _successes('fury_cutter', count: 2),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );

      expect(
        _damage(third, moveId: 'fury_cutter'),
        greaterThan(_damage(first, moveId: 'fury_cutter')),
      );
    });

    for (final entry in <({String method, String moveId})>[
      (method: 's_rollout', moveId: 'rollout'),
      (method: 's_ice_ball', moveId: 'ice_ball'),
    ]) {
      test('${entry.method} doubles after consecutive successful uses', () {
        final first = _runMove(
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            battleEngineMethod: entry.method,
          ),
        );
        final second = _runMove(
          playerMoveHistory: _successes(entry.moveId, count: 1),
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            battleEngineMethod: entry.method,
          ),
        );

        expect(
          _damage(second, moveId: entry.moveId),
          greaterThan(_damage(first, moveId: entry.moveId)),
        );
      });
    }

    test('s_echo gains power after recent Echoed Voice success', () {
      final first = _runMove(
        playerMove: _move(
          id: 'echoed_voice',
          category: PsdkBattleMoveCategory.special,
          power: 40,
          battleEngineMethod: 's_echo',
        ),
      );
      final boosted = _runMove(
        playerMoveHistory: _successes('echoed_voice', count: 2),
        playerMove: _move(
          id: 'echoed_voice',
          category: PsdkBattleMoveCategory.special,
          power: 40,
          battleEngineMethod: 's_echo',
        ),
      );

      expect(
        _damage(boosted, moveId: 'echoed_voice'),
        greaterThan(_damage(first, moveId: 'echoed_voice')),
      );
    });

    test('s_trump_card grows stronger as remaining PP gets lower', () {
      final highPp = _runMove(
        playerMove: _move(
          id: 'trump_card',
          category: PsdkBattleMoveCategory.special,
          power: 40,
          pp: 8,
          currentPp: 5,
          battleEngineMethod: 's_trump_card',
        ),
      );
      final lowPp = _runMove(
        playerMove: _move(
          id: 'trump_card',
          category: PsdkBattleMoveCategory.special,
          power: 40,
          pp: 8,
          currentPp: 2,
          battleEngineMethod: 's_trump_card',
        ),
      );

      expect(
        _damage(lowPp, moveId: 'trump_card'),
        greaterThan(_damage(highPp, moveId: 'trump_card')),
      );
    });
  });
}

PsdkBattleMoveHistory _successes(String moveId, {required int count}) {
  return PsdkBattleMoveHistory(
    attempts: <PsdkBattleMoveHistoryEntry>[
      for (var i = 0; i < count; i++)
        PsdkBattleMoveHistoryEntry(
          moveId: moveId,
          turn: i + 1,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
    successes: <PsdkBattleMoveHistoryEntry>[
      for (var i = 0; i < count; i++)
        PsdkBattleMoveHistoryEntry(
          moveId: moveId,
          turn: i + 1,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
  );
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveHistory? playerMoveHistory,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
        moveHistory: playerMoveHistory,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 0,
          category: PsdkBattleMoveCategory.status,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleMoveHistory? moveHistory,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moveHistory: moveHistory,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int pp = 35,
  int? currentPp,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: pp,
    currentPp: currentPp,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
