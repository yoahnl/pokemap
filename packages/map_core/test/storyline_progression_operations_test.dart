import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Storyline progression inverse operations', () {
    test('connects and disconnects an outcome effect', () {
      final project = _project();
      final connected = connectStorylineProgressionEdge(
        project,
        StorylineProgressionConnectRequest.outcomeEffect(
          storylineId: 'story_main',
          sceneLinkId: 'link_intro',
          outcomeLinkId: 'outcome_win',
          effectType: StorylineEffectType.completeStep,
          targetStepId: 'step_resolution',
        ),
      );
      final edge = buildStorylineProgressionProjection(
        project: connected.after,
        storylineId: 'story_main',
      ).edgesOfKind(StorylineProgressionEdgeKind.outcomeCompletesStep).single;
      final disconnected = disconnectStorylineProgressionEdge(
        connected.after,
        storylineId: 'story_main',
        edgeId: edge.id,
      );

      expect(connected.disposition,
          StorylineProgressionMutationDisposition.applied);
      expect(disconnected.disposition,
          StorylineProgressionMutationDisposition.applied);
      expect(disconnected.after, project);
    });

    test('rejects duplicate and missing outcome destinations atomically', () {
      final project = _project(withOutcomeEffect: true);
      final duplicate = connectStorylineProgressionEdge(
        project,
        StorylineProgressionConnectRequest.outcomeEffect(
          storylineId: 'story_main',
          sceneLinkId: 'link_intro',
          outcomeLinkId: 'outcome_win',
          effectType: StorylineEffectType.completeStep,
          targetStepId: 'step_resolution',
        ),
      );
      final missing = connectStorylineProgressionEdge(
        project,
        StorylineProgressionConnectRequest.outcomeEffect(
          storylineId: 'story_main',
          sceneLinkId: 'link_intro',
          outcomeLinkId: 'outcome_win',
          effectType: StorylineEffectType.activateStep,
          targetStepId: 'missing_step',
        ),
      );

      expect(duplicate.code, 'duplicateOutcomeEffect');
      expect(missing.code, 'destinationNotFound');
      expect(duplicate.after, same(project));
      expect(missing.after, same(project));
    });

    test('connects and disconnects requires without parallel edge data', () {
      final project = _project();
      final connected = connectStorylineProgressionEdge(
        project,
        StorylineProgressionConnectRequest.relationship(
          relationshipId: 'rel_side_requires_main',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'story_side',
          targetStorylineId: 'story_main',
        ),
      );
      final projection = buildStorylineProgressionProjection(
        project: connected.after,
        storylineId: 'story_main',
      );
      final edge =
          projection.edgesOfKind(StorylineProgressionEdgeKind.requires).single;
      final disconnected = disconnectStorylineProgressionEdge(
        connected.after,
        storylineId: 'story_main',
        edgeId: edge.id,
      );

      expect(
        connected.after.storylines
            .singleWhere((storyline) => storyline.id == 'story_side')
            .relationships
            .single
            .id,
        'rel_side_requires_main',
      );
      expect(disconnected.after, project);
    });

    test('forbids relationship and outcome cycles', () {
      final relationshipCycle = connectStorylineProgressionEdge(
        _project(withReverseRelationship: true),
        StorylineProgressionConnectRequest.relationship(
          relationshipId: 'rel_side_main',
          kind: StorylineRelationshipKind.requires,
          sourceStorylineId: 'story_side',
          targetStorylineId: 'story_main',
        ),
      );
      final outcomeCycle = connectStorylineProgressionEdge(
        _project(withReverseOutcomeEffect: true),
        StorylineProgressionConnectRequest.outcomeEffect(
          storylineId: 'story_main',
          sceneLinkId: 'link_intro',
          outcomeLinkId: 'outcome_win',
          effectType: StorylineEffectType.activateStep,
          targetStepId: 'step_resolution',
        ),
      );

      expect(relationshipCycle.code, 'cycleDetected');
      expect(outcomeCycle.code, 'cycleDetected');
    });

    test('sets and clears a simple Fact condition', () {
      final project = _project();
      final connected = connectStorylineProgressionEdge(
        project,
        StorylineProgressionConnectRequest.factCondition(
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'step_intro',
          slot: StorylineProgressionConditionSlot.entry,
          factId: 'fact_port_open',
          expectedValue: true,
        ),
      );
      final edge = buildStorylineProgressionProjection(
        project: connected.after,
        storylineId: 'story_main',
      ).edgesOfKind(StorylineProgressionEdgeKind.entryCondition).single;
      final cleared = disconnectStorylineProgressionEdge(
        connected.after,
        storylineId: 'story_main',
        edgeId: edge.id,
      );

      expect(connected.disposition,
          StorylineProgressionMutationDisposition.applied);
      expect(cleared.after, project);
    });

    test('refuses replacing an occupied advanced condition', () {
      final project = _project(withAdvancedCondition: true);

      final result = connectStorylineProgressionEdge(
        project,
        StorylineProgressionConnectRequest.factCondition(
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'step_intro',
          slot: StorylineProgressionConditionSlot.completion,
          factId: 'fact_port_open',
          expectedValue: false,
        ),
      );

      expect(result.code, 'conditionSlotOccupied');
      expect(result.after, same(project));
    });

    test('refuses disconnecting derived order and preserves JSON round-trip',
        () {
      final project = _project();
      final orderEdge = buildStorylineProgressionProjection(
        project: project,
        storylineId: 'story_main',
      ).edgesOfKind(StorylineProgressionEdgeKind.authorOrder).first;

      final rejected = disconnectStorylineProgressionEdge(
        project,
        storylineId: 'story_main',
        edgeId: orderEdge.id,
      );
      final decoded = ProjectManifest.fromJson(project.toJson());

      expect(rejected.code, 'edgeReadOnly');
      expect(rejected.after, same(project));
      expect(decoded, project);
    });
  });
}

