import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EventRegistryDecodeResult', () {
    test('maps absent and null registry to absent legacyOnly capabilities', () {
      for (final raw in [null, null]) {
        final result = decodeNarrativeEventRegistry(raw);
        expect(_decodeState(result), 'absent');
        expect(result.registryOrNull, isNull);
        expect(result.writable, isTrue);
        expect(result.runtimeAllowed, isTrue);
        expect(result.migrationAllowed, isTrue);
        expect(result.playtestAllowed, isTrue);
        expect(() => result.toJson(), throwsStateError);
      }
    });

    test('decodes a known registry and is the only state that can encode', () {
      final raw = _registryJson();
      final result = decodeNarrativeEventRegistry(raw);

      expect(_decodeState(result), 'decoded');
      expect(result.registryOrNull?.mode, EventSystemMode.legacyOnly);
      expect(result.toJson(), raw);
      expect(result.diagnostics, isEmpty);
    });

    test(
      'classifies future schema fields and discriminants as unsupported',
      () {
        final cases = [
          {..._registryJson(), 'schemaVersion': 2},
          {..._registryJson(), 'future': true},
          {..._registryJson(), 'mode': 'future'},
          {
            ..._registryJson(),
            'records': [
              {
                'state': 'draft',
                'draft': {
                  'id': 'evt_019abcde-0000-7000-8000-000000000001',
                  'name': 'Draft',
                  'conditions': <Object?>[],
                  'priority': 0,
                  'order': 0,
                  'future': true,
                },
              },
            ],
          },
        ];

        for (final raw in cases) {
          final result = decodeNarrativeEventRegistry(raw);
          expect(_decodeState(result), 'unsupported');
          _expectFailClosed(result, raw);
        }
      },
    );

    test('classifies missing null wrong type and invalid IDs as invalid', () {
      final cases = <Object?>[
        <String, Object?>{'schemaVersion': 1},
        {..._registryJson(), 'mode': null},
        {..._registryJson(), 'records': null},
        {..._registryJson(), 'legacyClaims': {}},
        {
          ..._registryJson(),
          'records': [
            {
              'state': 'draft',
              'draft': {
                'id': 'evt_invalid',
                'name': 'Draft',
                'conditions': <Object?>[],
                'priority': 0,
                'order': 0,
              },
            },
          ],
        },
      ];

      for (final raw in cases) {
        final first = decodeNarrativeEventRegistry(raw);
        final second = decodeNarrativeEventRegistry(raw);
        expect(_decodeState(first), 'invalid');
        expect(first.diagnostics, second.diagnostics);
        _expectFailClosed(first, raw);
      }
    });

    test(
      'classifies malformed and canonically inconsistent claim hashes as invalid',
      () {
        final claim = _validClaim().toJson();
        final malformedMember = Map<String, Object?>.from(claim)
          ..['members'] = [
            {
              'provenance': LegacySourceRef.mapEvent(
                'map_port',
                'legacy',
              ).toJson(),
              'sourceFingerprint': 'sha256:ABC',
            },
          ];
        final staleCohort = Map<String, Object?>.from(claim)
          ..['cohortFingerprint'] =
              'sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

        for (final invalidClaim in [malformedMember, staleCohort]) {
          final result = decodeNarrativeEventRegistry({
            ..._registryJson(),
            'legacyClaims': [invalidClaim],
          });
          expect(_decodeState(result), 'invalid');
          expect(result.runtimeAllowed, isFalse);
        }
      },
    );
  });

  group('ProjectManifest Event registry preflight', () {
    test('keeps old manifests registry-free through round-trip', () {
      final oldJson = _minimalManifestJson();
      final manifest = ProjectManifest.fromJsonPokeMapBetaV1ForTest(oldJson);

      expect(manifest.eventRegistry, isNull);
      expect(manifest.toJson(), isNot(contains('eventRegistry')));

      final preflight = preflightProjectManifestJson(
        utf8.encode(jsonEncode(oldJson)),
      );
      expect(preflight.manifest, isNotNull);
      expect(_decodeState(preflight.eventRegistry), 'absent');
      expect(preflight.effectiveMode, EventSystemMode.legacyOnly);
      expect(preflight.writable, isTrue);
    });

    test('treats explicit null as absent and omits it on the next encode', () {
      final json = {..._minimalManifestJson(), 'eventRegistry': null};
      final preflight = preflightProjectManifestJson(
        utf8.encode(jsonEncode(json)),
      );

      expect(_decodeState(preflight.eventRegistry), 'absent');
      expect(preflight.manifest?.eventRegistry, isNull);
      expect(preflight.manifest?.toJson(), isNot(contains('eventRegistry')));
    });

    test('round-trips a valid registry without changing ProjectVersion', () {
      final json = {
        ..._minimalManifestJson(),
        'eventRegistry': _registryJson(mode: 'v2Only'),
      };
      final manifest = ProjectManifest.fromJsonPokeMapBetaV1ForTest(json);

      expect(manifest.version, ProjectVersion.v6);
      expect(manifest.eventRegistry?.mode, EventSystemMode.v2Only);
      expect(manifest.toJson()['eventRegistry'], _registryJson(mode: 'v2Only'));
    });

    test(
      'retains raw future subtree and original bytes while decoding the rest',
      () {
        final rawRegistry = {
          ..._registryJson(),
          'futureField': {'value': 1},
        };
        final json = {
          ..._minimalManifestJson(),
          'unknownRootField': true,
          'eventRegistry': rawRegistry,
        };
        final bytes = utf8.encode(jsonEncode(json));
        final preflight = preflightProjectManifestJson(bytes);

        expect(preflight.manifest?.name, 'Legacy project');
        expect(_decodeState(preflight.eventRegistry), 'unsupported');
        expect(preflight.eventRegistry.rawEventRegistryJson, rawRegistry);
        expect(preflight.originalJsonBytes, bytes);
        expect(
          () => preflight.originalJsonBytes.add(1),
          throwsUnsupportedError,
        );
        expect(
          () =>
              (preflight.eventRegistry.rawEventRegistryJson! as Map)['new'] = 1,
          throwsUnsupportedError,
        );
        expect(preflight.writable, isFalse);
        expect(preflight.runtimeAllowed, isFalse);
        expect(preflight.migrationAllowed, isFalse);
        expect(preflight.playtestAllowed, isFalse);
        expect(preflight.effectiveMode, isNull);
      },
    );

    test(
      'retains invalid subtree and fails closed without losing the old manifest',
      () {
        final rawRegistry = {..._registryJson(), 'records': null};
        final json = {..._minimalManifestJson(), 'eventRegistry': rawRegistry};
        final preflight = preflightProjectManifestJson(
          utf8.encode(jsonEncode(json)),
        );

        expect(preflight.manifest?.name, 'Legacy project');
        expect(_decodeState(preflight.eventRegistry), 'invalid');
        expect(preflight.eventRegistry.rawEventRegistryJson, rawRegistry);
        expect(preflight.diagnostics, isNotEmpty);
        expect(preflight.writable, isFalse);
        expect(preflight.runtimeAllowed, isFalse);
      },
    );

    test(
      'rejects duplicate keys in the raw registry before jsonDecode erases them',
      () {
        const json =
            '{"name":"Legacy project","maps":[],"tilesets":[],"eventRegistry":{"schemaVersion":1,"schemaVersion":1,"mode":"legacyOnly","records":[],"legacyClaims":[]}}';
        final bytes = utf8.encode(json);
        final preflight = preflightProjectManifestJson(bytes);

        expect(preflight.manifest, isNull);
        expect(_decodeState(preflight.eventRegistry), 'invalid');
        expect(preflight.writable, isFalse);
        expect(preflight.originalJsonBytes, bytes);
        expect(
          preflight.eventRegistry.diagnostics.single,
          contains(r'$.eventRegistry.schemaVersion'),
        );
      },
    );

    test('rejects duplicate keys anywhere in the raw project JSON', () {
      const json = '{"name":"first","name":"second","maps":[],"tilesets":[]}';
      final bytes = utf8.encode(json);
      final preflight = preflightProjectManifestJson(bytes);

      expect(preflight.manifest, isNull);
      expect(_decodeState(preflight.eventRegistry), 'invalid');
      expect(preflight.writable, isFalse);
      expect(preflight.originalJsonBytes, bytes);
      expect(preflight.eventRegistry.diagnostics.single, contains(r'$.name'));
    });

    test(
      'direct ProjectManifest decoding also fails closed for future registry data',
      () {
        expect(
          () => ProjectManifest.fromJsonPokeMapBetaV1ForTest({
            ..._minimalManifestJson(),
            'eventRegistry': {..._registryJson(), 'future': true},
          }),
          throwsFormatException,
        );
      },
    );

    test('rejects malformed project bytes before exposing capabilities', () {
      final preflight = preflightProjectManifestJson(utf8.encode('{bad json'));
      expect(preflight.manifest, isNull);
      expect(preflight.writable, isFalse);
      expect(preflight.runtimeAllowed, isFalse);
      expect(preflight.diagnostics, isNotEmpty);
    });
  });
}

