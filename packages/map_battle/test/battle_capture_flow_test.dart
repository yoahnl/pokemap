import 'dart:collection';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _stats = BattleStatsSnapshot(
  attack: 30,
  defense: 30,
  specialAttack: 30,
  specialDefense: 30,
  speed: 30,
);

void main() {
  group('contextual capture opt-in', () {
    final policy = ProjectContextualCapturePolicy(
      rateRules: [
        ProjectCaptureRateRule(
          when: const ProjectCaptureAlwaysCondition(),
          adjustment: ProjectCaptureRateAdd(255),
        ),
      ],
      successEffects: [ProjectCaptureSetFriendship(200)],
    );

    test(
        'both engines carry an immutable receipt bound to the successful attempt',
        () {
      final context = BattleCaptureContext();
      final legacy = createBattleSession(
        _legacySetup(contextual: true,
            catchRate: 1,
            enemyHp: 1,
            enemyStatus: const BattleMajorStatusState.slp()),
        rng: const BattleScriptedRng([1]),
      ).applyChoice(PlayerBattleChoiceCapture(
        itemId: 'synthetic-orb',
        contextualPolicy: policy,
        captureContext: context,
      ));
      final event = legacy.state.currentTurn!.captureAttemptEvents.single;
      final action =
          legacy.state.currentTurn!.playerAction as BattleActionCapture;
      expect(event.caught, isTrue);
      expect(event.contextualReceipt!.attemptId, event.attemptId);
      expect(event.contextualReceipt!.ballId, event.ballId);
      expect(action.contextualReceipt, same(event.contextualReceipt));
      expect(event.contextualReceipt!.calculation.rate.afterClamp, 255);
      expect(
          event.contextualReceipt!.successEffects.single,
          isA<ProjectCaptureSetFriendship>()
              .having((effect) => effect.value, 'value', 200));
      expect(() => event.contextualReceipt!.successEffects.clear(),
          throwsUnsupportedError);
      expect(legacy.state.outcome!.captureAttemptId, event.attemptId);

      final engine = BattleEngine(
          setup: _psdkSetup(contextual: true,
              catchRate: 1,
              genericSeed: 47,
              enemyHp: 1,
              enemyStatus: PsdkBattleMajorStatus.sleep));
      final result = engine.submit(BattleDecision.capture(
        itemId: 'synthetic-orb',
        rateNumerator: 1,
        rateDenominator: 1,
        contextualPolicy: policy,
        captureContext: context,
      ));
      final clean = result.timeline.events
          .whereType<BattleCaptureAttemptTimelineEvent>()
          .single;
      expect(clean.caught, isTrue);
      expect(
          clean.contextualReceipt!.attemptId, result.outcome!.captureAttemptId);
      expect(
          clean.contextualReceipt!.toJson(), event.contextualReceipt!.toJson());
      final psdk = clean.toPsdkEvent() as PsdkBattleCaptureAttemptEvent;
      expect(psdk.contextualReceipt, same(clean.contextualReceipt));
      expect(psdk.toJson()['contextualReceipt'],
          clean.contextualReceipt!.toJson());
      final roundtrip = BattleTimelineEvent.fromPsdk(psdk)
          as BattleCaptureAttemptTimelineEvent;
      expect(roundtrip.contextualReceipt, same(clean.contextualReceipt));
    });

    test(
        'contextual failure retains its calculation but emits no success effect',
        () {
      final failure = ProjectContextualCapturePolicy(
          successEffects: [ProjectCaptureSetFriendship(200)]);
      final legacy = createBattleSession(_legacySetup(contextual: true, catchRate: 1),
              rng: const BattleSeededRng(state: 47))
          .applyChoice(PlayerBattleChoiceCapture(
              contextualPolicy: failure,
              captureContext: BattleCaptureContext()));
      final event = legacy.state.currentTurn!.captureAttemptEvents.single;
      expect(event.caught, isFalse);
      expect(event.contextualReceipt!.successEffects, isEmpty);
      expect(legacy.state.player.currentHp, lessThan(100));
      final clean =
          BattleEngine(setup: _psdkSetup(contextual: true, catchRate: 1, genericSeed: 47)).submit(
              BattleDecision.capture(
                  itemId: canonicalPokeBallItemId,
                  rateNumerator: 1,
                  rateDenominator: 1,
                  contextualPolicy: failure,
                  captureContext: BattleCaptureContext()));
      final cleanEvent = clean.timeline.events
          .whereType<BattleCaptureAttemptTimelineEvent>()
          .single;
      expect(cleanEvent.caught, isFalse);
      expect(cleanEvent.shakes, event.shakes);
      expect(cleanEvent.contextualReceipt!.toJson(),
          event.contextualReceipt!.toJson());
      expect(clean.state.battlerAt(psdkPlayerSlot).currentHp, lessThan(100));
    });

    test(
        'missing context refuses before legacy RNG or clean AI and turn events',
        () {
      final rng = _CaptureRngSpy();
      final legacy = createBattleSession(_legacySetup(contextual: true, catchRate: 45), rng: rng);
      expect(
          () => legacy
              .applyChoice(PlayerBattleChoiceCapture(contextualPolicy: policy)),
          throwsStateError);
      expect(rng.draws, 0);
      expect(legacy.captureAttemptSequence, 0);
      expect(legacy.state.currentTurn, isNull);
      final options = _AiOptionsSpy();
      final engine = BattleEngine(
          setup: _psdkSetup(contextual: true, catchRate: 45, genericSeed: 47),
          opponentAi: PsdkBattleAi(canUseItem: true, itemOptions: options));
      options.reads = 0;
      final before = engine.snapshot();
      expect(
          () => engine.submit(BattleDecision.capture(
              itemId: 'orb',
              rateNumerator: 1,
              rateDenominator: 1,
              contextualPolicy: policy)),
          throwsStateError);
      expect(options.reads, 0);
      expect(engine.snapshot().turnNumber, before.turnNumber);
      expect(engine.snapshot().rngSeeds.generic, before.rngSeeds.generic);
      final valid = engine.submit(const BattleDecision.capture(
          itemId: 'orb', rateNumerator: 1, rateDenominator: 1));
      expect(options.reads, greaterThan(0));
      expect(
          valid.timeline.events
              .whereType<BattleCaptureAttemptTimelineEvent>()
              .single
              .attemptId,
          'capture-attempt-1');
    });

    test(
        'policy and context survive decision mapping without re-reading item metadata',
        () {
      final context = BattleCaptureContext(targetTypes: {'synthetic-type'});
      final choice = PlayerBattleChoiceCapture(
          itemId: 'synthetic-orb',
          rateNumerator: 5,
          rateDenominator: 2,
          contextualPolicy: policy,
          captureContext: context);
      final decision = BattleDecision.capture(
          itemId: choice.itemId,
          rateNumerator: choice.rateNumerator,
          rateDenominator: choice.rateDenominator,
          contextualPolicy: choice.contextualPolicy,
          captureContext: choice.captureContext);
      final action = const PsdkBattleActionDecisionMapper().map(
          state: PsdkBattleState.fromSetup(
              _psdkSetup(contextual: true, catchRate: 45, genericSeed: 47).psdkSetup),
          user: psdkPlayerSlot,
          decision: decision) as PsdkBattleCaptureAction;
      expect(action.contextualPolicy, same(policy));
      expect(action.captureContext, same(context));
      expect(action.itemId, choice.itemId);
      expect(action.rateNumerator, 5);
      expect(action.rateDenominator, 2);
    });

    final missingFields = <(
      BattleCaptureContextField,
      ProjectCaptureCondition,
      BattleCaptureContext
    )>[
      for (final pair in [
        (
          BattleCaptureContextField.attackerLevel,
          ProjectCaptureNumericField.attackerLevel
        ),
        (
          BattleCaptureContextField.targetLevel,
          ProjectCaptureNumericField.targetLevel
        ),
        (
          BattleCaptureContextField.targetBaseSpeed,
          ProjectCaptureNumericField.targetBaseSpeed
        ),
        (
          BattleCaptureContextField.targetWeightDecikilograms,
          ProjectCaptureNumericField.targetWeightDecikilograms
        ),
      ])
        (
          pair.$1,
          ProjectCaptureNumericCondition(
              left: ProjectCaptureIntegerOperand.field(pair.$2),
              comparison: ProjectCaptureComparison.greaterThan,
              right: ProjectCaptureIntegerOperand.literal(0)),
          BattleCaptureContext()
        ),
      (
        BattleCaptureContextField.attackerSpecies,
        const ProjectCaptureRelationCondition(
            ProjectCaptureRelation.sameSpecies),
        BattleCaptureContext()
      ),
      (
        BattleCaptureContextField.attackerSex,
        const ProjectCaptureRelationCondition(
            ProjectCaptureRelation.differentSex),
        BattleCaptureContext()
      ),
      (
        BattleCaptureContextField.targetSex,
        const ProjectCaptureRelationCondition(
            ProjectCaptureRelation.differentSex),
        BattleCaptureContext(attackerSex: BattleCaptureSex.male)
      ),
      for (final pair in [
        (
          BattleCaptureContextField.targetSpecies,
          ProjectCaptureMatchField.targetSpecies
        ),
        (
          BattleCaptureContextField.targetTypes,
          ProjectCaptureMatchField.targetTypes
        ),
        (
          BattleCaptureContextField.targetEvolutionItemIds,
          ProjectCaptureMatchField.targetEvolutionItemIds
        ),
        (
          BattleCaptureContextField.encounterOrigin,
          ProjectCaptureMatchField.encounterOrigin
        ),
      ])
        (
          pair.$1,
          ProjectCaptureMatchCondition(field: pair.$2, values: {
            pair.$2 == ProjectCaptureMatchField.encounterOrigin
                ? 'fishing'
                : 'synthetic'
          }),
          BattleCaptureContext()
        ),
    ];
    for (final (field, condition, context) in missingFields) {
      test('missing ${field.name} refuses before RNG and AI', () {
        final selected = ProjectContextualCapturePolicy(rateRules: [
          ProjectCaptureRateRule(
              when: condition, adjustment: ProjectCaptureRateAdd(1))
        ]);
        final rng = _CaptureRngSpy();
        final legacy =
            createBattleSession(_legacySetup(contextual: true, catchRate: 45), rng: rng);
        final matcher = throwsA(isA<BattleCaptureMissingContext>()
            .having((error) => error.field, 'field', field));
        expect(
            () => legacy.applyChoice(PlayerBattleChoiceCapture(
                contextualPolicy: selected, captureContext: context)),
            matcher);
        expect(rng.draws, 0);
        expect(legacy.captureAttemptSequence, 0);
        expect(legacy.state.currentTurn, isNull);
        final options = _AiOptionsSpy();
        final engine = BattleEngine(
            setup: _psdkSetup(contextual: true, catchRate: 45, genericSeed: 47),
            opponentAi: PsdkBattleAi(canUseItem: true, itemOptions: options));
        options.reads = 0;
        expect(
            () => engine.submit(BattleDecision.capture(
                itemId: 'synthetic-orb',
                rateNumerator: 1,
                rateDenominator: 1,
                contextualPolicy: selected,
                captureContext: context)),
            matcher);
        expect(options.reads, 0);
        expect(engine.snapshot().turnNumber, 0);
        final result = engine.submit(const BattleDecision.capture(
            itemId: 'synthetic-orb', rateNumerator: 1, rateDenominator: 1));
        expect(options.reads, greaterThan(0));
        expect(
            result.timeline.events
                .whereType<BattleCaptureAttemptTimelineEvent>()
                .single
                .attemptId,
            'capture-attempt-1');
      });
    }

    test(
        'context without policy and invalid contextual multiplier refuse before any work',
        () {
      final context = BattleCaptureContext();
      for (final invalid in [
        PlayerBattleChoiceCapture(captureContext: context),
        PlayerBattleChoiceCapture(
            rateNumerator: 0,
            contextualPolicy: policy,
            captureContext: context),
        PlayerBattleChoiceCapture(
            rateDenominator: 0,
            contextualPolicy: policy,
            captureContext: context),
        PlayerBattleChoiceCapture(
            rateNumerator: 0x80000000,
            contextualPolicy: policy,
            captureContext: context),
      ]) {
        final rng = _CaptureRngSpy();
        final legacy =
            createBattleSession(_legacySetup(contextual: true, catchRate: 45), rng: rng);
        expect(() => legacy.applyChoice(invalid),
            throwsA(anyOf(isA<StateError>(), isA<ArgumentError>())));
        expect(rng.draws, 0);
        expect(legacy.captureAttemptSequence, 0);
        final options = _AiOptionsSpy();
        final engine = BattleEngine(
            setup: _psdkSetup(contextual: true, catchRate: 45, genericSeed: 47),
            opponentAi: PsdkBattleAi(canUseItem: true, itemOptions: options));
        options.reads = 0;
        expect(
            () => engine.submit(BattleDecision.capture(
                itemId: invalid.itemId,
                rateNumerator: invalid.rateNumerator,
                rateDenominator: invalid.rateDenominator,
                contextualPolicy: invalid.contextualPolicy,
                captureContext: invalid.captureContext)),
            throwsA(anyOf(isA<StateError>(), isA<ArgumentError>())));
        expect(options.reads, 0);
        expect(engine.snapshot().turnNumber, 0);
      }
    });

    test(
        'irrelevant missing characteristics remain optional through engine preflight',
        () {
      final unreachable = ProjectCaptureMatchCondition(
          field: ProjectCaptureMatchField.targetTypes,
          values: {'synthetic-type'});
      final alwaysFalse = ProjectCaptureNumericCondition(
          left: ProjectCaptureIntegerOperand.literal(0),
          comparison: ProjectCaptureComparison.greaterThan,
          right: ProjectCaptureIntegerOperand.literal(1));
      for (final conditions in [
        [const ProjectCaptureAlwaysCondition(), unreachable],
        [
          ProjectCaptureGroupCondition(
              group: ProjectCaptureGroup.all,
              conditions: [alwaysFalse, unreachable]),
          const ProjectCaptureAlwaysCondition()
        ],
        [
          ProjectCaptureGroupCondition(
              group: ProjectCaptureGroup.any,
              conditions: [const ProjectCaptureAlwaysCondition(), unreachable])
        ],
      ]) {
        final lazy = ProjectContextualCapturePolicy(rateRules: [
          for (final condition in conditions)
            ProjectCaptureRateRule(
                when: condition, adjustment: ProjectCaptureRateAdd(255))
        ]);
        final context = BattleCaptureContext();
        final legacy = createBattleSession(
                _legacySetup(contextual: true,
                    catchRate: 1,
                    enemyHp: 1,
                    enemyStatus: const BattleMajorStatusState.slp()),
                rng: const BattleScriptedRng([1]))
            .applyChoice(PlayerBattleChoiceCapture(
                contextualPolicy: lazy, captureContext: context));
        expect(legacy.state.outcome!.isCaptured, isTrue);
        final clean = BattleEngine(
                setup: _psdkSetup(contextual: true,
                    catchRate: 1,
                    enemyHp: 1,
                    enemyStatus: PsdkBattleMajorStatus.sleep,
                    genericSeed: 47))
            .submit(BattleDecision.capture(
                itemId: 'synthetic-orb',
                rateNumerator: 1,
                rateDenominator: 1,
                contextualPolicy: lazy,
                captureContext: context));
        expect(clean.outcome!.kind, BattleEngineOutcomeKind.captured);
      }
    });

    test('legacy clean timeline JSON has no contextual field without policy',
        () {
      final result =
          BattleEngine(setup: _psdkSetup(contextual: true, catchRate: 1, genericSeed: 47)).submit(
              const BattleDecision.capture(
                  itemId: canonicalPokeBallItemId,
                  rateNumerator: 1,
                  rateDenominator: 1));
      final event = result.timeline.events
          .whereType<BattleCaptureAttemptTimelineEvent>()
          .single;
      expect(event.contextualReceipt, isNull);
      expect(event.toJson(), {
        'kind': 'capture_attempt',
        'turn': 1,
        'attemptId': 'capture-attempt-1',
        'target': {'bank': 1, 'position': 0},
        'ballId': canonicalPokeBallItemId,
        'shakes': 2,
        'caught': false
      });
      expect(event.toPsdkEvent().toJson().containsKey('contextualReceipt'),
          isFalse);
    });
  });

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

    test('a failed attempt transmits the formula shakes, not a recomputation',
        () {
      // Transmission ENC-005 : la formule pure, rejouée avec le même seed et
      // les mêmes entrées que la session, dicte le nombre de secousses que
      // l'événement du tour doit porter. Un pipeline qui recalculerait
      // `caught ? 4 : 0` rendrait 0 ici et casserait.
      final expected = const BattleCaptureFormula().attempt(
        targetCurrentHp: 100,
        targetMaxHp: 100,
        catchRate: 1,
        ballId: canonicalPokeBallItemId,
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.none,
        rng: const BattleSeededRng(state: 47),
      );
      expect(expected.caught, isFalse);
      expect(expected.shakes, 2,
          reason: 'the chosen seed must discriminate 0, 3 and 4');

      final after = createBattleSession(
        _legacySetup(catchRate: 1),
        rng: const BattleSeededRng(state: 47),
      ).applyChoice(const PlayerBattleChoiceCapture());

      final event = after.state.currentTurn!.captureAttemptEvents.single;
      expect(event.caught, isFalse);
      expect(event.shakes, expected.shakes);
      expect(
        (after.state.currentTurn!.playerAction as BattleActionCapture).shakes,
        expected.shakes,
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

    test('the native timeline transmits the formula shakes on failure', () {
      final expected = const BattleCaptureFormula().attempt(
        targetCurrentHp: 100,
        targetMaxHp: 100,
        catchRate: 1,
        ballId: canonicalPokeBallItemId,
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.none,
        rng: const BattleSeededRng(state: 47),
      );
      expect(expected.caught, isFalse);
      expect(expected.shakes, 2);

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
      expect(attempt.caught, isFalse);
      expect(attempt.shakes, expected.shakes);
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
  bool contextual = false,
  required int? catchRate,
  int enemyHp = 100,
  BattleMajorStatusState? enemyStatus,
  bool isTrainerBattle = false,
}) {
  return BattleSetup(
    ruleset: contextual ? PokemonRulesetProfile.contextualV1 : PokemonRulesetProfile.pokeMapBetaV1,
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
  bool contextual = false,
  required int catchRate,
  required int genericSeed,
  int enemyHp = 100,
  PsdkBattleMajorStatus? enemyStatus,
  bool isTrainerBattle = false,
  bool canCapture = true,
}) {
  return BattleEngineSetup.singles(
    ruleset: contextual ? PokemonRulesetProfile.contextualV1 : PokemonRulesetProfile.pokeMapBetaV1,
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

class _CaptureRngSpy extends BattleRng {
  int draws = 0;

  @override
  BattleRngRoll nextPercentRoll() {
    draws++;
    return BattleRngRoll(value: 1, next: this);
  }

  @override
  BattleRngChanceResult nextChance(
      {required int numerator, required int denominator}) {
    draws++;
    return BattleRngChanceResult(didOccur: true, drawnValue: 1, next: this);
  }
}

class _AiOptionsSpy extends ListBase<PsdkBattleAiItemOption> {
  int reads = 0;

  @override
  int get length {
    reads++;
    return 0;
  }

  @override
  set length(int value) => throw UnsupportedError('immutable');

  @override
  PsdkBattleAiItemOption operator [](int index) =>
      throw RangeError.index(index, this);

  @override
  void operator []=(int index, PsdkBattleAiItemOption value) =>
      throw UnsupportedError('immutable');
}
