import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_scene_runtime_execution.dart';

void main() {
  group('Scene BranchByOutcome runtime integration', () {
    test(
        'Dialogue outcome follows the same Merge/Branch/End path in preview '
        'and runtime', () async {
      final scene = _scene();
      final project = _project(scene);
      const initial = GameState(saveId: 'save_branch_merge');

      final preview = previewSceneRuntimePath(
        buildSceneRuntimePlan(scene).plan!,
        input: const SceneDryRunInputState(
          outputPortByNodeId: {'dialogue': 'accept'},
        ),
      );
      final runtime = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_branch_merge',
          sceneId: 'scene_branch_merge',
          executionId: 'execution_branch_merge',
          gameState: initial,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => initial,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition'),
          showDialogue: (_) => 'accept',
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      );

      expect(preview.status, SceneDryRunPreviewStatus.completed);
      expect(preview.sceneOutcomeId, 'scene.accepted');
      expect(preview.context.branchProvenance.single.sourceOutcome, 'accept');
      expect(runtime, isA<NarrativeSceneExecutionCompleted>());
      final completed = runtime as NarrativeSceneExecutionCompleted;
      expect(
        completed.updatedGameState.storyFlags.activeFlags,
        contains('fact_branch_reward'),
      );
      expect(completed.qualifiedOutcomes.single.outcomeId, 'scene.accepted');
    });

    test('refuse reaches a different End without applying accept consequence',
        () async {
      final scene = _scene();
      final project = _project(scene);
      const initial = GameState(saveId: 'save_branch_merge_refuse');

      final runtime = await executeNarrativeEventScene(
        request: const NarrativeSceneExecutionRequest(
          eventId: 'event_branch_merge',
          sceneId: 'scene_branch_merge',
          executionId: 'execution_branch_merge_refuse',
          gameState: initial,
        ),
        project: project,
        mapsById: const <String, MapData>{},
        currentGameState: () => initial,
        callbacks: SceneRuntimeHostCallbacks(
          evaluateCondition: (_) => throw StateError('Unexpected condition'),
          showDialogue: (_) => 'refuse',
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
        ),
      ) as NarrativeSceneExecutionCompleted;

      expect(runtime.updatedGameState.storyFlags.activeFlags,
          isNot(contains('fact_branch_reward')));
      expect(runtime.qualifiedOutcomes.single.outcomeId, 'scene.refused');
    });
  });
}

ProjectManifest _project(SceneAsset scene) {
  return ProjectManifest(
    name: 'Branch merge integration',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'dialogue_branch',
        name: 'Branch dialogue',
        relativePath: 'dialogues/dialogue_branch.yarn',
        declaredOutcomes: [
          DialogueDeclaredOutcome(id: 'accept', label: 'Accept'),
          DialogueDeclaredOutcome(id: 'refuse', label: 'Refuse'),
        ],
      ),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_branch_reward',
        label: 'Branch reward',
      ),
    ],
    scenes: [scene],
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
  );
}

SceneAsset _scene() {
  return SceneAsset(
    id: 'scene_branch_merge',
    name: 'Branch merge',
    declaredOutcomes: [
      SceneOutcome(id: 'scene.accepted', label: 'Accepted'),
      SceneOutcome(id: 'scene.refused', label: 'Refused'),
      SceneOutcome(id: 'scene.completed', label: 'Completed'),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(
            dialogueId: 'dialogue_branch',
            expectedOutcomes: const ['accept', 'refuse'],
          ),
        ),
        SceneNode(id: 'merge_before_branch', kind: SceneNodeKind.merge),
        SceneNode(
          id: 'branch',
          kind: SceneNodeKind.branchByOutcome,
          payload: SceneBranchByOutcomePayload(sourceNodeId: 'dialogue'),
        ),
        SceneNode(
          id: 'accept_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_branch_reward',
              value: true,
            ),
          ),
        ),
        SceneNode(id: 'merge_after_action', kind: SceneNodeKind.merge),
        SceneNode(
          id: 'end_accept',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.accepted'),
        ),
        SceneNode(
          id: 'end_refuse',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.refused'),
        ),
        SceneNode(
          id: 'end_completed',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'scene.completed'),
        ),
      ],
      edges: [
        _edge('start_dialogue', 'start', 'completed', 'dialogue'),
        _edge('dialogue_accept_merge', 'dialogue', 'accept',
            'merge_before_branch', SceneEdgeKind.dialogueOutcome),
        _edge('dialogue_refuse_merge', 'dialogue', 'refuse',
            'merge_before_branch', SceneEdgeKind.dialogueOutcome),
        _edge('dialogue_completed_merge', 'dialogue', 'completed',
            'merge_before_branch'),
        _edge('merge_branch', 'merge_before_branch', 'completed', 'branch'),
        _edge('branch_accept_action', 'branch', 'accept', 'accept_action',
            SceneEdgeKind.branchOutcome),
        _edge('branch_refuse_end', 'branch', 'refuse', 'end_refuse',
            SceneEdgeKind.branchOutcome),
        _edge('branch_completed_end', 'branch', 'completed', 'end_completed',
            SceneEdgeKind.branchOutcome),
        _edge('action_merge', 'accept_action', 'completed',
            'merge_after_action', SceneEdgeKind.actionCompleted),
        _edge('merge_end', 'merge_after_action', 'completed', 'end_accept'),
      ],
    ),
  );
}

SceneEdge _edge(
  String id,
  String from,
  String port,
  String to, [
  SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
]) {
  return SceneEdge(
    id: id,
    fromNodeId: from,
    fromPortId: port,
    toNodeId: to,
    kind: kind,
  );
}
