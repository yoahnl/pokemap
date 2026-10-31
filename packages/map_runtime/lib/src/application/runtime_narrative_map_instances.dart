import 'package:map_core/map_core.dart';

bool hasNarrativeMapInstanceReferences(ProjectManifest project, String mapId) {
  for (final scene in project.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is SceneConditionPayload) {
        final source = payload.conditionSource;
        if (source?.sourceKind ==
                SceneConditionSourceKind.mapEventInstanceBoolean &&
            source?.mapId == mapId) {
          return true;
        }
      }
      if (payload is SceneActionPayload) {
        final consequence = payload.consequence;
        if (consequence is SceneSetMapEventInstanceBooleanConsequence &&
            consequence.mapId == mapId) {
          return true;
        }
      }
    }
  }
  for (final record
      in project.eventRegistry?.records ?? const <NarrativeEventRecord>[]) {
    for (final condition
        in record.definitionOrNull?.conditions ??
            const <NarrativeEventCondition>[]) {
      if (condition.whenTyped(
        periodicRewardAvailable: (_, _) => false,
        fact: (_, _, _) => false,
        narrativeEventConsumed: (_, _) => false,
        mapEventInstanceBoolean: (ownerMapId, _, _, _) => ownerMapId == mapId,
      )) {
        return true;
      }
    }
  }
  return false;
}
