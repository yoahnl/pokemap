import 'package:avelune_studio/features/events/application/event_condition_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test(
    'daily conditions retain the exact reward identity and negative predicate',
    () {
      final reference = PeriodicRewardReference(
        sceneId: 'station',
        nodeId: 'claim',
        rewardId: 'daily-station',
      );
      final original = NarrativeEventCondition.periodicRewardAvailable(
        reference: reference,
        expectedValue: false,
      );
      final draft = EventConditionDraft(facts: const [], initial: original);
      expect(draft.kind, EventConditionInputKind.periodicReward);
      expect(draft.rewardReference, reference);
      expect(draft.boolean, isFalse);
      expect(draft.condition, original);
      draft.rewardReference = null;
      expect(() => draft.condition, throwsStateError);
    },
  );

  test(
    'integer conditions preserve their operator and reject decimal input',
    () {
      final facts = [
        NarrativeFactDefinition(
          id: 'count',
          label: 'Nombre',
          initialValue: NarrativeValue.integer(0),
        ),
      ];
      final original = NarrativeEventCondition.factValue(
        'count',
        operator: NarrativeFactOperator.greaterThan,
        expectedValue: NarrativeValue.integer(3),
      );
      final draft = EventConditionDraft(facts: facts, initial: original);
      expect(draft.condition, original);
      draft.text = '3.5';
      expect(() => draft.condition, throwsFormatException);
      draft.text = '4';
      expect(
        draft.condition,
        NarrativeEventCondition.factValue(
          'count',
          operator: NarrativeFactOperator.greaterThan,
          expectedValue: NarrativeValue.integer(4),
        ),
      );
    },
  );

  test('string conditions retain the raw authored value', () {
    final original = NarrativeEventCondition.factValue(
      'name',
      operator: NarrativeFactOperator.equals,
      expectedValue: const NarrativeValue.string('  Clé du quai  '),
    );
    final draft = EventConditionDraft(
      facts: [
        NarrativeFactDefinition(
          id: 'name',
          label: 'Nom',
          initialValue: const NarrativeValue.string(''),
        ),
      ],
      initial: original,
    );
    expect(draft.text, '  Clé du quai  ');
    expect(draft.condition, original);
  });

  test('missing and removed fact references remain unpublishable', () {
    final draft = EventConditionDraft(facts: const []);
    expect(() => draft.condition, throwsStateError);
    draft.sourceId = 'removed';
    expect(() => draft.condition, throwsStateError);
    expect(draft.sourceId, 'removed');
  });

  test(
    'consumed events and local memories keep their exact source and predicate',
    () {
      final consumed = NarrativeEventCondition.narrativeEventConsumed(
      'evt_00000000-0000-7000-8000-000000000011',
        false,
      );
      expect(
        EventConditionDraft(facts: const [], initial: consumed).condition,
        consumed,
      );
      final local = NarrativeEventCondition.mapEventInstanceBoolean(
        mapId: 'station',
        eventId: 'chief',
        key: 'opened',
        expectedValue: false,
      );
      final draft = EventConditionDraft(
        facts: const [],
        mapId: 'other',
        entityId: 'other',
        initial: local,
      );
      expect(draft.condition, local);
      expect(draft.mapId, 'station');
      expect(draft.entityId, 'chief');
      expect(draft.boolean, isFalse);
    },
  );
}
