import 'dart:convert';
import 'dart:math' as math;

final class PresentationRuntimePerformanceReceipt {
  PresentationRuntimePerformanceReceipt._(this._json);

  factory PresentationRuntimePerformanceReceipt.fromMeasurements({
    required Map<String, Object?> measurements,
    required Map<String, Object?> platformSupport,
    required Map<String, Object?> provenance,
  }) {
    _expectKeys(measurements, const <String>{
      'schemaVersion',
      'benchmark',
      'target',
      'executionMode',
      'platform',
      'fixture',
      'lifecycle',
      'samples',
      'cycleEvidence',
    }, r'$');
    _expectValue(measurements, 'schemaVersion', 1, r'$.schemaVersion');
    _expectValue(
      measurements,
      'benchmark',
      'presentation_runtime_cin_038',
      r'$.benchmark',
    );
    _expectValue(
      measurements,
      'target',
      'integration_test/presentation_runtime_performance_journey_test.dart',
      r'$.target',
    );
    _expectValue(
      measurements,
      'executionMode',
      'flutter-profile',
      r'$.executionMode',
    );
    _expectValue(measurements, 'platform', 'macos', r'$.platform');

    final fixture = _map(measurements['fixture'], r'$.fixture');
    _expectKeys(fixture, const <String>{
      'landscapeVideoAsset',
      'landscapeVideoSha256',
      'portraitVideoAsset',
      'portraitVideoSha256',
      'posterAsset',
      'posterSha256',
    }, r'$.fixture');
    _expectValue(
      fixture,
      'landscapeVideoAsset',
      'assets/certification/intro_landscape_h264_aac.mp4',
      r'$.fixture.landscapeVideoAsset',
    );
    _expectValue(
      fixture,
      'landscapeVideoSha256',
      '5191da50cdedd4203edc1ccca5e1c3055d7f19c616fb570b0c8af992358fe591',
      r'$.fixture.landscapeVideoSha256',
    );
    _expectValue(
      fixture,
      'portraitVideoAsset',
      'assets/certification/intro_portrait_h264_aac.mp4',
      r'$.fixture.portraitVideoAsset',
    );
    _expectValue(
      fixture,
      'portraitVideoSha256',
      'a4759a929512ef967d8a58905f22923e6f15e86707fd7f9100f844880a3972de',
      r'$.fixture.portraitVideoSha256',
    );
    _expectValue(
      fixture,
      'posterAsset',
      'assets/avelune/artwork/fallback_moonlit_path.webp',
      r'$.fixture.posterAsset',
    );
    _expectValue(
      fixture,
      'posterSha256',
      'd0d048a67dfc9b514d39ec9133ac5c547f5e89c83bde27ba73aa10c75d3a4e10',
      r'$.fixture.posterSha256',
    );

    final lifecycle = _map(measurements['lifecycle'], r'$.lifecycle');
    _expectKeys(lifecycle, const <String>{
      'cycles',
      'maximumActiveDecoders',
      'finalActiveDecoders',
      'finalMediaHandles',
      'terminalReceipts',
      'skippedTerminals',
      'rssCycle5Bytes',
      'rssCycle50Bytes',
    }, r'$.lifecycle');
    final normalizedLifecycle = <String, Object?>{
      for (final key in lifecycle.keys)
        key: _nonNegativeInteger(lifecycle[key], r'$.lifecycle.' + key),
    };
    if ((normalizedLifecycle['rssCycle5Bytes']! as int) == 0) {
      throw const FormatException(
        r'$.lifecycle.rssCycle5Bytes must be positive.',
      );
    }

    final samples = _map(measurements['samples'], r'$.samples');
    _expectKeys(samples, const <String>{
      'skipUs',
      'posterUs',
      'videoFirstFrameUs',
      'mainIsolateStallUs',
      'uiFrameTotalUs',
    }, r'$.samples');
    final skipUs = _samples(samples['skipUs'], r'$.samples.skipUs', length: 50);
    final posterUs = _samples(
      samples['posterUs'],
      r'$.samples.posterUs',
      length: 50,
    );
    final videoFirstFrameUs = _samples(
      samples['videoFirstFrameUs'],
      r'$.samples.videoFirstFrameUs',
      length: 50,
    );
    final mainIsolateStallUs = _samples(
      samples['mainIsolateStallUs'],
      r'$.samples.mainIsolateStallUs',
    );
    final uiFrameTotalUs = _samples(
      samples['uiFrameTotalUs'],
      r'$.samples.uiFrameTotalUs',
    );
    final cycleEvidence = _validateCycleEvidence(measurements['cycleEvidence']);
    if (normalizedLifecycle['rssCycle5Bytes'] !=
            cycleEvidence[4]['rssAfterCooldownBytes'] ||
        normalizedLifecycle['rssCycle50Bytes'] !=
            cycleEvidence[49]['rssAfterCooldownBytes']) {
      throw const FormatException(
        r'$.lifecycle RSS values must match cooldown cycle evidence.',
      );
    }
    final normalizedProvenance = _validateProvenance(provenance);
    final platformProjection = _validatePlatformSupport(platformSupport);

    const budgets = <String, Object?>{
      'lifecycleCycles': 50,
      'maximumActiveDecoders': 1,
      'finalActiveDecoders': 0,
      'finalMediaHandles': 0,
      'rssGrowthBasisPointsMax': 1000,
      'skipP95UsExclusive': 100000,
      'posterP95UsExclusive': 500000,
      'videoFirstFrameP95UsExclusive': 1000000,
      'mainIsolateStallMaxUsInclusive': 100000,
      'uiFrameBudgetUsExclusive': 16700,
      'uiFramesWithinBudgetBasisPointsMin': 9900,
    };
    final rssCycle5 = normalizedLifecycle['rssCycle5Bytes']! as int;
    final rssCycle50 = normalizedLifecycle['rssCycle50Bytes']! as int;
    final rssGrowth = math.max(0, rssCycle50 - rssCycle5);
    final rssGrowthBasisPoints =
        (rssGrowth * 10000 + rssCycle5 - 1) ~/ rssCycle5;
    final skip = _distribution(skipUs);
    final poster = _distribution(posterUs);
    final videoFirstFrame = _distribution(videoFirstFrameUs);
    final mainIsolateStall = _distribution(mainIsolateStallUs);
    final uiWithinBudget = uiFrameTotalUs
        .where((sample) => sample < 16700)
        .length;
    final uiWithinBudgetBasisPoints =
        uiWithinBudget * 10000 ~/ uiFrameTotalUs.length;
    final metrics = <String, Object?>{
      'rss': <String, Object?>{
        'cycle5Bytes': rssCycle5,
        'cycle50Bytes': rssCycle50,
        'growthBytes': rssGrowth,
        'growthBasisPoints': rssGrowthBasisPoints,
      },
      'skip': skip,
      'poster': poster,
      'videoFirstFrameProxy': <String, Object?>{
        ...videoFirstFrame,
        'definition': 'position-positive-after-flutter-frame',
      },
      'mainIsolateStall': mainIsolateStall,
      'uiFrames': <String, Object?>{
        'samplesUs': uiFrameTotalUs,
        'total': uiFrameTotalUs.length,
        'withinBudget': uiWithinBudget,
        'withinBudgetBasisPoints': uiWithinBudgetBasisPoints,
        'maxUs': uiFrameTotalUs.reduce(math.max),
      },
    };
    final violations = <String>[];
    if (normalizedLifecycle['cycles'] != 50) {
      violations.add('lifecycle.cycles');
    }
    if ((normalizedLifecycle['maximumActiveDecoders']! as int) > 1) {
      violations.add('lifecycle.maximumActiveDecoders');
    }
    if (normalizedLifecycle['finalActiveDecoders'] != 0) {
      violations.add('lifecycle.finalActiveDecoders');
    }
    if (normalizedLifecycle['finalMediaHandles'] != 0) {
      violations.add('lifecycle.finalMediaHandles');
    }
    if (normalizedLifecycle['terminalReceipts'] != 50) {
      violations.add('lifecycle.terminalReceipts');
    }
    if (normalizedLifecycle['skippedTerminals'] != 50) {
      violations.add('lifecycle.skippedTerminals');
    }
    if (cycleEvidence.any(
      (cycle) => (cycle['activeDecoderAfterExit']! as int) != 0,
    )) {
      violations.add('cycleEvidence.activeDecoderAfterExit');
    }
    if (rssGrowthBasisPoints > 1000) violations.add('rss.growth');
    if ((skip['p95Us']! as int) >= 100000) violations.add('skip.p95');
    if ((poster['p95Us']! as int) >= 500000) violations.add('poster.p95');
    if ((videoFirstFrame['p95Us']! as int) >= 1000000) {
      violations.add('videoFirstFrame.p95');
    }
    if ((mainIsolateStall['maxUs']! as int) > 100000) {
      violations.add('mainIsolateStall.max');
    }
    if (uiWithinBudget * 100 < uiFrameTotalUs.length * 99) {
      violations.add('uiFrames.withinBudget');
    }

    return PresentationRuntimePerformanceReceipt._(<String, Object?>{
      'schemaVersion': 1,
      'benchmark': 'presentation_runtime_cin_038',
      'target':
          'integration_test/presentation_runtime_performance_journey_test.dart',
      'executionMode': 'flutter-profile',
      'platform': 'macos',
      'fixture': Map<String, Object?>.from(fixture),
      'supportedPlatforms': platformProjection.$1,
      'deferredPlatforms': platformProjection.$2,
      'budgets': budgets,
      'lifecycle': normalizedLifecycle,
      'cycleEvidence': cycleEvidence,
      'metrics': metrics,
      'provenance': normalizedProvenance,
      'verdict': violations.isEmpty ? 'passed' : 'failed',
      'violations': violations,
    });
  }

