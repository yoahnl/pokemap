import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_core/src/models/narrative_event_wire.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000001';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000002';
const _fingerprintA =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _fingerprintB =
    'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  group('Narrative Event V2 B3 registry model', () {
    test('encodes the exact empty registry for all three modes', () {
      for (final mode in EventSystemMode.values) {
        final registry = NarrativeEventRegistry(
          schemaVersion: 1,
          mode: mode,
          records: const [],
          legacyClaims: const [],
        );
        expect(
          jsonEncode(registry.toJson()),
          '{"schemaVersion":1,"mode":"${mode.name}","records":[],"legacyClaims":[]}',
        );
        expect(NarrativeEventRegistry.fromJson(registry.toJson()), registry);
      }
    });

    test('preserves author record and claim order without mutating inputs', () {
      final records = <NarrativeEventRecord>[
        _configured(_eventB, enabled: false),
        _configured(_eventA, enabled: true),
      ];
      final claims = <LegacySourceClaim>[
        _claim(
          source: NarrativeEventSourceRef.mapEnter('map_b'),
          provenance: LegacySourceRef.mapEvent('map_b', 'legacy_b'),
          targetIds: [_eventB],
        ),
        _claim(
          source: NarrativeEventSourceRef.mapEnter('map_a'),
          provenance: LegacySourceRef.mapEvent('map_a', 'legacy_a'),
          targetIds: [_eventA],
        ),
      ];
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        records: records,
        legacyClaims: claims,
      );
      records.clear();
      claims.clear();

      expect(registry.records.map((record) => record.id), [_eventB, _eventA]);
      expect(
        registry.legacyClaims.map((claim) => claim.targetEventIds.single),
        [_eventB, _eventA],
      );
      expect(() => registry.records.clear(), throwsUnsupportedError);
      expect(() => registry.legacyClaims.clear(), throwsUnsupportedError);
      expect(NarrativeEventRegistry.fromJson(registry.toJson()), registry);
    });

    test('encodes both exact legacy provenance variants', () {
      final sources = [
        LegacySourceRef.mapEvent('map_port', 'lysa'),
        LegacySourceRef.scenarioSourceNode('scenario_lysa', 'source'),
      ];
      expect(
        jsonEncode(sources[0].toJson()),
        '{"kind":"mapEvent","mapId":"map_port","eventId":"lysa"}',
      );
      expect(
        jsonEncode(sources[1].toJson()),
        '{"kind":"scenarioSourceNode","scenarioId":"scenario_lysa","nodeId":"source"}',
      );
      for (final source in sources) {
        expect(LegacySourceRef.fromJson(source.toJson()), source);
      }
    });

    test('rejects unknown registry fields and discriminants as unsupported',
        () {
      final base = _emptyRegistryJson();
      for (final decode in <void Function()>[
        () => NarrativeEventRegistry.fromJson({...base, 'future': true}),
        () => NarrativeEventRegistry.fromJson({...base, 'mode': 'future'}),
        () => NarrativeEventRegistry.fromJson({...base, 'schemaVersion': 2}),
        () => LegacySourceRef.fromJson({
              'kind': 'future',
              'mapId': 'map_port',
              'eventId': 'legacy',
            }),
      ]) {
        expect(decode, throwsA(isA<NarrativeEventUnsupportedWireException>()));
      }
    });

    test('rejects malformed registry values and duplicate record IDs', () {
      final configured = _configured(_eventA, enabled: false).toJson();
      for (final decode in <void Function()>[
        () => NarrativeEventRegistry.fromJson(
            {..._emptyRegistryJson()}..remove('mode')),
        () => NarrativeEventRegistry.fromJson(
            {..._emptyRegistryJson(), 'mode': null}),
        () => NarrativeEventRegistry.fromJson(
            {..._emptyRegistryJson(), 'records': {}}),
        () => NarrativeEventRegistry.fromJson({
              ..._emptyRegistryJson(),
              'records': [configured, configured],
            }),
        () => LegacySourceRef.fromJson({
              'kind': 'mapEvent',
              'mapId': ' map_port',
              'eventId': 'legacy',
            }),
      ]) {
        expect(decode, throwsA(isA<NarrativeEventInvalidWireException>()));
      }
    });

    test('enforces canonical non-empty claim members targets and fingerprints',
        () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final mapMember = LegacySourceClaimMember(
        provenance: LegacySourceRef.mapEvent('map_port', 'legacy'),
        sourceFingerprint: _fingerprintA,
      );
      final scenarioMember = LegacySourceClaimMember(
        provenance: LegacySourceRef.scenarioSourceNode('scenario', 'source'),
        sourceFingerprint: _fingerprintB,
      );

      expect(
        () => _claimFromParts(source, const [], [_eventA]),
        throwsArgumentError,
      );
      expect(
        () => _claimFromParts(source, [mapMember], const []),
        throwsArgumentError,
      );
      expect(
        () => _claimFromParts(source, [mapMember, mapMember], [_eventA]),
        throwsArgumentError,
      );
      expect(
        () => _claimFromParts(
          source,
          [scenarioMember, mapMember],
          [_eventA],
        ),
        throwsArgumentError,
      );
      expect(
        () => _claimFromParts(source, [mapMember], [_eventB, _eventA]),
        throwsArgumentError,
      );
      expect(
        () => _claimFromParts(source, [mapMember], [_eventA, _eventA]),
        throwsArgumentError,
      );
      expect(
        () => LegacySourceClaimMember(
          provenance: mapMember.provenance,
          sourceFingerprint: 'sha256:ABC',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ValidatedLegacyClaimIndex', () {
    test(
        'accepts disabled configured targets but rejects absent draft and source mismatch',
        () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final valid = _claim(
        source: source,
        provenance: LegacySourceRef.mapEvent('map_port', 'valid'),
        targetIds: [_eventA],
      );
      final validIndex = buildValidatedLegacyClaimIndex(
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.dualRead,
          records: [_configured(_eventA, enabled: false, source: source)],
          legacyClaims: [valid],
        ),
      );
      expect(validIndex.canStartDualRead, isTrue);
      expect(validIndex.validBySource[source], valid);

      final invalidCases = <NarrativeEventRecord?>[
        null,
        NarrativeEventRecord.draft(_draft(_eventA)),
        _configured(
          _eventA,
          enabled: true,
          source: NarrativeEventSourceRef.mapEnter('other_map'),
        ),
      ];
      for (final record in invalidCases) {
        final index = buildValidatedLegacyClaimIndex(
          NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.dualRead,
            records: [if (record != null) record],
            legacyClaims: [valid],
          ),
        );
        expect(index.canStartDualRead, isFalse);
        expect(index.invalidBySource[source], isNotEmpty);
      }
    });

    test('reports global duplicate source cohort and provenance conflicts', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final first = _claim(
        source: source,
        provenance: LegacySourceRef.mapEvent('map_port', 'legacy_a'),
        targetIds: [_eventA],
      );
      final second = _claim(
        source: source,
        provenance: LegacySourceRef.mapEvent('map_port', 'legacy_b'),
        targetIds: [_eventB],
      );
      final index = buildValidatedLegacyClaimIndex(
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.dualRead,
          records: [
            _configured(_eventA, enabled: true, source: source),
            _configured(_eventB, enabled: true, source: source),
          ],
          legacyClaims: [first, second],
        ),
      );

      expect(index.canStartDualRead, isFalse);
      expect(index.globalConflicts, isNotEmpty);
      expect(index.invalidBySource[source], isNotEmpty);
      expect(() => index.globalConflicts.clear(), throwsUnsupportedError);
    });

    test(
        'keeps duplicate cohort and cross-claim provenance decoded but globally blocked',
        () {
      final sourceA = NarrativeEventSourceRef.mapEnter('map_a');
      final sourceB = NarrativeEventSourceRef.mapEnter('map_b');
      final sharedProvenance = LegacySourceRef.mapEvent('map_a', 'legacy');
      final duplicate = _claim(
        source: sourceA,
        provenance: sharedProvenance,
        targetIds: [_eventA],
      );
      final duplicateIndex = buildValidatedLegacyClaimIndex(
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.dualRead,
          records: [
            _configured(_eventA, enabled: true, source: sourceA),
          ],
          legacyClaims: [duplicate, duplicate],
        ),
      );
      expect(duplicateIndex.canStartDualRead, isFalse);
      expect(
        duplicateIndex.globalConflicts.where(
          (diagnostic) => diagnostic.startsWith('cohortId '),
        ),
        isNotEmpty,
      );

      final other = _claim(
        source: sourceB,
        provenance: sharedProvenance,
        targetIds: [_eventB],
      );
      final provenanceIndex = buildValidatedLegacyClaimIndex(
        NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.dualRead,
          records: [
            _configured(_eventA, enabled: true, source: sourceA),
            _configured(_eventB, enabled: true, source: sourceB),
          ],
          legacyClaims: [duplicate, other],
        ),
      );
      expect(provenanceIndex.canStartDualRead, isFalse);
      expect(
        provenanceIndex.globalConflicts.where(
          (diagnostic) => diagnostic.startsWith('provenance '),
        ),
        isNotEmpty,
      );
    });
  });
}

