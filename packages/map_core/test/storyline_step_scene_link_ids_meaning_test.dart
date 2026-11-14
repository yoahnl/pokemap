import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('StorylineStep.sceneLinkIds holds SceneAsset ids', () {
    test('the dependency index records each entry as a scene usage', () {
      final index = buildNarrativeDependencyIndex(
        project: _project(sceneLinkIds: const ['scene_intro']),
      );

      expect(
        index
            .usagesFor(NarrativeDependencyKey.scene('scene_intro'))
            .map((usage) => usage.path),
        ['storylines[story_main].chapters[0].steps[0].sceneLinkIds[0]'],
      );
      expect(
        index.definitionsFor(NarrativeDependencyKey.scene('scene_intro')),
        hasLength(1),
      );
    });

    test('a structured StorylineSceneLink id is not resolved as an entry', () {
      final project = _project(sceneLinkIds: const ['link_intro']);
      final index = buildNarrativeDependencyIndex(project: project);

      expect(
        index.definitionsFor(NarrativeDependencyKey.scene('link_intro')),
        isEmpty,
      );
      expect(
        diagnoseStorylineSceneLinks(project: project)
            .byCode(
              StorylineSceneLinkDiagnosticCode.storylineStepUnknownSceneLink,
            )
            .single
            .sceneId,
        'link_intro',
      );
    });

    test('replacing a deleted scene rewrites the entry, not the link', () {
      final project = _project(sceneLinkIds: const ['scene_intro']);
      final replaced = deleteSceneFromProject(
        project,
        sceneId: 'scene_intro',
        replacementSceneId: 'scene_opening',
      );
      expect(replaced.isApplied, isTrue);
      final storyline = replaced.after.storylines.single;

      expect(storyline.chapters.single.steps.single.sceneLinkIds, [
        'scene_opening',
      ]);
      expect(storyline.sceneLinks.single.id, 'link_intro');
      expect(storyline.sceneLinks.single.sceneRef, isNull);
    });
  });
}

ProjectManifest _project({required List<String> sceneLinkIds}) =>
    ProjectManifest(
      name: 'Scene link ids',
      maps: const [],
      tilesets: const [],
      scenes: [
        for (final id in ['scene_intro', 'scene_opening'])
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
      storylines: [
        StorylineAsset(
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
                  sceneLinkIds: sceneLinkIds,
                ),
              ],
            ),
          ],
          sceneLinks: [
            StorylineSceneLink(
              id: 'link_intro',
              chapterId: 'chapter_intro',
              stepId: 'step_intro',
              label: 'Intro placeholder',
              state: StorylineSceneLinkState.placeholder,
              role: StorylineSceneLinkRole.primary,
              order: 0,
            ),
          ],
        ),
      ],
    );
