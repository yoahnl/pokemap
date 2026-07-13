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
