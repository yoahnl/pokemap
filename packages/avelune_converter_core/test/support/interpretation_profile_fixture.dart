import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;

import 'package:avelune_converter_core/avelune_converter_core.dart';

final fixtureSourceInterpretationProfile =
    SourceInterpretationProfile.fromJson(jsonDecode([
  'test/fixtures/attested_rmxp_corpus_profile.json',
  '../avelune_converter_core/test/fixtures/attested_rmxp_corpus_profile.json',
  '../../packages/avelune_converter_core/test/fixtures/attested_rmxp_corpus_profile.json',
].map(File.new).firstWhere((file) => file.existsSync()).readAsStringSync()));

final syntheticInterpretationSection =
    utf8.encode('synthetic source never executed');
List<int> _size(int value) => value == 0
    ? [0]
    : value < 123
        ? [value + 5]
        : [2, value & 255, value >> 8];
List<int> _bytes(List<int> bytes) => [34, ..._size(bytes.length), ...bytes];
final syntheticInterpretationArchive = <int>[
  4,
  8,
  91,
  6,
  91,
  8,
  105,
  0,
  ..._bytes(utf8.encode('Synthetic')),
  ..._bytes(zlib.encode(syntheticInterpretationSection))
];
final syntheticSourceInterpretationProfile =
    SourceInterpretationProfile.fromJson({
  'kind': 'sourceInterpretationProfile',
  'schemaVersion': 1,
  'profileId': 'synthetic-static-profile',
  'semanticsId': 'rmxp-essentials-static-v1',
  'scriptsArchive': {
    'relativePath': 'Data/Scripts.rxdata',
    'sha256': crypto.sha256.convert(syntheticInterpretationArchive).toString()
  },
  'capabilities': ['events', 'walking', 'encounters'],
  'sections': {
    for (final role in [
      'events.Interpreter',
      'walking.Game_Map',
      'walking.Game_Character',
      'walking.TerrainTag'
    ])
      role: {
        'index': 0,
        'name': 'Synthetic',
        'sha256':
            crypto.sha256.convert(syntheticInterpretationSection).toString()
      }
  }
});
