import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SceneConsequence V0', () {
    test('setFact stores factId and value', () {
      final consequence = SceneConsequence.setFact(
        factId: 'fact_test_gate_unlocked',
        value: true,
        label: 'Unlock test gate',
      );

      expect(consequence.kind, SceneConsequenceKind.setFact);
      expect(consequence, isA<SceneSetFactConsequence>());
      final setFact = consequence as SceneSetFactConsequence;
      expect(setFact.factId, 'fact_test_gate_unlocked');
      expect(setFact.value, isTrue);
      expect(setFact.label, 'Unlock test gate');
    });

    test('markEventConsumed stores mapId and eventId', () {
      final consequence = SceneConsequence.markEventConsumed(
        mapId: 'map_test',
        eventId: 'event_gate',
        label: 'Gate event consumed',
      );

      expect(consequence.kind, SceneConsequenceKind.markEventConsumed);
      expect(consequence, isA<SceneMarkEventConsumedConsequence>());
      final consumed = consequence as SceneMarkEventConsumedConsequence;
      expect(consumed.mapId, 'map_test');
      expect(consumed.eventId, 'event_gate');
      expect(consumed.label, 'Gate event consumed');
    });

    test('completeStoryStep stores the canonical Story Step id', () {
      final consequence = SceneConsequence.completeStoryStep(
        stepId: 'step_rival_battle',
        label: 'Complete rival battle',
      );

      expect(consequence.kind, SceneConsequenceKind.completeStoryStep);
      expect(consequence, isA<SceneCompleteStoryStepConsequence>());
      final completeStep = consequence as SceneCompleteStoryStepConsequence;
      expect(completeStep.stepId, 'step_rival_battle');
      expect(completeStep.label, 'Complete rival battle');
    });

    test('setFact JSON round-trips', () {
      final consequence = SceneConsequence.setFact(
        factId: 'fact_test_gate_unlocked',
        value: false,
        label: 'Close test gate',
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json['kind'], 'setFact');
      expect(json['factId'], 'fact_test_gate_unlocked');
      expect(json['value'], isFalse);
      expect(decoded, equals(consequence));
    });

    test('typed setFact round-trips int and keeps bool JSON unchanged', () {
      final consequence = SceneConsequence.setFactValue(
        factId: 'fact_reputation',
        value: NarrativeValue.integer(12),
      ) as SceneSetFactConsequence;

      expect(consequence.narrativeValue, NarrativeValue.integer(12));
      expect(consequence.toJson(), {
        'kind': 'setFact',
        'factId': 'fact_reputation',
        'valueType': 'int',
        'value': 12,
      });
      expect(SceneConsequence.fromJson(consequence.toJson()), consequence);
      expect(
        SceneConsequence.setFact(factId: 'fact_bool', value: false).toJson(),
        {'kind': 'setFact', 'factId': 'fact_bool', 'value': false},
      );
    });

    test('markEventConsumed JSON round-trips', () {
      final consequence = SceneConsequence.markEventConsumed(
        mapId: 'map_test',
        eventId: 'event_gate',
        label: 'Gate event consumed',
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json['kind'], 'markEventConsumed');
      expect(json['mapId'], 'map_test');
      expect(json['eventId'], 'event_gate');
      expect(decoded, equals(consequence));
    });

    test('completeStoryStep JSON round-trips', () {
      final consequence = SceneConsequence.completeStoryStep(
        stepId: 'step_rival_battle',
        notes: 'Qualified victory path only.',
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json['kind'], 'completeStoryStep');
      expect(json['stepId'], 'step_rival_battle');
      expect(decoded, equals(consequence));
    });

    test('giveItem JSON round-trips quantity and stable item reference', () {
      final consequence = SceneConsequence.giveItem(
        itemId: 'item_potion',
        quantity: 2,
        label: 'Potion reward',
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json, {
        'kind': 'giveItem',
        'itemId': 'item_potion',
        'quantity': 2,
        'label': 'Potion reward',
      });
      expect(decoded, equals(consequence));
      expect(decoded, isA<SceneGiveItemConsequence>());
    });

    test('takeItem JSON round-trips quantity and stable item reference', () {
      final consequence = SceneConsequence.takeItem(
        itemId: 'item_ticket',
        quantity: 1,
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json['kind'], 'takeItem');
      expect(json['itemId'], 'item_ticket');
      expect(json['quantity'], 1);
      expect(decoded, equals(consequence));
      expect(decoded, isA<SceneTakeItemConsequence>());
    });

    test('giveMoney JSON round-trips a positive amount', () {
      final consequence = SceneConsequence.giveMoney(
        amount: 500,
        notes: 'Quest reward.',
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json['kind'], 'giveMoney');
      expect(json['amount'], 500);
      expect(decoded, equals(consequence));
      expect(decoded, isA<SceneGiveMoneyConsequence>());
    });

    test('givePokemon JSON round-trips species and construction defaults', () {
      final consequence = SceneConsequence.givePokemon(
        speciesId: 'species_sproutle',
        formId: 'sunny',
        level: 7,
        currentHp: 24,
        nickname: 'Mousse',
        friendship: 80,
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json, {
        'kind': 'givePokemon',
        'speciesId': 'species_sproutle',
        'formId': 'sunny',
        'level': 7,
        'currentHp': 24,
        'natureId': 'hardy',
        'abilityId': 'unknown',
        'nickname': 'Mousse',
        'friendship': 80,
      });
      expect(decoded, equals(consequence));
      expect(decoded, isA<SceneGivePokemonConsequence>());
    });

    test('legacy givePokemon JSON decodes level as an explicit migration flag',
        () {
      final decoded = SceneConsequence.fromJson(<String, dynamic>{
        'kind': 'givePokemon',
        'speciesId': 'species_legacy',
        'formId': 'base',
        'level': 9,
        'natureId': 'hardy',
        'abilityId': 'legacy-ability',
      }) as SceneGivePokemonConsequence;

      expect(decoded.currentHp, 9);
      expect(decoded.currentHpIsLegacyFallback, isTrue);
      expect(decoded.nickname, isEmpty);
      expect(decoded.friendship, 0);
      expect(decoded.toJson(), isNot(contains('currentHp')));
    });

    test('givePokemon JSON refuses a missing formId', () {
      expect(
        () => SceneConsequence.fromJson(<String, dynamic>{
          'kind': 'givePokemon',
          'speciesId': 'species_sproutle',
          'level': 7,
          'currentHp': 24,
        }),
        throwsFormatException,
      );
    });

    test('giveConfiguredStarter JSON round-trips only the authored option ref',
        () {
      final consequence = SceneConsequence.giveConfiguredStarter(
        starterOptionId: 'starter_bulbasaur',
        label: 'Recevoir Bulbizarre',
      );

      final json =
          jsonDecode(jsonEncode(consequence.toJson())) as Map<String, dynamic>;
      final decoded = SceneConsequence.fromJson(json);

      expect(json, <String, dynamic>{
        'kind': 'giveConfiguredStarter',
        'starterOptionId': 'starter_bulbasaur',
        'label': 'Recevoir Bulbizarre',
      });
      expect(decoded, consequence);
      expect(decoded, isA<SceneGiveConfiguredStarterConsequence>());
    });

    test('canonical gameplay consequences round-trip stable wire values', () {
      final consequences = <SceneConsequence>[
        SceneConsequence.healParty(),
        SceneConsequence.awardBadge(badgeId: 'badge_tide'),
        SceneConsequence.unlockFieldAbility(ability: FieldAbility.surf),
      ];

      expect(consequences.map((entry) => entry.toJson()), <Object>[
        <String, dynamic>{'kind': 'healParty'},
        <String, dynamic>{'kind': 'awardBadge', 'badgeId': 'badge_tide'},
        <String, dynamic>{
          'kind': 'unlockFieldAbility',
          'abilityId': 'surf',
        },
      ]);
      for (final consequence in consequences) {
        expect(
          SceneConsequence.fromJson(consequence.toJson()),
          consequence,
        );
      }
    });

    test('pause menu visibility round-trips and rejects Resume', () {
      final consequence = SceneConsequence.setPauseMenuEntryVisibility(
        actionId: ProjectPauseActionId.pokedex,
        visible: false,
      );

      expect(consequence.toJson(), <String, dynamic>{
        'kind': 'setPauseMenuEntryVisibility',
        'actionId': 'pokedex',
        'visible': false,
      });
      expect(SceneConsequence.fromJson(consequence.toJson()), consequence);
      expect(
        () => SceneConsequence.setPauseMenuEntryVisibility(
          actionId: ProjectPauseActionId.resume,
          visible: false,
        ),
        throwsArgumentError,
      );
    });

    test('rejects unknown consequence kind', () {
      expect(
        () => SceneConsequence.fromJson({
          'kind': 'teleportToMoon',
          'itemId': 'item_test',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('SceneActionPayload typed consequences', () {
    test('can carry typed setFact consequence', () {
      final payload = SceneActionPayload.consequence(
        SceneConsequence.setFact(
          factId: 'fact_test_gate_unlocked',
          value: true,
        ),
      );

      expect(payload.actionKind, isNull);
      expect(payload.parameters, isEmpty);
      expect(payload.consequence, isA<SceneSetFactConsequence>());
      expect(payload.toJson()['consequence'], isA<Map<String, dynamic>>());
    });

    test('can carry typed markEventConsumed consequence', () {
      final payload = SceneActionPayload.consequence(
        SceneConsequence.markEventConsumed(
          mapId: 'map_test',
          eventId: 'event_gate',
        ),
      );

      expect(payload.consequence, isA<SceneMarkEventConsumedConsequence>());
      expect(
        SceneNodePayload.fromJson(payload.toJson()),
        equals(payload),
      );
    });

    test('can carry typed completeStoryStep consequence', () {
      final payload = SceneActionPayload.consequence(
        SceneConsequence.completeStoryStep(stepId: 'step_rival_battle'),
      );

      expect(payload.consequence, isA<SceneCompleteStoryStepConsequence>());
      expect(
        SceneNodePayload.fromJson(payload.toJson()),
        equals(payload),
      );
    });

    test('legacy actionKind payload still deserializes', () {
      final payload = SceneNodePayload.fromJson({
        'kind': 'action',
        'actionKind': 'setFlag',
        'parameters': {'flagId': 'legacy_flag'},
      });

      expect(payload, isA<SceneActionPayload>());
      final action = payload as SceneActionPayload;
      expect(action.actionKind, 'setFlag');
      expect(action.parameters, {'flagId': 'legacy_flag'});
      expect(action.consequence, isNull);
    });
  });
}
