import 'package:map_core/map_core.dart';

import 'battle_rng.dart';
import 'capture_formula.dart';

enum BattleCaptureSex { male, female, genderless }

enum BattleCaptureContextField {
  attackerLevel,
  targetLevel,
  targetBaseSpeed,
  targetWeightDecikilograms,
  attackerSpecies,
  targetSpecies,
  attackerSex,
  targetSex,
  targetTypes,
  targetEvolutionItemIds,
  encounterOrigin,
}

final class BattleCaptureMissingContext extends StateError {
  BattleCaptureMissingContext(this.field)
      : super('Contextual capture requires ${field.name}.');

  final BattleCaptureContextField field;
}

final class BattleCaptureContext {
  BattleCaptureContext({
    this.attackerLevel,
    this.targetLevel,
    this.targetBaseSpeed,
    this.targetBaseCatchRate,
    this.targetWeightDecikilograms,
    this.attackerSpecies,
    this.targetSpecies,
    this.attackerSex,
    this.targetSex,
    Set<String>? targetTypes,
    Set<String>? targetEvolutionItemIds,
    this.encounterOrigin,
  })  : targetTypes =
            targetTypes == null ? null : Set.unmodifiable(targetTypes),
        targetEvolutionItemIds = targetEvolutionItemIds == null
            ? null
            : Set.unmodifiable(targetEvolutionItemIds) {
    if (targetBaseCatchRate != null) {
      RangeError.checkValueInInterval(targetBaseCatchRate!, 0, 255);
    }
    for (final value in [attackerLevel, targetLevel]) {
      if (value != null) RangeError.checkValueInInterval(value, 1, 0x7fffffff);
    }
    for (final value in [targetBaseSpeed, targetWeightDecikilograms]) {
      if (value != null) RangeError.checkValueInInterval(value, 0, 0x7fffffff);
    }
    for (final value in [
      attackerSpecies,
      targetSpecies,
      ...?targetTypes,
      ...?targetEvolutionItemIds
    ]) {
      if (value != null && (value.isEmpty || value.trim() != value)) {
        throw ArgumentError.value(
            value, 'identity', 'must be a nonempty canonical identity');
      }
    }
  }

  final int? attackerLevel;
  final int? targetLevel;
  final int? targetBaseSpeed;
  final int? targetBaseCatchRate;
  final int? targetWeightDecikilograms;
  final String? attackerSpecies;
  final String? targetSpecies;
  final BattleCaptureSex? attackerSex;
  final BattleCaptureSex? targetSex;
  final Set<String>? targetTypes;
  final Set<String>? targetEvolutionItemIds;
  final ProjectCaptureEncounterOrigin? encounterOrigin;
}

final class BattleCaptureRateReceipt {
  const BattleCaptureRateReceipt(
      {required this.beforeClamp,
      required this.afterClamp,
      required this.matchedRuleIndex});

  final int beforeClamp;
  final int afterClamp;
  final int? matchedRuleIndex;
}

final class BattleContextualCaptureReceipt {
  BattleContextualCaptureReceipt({
    required this.rate,
    required this.afterBallMultiplier,
    required this.afterHp,
    required this.afterStatus,
    required List<ProjectCaptureSuccessEffect> successEffects,
  }) : successEffects = List.unmodifiable(successEffects);

  final BattleCaptureRateReceipt rate;
  final int afterBallMultiplier;
  final int afterHp;
  final int afterStatus;
  final List<ProjectCaptureSuccessEffect> successEffects;
}

final class BattleContextualCaptureAttempt {
  const BattleContextualCaptureAttempt(
      {required this.attempt, required this.receipt});

  final BattleCaptureAttemptResult attempt;
  final BattleContextualCaptureReceipt receipt;
}

final class BattleContextualCaptureFormula {
  const BattleContextualCaptureFormula();

  static const String decisionPolicyId =
      ProjectContextualCapturePolicy.algorithmId;
  static const String randomPolicyId =
      ProjectContextualCapturePolicy.randomPolicyId;
  static const String shakePolicyId =
      ProjectContextualCapturePolicy.shakePolicyId;

  BattleCaptureRateReceipt evaluateRate({
    required ProjectContextualCapturePolicy policy,
    required int catchRate,
    required BattleCaptureContext context,
  }) {
    RangeError.checkValueInInterval(catchRate, 0, 255, 'catchRate');
    var modified = catchRate;
    int? matched;
    for (var index = 0; index < policy.rateRules.length; index++) {
      final rule = policy.rateRules[index];
      if (!_matches(rule.when, context, catchRate)) continue;
      matched = index;
      modified = switch (rule.adjustment) {
        ProjectCaptureRateAdd(:final amount) => catchRate + amount,
        ProjectCaptureRateMultiply(:final numerator, :final denominator) =>
          _fraction(BigInt.from(catchRate) * BigInt.from(numerator),
              BigInt.from(denominator)),
      };
      break;
    }
    return BattleCaptureRateReceipt(
      beforeClamp: modified,
      afterClamp: modified > 255
          ? 255
          : modified < 0
              ? 1
              : modified,
      matchedRuleIndex: matched,
    );
  }

