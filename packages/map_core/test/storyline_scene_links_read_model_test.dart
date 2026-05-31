import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('buildStorylineStepSceneLinksReadModel', () {
    test('lists linked scenes with labels and available picker options', () {
      final project = _project(sceneLinkIds: const ['scene_intro']);
      final storyline = project.storylines.single;
      final chapter = storyline.chapters.single;
      final step = chapter.steps.single;

      final model = buildStorylineStepSceneLinksReadModel(
        project: project,
        storyline: storyline,
        chapter: chapter,
        step: step,
      );

      expect(model.linkedScenes, hasLength(1));
      expect(model.linkedScenes.single.sceneId, 'scene_intro');
      expect(model.linkedScenes.single.label, 'Intro Scene');
      expect(model.linkedScenes.single.exists, isTrue);
      expect(model.availableScenes.map((scene) => scene.sceneId),
          ['scene_intro', 'scene_resolution']);
      expect(model.availableScenes.first.isLinked, isTrue);
      expect(
        model.authoringOnlyMessageText,
        contains('déclenchement runtime'),
      );
    });

    test('reports missing linked scenes without requiring runtime state', () {
      final project = _project(sceneLinkIds: const ['missing_scene']);
      final storyline = project.storylines.single;
      final chapter = storyline.chapters.single;
      final step = chapter.steps.single;

      final model = buildStorylineStepSceneLinksReadModel(
        project: project,
        storyline: storyline,
        chapter: chapter,
        step: step,
      );

      expect(model.linkedScenes.single.exists, isFalse);
      expect(model.linkedScenes.single.label, 'Scene introuvable');
      expect(model.diagnostics.single.code,
          StorylineSceneLinkDiagnosticCode.storylineStepUnknownSceneLink);
    });
  });
}

ProjectManifest _project({required List<String> sceneLinkIds}) {
  return ProjectManifest(
    name: 'Story Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: [
      _scene('scene_intro', 'Intro Scene'),
      _scene('scene_resolution', 'Resolution Scene')
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
                sceneLinkIds: sceneLinkIds,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

SceneAsset _scene(String id, String name) {
  return SceneAsset(
    id: id,
    name: name,
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
