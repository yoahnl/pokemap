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

    test('s_fury_cutter resets when the previous successful move is different',
        () {
      final first = _runMove(
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );
      final reset = _runMove(
        playerMoveHistory: _history(
          successes: const <String>['fury_cutter', 'tackle'],
        ),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );

      expect(
        _damage(reset, moveId: 'fury_cutter'),
        _damage(first, moveId: 'fury_cutter'),
      );
    });

    test('s_fury_cutter resets when the previous attempt failed', () {
      final first = _runMove(
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );
      final reset = _runMove(
        playerMoveHistory: _history(
          attempts: const <String>['fury_cutter', 'fury_cutter'],
          successes: const <String>['fury_cutter'],
        ),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );

      expect(
        _damage(reset, moveId: 'fury_cutter'),
        _damage(first, moveId: 'fury_cutter'),
      );
    });

    test('s_fury_cutter caps at 160 base power', () {
      final capped = _runMove(
        playerMoveHistory: _successes('fury_cutter', count: 2),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );
      final overCapped = _runMove(
        playerMoveHistory: _successes('fury_cutter', count: 5),
        playerMove: _move(
          id: 'fury_cutter',
          type: 'bug',
          power: 40,
          battleEngineMethod: 's_fury_cutter',
        ),
      );

      expect(
        _damage(overCapped, moveId: 'fury_cutter'),
        _damage(capped, moveId: 'fury_cutter'),
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

      test('${entry.method} doubles once after Defense Curl succeeded', () {
        final first = _runMove(
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            battleEngineMethod: entry.method,
          ),
        );
        final curled = _runMove(
          playerMoveHistory: _history(successes: const <String>[
            'defense_curl',
          ]),
          playerMove: _move(
            id: entry.moveId,
            type: entry.method == 's_rollout' ? 'rock' : 'ice',
            power: 30,
            battleEngineMethod: entry.method,
          ),
        );

        expect(
          _damage(curled, moveId: entry.moveId),
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

    test('s_round doubles power when an ally used Round this turn', () {
      final round = _move(
        id: 'round',
        category: PsdkBattleMoveCategory.special,
        power: 60,
        battleEngineMethod: 's_round',
      );
      final baseline = _resolveRound(
        move: round,
        allyMoveHistory: PsdkBattleMoveHistory.empty(),
      );
      final boosted = _resolveRound(
        move: round,
        allyMoveHistory: _historyAt(
          successes: const <String>['round'],
          turn: 7,
        ),
      );

      expect(
        _resolutionDamage(boosted, moveId: 'round'),
        greaterThan(_resolutionDamage(baseline, moveId: 'round')),
      );
    });

    test('s_pledge combines with an ally pledge and installs field effect', () {
      final firePledge = _move(
        id: 'fire_pledge',
        type: 'fire',
        category: PsdkBattleMoveCategory.special,
        power: 80,
        battleEngineMethod: 's_pledge',
      );
      final waterPledge = _move(
        id: 'water_pledge',
        type: 'water',
        category: PsdkBattleMoveCategory.special,
        power: 80,
        battleEngineMethod: 's_pledge',
      );
      final baseline = _resolvePledge(
        playerMove: firePledge,
        allyMove: waterPledge,
        allyMoveHistory: PsdkBattleMoveHistory.empty(),
      );
      final combined = _resolvePledge(
        playerMove: firePledge,
        allyMove: waterPledge,
        allyMoveHistory: _historyAt(
          successes: const <String>['water_pledge'],
          turn: 7,
        ),
      );

      expect(
        _resolutionDamage(combined, moveId: 'fire_pledge'),
        greaterThan(_resolutionDamage(baseline, moveId: 'fire_pledge')),
      );
      expect(
        combined.state
            .battlerAt(psdkPlayerSlot)
            .effects
            .contains('pledge_rainbow'),
        isTrue,
      );
    });

    test('s_pledge combo uses the PSDK 160 base power', () {
      final firePledge = _move(
        id: 'fire_pledge',
        type: 'fire',
        category: PsdkBattleMoveCategory.special,
        power: 80,
        battleEngineMethod: 's_pledge',
      );
      final waterPledge = _move(
        id: 'water_pledge',
        type: 'water',
        category: PsdkBattleMoveCategory.special,
        power: 80,
        battleEngineMethod: 's_pledge',
      );
      final combined = _resolvePledge(
        playerMove: firePledge,
        allyMove: waterPledge,
        allyMoveHistory: _historyAt(
          successes: const <String>['water_pledge'],
          turn: 7,
        ),
      );
      final power160 = _runMove(
        playerMove: _move(
          id: 'fire_pledge',
          type: 'fire',
          category: PsdkBattleMoveCategory.special,
          power: 160,
        ),
      );

      expect(
        _resolutionDamage(combined, moveId: 'fire_pledge'),
        _damage(power160, moveId: 'fire_pledge'),
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

    test('s_trump_card bypasses accuracy against reachable targets', () {
      final result = _runMove(
        playerMove: _move(
          id: 'trump_card',
          category: PsdkBattleMoveCategory.special,
          power: 1,
          accuracy: 1,
          pp: 8,
          currentPp: 2,
          battleEngineMethod: 's_trump_card',
        ),
      );

      expect(_damageEvents(result, moveId: 'trump_card'), hasLength(1));
      expect(
        result.timeline.events.map((event) => event.kind),
        isNot(contains('move_missed')),
      );
    });
  });
}

PsdkBattleMoveHistory _successes(String moveId, {required int count}) {
  return _history(successes: <String>[
    for (var i = 0; i < count; i++) moveId,
  ]);
}

PsdkBattleMoveHistory _history({
  List<String>? attempts,
  required List<String> successes,
}) {
  final attemptIds = attempts ?? successes;
  return PsdkBattleMoveHistory(
    attempts: <PsdkBattleMoveHistoryEntry>[
      for (var i = 0; i < attemptIds.length; i++)
        PsdkBattleMoveHistoryEntry(
          moveId: attemptIds[i],
          turn: i + 1,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
    successes: <PsdkBattleMoveHistoryEntry>[
      for (var i = 0; i < successes.length; i++)
        PsdkBattleMoveHistoryEntry(
          moveId: successes[i],
          turn: i + 1,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
  );
}

PsdkBattleMoveHistory _historyAt({
  required List<String> successes,
  required int turn,
}) {
  return PsdkBattleMoveHistory(
    attempts: <PsdkBattleMoveHistoryEntry>[
      for (final moveId in successes)
        PsdkBattleMoveHistoryEntry(
          moveId: moveId,
          turn: turn,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
    successes: <PsdkBattleMoveHistoryEntry>[
      for (final moveId in successes)
        PsdkBattleMoveHistoryEntry(
          moveId: moveId,
          turn: turn,
          targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
        ),
    ],
  );
}

BattleMoveBehaviorResolution _resolveRound({
  required PsdkBattleMoveData move,
  required PsdkBattleMoveHistory allyMoveHistory,
}) {
  const userSlot = psdkPlayerSlot;
  const allySlot = PsdkBattleSlotRef(bank: 0, position: 1);
  const targetSlot = psdkOpponentSlot;
  final state = PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      userSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'player', speed: 100, move: move),
      ),
      allySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'ally',
          speed: 50,
          move: move,
          moveHistory: allyMoveHistory,
        ),
      ),
      targetSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent',
          speed: 1,
          move: _move(
            id: 'opponent_wait',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            battleEngineMethod: 's_splash',
          ),
        ),
      ),
    },
  );

  return createStaticBasicMoveRegistry().resolve('s_round').resolve(
        BattleMoveBehaviorContext(
          state: state,
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
          turn: 7,
          user: userSlot,
          target: targetSlot,
          move: BattleMoveDefinition.fromPsdk(move),
        ),
      );
}

BattleMoveBehaviorResolution _resolvePledge({
  required PsdkBattleMoveData playerMove,
  required PsdkBattleMoveData allyMove,
  required PsdkBattleMoveHistory allyMoveHistory,
}) {
  const userSlot = psdkPlayerSlot;
  const allySlot = PsdkBattleSlotRef(bank: 0, position: 1);
  const targetSlot = psdkOpponentSlot;
  final state = PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      userSlot: PsdkBattleCombatant.fromSetup(
        _combatant(id: 'player', speed: 100, move: playerMove),
      ),
      allySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'ally',
          speed: 50,
          move: allyMove,
          moveHistory: allyMoveHistory,
        ),
      ),
      targetSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent',
          speed: 1,
          move: _move(
            id: 'opponent_wait',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            battleEngineMethod: 's_splash',
          ),
        ),
      ),
    },
  );

  return createStaticBasicMoveRegistry().resolve('s_pledge').resolve(
        BattleMoveBehaviorContext(
          state: state,
          rng: BattleRngStreams.fromSeeds(
            moveDamageSeed: 1,
            moveCriticalSeed: 99999,
            moveAccuracySeed: 3,
            genericSeed: 4,
          ),
          turn: 7,
          user: userSlot,
          target: targetSlot,
          move: BattleMoveDefinition.fromPsdk(playerMove),
        ),
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

int _resolutionDamage(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .single
      .damage;
}