ProjectManifest _project({
  bool withOutcomeEffect = false,
  bool withReverseOutcomeEffect = false,
  bool withReverseRelationship = false,
  bool withAdvancedCondition = false,
}) {
  final links = <StorylineSceneLink>[
    _link(
      id: 'link_intro',
      chapterId: 'chapter_intro',
      stepId: 'step_intro',
      outcomeId: 'outcome_win',
      effects: withOutcomeEffect
          ? [
              StorylineEffect(
                type: StorylineEffectType.completeStep,
                targetId: 'step_resolution',
              ),
            ]
          : const [],
    ),
    if (withReverseOutcomeEffect)
      _link(
        id: 'link_resolution',
        chapterId: 'chapter_resolution',
        stepId: 'step_resolution',
        outcomeId: 'outcome_back',
        effects: [
          StorylineEffect(
            type: StorylineEffectType.activateStep,
            targetId: 'step_intro',
          ),
        ],
      ),
  ];
  final main = StorylineAsset(
    id: 'story_main',
    type: StorylineType.main,
    title: 'Main',
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
            completionCondition: withAdvancedCondition
                ? ScriptConditionFactory.allOf(<ScriptCondition>[
                    ScriptConditionFactory.flagIsSet('fact_port_open'),
                    ScriptConditionFactory.flagIsUnset('fact_rival_waiting'),
                  ])
                : null,
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
    sceneLinks: links,
    relationships: withReverseRelationship
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
  return ProjectManifest(
    name: 'Story project',
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
    facts: [
      NarrativeFactDefinition(
        id: 'fact_port_open',
        label: 'Port open',
      ),
      NarrativeFactDefinition(
        id: 'fact_rival_waiting',
        label: 'Rival waiting',
      ),
    ],
    storylines: [
      main,
      StorylineAsset(
        id: 'story_side',
        type: StorylineType.sideQuest,
        title: 'Side',
      ),
    ],
  );
}

StorylineSceneLink _link({
  required String id,
  required String chapterId,
  required String stepId,
  required String outcomeId,
  required List<StorylineEffect> effects,
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
        effects: effects.isEmpty
            ? [
                StorylineEffect(
                  type: StorylineEffectType.emitFact,
                  targetId: 'fact_port_open',
                ),
              ]
            : effects,
      ),
    ],
  );
}
