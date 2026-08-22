import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// A pre-session draft guard is analysable — BETA-CIN-083 follow-up.
///
/// `scene.preSession.condition.insert` is a canonical action, but the project
/// it produced was understood by no analysis layer: the symbolic solver
/// returned no value for a `newGameDraft` condition and reported it as
/// unprovable, while the dependency index reported its sourceId as a legacy
/// external reference at error severity. Between the two, the export refused
/// the package outright, so an author using the guard the Studio offers got a
/// game that could not ship and a diagnostic they could not act on.
///
/// Both were wrong for the same underlying reason: a draft field is not a
/// project resource to resolve, and whether it is assigned is written in the
/// graph. An upstream interaction that binds it assigns it; nothing else can.
void main() {
  group('the solver proves a draft guard from the graph', () {
    test('a field assigned upstream makes the guard true', () {
      final report = solveNarrativeSceneSymbolically(
        _preSessionScene(assignsPlayerName: true),
      );

      expect(
        report.issues.where(
          (issue) => issue.code == NarrativeSymbolicIssueCode.unsupportedCondition,
        ),
        isEmpty,
        reason: 'the assignment is visible in the graph, so the guard is not '
            'unprovable',
      );
      expect(
        report.terminalStates.any((state) => state.indeterminate),
        isFalse,
        reason: 'no path is left indeterminate by the draft condition',
      );
      expect(
        report.terminalStates
            .expand((state) => state.emittedOutcomeKeys)
            .map((key) => key.split('\u001f').last),
        contains('ready'),
        reason: 'the true branch is the one reached',
      );
    });

    test('a field nothing assigns makes the guard false, not unprovable', () {
      final report = solveNarrativeSceneSymbolically(
        _preSessionScene(assignsPlayerName: false),
      );

      expect(
        report.issues.where(
          (issue) => issue.code == NarrativeSymbolicIssueCode.unsupportedCondition,
        ),
        isEmpty,
        reason: 'an unassigned field is a determined false, not a mystery',
      );
      expect(
        report.terminalStates
            .expand((state) => state.emittedOutcomeKeys)
            .map((key) => key.split('\u001f').last),
        contains('missing_name'),
        reason: 'the false branch is the one reached, which is exactly what '
            'the guard exists to catch',
      );
    });

    test('the assignment is recorded on the state it happened in', () {
      final report = solveNarrativeSceneSymbolically(
        _preSessionScene(assignsPlayerName: true),
      );

      expect(
        report.terminalStates.every(
          (state) => state.assignedDraftFields.contains('playerName'),
        ),
        isTrue,
      );
      expect(
        report.terminalStates.first.semanticKey,
        contains('playerName'),
        reason: 'two paths differing only by which draft fields are assigned '
            'are different states, or the solver would merge them',
      );
    });
  });

  group('a draft field is not a reference to resolve', () {
    test('the dependency index reports no diagnostic for a draft guard', () {
      final scene = _preSessionScene(assignsPlayerName: true);
      final index = buildNarrativeDependencyIndex(
        project: _project(scene),
      );

      expect(
        index.usages.where(
          (usage) => usage.path.contains('conditionSource'),
        ),
        isEmpty,
        reason: 'a closed-enum draft field has nothing to resolve, so emitting '
            'a dependency for it can only ever produce a false diagnostic',
      );
    });
  });
}

ProjectManifest _project(SceneAsset scene) => ProjectManifest(
      name: 'Draft guard',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      scenes: <SceneAsset>[scene],
    );

/// A minimal pre-session: optionally an interaction binding `playerName`, then
/// a guard on that field with both branches ending on distinct outcomes.
SceneAsset _preSessionScene({required bool assignsPlayerName}) => SceneAsset(
      id: 'presession_draft_guard',
      name: 'Garde de brouillon',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          if (assignsPlayerName)
            SceneNode(
              id: 'ask_name',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(
                preSessionInteraction: ScenePreSessionInteractionSpec.text(
                  prompt: SceneInteractionPrompt(
                    localizationKey: 'draft.playerName.prompt',
                  ),
                  resultBinding: const ScenePreSessionResultBinding(
                    field: ScenePreSessionDraftField.playerName,
                  ),
                ),
              ),
            ),
          SceneNode(
            id: 'has_name',
            kind: SceneNodeKind.condition,
            payload: SceneConditionPayload(
              conditionSource: SceneConditionSource(
                sourceKind: SceneConditionSourceKind.newGameDraft,
                sourceId: 'playerName',
                operator: SceneConditionOperator.isTrue,
              ),
            ),
          ),
          SceneNode(
            id: 'end_ready',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: 'ready',
              outcomePolicy: SceneOutcomePolicy.progression,
            ),
          ),
          SceneNode(
            id: 'end_missing_name',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(
              sceneOutcomeId: 'missing_name',
              outcomePolicy: SceneOutcomePolicy.progression,
            ),
          ),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'e_start',
            fromNodeId: 'start',
            toNodeId: assignsPlayerName ? 'ask_name' : 'has_name',
            fromPortId: 'completed',
            kind: SceneEdgeKind.defaultFlow,
          ),
          if (assignsPlayerName)
            SceneEdge(
              id: 'e_ask',
              fromNodeId: 'ask_name',
              toNodeId: 'has_name',
              fromPortId: 'completed',
              kind: SceneEdgeKind.defaultFlow,
            ),
          SceneEdge(
            id: 'e_true',
            fromNodeId: 'has_name',
            toNodeId: 'end_ready',
            fromPortId: 'true',
            kind: SceneEdgeKind.conditionTrue,
          ),
          SceneEdge(
            id: 'e_false',
            fromNodeId: 'has_name',
            toNodeId: 'end_missing_name',
            fromPortId: 'false',
            kind: SceneEdgeKind.conditionFalse,
          ),
        ],
      ),
    );
