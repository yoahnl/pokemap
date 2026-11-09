import 'package:map_core/map_core.dart';

enum ContextualItemUseRefusal {
  staleMap,
  ambiguous,
  unavailableCondition,
  unavailableScene,
}

sealed class ContextualItemUseSelection {
  const ContextualItemUseSelection();
}

final class ContextualItemUseNoMatch extends ContextualItemUseSelection {
  const ContextualItemUseNoMatch();
}

final class ContextualItemUseRefused extends ContextualItemUseSelection {
  const ContextualItemUseRefused(this.reason);

  final ContextualItemUseRefusal reason;
}

final class ContextualItemUseMatched extends ContextualItemUseSelection {
  const ContextualItemUseMatched(this.rule);

  final ContextualItemUseRule rule;
}

Set<String> contextualItemUseIds({
  required NarrativeMapView map,
  required ProjectManifest project,
  required GameState state,
  List<NarrativeMapView> maps = const [],
  PresentationConditionContext? conditionContext,
}) {
  final context = conditionContext ??
      PresentationConditionContext(project: project, map: map, maps: maps);
  return {
    for (final id in map.contextualItemUses.map((rule) => rule.itemId).toSet())
      if (selectContextualItemUse(
          map: map,
          project: project,
          state: state,
          itemId: id,
          maps: maps,
          conditionContext: context) is! ContextualItemUseNoMatch)
        id,
  };
}

ContextualItemUseSelection selectContextualItemUse({
  required NarrativeMapView map,
  required ProjectManifest project,
  required GameState state,
  required String itemId,
  List<NarrativeMapView> maps = const [],
  PresentationConditionContext? conditionContext,
}) {
  if (map.id != state.currentMapId) {
    return const ContextualItemUseRefused(ContextualItemUseRefusal.staleMap);
  }
  final context = conditionContext ??
      PresentationConditionContext(project: project, map: map, maps: maps);
  final candidates = <ContextualItemUseRule>[];
  for (final rule in map.contextualItemUses) {
    if (rule.itemId != itemId ||
        rule.position != null && rule.position != state.playerPosition ||
        rule.facing != null && rule.facing != state.playerFacing) {
      continue;
    }
    final expression = rule.conditionExpression;
    if (expression != null) {
      final evaluation = context.evaluate(expression, state);
      if (evaluation.unavailable) {
        return const ContextualItemUseRefused(
          ContextualItemUseRefusal.unavailableCondition,
        );
      }
      if (!evaluation.passed) continue;
    }
    candidates.add(rule);
  }
  if (candidates.isEmpty) return const ContextualItemUseNoMatch();
  candidates.sort((a, b) => b.priority.compareTo(a.priority));
  final selected = candidates.first;
  if (candidates.length > 1 && candidates[1].priority == selected.priority ||
      candidates.where((rule) => rule.id == selected.id).length != 1) {
    return const ContextualItemUseRefused(ContextualItemUseRefusal.ambiguous);
  }
  if (project.scenes.where((scene) => scene.id == selected.sceneId).length !=
      1) {
    return const ContextualItemUseRefused(
      ContextualItemUseRefusal.unavailableScene,
    );
  }
  return ContextualItemUseMatched(selected);
}
