import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK history-powered move families', () {
    test(
        's_avalanche doubles power after the target damaged the user this turn',
        () {
      final boosted = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'avalanche',
          type: 'ice',
          power: 60,
          battleEngineMethod: 's_avalanche',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );
      final normal = _runMove(
        playerSpeed: 100,
        opponentSpeed: 1,
        playerMove: _move(
          id: 'avalanche',
          type: 'ice',
          power: 60,
          battleEngineMethod: 's_avalanche',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      expect(
        _damage(boosted, moveId: 'avalanche'),
        greaterThan(_damage(normal, moveId: 'avalanche')),
      );
    });

    test('s_revenge doubles power after the target damaged the user this turn',
        () {
      final boosted = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'revenge',
          type: 'fighting',
          power: 60,
          battleEngineMethod: 's_revenge',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );
      final normal = _runMove(
        playerSpeed: 100,
        opponentSpeed: 1,
        playerMove: _move(
          id: 'revenge',
          type: 'fighting',
          power: 60,
          battleEngineMethod: 's_revenge',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      expect(
        _damage(boosted, moveId: 'revenge'),
        greaterThan(_damage(normal, moveId: 'revenge')),
      );
    });

    test('s_payback doubles power after any current-turn damage to the user',
        () {
      final boosted = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'payback',
          type: 'dark',
          power: 50,
          battleEngineMethod: 's_payback',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );
      final normal = _runMove(
        playerSpeed: 100,
        opponentSpeed: 1,
        playerMove: _move(
          id: 'payback',
          type: 'dark',
          power: 50,
          battleEngineMethod: 's_payback',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      expect(
        _damage(boosted, moveId: 'payback'),
        greaterThan(_damage(normal, moveId: 'payback')),
      );
    });

    test('s_rage_fist gains 50 base power per recorded damage entry', () {
      final normal = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
        playerMove: _move(
          id: 'rage_fist',
          type: 'ghost',
          power: 50,
          battleEngineMethod: 's_rage_fist',
        ),
      );
      final boosted = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
        playerDamageHistory: PsdkBattleDamageHistory(
          entries: const <PsdkBattleDamageHistoryEntry>[
            PsdkBattleDamageHistoryEntry(
              turn: 1,
              source: psdkOpponentSlot,
              moveId: 'hit_one',
              damage: 10,
              remainingHp: 90,
            ),
            PsdkBattleDamageHistoryEntry(
              turn: 2,
              source: psdkOpponentSlot,
              moveId: 'hit_two',
              damage: 10,
              remainingHp: 80,
            ),
          ],
        ),
        playerMove: _move(
          id: 'rage_fist',
          type: 'ghost',
          power: 50,
          battleEngineMethod: 's_rage_fist',
        ),
      );

      expect(
        _damage(boosted, moveId: 'rage_fist'),
        greaterThan(_damage(normal, moveId: 'rage_fist')),
      );
    });

    test('s_assurance doubles power when the target took damage this turn', () {
      final normal = _runMove(
        playerMove: _move(
          id: 'assurance',
          type: 'dark',
          power: 60,
          battleEngineMethod: 's_assurance',
        ),
      );
      final boosted = _runMove(
        opponentDamageHistory: PsdkBattleDamageHistory(
          entries: const <PsdkBattleDamageHistoryEntry>[
            PsdkBattleDamageHistoryEntry(
              turn: 1,
              source: psdkOpponentSlot,
              moveId: 'ally_hit',
              damage: 10,
              remainingHp: 90,
            ),
          ],
        ),
        playerMove: _move(
          id: 'assurance',
          type: 'dark',
          power: 60,
          battleEngineMethod: 's_assurance',
        ),
      );

      expect(
        _damage(boosted, moveId: 'assurance'),
        greaterThan(_damage(normal, moveId: 'assurance')),
      );
    });

    test('s_fishious_rend doubles power when the user moves before the target',
        () {
      final boosted = _runMove(
        playerSpeed: 100,
        opponentSpeed: 1,
        playerMove: _move(
          id: 'fishious_rend',
          type: 'water',
          power: 85,
          battleEngineMethod: 's_fishious_rend',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );
      final normal = _runMove(
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'fishious_rend',
          type: 'water',
          power: 85,
          battleEngineMethod: 's_fishious_rend',
        ),
        opponentMove: _move(id: 'opponent_tackle', power: 40),
      );

      expect(
        _damage(boosted, moveId: 'fishious_rend'),
        greaterThan(_damage(normal, moveId: 'fishious_rend')),
      );
    });

    test('s_lash_out doubles power after a current-turn negative stat change',
        () {
      final normal = _runMove(
        playerMove: _move(
          id: 'lash_out',
          type: 'dark',
          power: 75,
          battleEngineMethod: 's_lash_out',
        ),
      );
      final boosted = _runMove(
        playerStatHistory: PsdkBattleStatHistory(
          entries: const <PsdkBattleStatHistoryEntry>[
            PsdkBattleStatHistoryEntry(
              turn: 1,
              stat: 'attack',
              delta: -1,
              currentStage: -1,
            ),
          ],
        ),
        playerMove: _move(
          id: 'lash_out',
          type: 'dark',
          power: 75,
          battleEngineMethod: 's_lash_out',
        ),
      );

      expect(
        _damage(boosted, moveId: 'lash_out'),
        greaterThan(_damage(normal, moveId: 'lash_out')),
      );
    });

    test('s_stomping_tantrum doubles power after the previous move failed', () {
      final normal = _runMove(
        playerMoveHistory: PsdkBattleMoveHistory(
          attempts: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'previous_success',
              turn: 0,
              targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'previous_success',
              turn: 0,
              targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
        playerMove: _move(
          id: 'stomping_tantrum',
          type: 'ground',
          power: 75,
          battleEngineMethod: 's_stomping_tantrum',
        ),
      );
      final boosted = _runMove(
        playerMoveHistory: PsdkBattleMoveHistory(
          attempts: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'previous_failure',
              turn: 0,
              targets: const <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
        playerMove: _move(
          id: 'stomping_tantrum',
          type: 'ground',
          power: 75,
          battleEngineMethod: 's_stomping_tantrum',
        ),
      );

      expect(
        _damage(boosted, moveId: 'stomping_tantrum'),
        greaterThan(_damage(normal, moveId: 'stomping_tantrum')),
      );
    });

    test('s_retaliate doubles when a same-bank battler fainted last turn', () {
      final normal = _resolveMoveWithState(
        state: _stateWithRetaliateUser(),
        move: _move(
          id: 'retaliate',
          power: 70,
          battleEngineMethod: 's_retaliate',
        ),
      );
      final boosted = _resolveMoveWithState(
        state: _stateWithRetaliateUser(
          allyDamageHistory: PsdkBattleDamageHistory(
            entries: const <PsdkBattleDamageHistoryEntry>[
              PsdkBattleDamageHistoryEntry(
                turn: 1,
                source: psdkOpponentSlot,
                moveId: 'opponent_tackle',
                damage: 100,
                remainingHp: 0,
              ),
            ],
          ),
        ),
        move: _move(
          id: 'retaliate',
          power: 70,
          battleEngineMethod: 's_retaliate',
        ),
      );

      expect(
        _resolutionDamage(boosted, moveId: 'retaliate'),
        greaterThan(_resolutionDamage(normal, moveId: 'retaliate')),
      );
    });
  });
}

