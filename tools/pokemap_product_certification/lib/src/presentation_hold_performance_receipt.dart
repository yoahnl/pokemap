import 'dart:convert';

/// The certified shape of a BETA-CIN-084 interactive-hold measurement.
///
/// BETA-CIN-038 already certifies Presentation playback: skip latency, poster
/// and first-frame timings, decoder and media-handle counts over fifty cycles.
/// This is its sibling for the part CIN-038 never touched — the HOLD. A hold is
/// where the timeline suspends and the player reads, chooses or types, so what
/// matters is how fast the frame comes back after an input and whether anything
/// survives the exit. Timers and subscriptions in particular: CIN-038 counts
/// decoders and media handles, and a leaked periodic timer is invisible to
/// both while quietly turning the phone into a radiator.
///
/// The receipt is a validator, not a measurer. It takes what a local profile
/// run reported and refuses everything a false green would need: a substitute
/// decoder, a missing orientation, fewer than fifty cycles, a threshold looked
/// up for a platform nobody declared, or a single residual handle after any of
/// the five exits.
///
/// Helpers are duplicated from the CIN-038 receipt on purpose. Extracting them
/// would edit a frozen certified contract for a refactor this ticket did not
/// ask for, and the package already duplicates them elsewhere.
final class PresentationHoldPerformanceReceipt {
  PresentationHoldPerformanceReceipt._(this._json);

  /// The exits a hold can leave through. Every one of them must release
  /// everything: the ticket says "après chaque sortie", not "à la fin".
  static const Set<String> exitReasons = <String>{
    'stop',
    'skip',
    'background',
    'error',
    'routeClose',
  };

  /// What must be at zero once the hold is gone. `activeTimers` and
  /// `activeSubscriptions` are the two CIN-038 cannot see.
  static const Set<String> residualResources = <String>{
    'activeDecoders',
    'activeAudioHandles',
    'activeTimers',
    'activeSubscriptions',
  };

  static const Set<String> orientations = <String>{'landscape', 'portrait'};

  static const int requiredHoldCycles = 50;

  /// Per-platform budgets, never averaged across platforms. A receipt for a
  /// platform absent from this map is refused rather than measured against
  /// some blended figure — that is the "sans moyenne inter-plateformes" the
  /// ticket asks for, expressed so it cannot be bypassed.
  static const Map<String, Map<String, int>> platformBudgets =
      <String, Map<String, int>>{
    'macos': <String, int>{
      'inputToDisplayP95Us': 120000,
      'inputToResumeP95Us': 180000,
      'maximumSlowFrames': 5,
      'maximumRssGrowthBytes': 48 * 1024 * 1024,
    },
  };

  /// Substitute media stacks. A hold that never decoded anything is trivially
  /// fast, which is exactly the false certification this ticket names as its
  /// main risk.
  static const Set<String> forbiddenDecoderMarkers = <String>{
    'fake',
    'stub',
    'mock',
    'noop',
    'null',
    'dummy',
  };

