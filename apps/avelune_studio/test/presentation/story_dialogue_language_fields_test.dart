import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dialogues/dialogue_catalog_support.dart';

import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';

import 'story_memory_harness.dart';

void main() {
  testWidgets(
    'an unrepresentable legacy document stays readable without opening an editor',
    (tester) async {
      final h = DialogueCatalogHarness(count: 1);
      final original = catalogDialogue('talk_0', localized: false);
      const source = 'title: Start\n---\nLuth:\n===\n';
      h.port.documents['talk_0'] = DialogueCatalogDocument(
        dialogue: StoryDialogueSource(
          entry: original.entry,
          source: source,
          revision: original.revision,
        ),
        sceneIds: const [],
        notCovered: const [],
      );
      await openMemoryStudio(
        tester,
        h.index,
        dialogueCatalog: h.port,
        project: memoryProject.copyWith(dialogues: [original.entry]),
      );
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-dialogues')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-dialogue-talk_0')));
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('dialogue-document-edit')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('dialogue-catalog-source')));
      await tester.pumpAndSettle();
      expect(find.text(source), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'an empty source stays recoverable and Cancel leaves no draft',
    (tester) async {
      final h = DialogueCatalogHarness(count: 1);
      final maps = await openMemoryStudio(
        tester,
        h.index,
        dialogueCatalog: h.port,
        project: memoryProject.copyWith(
          dialogues: [h.port.documents['talk_0']!.dialogue.entry],
        ),
      );
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-dialogues')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-dialogue-talk_0')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('dialogue-document-edit')));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('dialogue-editor-source'));
      await tester.enterText(field, '   ');
      await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<StudioDraftField>(field).value,
        '   ',
      );
      expect(
        find.textContaining('Impossible d’appliquer ces textes'),
        findsOneWidget,
      );
      await tester.tap(find.text('Annuler').last);
      await tester.pumpAndSettle();
      expect(find.text('Bonjour le monde.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dialogue-document-edit')));
      await tester.pumpAndSettle();
      expect(tester.widget<StudioDraftField>(field).value, 'Bonjour le monde.');
      expect(maps.writes, 0);
    },
  );
  testWidgets('the editor uses the configured project fallback', (
    tester,
  ) async {
    final h = DialogueCatalogHarness(count: 1);
    h.port.profile = const DialogueCatalogLanguages(
      locales: ['fr', 'en', 'es'],
      fallback: 'en',
    );
    await openMemoryStudio(
      tester,
      h.index,
      dialogueCatalog: h.port,
      project: memoryProject.copyWith(
        dialogues: [h.port.documents['talk_0']!.dialogue.entry],
      ),
    );
    await openTrame(tester);
    await tester.tap(find.byKey(const ValueKey('story-section-dialogues')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('story-dialogue-talk_0')));
    await settleMemory(tester);
    await tester.tap(find.byKey(const ValueKey('dialogue-document-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dialogue-editor-language')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ES').last);
    await tester.pumpAndSettle();
    expect(find.text('Repli : EN'), findsOneWidget);
    expect(find.text('Hello world.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('dialogue-editor-source')),
      'Salut !',
    );
    await tester.pumpAndSettle();
    expect(find.text('À revoir'), findsWidgets);
    expect(find.byKey(const ValueKey('dialogue-editor-review')), findsNothing);
  });

  testWidgets(
    'source and translation share a form and the common draft history',
    (tester) async {
      final h = DialogueCatalogHarness(count: 1);
      final maps = await openMemoryStudio(
        tester,
        h.index,
        dialogueCatalog: h.port,
        project: memoryProject.copyWith(
          dialogues: [h.port.documents['talk_0']!.dialogue.entry],
        ),
      );
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-dialogues')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-dialogue-talk_0')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('dialogue-document-edit')));
      await settleMemory(tester);
      final source = find.byKey(const ValueKey('dialogue-editor-source'));
      final translation = find.byKey(
        const ValueKey('dialogue-editor-translation'),
      );
      expect(
        tester.widget<StudioDraftField>(source).value,
        'Bonjour le monde.',
      );
      expect(
        tester.widget<StudioDraftField>(translation).value,
        'Hello world.',
      );
      await tester.enterText(source, 'Nouveau locuteur : (Salut le monde.)');
      await settleMemory(tester);
      expect(find.text('À revoir'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('dialogue-editor-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ES').last);
      await tester.pumpAndSettle();
      expect(find.text('Repli : FR'), findsOneWidget);
      await tester.enterText(translation, 'Hola mundo.');
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('dialogue-editor-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EN').last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<StudioDraftField>(translation).value,
        'Hello world.',
      );
      await tester.tap(find.byKey(const ValueKey('confirm-reviewed-plan')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('dialogue-editor-source')),
        findsNothing,
      );
      expect(find.text('Nouveau locuteur : (Salut le monde.)'), findsOneWidget);
      expect(maps.writes, 0);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await settleMemory(tester);
      expect(find.text('Bonjour le monde.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
