import 'package:map_core/map_core.dart';
import 'package:map_core/src/models/narrative_event_wire.dart';
import 'package:test/test.dart';

void main() {
  test(
    'entity bump invokes its required callback and never entity interact',
    () {
      final source = NarrativeEventSourceRef.entityBump('map', 'door');
      final result = source.when<String>(
        entityBump: (mapId, entityId) => 'bump:$mapId:$entityId',
        entityInteract: (_, _) =>
            fail('entityInteract must never consume a bump'),
        modelInteract: (_, _) => fail('modelInteract'),
        triggerEnter: (_, _) => fail('triggerEnter'),
        mapEnter: (_) => fail('mapEnter'),
        outcomeReceived: (_) => fail('outcomeReceived'),
      );
      expect(result, 'bump:map:door');
      expect(
        () => Function.apply(source.when<String>, [], {
          #entityInteract: (String _, String _) => 'interact',
          #modelInteract: (String _, String _) => 'model',
          #triggerEnter: (String _, String _) => 'trigger',
          #mapEnter: (String _) => 'map',
          #outcomeReceived: (NarrativeOutcomeRef _) => 'outcome',
        }),
        throwsA(isA<NoSuchMethodError>()),
      );
    },
  );

  test(
    'entity bump factory rejects invalid IDs and keeps case sensitivity',
    () {
      for (final id in ['', ' ', ' map', 'map ', '\tmap']) {
        expect(
          () => NarrativeEventSourceRef.entityBump(id, 'door'),
          throwsArgumentError,
        );
        expect(
          () => NarrativeEventSourceRef.entityBump('map', id),
          throwsArgumentError,
        );
      }
      expect(
        NarrativeEventSourceRef.entityBump('Map', 'door'),
        isNot(NarrativeEventSourceRef.entityBump('map', 'door')),
      );
    },
  );

  test('entity bump unknown fields remain unsupported closed-world data', () {
    expect(
      () => NarrativeEventSourceRef.fromJson({
        'kind': 'entityBump',
        'mapId': 'map',
        'entityId': 'door',
        'unknown': true,
      }),
      throwsA(isA<NarrativeEventUnsupportedWireException>()),
    );
  });
  test('entity bump is a distinct closed source identity', () {
    final source = NarrativeEventSourceRef.fromJson({
      'kind': 'entityBump',
      'mapId': 'map',
      'entityId': 'door',
    });
    expect(source.kind.name, 'entityBump');
    expect(source.toJson(), {
      'kind': 'entityBump',
      'mapId': 'map',
      'entityId': 'door',
    });
    expect(
      source,
      isNot(NarrativeEventSourceRef.entityInteract('map', 'door')),
    );
    final equal = NarrativeEventSourceRef.fromJson(source.toJson());
    expect(equal, source);
    expect(equal.hashCode, source.hashCode);
    expect(
      <NarrativeEventSourceRef, String>{
        source: 'bump',
        NarrativeEventSourceRef.entityInteract('map', 'door'): 'interact',
      }.length,
      2,
    );
  });

  test(
    'entity bump contract describes exact 2D NPC blocking source fields',
    () {
      final contract = NarrativeEventSourceRef.contracts.singleWhere(
        (entry) => entry['kind'] == 'entityBump',
      );
      expect(contract['requiredFields'], ['kind', 'mapId', 'entityId']);
      expect(contract['dimension'], 'twoD');
      expect(contract['entityReference'], 'knownUniqueBlockingNPCCharacter');
    },
  );

  test('entity bump rejects malformed identities and mixed source fields', () {
    for (final fields in <Map<String, Object?>>[
      {'mapId': 'map'},
      {'mapId': 'map', 'entityId': null},
      {'mapId': '', 'entityId': 'door'},
      {'mapId': ' map', 'entityId': 'door'},
      {'mapId': 'map', 'entityId': 'door '},
      {'mapId': 2, 'entityId': 'door'},
      {'mapId': 'map', 'entityId': 'door', 'triggerId': 'zone'},
    ]) {
      expect(
        () =>
            NarrativeEventSourceRef.fromJson({'kind': 'entityBump', ...fields}),
        throwsA(isA<NarrativeEventInvalidWireException>()),
      );
    }
  });
}
