import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StorylineProgressionProjection', () {
    test('derives ownership and author order without serialized graph data',
        () {
      final projection = buildStorylineProgressionProjection(
        project: _project(),
        storylineId: 'story_main',
      );

      expect(projection.storylineId, 'story_main');
      expect(
        projection.edgesOfKind(StorylineProgressionEdgeKind.contains),
        hasLength(4),
      );
      expect(
        projection.edgesOfKind(StorylineProgressionEdgeKind.authorOrder),
        hasLength(1),
      );
      expect(
        projection.edgesOfKind(StorylineProgressionEdgeKind.authorOrder),
        everyElement(
          isA<StorylineProgressionEdge>().having(
            (edge) => edge.editability,
            'editability',
            StorylineProgressionEdgeEditability.readOnly,
          ),
        ),
      );
      expect(
        projection.nodes.map((node) => node.id),
        containsAll(<String>[
          'storyline:story_main',
          'chapter:chapter_intro',
          'step:step_intro',
        ]),
      );
    });

    test('projects outcome effects from their exact canonical source', () {
      final projection = buildStorylineProgressionProjection(
        project: _project(withOutcomeLink: true),
        storylineId: 'story_main',
      );

      final edge = projection
          .edgesOfKind(
            StorylineProgressionEdgeKind.outcomeCompletesStep,
          )
          .single;
      expect(edge.fromNodeId, 'outcome:story_main:link_intro:outcome_win');
      expect(edge.toNodeId, 'step:step_resolution');
      expect(edge.source.kind, StorylineProgressionSourceKind.outcomeEffect);
      expect(edge.source.sceneLinkId, 'link_intro');
      expect(edge.source.outcomeLinkId, 'outcome_win');
      expect(
        edge.editability,
        StorylineProgressionEdgeEditability.reversible,
      );
    });

    test('projects reversible and descriptive relationships explicitly', () {
      final projection = buildStorylineProgressionProjection(
        project: _project(withRelationships: true),
        storylineId: 'story_main',
      );

      final requires =
          projection.edgesOfKind(StorylineProgressionEdgeKind.requires).single;
      expect(requires.fromNodeId, 'storyline:story_side');
      expect(requires.toNodeId, 'storyline:story_main');
      expect(
        requires.editability,
        StorylineProgressionEdgeEditability.reversible,
      );

      final attachment = projection
          .edgesOfKind(
            StorylineProgressionEdgeKind.sideQuestAvailability,
          )
          .single;
      expect(
        attachment.editability,
        StorylineProgressionEdgeEditability.readOnly,
      );
      expect(attachment.readOnlyReason, isNotEmpty);
    });

    test('maps simple Fact conditions and preserves advanced conditions', () {
      final projection = buildStorylineProgressionProjection(
        project: _project(withConditions: true),
        storylineId: 'story_main',
      );

      final entry = projection
          .edgesOfKind(StorylineProgressionEdgeKind.entryCondition)
          .single;
      expect(entry.fromNodeId, 'fact:fact_port_open');
      expect(entry.toNodeId, 'step:step_intro');
      expect(
        entry.editability,
        StorylineProgressionEdgeEditability.reversible,
      );

      final completion = projection
          .edgesOfKind(StorylineProgressionEdgeKind.completionCondition)
          .single;
      expect(completion.fromNodeId, contains('condition:'));
      expect(
        completion.editability,
        StorylineProgressionEdgeEditability.readOnly,
      );
      expect(completion.readOnlyReason, contains('non ambigu'));
    });

    test('surfaces missing destinations and existing cycles', () {
      final projection = buildStorylineProgressionProjection(
        project: _project(withBrokenCycle: true),
        storylineId: 'story_main',
      );

      expect(
        projection.diagnostics.where((diagnostic) =>
            diagnostic.code ==
            StorylineProgressionDiagnosticCode.missingDestination),
        isNotEmpty,
      );
      expect(
        projection.diagnostics.where((diagnostic) =>
            diagnostic.code ==
            StorylineProgressionDiagnosticCode.cycleDetected),
        isNotEmpty,
      );
      expect(
        projection.nodes
            .singleWhere((node) => node.id == 'step:missing_step')
            .isMissing,
        isTrue,
      );
    });
  });
}

