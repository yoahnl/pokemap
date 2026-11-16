import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/story/story_behaviour_context.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';

import '../game_behaviours/game_behaviour_edit_support.dart';
import 'map_builder_story_support.dart';

import 'story_memory_harness.dart';

void main() {
  testWidgets('saving refreshes the explicit context and leaves it editable', (
    tester,
  ) async {
    final record = recordOnB();
    final fixture = await openStory(records: [record]);
    final catalog = openCatalogue(fixture, BehaviourMapLoader());
    expect(await catalog.open(record.id), isTrue);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: fixture.tick,
            builder: (context, _) => StoryBehaviourContext(
              catalog: catalog,
              openMap: (_) async => true,
              retry: catalog.open,
              editable: true,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(catalog.editor!.renameBehaviour(record, 'Nom enregistré'), isTrue);
    await tester.pump();
    expect(await fixture.story.save(), isTrue);
    await settleMemory(tester);
    final editor = catalog.editor!;
    expect(editor.project, same(fixture.maps.project));
    expect(editor.editing!.problem, isNull);
    expect(editor.selectedBehaviour!.name, 'Nom enregistré');
    expect(editor.renameBehaviour(editor.selectedBehaviour!, 'Suite'), isTrue);
  });

  testWidgets('an absent porter can still open its map for repair', (
    tester,
  ) async {
    final record = memoryProject.eventRegistry!.records.single.draftOrNull!;
    final project = memoryProject.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.draft(
            NarrativeEventDraft(
              id: record.id,
              name: record.name,
              source: NarrativeEventSourceRef.entityInteract('b', 'absent'),
              conditions: const [],
              priority: 0,
              order: 0,
            ),
          ),
        ],
        legacyClaims: const [],
      ),
    );
    await openMemoryStudio(
      tester,
      memoryIndex(),
      project: project,
      world: MapOnlyWorld.new,
    );
    await openWholeGame(tester);
    await tester.tap(find.text('Parler au guide'));
    await settleMemory(tester);
    expect(
      find.textContaining('Le porteur de ce comportement est absent'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('story-behaviour-view-map')));
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('studio-story')), findsNothing);
    expect(find.text('Jardin'), findsWidgets);
  });

  testWidgets(
    'Histoire opens its editor and only explicit navigation opens Carte',
    (tester) async {
      final index = memoryIndex();
      final maps = await openMemoryStudio(
        tester,
        index,
        world: MapOnlyWorld.new,
      );
      await openWholeGame(tester);
      await tester.tap(find.text('Parler au guide'));
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('studio-story')), findsOneWidget);
      final context = find.byKey(
        const ValueKey('story-behaviour-context-$guideTalk'),
      );
      expect(context, findsOneWidget);
      expect(
        find.descendant(
          of: context,
          matching: find.byKey(const ValueKey('map-story-tabs')),
        ),
        findsNothing,
      );
      final name = find.byKey(
        const ValueKey('map-story-behaviour-name-$guideTalk'),
      );
      await tester.enterText(
        find.descendant(of: name, matching: find.byType(TextField)),
        'Guide renommé',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await settleMemory(tester);
      expect(maps.writes, 0);
      expect(
        maps.manifest.eventRegistry!.records.single.draftOrNull!.name,
        'Parler au guide',
      );
      expect(find.text('Guide renommé'), findsWidgets);
      expect(find.textContaining('Ce comportement a changé'), findsNothing);
      final button = find.byKey(const ValueKey('story-behaviour-view-map'));
      final scroll = find
          .descendant(of: context, matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(button, 500, scrollable: scroll);
      await tester.tap(button);
      await settleMemory(tester);
      expect(find.byKey(const ValueKey('studio-story')), findsNothing);
      expect(find.text('Guide renommé'), findsWidgets);
    },
  );
}
