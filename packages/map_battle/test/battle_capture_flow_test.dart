import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _stats = BattleStatsSnapshot(
  attack: 30,
  defense: 30,
  specialAttack: 30,
  specialDefense: 30,
  speed: 30,
);

void main() {
  group('legacy capture flow', () {
    test('fails closed when capture is enabled without catchRate', () {
      expect(
        () => createBattleSession(_legacySetup(catchRate: null)),
        throwsArgumentError,
      );
    });

    test(
        'failed attempt consumes the turn, lets the opponent act and continues',
        () {
      final before = createBattleSession(
        _legacySetup(catchRate: 1),
        rng: const BattleSeededRng(state: 47),
      );

      final after = before.applyChoice(const PlayerBattleChoiceCapture());

      expect(after.state.isFinished, isFalse);
      expect(after.state.currentTurn, isNotNull);
      expect(after.state.currentTurn!.playerAction, isA<BattleActionCapture>());
      expect(
          after.state.currentTurn!.captureAttemptEvents.single.caught, isFalse);
      expect(
        after.state.currentTurn!.captureAttemptEvents.single.attemptId,
        'capture-attempt-1',
      );
      expect(after.state.player.currentHp, lessThan(100));

      final second = after.applyChoice(const PlayerBattleChoiceCapture());
      expect(
        second.state.currentTurn!.captureAttemptEvents.single.attemptId,
        'capture-attempt-2',
      );
    });

    test('successful attempt ends battle and preserves the wild snapshot', () {
      final before = createBattleSession(
        _legacySetup(
          catchRate: 255,
          enemyHp: 1,
          enemyStatus: const BattleMajorStatusState.slp(),
        ),
        rng: const BattleScriptedRng(<int>[1]),
      );

      final after = before.applyChoice(const PlayerBattleChoiceCapture());

      expect(after.state.outcome?.isCaptured, isTrue);
      expect(after.state.outcome?.captureItemId, canonicalPokeBallItemId);
      expect(after.state.outcome?.captureAttemptId, 'capture-attempt-1');
      expect(after.state.enemy.currentHp, 1);
      expect(after.state.enemy.majorStatus?.id, BattleMajorStatusId.slp);
      expect(
          after.state.currentTurn!.captureAttemptEvents.single.caught, isTrue);
      expect(
        after.state.currentTurn!.captureAttemptEvents.single.attemptId,
        after.state.outcome!.captureAttemptId,
      );
    });

    test('trainer battle rejects capture without advancing RNG', () {
      const rng = BattleScriptedRng(<int>[1]);
      final session = createBattleSession(
        _legacySetup(catchRate: 45, isTrainerBattle: true),
        rng: rng,
      );

      expect(
        () => session.applyChoice(const PlayerBattleChoiceCapture()),
        throwsStateError,
      );
      expect(rng.index, 0);
    });
  });

  group('clean PSDK capture flow', () {
    test('native capture decision uses the same formula and generic RNG stream',
        () {
      final legacy = createBattleSession(
        _legacySetup(catchRate: 1),
        rng: const BattleSeededRng(state: 47),
      ).applyChoice(const PlayerBattleChoiceCapture());
      final engine = BattleEngine(
        setup: _psdkSetup(catchRate: 1, genericSeed: 47),
      );

      final result = engine.submit(
        const BattleDecision.capture(
          itemId: canonicalPokeBallItemId,
          rateNumerator: 1,
          rateDenominator: 1,
        ),
      );
      final attempt = result.timeline.events
          .whereType<BattleCaptureAttemptTimelineEvent>()
          .single;

      expect(attempt.caught,
          legacy.state.currentTurn!.captureAttemptEvents.single.caught);
      expect(attempt.attemptId, 'capture-attempt-1');
      expect(result.outcome, isNull);
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(100));
      expect(result.nextRequest, isNotNull);
    });

    test('successful capture produces a native captured outcome', () {
      final engine = BattleEngine(
        setup: _psdkSetup(
          catchRate: 255,
          enemyHp: 1,
          enemyStatus: PsdkBattleMajorStatus.sleep,
          genericSeed: 47,
        ),
      );

      final result = engine.submit(
        const BattleDecision.capture(
          itemId: 'aurora-orb',
          rateNumerator: 5,
          rateDenominator: 2,
        ),
      );

      expect(result.outcome?.kind, BattleEngineOutcomeKind.captured);
      expect(result.outcome?.captureAttemptId, 'capture-attempt-1');
      expect(
        result.timeline.events
            .whereType<BattleCaptureAttemptTimelineEvent>()
            .single
            .ballId,
        'aurora-orb',
      );
      expect(
        result.timeline.events
            .whereType<BattleCaptureAttemptTimelineEvent>()
            .single
            .attemptId,
        result.outcome!.captureAttemptId,
      );
      expect(
        result.timeline.events
            .whereType<BattleCaptureAttemptTimelineEvent>()
            .single
            .caught,
        isTrue,
      );
    });

    test('trainer setup rejects capture capability', () {
      expect(
        () => BattleEngine(
          setup: _psdkSetup(
            catchRate: 45,
            genericSeed: 47,
            isTrainerBattle: true,
            canCapture: true,
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

BattleSetup _legacySetup({
  required int? catchRate,
  int enemyHp = 100,
  BattleMajorStatusState? enemyStatus,
  bool isTrainerBattle = false,
}) {
  return BattleSetup(
    playerPokemon: BattleCombatantData(
      speciesId: 'player',
      level: 10,
      maxHp: 100,
      stats: _stats,
      moves: <BattleMoveData>[
        BattleMoveData(id: 'wait', name: 'Wait', power: 0),
      ],
    ),
    enemyPokemon: BattleCombatantData(
      speciesId: 'wild',
      level: 10,
      maxHp: 100,
      currentHp: enemyHp,
      catchRate: catchRate,
      majorStatus: enemyStatus,
      stats: _stats,
      moves: <BattleMoveData>[
        BattleMoveData(id: 'tackle', name: 'Tackle', power: 20),
      ],
    ),
    isTrainerBattle: isTrainerBattle,
    trainerId: isTrainerBattle ? 'trainer' : null,
    allowCapture: !isTrainerBattle,
  );
}

BattleEngineSetup _psdkSetup({
  required int catchRate,
  required int genericSeed,
  int enemyHp = 100,
  PsdkBattleMajorStatus? enemyStatus,
  bool isTrainerBattle = false,
  bool canCapture = true,
}) {
  return BattleEngineSetup.singles(
    player: _psdkCombatant(id: 'player_0', speciesId: 'player'),
    opponent: _psdkCombatant(
      id: 'opponent_0',
      speciesId: 'wild',
      currentHp: enemyHp,
      catchRate: catchRate,
      majorStatus: enemyStatus,
    ),
    rngSeeds: PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: genericSeed,
    ),
    isTrainerBattle: isTrainerBattle,
    canCapture: canCapture,
  );
}

PsdkBattleCombatantSetup _psdkCombatant({
  required String id,
  required String speciesId,
  int currentHp = 100,
  int? catchRate,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 10,
    maxHp: 100,
    currentHp: currentHp,
    catchRate: catchRate,
    majorStatus: majorStatus,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 30,
      defense: 30,
      specialAttack: 30,
      specialDefense: 30,
      speed: 30,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 20,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}
