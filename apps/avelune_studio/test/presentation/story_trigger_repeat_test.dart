import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';
import 'story_trigger_support.dart';

SceneAsset rearmScene() {
  final json = storyPlainScene('result').toJson();
  json['declaredOutcomes'] = [
    {'id': 'ready', 'label': 'Prêt à repartir'},
  ];
  final nodes = (json['graph'] as Map)['nodes'] as List;
  (nodes.last as Map)['payload'] = {'sceneOutcomeId': 'ready'};
  return SceneAsset.fromJson(json);
}

void main() {
  testWidgets(
    'rearm requires a real emitted outcome and participates in history',
    (tester) async {
      final fixture = await openStory(
        records: [storyRecord(1)],
        scenes: [rearmScene()],
      );
      await pumpTrigger(tester, fixture);
      final after = tester.widget<StudioSelect>(triggerKey('map-story-after'));
      expect(after.options.keys, contains('onceUntilOutcome'));
      final menu = triggerKey('map-story-after');
      await tester.ensureVisible(menu);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Une fois, puis après un résultat').last);
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: menu,
        matching: find.byType(DropdownButtonFormField<String>),
      );
      expect(tester.state<FormFieldState<String>>(field).value, 'once');
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Une fois, puis après un résultat').last);
      await tester.pumpAndSettle();
      expect(tester.state<FormFieldState<String>>(field).value, 'once');
      expect(
        storyCurrent(fixture, storyEventId(1)).resetPolicy,
        const NarrativeEventResetPolicy.never(),
      );
      expect(fixture.story.dirty, isFalse);
      final outcome = tester.widget<StudioSelect>(
        triggerKey('story-trigger-rearm-outcome'),
      );
      final selected = outcome.options.entries.singleWhere(
        (entry) => entry.value.contains('Prêt à repartir'),
      );
      outcome.onChanged!(selected.key);
      await tester.pump();
      final expected = NarrativeEventResetPolicy.onOutcomeReceived(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'result',
          outcomeId: 'ready',
        ),
      );
      expect(storyCurrent(fixture, storyEventId(1)).resetPolicy, expected);
      expect(storyCurrent(fixture, storyEventId(1)).enabledOrNull, isTrue);
      fixture.story.undo();
      expect(
        storyCurrent(fixture, storyEventId(1)).resetPolicy,
        const NarrativeEventResetPolicy.never(),
      );
      fixture.story.redo();
      expect(storyCurrent(fixture, storyEventId(1)).resetPolicy, expected);
    },
  );

  testWidgets(
    'parallel events retain their native execution policy on refusal',
    (tester) async {
      final json = storyRecord(
        1,
        source: NarrativeEventSourceRef.mapEnter('a'),
        reuse: NarrativeEventReusePolicy.reusable,
      ).toJson();
      (json['definition'] as Map)['parallelPolicy'] = {'cadenceMs': 1500};
      final record = NarrativeEventRecord.fromJson(json);
      final fixture = await openStory(records: [record]);
      await pumpTrigger(tester, fixture);
      fixture.story.select(storyElement(fixture, 'map:a'));
      await tester.pump();
      tester.widget<StudioSelect>(triggerKey('map-story-after')).onChanged!(
        'once',
      );
      await tester.pump();
      expect(storyCurrent(fixture, record.id), record);
      expect(fixture.story.dirty, isFalse);
      expect(
        tester.widget<StudioSelect>(triggerKey('map-story-after')).value,
        'eachTime',
      );
      expect(find.textContaining('Événement parallèle'), findsOneWidget);
    },
  );
}
