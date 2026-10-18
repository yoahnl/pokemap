import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;

import 'package:avelune_converter_core/avelune_converter_core.dart';

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
  'schemaVersion': 2,
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

final fixtureSourceInterpretationProfile =
    SourceInterpretationProfile.fromJson({
  ...syntheticSourceInterpretationProfile.toJson(),
  'profileId': 'synthetic-declared-services',
  'capabilities': ['events', 'walking', 'encounters', 'autotiles'],
  'sections': {
    ...syntheticSourceInterpretationProfile.toJson()['sections'] as Map,
    'autotiles.Synthetic': {
      'index': 0,
      'name': 'Synthetic',
      'sha256': crypto.sha256.convert(syntheticInterpretationSection).toString()
    }
  },
  'declaredPrograms': jsonDecode([
    'test/fixtures/synthetic_declared_programs.json',
    '../avelune_converter_core/test/fixtures/synthetic_declared_programs.json',
    '../../packages/avelune_converter_core/test/fixtures/synthetic_declared_programs.json',
  ].map(File.new).firstWhere((file) => file.existsSync()).readAsStringSync())
});

SourceInterpretationProfile externalOracleInterpretationProfile(
    {Map<String, String>? environment}) {
  final path =
      (environment ?? Platform.environment)['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  if (path == null || path.isEmpty || !File(path).isAbsolute) {
    throw StateError(
        'An explicit absolute AVELUNE_CONVERTER_ORACLE_PROFILE is required.');
  }
  return SourceInterpretationProfile.fromJson(
      jsonDecode(File(path).readAsStringSync()));
}