  factory PresentationHoldPerformanceReceipt.fromMeasurements({
    required Map<String, Object?> measurements,
    required Map<String, Object?> provenance,
  }) {
    _expectKeys(measurements, const <String>{
      'schemaVersion',
      'benchmark',
      'target',
      'executionMode',
      'platform',
      'mediaPipeline',
      'orientations',
      'teardown',
      'memory',
    }, r'$');
    _expectValue(measurements, 'schemaVersion', 1, r'$.schemaVersion');
    _expectValue(
      measurements,
      'benchmark',
      'presentation_hold_cin_084',
      r'$.benchmark',
    );
    _expectValue(
      measurements,
      'target',
      'integration_test/presentation_hold_performance_journey_test.dart',
      r'$.target',
    );
    _expectValue(
      measurements,
      'executionMode',
      'flutter-profile',
      r'$.executionMode',
    );

    final platform = _nonEmptyString(measurements['platform'], r'$.platform');
    final budgets = platformBudgets[platform];
    if (budgets == null) {
      throw FormatException(
        r'$.platform declares "' +
            platform +
            '" which has no versioned budget: a measurement cannot be judged '
                'against another platform average.',
      );
    }

    final pipeline = _validateMediaPipeline(measurements['mediaPipeline']);
    final orientationSamples = _validateOrientations(
      measurements['orientations'],
    );
    final teardown = _validateTeardown(measurements['teardown']);
    final memory = _validateMemory(measurements['memory']);
    final normalizedProvenance = _validateProvenance(provenance);

    final violations = <String>[];
    final metrics = <String, Object?>{};
    for (final orientation in orientations) {
      final samples = orientationSamples[orientation]!;
      final display = _distribution(
        samples['inputToDisplayUs']! as List<int>,
      );
      final resume = _distribution(samples['inputToResumeUs']! as List<int>);
      metrics['$orientation.inputToDisplayUs'] = display;
      metrics['$orientation.inputToResumeUs'] = resume;
      metrics['$orientation.slowFrames'] = samples['slowFrames'];

      if ((display['p95']! as int) > budgets['inputToDisplayP95Us']!) {
        violations.add('$orientation.inputToDisplay.p95');
      }
      if ((resume['p95']! as int) > budgets['inputToResumeP95Us']!) {
        violations.add('$orientation.inputToResume.p95');
      }
      if ((samples['slowFrames']! as int) > budgets['maximumSlowFrames']!) {
        violations.add('$orientation.slowFrames');
      }
    }

    // Every exit, every resource. A named violation per pair, because "some
    // teardown leaked" is not something anyone can act on.
    for (final reason in exitReasons) {
      final residual = teardown[reason]!;
      for (final resource in residualResources) {
        if ((residual[resource]! as int) != 0) {
          violations.add('teardown.$reason.$resource');
        }
      }
    }

    final growth = (memory['rssAfterCycle50Bytes']! as int) -
        (memory['rssAfterCycle5Bytes']! as int);
    metrics['rssGrowthBytes'] = growth;
    if (growth > budgets['maximumRssGrowthBytes']!) {
      violations.add('memory.rssGrowth');
    }

    return PresentationHoldPerformanceReceipt._(<String, Object?>{
      'schemaVersion': 1,
      'benchmark': 'presentation_hold_cin_084',
      'target': measurements['target'],
      'executionMode': 'flutter-profile',
      'platform': platform,
      'budgets': _copyMap(budgets),
      'mediaPipeline': pipeline,
      'orientations': <String, Object?>{
        for (final orientation in orientations)
          orientation: _copyMap(orientationSamples[orientation]!),
      },
      'teardown': <String, Object?>{
        for (final reason in exitReasons) reason: _copyMap(teardown[reason]!),
      },
      'memory': _copyMap(memory),
      'metrics': metrics,
      'provenance': normalizedProvenance,
      'verdict': violations.isEmpty ? 'passed' : 'failed',
      'violations': violations..sort(),
    });
  }

  factory PresentationHoldPerformanceReceipt.fromJson(
    Map<String, Object?> json,
  ) {
    _expectKeys(json, const <String>{
      'schemaVersion',
      'benchmark',
      'target',
      'executionMode',
      'platform',
      'budgets',
      'mediaPipeline',
      'orientations',
      'teardown',
      'memory',
      'metrics',
      'provenance',
      'verdict',
      'violations',
    }, r'$');
    return PresentationHoldPerformanceReceipt._(_copyMap(json));
  }

  final Map<String, Object?> _json;

  String get verdict => _json['verdict']! as String;

  bool get passed => verdict == 'passed';

  String get platform => _json['platform']! as String;

  List<String> get violations => <String>[
        for (final violation in _json['violations']! as List<Object?>)
          violation! as String,
      ];

