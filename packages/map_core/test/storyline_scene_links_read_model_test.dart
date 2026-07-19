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

    test('keeps the legacy last-match fallback without a dependency index', () {
      final project = _project(
        sceneLinkIds: const ['scene_intro'],
        scenes: [
          _scene('scene_intro', 'First Scene'),
          _invalidScene('scene_intro', 'Legacy Last Scene'),
        ],
      );
      final storyline = project.storylines.single;
      final chapter = storyline.chapters.single;

      final model = buildStorylineStepSceneLinksReadModel(
        project: project,
        storyline: storyline,
        chapter: chapter,
        step: chapter.steps.single,
      );

      expect(model.linkedScenes.single.label, 'Legacy Last Scene');
      expect(model.linkedScenes.single.exists, isTrue);
      expect(model.linkedScenes.single.hasSceneErrors, isTrue);
      expect(model.linkedScenes.single.isRuntimeBuildable, isFalse);
      expect(
        model.linkedScenes.single.referenceResolution,
        NarrativeDependencyResolution.resolved,
      );
    });

    test(
        'exposes duplicate Scene ids as ambiguous without arbitrary details when indexed',
        () {
      StorylineStepSceneLinkView buildLink(List<SceneAsset> scenes) {
        final project = _project(
          sceneLinkIds: const ['scene_intro'],
          scenes: scenes,
        );
        final storyline = project.storylines.single;
        final chapter = storyline.chapters.single;

        return buildStorylineStepSceneLinksReadModel(
          project: project,
          storyline: storyline,
          chapter: chapter,
          step: chapter.steps.single,
          dependencyIndex: buildNarrativeDependencyIndex(project: project),
        ).linkedScenes.single;
      }

      final valid = _scene('scene_intro', 'Valid Scene');
      final invalid = _invalidScene('scene_intro', 'Invalid Scene');
      final validThenInvalid = buildLink([valid, invalid]);
      final invalidThenValid = buildLink([invalid, valid]);

      for (final link in [validThenInvalid, invalidThenValid]) {
        expect(link.label, 'Scene ambiguë (scene_intro)');
        expect(link.exists, isTrue);
        expect(link.hasSceneErrors, isFalse);
        expect(link.isRuntimeBuildable, isFalse);
        expect(
          link.referenceResolution,
          NarrativeDependencyResolution.ambiguous,
        );
      }
    });
  });
}

ProjectManifest _project({
  required List<String> sceneLinkIds,
  List<SceneAsset>? scenes,
}) {
  return ProjectManifest(
    name: 'Story Project',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenes: scenes ??
        [
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

SceneAsset _invalidScene(String id, String name) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'node_start',
      nodes: [
        SceneNode(id: 'node_start', kind: SceneNodeKind.start),
      ],
    ),
  );
}