void _expectFailClosed(EventRegistryDecodeResult result, Object? raw) {
  expect(result.registryOrNull, isNull);
  expect(result.rawEventRegistryJson, raw);
  expect(result.diagnostics, isNotEmpty);
  expect(result.writable, isFalse);
  expect(result.runtimeAllowed, isFalse);
  expect(result.migrationAllowed, isFalse);
  expect(result.playtestAllowed, isFalse);
  expect(() => result.toJson(), throwsStateError);
}

String _decodeState(EventRegistryDecodeResult result) {
  return result.when(
    absent: () => 'absent',
    decoded: (_) => 'decoded',
    unsupported: (_, __) => 'unsupported',
    invalid: (_, __) => 'invalid',
  );
}

Map<String, Object?> _registryJson({String mode = 'legacyOnly'}) => {
  'schemaVersion': 1,
  'mode': mode,
  'records': <Object?>[],
  'legacyClaims': <Object?>[],
};

Map<String, Object?> _minimalManifestJson() => {
  'name': 'Legacy project',
  'version': 'v6',
  'maps': <Object?>[],
  'tilesets': <Object?>[],
  'pokemon': const ProjectPokemonConfig(
    ruleset: PokemonRulesetProfile.pokeMapBetaV1,
  ).toJson(),
};

LegacySourceClaim _validClaim() {
  final source = NarrativeEventSourceRef.mapEnter('map_port');
  final member = LegacySourceClaimMember(
    provenance: LegacySourceRef.mapEvent('map_port', 'legacy'),
    sourceFingerprint:
        'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  );
  final cohortId = computeLegacySourceCohortId(source, [member.provenance]);
  return LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: [member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(cohortId, [member]),
    targetEventIds: const ['evt_019abcde-0000-7000-8000-000000000001'],
    migrationReceiptId: 'receipt_1',
  );
}
