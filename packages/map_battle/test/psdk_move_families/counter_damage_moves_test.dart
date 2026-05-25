import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK counter/delayed damage move families', () {
    test('s_counter returns double current-turn damage to the attacker', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'counter',
          type: 'fighting',
          power: 0,
          battleEngineMethod: 's_counter',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      final incoming = _damage(result, moveId: 'opponent_tackle');
      final counter = _damage(result, moveId: 'counter');
      expect(counter, incoming * 2);
    });

    test('s_counter fails after special damage', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'counter',
          type: 'fighting',
          power: 0,
          battleEngineMethod: 's_counter',
        ),
        opponentMove: _move(
          id: 'opponent_water_gun',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      expect(_damageEvents(result, moveId: 'counter'), isEmpty);
      expect(_failed(result, moveId: 'counter'), isTrue);
    });

    test('s_mirror_coat returns double current-turn damage to the attacker',
        () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'mirror_coat',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 0,
          battleEngineMethod: 's_mirror_coat',
        ),
        opponentMove: _move(
          id: 'opponent_water_gun',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      final incoming = _damage(result, moveId: 'opponent_water_gun');
      final reflected = _damage(result, moveId: 'mirror_coat');
      expect(reflected, incoming * 2);
    });

    test('s_mirror_coat fails after physical damage', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'mirror_coat',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 0,
          battleEngineMethod: 's_mirror_coat',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      expect(_damageEvents(result, moveId: 'mirror_coat'), isEmpty);
      expect(_failed(result, moveId: 'mirror_coat'), isTrue);
    });

    test('s_metal_burst returns 1.5x current-turn damage to the attacker', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'metal_burst',
          type: 'steel',
          power: 0,
          battleEngineMethod: 's_metal_burst',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      final incoming = _damage(result, moveId: 'opponent_tackle');
      final burst = _damage(result, moveId: 'metal_burst');
      expect(burst, (incoming * 1.5).floor());
    });

    test('s_metal_burst can return special damage too', () {
      final result = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'metal_burst',
          type: 'steel',
          power: 0,
          battleEngineMethod: 's_metal_burst',
        ),
        opponentMove: _move(
          id: 'opponent_water_gun',
          category: PsdkBattleMoveCategory.special,
          power: 40,
        ),
      );

      final incoming = _damage(result, moveId: 'opponent_water_gun');
      final burst = _damage(result, moveId: 'metal_burst');
      expect(burst, (incoming * 1.5).floor());
    });

    test('counter family fails when no valid damage exists', () {
      final result = _runMove(
        playerMove: _move(
          id: 'counter',
          type: 'fighting',
          power: 0,
          battleEngineMethod: 's_counter',
        ),
      );

      expect(_damageEvents(result, moveId: 'counter'), isEmpty);
      expect(_failed(result, moveId: 'counter'), isTrue);
    });

    test('s_bide ignores damage that happened before the charge effect', () {
      final result = _runMove(
        playerDamageHistory: PsdkBattleDamageHistory(
          entries: const <PsdkBattleDamageHistoryEntry>[
            PsdkBattleDamageHistoryEntry(
              turn: 1,
              source: psdkOpponentSlot,
              moveId: 'hit_one',
              damage: 8,
              remainingHp: 92,
            ),
            PsdkBattleDamageHistoryEntry(
              turn: 2,
              source: psdkOpponentSlot,
              moveId: 'hit_two',
              damage: 10,
              remainingHp: 82,
            ),
          ],
        ),
        playerMove: _move(
          id: 'bide',
          type: 'normal',
          power: 0,
          battleEngineMethod: 's_bide',
        ),
      );

      expect(_damageEvents(result, moveId: 'bide'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).effects.contains('bide'),
          isTrue);
    });

    test('s_bide stores damage for two turns then unleashes it', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'bide',
            type: 'normal',
            power: 0,
            battleEngineMethod: 's_bide',
          ),
        ],
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final third = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(first, moveId: 'bide'), isEmpty);
      expect(_damageEvents(second, moveId: 'bide'), isEmpty);
      expect(first.state.battlerAt(psdkPlayerSlot).effects.contains('bide'),
          isTrue);
      expect(second.state.battlerAt(psdkPlayerSlot).effects.contains('bide'),
          isTrue);

      final storedDamage = _damage(first, moveId: 'opponent_tackle') +
          _damage(second, moveId: 'opponent_tackle');
      expect(_damage(third, moveId: 'bide'), storedDamage * 2);
      expect(third.state.battlerAt(psdkPlayerSlot).moves.single.currentPp, 34);
      expect(
        third.state.battlerAt(psdkPlayerSlot).effects.contains('bide'),
        isFalse,
      );
    });

    test('s_bide forces the stored move while charging', () {
      final engine = _engine(
        playerMoves: <PsdkBattleMoveData>[
          _move(
            id: 'bide',
            type: 'normal',
            power: 0,
            battleEngineMethod: 's_bide',
          ),
          _move(id: 'tackle', power: 40),
        ],
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(_damageEvents(second, moveId: 'tackle'), isEmpty);
      expect(_damageEvents(second, moveId: 'bide'), isEmpty);
      expect(
        second.state.battlerAt(psdkPlayerSlot).effects.contains('bide'),
        isTrue,
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleDamageHistory playerDamageHistory =
      const PsdkBattleDamageHistory.empty(),
  int playerSpeed = 100,
  int opponentSpeed = 1,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: playerSpeed,
        move: playerMove,
        damageHistory: playerDamageHistory,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: opponentSpeed,
        move: opponentMove ??
            _move(
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

PsdkBattleEngine _engine({
  required List<PsdkBattleMoveData> playerMoves,
  PsdkBattleMoveData? opponentMove,
}) {
  return PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        moves: playerMoves,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: opponentMove ??
            _move(
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
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  PsdkBattleMoveData? move,
  List<PsdkBattleMoveData>? moves,
  PsdkBattleDamageHistory damageHistory = const PsdkBattleDamageHistory.empty(),
}) {
  final resolvedMoves = moves ?? <PsdkBattleMoveData>[move!];
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
    damageHistory: damageHistory,
    moves: resolvedMoves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
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
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return _damageEvents(result, moveId: moveId).single.damage;
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList();
}

bool _failed(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .any((event) => event.moveId == moveId);
}