  factory PresentationRuntimePerformanceReceipt.fromJson(
    Map<String, Object?> json,
  ) {
    _expectKeys(json, const <String>{
      'schemaVersion',
      'benchmark',
      'target',
      'executionMode',
      'platform',
      'fixture',
      'supportedPlatforms',
      'deferredPlatforms',
      'budgets',
      'lifecycle',
      'cycleEvidence',
      'metrics',
      'provenance',
      'verdict',
      'violations',
    }, r'$');
    final metrics = _map(json['metrics'], r'$.metrics');
    final videoMetric = _map(
      metrics['videoFirstFrameProxy'],
      r'$.metrics.videoFirstFrameProxy',
    );
    final rebuilt = PresentationRuntimePerformanceReceipt.fromMeasurements(
      measurements: <String, Object?>{
        'schemaVersion': json['schemaVersion'],
        'benchmark': json['benchmark'],
        'target': json['target'],
        'executionMode': json['executionMode'],
        'platform': json['platform'],
        'fixture': json['fixture'],
        'lifecycle': json['lifecycle'],
        'cycleEvidence': json['cycleEvidence'],
        'samples': <String, Object?>{
          'skipUs': _map(metrics['skip'], r'$.metrics.skip')['samplesUs'],
          'posterUs': _map(metrics['poster'], r'$.metrics.poster')['samplesUs'],
          'videoFirstFrameUs': videoMetric['samplesUs'],
          'mainIsolateStallUs': _map(
            metrics['mainIsolateStall'],
            r'$.metrics.mainIsolateStall',
          )['samplesUs'],
          'uiFrameTotalUs': _map(
            metrics['uiFrames'],
            r'$.metrics.uiFrames',
          )['samplesUs'],
        },
      },
      platformSupport: const <String, Object?>{
        'schemaVersion': 1,
        'platforms': <String, Object?>{
          'macos': <String, Object?>{'status': 'supported'},
          'ios': <String, Object?>{'status': 'xcode-cloud-target'},
          'android': <String, Object?>{'status': 'build-target'},
        },
      },
      provenance: _map(json['provenance'], r'$.provenance'),
    );
    if (!_deepEquals(rebuilt.toJson(), json)) {
      throw const FormatException(
        'CIN-038 receipt contains non-canonical or inconsistent evidence.',
      );
    }
    return rebuilt;
  }

