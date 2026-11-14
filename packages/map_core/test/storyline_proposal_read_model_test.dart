import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'orders milestones by what unlocks what and groups them by category',
    () {
      final proposal = proposeStoryline(_project());
      final storyline = proposal.storyline!;

      expect(storyline.type, StorylineType.main);
      expect(storyline.title, 'Proposal');
      expect(
        [
          for (final chapter in storyline.chapters)
            (chapter.title, chapter.steps.map((step) => step.id).join(',')),
        ],
        [
          ('Act 1', 'proposed_fact_met,proposed_fact_badge'),
          ('Rescue', 'proposed_fact_rescue'),
        ],
      );
      final rescue = storyline.chapters.last.steps.single;
      expect(rescue.sceneLinkIds, ['scene_rescue']);
      expect(storylineMilestoneCompletionFactId(rescue), 'fact_rescue');
      expect(proposal.milestoneCount, 3);
      expect(proposal.unlockCount, 2);
      expect(proposal.scenesOutsideStoryline, [
        'scene_done',
        'scene_reset',
        'scene_loose',
      ]);
    },
  );

  test('a scene goes to the first milestone it completes', () {
    final project = _project();
    final rescueAlsoMeets = project.copyWith(
      scenes: [
        for (final scene in project.scenes)
          if (scene.id == 'scene_met')
            _scene('scene_met', setTrue: 'fact_rescue')
          else
            scene,
      ],
    );
    final steps = proposeStoryline(
      rescueAlsoMeets,
    ).storyline!.chapters.expand((chapter) => chapter.steps).toList();

    expect(steps.map((step) => (step.id, step.sceneLinkIds.join(','))), [
      ('proposed_fact_badge', 'scene_badge'),
      ('proposed_fact_rescue', 'scene_rescue,scene_met'),
    ]);
  });

  test('without any fact written by a behaviour there is no draft', () {
    final proposal = proposeStoryline(
      ProjectManifest(
        name: 'Empty',
        maps: const [],
        tilesets: const [],
        scenes: [_scene('scene_loose')],
      ),
    );

    expect(proposal.storyline, isNull);
    expect(proposal.milestoneCount, 0);
    expect(proposal.scenesOutsideStoryline, ['scene_loose']);
  });
}

SceneAsset _scene(String id, {String? setTrue, String? setFalse}) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      for (final (factId, value) in [(setTrue, true), (setFalse, false)])
        if (factId != null)
          SceneNode(
            id: 'set_$value',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload(
              consequence: SceneSetFactConsequence(
                factId: factId,
                value: value,
              ),
            ),
          ),
    ],
    edges: const [],
  ),
);

NarrativeEventRecord _event(int index, String sceneId, [String? requires]) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      enabled: true,
      NarrativeEventDefinition(
        id: 'evt_019abcde-0000-7000-8000-00000000000$index',
        name: 'Event $index',
        source: NarrativeEventSourceRef.mapEnter('map_$index'),
        conditions: [
          if (requires != null) NarrativeEventCondition.fact(requires, true),
        ],
        sceneId: sceneId,
        reusePolicy: NarrativeEventReusePolicy.reusable,
        priority: 0,
        order: index,
      ),
    );

ProjectManifest _project() => ProjectManifest(
  name: 'Proposal',
  maps: const [],
  tilesets: const [],
  facts: [
    NarrativeFactDefinition(id: 'fact_rescue', label: 'Rescue'),
    NarrativeFactDefinition(
      id: 'fact_badge',
      label: 'Badge',
      category: 'Act 1',
    ),
    NarrativeFactDefinition(id: 'fact_met', label: 'Met', category: 'Act 1'),
    NarrativeFactDefinition(id: 'fact_done', label: 'Done'),
    NarrativeFactDefinition(id: 'fact_unused', label: 'Unused'),
    NarrativeFactDefinition(
      id: 'fact_score',
      label: 'Score',
      initialValue: NarrativeValue.integer(0),
    ),
  ],
  scenes: [
    _scene('scene_done', setTrue: 'fact_done'),
    _scene('scene_rescue', setTrue: 'fact_rescue'),
    _scene('scene_badge', setTrue: 'fact_badge'),
    _scene('scene_met', setTrue: 'fact_met'),
    _scene('scene_reset', setFalse: 'fact_badge'),
    _scene('scene_loose'),
  ],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: [
      _event(1, 'scene_met'),
      _event(2, 'scene_badge', 'fact_met'),
      _event(3, 'scene_rescue', 'fact_badge'),
      _event(4, 'scene_reset', 'fact_rescue'),
    ],
    legacyClaims: const [],
  ),
  storylines: [
    StorylineAsset(
      id: 'existing',
      type: StorylineType.sideQuest,
      title: 'Existing',
      chapters: [
        StorylineChapter(
          id: 'existing_chapter',
          title: 'C',
          order: 0,
          steps: [
            StorylineStep(
              id: 'existing_step',
              title: 'Done',
              order: 0,
              completionCondition: ScriptConditionFactory.factEquals(
                'fact_done',
                const NarrativeValue.boolean(true),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
