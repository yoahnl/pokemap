import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'lists chapters and milestones in order with scenes, maps and facts',
    () {
      final outline = projectStorylineOutline(_project());
      final storyline = outline.storylines.single;

      expect(storyline.chapters.map((chapter) => chapter.id), [
        'act_1',
        'act_2',
      ]);
      final milestones = storyline.chapters.first.milestones;
      expect(milestones.map((milestone) => milestone.id), [
        'arrive',
        'rival',
        'rematch',
      ]);
      final arrive = milestones.first;
      expect(arrive.sceneIds, ['scene_arrive']);
      expect(arrive.mapIds, ['map_route', 'map_town']);
      expect(arrive.completionFactId, 'fact_arrive');
      expect(arrive.issues, isEmpty);
      expect(storyline.chapters.last.status, StorylineStatus.archived);
    },
  );

  test('reports each milestone diagnostic', () {
    final milestones = {
      for (final chapter in projectStorylineOutline(
        _project(),
      ).storylines.single.chapters)
        for (final milestone in chapter.milestones) milestone.id: milestone,
    };

    expect(milestones['rival']!.issues, {
      StorylineMilestoneIssue.completionFactShared,
      StorylineMilestoneIssue.completionFactCanReset,
    });
    expect(milestones['rematch']!.issues, {
      StorylineMilestoneIssue.noBehaviour,
      StorylineMilestoneIssue.completionFactShared,
      StorylineMilestoneIssue.completionFactCanReset,
    });
    expect(milestones['epilogue']!.issues, {
      StorylineMilestoneIssue.noBehaviour,
      StorylineMilestoneIssue.noCompletionFact,
    });
  });

  test('scenes attached to no milestone are outside the storyline', () {
    final fromProject = projectStorylineOutline(_project());
    final fromTitles = projectStorylineOutline(
      _project(),
      scenes: const [
        (id: 'scene_loose', title: 'Loose'),
        (id: 'scene_arrive', title: 'Arrive'),
        (id: 'scene_untitled', title: 'Undecoded'),
      ],
    );

    expect(fromProject.scenesOutsideStorylines, [
      (id: 'scene_loose', title: 'scene_loose'),
    ]);
    expect(fromTitles.scenesOutsideStorylines.map((scene) => scene.id), [
      'scene_loose',
      'scene_untitled',
    ]);
  });
}

ProjectManifest _project() {
  ScriptCondition done(String factId) => ScriptConditionFactory.factEquals(
    factId,
    const NarrativeValue.boolean(true),
  );
  SceneAsset scene(String id, [List<SceneNode> extra = const []]) => SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        ...extra,
      ],
      edges: const [],
    ),
  );
  NarrativeEventRecord event(String id, String mapId, String sceneId) =>
      NarrativeEventRecord.configuredStructurallyUnchecked(
        enabled: true,
        NarrativeEventDefinition(
          id: id,
          name: id,
          source: NarrativeEventSourceRef.mapEnter(mapId),
          conditions: const [],
          sceneId: sceneId,
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: 0,
          order: 0,
        ),
      );
  return ProjectManifest(
    name: 'Outline',
    maps: const [],
    tilesets: const [],
    scenes: [
      scene('scene_arrive'),
      scene('scene_rival', [
        SceneNode(
          id: 'reset',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload(
            consequence: SceneSetFactConsequence(
              factId: 'fact_rival',
              value: false,
            ),
          ),
        ),
      ]),
      scene('scene_loose'),
    ],
    facts: [
      NarrativeFactDefinition(id: 'fact_arrive', label: 'Arrive'),
      NarrativeFactDefinition(id: 'fact_rival', label: 'Rival'),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        event(
          'evt_019abcde-0000-7000-8000-000000000001',
          'map_town',
          'scene_arrive',
        ),
        event(
          'evt_019abcde-0000-7000-8000-000000000002',
          'map_route',
          'scene_arrive',
        ),
      ],
      legacyClaims: const [],
    ),
    storylines: [
      StorylineAsset(
        id: 'main',
        type: StorylineType.main,
        title: 'Main',
        chapters: [
          StorylineChapter(
            id: 'act_2',
            title: 'Act 2',
            order: 1,
            status: StorylineStatus.archived,
            steps: [StorylineStep(id: 'epilogue', title: 'Epilogue', order: 0)],
          ),
          StorylineChapter(
            id: 'act_1',
            title: 'Act 1',
            order: 0,
            steps: [
              StorylineStep(
                id: 'rematch',
                title: 'Rematch',
                order: 2,
                completionCondition: done('fact_rival'),
              ),
              StorylineStep(
                id: 'rival',
                title: 'Rival',
                order: 1,
                sceneLinkIds: const ['scene_rival'],
                completionCondition: done('fact_rival'),
              ),
              StorylineStep(
                id: 'arrive',
                title: 'Arrive',
                order: 0,
                sceneLinkIds: const ['scene_arrive'],
                completionCondition: done('fact_arrive'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
