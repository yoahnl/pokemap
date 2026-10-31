import 'package:map_core/map_core.dart';

import 'battle_rng.dart';
import 'battle_type_chart.dart';
import 'battle_typing.dart';
import 'capture_formula.dart';
import 'battle_capture_receipt.dart';
import 'contextual_capture_formula.dart';
import 'domain/rng/battle_rng_streams.dart';
import 'domain/rng/battle_seeded_rng.dart';

final class PokemonRulesetFeatureDisabledError extends StateError {
  PokemonRulesetFeatureDisabledError({
    required this.reference,
    required this.feature,
  }) : super(
          'Pokemon feature ${feature.name} is disabled by ruleset '
          '${reference.profileId}@${reference.schemaVersion}.',
        );

  final PokemonRulesetReference reference;
  final PokemonDisabledFeature feature;
}

final class PokemonCriticalHitRule {
  const PokemonCriticalHitRule({
    required this.numerator,
    required this.denominator,
    required this.damageMultiplier,
  });

  final int numerator;
  final int denominator;
  final double damageMultiplier;
}

final class PokemonLegacySpeedTieResult {
  const PokemonLegacySpeedTieResult({
    required this.firstActsFirst,
    required this.nextRng,
  });

  final bool firstActsFirst;
  final BattleRng nextRng;
}

final class PokemonPsdkSpeedTieResult {
  const PokemonPsdkSpeedTieResult({
    required this.firstActsFirst,
    required this.nextRng,
  });

  final bool firstActsFirst;
  final BattleRngStreams nextRng;
}

final class PokemonBattleRules {
  PokemonBattleRules._(this.profile, this.mechanics);

  factory PokemonBattleRules.fromProfile(PokemonRulesetProfile profile) {
    return PokemonBattleRules._(profile, profile.mechanics);
  }

  final PokemonRulesetProfile profile;
  final PokemonRulesetMechanics mechanics;

  PokemonRulesetReference get reference => mechanics.reference;

  double resolveStabMultiplier({
    required String moveType,
    required BattleTypingSnapshot? attackerTyping,
  }) {
    _requireTypeChart();
    return BattleTypeChart.resolveStabMultiplier(
      moveType: moveType,
      attackerTyping: attackerTyping,
    );
  }

  double resolveEffectivenessMultiplier({
    required String moveType,
    required BattleTypingSnapshot? defenderTyping,
  }) {
    _requireTypeChart();
    return BattleTypeChart.resolveEffectivenessMultiplier(
      moveType: moveType,
      defenderTyping: defenderTyping,
    );
  }

  PokemonCriticalHitRule criticalHitRule(int criticalRate) {
    if (mechanics.criticalHit != PokemonCriticalHitPolicy.mainlineGen9) {
      throw StateError(
        'Unsupported Pokemon critical hit policy ${mechanics.criticalHit.name}.',
      );
    }
    return switch (criticalRate) {
      <= 0 => const PokemonCriticalHitRule(
          numerator: 0,
          denominator: 1,
          damageMultiplier: 1.5,
        ),
      1 => const PokemonCriticalHitRule(
          numerator: 1,
          denominator: 24,
          damageMultiplier: 1.5,
        ),
      2 => const PokemonCriticalHitRule(
          numerator: 1,
          denominator: 8,
          damageMultiplier: 1.5,
        ),
      3 => const PokemonCriticalHitRule(
          numerator: 1,
          denominator: 2,
          damageMultiplier: 1.5,
        ),
      _ => const PokemonCriticalHitRule(
          numerator: 1,
          denominator: 1,
          damageMultiplier: 1.5,
        ),
    };
  }

  BattleCaptureAttemptResult attemptCapture({
    required int targetCurrentHp,
    required int targetMaxHp,
    required int catchRate,
    required String ballId,
    required int ballRateNumerator,
    required int ballRateDenominator,
    required BattleCaptureStatus status,
    required BattleRng rng,
  }) {
    if (mechanics.capture != PokemonCapturePolicy.pokeMapMvpV1 &&
        mechanics.capture != PokemonCapturePolicy.pokeMapContextualItemsMvpFallbackV1) {
      throw StateError(
        'Unsupported Pokemon capture policy ${mechanics.capture.name}.',
      );
    }
    return const BattleCaptureFormula().attempt(
      targetCurrentHp: targetCurrentHp,
      targetMaxHp: targetMaxHp,
      catchRate: catchRate,
      ballId: ballId,
      ballRateNumerator: ballRateNumerator,
      ballRateDenominator: ballRateDenominator,
      status: status,
      rng: rng,
    );
  }

