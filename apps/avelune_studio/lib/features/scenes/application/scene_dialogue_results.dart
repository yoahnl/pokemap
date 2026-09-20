import 'package:map_core/map_core_domain.dart';
import 'scene_workspace_controller.dart';

extension SceneDialogueResults on SceneWorkspaceController {
  void refreshDialogueResults(String dialogueId) {
    final entry = project.dialogues
        .where((d) => d.id == dialogueId)
        .firstOrNull;
    if (entry == null) return;
    for (final session in sessions.values) {
      final relevant = session.current.graph.nodes.where(
        (node) =>
            node.payload is SceneYarnDialoguePayload &&
            (node.payload as SceneYarnDialoguePayload).dialogueId == dialogueId,
      );
      if (relevant.isEmpty) continue;
      session.mutate(
        (scene) => SceneAsset.fromJson({
          ...scene.toJson(),
          'graph': {
            ...scene.graph.toJson(),
            'nodes': [
              for (final node in scene.graph.nodes)
                if (node.payload case SceneYarnDialoguePayload payload
                    when payload.dialogueId == dialogueId)
                  SceneNode(
                    id: node.id,
                    kind: node.kind,
                    title: node.title,
                    description: node.description,
                    payload: SceneYarnDialoguePayload(
                      dialogueId: payload.dialogueId,
                      yarnNodeName: payload.yarnNodeName,
                      expectedOutcomes: {
                        ...payload.expectedOutcomes,
                        ...entry.declaredOutcomes.map((o) => o.id),
                      }.toList(),
                      speakerHints: payload.speakerHints,
                    ),
                  ).toJson()
                else
                  node.toJson(),
            ],
          },
        }),
      );
    }
  }
}
