import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('retargeting the start preserves every policy and graph property', () {
    final scene = _scene();
    final updated = retargetSceneDialogue(
      scene,
      nodeId: 'dialogue',
      dialogueId: 'conversation',
      yarnNodeName: 'Other',
      expectedOutcomes: const ['yes', 'no', 'cancel'],
      dialogue: _document(),
    );
    final before = _payload(scene);
    final after = _payload(updated);
    expect(after.yarnNodeName, 'Other');
    expect(after.choicePolicies, before.choicePolicies);
    expect(after.linePolicies, before.linePolicies);
    expect(after.speakerHints, before.speakerHints);
    expect(
      after.declaredCancellationOutcomes,
      before.declaredCancellationOutcomes,
    );
    _expectUntouchedGraph(scene, updated);
    expect(SceneAsset.fromJson(updated.toJson()), updated);
    expect(_payload(scene).yarnNodeName, 'Start');
  });

  test(
    'compatible document replacement preserves policies and cancellation branches',
    () {
      final scene = _scene();
      final updated = retargetSceneDialogue(
        scene,
        nodeId: 'dialogue',
        dialogueId: 'replacement',
        yarnNodeName: 'Start',
        expectedOutcomes: const ['yes', 'no', 'cancel'],
        dialogue: _document(),
      );
      expect(_payload(updated).dialogueId, 'replacement');
      expect(_payload(updated).choicePolicies, _payload(scene).choicePolicies);
      expect(_payload(updated).linePolicies, _payload(scene).linePolicies);
      _expectUntouchedGraph(scene, updated);
    },
  );

  test(
    'incompatible replacement rejects policy loss and keeps the original intact',
    () {
      final scene = _scene();
      final before = scene.toJson();
      for (final document in [
        RuntimeDialogueDocument(
          nodes: [
            RuntimeDialogueNode(
              title: 'Start',
              steps: [RuntimeDialogueLine('Hi')],
            ),
          ],
        ),
        _document(text: 'Changed'),
      ]) {
        expect(
          () => retargetSceneDialogue(
            scene,
            nodeId: 'dialogue',
            dialogueId: 'replacement',
            yarnNodeName: 'Start',
            expectedOutcomes: const ['yes', 'no', 'cancel'],
            dialogue: document,
          ),
          throwsA(anyOf(isArgumentError, isA<FormatException>())),
        );
      }
      expect(scene.toJson(), before);
    },
  );

  test(
    'retarget rejects a missing start and preserves stale connections as draft',
    () {
      final scene = _scene();
      expect(
        () => retargetSceneDialogue(
          scene,
          nodeId: 'dialogue',
          dialogueId: 'conversation',
          yarnNodeName: 'Missing',
          expectedOutcomes: const ['yes', 'no', 'cancel'],
          dialogue: _document(),
        ),
        throwsArgumentError,
      );
      final updated = retargetSceneDialogue(
        scene,
        nodeId: 'dialogue',
        dialogueId: 'conversation',
        yarnNodeName: 'Start',
        expectedOutcomes: const ['no', 'cancel'],
        dialogue: _document(),
      );
      expect(_payload(updated).expectedOutcomes, ['no', 'cancel']);
      _expectUntouchedGraph(scene, updated);
    },
  );

  test(
    'choice mutation preserves line feedback and replaces only its scope',
    () {
      final scene = _scene();
      final policy = const SceneDialogueChoicePolicy(
        nodeName: 'Start',
        defaultOutcomeId: 'yes',
        cancellation: SceneDialogueChoiceCancellation.choice('no'),
      );
      final updated = updateSceneDialogueChoicePolicy(
        scene,
        nodeId: 'dialogue',
        dialogue: _document(),
        choicePolicy: policy,
      );
      expect(_payload(updated).choicePolicies, [policy]);
      expect(_payload(updated).linePolicies, _payload(scene).linePolicies);
      expect(_payload(updated).declaredCancellationOutcomes, ['cancel']);
      _expectUntouchedGraph(scene, updated);
      expect(
        () => updateSceneDialogueChoicePolicy(
          scene,
          nodeId: 'dialogue',
          dialogue: _document(),
          choicePolicy: const SceneDialogueChoicePolicy(nodeName: 'Missing'),
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'line mutation preserves choice policy and rejects incompatible content',
    () {
      final scene = _scene();
      final policy = SceneDialogueLinePolicy(
        nodeName: 'Start',
        lineIndex: 0,
        feedback: DialogueLineFeedback(
          revealIntervalMicros: 20000,
          advance: DialogueLineAdvancePolicy.autoAfterReveal(100000),
        ),
      );
      final updated = updateSceneDialogueLinePolicy(
        scene,
        nodeId: 'dialogue',
        dialogue: _document(),
        linePolicy: policy,
      );
      expect(_payload(updated).linePolicies, [policy]);
      expect(_payload(updated).choicePolicies, _payload(scene).choicePolicies);
      _expectUntouchedGraph(scene, updated);
      expect(
        () => updateSceneDialogueLinePolicy(
          scene,
          nodeId: 'dialogue',
          dialogue: _document(),
          linePolicy: SceneDialogueLinePolicy(
            nodeName: 'Start',
            lineIndex: 99,
            feedback: DialogueLineFeedback(),
          ),
        ),
        throwsArgumentError,
      );
    },
  );
}

SceneYarnDialoguePayload _payload(SceneAsset scene) =>
    scene.graph.nodes.singleWhere((node) => node.id == 'dialogue').payload
        as SceneYarnDialoguePayload;

void _expectUntouchedGraph(SceneAsset before, SceneAsset after) {
  expect(after.id, before.id);
  expect(after.graph.startNodeId, before.graph.startNodeId);
  expect(after.graph.edges, before.graph.edges);
  expect(after.layout, before.layout);
  expect(after.declaredOutcomes, before.declaredOutcomes);
  expect(after.metadata, before.metadata);
  expect(after.tags, before.tags);
  expect(after.name, before.name);
  expect(after.description, before.description);
  expect(after.storylineId, before.storylineId);
  expect(after.chapterId, before.chapterId);
  expect(after.executionProfile, before.executionProfile);
  final beforeNode = before.graph.nodes.singleWhere(
    (node) => node.id == 'dialogue',
  );
  final afterNode = after.graph.nodes.singleWhere(
    (node) => node.id == 'dialogue',
  );
  expect(afterNode.title, beforeNode.title);
  expect(afterNode.description, beforeNode.description);
  expect(
    after.graph.nodes.where((node) => node.id != 'dialogue'),
    before.graph.nodes.where((node) => node.id != 'dialogue'),
  );
}

RuntimeDialogueDocument _document({
  String text = 'Hi',
}) => RuntimeDialogueDocument(
  nodes: [
    RuntimeDialogueNode(
      title: 'Start',
      steps: [
        RuntimeDialogueLine(text),
        RuntimeDialogueChoiceBlock([
          RuntimeDialogueChoice(text: 'Yes', steps: const [], outcomeId: 'yes'),
          RuntimeDialogueChoice(text: 'No', steps: const [], outcomeId: 'no'),
        ]),
      ],
    ),
    RuntimeDialogueNode(title: 'Other', steps: [RuntimeDialogueLine('Other')]),
  ],
);

SceneAsset _scene() => SceneAsset(
  id: 'scene',
  name: 'Conversation',
  description: 'Keep',
  storylineId: 'story',
  chapterId: 'chapter',
  tags: const ['test'],
  metadata: const {'note': 'keep'},
  layout: SceneGraphLayout(
    nodeLayouts: [SceneNodeLayout(nodeId: 'dialogue', x: 20, y: 40)],
    edgeLayouts: [SceneEdgeLayout(edgeId: 'cancel')],
  ),
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        title: 'Keep title',
        description: 'Keep node',
        payload: SceneYarnDialoguePayload(
          dialogueId: 'conversation',
          yarnNodeName: 'Start',
          expectedOutcomes: const ['yes', 'no', 'cancel'],
          speakerHints: const ['guide'],
          declaredCancellationOutcomes: const ['cancel'],
          choicePolicies: const [
            SceneDialogueChoicePolicy(
              nodeName: 'Start',
              defaultOutcomeId: 'no',
              cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
            ),
          ],
          linePolicies: [
            SceneDialogueLinePolicy(
              nodeName: 'Start',
              lineIndex: 0,
              feedback: DialogueLineFeedback(
                segments: [DialogueTextSegment('Hi')],
                revealIntervalMicros: 30000,
                advance: DialogueLineAdvancePolicy.autoAfterReveal(250000),
              ),
            ),
          ],
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start-dialogue',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final outcome in ['yes', 'no', 'cancel'])
        SceneEdge(
          id: outcome,
          fromNodeId: 'dialogue',
          fromPortId: outcome,
          toNodeId: 'end',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
    ],
  ),
);