  void validateCaptureSelection({
    required int targetCurrentHp,
    required int targetMaxHp,
    required int catchRate,
    required String ballId,
    required int ballRateNumerator,
    required int ballRateDenominator,
    ProjectContextualCapturePolicy? contextualPolicy,
    BattleCaptureContext? captureContext,
  }) {
    if (mechanics.capture != PokemonCapturePolicy.pokeMapMvpV1 &&
        mechanics.capture != PokemonCapturePolicy.pokeMapContextualItemsMvpFallbackV1) {
      throw StateError(
          'Unsupported Pokemon capture policy ${mechanics.capture.name}.');
    }
    if (ballId.trim().isEmpty ||
        ballRateNumerator < 1 ||
        ballRateDenominator < 1 ||
        targetMaxHp < 1 ||
        targetCurrentHp < 1 ||
        targetCurrentHp > targetMaxHp ||
        catchRate < 1 ||
        catchRate > 255) {
      throw ArgumentError('Invalid capture selection.');
    }
    if (contextualPolicy == null) {
      if (captureContext != null) {
        throw StateError(
            'Capture context requires an explicit contextual policy.');
      }
      return;
    }
    if (mechanics.capture != PokemonCapturePolicy.pokeMapContextualItemsMvpFallbackV1) {
      throw StateError('Contextual capture requires the explicit contextual ruleset.');
    }
    if (captureContext == null) {
      throw StateError(
          'Contextual capture requires an explicit capture context.');
    }
    for (final value in [targetMaxHp, ballRateNumerator, ballRateDenominator]) {
      RangeError.checkValueInInterval(value, 1, 0x7fffffff);
    }
    const BattleContextualCaptureFormula().evaluateRate(
      policy: contextualPolicy,
      catchRate: captureContext.targetBaseCatchRate ?? catchRate,
      context: captureContext,
    );
  }

  BattleCaptureResolution resolveCapture({
    required String attemptId,
    required int targetCurrentHp,
    required int targetMaxHp,
    required int catchRate,
    required String ballId,
    required int ballRateNumerator,
    required int ballRateDenominator,
    required BattleCaptureStatus status,
    required BattleRng rng,
    ProjectContextualCapturePolicy? contextualPolicy,
    BattleCaptureContext? captureContext,
  }) {
    validateCaptureSelection(
      targetCurrentHp: targetCurrentHp,
      targetMaxHp: targetMaxHp,
      catchRate: catchRate,
      ballId: ballId,
      ballRateNumerator: ballRateNumerator,
      ballRateDenominator: ballRateDenominator,
      contextualPolicy: contextualPolicy,
      captureContext: captureContext,
    );
    if (contextualPolicy == null) {
      return BattleCaptureResolution(
          attempt: attemptCapture(
        targetCurrentHp: targetCurrentHp,
        targetMaxHp: targetMaxHp,
        catchRate: catchRate,
        ballId: ballId,
        ballRateNumerator: ballRateNumerator,
        ballRateDenominator: ballRateDenominator,
        status: status,
        rng: rng,
      ));
    }
    if (attemptId.trim().isEmpty) {
      throw ArgumentError.value(attemptId, 'attemptId', 'must not be empty');
    }
    final resolved = const BattleContextualCaptureFormula().attempt(
      policy: contextualPolicy,
      context: captureContext!,
      catchRate: captureContext.targetBaseCatchRate ?? catchRate,
      targetCurrentHp: targetCurrentHp,
      targetMaxHp: targetMaxHp,
      ballRateNumerator: ballRateNumerator,
      ballRateDenominator: ballRateDenominator,
      status: status,
      rng: rng,
    );
    return BattleCaptureResolution(
        attempt: resolved.attempt,
        contextualReceipt: BattleCaptureReceipt(
            attemptId: attemptId,
            ballId: ballId,
            calculation: resolved.receipt));
  }

  PokemonLegacySpeedTieResult resolveLegacySpeedTie(BattleRng rng) {
    _requireSpeedTiePolicy();
    final roll = rng.nextChance(numerator: 1, denominator: 2);
    return PokemonLegacySpeedTieResult(
      firstActsFirst: roll.didOccur,
      nextRng: roll.next,
    );
  }

  PokemonPsdkSpeedTieResult resolvePsdkSpeedTie(BattleRngStreams rng) {
    final result = resolveLegacySpeedTie(
      BattleSeededRng(state: rng.generic.seed),
    );
    final next = result.nextRng;
    if (next is! BattleSeededRng) {
      throw StateError('Speed tie policy returned an incompatible RNG state.');
    }
    return PokemonPsdkSpeedTieResult(
      firstActsFirst: result.firstActsFirst,
      nextRng: rng.copyWith(generic: BattleRngStream(seed: next.state)),
    );
  }

  void requireFeatureEnabled(PokemonDisabledFeature feature) {
    if (mechanics.disabledFeatures.contains(feature)) {
      throw PokemonRulesetFeatureDisabledError(
        reference: reference,
        feature: feature,
      );
    }
  }

  void _requireTypeChart() {
    if (mechanics.typeChart != PokemonTypeChartPolicy.mainlineModernV1) {
      throw StateError(
        'Unsupported Pokemon type chart policy ${mechanics.typeChart.name}.',
      );
    }
  }

  void _requireSpeedTiePolicy() {
    if (mechanics.speedTie != PokemonSpeedTiePolicy.mainlineGen9SeededRandom) {
      throw StateError(
        'Unsupported Pokemon speed tie policy ${mechanics.speedTie.name}.',
      );
    }
  }
}
