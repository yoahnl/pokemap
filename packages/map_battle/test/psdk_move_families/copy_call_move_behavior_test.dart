import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK copy/call move families', () {
    test('s_sleep_talk calls a seeded eligible user move while asleep', () {
      final result = _runMove(
        playerMajorStatus: PsdkBattleMajorStatus.sleep,
        playerMove: _move(
          id: 'sleep_talk',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_sleep_talk',
        ),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(id: 'tackle', power: 40),
        ],
      );

      expect(_failures(result), isEmpty);
      expect(_damageEvents(result, moveId: 'tackle'), hasLength(1));
      expect(_damageEvents(result, moveId: 'sleep_talk'), isEmpty);
      expect(_ppSpent(result, moveId: 'sleep_talk'), hasLength(1));
      expect(_ppSpent(result, moveId: 'tackle'), isEmpty);
      expect(
        result.state.battlerAt(psdkPlayerSlot).moves[1].currentPp,
        35,
      );
    });

    test('s_sleep_talk uses the generic RNG stream to pick among moves', () {
      final result = _runMove(
        playerMajorStatus: PsdkBattleMajorStatus.sleep,
        genericSeed: 1,
        playerMove: _move(
          id: 'sleep_talk',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_sleep_talk',
        ),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(id: 'tackle', power: 40),
          _move(id: 'scratch', power: 40),
        ],
      );

      expect(_failures(result), isEmpty);
      expect(_damageEvents(result, moveId: 'tackle'), isEmpty);
      expect(_damageEvents(result, moveId: 'scratch'), hasLength(1));
    });

    test('s_sleep_talk fails before PP when user is awake', () {
      final result = _runMove(
        playerMove: _move(
          id: 'sleep_talk',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_sleep_talk',
        ),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(id: 'tackle', power: 40),
        ],
      );

      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'sleep_talk');
      expect(
        _failures(result).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_ppSpent(result, moveId: 'sleep_talk'), isEmpty);
      expect(_damageEvents(result, moveId: 'tackle'), isEmpty);
    });

    test('s_sleep_talk fails when every user move is excluded', () {
      final result = _runMove(
        playerMajorStatus: PsdkBattleMajorStatus.sleep,
        playerMove: _move(
          id: 'sleep_talk',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_sleep_talk',
        ),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(
            id: 'metronome',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_metronome',
          ),
        ],
      );

      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'sleep_talk');
      expect(_ppSpent(result, moveId: 'sleep_talk'), isEmpty);
    });

    test('s_sleep_talk can be used by Comatose without sleep status', () {
      final result = _runMove(
        playerAbilityId: 'comatose',
        playerMove: _move(
          id: 'sleep_talk',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_sleep_talk',
        ),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(id: 'tackle', power: 40),
        ],
      );

      expect(_failures(result), isEmpty);
      expect(_damageEvents(result, moveId: 'tackle'), hasLength(1));
    });

    test('s_mimic fails before PP when the target has no successful move', () {
      final result = _runMove(
        playerMove: _move(
          id: 'mimic',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_mimic',
        ),
      );

      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'mimic');
      expect(
        _failures(result).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_ppSpent(result, moveId: 'mimic'), isEmpty);
    });

    for (final moveId in <String>[
      'chatter',
      'metronome',
      'sketch',
      'struggle',
      'mimic',
    ]) {
      test('s_mimic fails before PP when target last move is $moveId', () {
        final result = _runMove(
          opponentMoveHistory: PsdkBattleMoveHistory.empty().recordSuccess(
            moveId: moveId,
            turn: 0,
            targets: const <PsdkBattleSlotRef>[psdkPlayerSlot],
          ),
          opponentMove: _move(id: moveId, power: 40),
          playerMove: _move(
            id: 'mimic',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_mimic',
          ),
        );

        expect(_failures(result), hasLength(1), reason: moveId);
        expect(
          _ppSpent(result, moveId: 'mimic', user: psdkPlayerSlot),
          isEmpty,
          reason: moveId,
        );
      });
    }

    test('s_mimic replaces the selected move slot with the target last move',
        () {
      final targetMove = _move(
        id: 'flamethrower',
        category: PsdkBattleMoveCategory.special,
        power: 90,
        battleEngineMethod: 's_basic',
      );
      final result = _runMove(
        selectedMoveSlot: 1,
        playerMove: _move(id: 'tackle', power: 40),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(
            id: 'mimic',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_mimic',
          ),
        ],
        opponentMove: targetMove,
        opponentMoveHistory: PsdkBattleMoveHistory.empty().recordSuccess(
          moveId: 'flamethrower',
          turn: 0,
          targets: const <PsdkBattleSlotRef>[psdkPlayerSlot],
        ),
      );

      final copied = result.state.battlerAt(psdkPlayerSlot).moves[1];
      expect(_failures(result), isEmpty);
      expect(copied.id, 'flamethrower');
      expect(copied.pp, 5);
      expect(copied.currentPp, 5);
      expect(result.state.battlerAt(psdkPlayerSlot).moves[0].id, 'tackle');
    });

    test('s_sketch fails before PP when the target has no move history', () {
      final result = _runMove(
        playerMove: _move(
          id: 'sketch',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_sketch',
        ),
      );

      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'sketch');
      expect(
        _failures(result).single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(_ppSpent(result, moveId: 'sketch'), isEmpty);
    });

    test('s_sketch fails before PP when the user is transformed', () {
      final result = _runMove(
        playerTransformState: const PsdkBattleTransformState(
          transformedFromSpeciesId: 'smeargle',
        ),
        opponentMove: _move(id: 'flamethrower', power: 90),
        opponentMoveHistory: PsdkBattleMoveHistory.empty().recordAttempt(
          moveId: 'flamethrower',
          turn: 0,
          targets: const <PsdkBattleSlotRef>[psdkPlayerSlot],
        ),
        playerMove: _move(
          id: 'sketch',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_sketch',
        ),
      );

      expect(_failures(result), hasLength(1));
      expect(_failures(result).single.moveId, 'sketch');
      expect(_ppSpent(result, moveId: 'sketch'), isEmpty);
    });

    test('s_sketch replaces the selected move slot with the target last move',
        () {
      final targetMove = _move(
        id: 'flamethrower',
        category: PsdkBattleMoveCategory.special,
        power: 90,
        battleEngineMethod: 's_basic',
      ).copyWith(currentPp: 3);
      final result = _runMove(
        selectedMoveSlot: 1,
        playerMove: _move(id: 'tackle', power: 40),
        playerExtraMoves: <PsdkBattleMoveData>[
          _move(
            id: 'sketch',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_sketch',
          ),
        ],
        opponentMove: targetMove,
        opponentMoveHistory: PsdkBattleMoveHistory.empty().recordAttempt(
          moveId: 'flamethrower',
          turn: 0,
          targets: const <PsdkBattleSlotRef>[psdkPlayerSlot],
        ),
      );

      final copied = result.state.battlerAt(psdkPlayerSlot).moves[1];
      expect(_failures(result), isEmpty);
      expect(copied.id, 'flamethrower');
      expect(copied.pp, targetMove.pp);
      expect(copied.currentPp, targetMove.pp);
      expect(result.state.battlerAt(psdkPlayerSlot).moves[0].id, 'tackle');
      expect(_ppSpent(result, moveId: 'sketch'), hasLength(1));
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  List<PsdkBattleMoveData> playerExtraMoves = const <PsdkBattleMoveData>[],
  PsdkBattleMajorStatus? playerMajorStatus,
  String? playerAbilityId,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleMoveHistory? opponentMoveHistory,
  PsdkBattleTransformState playerTransformState =
      const PsdkBattleTransformState(),
  int genericSeed = 0,
  int selectedMoveSlot = 0,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: 100,
        move: playerMove,
        extraMoves: playerExtraMoves,
        majorStatus: playerMajorStatus,
        abilityId: playerAbilityId,
        transformState: playerTransformState,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: 1,
        move: opponentMove ??
            _move(
              id: 'opponent_wait',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 1,
              battleEngineMethod: 's_splash',
            ),
        moveHistory: opponentMoveHistory,
      ),
      rngSeeds: PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: genericSeed,
      ),
    ),
  );
  return engine.submit(PsdkBattleDecision.fight(moveSlot: selectedMoveSlot));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
  List<PsdkBattleMoveData> extraMoves = const <PsdkBattleMoveData>[],
  PsdkBattleMajorStatus? majorStatus,
  String? abilityId,
  PsdkBattleTransformState transformState = const PsdkBattleTransformState(),
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
    moves: <PsdkBattleMoveData>[move, ...extraMoves],
    majorStatus: majorStatus,
    abilityId: abilityId,
    transformState: transformState,
    moveHistory: moveHistory,
  );
}

PsdkBattleMoveData _move({
  required String id,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
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

List<PsdkBattleMoveFailedEvent> _failures(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleMoveFailedEvent>()
      .toList(growable: false);
}

List<PsdkBattleMovePpSpentEvent> _ppSpent(
  PsdkBattleTurnResult result, {
  required String moveId,
  PsdkBattleSlotRef? user,
}) {
  return result.timeline.events
      .whereType<PsdkBattleMovePpSpentEvent>()
      .where((event) => event.moveId == moveId)
      .where((event) => user == null || event.user == user)
      .toList(growable: false);
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
