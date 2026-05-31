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

    test('rejects unknown consequence kind', () {
      expect(
        () => SceneConsequence.fromJson({
          'kind': 'giveItem',
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
