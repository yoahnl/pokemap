import 'package:avelune_studio/features/events/application/event_condition_draft.dart';
import 'package:avelune_studio/features/events/application/event_condition_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  for (final expected in [false, true]) {
    test(
      'unavailable daily condition intent preserves exact reference predicate and groups expected=$expected',
      () {
        final reference = PeriodicRewardReference(
          sceneId: 'published-scene',
          nodeId: 'claim',
          rewardId: 'daily-fruit',
        );
        final condition = NarrativeEventCondition.periodicRewardAvailable(
          reference: reference,
          expectedValue: expected,
        );
        final expression = NarrativeEventConditionExpression.any([
          NarrativeEventConditionExpression.not(
            NarrativeEventConditionExpression.leaf(condition),
          ),
          NarrativeEventConditionExpression.leaf(
            NarrativeEventCondition.fact('ready', true),
          ),
        ]);
        final before = expression.toJson();

        expect(isEventConditionEditable(condition), isFalse);
        expect(eventConditionLabel(condition, const [], const []), isNotEmpty);
        final draft = EventConditionDraft(facts: const [], initial: condition);
        expect(draft.kind, EventConditionInputKind.periodicReward);
        final retained = draft.condition;
        expect(retained.rewardReference, reference);
        expect(retained.expectedValue, expected);
        expect(expression.toJson(), before);
        expect(condition.rewardReference, same(reference));
        expect(condition.expectedValue, expected);
      },
    );
  }

  test('remaining fact condition edits stay available and daily creation is absent', () {
    final initial = NarrativeEventCondition.fact('ready', false);
    final facts = [NarrativeFactDefinition(id: 'ready', label: 'Prêt')];

    expect(isEventConditionEditable(initial), isTrue);
    expect(
      eventConditionCreationKinds(),
      [EventConditionInputKind.fact, EventConditionInputKind.event],
    );
    expect(
      eventConditionCreationKinds(mapId: 'map', entityId: 'owner'),
      [
        EventConditionInputKind.fact,
        EventConditionInputKind.event,
        EventConditionInputKind.instance,
      ],
    );
    expect(
      eventConditionCreationKinds(mapId: 'map'),
      isNot(contains(EventConditionInputKind.instance)),
    );
    for (final owner in [(null, null), ('map', 'owner')]) {
      expect(
        eventConditionCreationKinds(mapId: owner.$1, entityId: owner.$2),
        isNot(contains(EventConditionInputKind.periodicReward)),
      );
    }

    final draft = EventConditionDraft(facts: facts, initial: initial);
    expect(draft.boolean, isFalse);
    draft.boolean = true;
    expect(draft.condition, NarrativeEventCondition.fact('ready', true));
    expect(initial, NarrativeEventCondition.fact('ready', false));
  });
}
