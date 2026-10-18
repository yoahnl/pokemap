import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

Map<String, Object?> _json(List<int> archive, List<int> section) => {
      'kind': 'sourceInterpretationProfile',
      'schemaVersion': 1,
      'profileId': 'synthetic-static-profile',
      'semanticsId': 'rmxp-essentials-static-v1',
      'scriptsArchive': {
        'relativePath': 'Data/Scripts.rxdata',
        'sha256': _hash(archive).value
      },
      'capabilities': ['walking'],
      'sections': {
        for (final role in ['Game_Map', 'Game_Character', 'TerrainTag'])
          'walking.$role': {
            'index': 0,
            'name': 'Synthetic',
            'sha256': _hash(section).value
          }
      }
    };
Sha256Hash _hash(List<int> bytes) =>
    Sha256Hash(crypto.sha256.convert(bytes).toString());
List<int> _packed(int value) => value == 0
    ? [0]
    : value < 123
        ? [value + 5]
        : [2, value & 255, value >> 8];
List<int> _string(List<int> value) => [34, ..._packed(value.length), ...value];
List<int> _archive(List<int> section) => [
      4,
      8,
      91,
      6,
      91,
      8,
      105,
      0,
      ..._string(utf8.encode('Synthetic')),
      ..._string(zlib.encode(section))
    ];
SourceSnapshot _snapshot(List<int> bytes) => SourceSnapshot(
    logicalProjectNamespace: ConverterId('synthetic-source'),
    policyHash: _hash([1]),
    entries: [
      SourceFileEntry(
          fileId: ConverterId('scripts'),
          relativePath: 'Data/Scripts.rxdata',
          kind: SourceNodeKind.file,
          byteLength: bytes.length,
          sha256: _hash(bytes),
          format: 'ruby-marshal',
          family: 'rmxp')
    ],
    diagnostics: [],
    excludedPaths: [],
    profileEvidence: [],
    state: SourceScanState.complete);

final class _Files implements SourceFilePort {
  _Files(this.bytes);
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId fileId) async => bytes;
}

void main() {
  const knownArchive =
      '3cfd90e8af16ab072807362b0b4da0aceb4fb5064e21396de81859827e0cb81d';
  test(
      'a known archive never implicitly qualifies walking without a selected profile',
      () {
    final profile = SourceSemanticProfile(
        scriptsArchiveHash: Sha256Hash(knownArchive),
        sourceSnapshotHash: Sha256Hash('a' * 64),
        sourceSelectionHash: Sha256Hash('b' * 64));
    expect(profile.isQualified, isFalse);
  });
  test(
      'a known archive never implicitly qualifies events without a selected profile',
      () {
    final profile = SourceEventProfile(
        scriptsArchiveHash: Sha256Hash(knownArchive),
        sourceSnapshotHash: Sha256Hash('a' * 64),
        normalizationHash: Sha256Hash('b' * 64));
    expect(profile.isQualified, isFalse);
  });
  test('explicit profile validates exact inert archive and section witnesses',
      () async {
    final section = utf8.encode('unexecuted source bytes');
    final bytes = _archive(section);
    final profile = SourceInterpretationProfile.fromJson(_json(bytes, section));
    await profile.verifySource(
        snapshot: _snapshot(bytes), files: _Files(bytes));
    final replay = SourceInterpretationProfile.fromJson(
        jsonDecode(jsonEncode(profile.toJson())));
    expect(replay.canonicalHash, profile.canonicalHash);
    expect(
        SourceSemanticProfile(
                scriptsArchiveHash: _hash(bytes),
                sourceSnapshotHash: _hash([1]),
                sourceSelectionHash: _hash([2]),
                interpretationProfile: profile)
            .isQualified,
        isTrue);
    expect(() => profile.sections['walking.Game_Map']!['index'] = 1,
        throwsUnsupportedError);
    expect(() => profile.capabilities.add('events'), throwsUnsupportedError);
  });
  test(
      'profile strict schema rejects unknown fields capabilities and excessive sections',
      () {
    final bytes = _archive([1]);
    for (final value in [
      {
        ..._json(bytes, [1]),
        'implicitFallback': true
      },
      {
        ..._json(bytes, [1]),
        'schemaVersion': 0
      },
      {
        ..._json(bytes, [1]),
        'capabilities': ['unknown']
      },
      {
        ..._json(bytes, [1]),
        'capabilities': ['walking', 'walking']
      },
      {
        ..._json(bytes, [1]),
        'sections': {
          for (var i = 0; i < 129; i++)
            'walking.role$i': {
              'index': 0,
              'sha256': _hash([1]).value
            }
        }
      },
      {
        ..._json(bytes, [1]),
        'scriptsArchive': {
          'relativePath': '../Scripts.rxdata',
          'sha256': _hash(bytes).value
        }
      },
    ]) {
      expect(() => SourceInterpretationProfile.fromJson(value),
          throwsA(isA<ContractError>()));
    }
  });
  test('profile identity includes every witness and selection', () {
    final bytes = _archive([1]);
    final first = SourceInterpretationProfile.fromJson(_json(bytes, [1]));
    final changed = SourceInterpretationProfile.fromJson({
      ..._json(bytes, [1]),
      'profileId': 'other-profile'
    });
    expect(changed.canonicalHash, isNot(first.canonicalHash));
    final missing = SourceInterpretationProfile.fromJson(_json(bytes, [2]));
    expect(missing.canonicalHash, isNot(first.canonicalHash));
  });
  test('wrong archive and changed file refuse before normalization or output',
      () async {
    final bytes = _archive([1]);
    final profile = SourceInterpretationProfile.fromJson(_json(bytes, [1]));
    await expectLater(
        profile.verifySource(
            snapshot: _snapshot(_archive([2])), files: _Files(bytes)),
        throwsA(isA<ContractError>().having(
            (e) => e.code, 'code', 'interpretation_profile.source_mismatch')));
    await expectLater(
        const RmxpSourceNormalizer().normalize(
            snapshot: _snapshot(bytes),
            files: _Files(_archive([2])),
            interpretationProfile: profile),
        throwsA(isA<ContractError>().having(
            (e) => e.code, 'code', 'interpretation_profile.source_changed')));
  });
  test(
      'matching archive never conceals mismatched or malformed section witnesses',
      () async {
    final bytes = _archive([1]);
    await expectLater(
        SourceInterpretationProfile.fromJson(_json(bytes, [2]))
            .verifySource(snapshot: _snapshot(bytes), files: _Files(bytes)),
        throwsA(isA<ContractError>().having(
            (e) => e.code, 'code', 'interpretation_profile.section_mismatch')));
    final malformed = [4, 8, 91, 6, 48];
    await expectLater(
        SourceInterpretationProfile.fromJson(_json(malformed, [1]))
            .verifySource(
                snapshot: _snapshot(malformed), files: _Files(malformed)),
        throwsA(isA<ContractError>().having(
            (e) => e.code, 'code', 'interpretation_profile.section_shape')));
  });
}
