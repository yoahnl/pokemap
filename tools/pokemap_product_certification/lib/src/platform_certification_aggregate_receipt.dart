import 'dart:convert';

import 'package:map_core/map_core.dart';

final class PlatformCertificationAggregateReceipt {
  PlatformCertificationAggregateReceipt._(this._json);

  factory PlatformCertificationAggregateReceipt.fromInputs({
    required Map<String, Object?> platformSupport,
    required Map<String, Object?> platformEvidence,
    required Map<String, Object?> provenance,
  }) {
    _validatePlatformSupport(platformSupport);
    final normalizedProvenance = _validateProvenance(provenance);
    final platforms = _validatePlatformEvidence(platformEvidence);
    final blockingPlatforms = <String>[
      for (final platform in platforms)
        if (platform['status'] != 'passed') platform['platform']! as String,
    ];
    return PlatformCertificationAggregateReceipt._(<String, Object?>{
      'schemaVersion': 1,
      'releaseCommit': normalizedProvenance['releaseCommit'],
      'treeState': normalizedProvenance['treeState'],
      'treeFingerprint': normalizedProvenance['treeFingerprint'],
      'platformSupportSha256': normalizedProvenance['platformSupportSha256'],
      'pluginLockSha256': normalizedProvenance['pluginLockSha256'],
      'bundleVersion': normalizedProvenance['bundleVersion'],
      'pluginVersions': normalizedProvenance['pluginVersions'],
      'verdict': blockingPlatforms.isEmpty ? 'passed' : 'failed',
      'blockingPlatforms': blockingPlatforms,
      'platforms': platforms,
    });
  }

  factory PlatformCertificationAggregateReceipt.fromJson(
    Map<String, Object?> json,
  ) {
    _expectKeys(json, const <String>{
      'schemaVersion',
      'releaseCommit',
      'treeState',
      'treeFingerprint',
      'platformSupportSha256',
      'pluginLockSha256',
      'bundleVersion',
      'pluginVersions',
      'verdict',
      'blockingPlatforms',
      'platforms',
    }, r'$');
    if (json['schemaVersion'] != 1) {
      throw const FormatException(r'$.schemaVersion must be 1.');
    }
    final rebuilt = PlatformCertificationAggregateReceipt.fromInputs(
      platformSupport: _canonicalPlatformSupport(),
      platformEvidence: <String, Object?>{
        'schemaVersion': 1,
        'platforms': json['platforms'],
      },
      provenance: <String, Object?>{
        'releaseCommit': json['releaseCommit'],
        'treeState': json['treeState'],
        'treeFingerprint': json['treeFingerprint'],
        'platformSupportSha256': json['platformSupportSha256'],
        'pluginLockSha256': json['pluginLockSha256'],
        'bundleVersion': json['bundleVersion'],
        'pluginVersions': json['pluginVersions'],
      },
    );
    if (!_deepEquals(rebuilt.toJson(), json)) {
      throw const FormatException(
        'Platform certification receipt is non-canonical or inconsistent.',
      );
    }
    return rebuilt;
  }

  final Map<String, Object?> _json;

  bool get passed => _json['verdict'] == 'passed';

  List<String> get blockingPlatforms => List<String>.unmodifiable(
    (_json['blockingPlatforms']! as List<Object?>).cast<String>(),
  );

  Map<String, Object?> toJson() => _copyMap(_json);

  String encodeCanonical() => jsonEncode(_json);
}

const _platformOrder = <PresentationMediaTargetPlatform>[
  PresentationMediaTargetPlatform.macos,
  PresentationMediaTargetPlatform.ios,
  PresentationMediaTargetPlatform.android,
  PresentationMediaTargetPlatform.windows,
  PresentationMediaTargetPlatform.linux,
  PresentationMediaTargetPlatform.web,
];

const _expectedStatuses = <PresentationMediaTargetPlatform, String>{
  PresentationMediaTargetPlatform.macos: 'supported',
  PresentationMediaTargetPlatform.ios: 'xcode-cloud-target',
  PresentationMediaTargetPlatform.android: 'build-target',
  PresentationMediaTargetPlatform.windows: 'build-and-launch-target',
  PresentationMediaTargetPlatform.linux: 'build-and-launch-target',
  PresentationMediaTargetPlatform.web: 'unsupported',
};

