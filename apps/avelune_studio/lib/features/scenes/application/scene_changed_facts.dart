import 'package:map_core/map_core_domain.dart';

List<String> sceneChangedFactIds(SceneGraph graph) => {
  for (final node in graph.nodes)
    if (node.payload case SceneActionPayload(:final consequence?))
      ...switch (consequence) {
        SceneSetFactConsequence(:final factId) => [factId],
        SceneAdjustIntegerFactConsequence(:final factId) => [factId],
        SceneCalculateIntegerFactsConsequence(:final factIds) => factIds,
        _ => const <String>[],
      },
}.toList();
