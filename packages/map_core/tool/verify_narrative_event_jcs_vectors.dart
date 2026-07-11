import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

void main() {
  final fixture = File.fromUri(
    Platform.script.resolve(
      '../test/fixtures/narrative_event_jcs/vectors.json',
    ),
  );
  final root = jsonDecode(fixture.readAsStringSync()) as Map<String, dynamic>;
  final failures = <String>[];
  const expectedSections = {
    'schemaVersion',
    'canonicalCases',
    'officialCorpus',
    'numberCases',
    'rejectedNumberCases',
    'invalidRawCases',
    'phaseBHashes',
    'claimCases',
  };
  if (root.keys.toSet().difference(expectedSections).isNotEmpty ||
      expectedSections.difference(root.keys.toSet()).isNotEmpty) {
    failures.add('Fixture sections do not match the version 1 schema.');
  }
  if (root['schemaVersion'] != 1) {
    failures.add('Unsupported fixture schema version.');
  }
  final ids = <String>{};

  void register(Map<String, dynamic> vector) {
    final id = vector['id'];
    if (id is! String || id.isEmpty || !ids.add(id)) {
      failures.add('Every vector must have a unique non-empty id: $id');
    }
    final provenance = vector['provenance'];
    if (provenance is! String || provenance.isEmpty) {
      failures.add('$id: missing provenance');
    }
  }

  for (final value in root['canonicalCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    register(vector);
    final canonical = canonicalizeNarrativeEventJson(vector['input']);
    final digest = narrativeEventCanonicalSha256(vector['input']);
    if (canonical != vector['canonical']) {
      failures.add('${vector['id']}: canonical output mismatch');
    }
    if (digest != vector['sha256']) {
      failures.add('${vector['id']}: SHA-256 mismatch');
    }
  }

  final corpus = root['officialCorpus'] as Map<String, dynamic>;
  if ((corpus['upstreamCommit'] as String?)?.length != 40 ||
      (corpus['provenance'] as String?)?.isEmpty != false) {
    failures.add('Official corpus provenance is incomplete.');
  }
  for (final caseName in corpus['cases'] as List<dynamic>) {
    final input = File.fromUri(
      fixture.uri.resolve('official/input/$caseName.json'),
    ).readAsStringSync();
    final expectedHex = File.fromUri(
      fixture.uri.resolve('official/outhex/$caseName.txt'),
    ).readAsStringSync().trim();
    final expectedBytes = expectedHex
        .split(RegExp(r'\s+'))
        .map((value) => int.parse(value, radix: 16))
        .toList();
    try {
      final actual = canonicalizeNarrativeEventJsonUtf8(
        decodeNarrativeEventJsonStrict(input),
      );
      if (!_listEquals(actual, expectedBytes)) {
        failures.add('$caseName: official corpus output mismatch');
      }
    } on Object catch (error) {
      failures.add('$caseName: official corpus failed: $error');
    }
  }

  for (final value in root['numberCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    final number = _doubleFromIeee754Hex(vector['ieee754Hex'] as String);
    if (canonicalizeNarrativeEventJson(number) != vector['canonical']) {
      failures.add('${vector['ieee754Hex']}: number output mismatch');
    }
    if (narrativeEventCanonicalSha256(number) != vector['sha256']) {
      failures.add('${vector['ieee754Hex']}: number SHA-256 mismatch');
    }
  }
  for (final value in root['rejectedNumberCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    final number = _doubleFromIeee754Hex(vector['ieee754Hex'] as String);
    if (!_throwsFormatException(
      () => canonicalizeNarrativeEventJson(number),
    )) {
      failures.add('${vector['ieee754Hex']}: forbidden number was accepted');
    }
  }

  for (final value in root['invalidRawCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    register(vector);
    final rawJson = vector['rawJson'] as String;
    switch (vector['operation']) {
      case 'canonicalizeDecoded':
        if (!_throwsFormatException(
          () => canonicalizeNarrativeEventJson(jsonDecode(rawJson)),
        )) {
          failures.add('${vector['id']}: invalid decoded value was accepted');
        }
      case 'canonicalizeText':
        if (!_throwsFormatException(
          () => canonicalizeNarrativeEventJsonText(rawJson),
        )) {
          failures.add('${vector['id']}: duplicate raw key was accepted');
        }
      case 'preflightProject':
        final expected = vector['expectedDiagnosticContains'] as String;
        final result = preflightProjectManifestJson(utf8.encode(rawJson));
        final rejected = result.eventRegistry.when(
          absent: () => false,
          decoded: (_) => false,
          unsupported: (_, __) => false,
          invalid: (_, diagnostics) =>
              diagnostics.any((message) => message.contains(expected)),
        );
        if (!rejected) {
          failures.add('${vector['id']}: project duplicate was accepted');
        }
      default:
        failures.add('${vector['id']}: unknown invalid operation');
    }
  }

  for (final value in root['phaseBHashes'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    register(vector);
    final preimage = vector['preimage'] as String;
    final decoded = jsonDecode(preimage);
    if (canonicalizeNarrativeEventJson(decoded) != preimage) {
      failures.add('${vector['id']}: preimage is not canonical');
    }
    if (narrativeEventCanonicalSha256(decoded) != vector['sha256']) {
      failures.add('${vector['id']}: Phase B SHA-256 mismatch');
    }
  }

  for (final value in root['claimCases'] as List<dynamic>) {
    final vector = value as Map<String, dynamic>;
    register(vector);
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
    if (cohortPreimage != vector['cohortPreimage'] ||
        cohortId != vector['cohortId'] ||
        fingerprintPreimage != vector['fingerprintPreimage'] ||
        computeLegacySourceCohortFingerprint(cohortId, members) !=
            vector['cohortFingerprint']) {
      failures.add('${vector['id']}: claim golden mismatch');
    }
  }

  if (failures.isNotEmpty) {
    throw StateError(failures.join('\n'));
  }
  stdout.writeln(
    'Verified ${(root['canonicalCases'] as List).length} canonical vectors '
    '${(corpus['cases'] as List).length} official corpus pairs, '
    '${(root['numberCases'] as List).length} number vectors, '
    '${(root['invalidRawCases'] as List).length} rejection vectors, '
    '${(root['phaseBHashes'] as List).length} Phase B hashes, and '
    '${(root['claimCases'] as List).length} claim vectors.',
  );
}

bool _throwsFormatException(Object? Function() callback) {
  try {
    callback();
    return false;
  } on FormatException {
    return true;
  }
}

bool _listEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

double _doubleFromIeee754Hex(String hex) {
  final bits = BigInt.parse(hex, radix: 16);
  final data = ByteData(8)
    ..setUint32(0, (bits >> 32).toInt(), Endian.big)
    ..setUint32(4, (bits & BigInt.from(0xffffffff)).toInt(), Endian.big);
  return data.getFloat64(0, Endian.big);
}
