import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK move effect hook convergence', () {
    test('s_yawn puts the target to sleep on the next end turn', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'yawn',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              battleEngineMethod: 's_yawn',
              target: PsdkBattleMoveTarget.adjacentFoe,
            ),
            _move(
              id: 'splash',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              battleEngineMethod: 's_splash',
              target: PsdkBattleMoveTarget.none,
            ),
          ],
        ),
      );

      final firstTurn = engine.submit(
        const PsdkBattleDecision.fight(moveSlot: 0),
      );
      expect(firstTurn.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        firstTurn.state.battlerAt(psdkOpponentSlot).effects.contains(
              'drowsiness',
            ),
        isTrue,
      );

      final secondTurn = engine.submit(
        const PsdkBattleDecision.fight(moveSlot: 1),
      );

      expect(
        secondTurn.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.sleep,
      );
      expect(
        secondTurn.state.battlerAt(psdkOpponentSlot).effects.contains(
              'drowsiness',
            ),
        isFalse,
      );
      expect(
        secondTurn.timeline.events.whereType<PsdkBattleStatusEvent>(),
        contains(
          isA<PsdkBattleStatusEvent>()
              .having((event) => event.moveId, 'moveId', 'effect:drowsiness')
              .having((event) => event.status, 'status',
                  PsdkBattleMajorStatus.sleep),
        ),
      );
    });

    test('s_yawn clears drowsiness without sleep under Electric Terrain', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          field: const PsdkBattleFieldState(
            terrain: PsdkBattleTerrainState(
              id: PsdkBattleTerrainId.electricTerrain,
              remainingTurns: 5,
            ),
          ),
          playerMoves: <PsdkBattleMoveData>[
            _move(
              id: 'yawn',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              battleEngineMethod: 's_yawn',
              target: PsdkBattleMoveTarget.adjacentFoe,
            ),
            _move(
              id: 'splash',
              category: PsdkBattleMoveCategory.status,
              power: 0,
              accuracy: 0,
              battleEngineMethod: 's_splash',
              target: PsdkBattleMoveTarget.none,
            ),
          ],
        ),
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final secondTurn = engine.submit(
        const PsdkBattleDecision.fight(moveSlot: 1),
      );

      expect(secondTurn.state.battlerAt(psdkOpponentSlot).majorStatus, isNull);
      expect(
        secondTurn.state.battlerAt(psdkOpponentSlot).effects.contains(
              'drowsiness',
            ),
        isFalse,
      );
    });

    test('s_fairy_lock prevents non-Ghost switching from the field', () {
      final result = _runMove(
        playerMove: _move(
          id: 'fairy_lock',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_fairy_lock',
          target: PsdkBattleMoveTarget.allBattlers,
        ),
      );

      final prevention = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: result.state,
          rng: _rng(),
          turn: 2,
          user: psdkOpponentSlot,
        ),
        target: psdkOpponentSlot,
      );

      final effect = result.state
          .battlerAt(psdkPlayerSlot)
          .effects
          .effects
          .singleWhere((effect) => effect.id == 'fairy_lock');

      expect(effect.remainingTurns, 2);
      expect(prevention.applied, isFalse);
      expect(prevention.reason, 'fairy_lock');
    });

    test('s_fairy_lock lets Ghost targets switch through', () {
      final result = _runMove(
        opponentTypes: const PsdkBattleTypes(primary: 'ghost'),
        playerMove: _move(
          id: 'fairy_lock',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_fairy_lock',
          target: PsdkBattleMoveTarget.allBattlers,
        ),
      );

      final prevention = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: result.state,
          rng: _rng(),
          turn: 2,
          user: psdkOpponentSlot,
        ),
        target: psdkOpponentSlot,
      );

      expect(prevention.applied, isTrue);
      expect(prevention.reason, isNull);
    });

    test('s_octolock traps and drops Defense and Special Defense each turn',
        () {
      final result = _runMove(
        playerMove: _move(
          id: 'octolock',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          accuracy: 0,
          battleEngineMethod: 's_octolock',
          target: PsdkBattleMoveTarget.adjacentFoe,
        ),
      );
      final opponent = result.state.battlerAt(psdkOpponentSlot);
      final prevention = const BattleSwitchHandler().resolveSwitchPrevention(
        context: BattleHandlerContext(
          state: result.state,
          rng: _rng(),
          turn: 2,
          user: psdkOpponentSlot,
        ),
        target: psdkOpponentSlot,
      );

      expect(opponent.effects.contains('octolock'), isTrue);
      expect(opponent.statStages.valueOf('defense'), -1);
      expect(opponent.statStages.valueOf('specialDefense'), -1);
      expect(prevention.applied, isFalse);
      expect(prevention.reason, 'octolock');
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
}) {
  final engine = PsdkBattleEngine(
    setup: _setup(
      opponentTypes: opponentTypes,
      playerMoves: <PsdkBattleMoveData>[playerMove],
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleSetup _setup({
  required List<PsdkBattleMoveData> playerMoves,
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      speed: 100,
      moves: playerMoves,
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
          target: PsdkBattleMoveTarget.none,
        ),
      ],
    ),
    field: field,
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: speed,
    ),
    moves: moves,
  );
}

PsdkBattleMoveData _move({
  required String id,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  int power = 40,
  int accuracy = 100,
  String type = 'normal',
  String? battleEngineMethod,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 20,
    priority: 0,
    battleEngineMethod: battleEngineMethod ?? 's_basic',
    target: target,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromSeeds(
    moveDamageSeed: 1,
    moveCriticalSeed: 2,
    moveAccuracySeed: 3,
    genericSeed: 4,
  );
}