Map<String, Object?> _emptyRegistryJson() => {
      'schemaVersion': 1,
      'mode': 'legacyOnly',
      'records': <Object?>[],
      'legacyClaims': <Object?>[],
    };

NarrativeEventRecord _configured(
  String id, {
  required bool enabled,
  NarrativeEventSourceRef? source,
}) =>
    NarrativeEventRecord.configured(
      NarrativeEventDefinition(
        id: id,
        name: id,
        source: source ?? NarrativeEventSourceRef.mapEnter('map_port'),
        conditions: const [],
        sceneId: 'scene',
        reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0,
        order: 0,
      ),
      enabled: enabled,
    );

NarrativeEventDraft _draft(String id) => NarrativeEventDraft(
      id: id,
      name: id,
      conditions: const [],
      priority: 0,
      order: 0,
    );

LegacySourceClaim _claim({
  required NarrativeEventSourceRef source,
  required LegacySourceRef provenance,
  required List<String> targetIds,
}) {
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: _fingerprintA,
  );
  return _claimFromParts(source, [member], targetIds);
}

LegacySourceClaim _claimFromParts(
  NarrativeEventSourceRef source,
  List<LegacySourceClaimMember> members,
  List<String> targetIds,
) {
  final cohortId = computeLegacySourceCohortId(
    source,
    members.map((member) => member.provenance),
  );
  final cohortFingerprint = computeLegacySourceCohortFingerprint(
    cohortId,
    members,
  );
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: members,
    cohortFingerprint: cohortFingerprint,
    targetEventIds: targetIds,
    migrationReceiptId: 'receipt_1',
  );
}
