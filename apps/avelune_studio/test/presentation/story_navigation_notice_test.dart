import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/story/story_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'story_interactions_support.dart';
import 'story_memory_harness.dart';
import 'map_builder_story_harness.dart' as local;

void main() {
  testWidgets('repairing the refused destination clears its old notice', (
    tester,
  ) async {
    await openMemoryStudio(
      tester,
      memoryIndex(),
      world: MapOnlyWorld.new,
      project: memoryProject.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            interactionRecord(guideTalk, 'a', 'absent', 'Source absente'),
          ],
          legacyClaims: const [],
        ),
      ),
    );
    await openWholeGame(tester);
    final page = tester.widget<StoryPage>(find.byType(StoryPage));
    expect(await page.behaviours.open(guideTalk), isFalse);
    await settleMemory(tester);
    final notice = find.textContaining('Cet élément n’est plus disponible');
    expect(notice, findsOneWidget);
    final binding = interactionBinding(tester);
    binding.search('Guide');
    await settleMemory(tester);
    expect(notice, findsOneWidget);
    final record = binding.behaviours
        .registry(binding.project!)!
        .records
        .single;
    expect(
      binding.reassign(record, binding.elements!.byKey('entity:guide')!),
      isTrue,
    );
    await settleMemory(tester);
    expect(notice, findsNothing);
    expect(
      binding.behaviours.registry(binding.project!)!.records.single.source,
      NarrativeEventSourceRef.entityInteract('a', 'guide'),
    );
  });

  testWidgets('the pending counter follows the interface language', (
    tester,
  ) async {
    await local.open(tester);
    final locale = ValueNotifier(const Locale('fr'));
    addTearDown(locale.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<Locale>(
        valueListenable: locale,
        builder: (_, value, _) => MaterialApp(
          locale: value,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => MapBuilderStoryPanel(
                outline: mapBuilderSpaceOutline(
                  MapBuilderSpace.story,
                  AppLocalizations.of(context),
                )!,
                binding: local.story,
              ),
            ),
          ),
        ),
      ),
    );
    await settleMemory(tester);
    final counter = find.descendant(
      of: find.byKey(const ValueKey('map-story-pending')),
      matching: find.byType(Text),
    );
    expect(tester.widget<Text>(counter).data, contains('à configurer'));
    locale.value = const Locale('en');
    await settleMemory(tester);
    expect(
      tester.widget<Text>(counter).data,
      contains('to configure on this map'),
    );
    locale.value = const Locale('fr');
    await settleMemory(tester);
    expect(tester.widget<Text>(counter).data, contains('à configurer'));
  });
}
