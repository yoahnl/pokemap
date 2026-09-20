import 'package:map_core/map_core.dart';

import 'dialogue_authoring_service.dart';
import 'narrative_authoring_exception.dart';

void validateDialogueSceneStarts({
  required ProjectManifest project,
  required String dialogueId,
  required DialogueAuthoringCompileResult compiled,
}) {
  final titles = {for (final node in compiled.document!.nodes) node.title};
  final references = <String>[];
  for (final scene in project.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneYarnDialoguePayload ||
          payload.dialogueId != dialogueId) {
        continue;
      }
      final start = payload.yarnNodeName;
      if (start != null && start.isNotEmpty && !titles.contains(start)) {
        references.add('scenes[${scene.id}].nodes[${node.id}]: $start');
      }
    }
  }
  if (references.isNotEmpty) {
    throw NarrativeAuthoringException(
      'dialogue.scene_start_references_blocking',
      'A Scene still starts this dialogue at a missing Yarn node.',
      details: {'references': references},
    );
  }
}
