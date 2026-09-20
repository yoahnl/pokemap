import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m3_story_fixture.dart';

void main() {
  late M3StoryFixture fixture;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late EventWorkspaceController events;
  setUp(() async {
    fixture = await M3StoryFixture.create();
    maps = MapWorkspaceController(fixture.session, fixture.maps);
    await maps.initialize();
    narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
      () {},
      (_, _) async {},
    );
    events = EventWorkspaceController(
      narrative,
      LocalEventAdapter(session: fixture.session, mapAdapter: fixture.maps),
      changed: () {},
    );
    expect(await events.prepare(), true);
  });
  tearDown(() async {
    events.dispose();
    narrative.dispose();
    maps.dispose();
    await fixture.directory.delete(recursive: true);
  });

  test(
    'UI08 priority publication refreshes clean simplified record with scene unchanged',
    () async {
      final initial = events.records.first;
      expect(await narrative.openRecord(initial), true);
      final previous = narrative.active!;
      final scenes = narrative.project.scenes;
      expect(events.open(initial.id), true);
      expect(events.setPriority(initial.id, 42), true);
      expect(events.setEnabled(initial.id, true), true);
      expect(await events.save(), true, reason: events.error);
      expect(narrative.project.scenes, scenes);
      expect(
        await narrative.openSession(previous),
        true,
        reason: narrative.error,
      );
      final current = narrative.active!;
      expect(current.current.interaction.priority, 42);
      current.change(
        dialogue: current.current.dialogue.copyWith(
          branches: [
            current.current.dialogue.branches.first.copyWith(
              lines: const [DialogueLineDraft(text: 'Bonjour après UI08')],
            ),
            ...current.current.dialogue.branches.skip(1),
          ],
        ),
      );
      expect(
        await narrative.save(document: current.document),
        true,
        reason: narrative.error,
      );
      final reopened = await fixture.maps.loadProject(fixture.session);
      expect(
        reopened.eventRegistry!.records
            .firstWhere((r) => r.id == initial.id)
            .definitionOrNull!
            .priority,
        42,
      );
      expect(reopened.scenes, unorderedEquals(scenes));
    },
  );

  test(
    'UI08 dirty record blocks simplified changes until explicit discard',
    () async {
      final initial = events.records.first;
      final other = events.records.last;
      expect(await narrative.openRecord(initial), true);
      final simplified = narrative.active!;
      expect(events.setPriority(initial.id, 42), true);
      final draft = events.record(initial.id);
      simplified.change(
        interaction: simplified.current.interaction.revise(
          name: 'Ne pas écrire',
        ),
      );
      expect(simplified.dirty, false);
      expect(events.record(initial.id), same(draft));
      expect(await narrative.openSession(simplified), false);
      expect(await narrative.openRecord(other), true);
      expect(events.discard(initial.id), true);
      expect(await narrative.openSession(simplified), true);
      simplified.change(
        interaction: simplified.current.interaction.revise(priority: 99),
      );
      expect(simplified.dirty, true);
      expect(events.setPriority(initial.id, 42), false);
      expect(events.error, contains('brouillon simplifié'));
      expect(events.setPriority(other.id, 42), true);
      expect(await events.save(), true, reason: events.error);
      expect(simplified.dirty, true);
      expect(events.record(initial.id), initial);
    },
  );
}
