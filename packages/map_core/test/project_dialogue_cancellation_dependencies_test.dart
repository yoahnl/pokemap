import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'scene-local branch cancellation is not a public dialogue dependency',
    () {
      final project = _project();
      final before = project.toJson();

      expect(_usages(project, 'cancel'), isEmpty);
      expect(_usages(project, 'yes'), hasLength(3));
      expect(
        collectDialogueOutcomeSceneUsages(
          project,
          dialogueId: 'dialogue',
        ).map((usage) => usage.outcomeId).toSet(),
        {'yes', 'no'},
      );
      expect(project.toJson(), before);
    },
  );

  test('local cancellation filtering follows each deferred branch source', () {
    final project = _project(includeSecondScope: true);
    final usages = _usages(project, 'cancel');

    expect(usages, hasLength(3));
    expect(usages.map((usage) => usage.nodeId).toSet(), {
      'second',
      'second_branch',
    });
    expect(usages.every((usage) => usage.path.contains('scene')), isTrue);
  });

  test('a colliding declared public outcome remains a blocking dependency', () {
    expect(
      () => validateSceneDialogueChoicePolicies(
        [
          SceneDialogueChoiceScope(
            nodeName: 'Start',
            choiceIndex: 0,
            outcomeIds: ['yes', 'no'],
          ),
          SceneDialogueChoiceScope(
            nodeName: 'Other',
            choiceIndex: 0,
            outcomeIds: ['cancel'],
          ),
        ],
        const [
          SceneDialogueChoicePolicy(
            nodeName: 'Start',
            cancellation: SceneDialogueChoiceCancellation.branch('cancel'),
          ),
        ],
      ),
      returnsNormally,
    );
    final usages = _usages(_project(publicCancellation: true), 'cancel');

    expect(usages, hasLength(3));
    expect(
      usages.any((usage) => usage.path.contains('expectedOutcomes')),
      isTrue,
    );
    expect(usages.map((usage) => usage.nodeId).toSet(), {
      'dialogue',
      'dialogue_branch',
    });
  });

  test(
    'cancellation selecting a public choice retains its public dependency',
    () {
      final project = _project(choiceCancellation: true);

      expect(_usages(project, 'no'), hasLength(3));
      expect(_usages(project, 'yes'), hasLength(3));
    },
  );

  test('an unknown outcome without a local declaration is still reported', () {
    final project = _project(includeSecondScope: true);

    expect(_usages(project, 'unknown'), hasLength(3));
  });

  test('dialogue identity and completed flow keep their strict scope', () {
    final project = _project();

    expect(_usages(project, 'completed'), isEmpty);
    expect(
      collectDialogueOutcomeSceneUsages(
        project,
        dialogueId: 'different_dialogue',
        outcomeId: 'yes',
      ),
      isEmpty,
    );
    expect(_usages(project, 'no'), hasLength(3));
  });
}

List<DialogueOutcomeSceneUsage> _usages(
  ProjectManifest project,
  String outcome,
) => collectDialogueOutcomeSceneUsages(
  project,
  dialogueId: 'dialogue',
  outcomeId: outcome,
);

ProjectManifest _project({
  bool publicCancellation = false,
  bool choiceCancellation = false,
  bool includeSecondScope = false,
}) {
  final first = SceneYarnDialoguePayload(
    dialogueId: 'dialogue',
    expectedOutcomes: choiceCancellation
        ? ['yes', 'no']
        : ['yes', 'no', 'cancel'],
    choicePolicies: [
      SceneDialogueChoicePolicy(
        nodeName: 'Start',
        cancellation: choiceCancellation
            ? const SceneDialogueChoiceCancellation.choice('no')
            : const SceneDialogueChoiceCancellation.branch('cancel'),
      ),
    ],
  );
  final payloads = {
    'dialogue': first,
    if (includeSecondScope)
      'second': SceneYarnDialoguePayload(
        dialogueId: 'dialogue',
        expectedOutcomes: const ['cancel', 'unknown'],
      ),
  };
  return ProjectManifest(
    name: 'Public outcomes and scene cancellation',
    maps: const [],
    tilesets: const [],
    dialogues: [
      ProjectDialogueEntry(
        id: 'dialogue',
        name: 'Dialogue',
        relativePath: 'dialogues/dialogue.yarn',
        declaredOutcomes: [
          const DialogueDeclaredOutcome(id: 'yes', label: 'Oui'),
          const DialogueDeclaredOutcome(id: 'no', label: 'Non'),
          if (publicCancellation)
            const DialogueDeclaredOutcome(
              id: 'cancel',
              label: 'Sortie publique',
            ),
        ],
      ),
    ],
    scenes: [
      SceneAsset(
        id: 'scene',
        name: 'Scene',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            for (final entry in payloads.entries) ...[
              SceneNode(
                id: entry.key,
                kind: SceneNodeKind.yarnDialogue,
                payload: entry.value,
              ),
              SceneNode(
                id: '${entry.key}_branch',
                kind: SceneNodeKind.branchByOutcome,
                payload: SceneBranchByOutcomePayload(sourceNodeId: entry.key),
              ),
            ],
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
            for (final entry in payloads.entries) ...[
              SceneEdge(
                id: '${entry.key}_completed',
                fromNodeId: entry.key,
                fromPortId: 'completed',
                toNodeId: '${entry.key}_branch',
                kind: SceneEdgeKind.defaultFlow,
              ),
              for (final outcome in entry.value.expectedOutcomes) ...[
                SceneEdge(
                  id: '${entry.key}_direct_$outcome',
                  fromNodeId: entry.key,
                  fromPortId: outcome,
                  toNodeId: 'end',
                  kind: SceneEdgeKind.dialogueOutcome,
                ),
                SceneEdge(
                  id: '${entry.key}_deferred_$outcome',
                  fromNodeId: '${entry.key}_branch',
                  fromPortId: outcome,
                  toNodeId: 'end',
                  kind: SceneEdgeKind.branchOutcome,
                ),
              ],
            ],
          ],
        ),
      ),
    ],
  );
}
