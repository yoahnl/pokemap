import 'package:map_core/map_core.dart';

import 'script_condition_evaluator.dart';

/// Immutable shop profile projected from one [ShopDefinition] and [GameState].
final class ResolvedShopState {
  ResolvedShopState({
    required this.shopId,
    required this.stateId,
    required this.authoringLabel,
    required this.storefrontLabel,
    required this.priority,
    required this.isDefault,
    required this.isOpen,
    required this.message,
    required List<ShopEntryDefinition> entries,
    required List<String> matchedStateIds,
  })  : entries = List<ShopEntryDefinition>.unmodifiable(entries),
        matchedStateIds = List<String>.unmodifiable(matchedStateIds);

  final String shopId;
  final String stateId;
  final String authoringLabel;
  final String storefrontLabel;
  final int priority;
  final bool isDefault;
  final bool isOpen;
  final String message;
  final List<ShopEntryDefinition> entries;
  final List<String> matchedStateIds;
}

/// Resolves the complete shop profile active for one game-state snapshot.
///
/// Conditional states replace the default profile instead of patching it.
/// Higher priorities win, while declaration order makes runtime ties
/// deterministic until authoring validation reports them.
final class ShopStateResolver {
  const ShopStateResolver({
    this.conditions = const ScriptConditionEvaluator(),
  });

  static const String defaultStateId = 'default';

  final ScriptConditionEvaluator conditions;

  ResolvedShopState resolve({
    required ShopDefinition shop,
    required GameState gameState,
    ScriptEvaluationContext? conditionContext,
  }) {
    final normalizedShop = shop.normalized();
    final matches = <_MatchedShopState>[];
    for (var index = 0; index < normalizedShop.states.length; index += 1) {
      final state = normalizedShop.states[index];
      if (conditions.evaluate(
        state.activation,
        gameState,
        context: conditionContext,
      )) {
        matches.add(_MatchedShopState(index: index, state: state));
      }
    }
    matches.sort((left, right) {
      final byPriority = right.state.priority.compareTo(left.state.priority);
      return byPriority != 0 ? byPriority : left.index.compareTo(right.index);
    });

    final matchedStateIds =
        matches.map((match) => match.state.id).toList(growable: false);
    if (matches.isEmpty) {
      return ResolvedShopState(
        shopId: normalizedShop.id,
        stateId: defaultStateId,
        authoringLabel: 'État par défaut',
        storefrontLabel: normalizedShop.label,
        priority: 0,
        isDefault: true,
        isOpen: true,
        message: '',
        entries: normalizedShop.entries,
        matchedStateIds: matchedStateIds,
      );
    }

    final selected = matches.first.state;
    return ResolvedShopState(
      shopId: normalizedShop.id,
      stateId: selected.id,
      authoringLabel: selected.label,
      storefrontLabel: selected.storefrontLabel ?? normalizedShop.label,
      priority: selected.priority,
      isDefault: false,
      isOpen: selected.isOpen,
      message:
          selected.isOpen ? selected.welcomeMessage : selected.closedMessage,
      entries: selected.entries,
      matchedStateIds: matchedStateIds,
    );
  }
}

final class _MatchedShopState {
  const _MatchedShopState({
    required this.index,
    required this.state,
  });

  final int index;
  final ShopStateDefinition state;
}