  final Map<String, Object?> _json;

  bool get passed => _json['verdict'] == 'passed';

  List<String> get violations =>
      List<String>.unmodifiable((_json['violations']! as List<Object?>).cast());

  Map<String, Object?> toJson() => _copyMap(_json);

  String encodeCanonical() => jsonEncode(_json);
}

(List<String>, List<String>) _validatePlatformSupport(
  Map<String, Object?> json,
) {
  if (json['schemaVersion'] != 1) {
    throw const FormatException(r'$.platformSupport.schemaVersion must be 1.');
  }
  final platforms = _map(json['platforms'], r'$.platformSupport.platforms');
  final expected = <String, String>{
    'macos': 'supported',
    'ios': 'xcode-cloud-target',
    'android': 'build-target',
  };
  for (final entry in expected.entries) {
    final platform = _map(
      platforms[entry.key],
      r'$.platformSupport.platforms.' + entry.key,
    );
    if (platform['status'] != entry.value) {
      throw FormatException(
        r'$.platformSupport.platforms.' +
            '${entry.key}.status must be ${entry.value}.',
      );
    }
  }
  return (const <String>['macos'], const <String>['ios', 'android']);
}

Map<String, Object?> _validateProvenance(Map<String, Object?> provenance) {
  _expectKeys(provenance, const <String>{
    'commit',
    'treeState',
    'treeFingerprint',
    'os',
    'osVersion',
    'architecture',
    'dartVersion',
    'flutterVersion',
    'flutterRevision',
    'command',
  }, r'$.provenance');
  _digest(provenance['commit'], r'$.provenance.commit', length: 40);
  _expectValue(provenance, 'treeState', 'clean', r'$.provenance.treeState');
  _digest(provenance['treeFingerprint'], r'$.provenance.treeFingerprint');
  _expectValue(provenance, 'os', 'macos', r'$.provenance.os');
  for (final key in <String>['osVersion', 'dartVersion', 'flutterVersion']) {
    _nonEmptyString(provenance[key], r'$.provenance.' + key);
  }
  final architecture = _nonEmptyString(
    provenance['architecture'],
    r'$.provenance.architecture',
  );
  if (architecture != 'arm64' && architecture != 'x64') {
    throw const FormatException(
      r'$.provenance.architecture must be arm64 or x64.',
    );
  }
  _digest(
    provenance['flutterRevision'],
    r'$.provenance.flutterRevision',
    length: 40,
  );
  final command = provenance['command'];
  if (command is! List<Object?> || command.length < 3) {
    throw const FormatException(
      r'$.provenance.command must contain the executed command tokens.',
    );
  }
  for (final entry in command.indexed) {
    _nonEmptyString(entry.$2, r'$.provenance.command[]');
  }
  if (command[0] != 'dart' ||
      command[1] != 'run' ||
      command[2] != 'bin/certify_presentation_runtime_performance.dart') {
    throw const FormatException(
      r'$.provenance.command must identify the CIN-038 certifier.',
    );
  }
  return Map<String, Object?>.from(provenance);
}

