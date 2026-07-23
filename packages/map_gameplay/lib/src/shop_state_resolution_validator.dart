import 'package:map_core/map_core.dart';

import 'script_condition_evaluator.dart';
import 'shop_state_resolver.dart';

final class ShopStateResolutionScenario {
  const ShopStateResolutionScenario({
    required this.id,
    required this.label,
    required this.gameState,
    this.conditionContext,
  });

  final String id;
  final String label;
  final GameState gameState;
  final ScriptEvaluationContext? conditionContext;
}

/// Runtime-aware diagnostics for authored shop states.
///
/// Matching is always delegated to [ShopStateResolver]. This validator merely
/// interprets the resolver explanation to detect an active winning-priority
/// tie in the supplied authoring scenarios.
final class ShopStateResolutionValidator {
  const ShopStateResolutionValidator({
    this.resolver = const ShopStateResolver(),
  });

  final ShopStateResolver resolver;

  List<ShopStateDiagnostic> validate({
    required ShopDefinition shop,
    required Iterable<ShopStateResolutionScenario> scenarios,
  }) {
    final normalizedShop = shop.normalized();
    final statesById = <String, ShopStateDefinition>{
      for (final state in normalizedShop.states) state.id: state,
    };
    final diagnostics = <ShopStateDiagnostic>[];
    for (final scenario in scenarios) {
      final resolved = resolver.resolve(
        shop: normalizedShop,
        gameState: scenario.gameState,
        conditionContext: scenario.conditionContext,
      );
      if (resolved.isDefault) continue;
      final winningMatches = resolved.matchedStateIds
          .map((stateId) => statesById[stateId])
          .whereType<ShopStateDefinition>()
          .where((state) => state.priority == resolved.priority)
          .toList(growable: false);
      if (winningMatches.length < 2) continue;
      diagnostics.add(
        ShopStateDiagnostic(
          code: 'SHOP_STATE_EQUAL_PRIORITY_ACTIVE_MATCH',
          severity: ShopStateDiagnosticSeverity.error,
          message: 'Dans « ${scenario.label} », '
              '${winningMatches.map((state) => '« ${state.label} »').join(' et ')} '
              'sont actifs avec la priorité ${resolved.priority}.',
          shopId: normalizedShop.id,
          stateId: resolved.stateId,
          path: 'shops.${normalizedShop.id}.states',
          contextId: scenario.id,
        ),
      );
    }
    return List<ShopStateDiagnostic>.unmodifiable(diagnostics);
  }
}
