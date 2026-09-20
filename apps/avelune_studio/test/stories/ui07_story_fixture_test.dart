import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/ui06_scene_fixture.dart';
import '../support/ui07_story_fixture.dart';

void main() {
  test(
    'rich fixture publishes real outcomes, owner relationship and modern scene link',
    () async {
      final fixture = await Ui07StoryFixture.create();
      addTearDown(fixture.dispose);
      final project = await fixture.readFresh();
      expect(project, fixture.manifest);
      final main = project.storylines.singleWhere(
        (s) => s.id == Ui07StoryFixture.mainId,
      );
      expect(main.chapters, hasLength(2));
      expect(main.chapters.expand((c) => c.steps), hasLength(5));
      expect(main.chapters.first.steps[1].sceneLinkIds, [
        Ui06SceneFixture.sceneId,
      ]);
      expect(project.scenes.single.id, Ui06SceneFixture.sceneId);
      expect(project.scenarios.single.declaredOutcomes, ['ready', 'wait']);
      expect(
        project.scenarios.single.nodes
            .singleWhere((n) => n.id == 'choice')
            .payload
            .choiceLabels,
        ['Prêt', 'Attendre'],
      );
      final projection = buildStorylineProgressionProjection(
        project: project,
        storylineId: main.id,
      );
      expect(projection.diagnostics, isEmpty);
      final results = projection
          .edgesOfKind(StorylineProgressionEdgeKind.outcomeActivatesStep)
          .toList();
      expect(results, hasLength(2));
      expect(
        results
            .singleWhere(
              (e) => e.source.outcomeLinkId == Ui07StoryFixture.readyLinkId,
            )
            .toNodeId,
        'step:${Ui07StoryFixture.boardId}',
      );
      expect(
        results
            .singleWhere(
              (e) => e.source.outcomeLinkId == Ui07StoryFixture.waitLinkId,
            )
            .toNodeId,
        'step:${Ui07StoryFixture.waitId}',
      );
      final requires = projection
          .edgesOfKind(StorylineProgressionEdgeKind.requires)
          .single;
      expect(requires.fromNodeId, 'storyline:${Ui07StoryFixture.sideId}');
      expect(requires.toNodeId, 'storyline:${Ui07StoryFixture.mainId}');
      final condition = projection
          .edgesOfKind(StorylineProgressionEdgeKind.entryCondition)
          .single;
      expect(condition.fromNodeId, 'fact:${Ui07StoryFixture.factId}');
      expect(condition.toNodeId, 'step:${Ui07StoryFixture.boardId}');
      expect(
        await Directory('${fixture.directory.path}/saves').exists(),
        false,
      );
    },
  );

  test(
    'construction fixture provides prerequisites but no authored stories',
    () async {
      final fixture = await Ui07StoryFixture.create(withStories: false);
      addTearDown(fixture.dispose);
      final project = await fixture.readFresh();
      expect(project.storylines, isEmpty);
      expect(project.scenes, isNotEmpty);
      expect(project.scenarios.single.declaredOutcomes, ['ready', 'wait']);
      expect(project.facts.any((f) => f.id == Ui07StoryFixture.factId), true);
    },
  );
}