List<Map<String, Object?>> _validateCycleEvidence(Object? value) {
  if (value is! List<Object?> || value.length != 50) {
    throw const FormatException(
      r'$.cycleEvidence must contain exactly 50 cycles.',
    );
  }
  final normalized = <Map<String, Object?>>[];
  for (var index = 0; index < value.length; index += 1) {
    final path = r'$.cycleEvidence[' + '$index]';
    final cycle = _map(value[index], path);
    _expectKeys(cycle, const <String>{
      'cycle',
      'orientation',
      'replay',
      'lifecycle',
      'activeDecoderAfterExit',
      'rssAfterCooldownBytes',
    }, path);
    final expectedCycle = index + 1;
    final expectedOrientation = expectedCycle.isOdd ? 'landscape' : 'portrait';
    final expectedReplay = (expectedCycle + 1) ~/ 2;
    if (cycle['cycle'] != expectedCycle ||
        cycle['orientation'] != expectedOrientation ||
        cycle['replay'] != expectedReplay ||
        cycle['lifecycle'] != 'pause-resume') {
      throw FormatException('$path is not the canonical replay sequence.');
    }
    final activeDecoderAfterExit = _nonNegativeInteger(
      cycle['activeDecoderAfterExit'],
      '$path.activeDecoderAfterExit',
    );
    final rssAfterCooldownBytes = _nonNegativeInteger(
      cycle['rssAfterCooldownBytes'],
      '$path.rssAfterCooldownBytes',
    );
    if (rssAfterCooldownBytes == 0) {
      throw FormatException('$path.rssAfterCooldownBytes must be positive.');
    }
    normalized.add(<String, Object?>{
      'cycle': expectedCycle,
      'orientation': expectedOrientation,
      'replay': expectedReplay,
      'lifecycle': 'pause-resume',
      'activeDecoderAfterExit': activeDecoderAfterExit,
      'rssAfterCooldownBytes': rssAfterCooldownBytes,
    });
  }
  return List<Map<String, Object?>>.unmodifiable(normalized);
}

