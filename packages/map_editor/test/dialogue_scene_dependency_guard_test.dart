import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/dialogue_scene_dependency_guard.dart';

void main() {
  const guard = DialogueSceneDependencyGuard();

  test('blocks removing an outcome still consumed by a Scene', () {
    final project = _project();

    final decision = guard.inspectOutcomeUpdate(
      project: project,
      dialogueId: 'dialogue_a',
      candidateOutcomes: const [
        DialogueDeclaredOutcome(id: 'refused', label: 'Refuser'),
      ],
    );

    expect(decision.isAllowed, isFalse);
    expect(
      decision.affectedUsages.map((usage) => usage.sceneId).toSet(),
      {'scene_a'},
    );
    expect(decision.message, contains('accepted'));
  });

  test('allows removing an unused outcome and distinguishes equal labels', () {
    final project = _project();

    final decision = guard.inspectOutcomeUpdate(
      project: project,
      dialogueId: 'dialogue_b',
      candidateOutcomes: const <DialogueDeclaredOutcome>[],
    );

    expect(decision.isAllowed, isTrue);
    expect(decision.affectedUsages, isEmpty);
  });

  test('previews an explicit replacement without mutating the source project',
      () {
    final project = _project();

    final preview = guard.previewOutcomeReplacement(
      project: project,
      dialogueId: 'dialogue_a',
      fromOutcomeId: 'accepted',
      replacement: const DialogueDeclaredOutcome(
        id: 'approved',
        label: 'Approuver',
      ),
    );
    final originalPayload = project.scenes.single.graph.nodes
        .where((node) => node.id == 'dialogue')
        .single
        .payload as SceneYarnDialoguePayload;
    final previewPayload = preview.candidateProject.scenes.single.graph.nodes
        .where((node) => node.id == 'dialogue')
        .single
        .payload as SceneYarnDialoguePayload;

    expect(preview.affectedUsages, isNotEmpty);
    expect(originalPayload.expectedOutcomes, ['accepted']);
    expect(previewPayload.expectedOutcomes, ['approved']);
    expect(
      preview.candidateProject.dialogues
          .where((dialogue) => dialogue.id == 'dialogue_a')
          .single
          .declaredOutcomes
          .map((outcome) => outcome.id),
      ['approved', 'refused'],
    );
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Dependency guard',
    maps: const [],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_a',
        name: 'Même nom',
        relativePath: 'dialogues/a.yarn',
        declaredOutcomes: [
          DialogueDeclaredOutcome(id: 'accepted', label: 'Accepter'),
          DialogueDeclaredOutcome(id: 'refused', label: 'Refuser'),
        ],
      ),
      ProjectDialogueEntry(
        id: 'dialogue_b',
        name: 'Même nom',
        relativePath: 'dialogues/b.yarn',
        declaredOutcomes: [
          DialogueDeclaredOutcome(id: 'accepted', label: 'Accepter'),
        ],
      ),
    ],
    scenes: [
      SceneAsset(
        id: 'scene_a',
        name: 'Scene A',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(
                dialogueId: 'dialogue_a',
                expectedOutcomes: const ['accepted'],
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_dialogue',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'dialogue',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'dialogue_end',
              fromNodeId: 'dialogue',
              fromPortId: 'accepted',
              toNodeId: 'end',
              kind: SceneEdgeKind.dialogueOutcome,
            ),
          ],
        ),
      ),
    ],
  );
}