const _expectedTickets = <PresentationMediaTargetPlatform, String>{
  PresentationMediaTargetPlatform.macos: 'BETA-CIN-045',
  PresentationMediaTargetPlatform.ios: 'BETA-CIN-046',
  PresentationMediaTargetPlatform.android: 'BETA-CIN-046',
  PresentationMediaTargetPlatform.windows: 'BETA-CIN-047',
  PresentationMediaTargetPlatform.linux: 'BETA-CIN-047',
  PresentationMediaTargetPlatform.web: 'BETA-CIN-047',
};

const _expectedPackageManagers = <PresentationMediaTargetPlatform, String>{
  PresentationMediaTargetPlatform.macos: 'spm-only',
  PresentationMediaTargetPlatform.ios: 'spm-only',
  PresentationMediaTargetPlatform.android: 'gradle',
  PresentationMediaTargetPlatform.windows: 'native-runner',
  PresentationMediaTargetPlatform.linux: 'native-runner',
  PresentationMediaTargetPlatform.web: 'none',
};

const _expectedBundleIds = <PresentationMediaTargetPlatform, String?>{
  PresentationMediaTargetPlatform.macos: 'app.pokemap.hub',
  PresentationMediaTargetPlatform.ios: 'com.yoahnl.avelune.player',
  PresentationMediaTargetPlatform.android: 'com.yoahnl.avelune.player',
  PresentationMediaTargetPlatform.windows: null,
  PresentationMediaTargetPlatform.linux: null,
  PresentationMediaTargetPlatform.web: null,
};

void _validatePlatformSupport(Map<String, Object?> json) {
  _expectKeys(json, const <String>{
    'schemaVersion',
    'platforms',
  }, r'$.platformSupport');
  if (json['schemaVersion'] != 2) {
    throw const FormatException(r'$.platformSupport.schemaVersion must be 2.');
  }
  final platforms = _map(json['platforms'], r'$.platformSupport.platforms');
  final expectedNames = _platformOrder.map((platform) => platform.name).toSet();
  if (!_sameStrings(platforms.keys, expectedNames)) {
    throw const FormatException(
      r'$.platformSupport.platforms must contain exactly six platforms.',
    );
  }
  for (final platform in _platformOrder) {
    final path = r'$.platformSupport.platforms.' + platform.name;
    final value = _map(platforms[platform.name], path);
    if (value['status'] != _expectedStatuses[platform]) {
      throw FormatException('$path.status is inconsistent.');
    }
    final capabilities = _map(value['capabilities'], '$path.capabilities');
    _expectKeys(capabilities, const <String>{
      'image',
      'audio',
      'video',
      'captions',
    }, '$path.capabilities');
    final expected = presentationMediaPlatformCapabilities(platform).toJson();
    if (!_deepEquals(capabilities, expected)) {
      throw FormatException('$path.capabilities is inconsistent.');
    }
  }
}

List<Map<String, Object?>> _validatePlatformEvidence(
  Map<String, Object?> json,
) {
  _expectKeys(json, const <String>{
    'schemaVersion',
    'platforms',
  }, r'$.evidence');
  if (json['schemaVersion'] != 1) {
    throw const FormatException(r'$.evidence.schemaVersion must be 1.');
  }
  final rawPlatforms = json['platforms'];
  if (rawPlatforms is! List<Object?>) {
    throw const FormatException(r'$.evidence.platforms must be an array.');
  }
  final indexed = <String, Map<String, Object?>>{};
  for (final rawPlatform in rawPlatforms) {
    final platform = _map(rawPlatform, r'$.evidence.platforms[]');
    final name = _string(platform['platform'], r'$.platforms[].platform');
    if (indexed.putIfAbsent(name, () => platform) != platform) {
      throw FormatException('Duplicate platform receipt: $name.');
    }
  }
  if (!_sameStrings(
    indexed.keys,
    _platformOrder.map((platform) => platform.name),
  )) {
    throw const FormatException(
      r'$.evidence.platforms must contain exactly six receipts.',
    );
  }
  return <Map<String, Object?>>[
    for (final platform in _platformOrder)
      _normalizePlatformEvidence(platform, indexed[platform.name]!),
  ];
}

