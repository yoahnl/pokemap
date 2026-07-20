import 'package:map_core/map_core.dart';

bool evaluateCanonicalNarrativeFactSceneCondition({
  required SceneConditionSource source,
  required GameState gameState,
  required NarrativeFactRuntimeResolver resolver,
}) {
  if (source.sourceKind != SceneConditionSourceKind.fact) {
    throw ArgumentError.value(
      source.sourceKind,
      'source.sourceKind',
      'must be SceneConditionSourceKind.fact',
    );
  }
  final resolution = resolver.resolve(
    factId: source.sourceId,
    runtimeState: gameState.narrativeFactRuntimeState,
    storyFlags: gameState.storyFlags,
  );
  if (resolution is! NarrativeFactRuntimeResolved) {
    throw StateError(
      'Canonical Fact condition "${source.sourceId}" could not be resolved: '
      '${resolution.runtimeType}.',
    );
  }
  final expected = source.resolvedExpectedFactValue;
  if (resolution.narrativeValue.kind != expected.kind) {
    return false;
  }
  return resolution.narrativeValue.matches(
    source.resolvedFactOperator,
    expected,
  );
}
