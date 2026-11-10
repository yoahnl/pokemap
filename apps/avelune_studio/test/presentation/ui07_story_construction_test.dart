import 'package:avelune_studio/features/stories/application/story_document_commands.dart';
import 'package:avelune_studio/features/stories/application/story_progression_sources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/story_backend_fixture.dart';
import '../support/ui07_story_fixture.dart';

void main() {
  test('story commands author chapters steps scene associations and a canonical side relation from empty stories', () async {
    final scene = SceneAsset(
      id: 'station',
      name: 'Rencontre en gare',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'flow',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );
    final fixture = await StoryBackendFixture.create(
      scenarios: [Ui07StoryFixture.scenario()],
      scenes: [scene],
    );
    addTearDown(fixture.dispose);
    final controller = fixture.attach();
    final commands = StoryDocumentCommands(controller);
    expect(controller.create('   '), isNull);
    expect(controller.stories, isEmpty);
    expect(controller.dirty, isFalse);
    final main = controller.create('Préparer le départ')!;
    commands.addChapter(main.id, 'Arrivée à Hanazuki');
    commands.addChapter(main.id, 'Préparer le voyage');
    final chapterIds = controller.active!.chapters
        .map((chapter) => chapter.id)
        .toList();
    for (final title in [
      'Trouver la gare',
      'Parler au chef de gare',
      'Obtenir le billet',
    ]) {
      commands.addStep(main.id, chapterIds.first, title);
    }
    for (final title in [
      'Monter dans le train',
      'Attendre le prochain départ',
    ]) {
      commands.addStep(main.id, chapterIds.last, title);
    }
    final authored = controller.active!;
    expect(authored.chapters.map((chapter) => chapter.id), chapterIds);
    expect(authored.chapters.expand((chapter) => chapter.steps), hasLength(5));
    expect(authored.relationships, isEmpty);
    final talk = authored.chapters.first.steps[1];
    void associate(bool linked, {String sceneId = 'station'}) =>
        commands.associateScene(
          storyId: main.id,
          chapterId: chapterIds.first,
          stepId: talk.id,
          sceneId: sceneId,
          linked: linked,
        );
    associate(true);
    associate(true);
    expect(controller.active!.chapters.first.steps[1].sceneLinkIds, [
      'station',
    ]);
    final beforeInvalid = controller.project;
    associate(true, sceneId: 'missing');
    expect(controller.project, beforeInvalid);
    associate(false);
    expect(controller.active!.chapters.first.steps[1].sceneLinkIds, isEmpty);
    controller.restore(redo: false);
    expect(controller.active!.chapters.first.steps[1].sceneLinkIds, [
      'station',
    ]);
    commands.addScenarioLink(
      main.id,
      chapterIds.first,
      talk.id,
      Ui07StoryFixture.scenarioId,
    );
    final link = controller.active!.sceneLinks.single;
    expect(link.expectedOutcomeIds, ['ready', 'wait']);
    expect(link.outcomeLinks, isEmpty);
    final board = controller.active!.chapters.last.steps.first;
    final sources = StoryProgressionSources(controller.project, main.id);
    final sourceId = 'outcome:${main.id}:${link.id}:outcome-ready';
    expect(
      controller.connect(
        StoryDocumentCommands.connectionRequest(
          source: sources.nodes[sourceId]!,
          target: sources.nodes['step:${board.id}']!,
          choice: 0,
          outcome: sources.outcomeSources[sourceId],
          relationshipId: () => throw StateError('Unexpected relationship'),
        ),
      ),
      isTrue,
    );
    final mainDraft = controller.active!;
    expect(
      mainDraft.sceneLinks.single.outcomeLinks.single.effects.single.type,
      StorylineEffectType.activateStep,
    );
    final side = controller.create(
      'Le sac oublié',
      type: StorylineType.sideQuest,
    )!;
    final sideSources = StoryProgressionSources(
      controller.project,
      side.id,
      revealedStories: [main.id],
    );
    expect(
      controller.connect(
        StoryDocumentCommands.connectionRequest(
          source: sideSources.nodes['storyline:${side.id}']!,
          target: sideSources.nodes['storyline:${main.id}']!,
          choice: 0,
          relationshipId: () => 'side-requires-main',
        ),
      ),
      isTrue,
    );
    final relation = controller.active!.relationships.single;
    expect(relation.sourceStorylineId, side.id);
    expect(relation.targetStorylineId, main.id);
    expect(
      controller.stories
          .singleWhere((story) => story.id == main.id)
          .relationships,
      isEmpty,
    );
    expect(await controller.save(), isTrue, reason: controller.error);
    expect(controller.dirty, isFalse);
    final fresh = await fixture.readFresh();
    expect(fresh.storylines, unorderedEquals(controller.stories));
    expect(fresh.scenes.single, scene);
    expect(fresh.scenarios.single, Ui07StoryFixture.scenario());
    expect(
      fresh.storylines.singleWhere((story) => story.id == main.id),
      mainDraft,
    );
  });
}
