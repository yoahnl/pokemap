import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';

const dialoguePolicySource = '''
title: Start
---
Bonjour.
Une autre ligne.
-> Oui
    <<outcome yes>>
-> Non
    <<outcome no>>
===
''';

const dialoguePolicyEntry = ProjectDialogueEntry(
  id: 'guide',
  name: 'Conversation du guide',
  relativePath: 'dialogues/guide.yarn',
  defaultStartNode: 'Start',
  declaredOutcomes: [
    DialogueDeclaredOutcome(id: 'yes', label: 'Accepter'),
    DialogueDeclaredOutcome(id: 'no', label: 'Refuser'),
  ],
);

const emptyDialoguePolicyEntry = ProjectDialogueEntry(
  id: 'empty',
  name: 'Document sans choix',
  relativePath: 'dialogues/empty.yarn',
  defaultStartNode: 'Start',
);

SceneYarnDialoguePayload dialoguePolicyPayload(SceneAsset scene) =>
    scene.graph.nodes.singleWhere((node) => node.id == 'talk').payload
        as SceneYarnDialoguePayload;

SceneAsset dialoguePolicyScene() => SceneAsset(
  id: 'meeting',
  name: 'Rencontre du guide',
  metadata: const {'original': 'synthetic'},
  layout: SceneGraphLayout(
    nodeLayouts: [SceneNodeLayout(nodeId: 'talk', x: 150, y: 80)],
    edgeLayouts: [SceneEdgeLayout(edgeId: 'cancel')],
  ),
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'talk',
        kind: SceneNodeKind.yarnDialogue,
        title: 'Dialogue du guide',
        payload: SceneYarnDialoguePayload(
          dialogueId: 'guide',
          yarnNodeName: 'Start',
          expectedOutcomes: const ['yes', 'no', 'cancel'],
          choicePolicies: const [
            SceneDialogueChoicePolicy(
              nodeName: 'Start',
              defaultOutcomeId: 'yes',
              cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
            ),
          ],
          linePolicies: [
            SceneDialogueLinePolicy(
              nodeName: 'Start',
              lineIndex: 0,
              feedback: DialogueLineFeedback(
                segments: [
                  DialogueTextSegment(
                    'Bonjour.',
                    style: DialogueSegmentStyle(colorArgb: 0xff123456),
                  ),
                ],
                revealIntervalMicros: 25000,
                advance: DialogueLineAdvancePolicy.autoAfterReveal(250000),
              ),
            ),
            SceneDialogueLinePolicy(
              nodeName: 'Start',
              lineIndex: 1,
              feedback: DialogueLineFeedback(revealIntervalMicros: 40000),
            ),
          ],
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start-talk',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'talk',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'completed',
        fromNodeId: 'talk',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final outcome in ['yes', 'no', 'cancel'])
        SceneEdge(
          id: outcome,
          fromNodeId: 'talk',
          fromPortId: outcome,
          toNodeId: 'end',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
    ],
  ),
);

class DialoguePolicyPublicationFixture {
  DialoguePolicyPublicationFixture(
    this.root,
    this.session,
    this.maps,
    this.project,
  );
  final Directory root;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final ProjectManifest project;
  File get projectFile => File('${root.path}/project.json');
  File get sourceFile =>
      File('${root.path}/${dialoguePolicyEntry.relativePath}');

  static Future<DialoguePolicyPublicationFixture> create() async {
    final temporary = await Directory.systemTemp.createTemp(
      'dialogue_policy_publication_',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    await Directory('${root.path}/dialogues').create();
    final project = ProjectManifest(
      name: 'Politiques du guide',
      maps: const [],
      tilesets: const [],
      dialogues: const [dialoguePolicyEntry, emptyDialoguePolicyEntry],
      scenes: [dialoguePolicyScene()],
    );
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await File('${root.path}/${dialoguePolicyEntry.relativePath}')
        .writeAsString(dialoguePolicySource);
    await File('${root.path}/${emptyDialoguePolicyEntry.relativePath}')
        .writeAsString('title: Start\n---\nSans choix.\n===\n');
    final session = ProjectSession(
      sessionId: root.path,
      name: project.name,
      directoryPath: root.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    return DialoguePolicyPublicationFixture(
      root,
      session,
      maps,
      await maps.loadProject(session),
    );
  }
}