  Map<String, Object?> toJson() => _copyMap(_json);

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}

Map<String, Object?> _validateMediaPipeline(Object? value) {
  final pipeline = _map(value, r'$.mediaPipeline');
  _expectKeys(pipeline, const <String>{
    'decoderImplementation',
    'audioSinkImplementation',
    'decodedVideoFrames',
    'renderedCaptionCues',
  }, r'$.mediaPipeline');

  for (final key in const <String>[
    'decoderImplementation',
    'audioSinkImplementation',
  ]) {
    final name = _nonEmptyString(pipeline[key], r'$.mediaPipeline.' + key);
    final lowered = name.toLowerCase();
    for (final marker
        in PresentationHoldPerformanceReceipt.forbiddenDecoderMarkers) {
      if (lowered.contains(marker)) {
        throw FormatException(
          r'$.mediaPipeline.' +
              key +
              ' is a substitute ("' +
              name +
              '"): a hold that decodes nothing is trivially fast, so this '
                  'measurement would certify nothing.',
        );
      }
    }
  }

  final frames = _nonNegativeInteger(
    pipeline['decodedVideoFrames'],
    r'$.mediaPipeline.decodedVideoFrames',
  );
  if (frames == 0) {
    throw const FormatException(
      r'$.mediaPipeline.decodedVideoFrames must be positive: nothing was '
      'actually decoded.',
    );
  }
  final cues = _nonNegativeInteger(
    pipeline['renderedCaptionCues'],
    r'$.mediaPipeline.renderedCaptionCues',
  );
  if (cues == 0) {
    throw const FormatException(
      r'$.mediaPipeline.renderedCaptionCues must be positive: the ticket '
      'requires captions in the exercised cycles.',
    );
  }
  return _copyMap(pipeline);
}

Map<String, Map<String, Object?>> _validateOrientations(Object? value) {
  final root = _map(value, r'$.orientations');
  _expectKeys(
    root,
    PresentationHoldPerformanceReceipt.orientations,
    r'$.orientations',
  );
  final result = <String, Map<String, Object?>>{};
  for (final orientation in PresentationHoldPerformanceReceipt.orientations) {
    final path = r'$.orientations.' + orientation;
    final entry = _map(root[orientation], path);
    _expectKeys(entry, const <String>{
      'holdCycles',
      'inputToDisplayUs',
      'inputToResumeUs',
      'slowFrames',
      'answeredInputs',
    }, path);
    final cycles = _nonNegativeInteger(entry['holdCycles'], '$path.holdCycles');
    if (cycles != PresentationHoldPerformanceReceipt.requiredHoldCycles) {
      throw FormatException(
        '$path.holdCycles must be exactly '
        '${PresentationHoldPerformanceReceipt.requiredHoldCycles}, not '
        '$cycles.',
      );
    }
    final answered = _nonNegativeInteger(
      entry['answeredInputs'],
      '$path.answeredInputs',
    );
    if (answered != cycles) {
      throw FormatException(
        '$path.answeredInputs must match holdCycles: a cycle whose input was '
        'never answered never held.',
      );
    }
    result[orientation] = <String, Object?>{
      'holdCycles': cycles,
      'answeredInputs': answered,
      'inputToDisplayUs': _samples(
        entry['inputToDisplayUs'],
        '$path.inputToDisplayUs',
        length: cycles,
      ),
      'inputToResumeUs': _samples(
        entry['inputToResumeUs'],
        '$path.inputToResumeUs',
        length: cycles,
      ),
      'slowFrames': _nonNegativeInteger(
        entry['slowFrames'],
        '$path.slowFrames',
      ),
    };
  }
  return result;
}

