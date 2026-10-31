import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final oracle = jsonDecode(
      File('test/fixtures/contextual_capture_native_oracle.json')
          .readAsStringSync()) as Map;
  final policies = (oracle['policies'] as Map).map((id, json) => MapEntry(
      id.toString(),
      ProjectContextualCapturePolicy.fromJson(
          Map<String, dynamic>.from(json as Map))));
  const formula = BattleContextualCaptureFormula();

  test(
      'matches all 378 compiled native modifier vectors without engine item IDs',
      () {
    expect((oracle['vectors'] as List).length, 378);
    for (final raw in oracle['vectors'] as List) {
      final row = raw as Map;
      final input = (row['input'] as List).cast<int>();
      final receipt = formula.evaluateRate(
        policy: policies[input[0].toString()]!,
        catchRate: input[1],
        context: BattleCaptureContext(
          attackerLevel: input[2],
          targetLevel: input[3],
          targetBaseSpeed: input[4],
          targetWeightDecikilograms: input[5],
          attackerSpecies: input[6].toString(),
          targetSpecies: input[7].toString(),
          attackerSex: BattleCaptureSex.values[input[8]],
          targetSex: BattleCaptureSex.values[input[9]],
          encounterOrigin: input[10] == 1
              ? ProjectCaptureEncounterOrigin.fishing
              : ProjectCaptureEncounterOrigin.walking,
        ),
      );
      expect(receipt.beforeClamp, row['expectedBeforeClamp'], reason: '$input');
      expect(receipt.afterClamp, row['expectedAfterClamp'], reason: '$input');
    }
  });

  test('native floor stages differ from the protected MVP rational', () {
    final result = formula.attempt(
      policy: policies['492']!,
      context: BattleCaptureContext(targetBaseSpeed: 100),
      catchRate: 190,
      targetCurrentHp: 77,
      targetMaxHp: 101,
      ballRateNumerator: 15,
      ballRateDenominator: 10,
      status: BattleCaptureStatus.paralysis,
      rng: const BattleScriptedRng([255]),
    );
    expect(result.receipt.rate.beforeClamp, 760);
    expect(result.receipt.rate.afterClamp, 255);
    expect(result.receipt.afterBallMultiplier, 382);
    expect(result.receipt.afterHp, 187);
    expect(result.receipt.afterStatus, 280);
    expect(result.attempt.chanceNumerator, 255);
    expect(result.attempt.chanceDenominator, 255);
    expect((result.attempt.nextRng as BattleScriptedRng).index, 1);
  });

  test('missing characteristics refuse before any RNG draw', () {
    final rng = _CountingRng();
    expect(
        () => formula.attempt(
              policy: policies['492']!,
              context: BattleCaptureContext(),
              catchRate: 45,
              targetCurrentHp: 1,
              targetMaxHp: 10,
              ballRateNumerator: 1,
              ballRateDenominator: 1,
              status: BattleCaptureStatus.none,
              rng: rng,
            ),
        throwsA(isA<BattleCaptureMissingContext>().having(
            (error) => error.field,
            'field',
            BattleCaptureContextField.targetBaseSpeed)));
    expect(rng.draws, 0);
  });
  test('zero stays zero, consumes one draw and retains all failure shakes', () {
    for (final entry in {1: 3, 65: 2, 129: 1, 193: 0}.entries) {
      final result = formula.attempt(
        policy: policies['495']!,
        context: BattleCaptureContext(targetWeightDecikilograms: 100),
        catchRate: 20,
        targetCurrentHp: 1,
        targetMaxHp: 100,
        ballRateNumerator: 1,
        ballRateDenominator: 1,
        status: BattleCaptureStatus.sleep,
        rng: BattleScriptedRng([entry.key]),
      );
      expect(result.receipt.rate.beforeClamp, 0);
      expect(result.attempt.chanceNumerator, 0);
      expect(result.attempt.caught, isFalse);
      expect(result.attempt.shakes, entry.value);
      expect((result.attempt.nextRng as BattleScriptedRng).index, 1);
    }
    final negative = formula.evaluateRate(
        policy: policies['495']!,
        catchRate: 19,
        context: BattleCaptureContext(targetWeightDecikilograms: 100));
    expect(negative.beforeClamp, -1);
    expect(negative.afterClamp, 1);
  });

  test(
      'HP truncation remains before status and separate from the legacy formula',
      () {
    final contextual = formula.attempt(
      policy: ProjectContextualCapturePolicy(),
      context: BattleCaptureContext(),
      catchRate: 1,
      targetCurrentHp: 100,
      targetMaxHp: 100,
      ballRateNumerator: 1,
      ballRateDenominator: 1,
      status: BattleCaptureStatus.sleep,
      rng: const BattleScriptedRng([1]),
    );
    expect(contextual.receipt.afterHp, 0);
    expect(contextual.receipt.afterStatus, 0);
    expect(contextual.attempt.caught, isFalse);
    final legacy = const BattleCaptureFormula().attempt(
      targetCurrentHp: 100,
      targetMaxHp: 100,
      catchRate: 1,
      ballId: 'synthetic',
      ballRateNumerator: 1,
      ballRateDenominator: 1,
      status: BattleCaptureStatus.sleep,
      rng: const BattleScriptedRng([1]),
    );
    expect(legacy.chanceNumerator, 200);
    expect(legacy.chanceDenominator, 76500);
    expect(legacy.caught, isTrue);
  });

  test(
      'post-success friendship needs no unrelated context and is an immutable receipt',
      () {
    BattleContextualCaptureAttempt attempt(int draw) => formula.attempt(
          policy: policies['497']!,
          context: BattleCaptureContext(),
          catchRate: 255,
          targetCurrentHp: 100,
          targetMaxHp: 100,
          ballRateNumerator: 1,
          ballRateDenominator: 1,
          status: BattleCaptureStatus.none,
          rng: BattleScriptedRng([draw]),
        );
    final success = attempt(1);
    expect(
        (success.receipt.successEffects.single as ProjectCaptureSetFriendship)
            .value,
        200);
    expect(
        () => success.receipt.successEffects.clear(), throwsUnsupportedError);
    final failure = attempt(255);
    expect(failure.attempt.caught, isFalse);
    expect(failure.receipt.successEffects, isEmpty);
    expect(BattleContextualCaptureFormula.randomPolicyId,
        'pokemap-capture-single-draw-v1');
    expect(BattleContextualCaptureFormula.shakePolicyId,
        BattleCaptureFormula.shakeRuleId);
  });

  test('first-match and boolean short circuit demand only evaluated context',
      () {
    final laterMissing = ProjectCaptureRateRule(
      when: ProjectCaptureNumericCondition(
          left: ProjectCaptureIntegerOperand.field(
              ProjectCaptureNumericField.targetBaseSpeed),
          comparison: ProjectCaptureComparison.greaterThan,
          right: ProjectCaptureIntegerOperand.literal(0)),
      adjustment: ProjectCaptureRateAdd(99),
    );
    final first = ProjectCaptureRateRule(
        when: const ProjectCaptureAlwaysCondition(),
        adjustment: ProjectCaptureRateAdd(1));
    final result = formula.evaluateRate(
        policy:
            ProjectContextualCapturePolicy(rateRules: [first, laterMissing]),
        catchRate: 10,
        context: BattleCaptureContext());
    expect(result.beforeClamp, 11);
    expect(result.matchedRuleIndex, 0);
    final any = ProjectContextualCapturePolicy(rateRules: [
      ProjectCaptureRateRule(
          when: ProjectCaptureGroupCondition(
              group: ProjectCaptureGroup.any,
              conditions: [
                const ProjectCaptureAlwaysCondition(),
                laterMissing.when
              ]),
          adjustment: ProjectCaptureRateAdd(2))
    ]);
    expect(
        formula
            .evaluateRate(
                policy: any, catchRate: 10, context: BattleCaptureContext())
            .beforeClamp,
        12);
    final differentSpecies = formula.evaluateRate(
        policy: policies['496']!,
        catchRate: 10,
        context: BattleCaptureContext(
            attackerSpecies: 'one', targetSpecies: 'another'));
    expect(differentSpecies.beforeClamp, 10);
    expect(
        () => formula.evaluateRate(
            policy: policies['496']!,
            catchRate: 10,
            context: BattleCaptureContext(
                attackerSpecies: 'one', targetSpecies: 'one')),
        throwsA(isA<BattleCaptureMissingContext>().having(
            (e) => e.field, 'field', BattleCaptureContextField.attackerSex)));
  });

  test(
      'synthetic type and evolution memberships distinguish absent from unknown',
      () {
    for (final field in [
      ProjectCaptureMatchField.targetTypes,
      ProjectCaptureMatchField.targetEvolutionItemIds
    ]) {
      final policy = ProjectContextualCapturePolicy(rateRules: [
        ProjectCaptureRateRule(
            when: ProjectCaptureMatchCondition(
                field: field, values: {'synthetic-id'}),
            adjustment:
                ProjectCaptureRateMultiply(numerator: 3, denominator: 2))
      ]);
      BattleCaptureContext context(Set<String>? values) =>
          field == ProjectCaptureMatchField.targetTypes
              ? BattleCaptureContext(targetTypes: values)
              : BattleCaptureContext(targetEvolutionItemIds: values);
      expect(
          formula
              .evaluateRate(
                  policy: policy,
                  catchRate: 3,
                  context: context({'other', 'synthetic-id'}))
              .beforeClamp,
          4);
      expect(
          formula
              .evaluateRate(policy: policy, catchRate: 3, context: context({}))
              .beforeClamp,
          3);
      expect(
          () => formula.evaluateRate(
              policy: policy, catchRate: 3, context: context(null)),
          throwsA(isA<BattleCaptureMissingContext>()));
    }
  });

  test(
      'large valid HP and multipliers keep exact integer stages without overflow',
      () {
    final result = formula.attempt(
      policy: ProjectContextualCapturePolicy(),
      context: BattleCaptureContext(),
      catchRate: 255,
      targetCurrentHp: 1,
      targetMaxHp: 2147483647,
      ballRateNumerator: 2147483647,
      ballRateDenominator: 1,
      status: BattleCaptureStatus.paralysis,
      rng: const BattleScriptedRng([255]),
    );
    expect(result.receipt.afterBallMultiplier, 547608329985);
    expect(result.receipt.afterHp, 547608329815);
    expect(result.receipt.afterStatus, 821412494722);
    expect(result.attempt.caught, isTrue);
    expect((result.attempt.nextRng as BattleScriptedRng).index, 1);
  });

  test(
      'invalid common inputs reject before RNG and preserve context collections',
      () {
    final rng = _CountingRng();
    for (final invalid in [
      [0, 100, 45, 1, 1],
      [101, 100, 45, 1, 1],
      [1, 0, 45, 1, 1],
      [1, 100, -1, 1, 1],
      [1, 100, 256, 1, 1],
      [1, 100, 45, 0, 1],
      [1, 100, 45, 1, 0],
      [1, 2147483648, 45, 1, 1],
    ]) {
      expect(
          () => formula.attempt(
              policy: ProjectContextualCapturePolicy(),
              context: BattleCaptureContext(),
              targetCurrentHp: invalid[0],
              targetMaxHp: invalid[1],
              catchRate: invalid[2],
              ballRateNumerator: invalid[3],
              ballRateDenominator: invalid[4],
              status: BattleCaptureStatus.none,
              rng: rng),
          throwsRangeError);
    }
    expect(rng.draws, 0);
    final types = <String>{'synthetic'};
    final context = BattleCaptureContext(targetTypes: types);
    types.clear();
    expect(context.targetTypes, {'synthetic'});
    expect(() => context.targetTypes!.clear(), throwsUnsupportedError);
    expect(() => BattleCaptureContext(targetWeightDecikilograms: -1),
        throwsRangeError);
    expect(() => BattleCaptureContext(attackerLevel: 0), throwsRangeError);
    expect(() => BattleCaptureContext(targetSpecies: ''), throwsArgumentError);
  });
}

class _CountingRng extends BattleRng {
  int draws = 0;

  @override
  BattleRngRoll nextPercentRoll() => throw UnimplementedError();

  @override
  BattleRngChanceResult nextChance(
      {required int numerator, required int denominator}) {
    draws++;
    return BattleRngChanceResult(
        didOccur: numerator >= 1, drawnValue: 1, next: this);
  }
}
