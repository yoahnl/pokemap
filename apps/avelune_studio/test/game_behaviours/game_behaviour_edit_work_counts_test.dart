import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_conditions.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_reuse.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';

import '../presentation/map_builder_story_support.dart';
import '../support/map_workspace_fixture.dart';
import 'game_behaviour_edit_support.dart';

void main() {
  test(
    'one relevant map and one relevant dialogue, with no publication',
    () async {
      final dialogue = storyLineDialogue('wanted', ['Bonjour']);
      final unrelated = storyLineDialogue('unrelated', ['À ignorer']);
      final record = storyRecord(
        1,
        source: NarrativeEventSourceRef.entityInteract('b', 'luth'),
        sceneId: 'line',
      );
      final fixture = await openStory(
        records: [record],
        scenes: [
          storyLineScene('line', 'wanted'),
          storyLineScene('other', 'unrelated'),
        ],
        dialogues: [dialogue, unrelated],
      );
      final loader = BehaviourMapLoader();
      final catalog = openCatalogue(fixture, loader);
      expect(await catalog.open(record.id), isTrue);
      final editor = catalog.editor!;
      expect(editor.lineOf(record).text, 'Bonjour');
      expect(loader.reads, ['b']);
    expect(fixture.ports.dialogueReads, ['wanted']);
      expect(fixture.story.behaviours.dialogues['unrelated'], isNull);
      expect(editor.writeLine(editor.selected!, record, 'Brouillon B'), isTrue);
      expect(editor.lineOf(record).text, 'Brouillon B');
      expect(fixture.story.behaviours.draft.touchedRefs, [
        (kind: StoryDraftKind.dialogue, id: 'wanted'),
      ]);
      expect(fixture.maps.active!.current.id, 'a');
      expect(loader.reads, ['b']);
      expect(fixture.ports.calls, isEmpty);
    expect((fixture.maps.port as WorkspaceMemoryPort).writes, 0);
    },
  );

  test(
    'Carte and Histoire use the same conditions and after operations',
    () async {
      final record = recordOnB();
      final fact = NarrativeFactDefinition(
        id: 'ready',
        label: 'Prêt',
        initialValue: const NarrativeValue.boolean(false),
      );
      final carte = await openStory(records: [record], facts: [fact]);
      final histoire = await openStory(records: [record], facts: [fact]);
      await carte.maps.activate(workspaceEntries.last);
      carte.maps.active!.current = workspaceMap('b')
          .copyWith(entities: [storyLuth]);
      final catalog = openCatalogue(histoire, BehaviourMapLoader());
      expect(await catalog.open(record.id), isTrue);
      final conditions = readBehaviourConditions(record)
          .adding(BehaviourEditableCondition.isTrue('ready'));
      for (final editor in [carte.story, catalog.editor!]) {
        expect(editor.setConditions(record, conditions), isTrue);
        final current = editor.behaviours
            .registry(editor.project!)!
            .records
            .single;
        expect(editor.setAfter(current, BehaviourAfter.eachTime), isTrue);
      }
      expect(storyCurrent(histoire, record.id), storyCurrent(carte, record.id));
      final draft = histoire.story.behaviours.draft;
      final before = draft.recorded;
      final report = catalog.editor!.simulate(
        NarrativeEventSimulationInput(
          targetEventId: record.id,
          factNarrativeValues: {'ready': const NarrativeValue.boolean(true)},
        ),
      );
      expect(report!.handledEventId, record.id);
      expect(draft.recorded, before);
      expect(draft.touched(StoryDraftKind.fact), isEmpty);
      expect(
        histoire.maps.project!.facts.single.initialValue,
        const NarrativeValue.boolean(false),
      );
      expect(histoire.ports.calls, isEmpty);
    },
  );
}
