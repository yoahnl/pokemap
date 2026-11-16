import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

Future<({int documents, int index, int levels})> measureDialogueCatalogAccesses(
  CatalogStorageStore store,
  List<String> accesses,
) async {
  final head = (await store.readHead())!;
  final counts = <String, int>{};
  for (final path in accesses.where(
    (path) =>
        path.startsWith('${store.projectRoot}/catalog/objects/') &&
        path.endsWith('.json'),
  )) {
    counts.update(path, (value) => value + 1, ifAbsent: () => 1);
  }
  var documents = 0;
  var index = 0;
  for (final entry in counts.entries) {
    final value = jsonDecode(await File(entry.key).readAsString()) as Map;
    switch (value['type']) {
      case 'unit':
        documents += entry.value;
      case 'root' || 'branch' || 'leaf':
        index += entry.value;
      default:
        throw StateError('Unknown catalog object ${entry.key}');
    }
  }
  final root = jsonDecode(utf8.decode(await store.readObject(head))) as Map;
  return (
    documents: documents,
    index: index,
    levels: ((root['index'] as Map?)?['height'] as int? ?? 0) + 1,
  );
}

SceneAsset dialogueConsumerScene(String id, String dialogue) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: dialogue,
          linePolicies: [
            SceneDialogueLinePolicy(
              nodeName: 'Start',
              lineIndex: 0,
              feedback: DialogueLineFeedback(
                segments: [DialogueTextSegment('Bonjour !')],
              ),
            ),
          ],
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'last',
        fromNodeId: 'dialogue',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);
