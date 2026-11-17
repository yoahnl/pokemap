import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

void main() {
  testWidgets(
    'local management shares history and preserves scene and dialogue',
    (tester) async {
      final fixture = await openStory(
        records: [storyRecord(1, sceneId: 'talk')],
        scenes: [storyLineScene('talk', 'shared')],
        dialogues: [
          storyLineDialogue('shared', ['Bonjour']),
        ],
      );
      final opened = <String>[];
      fixture.story.openInStory = (id) async => opened.add(id);
      await fixture.story.prepare();
      await pumpStoryInspector(tester, fixture);
      fixture.story.openTab(MapStoryTab.behaviour);
      await tester.pump();
      await tester.tap(
        _key('map-interaction-trigger-actions-${storyEventId(1)}'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Renommer'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getTopLeft(_key('map-story-behaviour-name-${storyEventId(1)}'))
            .dy,
        greaterThanOrEqualTo(
          tester.getBottomLeft(find.text('Cas 1').first).dy + 8,
        ),
      );
      await tester.enterText(
        find.descendant(
          of: _key('map-story-behaviour-name-${storyEventId(1)}'),
          matching: find.byType(TextField),
        ),
        'Rencontre',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(storyCurrent(fixture, storyEventId(1)).name, 'Rencontre');
      await tester.tap(_key('map-interaction-trigger-open-${storyEventId(1)}'));
      await tester.pumpAndSettle();
      expect(opened, [storyEventId(1)]);
      await tester.tap(_key('map-story-behaviour-add'));
      await tester.pumpAndSettle();
      final created = fixture.story.selectedBehaviour!;
      expect(created.draftOrNull, isNotNull);
      expect(created.sceneId, isNull);
      expect(created.enabledOrNull, isNot(true));
      expect(opened.last, created.id);
      await tester.tap(
        _key('map-interaction-trigger-actions-${storyEventId(1)}'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retirer le déclencheur'));
      await tester.pumpAndSettle();
      expect(_key('map-interaction-trigger-${storyEventId(1)}'), findsNothing);
      expect(fixture.story.sceneOf('talk'), fixture.maps.project!.scenes.last);
      expect(fixture.maps.project!.dialogues.single.id, 'shared');
      fixture.story.undo();
      await tester.pump();
      expect(storyCurrent(fixture, storyEventId(1)).name, 'Rencontre');
      expect(storyCurrent(fixture, storyEventId(1)).sceneId, 'talk');
      fixture.story.undo();
      fixture.story.undo();
      expect(fixture.story.dirty, isFalse);
    },
  );

  testWidgets('read-only cards allow navigation but no mutations', (
    tester,
  ) async {
    final fixture = await openStory(records: [storyRecord(1)]);
    final opened = <String>[];
    fixture.story.openInStory = (id) async => opened.add(id);
    await fixture.story.prepare();
    await pumpStoryInspector(tester, fixture, 'entity:luth', false);
    fixture.story.openTab(MapStoryTab.behaviour);
    await tester.pump();
    expect(
      tester.widget<StudioButton>(_key('map-story-behaviour-add')).onPressed,
      isNull,
    );
    final actions = tester
        .widget<StudioContextMenuButton>(
          _key('map-interaction-trigger-actions-${storyEventId(1)}'),
        )
        .items()
        .whereType<StudioContextMenuEntry>();
    expect(actions.every((action) => action.onSelected == null), isTrue);
    await tester.tap(_key('map-interaction-trigger-open-${storyEventId(1)}'));
    await tester.pump();
    expect(opened, [storyEventId(1)]);
    expect(fixture.story.dirty, isFalse);
  });

  testWidgets('cards retain simple OR and identify complex conditions', (
    tester,
  ) async {
    final first = NarrativeEventConditionExpression.any([
      NarrativeEventConditionLeaf(NarrativeEventCondition.fact('met', true)),
      NarrativeEventConditionLeaf(NarrativeEventCondition.fact('badge', false)),
    ]);
    final complex = NarrativeEventConditionExpression.all([
      first,
      NarrativeEventConditionExpression.not(
        NarrativeEventConditionLeaf(NarrativeEventCondition.fact('met', false)),
      ),
    ]);
    final fixture = await openStory(
      records: [
        storyRecord(1, expression: first),
        storyRecord(2, expression: complex, enabled: false, order: 1),
      ],
      facts: [
        NarrativeFactDefinition(
          id: 'met',
          label: 'Rencontré',
          defaultValue: false,
        ),
        NarrativeFactDefinition(
          id: 'badge',
          label: 'Badge',
          defaultValue: false,
        ),
      ],
    );
    await pumpStoryInspector(tester, fixture);
    fixture.story.openTab(MapStoryTab.behaviour);
    await tester.pump();
    expect(_key('map-interaction-trigger-${storyEventId(1)}'), findsOneWidget);
    expect(find.textContaining('Rencontré'), findsOneWidget);
    expect(find.textContaining(' ou '), findsOneWidget);
    expect(find.text('Expression complexe conservée'), findsOneWidget);
    expect(find.text('Scène scene-plain'), findsNWidgets(2));
    expect(find.text('Une seule fois'), findsNWidgets(2));
    expect(find.text('Modifier dans Histoire'), findsNWidgets(2));
    expect(
      storyCurrent(
        fixture,
        storyEventId(2),
      ).definitionOrNull!.conditionExpression,
      complex,
    );
    expect(fixture.story.dirty, isFalse);
  });

  testWidgets('missing scene remains explicit without showing raw ids', (
    tester,
  ) async {
    final fixture = await openStory(
      records: [storyRecord(1, sceneId: 'missing-secret-id')],
    );
    await pumpStoryInspector(tester, fixture);
    fixture.story.openTab(MapStoryTab.behaviour);
    await tester.pump();
    expect(find.text('Scène introuvable'), findsOneWidget);
    expect(find.text('À compléter'), findsOneWidget);
    expect(find.text('Compléter dans Histoire'), findsOneWidget);
    expect(find.textContaining('missing-secret-id'), findsNothing);
    expect(storyCurrent(fixture, storyEventId(1)).sceneId, 'missing-secret-id');
    expect(fixture.story.dirty, isFalse);
  });
}
