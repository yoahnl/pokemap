import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_core/src/models/narrative_event_wire.dart';
import 'package:map_core/src/read_models/narrative_reference_picker_read_models.dart'
    as legacy_picker;
import 'package:test/test.dart';

void main() {
  group('NarrativeEventSourceRef', () {
    test('keeps the V1 source kind order and exposes the exact V0 variants',
        () {
      expect(NarrativeEventSourceKind.values, [
        NarrativeEventSourceKind.mapEnter,
        NarrativeEventSourceKind.triggerEnter,
        NarrativeEventSourceKind.entityInteract,
        NarrativeEventSourceKind.outcomeReceived,
      ]);
      expect(NarrativeOutcomeProducerKind.values, [
        NarrativeOutcomeProducerKind.scene,
        NarrativeOutcomeProducerKind.battle,
        NarrativeOutcomeProducerKind.legacyScenario,
      ]);

      final outcome = _sceneOutcome();
      final sources = [
        NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
        NarrativeEventSourceRef.triggerEnter('map_port', 'zone_entry'),
        NarrativeEventSourceRef.mapEnter('map_port'),
        NarrativeEventSourceRef.outcomeReceived(outcome),
      ];

      expect(sources.map((source) => source.kind), [
        NarrativeEventSourceKind.entityInteract,
        NarrativeEventSourceKind.triggerEnter,
        NarrativeEventSourceKind.mapEnter,
        NarrativeEventSourceKind.outcomeReceived,
      ]);
      expect(sources.map(_describeSource), [
        'entityInteract:map_port:npc_lysa',
        'triggerEnter:map_port:zone_entry',
        'mapEnter:map_port',
        'outcomeReceived:scene:scene_lysa:victory',
      ]);
      expect(outcome.producerKind, NarrativeOutcomeProducerKind.scene);
      expect(outcome.producerId, 'scene_lysa');
      expect(outcome.outcomeId, 'victory');
    });

    test('rejects empty or non-trimmed identities instead of normalizing', () {
      for (final invalidId in ['', ' ', ' map_port', 'map_port ', '\tmap']) {
        expect(
          () => NarrativeEventSourceRef.mapEnter(invalidId),
          throwsArgumentError,
          reason: 'mapId "$invalidId" must be rejected',
        );
        expect(
          () => NarrativeEventSourceRef.entityInteract(invalidId, 'npc'),
          throwsArgumentError,
        );
        expect(
          () => NarrativeEventSourceRef.entityInteract('map', invalidId),
          throwsArgumentError,
        );
        expect(
          () => NarrativeEventSourceRef.triggerEnter(invalidId, 'trigger'),
          throwsArgumentError,
        );
        expect(
          () => NarrativeEventSourceRef.triggerEnter('map', invalidId),
          throwsArgumentError,
        );
        expect(
          () => NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: invalidId,
            outcomeId: 'victory',
          ),
          throwsArgumentError,
        );
        expect(
          () => NarrativeOutcomeRef(
            producerKind: NarrativeOutcomeProducerKind.scene,
            producerId: 'scene',
            outcomeId: invalidId,
          ),
          throwsArgumentError,
        );
      }
    });

    test('keeps identities case-sensitive', () {
      expect(
        NarrativeEventSourceRef.mapEnter('Map_Port'),
        isNot(NarrativeEventSourceRef.mapEnter('map_port')),
      );
      expect(
        NarrativeOutcomeRef(
          producerKind: NarrativeOutcomeProducerKind.scene,
          producerId: 'Scene_Lysa',
          outcomeId: 'Victory',
        ),
        isNot(_sceneOutcome()),
      );
    });

    test('uses structural equality and hash codes as map keys', () {
      final first = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final equal = NarrativeEventSourceRef.entityInteract(
        'map_port',
        'npc_lysa',
      );
      final values = <NarrativeEventSourceRef, String>{first: 'event'};

      expect(equal, first);
      expect(equal.hashCode, first.hashCode);
      expect(values[equal], 'event');

      expect(
        NarrativeEventSourceRef.entityInteract('a:b', 'c'),
        isNot(NarrativeEventSourceRef.entityInteract('a', 'b:c')),
        reason: 'identity must not be reconstructed from a joined string',
      );
      expect(
        NarrativeEventSourceRef.entityInteract('map_port', 'shared'),
        isNot(NarrativeEventSourceRef.triggerEnter('map_port', 'shared')),
      );
    });

    test('qualifies equal outcome ids by producer kind and producer id', () {
      final scene = _sceneOutcome();
      final otherScene = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'scene_other',
        outcomeId: 'victory',
      );
      final battle = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'scene_lysa',
        outcomeId: 'victory',
      );

      expect(scene, NarrativeOutcomeRef.fromJson(scene.toJson()));
      expect(scene.hashCode,
          NarrativeOutcomeRef.fromJson(scene.toJson()).hashCode);
      expect(scene, isNot(otherScene));
      expect(scene, isNot(battle));
      expect(
        NarrativeEventSourceRef.outcomeReceived(scene),
        isNot(NarrativeEventSourceRef.outcomeReceived(battle)),
      );
    });
  });

  group('canonical JSON', () {
    test('encodes every source variant with exact fields and order', () {
      final cases = <(NarrativeEventSourceRef, String)>[
        (
          NarrativeEventSourceRef.entityInteract('map_port', 'npc_lysa'),
          '{"kind":"entityInteract","mapId":"map_port","entityId":"npc_lysa"}',
        ),
        (
          NarrativeEventSourceRef.triggerEnter('map_port', 'zone_entry'),
          '{"kind":"triggerEnter","mapId":"map_port","triggerId":"zone_entry"}',
        ),
        (
          NarrativeEventSourceRef.mapEnter('map_port'),
          '{"kind":"mapEnter","mapId":"map_port"}',
        ),
        (
          NarrativeEventSourceRef.outcomeReceived(_sceneOutcome()),
          '{"kind":"outcomeReceived","outcome":{"producerKind":"scene","producerId":"scene_lysa","outcomeId":"victory"}}',
        ),
      ];

      for (final (source, expectedJson) in cases) {
        expect(jsonEncode(source.toJson()), expectedJson);
        expect(NarrativeEventSourceRef.fromJson(source.toJson()), source);
      }
    });

    test('encodes and decodes each exact outcome producer discriminant', () {
      for (final (producerKind, wireName) in [
        (NarrativeOutcomeProducerKind.scene, 'scene'),
        (NarrativeOutcomeProducerKind.battle, 'battle'),
        (NarrativeOutcomeProducerKind.legacyScenario, 'legacyScenario'),
      ]) {
        final outcome = NarrativeOutcomeRef(
          producerKind: producerKind,
          producerId: 'producer',
          outcomeId: 'result',
        );

        expect(
          jsonEncode(outcome.toJson()),
          '{"producerKind":"$wireName","producerId":"producer","outcomeId":"result"}',
        );
        expect(NarrativeOutcomeRef.fromJson(outcome.toJson()), outcome);
      }
    });
  });

  group('strict closed-world decode', () {
    test('classifies unknown fields and discriminants as unsupported', () {
      final decoders = <void Function()>[
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'mapEnter',
              'mapId': 'map_port',
              'futureField': true,
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'futureSource',
              'mapId': 'map_port',
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'outcomeReceived',
              'outcome': {
                'producerKind': 'scene',
                'producerId': 'scene_lysa',
                'outcomeId': 'victory',
                'futureField': true,
              },
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'outcomeReceived',
              'outcome': {
                'producerKind': 'futureProducer',
                'producerId': 'scene_lysa',
                'outcomeId': 'victory',
              },
            }),
        () => NarrativeOutcomeRef.fromJson({
              'producerKind': 'scene',
              'producerId': 'scene_lysa',
              'outcomeId': 'victory',
              'futureField': true,
            }),
      ];

      for (final decode in decoders) {
        expect(
          decode,
          throwsA(
            allOf(
              isA<FormatException>(),
              isA<NarrativeEventUnsupportedWireException>(),
              isNot(isA<NarrativeEventInvalidWireException>()),
            ),
          ),
        );
      }
    });

    test('classifies missing null wrong-type and invalid values as invalid',
        () {
      final decoders = <void Function()>[
        () => NarrativeEventSourceRef.fromJson(null),
        () => NarrativeEventSourceRef.fromJson(const []),
        () => NarrativeEventSourceRef.fromJson(<Object?, Object?>{1: 'bad'}),
        () => NarrativeEventSourceRef.fromJson(const {}),
        () => NarrativeEventSourceRef.fromJson({'kind': null}),
        () => NarrativeEventSourceRef.fromJson({'kind': 1}),
        () => NarrativeEventSourceRef.fromJson({'kind': 'mapEnter'}),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'mapEnter',
              'mapId': null,
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'mapEnter',
              'mapId': 42,
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'mapEnter',
              'mapId': '',
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'mapEnter',
              'mapId': ' map_port',
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'mapEnter',
              'mapId': 'map_port',
              'entityId': 'npc_lysa',
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'entityInteract',
              'mapId': 'map_port',
              'entityId': 'npc_lysa',
              'triggerId': 'zone_entry',
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'outcomeReceived',
              'mapId': 'map_port',
              'outcome': _sceneOutcome().toJson(),
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'entityInteract',
              'mapId': 'map_port',
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'triggerEnter',
              'mapId': 'map_port',
              'triggerId': false,
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'outcomeReceived',
              'outcome': null,
            }),
        () => NarrativeEventSourceRef.fromJson({
              'kind': 'outcomeReceived',
              'outcome': 'scene:scene_lysa:victory',
            }),
        () => NarrativeOutcomeRef.fromJson({
              'producerKind': 'scene',
              'producerId': 'scene_lysa',
            }),
        () => NarrativeOutcomeRef.fromJson({
              'producerKind': null,
              'producerId': 'scene_lysa',
              'outcomeId': 'victory',
            }),
        () => NarrativeOutcomeRef.fromJson({
              'producerKind': 'scene',
              'producerId': 'scene_lysa ',
              'outcomeId': 'victory',
            }),
      ];

      for (final decode in decoders) {
        expect(
          decode,
          throwsA(
            allOf(
              isA<FormatException>(),
              isA<NarrativeEventInvalidWireException>(),
              isNot(isA<NarrativeEventUnsupportedWireException>()),
            ),
          ),
        );
      }
    });
  });

  test('the V1 picker path re-exports the relocated source kind', () {
    expect(
      legacy_picker.NarrativeEventSourceKind.values,
      NarrativeEventSourceKind.values,
    );
    expect(
      legacy_picker.NarrativeEventSourceKind.mapEnter,
      same(NarrativeEventSourceKind.mapEnter),
    );
  });
}

NarrativeOutcomeRef _sceneOutcome() => NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'scene_lysa',
      outcomeId: 'victory',
    );

String _describeSource(NarrativeEventSourceRef source) => source.when(
      entityInteract: (mapId, entityId) => 'entityInteract:$mapId:$entityId',
      triggerEnter: (mapId, triggerId) => 'triggerEnter:$mapId:$triggerId',
      mapEnter: (mapId) => 'mapEnter:$mapId',
      outcomeReceived: (outcome) =>
          'outcomeReceived:${outcome.producerKind.name}:'
          '${outcome.producerId}:${outcome.outcomeId}',
    );
