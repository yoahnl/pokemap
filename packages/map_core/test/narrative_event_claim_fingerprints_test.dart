import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _sourceFingerprint =
    'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('RFC 8785 canonical JSON', () {
    test('matches the RFC numeric, literal, and property ordering rules', () {
      final value = {
        'numbers': [333333333.33333329, 1e30, 4.50, 2e-3, 1e-27, -0.0],
        'literals': [null, true, false],
      };

      expect(
        canonicalizeNarrativeEventJson(value),
        '{"literals":[null,true,false],"numbers":[333333333.3333333,1e+30,4.5,0.002,1e-27,0]}',
      );
    });

    test('uses UTF-16 key ordering including non-BMP characters', () {
      final canonical = canonicalizeNarrativeEventJson({
        '\u20ac': 'euro',
        '\r': 'carriage return',
        '\ufb33': 'hebrew',
        '1': 'one',
        '😀': 'emoji',
        '\u0080': 'control',
        'ö': 'o umlaut',
      });

      expect(
        (jsonDecode(canonical) as Map<String, dynamic>).keys.toList(),
        ['\r', '1', '\u0080', 'ö', '\u20ac', '😀', '\ufb33'],
      );
    });

    test('keeps arrays ordered, recursively sorts objects, and escapes strings',
        () {
      final first = <String, Object?>{
        'z': [3, 2, 1],
        'a': {'quote': '"', 'slash': '/', 'backslash': '\\', 'line': '\n'},
      };
      final second = <String, Object?>{
        'a': {'line': '\n', 'backslash': '\\', 'slash': '/', 'quote': '"'},
        'z': [3, 2, 1],
      };

      expect(
        canonicalizeNarrativeEventJson(first),
        canonicalizeNarrativeEventJson(second),
      );
      expect(
        canonicalizeNarrativeEventJson(first),
        '{"a":{"backslash":"\\\\","line":"\\n","quote":"\\"","slash":"/"},"z":[3,2,1]}',
      );
    });

    test('produces UTF-8 SHA-256 goldens and rejects non-I-JSON values', () {
      expect(
        narrativeEventCanonicalSha256({'a': 1}),
        '015abd7f5cc57a2dd94b7590f04ad8084273905ee33ec5cebeae62276a97f862',
      );
      expect(
        canonicalizeNarrativeEventJsonUtf8({'é': '€'}),
        utf8.encode('{"é":"€"}'),
      );
      expect(
        () => canonicalizeNarrativeEventJson(double.nan),
        throwsFormatException,
      );
      expect(
        () => canonicalizeNarrativeEventJson(double.infinity),
        throwsFormatException,
      );
      expect(
        canonicalizeNarrativeEventJson(9007199254740992),
        '9007199254740992',
      );
      expect(
        canonicalizeNarrativeEventJson(-9007199254740992),
        '-9007199254740992',
      );
      expect(
        () => canonicalizeNarrativeEventJson(9007199254740993),
        throwsFormatException,
      );
      expect(
        () => canonicalizeNarrativeEventJson(String.fromCharCode(0xd800)),
        throwsFormatException,
      );
      expect(
        () => canonicalizeNarrativeEventJson({1: 'not a string key'}),
        throwsFormatException,
      );
      for (final noncharacter in [
        0xfdd0,
        0xfffe,
        0xffff,
        0x1fffe,
        0x10ffff,
      ]) {
        final value = String.fromCharCode(noncharacter);
        expect(
          () => canonicalizeNarrativeEventJson(value),
          throwsFormatException,
          reason: 'U+${noncharacter.toRadixString(16)}',
        );
        expect(
          () => canonicalizeNarrativeEventJson({value: true}),
          throwsFormatException,
          reason: 'key U+${noncharacter.toRadixString(16)}',
        );
      }
      expect(
        () => canonicalizeNarrativeEventJsonText(
          r'{"a":1,"\u0061":2}',
        ),
        throwsFormatException,
      );
    });
  });

  group('canonical claim fingerprints', () {
    test('matches independent cohort ID and fingerprint goldens', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final provenance = LegacySourceRef.mapEvent('map_port', 'lysa');
      final member = LegacySourceClaimMember(
        provenance: provenance,
        sourceFingerprint: _sourceFingerprint,
      );

      final cohortId = computeLegacySourceCohortId(source, [provenance]);
      expect(
        cohortId,
        'lsc_f33795b3ad4a0b7522087062de7b7fe3d0bfee38c2c8920172821baa13e4e6c5',
      );
      expect(
        computeLegacySourceCohortFingerprint(cohortId, [member]),
        'sha256:8e7c6e870ef25acf92eebf9f2641f198c2f2bd774920099b42f0e1bf16d14e9d',
      );
    });

    test('sorts canonical internal inputs independently of caller order', () {
      final source = NarrativeEventSourceRef.mapEnter('map_port');
      final map = LegacySourceRef.mapEvent('map_port', 'legacy');
      final scenario = LegacySourceRef.scenarioSourceNode('scenario', 'source');
      final first = LegacySourceClaimMember(
        provenance: map,
        sourceFingerprint: _sourceFingerprint,
      );
      final second = LegacySourceClaimMember(
        provenance: scenario,
        sourceFingerprint:
            'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      );

      expect(
        computeLegacySourceCohortId(source, [scenario, map]),
        computeLegacySourceCohortId(source, [map, scenario]),
      );
      final cohortId = computeLegacySourceCohortId(source, [map, scenario]);
      expect(
        computeLegacySourceCohortFingerprint(cohortId, [second, first]),
        computeLegacySourceCohortFingerprint(cohortId, [first, second]),
      );
    });

    test('matches independent complete legacy source fingerprint goldens', () {
      final event = MapEventDefinition(
        id: 'legacy',
        pages: const [MapEventPage(pageNumber: 0)],
        position: const EventPosition(layerId: 'events', x: 2, y: 1),
      );
      final scenario = ScenarioAsset(
        id: 'scenario',
        name: 'Scenario',
        entryNodeId: 'source',
      );

      expect(
        computeMapEventSourceFingerprint(mapId: 'map_port', event: event),
        'sha256:6ea5956cc0973bd2b6ce93cef2ac703dd61035c6b530dac02f08610239b548db',
      );
      expect(
        computeScenarioSourceFingerprint(
          scenarioId: 'scenario',
          nodeId: 'source',
          scenario: scenario,
        ),
        'sha256:e8e4b2a3a69a8b291f9e29497c94d054847d5474d2860bd86d9e90dba446a93e',
      );
    });
  });

  group('committed JCS reproducibility pack', () {
    late Map<String, dynamic> vectors;

    setUpAll(() {
      vectors = jsonDecode(
        File('test/fixtures/narrative_event_jcs/vectors.json')
            .readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(vectors['schemaVersion'], 1);
    });

    test('replays canonical outputs and SHA-256 vectors offline', () {
      for (final value in vectors['canonicalCases'] as List<dynamic>) {
        final vector = value as Map<String, dynamic>;
        expect(
          canonicalizeNarrativeEventJson(vector['input']),
          vector['canonical'],
          reason: vector['id'] as String,
        );
        expect(
          narrativeEventCanonicalSha256(vector['input']),
          vector['sha256'],
          reason: vector['id'] as String,
        );
        expect(vector['provenance'], isNotEmpty);
      }
    });

    test('matches all six pinned upstream corpus outputs byte for byte', () {
      final corpus = vectors['officialCorpus'] as Map<String, dynamic>;
      expect(corpus['upstreamCommit'], hasLength(40));
      expect(corpus['provenance'], isNotEmpty);
      for (final caseName in corpus['cases'] as List<dynamic>) {
        final input = File(
          'test/fixtures/narrative_event_jcs/official/input/$caseName.json',
        ).readAsStringSync();
        final expectedHex = File(
          'test/fixtures/narrative_event_jcs/official/outhex/$caseName.txt',
        ).readAsStringSync().trim();
        final expectedBytes = expectedHex
            .split(RegExp(r'\s+'))
            .map((value) => int.parse(value, radix: 16))
            .toList();

        expect(
          canonicalizeNarrativeEventJsonUtf8(
            decodeNarrativeEventJsonStrict(input),
          ),
          expectedBytes,
          reason: caseName as String,
        );
      }
    });

    test('matches every finite RFC 8785 Appendix B number vector', () {
      for (final value in vectors['numberCases'] as List<dynamic>) {
        final vector = value as Map<String, dynamic>;
        final number = _doubleFromIeee754Hex(
          vector['ieee754Hex'] as String,
        );
        expect(
          canonicalizeNarrativeEventJson(number),
          vector['canonical'],
          reason: vector['ieee754Hex'] as String,
        );
        expect(
          narrativeEventCanonicalSha256(number),
          vector['sha256'],
          reason: vector['ieee754Hex'] as String,
        );
      }
      for (final value in vectors['rejectedNumberCases'] as List<dynamic>) {
        final vector = value as Map<String, dynamic>;
        final number = _doubleFromIeee754Hex(
          vector['ieee754Hex'] as String,
        );
        expect(
          () => canonicalizeNarrativeEventJson(number),
          throwsFormatException,
          reason: vector['reason'] as String,
        );
      }
    });

    test('rejects invalid Unicode numbers and duplicate registry keys', () {
      for (final value in vectors['invalidRawCases'] as List<dynamic>) {
        final vector = value as Map<String, dynamic>;
        final rawJson = vector['rawJson'] as String;
        switch (vector['operation']) {
          case 'canonicalizeDecoded':
            expect(
              () => canonicalizeNarrativeEventJson(jsonDecode(rawJson)),
              throwsFormatException,
              reason: vector['id'] as String,
            );
          case 'canonicalizeText':
            expect(
              () => canonicalizeNarrativeEventJsonText(rawJson),
              throwsFormatException,
              reason: vector['id'] as String,
            );
          case 'preflightProject':
            final result = preflightProjectManifestJson(utf8.encode(rawJson));
            final expected = vector['expectedDiagnosticContains'] as String;
            expect(
              result.eventRegistry.when(
                absent: () => false,
                decoded: (_) => false,
                unsupported: (_, __) => false,
                invalid: (_, diagnostics) =>
                    diagnostics.any((message) => message.contains(expected)),
              ),
              isTrue,
              reason: vector['id'] as String,
            );
          default:
            fail('Unknown raw vector operation ${vector['operation']}');
        }
      }
    });

    test('pins Phase B source and claim preimages and hashes', () {
      for (final value in vectors['phaseBHashes'] as List<dynamic>) {
        final vector = value as Map<String, dynamic>;
        final preimage = vector['preimage'] as String;
        final decoded = jsonDecode(preimage);
        expect(
          canonicalizeNarrativeEventJson(decoded),
          preimage,
          reason: vector['id'] as String,
        );
        expect(
          narrativeEventCanonicalSha256(decoded),
          vector['sha256'],
          reason: vector['id'] as String,
        );
      }

      for (final value in vectors['claimCases'] as List<dynamic>) {
        final vector = value as Map<String, dynamic>;
        final source = NarrativeEventSourceRef.fromJson(vector['source']);
        final provenances = (vector['provenances'] as List<dynamic>)
            .map(LegacySourceRef.fromJson)
            .toList()
          ..sort(compareLegacySourceRefs);
        final members = (vector['members'] as List<dynamic>)
            .map(LegacySourceClaimMember.fromJson)
            .toList()
          ..sort((left, right) {
            final provenance = compareLegacySourceRefs(
              left.provenance,
              right.provenance,
            );
            if (provenance != 0) return provenance;
            return compareNarrativeEventUtf16(
              left.sourceFingerprint,
              right.sourceFingerprint,
            );
          });
        final cohortPreimage = canonicalizeNarrativeEventJson({
          'source': source.toJson(),
          'provenances': [
            for (final provenance in provenances) provenance.toJson(),
          ],
        });
        final cohortId = computeLegacySourceCohortId(source, provenances);
        final fingerprintPreimage = canonicalizeNarrativeEventJson({
          'cohortId': cohortId,
          'members': [for (final member in members) member.toJson()],
        });

        expect(cohortPreimage, vector['cohortPreimage']);
        expect(cohortId, vector['cohortId']);
        expect(fingerprintPreimage, vector['fingerprintPreimage']);
        expect(
          computeLegacySourceCohortFingerprint(cohortId, members),
          vector['cohortFingerprint'],
        );
      }
    });
  });
}

double _doubleFromIeee754Hex(String hex) {
  final bits = BigInt.parse(hex, radix: 16);
  final data = ByteData(8)
    ..setUint32(0, (bits >> 32).toInt(), Endian.big)
    ..setUint32(4, (bits & BigInt.from(0xffffffff)).toInt(), Endian.big);
  return data.getFloat64(0, Endian.big);
}
