import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';

import '../dialogues/dialogue_catalog_support.dart';

import 'story_memory_harness.dart';

void main() {
  testWidgets(
    'an unsupported preview keeps its source and exposes missing usage coverage',
    (tester) async {
      final h = DialogueCatalogHarness(count: 1);
      final original = h.port.documents['talk_0']!.dialogue;
      const source = 'unrepresented source preserved byte for byte';
      h.port.documents['talk_0'] = DialogueCatalogDocument(
        dialogue: StoryDialogueSource(entry: original.entry, source: source),
        sceneIds: const [],
        notCovered: const ['sceneDialogueIndex'],
      );
      final maps = await openMemoryStudio(
        tester,
        h.index,
        dialogueCatalog: h.port,
      );
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-dialogues')));
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-dialogue-talk_0')));
      await settleMemory(tester);
      expect(
        find.textContaining('Les appels de scènes ne sont pas couverts'),
        findsOneWidget,
      );
      expect(find.text('Aucun texte à prévisualiser.'), findsNothing);
      final button = find.byKey(const ValueKey('dialogue-catalog-source'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await settleMemory(tester);
      expect(find.text(source), findsOneWidget);
      expect(h.port.documents['talk_0']!.dialogue.source, source);
      expect(maps.writes, 0);
    },
  );

  testWidgets(
    'Dialogues opens a document library instead of routing to behaviours',
    (tester) async {
      await openMemoryStudio(tester, memoryIndex());
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-dialogues')));
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('story-dialogue-catalog')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-dialogue-behaviours')),
        findsNothing,
      );
    },
  );
  testWidgets(
    'visible documents have language states and preserve search on return',
    (tester) async {
      final h = DialogueCatalogHarness(count: 200);
      await openMemoryStudio(tester, h.index, dialogueCatalog: h.port);
      tester.view.physicalSize = const Size(1280, 720);
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-dialogues')));
      await settleMemory(tester);
      expect(h.port.requests.length, lessThan(15));
      expect(find.text('EN · Traduit'), findsWidgets);
      expect(find.text('ES · Manquant'), findsWidgets);
      await tester.enterText(
        find.byKey(const ValueKey('dialogue-catalog-search')),
        '199',
      );
      await settleMemory(tester);
      await tester.tap(find.byKey(const ValueKey('story-dialogue-talk_199')));
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('dialogue-document-talk_199')),
        findsOneWidget,
      );
      expect(find.text('Bonjour le monde.'), findsOneWidget);
      expect(find.textContaining('Usages partiels'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dialogue-catalog-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ES').last);
      await tester.pumpAndSettle();
      expect(find.text('Manquant'), findsOneWidget);
      expect(find.text('Repli : FR'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dialogue-catalog-back')));
      await settleMemory(tester);
      expect(
        tester
            .widget<StudioSearchField>(
              find.byKey(const ValueKey('dialogue-catalog-search')),
            )
            .controller
            .text,
        '199',
      );
      expect(
        find.byKey(const ValueKey('story-dialogue-talk_199')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('dialogue-catalog-search')),
        'UwU_introuvable',
      );
      await settleMemory(tester);
      expect(find.text('0 documents de dialogue'), findsOneWidget);
      expect(
        find.text('Aucun dialogue ne correspond à cette recherche.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed previews wait for explicit retry and do not hide their title',
    (tester) async {
      final h = DialogueCatalogHarness(count: 1);
      h.port.failure = StateError('missing source');
      await openMemoryStudio(tester, h.index, dialogueCatalog: h.port);
      await openTrame(tester);
      await tester.tap(find.byKey(const ValueKey('story-section-dialogues')));
      await settleMemory(tester);
      await settleMemory(tester);
      expect(h.port.requests, ['talk_0']);
      await tester.tap(find.byKey(const ValueKey('story-dialogue-talk_0')));
      await settleMemory(tester);
      expect(h.port.requests, ['talk_0']);
      await settleMemory(tester);
      expect(h.port.requests, ['talk_0']);
      h.port.failure = null;
      await tester.tap(find.widgetWithText(StudioButton, 'Réessayer'));
      await settleMemory(tester);
      expect(
        find.byKey(const ValueKey('dialogue-document-talk_0')),
        findsOneWidget,
      );
      expect(h.port.requests, ['talk_0', 'talk_0']);
    },
  );
}
