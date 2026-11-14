import 'package:map_core/map_core_domain.dart';

import '../../../narrative/application/scene_node_references.dart';
import '../../../narrative/domain/narrative_port.dart';
import 'behaviour_line.dart';
import 'behaviour_line_draft.dart';

final class BehaviourDialogueSharing {
  BehaviourDialogueSharing(List<String> otherSceneIds)
    : otherSceneIds = List.unmodifiable(otherSceneIds);

  final List<String> otherSceneIds;

  bool get shared => otherSceneIds.isNotEmpty;
}

BehaviourDialogueSharing behaviourDialogueSharing({
  required String sceneId,
  required String dialogueId,
  required Iterable<SceneAsset> scenes,
}) => BehaviourDialogueSharing([
  ...{
    for (final reference in sceneNodesWhere(
      scenes,
      (node) => switch (node.payload) {
        SceneYarnDialoguePayload(dialogueId: final id) => id == dialogueId,
        _ => false,
      },
    ))
      if (reference.scene.id != sceneId) reference.scene.id,
  },
]);

final class BehaviourLineDetached {
  const BehaviourLineDetached({required this.scene, required this.line});

  final SceneAsset scene;
  final BehaviourLine line;
}

BehaviourLineDetached detachBehaviourLine({
  required BehaviourLine line,
  required SceneAsset scene,
  required BehaviourLineIds ids,
}) {
  if (scene.id != line.sceneId || behaviourLineDialogueId(scene) == null) {
    throw ArgumentError.value(scene.id, 'scene');
  }
  final json = scene.toJson();
  final graph = Map<String, dynamic>.of(json['graph'] as Map<String, dynamic>);
  graph['nodes'] = [
    for (final node in graph['nodes'] as List<dynamic>)
      _detachedNode(node as Map<String, dynamic>, ids.dialogueId),
  ];
  final dialogue = NarrativeDialogueSource(
    entry: line.dialogue.entry.copyWith(
      id: ids.dialogueId,
      relativePath: ids.dialoguePath,
    ),
    source: line.dialogue.source,
  );
  return BehaviourLineDetached(
    scene: SceneAsset.fromJson({...json, 'graph': graph}),
    line: BehaviourLine(
      sceneId: line.sceneId,
      dialogue: dialogue,
      nodeTitle: line.nodeTitle,
      nodeName: line.nodeName,
      speakerId: line.speakerId,
      lines: line.lines,
      studioFormat: line.studioFormat,
    ),
  );
}

Map<String, dynamic> _detachedNode(
  Map<String, dynamic> node,
  String dialogueId,
) {
  final payload = node['payload'];
  if (node['kind'] != 'yarnDialogue' || payload is! Map<String, dynamic>) {
    return node;
  }
  return {
    ...node,
    'payload': {...payload, 'dialogueId': dialogueId},
  };
}
