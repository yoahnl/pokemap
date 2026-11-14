import 'package:map_core/map_core.dart';

ProjectManifest storylineTrameProject() => ProjectManifest(
  name: 'Trame',
  maps: const [],
  tilesets: const [],
  scenes: [
    for (final id in ['scene_rival', 'scene_shared'])
      SceneAsset(
        id: id,
        name: id,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
          edges: const [],
        ),
      ),
  ],
  facts: [
    NarrativeFactDefinition(id: 'fact_leave_town', label: 'Leave town'),
    NarrativeFactDefinition(id: 'fact_meet_rival', label: 'Meet rival'),
  ],
  storylines: [
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Main',
      chapters: [
        StorylineChapter(
          id: 'act_1',
          title: 'Act 1',
          order: 0,
          steps: [
            StorylineStep(
              id: 'meet_rival',
              title: 'Meet rival',
              order: 0,
              sceneLinkIds: const ['scene_rival'],
              completionCondition: ScriptConditionFactory.factEquals(
                'fact_meet_rival',
                const NarrativeValue.boolean(true),
              ),
            ),
          ],
        ),
      ],
    ),
    StorylineAsset(
      id: 'side',
      type: StorylineType.sideQuest,
      title: 'Side',
      chapters: [
        StorylineChapter(
          id: 'side_act',
          title: 'Side act',
          order: 0,
          steps: [
            StorylineStep(
              id: 'side_step',
              title: 'Side step',
              order: 0,
              sceneLinkIds: const ['scene_shared'],
            ),
          ],
        ),
      ],
    ),
  ],
);
