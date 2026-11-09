import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

final class ScenePeriodicEncounterAuthoringGateway {
  const ScenePeriodicEncounterAuthoringGateway();

  Future<ProjectManifest> updateDraft({
    required ProjectManifest project,
    required String sceneId,
    required String nodeId,
    required bool enabled,
    required String label,
    required Set<PeriodicEncounterOutcome> consumeOnOutcomes,
  }) async => const SceneActions().updateBattlePeriodicEncounter(
    project,
    sceneId: sceneId,
    nodeId: nodeId,
    enabled: enabled,
    label: label,
    consumeOnOutcomes: consumeOnOutcomes,
  );
}
