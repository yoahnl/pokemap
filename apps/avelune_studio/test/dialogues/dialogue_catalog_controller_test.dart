import 'dart:async';

import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_preview.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dialogue_catalog_support.dart';

void main() {
  test(
    'overlapping opens do not attribute old titles to a new revision',
    () async {
      final h = DialogueCatalogHarness();
      final firstRead = Completer<List<NarrativeTitle>>();
      var reads = 0;
      h.index.titleLoader = (_) async => ++reads == 1
          ? firstRead.future
          : const [NarrativeTitle(id: 'new', title: 'Nouveau document')];
      final first = h.controller.open();
      h.revision = Object();
      final second = h.controller.open();
      firstRead.complete(const [
        NarrativeTitle(id: 'old', title: 'Ancien document'),
      ]);
      await Future.wait([first, second]);
      h.controller.sync();
      expect(reads, 2);
      expect(h.controller.rows.single.title, 'Nouveau document');
      expect(h.controller.stale, isFalse);
    },
  );

  test(
    'reopening after a revision change reloads the selected document',
    () async {
      final h = DialogueCatalogHarness();
      await h.controller.open();
      await h.controller.load('talk_0');
      h.controller.filter('talk');
      h.controller.previewIn('en');
      final previous = h.port.documents['talk_0']!;
      h.port.documents['talk_0'] = DialogueCatalogDocument(
        dialogue: StoryDialogueSource(
          entry: previous.dialogue.entry,
          source: 'title: Start\n---\nTexte actualisé.\n===\n',
        ),
        sceneIds: previous.sceneIds,
        notCovered: previous.notCovered,
      );
      h.revision = Object();
      await h.controller.open();
      await h.controller.load('talk_0');
      expect(
        h.controller.document('talk_0')!.dialogue.source,
        contains('Texte actualisé.'),
      );
      expect(h.controller.stale, isFalse);
      expect(h.controller.query, 'talk');
      expect(h.controller.language, 'en');
      expect(h.port.requests, ['talk_0', 'talk_0']);
    },
  );

  test(
    'refreshing a profile reconciles a language no longer offered',
    () async {
      final h = DialogueCatalogHarness();
      await h.controller.open();
      h.controller.previewIn('en');
      h.port.profile = const DialogueCatalogLanguages(
        locales: ['fr'],
        fallback: 'fr',
      );
      await h.controller.open(force: true);
      expect(h.controller.language, 'source');
    },
  );

  test(
    'a language discovered in another document remains missing here',
    () async {
      final h = DialogueCatalogHarness();
      h.port.profile = const DialogueCatalogLanguages();
      final original = h.port.documents['talk_1']!;
      final source = original.dialogue;
      final localized = source.entry.localization!;
      h.port.documents['talk_1'] = DialogueCatalogDocument(
        dialogue: StoryDialogueSource(
          entry: source.entry.copyWith(
            localization: localized.translate(
              localized.units.single.id,
              'es',
              'Hola.',
            ),
          ),
          source: source.source,
        ),
        sceneIds: original.sceneIds,
        notCovered: original.notCovered,
      );
      await h.controller.open();
      await h.controller.load('talk_0');
      await h.controller.load('talk_1');
      expect(h.controller.locales, contains('es'));
      h.controller.previewIn('es');
      expect(
        h.controller.preview('talk_0')!.status,
        DialogueCatalogStatus.missing,
      );
      expect(h.controller.preview('talk_0')!.fallback, isTrue);
    },
  );

  test(
    'configured project languages do not silently expand from loaded documents',
    () async {
      final h = DialogueCatalogHarness();
      h.port.profile = const DialogueCatalogLanguages(
        locales: ['fr'],
        fallback: 'fr',
      );
      await h.controller.open();
      await h.controller.load('talk_0');
      expect(h.controller.locales, ['fr']);
    },
  );

  test('opening only reads titles and language configuration', () async {
    final h = DialogueCatalogHarness(count: 500);
    await h.controller.open();
    expect(h.index.titleRequests, [NarrativeTitleKind.dialogues]);
    expect(h.port.requests, isEmpty);
    expect(h.port.languageReads, 1);
    expect(h.controller.rows, hasLength(500));
    expect(h.draft.touchedRefs, isEmpty);
    expect(h.draft.canUndo, isFalse);
  });

  test(
    'preview distinguishes source, translation and missing with fallback',
    () async {
      final h = DialogueCatalogHarness();
      await h.controller.open();
      await h.controller.load('talk_0');
      expect(
        h.controller.preview('talk_0')!.status,
        DialogueCatalogStatus.source,
      );
      h.controller.previewIn('en');
      expect(h.controller.preview('talk_0')!.texts, ['Hello world.']);
      expect(
        h.controller.preview('talk_0')!.status,
        DialogueCatalogStatus.translated,
      );
      h.controller.previewIn('es');
      final missing = h.controller.preview('talk_0')!;
      expect(missing.status, DialogueCatalogStatus.missing);
      expect(missing.fallback, isTrue);
      expect(missing.textLocales, {'fr'});
      expect(missing.texts, ['Bonjour le monde.']);
      expect(h.port.requests, ['talk_0']);
    },
  );

  test(
    'source edits in the common draft invalidate only their own preview',
    () async {
      final h = DialogueCatalogHarness();
      await h.controller.open();
      await h.controller.load('talk_0');
      final source = h.controller.document('talk_0')!.dialogue;
      final previous = source.entry.localization!;
      final updated = previous.withUnits([
        previous.units.single.copyWith(source: 'Salut le monde.'),
      ]);
      h.draft.load(StoryDraftKind.dialogue, source.id, source);
      h.draft.put(
        StoryDraftKind.dialogue,
        StoryDialogueSource(
          entry: source.entry.copyWith(localization: updated),
          source: source.source.replaceFirst('Bonjour', 'Salut'),
        ),
      );
      h.controller.previewIn('en');
      expect(
        h.controller.preview('talk_0')!.status,
        DialogueCatalogStatus.needsReview,
      );
      expect(h.controller.preview('talk_0')!.texts, ['Hello world.']);
      h.draft.undo();
      expect(
        h.controller.preview('talk_0')!.status,
        DialogueCatalogStatus.translated,
      );
      expect(h.port.requests, ['talk_0']);
    },
  );

  test(
    'an unlocalized source is not assigned the interface language',
    () async {
      final h = DialogueCatalogHarness();
      h.port.documents['talk_0'] = DialogueCatalogDocument(
        dialogue: catalogDialogue('talk_0', localized: false),
        sceneIds: const [],
        notCovered: const ['cinematics'],
      );
      await h.controller.open();
      await h.controller.load('talk_0');
      h.controller.previewIn('en');
      expect(
        h.controller.preview('talk_0')!.status,
        DialogueCatalogStatus.unlocalized,
      );
      expect(h.controller.preview('talk_0')!.textLocales, isEmpty);
      expect(h.controller.preview('talk_0')!.texts, ['Bonjour le monde.']);
      expect(h.draft.touchedRefs, isEmpty);
    },
  );

  test(
    'filter and document navigation preserve identity without new objects',
    () async {
      final h = DialogueCatalogHarness();
      await h.controller.open();
      h.controller.filter('1');
      h.controller.select('talk_1');
      await h.controller.load('talk_1');
      h.controller.back();
      expect(h.controller.query, '1');
      expect(h.controller.selectedId, 'talk_1');
      expect(h.controller.visibleRows.single.id, 'talk_1');
      expect(h.draft.touchedRefs, isEmpty);
    },
  );

  test(
    'parallel and late reads do not replace the selected document',
    () async {
      final h = DialogueCatalogHarness();
      final late = Completer<DialogueCatalogDocument>();
      h.port.loader = (id) async =>
          id == 'talk_0' ? late.future : h.port.documents[id]!;
      await h.controller.open();
      h.controller.select('talk_0');
      final first = h.controller.load('talk_0');
      await h.controller.load('talk_0');
      h.controller.select('talk_1');
      await h.controller.load('talk_1');
      late.complete(h.port.documents['talk_0']);
      await first;
      expect(h.controller.selectedId, 'talk_1');
      expect(h.port.requests, ['talk_0', 'talk_1']);
    },
  );

  test(
    'an unsupported or mismatched document is never rewritten for preview',
    () async {
      final h = DialogueCatalogHarness();
      final saved = h.port.documents['talk_0']!;
      h.port.documents['talk_0'] = DialogueCatalogDocument(
        dialogue: StoryDialogueSource(
          entry: saved.dialogue.entry,
          source: 'invalid',
        ),
        sceneIds: saved.sceneIds,
        notCovered: saved.notCovered,
      );
      await h.controller.open();
      await h.controller.load('talk_0');
      expect(
        h.controller.preview('talk_0')!.status,
        DialogueCatalogStatus.unsupported,
      );
      expect(h.draft.touchedRefs, isEmpty);
      expect(h.controller.document('talk_0')!.dialogue.source, 'invalid');
    },
  );

  test(
    'saved revision changes are explicit and do not trigger global reads',
    () async {
      final h = DialogueCatalogHarness();
      await h.controller.open();
      h.revision = Object();
      h.controller.sync();
      expect(h.controller.stale, isTrue);
      expect(h.index.titleRequests, hasLength(1));
      expect(h.port.requests, isEmpty);
    },
  );
}
