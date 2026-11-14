import 'package:map_core/map_core.dart';

import 'narrative_title_fixture.dart';

StorylineAsset trameStoryline() => StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Main quest',
      chapters: [
        StorylineChapter(id: 'act_1', title: 'Act 1', order: 0, steps: [
          StorylineStep(
            id: 'wake_up',
            title: 'Wake up',
            order: 0,
            sceneLinkIds: const ['scene_gate'],
          ),
        ]),
      ],
    );

ProjectManifest trameProject(int unrelated) {
  final base = narrativeTitleProject(unrelated: unrelated);
  SceneAsset scene(String id) => SceneAsset(
        id: id,
        name: id,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
          edges: const [],
        ),
      );
  return base.copyWith(
    scenes: [
      ...base.scenes,
      scene('scene_gate'),
      scene('scene_town'),
      for (var i = 0; i < unrelated; i++) scene('scene_unrelated_$i'),
    ],
    storylines: [trameStoryline()],
  );
}

ProjectManifest storylineOutlineProject(int unrelated) {
  final base = trameProject(unrelated);
  final done = ScriptConditionFactory.factEquals(
      'fact_fact_0', const NarrativeValue.boolean(true));
  return base.copyWith(
    scenes: [
      ...base.scenes,
      SceneAsset(
        id: 'scene_reset',
        name: 'scene_reset',
        graph: SceneGraph(startNodeId: 'start', nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
              id: 'reset',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(
                  consequence: SceneSetFactConsequence(
                      factId: 'fact_fact_0', value: false))),
          SceneNode(
              id: 'gate',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload(
                  consequence: SceneSetFactConsequence(
                      factId: 'fact_fact_1', value: true))),
        ], edges: const []),
      ),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        ...base.eventRegistry!.records,
        NarrativeEventRecord.configuredStructurallyUnchecked(
          enabled: true,
          NarrativeEventDefinition(
            id: narrativeTitleEvent(9),
            name: 'Enter gate',
            source: NarrativeEventSourceRef.mapEnter('map_0'),
            conditions: const [],
            sceneId: 'scene_gate',
            reusePolicy: NarrativeEventReusePolicy.reusable,
            priority: 0,
            order: 9,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
    storylines: [
      StorylineAsset(
        id: 'main',
        type: StorylineType.main,
        title: 'Main quest',
        chapters: [
          StorylineChapter(id: 'act_1', title: 'Act 1', order: 0, steps: [
            StorylineStep(
                id: 'wake_up',
                title: 'Wake up',
                order: 0,
                sceneLinkIds: const ['scene_gate'],
                completionCondition: done),
            StorylineStep(
                id: 'leave_home',
                title: 'Leave home',
                order: 1,
                completionCondition: done),
          ]),
        ],
      ),
    ],
  );
}