Map<String, Object?> _distribution(List<int> samples) {
  final sorted = samples.toList()..sort();
  int percentile(double value) =>
      sorted[(value * sorted.length).ceil().clamp(1, sorted.length) - 1];
  return <String, Object?>{
    'samplesUs': samples,
    'p50Us': percentile(0.50),
    'p95Us': percentile(0.95),
    'p99Us': percentile(0.99),
    'maxUs': sorted.last,
  };
}

List<int> _samples(Object? value, String path, {int? length}) {
  if (value is! List<Object?> || value.isEmpty) {
    throw FormatException('$path must be a non-empty array.');
  }
  if (length != null && value.length != length) {
    throw FormatException('$path must contain exactly $length samples.');
  }
  return List<int>.unmodifiable(
    value.indexed.map(
      (entry) => _nonNegativeInteger(entry.$2, '$path[${entry.$1}]'),
    ),
  );
}

Map<String, Object?> _map(Object? value, String path) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$path must be an object.');
  }
  return value;
}

void _expectKeys(Map<String, Object?> json, Set<String> expected, String path) {
  if (json.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw FormatException('$path keys are invalid.');
  }
}

void _expectValue(
  Map<String, Object?> json,
  String key,
  Object expected,
  String path,
) {
  if (json[key] != expected) throw FormatException('$path is invalid.');
}

int _nonNegativeInteger(Object? value, String path) {
  if (value is! int || value < 0) {
    throw FormatException('$path must be a non-negative integer.');
  }
  return value;
}

String _nonEmptyString(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return value;
}

void _digest(Object? value, String path, {int length = 64}) {
  if (value is! String || !RegExp('^[0-9a-f]{$length}\$').hasMatch(value)) {
    throw FormatException('$path must be a lowercase hexadecimal digest.');
  }
}

Map<String, Object?> _copyMap(Map<String, Object?> value) =>
    value.map((key, entry) => MapEntry(key, _copy(entry)));

Object? _copy(Object? value) {
  if (value is Map<String, Object?>) return _copyMap(value);
  if (value is List<Object?>) return value.map(_copy).toList(growable: false);
  return value;
}

bool _deepEquals(Object? left, Object? right) {
  if (left is Map<String, Object?> && right is Map<String, Object?>) {
    if (left.length != right.length ||
        left.keys.any((key) => !right.containsKey(key))) {
      return false;
    }
    return left.keys.every((key) => _deepEquals(left[key], right[key]));
  }
  if (left is List<Object?> && right is List<Object?>) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_deepEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
}