ProjectManifest _project({
  bool withOutcomeLink = false,
  bool withRelationships = false,
  bool withConditions = false,
  bool withBrokenCycle = false,
}) {
  final completionCondition = withConditions
      ? ScriptConditionFactory.allOf(<ScriptCondition>[
          ScriptConditionFactory.flagIsSet('fact_intro_complete'),
          ScriptConditionFactory.flagIsUnset('fact_rival_waiting'),
        ])
      : null;
  final main = StorylineAsset(
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
            entryCondition: withConditions
                ? ScriptConditionFactory.flagIsSet('fact_port_open')
                : null,
            completionCondition: completionCondition,
          ),
        ],
      ),
      StorylineChapter(
        id: 'chapter_resolution',
        title: 'Resolution',
        order: 1,
        steps: [
          StorylineStep(
            id: 'step_resolution',
            title: 'Resolution',
            order: 0,
          ),
        ],
      ),
    ],
    sceneLinks: withOutcomeLink || withBrokenCycle
        ? [
            _sceneLink(
              id: 'link_intro',
              stepId: 'step_intro',
              outcomeId: 'outcome_win',
              effect: StorylineEffect(
                type: StorylineEffectType.completeStep,
                targetId: withBrokenCycle ? 'missing_step' : 'step_resolution',
              ),
            ),
            if (withBrokenCycle)
              _sceneLink(
                id: 'link_resolution',
                chapterId: 'chapter_resolution',
                stepId: 'step_resolution',
                outcomeId: 'outcome_back',
                effect: StorylineEffect(
                  type: StorylineEffectType.activateStep,
                  targetId: 'step_intro',
                ),
              ),
          ]
        : const [],
    relationships: withBrokenCycle
        ? [
            StorylineRelationship(
              id: 'rel_main_side',
              kind: StorylineRelationshipKind.requires,
              sourceStorylineId: 'story_main',
              targetStorylineId: 'story_side',
            ),
          ]
        : const [],
  );
  final side = StorylineAsset(
    id: 'story_side',
    type: StorylineType.sideQuest,
    title: 'Side quest',
    relationships: [
      if (withRelationships)
        StorylineRelationship(
          id: 'rel_requires',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'story_side',
          targetStorylineId: 'story_main',
        ),
      if (withRelationships)
        StorylineRelationship(
          id: 'rel_available',
          kind: StorylineRelationshipKind.sideQuestAvailableDuring,
          sourceStorylineId: 'story_side',
          targetStorylineId: 'story_main',
          anchor: StorylineAnchor(
            kind: StorylineAnchorKind.chapter,
            targetId: 'chapter_intro',
          ),
        ),
      if (withBrokenCycle)
        StorylineRelationship(
          id: 'rel_side_main',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'story_side',
          targetStorylineId: 'story_main',
        ),
    ],
  );
  return ProjectManifest(
    name: 'Story Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: [
      ScenarioAsset(
        id: 'scenario_intro',
        name: 'Intro',
        entryNodeId: 'start',
        declaredOutcomes: const ['victory', 'return'],
      ),
    ],
    facts: withConditions
        ? [
            NarrativeFactDefinition(
              id: 'fact_port_open',
              label: 'Port open',
            ),
            NarrativeFactDefinition(
              id: 'fact_intro_complete',
              label: 'Intro complete',
            ),
            NarrativeFactDefinition(
              id: 'fact_rival_waiting',
              label: 'Rival waiting',
            ),
          ]
        : const [],
    storylines: [main, side],
  );
}

StorylineSceneLink _sceneLink({
  required String id,
  String chapterId = 'chapter_intro',
  required String stepId,
  required String outcomeId,
  required StorylineEffect effect,
}) {
  return StorylineSceneLink(
    id: id,
    chapterId: chapterId,
    stepId: stepId,
    label: id,
    state: StorylineSceneLinkState.linkedScenario,
    role: StorylineSceneLinkRole.primary,
    sceneRef: StorylineSceneRef(
      kind: StorylineSceneRefKind.scenario,
      targetId: 'scenario_intro',
    ),
    order: 0,
    outcomeLinks: [
      StorylineSceneOutcomeLink(
        id: outcomeId,
        outcomeId: outcomeId == 'outcome_win' ? 'victory' : 'return',
        effects: [effect],
      ),
    ],
  );
}
