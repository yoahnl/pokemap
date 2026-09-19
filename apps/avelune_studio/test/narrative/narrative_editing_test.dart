import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_draft_codec.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_editing_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'dialogue_draft_codec_test.dart' show dialogueFixture;

void main() {
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController narrative;
  late _Port port;
  late InteractionEditSession edit;
  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    port = _Port(maps);
    narrative = NarrativeWorkspaceController(
      maps,
      port,
      () {},
      (manifest, paths) async {},
    );
    edit = InteractionEditSession(
      document: maps.active!,
      dialogue: dialogueFixture(),
      interaction: NarrativeInteractionDraft(
        id: 'evt_00000000-0000-7000-8000-000000000001',
        name: 'Conversation',
        mapId: 'a',
        source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
        dialogueId: 'station',
        branches: {
          'accepted': [
            const NarrativeSequenceStep(
              kind: NarrativeSequenceKind.setFact,
              targetId: 'help',
            ),
          ],
        },
      ),
    );
    narrative.sessions[edit.current.interaction.id] = edit;
    narrative.active = edit;
  });
  tearDown(() => maps.dispose());

  test(
    'consultation and source outside visual subset never create a mutation',
    () async {
      expect(narrative.dirty, false);
      final original = const DialogueDraftCodec().encode(dialogueFixture());
      port.source = NarrativeDialogueSource(
        entry: original.entry,
        source: original.source.replaceFirst('---', '---\n<<unrepresented>>'),
      );
      await narrative.openSource(
        maps.active!,
        NarrativeEventSourceRef.entityInteract('a', 'other'),
        'Autre',
        existing: original.entry,
      );
      expect(narrative.active!.editable, false);
      final before = narrative.active!.current;
      DialogueEditingController(
        narrative.active!,
        () {},
      ).line(0, const DialogueLineDraft(text: 'Ne pas remplacer'));
      expect(narrative.active!.current, same(before));
      expect(narrative.dirty, false);
      expect(port.publications, isEmpty);
    },
  );

  test('new choice receives a matching scene outcome branch', () {
    DialogueEditingController(edit, () {}).addChoice();
    final outcome =
        edit.current.dialogue.branches.first.choices.last.outcomeId!;
    expect(edit.current.interaction.branches[outcome], isEmpty);
    expect(edit.current.interaction.branches['accepted'], hasLength(1));
    edit.restore(redo: false);
    expect(edit.current.interaction.branches.containsKey(outcome), false);
  });

  test('removing a choice removes its effects in the same undoable edit', () {
    final editor = DialogueEditingController(edit, () {});
    editor.removeChoice(0);
    expect(edit.current.interaction.branches, isEmpty);
    expect(edit.current.dialogue.branches.first.choices, hasLength(1));
    edit.restore(redo: false);
    expect(edit.current.interaction.branches.keys, ['accepted']);
    expect(edit.current.dialogue.branches.first.choices, hasLength(2));
    expect(edit.dirty, false);
    edit.restore(redo: true);
    expect(edit.current.interaction.branches, isEmpty);
  });

  test(
    'line order and named destinations are undoable and referenced branch deletion blocked',
    () {
      final editor = DialogueEditingController(edit, () {});
      editor.addLine();
      editor.line(1, const DialogueLineDraft(text: 'Deuxième'));
      editor.moveLine(1, -1);
      expect(editor.branch.lines.first.text, 'Deuxième');
      edit.restore(redo: false);
      expect(editor.branch.lines.last.text, 'Deuxième');
      edit.branchIndex = 1;
      expect(editor.removeBranch(), false);
    },
  );

  test(
    'failed save prevents closure and keeps the complete draft and pending facts',
    () async {
      DialogueEditingController(
        edit,
        () {},
      ).line(0, const DialogueLineDraft(text: 'Modifié'));
      narrative.addFact('Aide acceptée');
      port.fail = true;
      expect(await narrative.saveAll(), false);
      expect(edit.dirty, true);
      expect(narrative.pendingFacts, hasLength(1));
      expect(maps.active!.saving, false);
      expect(narrative.error, contains('Conflit'));
    },
  );

  test(
    'save acknowledges snapshot only and undo never restores stale source revision',
    () async {
      final editor = DialogueEditingController(edit, () {});
      editor.line(0, const DialogueLineDraft(text: 'Version A'));
      port.gate = Completer<void>();
      final saving = narrative.save();
      editor.line(0, const DialogueLineDraft(text: 'Version B'));
      maps.active!.commit(
        maps.active!.current.copyWith(name: 'Geste concurrent'),
      );
      port.gate!.complete();
      expect(await saving, true);
      expect(edit.dirty, true);
      expect(maps.active!.dirty, true);
      expect(
        edit.current.dialogue.branches.first.lines.first.text,
        'Version B',
      );
      port.gate = null;
      edit.restore(redo: false);
      edit.change(
        interaction: edit.current.interaction.revise(name: 'Titre après undo'),
      );
      expect(await narrative.save(), true);
      expect(port.publications.last.dialogues.single.revision, 'source-1');
      expect(edit.dirty, false);
    },
  );
}

class _Port implements NarrativePort {
  _Port(this.maps);
  final MapWorkspaceController maps;
  bool fail = false;
  Completer<void>? gate;
  NarrativeDialogueSource? source;
  final publications = <NarrativePublication>[];
  @override
  Future<NarrativeDialogueSource> readDialogue(
    ProjectDialogueEntry entry,
  ) async => source!;
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) async {
    publications.add(publication);
    await gate?.future;
    if (fail) throw const NarrativeFailure('Conflit externe');
    return NarrativePublicationReceipt(
      beforeManifest: maps.project!,
      manifest: maps.project!,
      savedMap: publication.current,
      revision: 'map-${publications.length}',
      sourceRevisions: {
        for (final source in publication.dialogues)
          source.entry.id: 'source-${publications.length}',
      },
      changedPaths: const [],
    );
  }
}
