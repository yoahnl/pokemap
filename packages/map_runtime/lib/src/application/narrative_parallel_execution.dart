import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_runtime/scene_consequence_runtime_writer.dart';
import 'scene_runtime/scene_fact_condition_runtime_resolver.dart';

final class NarrativeParallelProgram {
  NarrativeParallelProgram._(this.scene, this.plan);
  factory NarrativeParallelProgram.compile(
    SceneAsset scene, {
    String? ownerMapId,
  }) {
    final issues = validateNarrativeParallelProgram(
      scene,
      ownerMapId: ownerMapId,
    );
    if (issues.isNotEmpty) {
      throw StateError(issues.join(' '));
    }
    final built = buildSceneRuntimePlan(scene);
    if (!built.canBuild) {
      throw StateError('Parallel Scene cannot build its runtime plan.');
    }
    return NarrativeParallelProgram._(scene, built.plan!);
  }
  final SceneAsset scene;
  final SceneRuntimePlan plan;
}

GameState executeNarrativeParallelProgram({
  required SceneAsset scene,
  required GameState gameState,
  required SceneConsequenceRuntimeWriter writer,
  NarrativeParallelProgram? program,
}) {
  if (program != null && !identical(program.scene, scene)) {
    throw StateError('Parallel program scene changed.');
  }
  final plan = (program ?? NarrativeParallelProgram.compile(scene)).plan;
  final nodes = {for (final node in plan.nodes) node.id: node};
  var current = nodes[plan.startNodeId]!;
  var projected = gameState;
  final resolver = NarrativeFactRuntimeResolver.fromFacts(writer.project.facts);
  for (var step = 0; step < 64; step++) {
    final intent = current.intent;
    String port;
    switch (intent.kind) {
      case SceneRuntimePlanIntentKind.start:
      case SceneRuntimePlanIntentKind.merge:
        port = 'completed';
      case SceneRuntimePlanIntentKind.end:
        return projected;
      case SceneRuntimePlanIntentKind.applyConsequence:
        final result = writer.applyOne(projected, intent.consequence!);
        if (!result.success) {
          throw StateError(result.message ?? 'Parallel write failed.');
        }
        projected = result.gameState;
        port = 'completed';
      case SceneRuntimePlanIntentKind.evaluateCondition:
        final source = intent.conditionSource!;
        if (source.sourceKind == SceneConditionSourceKind.inventoryItem &&
            writer.itemCatalog?.definitionFor(source.sourceId) == null) {
          throw StateError(
            'Parallel inventory condition requires a known item in the authoritative catalog.',
          );
        }
        final passed = switch (source.sourceKind) {
          SceneConditionSourceKind.fact ||
          SceneConditionSourceKind.integerComparison =>
            evaluateCanonicalNarrativeFactSceneCondition(
              source: source,
              gameState: projected,
              resolver: resolver,
            ),
          SceneConditionSourceKind.inventoryItem =>
            evaluateSceneInventoryCondition(
              source: source,
              gameState: projected,
            ),
          SceneConditionSourceKind.mapEventInstanceBoolean =>
            evaluateSceneMapEventInstanceBoolean(
              source: source,
              gameState: projected,
              map:
                  writer.mapsById[source.mapId] ??
                  (throw StateError('Parallel map owner is unavailable.')),
              scope:
                  writer.mapInstanceScopes[source.mapId] ??
                  (throw StateError('Parallel map instance is unavailable.')),
            ),
          _ => throw StateError('Unsupported parallel condition.'),
        };
        port = passed ? 'true' : 'false';
      default:
        throw StateError('Unsupported parallel runtime intent.');
    }
    final routes = plan.edges
        .where(
          (edge) => edge.fromNodeId == current.id && edge.fromPortId == port,
        )
        .toList();
    if (routes.length != 1) {
      throw StateError('Parallel program needs exactly one route for $port.');
    }
    current =
        nodes[routes.single.toNodeId] ??
        (throw StateError('Parallel route target is unavailable.'));
  }
  throw StateError('Parallel program exceeded its node budget.');
}