  BattleContextualCaptureAttempt attempt({
    required ProjectContextualCapturePolicy policy,
    required BattleCaptureContext context,
    required int catchRate,
    required int targetCurrentHp,
    required int targetMaxHp,
    required int ballRateNumerator,
    required int ballRateDenominator,
    required BattleCaptureStatus status,
    required BattleRng rng,
  }) {
    RangeError.checkValueInInterval(targetMaxHp, 1, 0x7fffffff, 'targetMaxHp');
    RangeError.checkValueInInterval(
        targetCurrentHp, 1, targetMaxHp, 'targetCurrentHp');
    RangeError.checkValueInInterval(
        ballRateNumerator, 1, 0x7fffffff, 'ballRateNumerator');
    RangeError.checkValueInInterval(
        ballRateDenominator, 1, 0x7fffffff, 'ballRateDenominator');
    final rate =
        evaluateRate(policy: policy, catchRate: catchRate, context: context);
    final afterBall = _fraction(
        BigInt.from(rate.afterClamp) * BigInt.from(ballRateNumerator),
        BigInt.from(ballRateDenominator));
    final maximumHp = BigInt.from(targetMaxHp);
    final hpFactor =
        BigInt.from(3) * maximumHp - BigInt.two * BigInt.from(targetCurrentHp);
    final afterHp = _fraction(
        hpFactor * BigInt.from(afterBall), BigInt.from(3) * maximumHp);
    final (statusNumerator, statusDenominator) = switch (status) {
      BattleCaptureStatus.sleep || BattleCaptureStatus.freeze => (2, 1),
      BattleCaptureStatus.paralysis ||
      BattleCaptureStatus.burn ||
      BattleCaptureStatus.poison =>
        (3, 2),
      BattleCaptureStatus.none => (1, 1),
    };
    final afterStatus = _fraction(
        BigInt.from(afterHp) * BigInt.from(statusNumerator),
        BigInt.from(statusDenominator));
    final numerator = afterStatus.clamp(0, 255);
    final roll = rng.nextChance(numerator: numerator, denominator: 255);
    final shakes = roll.didOccur
        ? 4
        : 3 - (4 * (roll.drawnValue - numerator - 1)) ~/ (255 - numerator);
    return BattleContextualCaptureAttempt(
      attempt: BattleCaptureAttemptResult(
        caught: roll.didOccur,
        shakes: shakes,
        chanceNumerator: numerator,
        chanceDenominator: 255,
        nextRng: roll.next,
      ),
      receipt: BattleContextualCaptureReceipt(
        rate: rate,
        afterBallMultiplier: afterBall,
        afterHp: afterHp,
        afterStatus: afterStatus,
        successEffects: roll.didOccur ? policy.successEffects : const [],
      ),
    );
  }
}

bool _matches(ProjectCaptureCondition condition, BattleCaptureContext context,
    int catchRate) {
  switch (condition) {
    case ProjectCaptureAlwaysCondition():
      return true;
    case ProjectCaptureNumericCondition(
        :final left,
        :final comparison,
        :final right
      ):
      final leftValue = _operand(left, context, catchRate);
      final rightValue = _operand(right, context, catchRate);
      return switch (comparison) {
        ProjectCaptureComparison.lessThan => leftValue < rightValue,
        ProjectCaptureComparison.lessThanOrEqual => leftValue <= rightValue,
        ProjectCaptureComparison.equal => leftValue == rightValue,
        ProjectCaptureComparison.greaterThanOrEqual => leftValue >= rightValue,
        ProjectCaptureComparison.greaterThan => leftValue > rightValue,
      };
    case ProjectCaptureMatchCondition(:final field, :final values):
      final actual = switch (field) {
        ProjectCaptureMatchField.targetSpecies => {
            _required(
                context.targetSpecies, BattleCaptureContextField.targetSpecies)
          },
        ProjectCaptureMatchField.targetTypes =>
          _required(context.targetTypes, BattleCaptureContextField.targetTypes),
        ProjectCaptureMatchField.targetEvolutionItemIds => _required(
            context.targetEvolutionItemIds,
            BattleCaptureContextField.targetEvolutionItemIds),
        ProjectCaptureMatchField.encounterOrigin => {
            _required(context.encounterOrigin,
                    BattleCaptureContextField.encounterOrigin)
                .name
          },
      };
      return actual.any(values.contains);
    case ProjectCaptureRelationCondition(:final relation):
      return switch (relation) {
        ProjectCaptureRelation.sameSpecies => _required(context.attackerSpecies,
                BattleCaptureContextField.attackerSpecies) ==
            _required(
                context.targetSpecies, BattleCaptureContextField.targetSpecies),
        ProjectCaptureRelation.differentSex => _required(
                context.attackerSex, BattleCaptureContextField.attackerSex) !=
            _required(context.targetSex, BattleCaptureContextField.targetSex),
      };
    case ProjectCaptureGroupCondition(:final group, :final conditions):
      return switch (group) {
        ProjectCaptureGroup.all =>
          conditions.every((child) => _matches(child, context, catchRate)),
        ProjectCaptureGroup.any =>
          conditions.any((child) => _matches(child, context, catchRate)),
      };
  }
}

int _operand(ProjectCaptureIntegerOperand operand, BattleCaptureContext context,
    int catchRate) {
  final int value = operand.literal ??
      switch (operand.field!) {
        ProjectCaptureNumericField.catchRate => catchRate,
        ProjectCaptureNumericField.attackerLevel => _required(
            context.attackerLevel, BattleCaptureContextField.attackerLevel),
        ProjectCaptureNumericField.targetLevel =>
          _required(context.targetLevel, BattleCaptureContextField.targetLevel),
        ProjectCaptureNumericField.targetBaseSpeed => _required(
            context.targetBaseSpeed, BattleCaptureContextField.targetBaseSpeed),
        ProjectCaptureNumericField.targetWeightDecikilograms => _required(
            context.targetWeightDecikilograms,
            BattleCaptureContextField.targetWeightDecikilograms),
      };
  return value ~/ operand.divisor;
}

T _required<T>(T? value, BattleCaptureContextField field) {
  if (value == null) throw BattleCaptureMissingContext(field);
  return value;
}

int _fraction(BigInt numerator, BigInt denominator) =>
    (numerator ~/ denominator).toInt();
