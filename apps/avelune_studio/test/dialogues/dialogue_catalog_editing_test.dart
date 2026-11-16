import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_controller.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_editing.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_draft_host.dart';
import 'package:avelune_studio/features/dialogues/application/dialogue_localization_editing.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/application/story_saved_dialogues.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogue_catalog_support.dart';

final class _Host implements DialogueDraftHost {
  @override
  final draft = StoryDraft();
  final saved = StorySavedDialogues();
  @override
  bool editable = true;
  @override
  void rememberDialogue(StoryDialogueSource source) => saved.remember(source);
  @override
  StoryDialogueSource? savedDialogue(String id) => saved[id];
  @override
  void stage(void Function(StoryDraft) edit) => draft.group(() => edit(draft));
}

Future<(DialogueCatalogController, _Host)> setup() async {
  final h = DialogueCatalogHarness();
  final host = _Host();
  final catalog = DialogueCatalogController(
    index: h.index,
    port: h.port,
    draft: host.draft,
    revision: () => h.revision,
    changed: () {},
    editing: host,
  );
  await catalog.open();
  await catalog.load('talk_0');
  return (catalog, host);
}

void main() {
  test(
    'an unrelated project revision does not invalidate the document form',
    () async {
      final h = DialogueCatalogHarness();
      final host = _Host();
      Object revision = Object();
      final catalog = DialogueCatalogController(
        index: h.index,
        port: h.port,
        draft: host.draft,
        revision: () => revision,
        changed: () {},
        editing: host,
      );
      await catalog.open();
      await catalog.load('talk_0');
      final form = DialogueLocalizationEditing(
        catalog.document('talk_0')!.dialogue,
      );
      form.writeSource(form.localization.units.single.id, 'Salut.');
      revision = Object();
      catalog.applyEditing(form);
      expect(catalog.document('talk_0')!.dialogue.source, contains('Salut.'));
    },
  );

  test('editing uses the saved baseline and the shared undo history', () async {
    final (catalog, host) = await setup();
    final original = catalog.document('talk_0')!.dialogue;
    final edit = DialogueLocalizationEditing(original);
    edit.writeSource(edit.localization.units.single.id, 'Salut le monde.');
    catalog.applyEditing(edit);
    expect(host.saved['talk_0'], original);
    expect(
      host.draft.changesOf(StoryDraftKind.dialogue, host.saved),
      hasLength(1),
    );
    expect(host.draft.recorded, 1);
    expect(catalog.document('talk_0')!.dialogue.source, contains('Salut'));
    host.draft.undo();
    expect(catalog.document('talk_0')!.dialogue, original);
    host.draft.redo();
    expect(catalog.document('talk_0')!.dialogue.source, contains('Salut'));
  });

  test(
    'a copy has fresh identities and undo does not resurrect a cached draft',
    () async {
      final (catalog, host) = await setup();
      final original = catalog.document('talk_0')!.dialogue;
      final id = catalog.copyEditing(
        DialogueLocalizationEditing(original),
        'Copie',
      );
      await catalog.load(id);
      final copy = catalog.document(id)!.dialogue;
      expect(copy.id, isNot(original.id));
      expect(
        copy.entry.localization!.units.single.id,
        isNot(original.entry.localization!.units.single.id),
      );
      expect(
        copy.entry.localization!.units.single.translations,
        original.entry.localization!.units.single.translations,
      );
      expect(catalog.document('talk_0')!.dialogue, original);
      expect(catalog.document(id)!.sceneIds, isEmpty);
      host.draft.undo();
      expect(catalog.document(id), isNull);
      host.draft.redo();
      expect(catalog.document(id)!.dialogue, copy);
    },
  );

  test(
    'read-only and concurrent edits preserve the current document',
    () async {
      final (catalog, host) = await setup();
      final original = catalog.document('talk_0')!.dialogue;
      final stale = DialogueLocalizationEditing(original);
      host.editable = false;
      expect(() => catalog.applyEditing(stale), throwsStateError);
      expect(() => catalog.copyEditing(stale, 'Copie'), throwsStateError);
      expect(host.draft.canUndo, isFalse);
      host.editable = true;
      final newer = DialogueLocalizationEditing(original);
      newer.writeSource(newer.localization.units.single.id, 'Texte récent.');
      catalog.applyEditing(newer);
      stale.writeSource(stale.localization.units.single.id, 'Texte obsolète.');
      expect(() => catalog.applyEditing(stale), throwsStateError);
      expect(
        catalog.document('talk_0')!.dialogue.source,
        contains('Texte récent.'),
      );
      expect(host.draft.recorded, 1);
    },
  );
}
