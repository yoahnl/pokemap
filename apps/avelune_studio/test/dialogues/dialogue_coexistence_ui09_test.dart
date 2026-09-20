import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import '../support/m3_story_fixture.dart';

void main() {
  late M3StoryFixture f;
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController n;
  late DialogueWorkspaceController c;
  setUp(() async {
    f = await M3StoryFixture.create();
    maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    n = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    c = DialogueWorkspaceController(
      n,
      LocalDialogueAdapter(session: f.session, mapAdapter: f.maps),
      changed: () {},
    );
  });
  tearDown(() async {
    c.dispose();
    n.dispose();
    maps.dispose();
    await f.directory.delete(recursive: true);
  });
  test(
    'simplified dirty blocks full document; full dirty blocks simplified and preserves unrelated use',
    () async {
      final record = n.project.eventRegistry!.records.first;
      expect(await n.openRecord(record), true, reason: n.error);
      final simple = n.active!;
      final id = simple.current.dialogue.entry.id;
      simple.change(
        interaction: simple.current.interaction.revise(
          name: 'Interaction modifiée',
        ),
      );
      expect(await c.open(id), false);
      expect(simple.dirty, true);
      expect(n.discardInteraction(record.id), true);
      expect(await c.open(id), true, reason: c.error);
      expect(c.active!.readOnlyReason, isNull);
      final line = c.active!.document.nodes.first.steps
          .whereType<DeLineStep>()
          .first;
      c.updateLine(line.id, text: 'Texte UI09');
      expect(c.active!.dirty, true);
      expect(await n.openRecord(record), false);
      expect(c.active!.source, contains('Texte UI09'));
      expect(
        await n.openRecord(n.project.eventRegistry!.records.last),
        true,
        reason: n.error,
      );
      expect(await c.save(), true, reason: c.error);
      expect(await n.openRecord(record), true, reason: n.error);
      expect(n.active!.readOnlySource, contains('Texte UI09'));
      expect(n.active!.editable, false);
    },
  );
  test(
    'simplified source-only publication invalidates clean full cached source',
    () async {
      final record = n.project.eventRegistry!.records.last;
      expect(await n.openRecord(record), true);
      final simple = n.active!;
      final id = simple.current.dialogue.entry.id;
      expect(await c.open(id), true);
      simple.change(
        dialogue: simple.current.dialogue.copyWith(
          branches: [
            simple.current.dialogue.branches.first.copyWith(
              lines: const [DialogueLineDraft(text: 'Texte simplifié publié')],
            ),
            ...simple.current.dialogue.branches.skip(1),
          ],
        ),
      );
      expect(await n.save(document: simple.document), true, reason: n.error);
      expect(c.session(id), isNull);
      expect(await c.open(id), true, reason: c.error);
      expect(c.active!.source, contains('Texte simplifié publié'));
    },
  );
  test(
    'two clean simplified consumers cannot republish a stale shared source',
    () async {
      final record = n.project.eventRegistry!.records.last;
      expect(await n.openRecord(record), true);
      final a = n.active!;
      final id = a.current.dialogue.entry.id;
      final source = NarrativeEventSourceRef.mapEnter(a.document.current.id);
      await n.openSource(
        a.document,
        source,
        'Second consommateur',
        existing: a.current.dialogue.entry,
      );
      final b = n.active!;
      expect(b, isNot(same(a)));
      a.change(
        dialogue: a.current.dialogue.copyWith(
          branches: [
            a.current.dialogue.branches.first.copyWith(
              lines: const [DialogueLineDraft(text: 'Nouvelle source A')],
            ),
            ...a.current.dialogue.branches.skip(1),
          ],
        ),
      );
      b.change(
        dialogue: b.current.dialogue.copyWith(
          entry: b.current.dialogue.entry.copyWith(name: 'Écriture B refusée'),
        ),
      );
      expect(b.dirty, false);
      expect(await n.save(document: a.document), true, reason: n.error);
      expect(n.sessions.containsValue(a), true);
      expect(n.sessions.containsValue(b), false);
      await n.openSource(
        a.document,
        source,
        'Second consommateur',
        existing: n.project.dialogues.firstWhere((d) => d.id == id),
      );
      expect(
        n.active!.current.dialogue.branches.first.lines.first.text,
        'Nouvelle source A',
      );
    },
  );
}
