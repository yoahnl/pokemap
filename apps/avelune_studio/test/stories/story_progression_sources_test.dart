import 'package:avelune_studio/features/stories/application/story_document_commands.dart';
import 'package:avelune_studio/features/stories/application/story_progression_sources.dart';
import 'package:avelune_studio/features/stories/application/story_step_outcomes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/story_backend_fixture.dart';
import '../support/story_graph_project_fixture.dart';

void main() {
  test(
    'catalogue sources retain native identities without modifying the project',
    () {
      final initial = storyCanvasProject();
      final project = initial.copyWith(
        facts: [
          ...initial.facts,
          NarrativeFactDefinition(
            id: 'count',
            label: 'Compteur',
            initialValue: NarrativeValue.integer(2),
          ),
        ],
      );
      final before = project.toJson();
      final initialSources = StoryProgressionSources(project, 'main');
      expect(initialSources.additionalSources(), {
        'fact:fact': 'Fait · Le passage est ouvert',
        'storyline:side0': 'Histoire · Histoire secondaire 1',
      });
      expect(initialSources.additionalSources(query: 'SIDE0').keys, [
        'storyline:side0',
      ]);
      expect(initialSources.additionalSources(query: 'passage').keys, [
        'fact:fact',
      ]);
      final sources = StoryProgressionSources(
        project,
        'main',
        revealedFacts: const ['fact', 'count', 'unknown'],
        revealedStories: const ['side0', 'unknown'],
      );
      final fact = sources.nodes['fact:fact']!;
      final target = sources.nodes['step:step1_1']!;
      expect(sources.canSource(fact), isTrue);
      expect(sources.canSource(sources.nodes['fact:count']!), isFalse);
      expect(sources.canSource(target), isFalse);
      expect(sources.nodes, isNot(contains('fact:unknown')));
      expect(sources.nodes, isNot(contains('storyline:unknown')));
      expect(sources.additionalSources(), isEmpty);
      expect(sources.canTarget(fact, target), isTrue);
      expect(
        sources.canTarget(fact, sources.nodes['chapter:chapter0']!),
        isFalse,
      );
      expect(
        sources.canTarget(fact, sources.nodes['storyline:side0']!),
        isFalse,
      );
      final sourceStory = sources.nodes['storyline:side0']!;
      expect(
        sources.canTarget(sourceStory, sources.nodes['storyline:main']!),
        isTrue,
      );
      expect(sources.canTarget(sourceStory, sourceStory), isFalse);
      expect(sources.canTarget(sourceStory, target), isFalse);
      const missing = StorylineProgressionNode(
        id: 'missing',
        kind: StorylineProgressionNodeKind.step,
        canonicalId: 'missing',
        label: 'Absente',
        storylineId: 'main',
        isMissing: true,
      );
      const foreign = StorylineProgressionNode(
        id: 'foreign',
        kind: StorylineProgressionNodeKind.step,
        canonicalId: 'foreign',
        label: 'Autre histoire',
        storylineId: 'side0',
      );
      expect(sources.canSource(missing), isFalse);
      expect(sources.canTarget(fact, missing), isFalse);
      expect(sources.canTarget(fact, foreign), isFalse);
      expect(project.toJson(), before);
    },
  );

  test('missing scenario results stay visible and cannot become connection sources', () {
    final initial = storyCanvasProject();
    final project = initial.copyWith(scenarios: []);
    final sources = StoryProgressionSources(project, 'main');
    final outcome = sources.nodes['outcome:main:link:result']!;
    expect(sources.outcomeSources[outcome.id]!.connectable, isFalse);
    expect(sources.canSource(outcome), isFalse);
    expect(
      project.storylines.first.sceneLinks.single.outcomeLinks,
      initial.storylines.first.sceneLinks.single.outcomeLinks,
    );
  });

  test('scenario outcome choices preserve unknown expectations labels and latest edits', () async {
    final project = storyCanvasProject();
    final fixture = await StoryBackendFixture.create(
      stories: project.storylines,
      facts: project.facts,
      scenarios: project.scenarios,
    );
    addTearDown(fixture.dispose);
    final controller = fixture.attach()..open('main');
    final commands = StoryDocumentCommands(controller);
    commands.patchScenarioLink(
      'main',
      'link',
      (_) => {
        'expectedOutcomeIds': ['accepted', 'unknown'],
        'authorNotes': 'Conserver',
      },
    );
    final before = controller.active!.sceneLinks.single;
    final choices = storyScenarioOutcomeChoices(project.scenarios, before);
    expect(choices.map((choice) => choice.id), ['accepted', 'unknown']);
    expect(choices.first.label, 'Invitation acceptée');
    expect(choices.first.expected, isTrue);
    expect(choices.last.expected, isTrue);
    expect(choices.last.missing, isTrue);
    expect(storyScenarioOutcomeChoices(const [], before), isEmpty);
    commands.patchScenarioLink('main', 'link', (_) => {'role': 'branch'});
    commands.expectScenarioOutcome('main', 'link', 'accepted', false);
    final changed = controller.active!.sceneLinks.single;
    expect(changed.expectedOutcomeIds, ['unknown']);
    expect(changed.role, StorylineSceneLinkRole.branch);
    expect(changed.authorNotes, 'Conserver');
    expect(changed.outcomeLinks, before.outcomeLinks);
    controller.restore(redo: false);
    expect(controller.active!.sceneLinks.single.expectedOutcomeIds, [
      'accepted',
      'unknown',
    ]);
    commands.expectScenarioOutcome('main', 'missing', 'accepted', false);
    expect(controller.active!.sceneLinks.single.expectedOutcomeIds, [
      'accepted',
      'unknown',
    ]);
  });
}
