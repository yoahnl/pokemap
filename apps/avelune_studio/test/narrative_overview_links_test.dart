import 'package:avelune_studio/features/narrative/application/narrative_overview.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview_context.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test(
    'both canonical step scene link directions are indexed and deduplicated',
    () {
      final scene = SceneAsset(
        id: 'known',
        name: 'La conversation',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
          edges: [],
        ),
      );
      final story = StorylineAsset(
        id: 'story',
        title: 'Histoire',
        type: StorylineType.sideQuest,
        chapters: [
          StorylineChapter(
            id: 'chapter',
            title: 'Chapitre',
            order: 0,
            steps: [
              StorylineStep(
                id: 'indirect',
                title: 'Lien indirect',
                order: 0,
                sceneLinkIds: ['reference'],
              ),
              StorylineStep(
                id: 'both',
                title: 'Deux sens',
                order: 1,
                sceneLinkIds: ['both-reference'],
              ),
              StorylineStep(
                id: 'broken',
                title: 'Scène absente',
                order: 2,
                sceneLinkIds: ['missing-reference'],
              ),
              StorylineStep(id: 'alone', title: 'Sans lien', order: 3),
            ],
          ),
        ],
        sceneLinks: [
          for (final entry in [
            (id: 'reference', step: null, scene: 'known'),
            (id: 'both-reference', step: 'both', scene: 'known'),
            (id: 'missing-reference', step: null, scene: 'missing'),
          ])
            StorylineSceneLink(
              id: entry.id,
              chapterId: 'chapter',
              stepId: entry.step,
              label: entry.id,
              state: StorylineSceneLinkState.linkedScenario,
              role: StorylineSceneLinkRole.branch,
              order: 0,
              sceneRef: StorylineSceneRef(
                kind: StorylineSceneRefKind.scenario,
                targetId: entry.scene,
              ),
            ),
        ],
      );
      final project = ProjectManifest(
        name: 'Test',
        maps: [],
        tilesets: [],
        storylines: [story],
        scenes: [scene],
      );
      final context = NarrativeOverviewContext(project, [story], [], []);
      expect(context.sceneSteps['known'], {'indirect', 'both'});
      expect(context.sceneSteps['missing'], {'broken'});
      expect(
        context.stepReferences['indirect']!.single.label,
        'La conversation',
      );
      expect(context.stepReferences['both'], hasLength(1));
      expect(context.stepReferences['broken']!.single.missing, isTrue);
      expect(
        context.stepReferences['broken']!.single.kind,
        NarrativeOverviewReferenceKind.scene,
      );
      expect(context.stepReferences['alone'], isNull);
      expect(project.storylines.single, same(story));
    },
  );
}