BattleMoveBehaviorResolution _resolveMoveWithState({
  required PsdkBattleState state,
  required PsdkBattleMoveData move,
}) {
  return createStaticBasicMoveRegistry()
      .resolve(move.battleEngineMethod)
      .resolve(
        BattleMoveBehaviorContext(
          state: state,
          rng: BattleRngStreams.fromPsdkSeeds(
            const PsdkBattleRngSeeds(
              moveDamage: 1,
              moveCritical: 99999,
              moveAccuracy: 3,
              generic: 4,
            ),
          ),
          turn: 2,
          user: psdkPlayerSlot,
          target: psdkOpponentSlot,
          move: BattleMoveDefinition.fromPsdk(move),
        ),
      );
}

PsdkBattleState _stateWithRetaliateUser({
  PsdkBattleDamageHistory allyDamageHistory =
      const PsdkBattleDamageHistory.empty(),
}) {
  const allySlot = PsdkBattleSlotRef(bank: 0, position: -1);
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'player',
          speed: 100,
          move: _move(
            id: 'retaliate',
            power: 70,
            battleEngineMethod: 's_retaliate',
          ),
        ),
      ),
      allySlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'fainted_ally',
          speed: 1,
          move: _move(id: 'ally_wait', power: 0),
          damageHistory: allyDamageHistory,
        ),
      ).copyWith(currentHp: allyDamageHistory.entries.isEmpty ? 100 : 0),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          id: 'opponent',
          speed: 1,
          move: _move(id: 'opponent_wait', power: 0),
        ),
      ),
    },
  );
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleDamageHistory playerDamageHistory =
      const PsdkBattleDamageHistory.empty(),
  PsdkBattleDamageHistory opponentDamageHistory =
      const PsdkBattleDamageHistory.empty(),
  PsdkBattleStatHistory playerStatHistory = const PsdkBattleStatHistory.empty(),
  PsdkBattleMoveHistory? playerMoveHistory,
  int playerSpeed = 100,
  int opponentSpeed = 1,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        speed: playerSpeed,
        move: playerMove,
        damageHistory: playerDamageHistory,
        statHistory: playerStatHistory,
        moveHistory: playerMoveHistory,
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: opponentSpeed,
        types: opponentTypes,
        damageHistory: opponentDamageHistory,
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

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  required PsdkBattleMoveData move,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleDamageHistory damageHistory = const PsdkBattleDamageHistory.empty(),
  PsdkBattleStatHistory statHistory = const PsdkBattleStatHistory.empty(),
  PsdkBattleMoveHistory? moveHistory,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    damageHistory: damageHistory,
    statHistory: statHistory,
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

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}

int _resolutionDamage(
  BattleMoveBehaviorResolution result, {
  required String moveId,
}) {
  return result.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
