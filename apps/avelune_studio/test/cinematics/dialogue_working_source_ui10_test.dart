import 'dart:io';
import 'package:flutter/material.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_working_source.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_linked_document.dart';
import '../support/m3_story_fixture.dart';

void main() {
  testWidgets(
    'C1 dirty simplified dialogue wins over old clean full snapshot without publication',
    (tester) async {
      late M3StoryFixture fixture;
      late MapWorkspaceController maps;
      late NarrativeWorkspaceController narrative;
      late DialogueWorkspaceController dialogues;
      await tester.runAsync(() async {
        fixture = await M3StoryFixture.create();
        maps = MapWorkspaceController(fixture.session, fixture.maps);
        await maps.initialize();
        narrative = NarrativeWorkspaceController(
          maps,
          LocalNarrativeAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ),
          () {},
          (_, _) async {},
        );
        dialogues = DialogueWorkspaceController(
          narrative,
          LocalDialogueAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ),
          changed: () {},
        );
        await narrative.openRecord(
          narrative.project.eventRegistry!.records.last,
        );
        await dialogues.open(narrative.active!.current.dialogue.entry.id);
      });
      addTearDown(() async {
        dialogues.dispose();
        narrative.dispose();
        maps.dispose();
        await tester.runAsync(() => fixture.directory.delete(recursive: true));
      });
      final simple = narrative.active!;
      final sourceFile = File.fromUri(
        fixture.directory.uri.resolve(
          simple.current.dialogue.entry.relativePath,
        ),
      );
      final sourceBytes = await tester.runAsync(sourceFile.readAsBytes);
      simple.change(
        dialogue: simple.current.dialogue.copyWith(
          branches: [
            simple.current.dialogue.branches.first.copyWith(
              lines: const [DialogueLineDraft(text: 'Brouillon récent C1')],
            ),
            ...simple.current.dialogue.branches.skip(1),
          ],
        ),
      );
      expect(simple.dirty, true);
      final linked = SceneLinkedDocuments()..dialogues = dialogues;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: linked.dialoguePreview(
              SceneYarnDialoguePayload(
                dialogueId: simple.current.dialogue.entry.id,
              ),
              narrative.project,
              narrative,
              detailed: true,
            ),
          ),
        ),
      );
      expect(find.text('Brouillon récent C1'), findsOneWidget);
      expect(await tester.runAsync(sourceFile.readAsBytes), sourceBytes);
    },
  );
  test(
    'working source resolves publication, explicit discard, homonyms and project boundary',
    () async {
      final f = await _WorkingFixture.create();
      final other = await _WorkingFixture.create();
      addTearDown(f.dispose);
      addTearDown(other.dispose);
      final simple = f.n.active!, id = simple.current.dialogue.entry.id;

      expect(f.c.active!.dirty, false);
      simple.change(
        dialogue: simple.current.dialogue.copyWith(
          branches: [
            simple.current.dialogue.branches.first.copyWith(
              lines: const [DialogueLineDraft(text: 'Travail C1')],
            ),
            ...simple.current.dialogue.branches.skip(1),
          ],
        ),
      );
      final resolved = resolveDialogueWorkingSource(
        narrative: f.n,
        dialogues: f.c,
        dialogueId: id,
      );
      expect(resolved.dirty, true);
      expect(resolved.source!.source, contains('Travail C1'));
      expect(
        resolveDialogueWorkingSource(
          narrative: other.n,
          dialogues: f.c,
          dialogueId: id,
        ).source!.source,
        isNot(contains('Travail C1')),
      );
      expect(
        resolveDialogueWorkingSource(
          narrative: f.n,
          dialogues: f.c,
          dialogueId: 'autre-id',
        ).source,
        isNull,
      );
      simple.restore(redo: false);
      expect(
        resolveDialogueWorkingSource(
          narrative: f.n,
          dialogues: f.c,
          dialogueId: id,
        ).dirty,
        false,
      );
      simple.restore(redo: true);
      expect(
        await f.n.save(document: simple.document),
        true,
        reason: f.n.error,
      );
      expect(f.c.session(id), isNull);
      expect(
        resolveDialogueWorkingSource(
          narrative: f.n,
          dialogues: f.c,
          dialogueId: id,
        ).source!.source,
        contains('Travail C1'),
      );
      expect(await f.c.open(id), true);
      expect(f.c.active!.source, contains('Travail C1'));
    },
  );
  test(
    'incompatible modified versions produce explicit conflict and readonly source remains exact',
    () async {
      final f = await _WorkingFixture.create();
      addTearDown(f.dispose);
      final original = f.n.active!, id = original.current.dialogue.entry.id;
      final a = InteractionEditSession(
        document: original.document,
        dialogue: original.current.dialogue,
        interaction: original.current.interaction,
      );
      final b = InteractionEditSession(
        document: original.document,
        dialogue: original.current.dialogue,
        interaction: original.current.interaction,
      );
      a.change(
        dialogue: a.current.dialogue.copyWith(
          entry: a.current.dialogue.entry.copyWith(name: 'A'),
        ),
      );
      b.change(
        dialogue: b.current.dialogue.copyWith(
          entry: b.current.dialogue.entry.copyWith(name: 'B'),
        ),
      );
      f.n.sessions.clear();
      f.n.sessions['a'] = a;
      f.n.sessions['b'] = b;
      expect(
        resolveDialogueWorkingSource(
          narrative: f.n,
          dialogues: f.c,
          dialogueId: id,
        ).problem,
        contains('incompatibles'),
      );
      f.n.sessions.clear();
      const exact =
          'title: Start\n---\n<<custom unsupported>>\nTexte opaque\n===\n';
      f.n.sessions['readonly'] = InteractionEditSession(
        document: original.document,
        dialogue: original.current.dialogue,
        interaction: original.current.interaction,
        readOnlySource: exact,
      );
      final readonly = resolveDialogueWorkingSource(
        narrative: f.n,
        dialogueId: id,
      );
      expect(readonly.source!.source, exact);
      expect(readonly.dirty, false);
    },
  );
}

class _WorkingFixture {
  _WorkingFixture(this.f, this.maps, this.n, this.c);
  final M3StoryFixture f;
  final MapWorkspaceController maps;
  final NarrativeWorkspaceController n;
  final DialogueWorkspaceController c;
  static Future<_WorkingFixture> create() async {
    final f = await M3StoryFixture.create();
    final maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    final n = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    final c = DialogueWorkspaceController(
      n,
      LocalDialogueAdapter(session: f.session, mapAdapter: f.maps),
      changed: () {},
    );
    await n.openRecord(n.project.eventRegistry!.records.last);
    await c.open(n.active!.current.dialogue.entry.id);
    return _WorkingFixture(f, maps, n, c);
  }

  Future<void> dispose() async {
    c.dispose();
    n.dispose();
    maps.dispose();
    await f.directory.delete(recursive: true);
  }
}