Map<String, Object?> _normalizePlatformEvidence(
  PresentationMediaTargetPlatform platform,
  Map<String, Object?> json,
) {
  _expectKeys(json, const <String>{
    'platform',
    'verdict',
    'status',
    'sourceTicket',
    'sourceCommit',
    'build',
    'smoke',
    'policy',
    'packageManager',
    'bundleId',
    'commands',
    'limitations',
  }, r'$.evidence.platforms[]');
  final path = r'$.evidence.platforms.' + platform.name;
  if (json['platform'] != platform.name) {
    throw FormatException('$path.platform is inconsistent.');
  }
  final verdict = _string(json['verdict'], '$path.verdict');
  final expectedVerdict = _expectedVerdict(platform);
  if (verdict != expectedVerdict) {
    throw FormatException('$path.verdict must be $expectedVerdict.');
  }
  final status = _enumString(json['status'], const <String>{
    'passed',
    'failed',
  }, '$path.status');
  if (json['sourceTicket'] != _expectedTickets[platform]) {
    throw FormatException('$path.sourceTicket is inconsistent.');
  }
  final sourceCommit = _digest(json['sourceCommit'], '$path.sourceCommit', 40);
  final build = _enumString(json['build'], const <String>{
    'passed',
    'target',
    'not-applicable',
  }, '$path.build');
  final smoke = _enumString(json['smoke'], const <String>{
    'passed',
    'equivalent',
    'target',
    'not-applicable',
  }, '$path.smoke');
  if (json['policy'] != 'passed') {
    throw FormatException('$path.policy must be passed.');
  }
  final packageManager = _string(
    json['packageManager'],
    '$path.packageManager',
  );
  if (packageManager != _expectedPackageManagers[platform]) {
    throw FormatException('$path.packageManager is inconsistent.');
  }
  final bundleId = _nullableString(json['bundleId'], '$path.bundleId');
  if (bundleId != _expectedBundleIds[platform]) {
    throw FormatException('$path.bundleId is inconsistent.');
  }
  final commands = _strings(
    json['commands'],
    '$path.commands',
    allowEmpty: false,
  );
  final limitations = _strings(json['limitations'], '$path.limitations');
  if (verdict == 'supported') {
    if (build != 'passed' || (smoke != 'passed' && smoke != 'equivalent')) {
      throw FormatException('$path lacks supported build and smoke evidence.');
    }
  } else if (verdict == 'fallback-only') {
    if (build != 'target' || smoke != 'target' || limitations.isEmpty) {
      throw FormatException('$path lacks fallback limitations.');
    }
  } else if (build != 'not-applicable' ||
      smoke != 'not-applicable' ||
      limitations.isEmpty) {
    throw FormatException('$path lacks out-of-scope evidence.');
  }
  for (final value in <String>[...commands, ...limitations]) {
    _safeText(value, path);
  }
  return <String, Object?>{
    'platform': platform.name,
    'verdict': verdict,
    'status': status,
    'sourceTicket': _expectedTickets[platform],
    'sourceCommit': sourceCommit,
    'build': build,
    'smoke': smoke,
    'policy': 'passed',
    'packageManager': packageManager,
    'bundleId': bundleId,
    'commands': commands,
    'limitations': limitations,
  };
}

Map<String, Object?> _validateProvenance(Map<String, Object?> json) {
  _expectKeys(json, const <String>{
    'releaseCommit',
    'treeState',
    'treeFingerprint',
    'platformSupportSha256',
    'pluginLockSha256',
    'bundleVersion',
    'pluginVersions',
  }, r'$.provenance');
  if (json['treeState'] != 'clean') {
    throw const FormatException(r'$.provenance.treeState must be clean.');
  }
  final pluginVersions = _map(
    json['pluginVersions'],
    r'$.provenance.pluginVersions',
  );
  final bundleVersion = _string(
    json['bundleVersion'],
    r'$.provenance.bundleVersion',
  );
  if (!RegExp(
    r'^[0-9]+\.[0-9]+\.[0-9]+\+[1-9][0-9]*$',
  ).hasMatch(bundleVersion)) {
    throw const FormatException(
      r'$.provenance.bundleVersion must be a semantic version with build.',
    );
  }
  if (!pluginVersions.keys.toSet().containsAll(<String>{
        'audioplayers',
        'video_player',
      }) ||
      pluginVersions.isEmpty) {
    throw const FormatException(r'$.provenance.pluginVersions is incomplete.');
  }
  final sortedPlugins = <String, Object?>{};
  for (final key in pluginVersions.keys.toList()..sort()) {
    final version = _string(
      pluginVersions[key],
      r'$.provenance.pluginVersions.' + key,
    );
    if (!RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+(?:\+[0-9]+)?$').hasMatch(version)) {
      throw FormatException('Invalid plugin version for $key.');
    }
    sortedPlugins[key] = version;
  }
  return <String, Object?>{
    'releaseCommit': _digest(
      json['releaseCommit'],
      r'$.provenance.releaseCommit',
      40,
    ),
    'treeState': 'clean',
    'treeFingerprint': _digest(
      json['treeFingerprint'],
      r'$.provenance.treeFingerprint',
      64,
    ),
    'platformSupportSha256': _digest(
      json['platformSupportSha256'],
      r'$.provenance.platformSupportSha256',
      64,
    ),
    'pluginLockSha256': _digest(
      json['pluginLockSha256'],
      r'$.provenance.pluginLockSha256',
      64,
    ),
    'bundleVersion': bundleVersion,
    'pluginVersions': sortedPlugins,
  };
}

