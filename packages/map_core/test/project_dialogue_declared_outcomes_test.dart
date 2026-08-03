import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project dialogue declared outcomes', () {
    test('round-trips declared outcomes and defaults legacy JSON to empty', () {
      final legacy = ProjectManifest.fromJson(_projectJson());
      expect(legacy.dialogues.single.declaredOutcomes, isEmpty);

      final manifest = ProjectManifest.fromJson(
        _projectJson(
          declaredOutcomes: [
            {'id': 'accepted', 'label': 'Accepter'},
            {'id': 'refused', 'label': 'Refuser'},
          ],
        ),
      );

      expect(
        manifest.dialogues.single.declaredOutcomes
            .map((outcome) => (outcome.id, outcome.label)),
        [('accepted', 'Accepter'), ('refused', 'Refuser')],
      );
      expect(
        ProjectManifest.fromJson(manifest.toJson())
            .dialogues
            .single
            .declaredOutcomes,
        manifest.dialogues.single.declaredOutcomes,
      );
    });

    test('rejects blank or duplicate declared outcome ids and blank labels',
        () {
      for (final outcomes in <List<Map<String, Object?>>>[
        [
          {'id': '   ', 'label': 'Accepter'},
        ],
        [
          {'id': 'accepted', 'label': 'Accepter'},
          {'id': ' accepted ', 'label': 'Encore'},
        ],
        [
          {'id': 'accepted', 'label': '   '},
        ],
        [
          {'id': 'completed', 'label': 'Terminé'},
        ],
      ]) {
        final manifest = ProjectManifest.fromJson(
          _projectJson(declaredOutcomes: outcomes),
        );

        expect(
          () => ProjectValidator.validate(manifest),
          throwsA(isA<ValidationException>()),
          reason: '$outcomes',
        );
      }
    });

    test('collects outcome consumers by stable dialogue id, not label', () {
      final project = ProjectManifest.fromJson(
        _projectJson(
          declaredOutcomes: [
            {'id': 'accepted', 'label': 'Accepter'},
          ],
        ),
      ).copyWith(
        dialogues: [
          const ProjectDialogueEntry(
            id: 'dialogue_intro',
            name: 'Même nom',
            relativePath: 'dialogues/intro.yarn',
            declaredOutcomes: [
              DialogueDeclaredOutcome(id: 'accepted', label: 'Accepter'),
            ],
          ),
          const ProjectDialogueEntry(
            id: 'dialogue_other',
            name: 'Même nom',
            relativePath: 'dialogues/other.yarn',
            declaredOutcomes: [
              DialogueDeclaredOutcome(id: 'accepted', label: 'Accepter'),
            ],
          ),
        ],
        scenes: [
          _dialogueScene(
            id: 'scene_intro',
            dialogueId: 'dialogue_intro',
            outcomeId: 'accepted',
          ),
          _dialogueScene(
            id: 'scene_other',
            dialogueId: 'dialogue_other',
            outcomeId: 'accepted',
          ),
        ],
      );

      final usages = collectDialogueOutcomeSceneUsages(
        project,
        dialogueId: 'dialogue_intro',
        outcomeId: 'accepted',
      );

      expect(usages.map((usage) => usage.sceneId).toSet(), {'scene_intro'});
      expect(usages.any((usage) => usage.path.contains('expectedOutcomes')),
          isTrue);
      expect(usages.any((usage) => usage.path.contains('edges')), isTrue);
    });

    test('replaces direct and deferred branch outcome ports without legacy',
        () {
      final direct = _dialogueScene(
        id: 'scene_intro',
        dialogueId: 'dialogue_intro',
        outcomeId: 'accepted',
        includeDeferredBranch: true,
      );
      final project = ProjectManifest.fromJson(
        _projectJson(
          declaredOutcomes: [
            {'id': 'accepted', 'label': 'Accepter'},
          ],
        ),
      ).copyWith(scenes: [direct]);

      final updated = replaceDialogueOutcomeSceneReferences(
        project,
        dialogueId: 'dialogue_intro',
        fromOutcomeId: 'accepted',
        toOutcomeId: 'approved',
      );
      final scene = updated.scenes.single;
      final dialoguePayload = scene.graph.nodes
          .where((node) => node.id == 'dialogue')
          .single
          .payload as SceneYarnDialoguePayload;

      expect(dialoguePayload.expectedOutcomes, ['approved']);
      expect(
        scene.graph.edges.where((edge) => edge.fromPortId == 'approved').length,
        2,
      );
      expect(
        collectDialogueOutcomeSceneUsages(
          updated,
          dialogueId: 'dialogue_intro',
          outcomeId: 'accepted',
        ),
        isEmpty,
      );
      expect(
        scene.graph.edges.any((edge) => edge.fromPortId == 'completed'),
        isTrue,
      );
    });
  });
}

SceneAsset _dialogueScene({
  required String id,
  required String dialogueId,
  required String outcomeId,
  bool includeDeferredBranch = false,
}) {
  return SceneAsset(
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
            dialogueId: dialogueId,
            expectedOutcomes: [outcomeId],
          ),
        ),
        if (includeDeferredBranch)
          SceneNode(
            id: 'branch',
            kind: SceneNodeKind.branchByOutcome,
            payload: SceneBranchByOutcomePayload(
              sourceNodeId: 'dialogue',
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
          id: 'dialogue_outcome',
          fromNodeId: 'dialogue',
          fromPortId: outcomeId,
          toNodeId: includeDeferredBranch ? 'branch' : 'end',
          kind: SceneEdgeKind.dialogueOutcome,
        ),
        if (includeDeferredBranch)
          SceneEdge(
            id: 'branch_outcome',
            fromNodeId: 'branch',
            fromPortId: outcomeId,
            toNodeId: 'end',
            kind: SceneEdgeKind.branchOutcome,
          ),
        if (includeDeferredBranch)
          SceneEdge(
            id: 'legacy_completed',
            fromNodeId: 'dialogue',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
      ],
    ),
  );
}

Map<String, Object?> _projectJson({
  List<Map<String, Object?>>? declaredOutcomes,
}) {
  return {
    'name': 'Dialogue outcomes test',
    'version': 'v6',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
    'dialogues': [
      {
        'id': 'dialogue_intro',
        'name': 'Introduction',
        'relativePath': 'dialogues/intro.yarn',
        if (declaredOutcomes != null) 'declaredOutcomes': declaredOutcomes,
      },
    ],
  };
}
