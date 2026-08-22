import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// An unprovable condition must not hide a real failure — BETA-CIN-087.
///
/// `_verdict` tested `indeterminate` before `fail`, so a scene with both an
/// unprovable condition and a path reaching no ending reported only the
/// indeterminacy. The diagnostics always listed both, which is why this hid for
/// so long: the export gate reads severities and saw the failure, while
/// anything reading the verdict — map_gameplay tells an indeterminate source
/// from a permanently blocked one that way — was told the wrong thing.
void main() {
  test('a path without exit outranks an unprovable condition', () {
    final report = solveNarrativeSceneSymbolically(_scene(danglingBranch: true));

    expect(
      report.issues.map((issue) => issue.code),
      containsAll(<NarrativeSymbolicIssueCode>[
        NarrativeSymbolicIssueCode.unsupportedCondition,
        NarrativeSymbolicIssueCode.pathWithoutExit,
      ]),
      reason: 'the scene really has both problems, which is the whole point',
    );
    expect(
      report.verdict,
      NarrativeSymbolicVerdict.fail,
      reason: 'the failure is the actionable one; the indeterminacy used to '
          'swallow it',
    );
  });

  test('an unprovable condition alone still reports indeterminate', () {
    final report =
        solveNarrativeSceneSymbolically(_scene(danglingBranch: false));

    expect(
      report.issues.map((issue) => issue.code),
      contains(NarrativeSymbolicIssueCode.unsupportedCondition),
    );
    expect(
      report.verdict,
      NarrativeSymbolicVerdict.indeterminate,
      reason: 'reordering must not turn an indeterminate scene into a passing '
          'one, nor into a failing one',
    );
  });
}

/// A scene branching on a condition the solver cannot decide — an inventory
/// check, which is declared in the enum but implemented nowhere, so the runtime
/// throws on it and the export refuses it.
///
/// With [danglingBranch] the false side reaches a merge that leads nowhere,
/// which is a genuine `pathWithoutExit`.
SceneAsset _scene({required bool danglingBranch}) => SceneAsset(
      id: 'scene_masking',
      name: 'Masquage de verdict',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'gate_node',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
              conditionSource: SceneConditionSource(
                sourceKind: SceneConditionSourceKind.inventoryItem,
                sourceId: 'potion',
                operator: SceneConditionOperator.isTrue,
              ),
            ),
          ),
          if (danglingBranch)
            SceneNode(id: 'dead_end', kind: SceneNodeKind.merge),
          SceneNode(
            id: 'end_true',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: 'went_true',
              outcomePolicy: SceneOutcomePolicy.progression,
            ),
          ),
          if (!danglingBranch)
            SceneNode(
              id: 'end_false',
              kind: SceneNodeKind.end,
              payload: SceneEndPayload(
                sceneOutcomeId: 'went_false',
                outcomePolicy: SceneOutcomePolicy.progression,
              ),
            ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'e_start',
            fromNodeId: 'start',
            toNodeId: 'gate_node',
            fromPortId: 'completed',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'e_true',
            fromNodeId: 'gate_node',
            toNodeId: 'end_true',
            fromPortId: 'true',
            kind: SceneEdgeKind.conditionTrue,
          ),
          SceneEdge(
            id: 'e_false',
            fromNodeId: 'gate_node',
            toNodeId: danglingBranch ? 'dead_end' : 'end_false',
            fromPortId: 'false',
            kind: SceneEdgeKind.conditionFalse,
          ),
        ],
      ),
    );
