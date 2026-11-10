import 'package:avelune_studio/features/stories/application/story_document_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/story_backend_fixture.dart';
import '../support/story_graph_project_fixture.dart';

void main() {
  test('scenario role edits preserve metadata outcomes and effects, refuse removal, and publish', () async {
    final source = storyCanvasProject();
    final fixture = await StoryBackendFixture.create(
      stories: source.storylines,
      facts: source.facts,
      scenarios: source.scenarios,
    );
    addTearDown(fixture.dispose);
    final controller = fixture.attach()..open('main');
    final commands = StoryDocumentCommands(controller);
    final original = controller.active!;
    final link = StorylineSceneLink.fromJson({
      ...original.sceneLinks.single.toJson(),
      'metadata': {'future': 'keep'},
      'authorNotes': 'Conserver',
    });
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: 'main',
        storyline: original.copyWith(sceneLinks: [link]),
      ),
    );
    commands.patchScenarioLink(
      'main',
      link.id,
      (_) => {'role': StorylineSceneLinkRole.branch.name},
    );
    final updated = controller.active!.sceneLinks.single;
    expect(updated.role, StorylineSceneLinkRole.branch);
    expect(updated.metadata, link.metadata);
    expect(updated.authorNotes, link.authorNotes);
    expect(updated.outcomeLinks, link.outcomeLinks);
    final beforeRemoval = controller.project;
    commands.removeScenarioLink('main', link.id);
    expect(controller.project, beforeRemoval);
    expect(await controller.save(), isTrue, reason: controller.error);
    expect(
      (await fixture.readFresh()).storylines.first.sceneLinks.single,
      updated,
    );
  });

  test('scenario associations use declared results without creating effects and undo removal', () async {
    final source = storyCanvasProject();
    final fixture = await StoryBackendFixture.create(
      stories: source.storylines,
      facts: source.facts,
      scenarios: source.scenarios,
    );
    addTearDown(fixture.dispose);
    final controller = fixture.attach()..open('main');
    final commands = StoryDocumentCommands(controller);
    controller.apply(
      updateStoryline(
        controller.project,
        storylineId: 'main',
        storyline: controller.active!.copyWith(sceneLinks: []),
      ),
    );
    commands.addScenarioLink('main', 'chapter0', 'step0_0', 'scenario');
    final link = controller.active!.sceneLinks.single;
    expect(link.sceneRef!.targetId, 'scenario');
    expect(link.expectedOutcomeIds, ['accepted']);
    expect(link.outcomeLinks, isEmpty);
    commands.removeScenarioLink('main', link.id);
    expect(controller.active!.sceneLinks, isEmpty);
    controller.restore(redo: false);
    expect(controller.active!.sceneLinks.single, link);
    final before = controller.project;
    commands.addScenarioLink('main', 'missing', 'step0_0', 'scenario');
    commands.addScenarioLink('main', 'chapter0', 'missing', 'scenario');
    commands.addScenarioLink('main', 'chapter0', 'step0_0', 'missing');
    commands.patchScenarioLink('main', 'missing', (_) => {'role': 'optional'});
    expect(controller.project, before);
    expect(await controller.save(), isTrue, reason: controller.error);
    expect(
      (await fixture.readFresh()).storylines.first.sceneLinks.single,
      link,
    );
  });
}
