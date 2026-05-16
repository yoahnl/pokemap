import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK status lifecycle handlers', () {
    test('applies status effects and blocks simple type immunities', () {
      final context = BattleHandlerContext(
        state: PsdkBattleState.fromSetup(
          _setup(
            opponentTypes: const PsdkBattleTypes(primary: 'fire'),
          ),
        ),
        rng: _rng(),
        turn: 1,
        user: psdkPlayerSlot,
      );

      final burn = const BattleStatusChangeHandler().applyMajorStatus(
        context: context,
        target: psdkOpponentSlot,
        moveId: 'will_o_wisp',
        status: PsdkBattleMajorStatus.burn,
      );
      final paralysis = const BattleStatusChangeHandler().applyMajorStatus(
        context: context,
        target: psdkPlayerSlot,
        moveId: 'thunder_wave',
        status: PsdkBattleMajorStatus.paralysis,
      );

      expect(burn.applied, isFalse);
      expect(burn.reason, 'status_immune');
      expect(paralysis.applied, isTrue);
      expect(
        paralysis.state.battlerAt(psdkPlayerSlot).effects.values,
        contains('paralysis'),
      );
    });

    for (final terrainId in <PsdkBattleTerrainId>[
      PsdkBattleTerrainId.electricTerrain,
      PsdkBattleTerrainId.mistyTerrain,
    ]) {
      test('blocks sleep on grounded targets under ${terrainId.jsonName}', () {
        final context = BattleHandlerContext(
          state: PsdkBattleState.fromSetup(
            _setup(
              field: PsdkBattleFieldState(
                terrain: PsdkBattleTerrainState(
                  id: terrainId,
                  remainingTurns: 5,
                ),
              ),
            ),
          ),
          rng: _rng(),
          turn: 1,
          user: psdkPlayerSlot,
        );

        final sleep = const BattleStatusChangeHandler().applyMajorStatus(
          context: context,
          target: psdkOpponentSlot,
          moveId: 'sleep_powder',
          status: PsdkBattleMajorStatus.sleep,
        );

        expect(sleep.applied, isFalse);
        expect(sleep.reason, 'status_immune');
        expect(sleep.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      });
    }

    test('Misty Terrain blocks major statuses on grounded targets', () {
      final context = BattleHandlerContext(
        state: PsdkBattleState.fromSetup(
          _setup(
            field: const PsdkBattleFieldState(
              terrain: PsdkBattleTerrainState(
                id: PsdkBattleTerrainId.mistyTerrain,
                remainingTurns: 5,
              ),
            ),
          ),
        ),
        rng: _rng(),
        turn: 1,
        user: psdkPlayerSlot,
      );

      final burn = const BattleStatusChangeHandler().applyMajorStatus(
        context: context,
        target: psdkOpponentSlot,
        moveId: 'will_o_wisp',
        status: PsdkBattleMajorStatus.burn,
      );

      expect(burn.applied, isFalse);
      expect(burn.reason, 'status_immune');
      expect(burn.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
    });

    test('Misty Terrain does not block airborne target statuses', () {
      final context = BattleHandlerContext(
        state: PsdkBattleState.fromSetup(
          _setup(
            opponentTypes: const PsdkBattleTypes(primary: 'flying'),
            field: const PsdkBattleFieldState(
              terrain: PsdkBattleTerrainState(
                id: PsdkBattleTerrainId.mistyTerrain,
                remainingTurns: 5,
              ),
            ),
          ),
        ),
        rng: _rng(),
        turn: 1,
        user: psdkPlayerSlot,
      );

      final burn = const BattleStatusChangeHandler().applyMajorStatus(
        context: context,
        target: psdkOpponentSlot,
        moveId: 'will_o_wisp',
        status: PsdkBattleMajorStatus.burn,
      );

      expect(burn.applied, isTrue);
      expect(
        burn.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.burn,
      );
    });

    test('end turn applies burn poison and toxic residual damage', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'burned',
              majorStatus: PsdkBattleMajorStatus.burn,
            ),
          ),
          psdkOpponentSlot: PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'toxic',
              majorStatus: PsdkBattleMajorStatus.toxic,
              toxicCounter: 1,
            ),
          ),
          const PsdkBattleSlotRef(bank: 1, position: 1):
              PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'poisoned',
              majorStatus: PsdkBattleMajorStatus.poison,
            ),
          ),
        },
      );

      final result = const BattleEndTurnHandler().resolveEndTurn(
        BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 3,
          user: psdkPlayerSlot,
        ),
      );
      final damageEvents = result.events.whereType<PsdkBattleDamageEvent>();

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 88);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 88);
      expect(result.state.battlerAt(psdkOpponentSlot).toxicCounter, 2);
      expect(
        result.state
            .battlerAt(const PsdkBattleSlotRef(bank: 1, position: 1))
            .currentHp,
        88,
      );
      expect(
          damageEvents.map((event) => event.moveId), contains('status:burn'));
      expect(
        damageEvents.map((event) => event.moveId),
        contains('status:toxic'),
      );
    });
  });

  group('PSDK status action prevention', () {
    test('paralysis can stop the user before PP is spent', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMajorStatus: PsdkBattleMajorStatus.paralysis,
          genericSeed: 4,
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final failed =
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>();

      expect(failed.any((event) => event.reason == 'unusable_by_user'), isTrue);
      expect(result.state.battlerAt(psdkPlayerSlot).moves.single.currentPp, 35);
    });

    test('sleep increments turns then wakes and allows the move', () {
      final engine = PsdkBattleEngine(
        setup: _setup(playerMajorStatus: PsdkBattleMajorStatus.sleep),
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final third = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(first.state.battlerAt(psdkPlayerSlot).sleepTurns, 1);
      expect(second.state.battlerAt(psdkPlayerSlot).sleepTurns, 2);
      expect(third.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(
        third.timeline.events
            .whereType<PsdkBattleDamageEvent>()
            .any((event) => event.moveId == 'tackle'),
        isTrue,
      );
    });

    test('freeze prevents the user when the thaw roll fails', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMajorStatus: PsdkBattleMajorStatus.freeze,
          genericSeed: 4,
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .any((event) => event.reason == 'unusable_by_user'),
        isTrue,
      );
      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus,
          PsdkBattleMajorStatus.freeze);
    });
  });

  group('PSDK status-dependent move parity', () {
    test('a real applied burn powers Hex on the next turn', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
          playerMoves: <PsdkBattleMoveData>[
            _statusMove(
              id: 'will_o_wisp',
              status: PsdkBattleMajorStatus.burn,
            ),
            _move(
              id: 'hex',
              type: 'ghost',
              category: PsdkBattleMoveCategory.special,
              power: 65,
              battleEngineMethod: 's_hex',
            ),
          ],
        ),
      );

      final first = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const PsdkBattleDecision.fight(moveSlot: 1));

      expect(first.state.battlerAt(psdkOpponentSlot).majorStatus,
          PsdkBattleMajorStatus.burn);
      expect(_damage(second, moveId: 'hex'), greaterThan(20));
    });
  });
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}

