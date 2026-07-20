import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('diagnoseStorylineSceneLinks', () {
    test('does not report a step with no scene links', () {
      final report = diagnoseStorylineSceneLinks(project: _project());

      expect(report.diagnostics, isEmpty);
    });

    test('accepts known scene links', () {
      final report = diagnoseStorylineSceneLinks(
        project: _projectWithStepLinks(['scene_intro']),
      );

      expect(report.diagnostics, isEmpty);
    });

    test('reports unknown scene links as errors', () {
      final project = _projectWithUnknownLink('missing_scene');

      final report = diagnoseStorylineSceneLinks(project: project);

      final diagnostic = report
          .byCode(
            StorylineSceneLinkDiagnosticCode.storylineStepUnknownSceneLink,
          )
          .single;
      expect(diagnostic.severity, StorylineSceneLinkDiagnosticSeverity.error);
      expect(diagnostic.sceneId, 'missing_scene');
      expect(report.hasErrors, isTrue);
    });

    test('warns when a linked scene has scene diagnostics errors', () {
      final report = diagnoseStorylineSceneLinks(
        project: _projectWithScenesAndLinks(
          scenes: [_invalidScene('scene_broken')],
          sceneLinkIds: const ['scene_broken'],
        ),
      );

      final diagnostic = report
          .byCode(
            StorylineSceneLinkDiagnosticCode.storylineStepLinkedSceneHasErrors,
          )
          .single;
      expect(diagnostic.severity, StorylineSceneLinkDiagnosticSeverity.warning);
      expect(report.hasErrors, isFalse);
    });

    test('warns when a linked scene cannot build a runtime plan', () {
      final report = diagnoseStorylineSceneLinks(
        project: _projectWithScenesAndLinks(
          scenes: [_notBuildableScene('scene_action')],
          sceneLinkIds: const ['scene_action'],
        ),
      );

      final diagnostic = report
          .byCode(
            StorylineSceneLinkDiagnosticCode
                .storylineStepLinkedSceneNotRuntimeBuildable,
          )
          .single;
      expect(diagnostic.severity, StorylineSceneLinkDiagnosticSeverity.warning);
      expect(diagnostic.sceneId, 'scene_action');
      expect(report.hasErrors, isFalse);
    });

    test('reports a structured link to an unknown Scenario', () {
      final report = diagnoseStorylineSceneLinks(
        project: _projectWithStructuredLink(
          scenarioId: 'missing_scenario',
        ),
      );

      final diagnostic = report
          .byCode(
            StorylineSceneLinkDiagnosticCode
                .storylineStructuredOutcomeUnknownScenario,
          )
          .single;
      expect(diagnostic.severity, StorylineSceneLinkDiagnosticSeverity.error);
      expect(diagnostic.sceneLinkId, 'link_intro');
      expect(diagnostic.sceneId, 'missing_scenario');
    });

    test('reports unknown declared outcomes and target Steps', () {
      final report = diagnoseStorylineSceneLinks(
        project: _projectWithStructuredLink(
          outcomeId: 'missing_outcome',
          effectTargetId: 'missing_step',
        ),
      );

      expect(
        report
            .byCode(
              StorylineSceneLinkDiagnosticCode
                  .storylineStructuredOutcomeUnknownOutcome,
            )
            .single
            .outcomeId,
        'missing_outcome',
      );
      expect(
        report
            .byCode(
              StorylineSceneLinkDiagnosticCode
                  .storylineStructuredOutcomeUnknownStepTarget,
            )
            .single
            .effectTargetId,
        'missing_step',
      );
      expect(report.hasErrors, isTrue);
    });

    test('warns about duplicate structured Step effects', () {
      final effect = StorylineEffect(
        type: StorylineEffectType.completeStep,
        targetId: 'step_intro',
      );
      final report = diagnoseStorylineSceneLinks(
        project: _projectWithStructuredLink(effects: [effect, effect]),
      );

      final diagnostic = report
          .byCode(
            StorylineSceneLinkDiagnosticCode
                .storylineStructuredOutcomeDuplicateStepEffect,
          )
          .single;
      expect(diagnostic.severity, StorylineSceneLinkDiagnosticSeverity.warning);
      expect(diagnostic.outcomeId, 'victory');
      expect(diagnostic.effectTargetId, 'step_intro');
    });
  });
}

