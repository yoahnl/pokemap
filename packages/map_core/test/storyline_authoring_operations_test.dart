import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Storyline scene link authoring operations', () {
    test('linkSceneToStorylineStep adds an existing scene id', () {
      final project = _project();

      final result = linkSceneToStorylineStep(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        sceneId: 'scene_intro',
      );

      expect(result.updatedStep.sceneLinkIds, ['scene_intro']);
      expect(
        result.updatedProject.storylines.single.chapters.single.steps.single
            .sceneLinkIds,
        ['scene_intro'],
      );
      expect(
          project.storylines.single.chapters.single.steps.single.sceneLinkIds,
          isEmpty);
      expect(result.updatedProject.scenes, equals(project.scenes));
      expect(result.updatedProject, isNot(same(project)));
    });

    test('linkSceneToStorylineStep refuses unknown step', () {
      expect(
        () => linkSceneToStorylineStep(
          _project(),
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'missing_step',
          sceneId: 'scene_intro',
        ),
        throwsArgumentError,
      );
    });

    test('linkSceneToStorylineStep refuses empty scene id', () {
      expect(
        () => linkSceneToStorylineStep(
          _project(),
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'step_intro',
          sceneId: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('linkSceneToStorylineStep refuses unknown scene id', () {
      expect(
        () => linkSceneToStorylineStep(
          _project(),
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'step_intro',
          sceneId: 'missing_scene',
        ),
        throwsArgumentError,
      );
    });

    test('linkSceneToStorylineStep refuses duplicate scene id', () {
      final linked = linkSceneToStorylineStep(
        _project(),
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        sceneId: 'scene_intro',
      ).updatedProject;

      expect(
        () => linkSceneToStorylineStep(
          linked,
          storylineId: 'story_main',
          chapterId: 'chapter_intro',
          stepId: 'step_intro',
          sceneId: 'scene_intro',
        ),
        throwsArgumentError,
      );
    });

    test('unlinkSceneFromStorylineStep removes only selected scene id', () {
      final project =
          _projectWithStepLinks(['scene_intro', 'scene_resolution']);

      final result = unlinkSceneFromStorylineStep(
        project,
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        sceneId: 'scene_intro',
      );

      expect(result.updatedStep.sceneLinkIds, ['scene_resolution']);
      expect(
          project.storylines.single.chapters.single.steps.single.sceneLinkIds,
          ['scene_intro', 'scene_resolution']);
    });

    test('replaceStorylineStepSceneLinks preserves order without duplicates',
        () {
      final result = replaceStorylineStepSceneLinks(
        _project(),
        storylineId: 'story_main',
        chapterId: 'chapter_intro',
        stepId: 'step_intro',
        sceneIds: const ['scene_resolution', 'scene_intro', 'scene_resolution'],
      );

      expect(
          result.updatedStep.sceneLinkIds, ['scene_resolution', 'scene_intro']);
    });
  });
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'Story Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: [_scene('scene_intro'), _scene('scene_resolution')],
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
              StorylineStep(id: 'step_intro', title: 'Intro', order: 0),
            ],
          ),
        ],
      ),
    ],
  );
}

ProjectManifest _projectWithStepLinks(List<String> sceneLinkIds) {
  final project = _project();
  return replaceStorylineStepSceneLinks(
    project,
    storylineId: 'story_main',
    chapterId: 'chapter_intro',
    stepId: 'step_intro',
    sceneIds: sceneLinkIds,
  ).updatedProject;
}

SceneAsset _scene(String id) {
  return SceneAsset(
    id: id,
    name: id == 'scene_intro' ? 'Intro Scene' : 'Resolution Scene',
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