PsdkBattleSetup _setup({
  List<PsdkBattleMoveData>? playerMoves,
  PsdkBattleMajorStatus? playerMajorStatus,
  PsdkBattleMajorStatus? opponentMajorStatus,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  int genericSeed = 5,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      speed: 100,
      moves:
          playerMoves ?? <PsdkBattleMoveData>[_move(id: 'tackle', power: 40)],
      majorStatus: playerMajorStatus,
    ),
    opponent: _combatant(
      id: 'opponent',
      speed: 1,
      types: opponentTypes,
      moves: <PsdkBattleMoveData>[
        _move(
          id: 'splash',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_splash',
        ),
      ],
      majorStatus: opponentMajorStatus,
    ),
    rngSeeds: PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: genericSeed,
    ),
    field: field,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  int speed = 50,
  List<PsdkBattleMoveData>? moves,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleMajorStatus? majorStatus,
  int toxicCounter = 0,
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
    moves: moves ?? <PsdkBattleMoveData>[_move(id: 'tackle', power: 40)],
    majorStatus: majorStatus,
    toxicCounter: toxicCounter,
  );
}

PsdkBattleMoveData _statusMove({
  required String id,
  required PsdkBattleMajorStatus status,
}) {
  return _move(
    id: id,
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 100,
    battleEngineMethod: 's_status',
    statuses: <PsdkBattleMoveStatus>[
      PsdkBattleMoveStatus(status: status, chance: 100),
    ],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String? dbSymbol,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: dbSymbol ?? id,
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
    statuses: statuses,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 5,
  );
}
