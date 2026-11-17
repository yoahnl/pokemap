import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';
import 'story_trigger_support.dart';

void main() {
  testWidgets(
    'simulation uses temporary values without staging or publishing facts',
    (tester) async {
      final fact = NarrativeFactDefinition(id: 'gate', label: 'Porte ouverte');
      final fixture = await openStory(
        facts: [fact],
        records: [
          storyRecord(
            1,
            expression: NarrativeEventConditionExpression.leaf(
              NarrativeEventCondition.fact('gate', true),
            ),
          ),
          storyRecord(2, order: 1),
        ],
      );
      await pumpTrigger(tester, fixture);
      final open = triggerKey('map-story-simulate');
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pump();
      expect(find.text('C’est « Cas 2 » qui se déclenche.'), findsOneWidget);
      final toggle = tester.widget<StudioToggleRow>(
        triggerKey('map-story-simulation-fact-gate'),
      );
      toggle.onChanged!(true);
      await tester.pump();
      expect(find.text('C’est « Cas 1 » qui se déclenche.'), findsOneWidget);
      expect(fixture.maps.project!.facts.single, fact);
      expect(fixture.story.behaviours.draft.touchedRefs, isEmpty);
      expect(fixture.ports.calls, isEmpty);
    },
  );
}