ProjectManifest _project() {
  return _projectWithScenesAndLinks(
    scenes: [_validScene('scene_intro')],
    sceneLinkIds: const <String>[],
  );
}

ProjectManifest _projectWithStepLinks(List<String> sceneLinkIds) {
  return _projectWithScenesAndLinks(
    scenes: [_validScene('scene_intro')],
    sceneLinkIds: sceneLinkIds,
  );
}

ProjectManifest _projectWithUnknownLink(String sceneId) {
  return ProjectManifest(
    name: 'Story Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: [_validScene('scene_intro')],
    storylines: [
      _storyline(sceneLinkIds: [sceneId])
    ],
  );
}

ProjectManifest _projectWithScenesAndLinks({
  required List<SceneAsset> scenes,
  required List<String> sceneLinkIds,
}) {
  return ProjectManifest(
    name: 'Story Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: scenes,
    storylines: [_storyline(sceneLinkIds: sceneLinkIds)],
  );
}

ProjectManifest _projectWithStructuredLink({
  String scenarioId = 'scenario_intro',
  String outcomeId = 'victory',
  String effectTargetId = 'step_intro',
  List<StorylineEffect>? effects,
}) {
  return ProjectManifest(
    name: 'Story Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: [
      ScenarioAsset(
        id: 'scenario_intro',
        name: 'Intro',
        entryNodeId: 'start',
        declaredOutcomes: const ['victory'],
      ),
    ],
    storylines: [
      StorylineAsset(
        id: 'story_main',
        type: StorylineType.main,
        title: 'Main story',
        chapters: [
          StorylineChapter(
            id: 'chapter_intro',
            title: 'Intro',
            order: 0,
            steps: [
              StorylineStep(
                id: 'step_intro',
                title: 'Intro',
                order: 0,
              ),
            ],
          ),
        ],
        sceneLinks: [
          StorylineSceneLink(
            id: 'link_intro',
            chapterId: 'chapter_intro',
            stepId: 'step_intro',
            label: 'Intro',
            state: StorylineSceneLinkState.linkedScenario,
            role: StorylineSceneLinkRole.primary,
            sceneRef: StorylineSceneRef(
              kind: StorylineSceneRefKind.scenario,
              targetId: scenarioId,
            ),
            order: 0,
            outcomeLinks: [
              StorylineSceneOutcomeLink(
                id: 'outcome_intro',
                outcomeId: outcomeId,
                effects: effects ??
                    [
                      StorylineEffect(
                        type: StorylineEffectType.completeStep,
                        targetId: effectTargetId,
                      ),
                    ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

StorylineAsset _storyline({required List<String> sceneLinkIds}) {
  return StorylineAsset(
    id: 'story_main',
    type: StorylineType.main,
    title: 'Main story',
    chapters: [
      StorylineChapter(
        id: 'chapter_intro',
        title: 'Intro',
        order: 0,
        steps: [
          StorylineStep(
            id: 'step_intro',
            title: 'Intro',
            order: 0,
            sceneLinkIds: sceneLinkIds,
          ),
        ],
      ),
    ],
  );
}

SceneAsset _validScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Intro Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_end',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

SceneAsset _invalidScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Broken Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [SceneNode(id: 'node_start', kind: SceneNodeKind.start)],
    ),
  );
}

SceneAsset _notBuildableScene(String id) {
  return SceneAsset(
    id: id,
    name: 'Action Scene',
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'node_action',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(actionKind: 'legacy'),
        ),
        SceneNode(id: 'node_end', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start_action',
          fromNodeId: 'node_start',
          fromPortId: 'completed',
          toNodeId: 'node_action',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_action_end',
          fromNodeId: 'node_action',
          fromPortId: 'completed',
          toNodeId: 'node_end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}
