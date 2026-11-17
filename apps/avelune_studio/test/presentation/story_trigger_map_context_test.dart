import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'story_interactions_support.dart';
import 'story_memory_harness.dart';

void main() {
  testWidgets('cancelled creation clears the old narrative undo scope', (
    tester,
  ) async {
    await openInteractions(tester);
    await openInteractionRule(tester);
    await tester.enterText(
      find.descendant(
        of: interactionKey('map-story-behaviour-name-$guideTalk'),
        matching: find.byType(TextField),
      ),
      'Ancienne règle modifiée',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settleMemory(tester);
    await tester.tap(interactionKey('story-trigger-create'));
    await settleMemory(tester);
    await tester.tap(find.text('Annuler').last);
    await settleMemory(tester);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo).first)
          .onPressed,
      isNull,
    );
    expect(interactionKey('map-story-behaviour-name-$guideTalk'), findsNothing);
  });

  testWidgets(
    'empty-map creation from Construction opens Interactions explicitly',
    (tester) async {
      await openInteractions(tester);
      await tester.tap(interactionKey('map-space-construction'));
      await settleMemory(tester);
      await openWholeGame(tester);
      await filterInteractions(tester, 'empty');
      await tester.tap(interactionKey('story-trigger-create'));
      await settleMemory(tester);
      await tester.tap(interactionKey('story-trigger-create-map'));
      await settleMemory(tester);
      expect(interactionMaps(tester).active!.current.id, 'empty');
      expect(interactionKey('map-story-add'), findsOneWidget);
      expect(interactionKey('story-trigger-create-source'), findsNothing);
    },
  );

  testWidgets('a stale creation context explains its refusal and can reload', (
    tester,
  ) async {
    await openInteractions(tester);
    await openInteractionRule(tester);
    await filterInteractions(tester, 'b');
    await tester.tap(interactionKey('story-trigger-create'));
    await settleMemory(tester);
    final maps = interactionMaps(tester);
    maps.project = maps.project!.copyWith(name: 'Révision suivante');
    maps.notify();
    await settleMemory(tester);
    expect(find.textContaining('Ce contexte a changé'), findsOneWidget);
    expect(interactionKey('story-trigger-create-confirm'), findsNothing);
    await tester.tap(interactionKey('story-trigger-create-retry'));
    await settleMemory(tester);
    expect(interactionKey('story-trigger-create-source'), findsOneWidget);
    expect(maps.active!.current.id, 'a');
  });
  testWidgets(
    'map overview clears an unrelated editor and filters even an empty map',
    (tester) async {
      await openInteractions(tester);
      await openInteractionRule(tester);
      await tester.tap(interactionKey('story-return'));
      await settleMemory(tester);
      final maps = interactionMaps(tester);
      await maps.activate(maps.project!.maps.last);
      await settleMemory(tester);
      await tester.tap(interactionKey('map-story-open-history'));
      await settleMemory(tester);
      expect(interactionFilter(tester).value, 'empty');
      expect(find.text('Parler au guide'), findsNothing);
      expect(
        interactionKey('map-story-behaviour-name-$guideTalk'),
        findsNothing,
      );
      expect(interactionKey('story-trigger-create'), findsOneWidget);
      await tester.tap(interactionKey('story-trigger-create'));
      await settleMemory(tester);
      expect(interactionKey('story-trigger-create-source'), findsNothing);
      expect(interactionKey('story-trigger-create-map'), findsOneWidget);
    },
  );

  testWidgets(
    'creation in a filtered map only proposes its sources and keeps A active',
    (tester) async {
      await openInteractions(tester);
      await openInteractionRule(tester);
      final maps = interactionMaps(tester);
      final active = maps.active;
      await filterInteractions(tester, 'b');
      await tester.tap(find.text('DÉCLENCHEURS · 1'));
      await settleMemory(tester);
      final addOldSource = tester.widget<StudioButton>(
        interactionKey('map-story-behaviour-add'),
      );
      expect(addOldSource.onPressed, isNull);
      await tester.tap(interactionKey('story-trigger-create'));
      await settleMemory(tester);
      final source = tester.widget<StudioSelect>(
        interactionKey('story-trigger-create-source'),
      );
      expect(source.options.keys, ['entity:mother']);
      source.onChanged!('entity:mother');
      await settleMemory(tester);
      await tester.tap(interactionKey('story-trigger-create-confirm'));
      await settleMemory(tester);
      expect(maps.active, same(active));
      final binding = interactionBinding(tester);
      final draft = binding.behaviours
          .registry(binding.project!)!
          .records
          .where((record) => record.id != guideTalk && record.id != motherTalk)
          .single;
      expect(
        draft.source,
        NarrativeEventSourceRef.entityInteract('b', 'mother'),
      );
      expect(draft.enabledOrNull, isNot(true));
      expect(draft.sceneId, isNull);
      expect(
        interactionKey('map-story-behaviour-name-${draft.id}'),
        findsOneWidget,
      );
    },
  );
}
