import 'dart:convert';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/application/behaviour/behaviour_conditions.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/story_draft/domain/story_draft_entry.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_story_support.dart';

final _met = NarrativeFactDefinition(id: 'fact_met', label: 'Rencontré');
final _count = NarrativeFactDefinition(
  id: 'fact_count',
  label: 'Badges',
  initialValue: NarrativeValue.integer(0),
);

NarrativeEventConditionExpression _leaf(NarrativeEventCondition condition) =>
    NarrativeEventConditionExpression.leaf(condition);

final _fixedCompare = _leaf(
  NarrativeEventCondition.factValue(
    'fact_count',
    operator: NarrativeFactOperator.greaterThan,
    expectedValue: NarrativeValue.integer(3),
  ),
);

final _fixedAny = NarrativeEventConditionExpression.any([
  _leaf(NarrativeEventCondition.fact('fact_met', false)),
  _leaf(
    NarrativeEventCondition.factValue(
      'fact_count',
      operator: NarrativeFactOperator.equals,
      expectedValue: NarrativeValue.integer(1),
    ),
  ),
]);

Future<StoryFixture> _open() => openStory(
  facts: [_met, _count],
  records: [
    storyRecord(
      1,
      expression: NarrativeEventConditionExpression.all([
        _leaf(NarrativeEventCondition.fact('fact_met', true)),
        _fixedCompare,
        _fixedAny,
      ]),
    ),
  ],
);

String _json(NarrativeEventConditionExpression expression) =>
    jsonEncode(expression.toJson());

void main() {
  test('editing a condition keeps the other forms byte for byte', () async {
    final fixture = await _open();
    final story = fixture.story;
    final record = storyCurrent(fixture, storyEventId(1));
    final conditions = story.conditionsOf(record);
    expect(conditions.items.map((item) => item.runtimeType), [
      BehaviourEditableCondition,
      BehaviourFixedCondition,
      BehaviourFixedCondition,
    ]);

    expect(
      story.setConditions(
        record,
        conditions.replacing(0, BehaviourEditableCondition.isFalse('fact_met')),
      ),
      isTrue,
      reason: story.error,
    );

    final edited = storyCurrent(fixture, storyEventId(1));
    final root = edited.expression as NarrativeEventConditionAll;
    expect(root.children, hasLength(3));
    expect(
      _json(root.children.first),
      _json(_leaf(NarrativeEventCondition.fact('fact_met', false))),
    );
    expect(_json(root.children[1]), _json(_fixedCompare));
    expect(_json(root.children[2]), _json(_fixedAny));
    expect(edited.enabledOrNull, isTrue);
    expect(story.error, isNull);

    expect(
      story.setConditions(
        edited,
        story
            .conditionsOf(edited)
            .adding(BehaviourEditableCondition.equalsNumber('fact_count', 2)),
      ),
      isTrue,
    );
    final added = storyCurrent(fixture, storyEventId(1));
    final children = (added.expression as NarrativeEventConditionAll).children;
    expect(children, hasLength(4));
    expect(_json(children[1]), _json(_fixedCompare));
    expect(_json(children[2]), _json(_fixedAny));
  });

  test('a new fact is created in place and published first', () async {
    final fixture = await _open();
    final story = fixture.story;
    final record = storyCurrent(fixture, storyEventId(1));

    expect(
      story.addConditionOnNewFact(
        record,
        'Badge obtenu',
        NarrativeValueKind.boolean,
      ),
      isTrue,
      reason: story.error,
    );

    expect(
      [...story.behaviours.draft.touched(StoryDraftKind.fact)],
      ['fact_badge_obtenu'],
    );
    final edited = storyCurrent(fixture, storyEventId(1));
    final last = story.conditionsOf(edited).items.last;
    expect(last, isA<BehaviourEditableCondition>());
    expect((last as BehaviourEditableCondition).factId, 'fact_badge_obtenu');
    expect(
      story.conditionFacts.map((fact) => fact.id),
      contains('fact_badge_obtenu'),
    );

    story.undo();
    expect(story.behaviours.draft.touchedRefs, isEmpty);
    story.redo();

    expect(await story.save(), isTrue, reason: story.error);
    expect(fixture.ports.calls, [
      'fact fact_badge_obtenu',
      'event ${storyEventId(1)}',
    ]);
    expect(
      fixture.maps.project!.facts.map((fact) => fact.id),
      contains('fact_badge_obtenu'),
    );
    expect(story.dirty, isFalse);
  });

  testWidgets('the conditions editor edits facts and shows fixed forms', (
    tester,
  ) async {
    final fixture = await _open();
    await pumpStoryInspector(tester, fixture);
    Finder key(String value) => find.byKey(ValueKey(value));

    expect(key('map-story-condition-0'), findsOneWidget);
    expect(key('map-story-condition-fixed-1'), findsOneWidget);
    expect(key('map-story-condition-fixed-2'), findsOneWidget);
    expect(find.text('et'), findsNWidgets(2));
    expect(find.text('Rencontré'), findsWidgets);

    tester
        .widget<StudioSelect>(
          find.descendant(
            of: key('map-story-condition-0'),
            matching: key('map-story-condition-test'),
          ),
        )
        .onChanged!('isFalse');
    await tester.pump();
    final first =
        (storyCurrent(fixture, storyEventId(1)).expression
                as NarrativeEventConditionAll)
            .children
            .first;
    expect(
      _json(first),
      _json(_leaf(NarrativeEventCondition.fact('fact_met', false))),
    );

    await tester.tap(key('map-story-condition-add'));
    await tester.pump();
    expect(key('map-story-fact-picker'), findsOneWidget);
    await tester.enterText(key('map-story-fact-search'), 'badg');
    await tester.pump();
    expect(key('map-story-fact-fact_met'), findsNothing);
    await tester.tap(key('map-story-fact-fact_count'));
    await tester.pump();

    final items = fixture.story
        .conditionsOf(storyCurrent(fixture, storyEventId(1)))
        .items;
    expect(items, hasLength(4));
    final added = items.last as BehaviourEditableCondition;
    expect(added.factId, 'fact_count');
    expect(added.test, BehaviourConditionTest.equalsNumber);
    expect(key('map-story-fact-picker'), findsNothing);
  });
}
