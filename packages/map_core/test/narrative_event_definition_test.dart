import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_core/src/models/narrative_event_wire.dart';
import 'package:test/test.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000001';
const _secondEventId = 'evt_019abcde-0000-7000-8000-000000000002';

void main() {
  group('Narrative Event V2 B2', () {
    test('encodes the exact definition, conditions, and configured record JSON',
        () {
      final definition = _definition();
      final record = NarrativeEventRecord.configuredStructurallyUnchecked(
        definition,
        enabled: false,
      );

      expect(
        jsonEncode(definition.toJson()),
        '{"id":"$_eventId","name":"Arrival","source":{"kind":"mapEnter","mapId":"map_port"},"conditions":[{"kind":"fact","factId":"intro_done","expectedValue":true},{"kind":"narrativeEventConsumed","eventId":"$_secondEventId","expectedValue":false}],"sceneId":"scene_arrival","reusePolicy":"oneShot","priority":-2,"order":0}',
      );
      expect(
        jsonEncode(record.toJson()),
        '{"state":"configured","definition":${jsonEncode(definition.toJson())},"enabled":false}',
      );
      expect(NarrativeEventRecord.fromJson(record.toJson()), record);
    });

    test('fails closed for invalid, unsupported, and forbidden wire fields',
        () {
      final decoders = <void Function()>[
        () => NarrativeEventDefinition.fromJson({
              ..._definition().toJson(),
              'future': true,
            }),
        () => NarrativeEventDefinition.fromJson({
              ..._definition().toJson(),
              'enabled': true,
            }),
        () => NarrativeEventDefinition.fromJson({
              ..._definition().toJson(),
              'id': ' $_eventId',
            }),
        () => NarrativeEventRecord.fromJson({
              'state': 'draft',
              'draft': _draft().toJson(),
              'enabled': true,
            }),
      ];

      expect(
        decoders[0],
        throwsA(isA<NarrativeEventUnsupportedWireException>()),
      );
      for (final decode in decoders.skip(1)) {
        expect(decode, throwsA(isA<NarrativeEventInvalidWireException>()));
      }
    });

    test(
        'preserves ordered immutable conditions and omits draft null optionals',
        () {
      final input = <NarrativeEventCondition>[
        NarrativeEventCondition.fact('intro_done', true),
      ];
      final draft = _draft(conditions: input);
      input.add(NarrativeEventCondition.fact('later', false));

      expect(draft.conditions, hasLength(1));
      expect(() => draft.conditions.add(input.first), throwsUnsupportedError);
      expect(
        jsonEncode(draft.toJson()),
        '{"id":"$_eventId","name":"Arrival","conditions":[{"kind":"fact","factId":"intro_done","expectedValue":true}],"priority":0,"order":3}',
      );
      expect(NarrativeEventDraft.fromJson(draft.toJson()), draft);
    });

    test(
        'keeps condition JSON exact, ordered, immutable, and AND-neutral when empty',
        () {
      final fact = NarrativeEventCondition.fact('intro_done', true);
      final consumed = NarrativeEventCondition.narrativeEventConsumed(
        _secondEventId,
        false,
      );

      expect(
        jsonEncode(fact.toJson()),
        '{"kind":"fact","factId":"intro_done","expectedValue":true}',
      );
      expect(
        jsonEncode(consumed.toJson()),
        '{"kind":"narrativeEventConsumed","eventId":"$_secondEventId","expectedValue":false}',
      );
      expect(NarrativeEventCondition.fromJson(fact.toJson()), fact);
      expect(NarrativeEventCondition.fromJson(consumed.toJson()), consumed);
      expect(_draft().conditions, isEmpty);
      expect(
        _definition().conditions.map((condition) => condition.toJson()),
        [fact.toJson(), consumed.toJson()],
      );
    });

    test('rejects malformed conditions and future condition wire shapes', () {
      expect(
        () => NarrativeEventCondition.fromJson({
          'kind': 'futureCondition',
          'factId': 'intro_done',
          'expectedValue': true,
        }),
        throwsA(isA<NarrativeEventUnsupportedWireException>()),
      );
      expect(
        () => NarrativeEventCondition.fromJson({
          'kind': 'fact',
          'factId': 'intro_done',
          'eventId': _eventId,
          'expectedValue': true,
        }),
        throwsA(isA<NarrativeEventInvalidWireException>()),
      );
      for (final decode in <void Function()>[
        () => NarrativeEventCondition.fromJson({
              'kind': 'fact',
              'expectedValue': true,
            }),
        () => NarrativeEventCondition.fromJson({
              'kind': 'fact',
              'factId': ' intro_done',
              'expectedValue': true,
            }),
        () => NarrativeEventCondition.fromJson({
              'kind': 'fact',
              'factId': 'intro_done',
              'expectedValue': 1,
            }),
        () => NarrativeEventCondition.fromJson({
              'kind': 'narrativeEventConsumed',
              'eventId': 'evt_not-v7',
              'expectedValue': false,
            }),
      ]) {
        expect(decode, throwsA(isA<NarrativeEventInvalidWireException>()));
      }
    });

    test('validates IDs names scenes priorities orders and draft optionals',
        () {
      expect(_definition().name, 'Arrival');
      expect(_draft().name, 'Arrival');
      expect(_definition().priority, -2);
      expect(
        () => _definitionWith(id: ' $_eventId'),
        throwsArgumentError,
      );
      expect(
        () => _definitionWith(id: 'evt_not-v7'),
        throwsArgumentError,
      );
      expect(
        () => _definitionWith(name: '  '),
        throwsArgumentError,
      );
      expect(
        () => _definitionWith(sceneId: ' scene_arrival'),
        throwsArgumentError,
      );
      expect(
        () => _definitionWith(order: -1),
        throwsArgumentError,
      );
      expect(
        NarrativeEventDraft.fromJson({
          ..._draft().toJson(),
          'source': null,
          'sceneId': null,
          'reusePolicy': null,
        }).toJson(),
        _draft().toJson(),
      );
    });

    test('rejects record payload mismatches and preserves exact discriminants',
        () {
      final draftRecord = NarrativeEventRecord.draft(_draft());
      expect(
        jsonEncode(draftRecord.toJson()),
        '{"state":"draft","draft":${jsonEncode(_draft().toJson())}}',
      );
      expect(NarrativeEventRecord.fromJson(draftRecord.toJson()), draftRecord);

      for (final decode in <void Function()>[
        () => NarrativeEventRecord.fromJson({
              'state': 'draft',
              'draft': _draft().toJson(),
              'definition': _definition().toJson(),
            }),
        () => NarrativeEventRecord.fromJson({
              'state': 'configured',
              'definition': _definition().toJson(),
              'enabled': null,
            }),
        () => NarrativeEventRecord.fromJson({
              'state': 'configured',
              'definition': _definition().toJson(),
              'enabled': 1,
            }),
      ]) {
        expect(decode, throwsA(isA<NarrativeEventInvalidWireException>()));
      }
      expect(
        () => NarrativeEventRecord.fromJson({
          'state': 'future',
          'draft': _draft().toJson(),
        }),
        throwsA(isA<NarrativeEventUnsupportedWireException>()),
      );
    });

    test('keeps forbidden Event fields out of definition and draft JSON', () {
      const forbidden = {
        'position',
        'x',
        'y',
        'layerId',
        'metadata',
        'enabled',
        'status',
        'action',
        'outcome',
      };
      expect(
          _definition().toJson().keys.toSet().intersection(forbidden), isEmpty);
      expect(_draft().toJson().keys.toSet().intersection(forbidden), isEmpty);
    });

    test('migrates historical condition lists to an in-memory all expression',
        () {
      final decoded = NarrativeEventDefinition.fromJson(_definition().toJson());

      expect(decoded.conditionExpression, isA<NarrativeEventConditionAll>());
      expect(decoded.conditionExpression.leaves, decoded.conditions);
      expect(decoded.toJson().containsKey('conditionExpression'), isFalse);
    });

    test('round-trips bounded any and not expressions without losing leaves',
        () {
      final fact = NarrativeEventCondition.fact('intro_done', true);
      final consumed = NarrativeEventCondition.narrativeEventConsumed(
        _secondEventId,
        false,
      );
      final expression = NarrativeEventConditionExpression.any([
        NarrativeEventConditionExpression.leaf(fact),
        NarrativeEventConditionExpression.not(
          NarrativeEventConditionExpression.leaf(consumed),
        ),
      ]);
      final definition = NarrativeEventDefinition(
        id: _eventId,
        name: 'Expression',
        source: NarrativeEventSourceRef.mapEnter('map_port'),
        conditions: [fact, consumed],
        conditionExpression: expression,
        sceneId: 'scene_arrival',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      );

      expect(definition.toJson()['conditionExpression'], expression.toJson());
      expect(
          NarrativeEventDefinition.fromJson(definition.toJson()), definition);
    });

    test('rejects empty nested groups, oversized depth and mismatched leaves',
        () {
      final fact = NarrativeEventCondition.fact('intro_done', true);
      expect(
        () => NarrativeEventDefinition(
          id: _eventId,
          name: 'Empty any',
          source: NarrativeEventSourceRef.mapEnter('map_port'),
          conditions: const [],
          conditionExpression: NarrativeEventConditionExpression.any([]),
          sceneId: 'scene_arrival',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        throwsArgumentError,
      );
      var tooDeep = NarrativeEventConditionExpression.leaf(fact);
      for (var index = 0; index < 8; index++) {
        tooDeep = NarrativeEventConditionExpression.not(tooDeep);
      }
      expect(
        () => NarrativeEventDefinition(
          id: _eventId,
          name: 'Too deep',
          source: NarrativeEventSourceRef.mapEnter('map_port'),
          conditions: [fact],
          conditionExpression: tooDeep,
          sceneId: 'scene_arrival',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventDefinition(
          id: _eventId,
          name: 'Mismatch',
          source: NarrativeEventSourceRef.mapEnter('map_port'),
          conditions: const [],
          conditionExpression: NarrativeEventConditionExpression.leaf(fact),
          sceneId: 'scene_arrival',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
        ),
        throwsArgumentError,
      );
    });

    test('enforces deterministic reset policy combinations and exact outcome',
        () {
      final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_signal',
        outcomeId: 'completed',
      );
      final reset = NarrativeEventResetPolicy.onOutcomeReceived(outcome);
      final definition = NarrativeEventDefinition(
        id: _eventId,
        name: 'Reset',
        source: NarrativeEventSourceRef.mapEnter('map_port'),
        conditions: const [],
        sceneId: 'scene_arrival',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
        resetPolicy: reset,
      );

      expect(definition.toJson()['resetPolicy'], reset.toJson());
      expect(
          NarrativeEventDefinition.fromJson(definition.toJson()), definition);
      expect(
        () => NarrativeEventDefinition(
          id: _eventId,
          name: 'Reusable reset',
          source: NarrativeEventSourceRef.mapEnter('map_port'),
          conditions: const [],
          sceneId: 'scene_arrival',
          reusePolicy: NarrativeEventReusePolicy.reusable,
          priority: 0,
          order: 0,
          resetPolicy: const NarrativeEventResetPolicy.onMapReentry(),
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeEventDefinition(
          id: _eventId,
          name: 'Non spatial reset',
          source: NarrativeEventSourceRef.outcomeReceived(outcome),
          conditions: const [],
          sceneId: 'scene_arrival',
          reusePolicy: NarrativeEventReusePolicy.oneShot,
          priority: 0,
          order: 0,
          resetPolicy: const NarrativeEventResetPolicy.onMapReentry(),
        ),
        throwsArgumentError,
      );
    });

    test('keeps raw Phase B transitions structurally explicit', () {
      expect(
        () => compileNarrativeEventDraftStructurally(
          NarrativeEventRecord.draft(_draft()),
        ),
        throwsStateError,
      );
      expect(
        () => setNarrativeEventRecordEnabledStructurallyUnchecked(
          NarrativeEventRecord.draft(_draft()),
          enabled: true,
        ),
        throwsArgumentError,
      );

      final configured = compileNarrativeEventDraftStructurally(
        NarrativeEventRecord.draft(_draft(
            source: NarrativeEventSourceRef.mapEnter('map_port'),
            sceneId: 'scene_arrival',
            reusePolicy: NarrativeEventReusePolicy.reusable)),
      );
      expect(configured.definitionOrNull, isNotNull);
      expect(configured.id, _eventId);
      expect(configured.definitionOrNull!.order, 3);
      expect(configured.enabledOrNull, isFalse);
      expect(
        setNarrativeEventRecordEnabledStructurallyUnchecked(
          configured,
          enabled: true,
        ).enabledOrNull,
        isTrue,
      );
      expect(
        setNarrativeEventRecordEnabledStructurallyUnchecked(
          configured,
          enabled: false,
        ).enabledOrNull,
        isFalse,
      );
    });

    test(
        'generates V7 IDs, retries existing and emitted collisions through attempt 17',
        () {
      var calls = 0;
      final generator = NarrativeEventIdGenerator(
        rawUuidFactory: () =>
            ++calls <= 16 ? _eventId.substring(4) : _secondEventId.substring(4),
      );
      final existing = NarrativeEventRecord.configuredStructurallyUnchecked(
        _definition(),
        enabled: false,
      );

      expect(generator.generate(existingRecords: [existing]), _secondEventId);
      expect(calls, 17);
      expect(
        NarrativeEventIdGenerator.eventIdPattern.hasMatch(_secondEventId),
        isTrue,
      );
      expect(
        () => NarrativeEventIdGenerator(rawUuidFactory: () => 'not-a-v7')
            .generate(existingRecords: const []),
        throwsArgumentError,
      );

      final emitted = NarrativeEventIdGenerator(
        rawUuidFactory: _sequence([
          _eventId.substring(4),
          _eventId.substring(4),
          _secondEventId.substring(4)
        ]),
      );
      expect(emitted.generate(existingRecords: const []), _eventId);
      expect(emitted.generate(existingRecords: const []), _secondEventId);

      final exhausted = NarrativeEventIdGenerator(
        rawUuidFactory: () => _eventId.substring(4),
      );
      expect(
        () => exhausted.generate(existingRecords: [existing]),
        throwsStateError,
      );
    });
  });
}

NarrativeEventDefinition _definition() => NarrativeEventDefinition(
      id: _eventId,
      name: ' Arrival ',
      source: NarrativeEventSourceRef.mapEnter('map_port'),
      conditions: [
        NarrativeEventCondition.fact('intro_done', true),
        NarrativeEventCondition.narrativeEventConsumed(_secondEventId, false),
      ],
      sceneId: 'scene_arrival',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: -2,
      order: 0,
    );

NarrativeEventDefinition _definitionWith({
  String id = _eventId,
  String name = 'Arrival',
  String sceneId = 'scene_arrival',
  int order = 0,
}) =>
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: NarrativeEventSourceRef.mapEnter('map_port'),
      conditions: const [],
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: -1,
      order: order,
    );

NarrativeEventDraft _draft({
  NarrativeEventSourceRef? source,
  List<NarrativeEventCondition> conditions = const [],
  String? sceneId,
  NarrativeEventReusePolicy? reusePolicy,
}) =>
    NarrativeEventDraft(
      id: _eventId,
      name: ' Arrival ',
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: reusePolicy,
      priority: 0,
      order: 3,
    );

String Function() _sequence(List<String> values) {
  var index = 0;
  return () => values[index++];
}
