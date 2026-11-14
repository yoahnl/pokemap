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
