import '../diagnostics/world_rule_diagnostics.dart';
import '../models/game_state.dart';
import '../models/map_data.dart';
import '../models/narrative_fact.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';

final class WorldRuleResolvedEffect {
  const WorldRuleResolvedEffect({
    required this.ruleId,
    required this.target,
    required this.effect,
    required this.priority,
  });

  final String ruleId;
  final WorldRuleTarget target;
  final WorldRuleEffect effect;
  final int priority;
}

List<WorldRuleResolvedEffect> projectWorldRuleEffects(
  ProjectManifest project,
  GameState gameState, {
  List<MapData> maps = const <MapData>[],
  String? mapId,
}) {
  final diagnostics = diagnoseWorldRules(project, maps: maps);
  final invalidRuleIds = {
    for (final diagnostic in diagnostics.diagnostics)
      if (diagnostic.severity == WorldRuleDiagnosticSeverity.error)
        diagnostic.ruleId,
  };
  final factById = {for (final fact in project.facts) fact.id: fact};
  final resolved = <WorldRuleResolvedEffect>[];
  for (final rule in project.worldRules) {
    if (!rule.enabled || invalidRuleIds.contains(rule.id)) {
      continue;
    }
    if (mapId != null && rule.target.mapId != mapId) {
      continue;
    }
    if (!_sourceMatches(rule.source, gameState, factById)) {
      continue;
    }
    resolved.add(
      WorldRuleResolvedEffect(
        ruleId: rule.id,
        target: rule.target,
        effect: rule.effect,
        priority: rule.priority,
      ),
    );
  }
  resolved.sort((a, b) {
    final byPriority = a.priority.compareTo(b.priority);
    if (byPriority != 0) {
      return byPriority;
    }
    return a.ruleId.compareTo(b.ruleId);
  });
  return List<WorldRuleResolvedEffect>.unmodifiable(resolved);
}

bool _sourceMatches(
  WorldRuleSource source,
  GameState gameState,
  Map<String, NarrativeFactDefinition> factById,
) {
  return switch (source.kind) {
    WorldRuleSourceKind.fact => _factMatches(source, gameState, factById),
    WorldRuleSourceKind.storyStepCompletion =>
      _storyStepCompletionMatches(source, gameState),
    WorldRuleSourceKind.consumedEvent =>
      _consumedEventMatches(source, gameState),
  };
}

bool _factMatches(
  WorldRuleSource source,
  GameState gameState,
  Map<String, NarrativeFactDefinition> factById,
) {
  final fact = factById[source.sourceId];
  if (fact == null) {
    return false;
  }
  final runtimeKey = fact.legacyFlagName ?? fact.id;
  final active = gameState.storyFlags.activeFlags.contains(runtimeKey) ||
      fact.defaultValue;
  return switch (source.predicate) {
    WorldRuleSourcePredicate.isTrue => active,
    WorldRuleSourcePredicate.isFalse => !active,
    WorldRuleSourcePredicate.completed ||
    WorldRuleSourcePredicate.notCompleted ||
    WorldRuleSourcePredicate.consumed ||
    WorldRuleSourcePredicate.notConsumed =>
      false,
  };
}

bool _storyStepCompletionMatches(
  WorldRuleSource source,
  GameState gameState,
) {
  final completed = gameState.progression.completedStepIds
      .map((id) => id.trim())
      .contains(source.sourceId);
  return switch (source.predicate) {
    WorldRuleSourcePredicate.completed => completed,
    WorldRuleSourcePredicate.notCompleted => !completed,
    WorldRuleSourcePredicate.isTrue ||
    WorldRuleSourcePredicate.isFalse ||
    WorldRuleSourcePredicate.consumed ||
    WorldRuleSourcePredicate.notConsumed =>
      false,
  };
}

bool _consumedEventMatches(
  WorldRuleSource source,
  GameState gameState,
) {
  final consumed = gameState.consumedEventIds.contains(source.sourceId);
  return switch (source.predicate) {
    WorldRuleSourcePredicate.consumed => consumed,
    WorldRuleSourcePredicate.notConsumed => !consumed,
    WorldRuleSourcePredicate.isTrue ||
    WorldRuleSourcePredicate.isFalse ||
    WorldRuleSourcePredicate.completed ||
    WorldRuleSourcePredicate.notCompleted =>
      false,
  };
}