String _expectedVerdict(PresentationMediaTargetPlatform platform) {
  final capabilities = presentationMediaPlatformCapabilities(platform);
  final values = capabilities.toJson().values.toSet();
  if (values.length == 1 && values.single == 'supported') return 'supported';
  if (values.contains('fallback-only')) return 'fallback-only';
  if (values.length == 1 && values.single == 'unsupported') {
    return 'out-of-scope';
  }
  throw FormatException('Platform ${platform.name} has no explicit verdict.');
}

Map<String, Object?> _canonicalPlatformSupport() => <String, Object?>{
  'schemaVersion': 2,
  'platforms': <String, Object?>{
    for (final platform in _platformOrder)
      platform.name: <String, Object?>{
        'status': _expectedStatuses[platform],
        'capabilities': presentationMediaPlatformCapabilities(
          platform,
        ).toJson(),
      },
  },
};

void _expectKeys(Map<String, Object?> json, Set<String> expected, String path) {
  if (!_sameStrings(json.keys, expected)) {
    throw FormatException('$path contains missing or unexpected fields.');
  }
}

bool _sameStrings(Iterable<String> left, Iterable<String> right) =>
    left.toSet().difference(right.toSet()).isEmpty &&
    right.toSet().difference(left.toSet()).isEmpty;

Map<String, Object?> _map(Object? value, String path) {
  if (value is! Map) throw FormatException('$path must be an object.');
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String _string(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return value;
}

String? _nullableString(Object? value, String path) {
  if (value == null) return null;
  return _string(value, path);
}

String _enumString(Object? value, Set<String> allowed, String path) {
  final parsed = _string(value, path);
  if (!allowed.contains(parsed)) {
    throw FormatException('$path has an unsupported value.');
  }
  return parsed;
}

String _digest(Object? value, String path, int length) {
  final parsed = _string(value, path);
  if (!RegExp('^[0-9a-f]{$length}\$').hasMatch(parsed)) {
    throw FormatException('$path must be a lowercase hexadecimal digest.');
  }
  return parsed;
}

List<String> _strings(Object? value, String path, {bool allowEmpty = true}) {
  if (value is! List<Object?> || (!allowEmpty && value.isEmpty)) {
    throw FormatException('$path must be an array of strings.');
  }
  return List<String>.unmodifiable(
    value.map((entry) => _string(entry, '$path[]')),
  );
}

void _safeText(String value, String path) {
  final unsafe = <RegExp>[
    RegExp(r'(^|\s)/Users/'),
    RegExp(r'(^|\s)[A-Za-z]:\\Users\\'),
    RegExp(r'file:///'),
    RegExp(
      r'(authorization|password|secret|api[_-]?key)\s*[:=]',
      caseSensitive: false,
    ),
  ];
  if (unsafe.any((pattern) => pattern.hasMatch(value))) {
    throw FormatException('$path contains local or credential data.');
  }
}

Map<String, Object?> _copyMap(Map<String, Object?> source) =>
    jsonDecode(jsonEncode(source)) as Map<String, Object?>;

bool _deepEquals(Object? left, Object? right) =>
    jsonEncode(left) == jsonEncode(right);
