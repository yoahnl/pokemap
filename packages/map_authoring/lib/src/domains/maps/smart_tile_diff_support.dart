import 'dart:convert';

import '../../support/authoring_fingerprint.dart';

const maximumSmartTileInlineDiffByteLength = 64 * 1024;

Object? smartTileDiffValue(Object? value) {
  if (value is! Map) return value;
  final bytes = utf8.encode(canonicalAuthoringJson(value));
  if (bytes.length <= maximumSmartTileInlineDiffByteLength) return value;
  final coverageProfile = value['coverageProfile'];
  final metadata = {
    for (final key in ['id', 'name', 'targetPresetId', 'sourcePresetId'])
      if (value.containsKey(key))
        key: value[key] is String
            ? String.fromCharCodes((value[key] as String).runes.take(256))
            : value[key],
  };
  return {
    'documentSummary': {
      ...metadata,
      'truncatedFields': [
        for (final entry in metadata.entries)
          if (value[entry.key] is String && entry.value != value[entry.key])
            entry.key,
      ],
      'fingerprintDomain': 'smart-tile-document.json',
      'fingerprint': computeAuthoringBytesFingerprint(bytes,
          logicalName: 'smart-tile-document.json'),
      'byteLength': bytes.length,
      'counts': {
        for (final key in [
          'categories',
          'atlases',
          'materials',
          'animations',
          'allowedMaterialIds',
          'rules',
          'presets',
          'patterns',
          'drafts',
        ])
          if (value[key] is List) key: (value[key] as List).length,
        if (coverageProfile is Map &&
            coverageProfile['requiredScenarios'] is List)
          'coverageScenarios':
              (coverageProfile['requiredScenarios'] as List).length,
      },
    },
  };
}