Map<String, Map<String, Object?>> _validateTeardown(Object? value) {
  final root = _map(value, r'$.teardown');
  _expectKeys(
    root,
    PresentationHoldPerformanceReceipt.exitReasons,
    r'$.teardown',
  );
  final result = <String, Map<String, Object?>>{};
  for (final reason in PresentationHoldPerformanceReceipt.exitReasons) {
    final path = r'$.teardown.' + reason;
    final entry = _map(root[reason], path);
    _expectKeys(
      entry,
      PresentationHoldPerformanceReceipt.residualResources,
      path,
    );
    result[reason] = <String, Object?>{
      for (final resource
          in PresentationHoldPerformanceReceipt.residualResources)
        resource: _nonNegativeInteger(entry[resource], '$path.$resource'),
    };
  }
  return result;
}

Map<String, Object?> _validateMemory(Object? value) {
  final memory = _map(value, r'$.memory');
  _expectKeys(memory, const <String>{
    'rssAfterCycle5Bytes',
    'rssAfterCycle50Bytes',
  }, r'$.memory');
  final normalized = <String, Object?>{
    for (final key in memory.keys)
      key: _nonNegativeInteger(memory[key], r'$.memory.' + key),
  };
  if ((normalized['rssAfterCycle5Bytes']! as int) == 0) {
    throw const FormatException(
      r'$.memory.rssAfterCycle5Bytes must be positive: a run that measured no '
      'resident memory measured nothing.',
    );
  }
  return normalized;
}

Map<String, Object?> _validateProvenance(Map<String, Object?> provenance) {
  _expectKeys(provenance, const <String>{
    'commit',
    'treeState',
    'os',
    'device',
    'flutterVersion',
    'recordedAtUtc',
  }, r'$.provenance');
  _digest(provenance['commit'], r'$.provenance.commit', length: 40);
  // A measurement taken on a dirty tree cannot be reproduced, so it is not
  // evidence of anything.
  _expectValue(provenance, 'treeState', 'clean', r'$.provenance.treeState');
  for (final key in const <String>[
    'os',
    'device',
    'flutterVersion',
    'recordedAtUtc',
  ]) {
    _nonEmptyString(provenance[key], r'$.provenance.' + key);
  }
  return _copyMap(provenance);
}

Map<String, Object?> _distribution(List<int> samples) {
  final sorted = samples.toList()..sort();
  int at(double fraction) {
    final index = ((sorted.length - 1) * fraction).round();
    return sorted[index];
  }

  return <String, Object?>{
    'count': sorted.length,
    'p50': at(0.50),
    'p95': at(0.95),
    'p99': at(0.99),
    'max': sorted.last,
  };
}

List<int> _samples(Object? value, String path, {int? length}) {
  if (value is! List) {
    throw FormatException('$path must be a list of integers.');
  }
  if (length != null && value.length != length) {
    throw FormatException('$path must hold exactly $length samples.');
  }
  return <int>[
    for (var index = 0; index < value.length; index += 1)
      _nonNegativeInteger(value[index], '$path[$index]'),
  ];
}

Map<String, Object?> _map(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object.');
  }
  return Map<String, Object?>.from(value);
}

void _expectKeys(Map<String, Object?> json, Set<String> expected, String path) {
  final actual = json.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    final missing = expected.difference(actual).toList()..sort();
    final unknown = actual.difference(expected).toList()..sort();
    throw FormatException(
      '$path keys are invalid. missing=$missing unknown=$unknown',
    );
  }
}

void _expectValue(
  Map<String, Object?> json,
  String key,
  Object expected,
  String path,
) {
  if (json[key] != expected) {
    throw FormatException('$path must be $expected, not ${json[key]}.');
  }
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
  final digest = _nonEmptyString(value, path);
  if (digest.length != length ||
      !RegExp('^[0-9a-f]{$length}\$').hasMatch(digest)) {
    throw FormatException('$path must be $length lowercase hex characters.');
  }
}

Map<String, Object?> _copyMap(Map<String, Object?> value) =>
    <String, Object?>{for (final entry in value.entries) entry.key: entry.value};
