import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NS-EVENT-V2 Phase D D2 Scene outcome diagnostics', () {
    test('distinguishes a declared unused outcome from an undeclared emission',
        () {
      final scene = _scene(
        declaredOutcomes: [
          SceneOutcome(id: 'declared_only', label: 'Déclaré seulement'),
        ],
        endOutcomeId: 'emitted_only',
      );

      final report = diagnoseScene(scene);

      expect(
        report
            .byCode(SceneDiagnosticCode.declaredOutcomeUnused)
            .single
            .outcomeId,
        'declared_only',
      );
      expect(
        report
            .byCode(SceneDiagnosticCode.endOutcomeUndeclared)
            .single
            .outcomeId,
        'emitted_only',
      );
      expect(
        report.byCode(SceneDiagnosticCode.endOutcomeUndeclared).single.severity,
        SceneDiagnosticSeverity.error,
      );
    });

    test('keeps a declared reachable end outcome free of mismatch diagnostics',
        () {
      final scene = _scene(
        declaredOutcomes: [
          SceneOutcome(id: 'completed', label: 'Terminé'),
        ],
        endOutcomeId: 'completed',
      );

      final report = diagnoseScene(scene);

      expect(
        report.byCode(SceneDiagnosticCode.declaredOutcomeUnused),
        isEmpty,
      );
      expect(
        report.byCode(SceneDiagnosticCode.endOutcomeUndeclared),
        isEmpty,
      );
    });

    test('blocks a Scene port orphaned by a dialogue outcome removal', () {
      final project = ProjectManifest(
        name: 'Outcome diagnostic',
        maps: const [],
        tilesets: const [],
        dialogues: const [
          ProjectDialogueEntry(
            id: 'dialogue_intro',
            name: 'Introduction',
            relativePath: 'dialogues/intro.yarn',
            declaredOutcomes: [
              DialogueDeclaredOutcome(id: 'refused', label: 'Refuser'),
            ],
          ),
        ],
      );
      final scene = SceneAsset(
        id: 'scene_dialogue',
        name: 'Dialogue',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'dialogue',
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(
                dialogueId: 'dialogue_intro',
                expectedOutcomes: const ['accepted'],
              ),
            ),
          ],
          edges: [
            SceneEdge(
              id: 'start_dialogue',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'dialogue',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );

      final report = diagnoseSceneAgainstProject(scene, project);

      expect(
        report
            .byCode(SceneDiagnosticCode.dialogueExpectedOutcomeUnknown)
            .single
            .outcomeId,
        'accepted',
      );
      expect(
        report
            .byCode(SceneDiagnosticCode.dialogueExpectedOutcomeUnknown)
            .single
            .severity,
        SceneDiagnosticSeverity.error,
      );
    });
  });
}

SceneAsset _scene({
  required List<SceneOutcome> declaredOutcomes,
  required String endOutcomeId,
}) {
  return SceneAsset(
    id: 'scene_outcome_diagnostic',
    name: 'Diagnostic outcome',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: endOutcomeId),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    declaredOutcomes: declaredOutcomes,
  );
}
