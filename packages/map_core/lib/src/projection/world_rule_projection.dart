import '../diagnostics/world_rule_diagnostics.dart';
import '../models/game_state.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';
import '../operations/narrative_fact_runtime.dart';

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
  final factResolver = NarrativeFactRuntimeResolver.fromFacts(project.facts);
  final resolved = <WorldRuleResolvedEffect>[];
  for (final rule in project.worldRules) {
    if (!rule.enabled || invalidRuleIds.contains(rule.id)) {
      continue;
    }
    if (mapId != null && rule.target.mapId != mapId) {
      continue;
    }
    if (!_sourceMatches(rule.source, gameState, factResolver)) {
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
  NarrativeFactRuntimeResolver factResolver,
) {
  return switch (source.kind) {
    WorldRuleSourceKind.fact => _factMatches(source, gameState, factResolver),
    WorldRuleSourceKind.storyStepCompletion =>
      _storyStepCompletionMatches(source, gameState),
    WorldRuleSourceKind.consumedEvent =>
      _consumedEventMatches(source, gameState),
  };
}

bool _factMatches(
  WorldRuleSource source,
  GameState gameState,
  NarrativeFactRuntimeResolver factResolver,
) {
  final resolution = factResolver.resolve(
    factId: source.sourceId,
    runtimeState: gameState.narrativeFactRuntimeState,
    storyFlags: gameState.storyFlags,
  );
  if (resolution is! NarrativeFactRuntimeResolved) {
    return false;
  }
  final expected = source.resolvedExpectedFactValue;
  if (resolution.narrativeValue.kind != expected.kind) return false;
  return switch (source.predicate) {
    WorldRuleSourcePredicate.isTrue ||
    WorldRuleSourcePredicate.isFalse =>
      resolution.narrativeValue.matches(
        source.resolvedFactOperator,
        expected,
      ),
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
