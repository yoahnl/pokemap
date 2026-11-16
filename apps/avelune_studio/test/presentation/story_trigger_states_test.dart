import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/story/story_behaviour_context.dart';
import 'package:avelune_studio/presentation/features/story/behaviours/game_behaviour_editor.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../game_behaviours/game_behaviour_edit_support.dart';
import 'map_builder_story_support.dart';
import 'story_memory_harness.dart';

void main() {
  testWidgets('a refused repetition restores the actual dropdown selection', (
    tester,
  ) async {
    final outcome = NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'scene-plain',
      outcomeId: 'won',
    );
    final record = storyRecord(
      1,
      enabled: false,
      reset: NarrativeEventResetPolicy.onOutcomeReceived(outcome),
    );
    final fixture = await openStory(records: [record]);
    fixture.story.select(storyElement(fixture));
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: fixture.tick,
            builder: (context, _) => SingleChildScrollView(
              child: GameBehaviourEditor(
                binding: fixture.story,
                editable: true,
              ),
            ),
          ),
        ),
      ),
    );
    final select = find.byKey(const ValueKey('map-story-after'));
    await tester.ensureVisible(select);
    await tester.tap(select);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Une seule fois').last);
    await tester.pumpAndSettle();
    final form = find.descendant(
      of: select,
      matching: find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<String>,
      ),
    );
    expect(
      tester.state<FormFieldState<String>>(form).value,
      'onceUntilOutcome',
    );
    expect(fixture.story.behaviours.draft.touchedRefs, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and failed trigger indexes never create a draft', (
    tester,
  ) async {
    final pending = Completer<List<NarrativeTitle>>();
    final index = memoryIndex()
      ..titleLoader = (kind) async =>
          kind == NarrativeTitleKind.events ? pending.future : [];
    final maps = await openMemoryStudio(tester, index, world: MapOnlyWorld.new);
    await openWholeGame(tester);
    expect(find.text('Lecture des déclencheurs…'), findsOneWidget);
    expect(find.byKey(const ValueKey('behaviour-$guideTalk')), findsNothing);
    pending.completeError(const NarrativeIndexUnavailable());
    await settleMemory(tester);
    expect(find.byKey(const ValueKey('behaviour-$guideTalk')), findsNothing);
    expect(
      find.byKey(const ValueKey('story-trigger-workspace')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('memory-unavailable')), findsOneWidget);
    expect(find.textContaining('NarrativeIndexUnavailable'), findsNothing);
    expect(maps.writes, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only central editing disables every mutation control', (
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
          body: StoryBehaviourContext(
            catalog: catalog,
            openMap: (_) async => true,
            retry: catalog.open,
            editable: false,
            onSelected: (_) {},
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<MapBuilderNameField>(
            find.byKey(ValueKey('map-story-behaviour-name-${record.id}')),
          )
          .enabled,
      isFalse,
    );
    expect(
      tester
          .widget<StudioToggleRow>(
            find.byKey(const ValueKey('map-story-behaviour-active')),
          )
          .onChanged,
      isNull,
    );
    for (final key in ['map-story-when', 'map-story-after']) {
      expect(
        tester.widget<StudioSelect>(find.byKey(ValueKey(key))).onChanged,
        isNull,
      );
    }
    expect(
      tester
          .widget<StudioButton>(
            find.byKey(const ValueKey('map-story-behaviour-delete')),
          )
          .onPressed,
      isNull,
    );
    expect(fixture.story.dirty, isFalse);
    expect(tester.takeException(), isNull);
  });
}
