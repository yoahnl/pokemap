import 'package:map_core/map_core.dart';

import 'capture_formula.dart';
import 'contextual_capture_formula.dart';

final class BattleCaptureResolution {
  const BattleCaptureResolution(
      {required this.attempt, this.contextualReceipt});

  final BattleCaptureAttemptResult attempt;
  final BattleCaptureReceipt? contextualReceipt;
}

final class BattleCaptureReceipt {
  const BattleCaptureReceipt({
    required this.attemptId,
    required this.ballId,
    required this.calculation,
  });

  final String attemptId;
  final String ballId;
  final BattleContextualCaptureReceipt calculation;

  List<ProjectCaptureSuccessEffect> get successEffects =>
      calculation.successEffects;

  Map<String, Object?> toJson() => {
        'attemptId': attemptId,
        'ballId': ballId,
        'algorithmId': ProjectContextualCapturePolicy.algorithmId,
        'randomPolicyId': ProjectContextualCapturePolicy.randomPolicyId,
        'shakePolicyId': ProjectContextualCapturePolicy.shakePolicyId,
        'rate': {
          'beforeClamp': calculation.rate.beforeClamp,
          'afterClamp': calculation.rate.afterClamp,
          'matchedRuleIndex': calculation.rate.matchedRuleIndex,
        },
        'afterBallMultiplier': calculation.afterBallMultiplier,
        'afterHp': calculation.afterHp,
        'afterStatus': calculation.afterStatus,
        'successEffects':
            successEffects.map((effect) => effect.toJson()).toList(),
      };
}
