import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('public outcome replacement rewrites choice policies without losing a cancellation branch', () {
    final payload = SceneYarnDialoguePayload(dialogueId: 'dialogue_pick', expectedOutcomes: const ['yes', 'no', 'cancel'],
      choicePolicies: const [
        SceneDialogueChoicePolicy(nodeName: 'Start', defaultOutcomeId: 'no', cancellation: SceneDialogueChoiceCancellation.choice('no')),
        SceneDialogueChoicePolicy(nodeName: 'Next', cancellation: SceneDialogueChoiceCancellation.branch('cancel')),
      ]);
    final project = ProjectManifest(name: 'Policy replacement', maps: const [], tilesets: const [], scenes: [
      SceneAsset(id: 'scene', name: 'Scene', graph: SceneGraph(startNodeId: 'start', nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(id: 'dialogue', kind: SceneNodeKind.yarnDialogue, payload: payload),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ], edges: [
        SceneEdge(id: 'start-dialogue', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'dialogue', kind: SceneEdgeKind.defaultFlow),
        for (final id in ['completed', 'yes', 'no', 'cancel'])
          SceneEdge(id: 'dialogue-$id', fromNodeId: 'dialogue', fromPortId: id, toNodeId: 'end',
            kind: id == 'completed' ? SceneEdgeKind.defaultFlow : SceneEdgeKind.dialogueOutcome),
      ])),
    ]);
    final rewritten = replaceDialogueOutcomeSceneReferences(project, dialogueId: 'dialogue_pick', fromOutcomeId: 'no', toOutcomeId: 'refused');
    final replacement = rewritten.scenes.single.graph.nodes.singleWhere((node) => node.id == 'dialogue').payload as SceneYarnDialoguePayload;
    expect(replacement.choicePolicies, const [
      SceneDialogueChoicePolicy(nodeName: 'Start', defaultOutcomeId: 'refused', cancellation: SceneDialogueChoiceCancellation.choice('refused')),
      SceneDialogueChoicePolicy(nodeName: 'Next', cancellation: SceneDialogueChoiceCancellation.branch('cancel')),
    ]);
  });

  test('typed cancellation and default survive native scene payload JSON', () {
    final payload = SceneYarnDialoguePayload(
      dialogueId: 'dialogue_pick',
      expectedOutcomes: const ['yes', 'no', 'cancel'],
      choicePolicies: const [
        SceneDialogueChoicePolicy(
          nodeName: 'Start',
          defaultOutcomeId: 'no',
          cancellation: SceneDialogueChoiceCancellation.choice('no'),
        ),
        SceneDialogueChoicePolicy(
          nodeName: 'Next',
          choiceIndex: 1,
          cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
        ),
      ],
    );
    final reloaded = SceneYarnDialoguePayload.fromJson(
      jsonDecode(jsonEncode(payload.toJson())) as Map<String, dynamic>,
    );
    expect(reloaded.choicePolicies, payload.choicePolicies);
    expect(reloaded, payload);
    expect(reloaded.hashCode, payload.hashCode);
    expect(reloaded.toJson()['choicePolicies'], [
      {
        'nodeName': 'Start',
        'choiceIndex': 0,
        'defaultOutcomeId': 'no',
        'cancellation': {'kind': 'choice', 'outcomeId': 'no'},
      },
      {
        'nodeName': 'Next',
        'choiceIndex': 1,
        'cancellation': {'kind': 'branch', 'outcomeId': 'cancel'},
      },
    ]);
  });

  test('rejects duplicate choice scopes and undeclared outcome references', () {
    for (final policies in <List<SceneDialogueChoicePolicy>>[
      const [
        SceneDialogueChoicePolicy(nodeName: 'Start'),
        SceneDialogueChoicePolicy(nodeName: 'Start'),
      ],
      const [SceneDialogueChoicePolicy(nodeName: ' ')],
      const [SceneDialogueChoicePolicy(nodeName: 'Start', choiceIndex: -1)],
      const [SceneDialogueChoicePolicy(nodeName: 'Start', defaultOutcomeId: 'missing')],
      const [SceneDialogueChoicePolicy(nodeName: 'Start', cancellation: SceneDialogueChoiceCancellation.branch('missing'))],
      const [SceneDialogueChoicePolicy(nodeName: 'Start', cancellation: SceneDialogueChoiceCancellation.choice(''))],
    ]) {
      expect(
        () => SceneYarnDialoguePayload(
          dialogueId: 'dialogue_pick',
          expectedOutcomes: const ['yes', 'no'],
          choicePolicies: policies,
        ),
        throwsA(isA<ValidationException>()),
      );
    }
  });

  test('rejects unknown cancellation kinds and malformed disabled policies', () {
    for (final cancellation in [
      {'kind': 'technicalFailure'},
      {'kind': 'disabled', 'outcomeId': 'no'},
      {'kind': 'branch'},
    ]) {
      expect(
        () => SceneYarnDialoguePayload.fromJson({
          'dialogueId': 'dialogue_pick',
          'expectedOutcomes': ['yes', 'no'],
          'choicePolicies': [
            {'nodeName': 'Start', 'choiceIndex': 0, 'cancellation': cancellation},
          ],
        }),
        throwsA(anyOf(isA<FormatException>(), isA<ValidationException>())),
      );
    }
  });
}
