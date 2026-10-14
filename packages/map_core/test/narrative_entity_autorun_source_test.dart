import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, Object?> _source([String kind = 'entityAutorun']) => {
  'kind': kind,
  'mapId': 'map',
  'entityId': 'owner',
};

void main() {
  test('autorun invokes only its required callback', () {
    final source = NarrativeEventSourceRef.entityAutorun('map', 'owner');
    expect(
      source.when<String>(
        entityAutorun: (mapId, entityId) => '$mapId/$entityId',
        entityInteract: (_, _) => fail('interaction fallback'),
        entityBump: (_, _) => fail('contact fallback'),
        mapEnter: (_) => fail('map entry fallback'),
        modelInteract: (_, _) => fail('model fallback'),
        triggerBump: (_, _) => fail('trigger fallback'),
        triggerEnter: (_, _) => fail('trigger fallback'),
        outcomeReceived: (_) => fail('outcome fallback'),
      ),
      'map/owner',
    );
    expect(
      () => Function.apply(source.when<String>, [], {
        #entityInteract: (String _, String _) => 'interact',
        #entityBump: (String _, String _) => 'bump',
        #mapEnter: (String _) => 'map',
        #modelInteract: (String _, String _) => 'model',
        #triggerBump: (String _, String _) => 'trigger',
        #triggerEnter: (String _, String _) => 'trigger',
        #outcomeReceived: (NarrativeOutcomeRef _) => 'outcome',
      }),
      throwsA(isA<NoSuchMethodError>()),
    );
  });

  test(
    'entity autorun is an exact source distinct from interaction contact and map entry',
    () {
      final source = NarrativeEventSourceRef.fromJson(_source());
      expect(source.kind.name, 'entityAutorun');
      expect(source.toJson(), _source());
      expect(NarrativeEventSourceRef.fromJson(source.toJson()), source);
      expect(
        source,
        isNot(NarrativeEventSourceRef.entityInteract('map', 'owner')),
      );
      expect(source, isNot(NarrativeEventSourceRef.entityBump('map', 'owner')));
      expect(source, isNot(NarrativeEventSourceRef.mapEnter('map')));
    },
  );

  test(
    'autorun rejects aliases partial identities nulls and unknown wire fields',
    () {
      for (final value in <Map<String, Object?>>[
        _source('entityAutoRun'),
        _source('autorun'),
        {'kind': 'entityAutorun', 'mapId': 'map'},
        {..._source(), 'entityId': null},
        {..._source(), 'entityId': ''},
        {..._source(), 'mapId': ' map'},
        {..._source(), 'triggerId': 'zone'},
        {..._source(), 'visible': false},
      ]) {
        expect(
          () => NarrativeEventSourceRef.fromJson(value),
          throwsFormatException,
        );
      }
    },
  );
}
