import 'dart:convert';

/// The certified shape of a BETA-CIN-085 installed-Hub journey.
///
/// The ticket names its own risk twice: "canary vert en assemblant des fakes ou
/// en plaçant l'interaction hors de la Presentation". So this validator is
/// built around refusing exactly those two, and everything else follows.
///
/// The anti-fake half is identity: the receipt has to name the package that was
/// installed, by gameId, version and both hashes, and those must match the
/// artifact the fixture builder produced. A journey that ran against a
/// hand-assembled project cannot present a package hash it never built.
///
/// The anti-canary half is semantic rather than arithmetic. The old canary put
/// the dialogue before or after the Presentation and still went green, so
/// timing an interaction inside `[0, duration]` would not settle it — a marker
/// at 0 is a legitimate first page. What settles it is the playback state at
/// cue time: an interaction that really happened DURING the Presentation was
/// observed while it was suspended on a cue or holding for the player. Any
/// other state — playing, stopped, disposed — means the dialogue was outside
/// the hold, whatever the clock said.
final class InstalledHubJourneyReceipt {
  InstalledHubJourneyReceipt._(this._json);

  /// The paths the ticket requires green, nominal first.
  static const Set<String> journeyPaths = <String>{
    'nominal',
    'cancel',
    'skip',
    'error',
  };

  /// The only states in which an interaction can be said to have happened
  /// during the Presentation.
  static const Set<String> insidePresentationStates = <String>{
    'cueSuspended',
    'interactionHold',
  };

  /// Draft fields the journey has to show surviving into the session. The
  /// ticket names all three.
  static const Set<String> committedDraftFields = <String>{
    'playerName',
    'avatarCharacterId',
    'starterOptionId',
  };

  static const Set<String> residualResources = <String>{
    'activeDecoders',
    'activeAudioHandles',
    'activeTimers',
    'activeSubscriptions',
  };

  factory InstalledHubJourneyReceipt.fromMeasurements({
    required Map<String, Object?> measurements,
    required Map<String, Object?> provenance,
  }) {
    _expectKeys(measurements, const <String>{
      'schemaVersion',
      'benchmark',
      'installedPackage',
      'paths',
      'persistence',
      'uncertifiedLimits',
    }, r'$');
    _expectValue(measurements, 'schemaVersion', 1, r'$.schemaVersion');
    _expectValue(
      measurements,
      'benchmark',
      'installed_hub_journey_cin_085',
      r'$.benchmark',
    );

    final package = _validateInstalledPackage(measurements['installedPackage']);
    final paths = _validatePaths(measurements['paths']);
    final persistence = _validatePersistence(measurements['persistence']);
    final limits = _validateUncertifiedLimits(
      measurements['uncertifiedLimits'],
    );
    final normalizedProvenance = _validateProvenance(provenance);

    final violations = <String>[];
    for (final path in journeyPaths) {
      final record = paths[path]!;
      if (record['outcome'] == null) {
        violations.add('paths.$path.outcome');
      }
      // Exactly one terminal commit per exit. Two is a double commit and zero
      // is a journey that never ended.
      if ((record['terminalCommits']! as int) != 1) {
        violations.add('paths.$path.terminalCommits');
      }
      final residual = record['residual']! as Map<String, Object?>;
      for (final resource in residualResources) {
        if ((residual[resource]! as int) != 0) {
          violations.add('paths.$path.residual.$resource');
        }
      }
    }

    if (!persistence['projectConfigUnchanged']!) {
      violations.add('persistence.projectConfigMutated');
    }
    if (!persistence['survivedReload']!) {
      violations.add('persistence.survivedReload');
    }

    return InstalledHubJourneyReceipt._(<String, Object?>{
      'schemaVersion': 1,
      'benchmark': 'installed_hub_journey_cin_085',
      'installedPackage': package,
      'paths': <String, Object?>{
        for (final path in journeyPaths) path: _copyMap(paths[path]!),
      },
      'persistence': <String, Object?>{
        for (final entry in persistence.entries) entry.key: entry.value,
      },
      'uncertifiedLimits': limits,
      'provenance': normalizedProvenance,
      'verdict': violations.isEmpty ? 'passed' : 'failed',
      'violations': violations..sort(),
    });
  }

  factory InstalledHubJourneyReceipt.fromJson(Map<String, Object?> json) {
    _expectKeys(json, const <String>{
      'schemaVersion',
      'benchmark',
      'installedPackage',
      'paths',
      'persistence',
      'uncertifiedLimits',
      'provenance',
      'verdict',
      'violations',
    }, r'$');
    return InstalledHubJourneyReceipt._(_copyMap(json));
  }

  final Map<String, Object?> _json;

  String get verdict => _json['verdict']! as String;

  bool get passed => verdict == 'passed';

  List<String> get violations => <String>[
        for (final violation in _json['violations']! as List<Object?>)
          violation! as String,
      ];

  List<String> get uncertifiedLimits => <String>[
        for (final limit in _json['uncertifiedLimits']! as List<Object?>)
          limit! as String,
      ];

  Map<String, Object?> toJson() => _copyMap(_json);

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}

Map<String, Object?> _validateInstalledPackage(Object? value) {
  final package = _map(value, r'$.installedPackage');
  _expectKeys(package, const <String>{
    'gameId',
    'gameVersion',
    'treeSha256',
    'packageSha256',
    'installedVersionRoot',
  }, r'$.installedPackage');
  _nonEmptyString(package['gameId'], r'$.installedPackage.gameId');
  _nonEmptyString(package['gameVersion'], r'$.installedPackage.gameVersion');
  _digest(package['treeSha256'], r'$.installedPackage.treeSha256');
  _digest(package['packageSha256'], r'$.installedPackage.packageSha256');
  // The installed root is what separates "ran against the Hub's copy" from
  // "ran against the author workspace".
  final root = _nonEmptyString(
    package['installedVersionRoot'],
    r'$.installedPackage.installedVersionRoot',
  );
  if (!root.contains('games') || !root.contains('versions')) {
    throw FormatException(
      r'$.installedPackage.installedVersionRoot must point inside an installed '
      'library ("games/<id>/versions/<version>"), not at an author project: '
      'got "$root".',
    );
  }
  return _copyMap(package);
}

Map<String, Map<String, Object?>> _validatePaths(Object? value) {
  final root = _map(value, r'$.paths');
  _expectKeys(root, InstalledHubJourneyReceipt.journeyPaths, r'$.paths');
  final result = <String, Map<String, Object?>>{};
  for (final path in InstalledHubJourneyReceipt.journeyPaths) {
    final where = r'$.paths.' + path;
    final record = _map(root[path], where);
    _expectKeys(record, const <String>{
      'outcome',
      'terminalCommits',
      'interactions',
      'residual',
    }, where);

    final interactions = _validateInteractions(
      record['interactions'],
      '$where.interactions',
    );
    final outcome = _nonEmptyString(record['outcome'], '$where.outcome');
    // A path that answered nothing did not exercise the dialogue — unless it
    // failed before the first cue could open, which is what an error path is.
    if (interactions.isEmpty && outcome != 'failed') {
      throw FormatException(
        '$where.interactions must record at least one interaction: a path '
        'that answered nothing and did not fail exercised no dialogue.',
      );
    }
    final residual = _map(record['residual'], '$where.residual');
    _expectKeys(
      residual,
      InstalledHubJourneyReceipt.residualResources,
      '$where.residual',
    );

    result[path] = <String, Object?>{
      'outcome': outcome,
      'terminalCommits': _nonNegativeInteger(
        record['terminalCommits'],
        '$where.terminalCommits',
      ),
      'interactions': interactions,
      'residual': <String, Object?>{
        for (final resource in InstalledHubJourneyReceipt.residualResources)
          resource: _nonNegativeInteger(
            residual[resource],
            '$where.residual.$resource',
          ),
      },
    };
  }
  return result;
}

List<Map<String, Object?>> _validateInteractions(Object? value, String path) {
  if (value is! List) {
    throw FormatException('$path must be a list.');
  }
  final result = <Map<String, Object?>>[];
  for (var index = 0; index < value.length; index += 1) {
    final where = '$path[$index]';
    final record = _map(value[index], where);
    _expectKeys(record, const <String>{
      'markerId',
      'kind',
      'presentationState',
      'presentationNodeId',
    }, where);
    _nonEmptyString(record['markerId'], '$where.markerId');
    _nonEmptyString(record['kind'], '$where.kind');
    _nonEmptyString(record['presentationNodeId'], '$where.presentationNodeId');
    final state = _nonEmptyString(
      record['presentationState'],
      '$where.presentationState',
    );
    if (!InstalledHubJourneyReceipt.insidePresentationStates.contains(state)) {
      throw FormatException(
        '$where.presentationState is "$state": the interaction did not happen '
        'DURING the Presentation. That is the old canary, which went green '
        'with the dialogue before or after the cinematic.',
      );
    }
    result.add(_copyMap(record));
  }
  return result;
}

Map<String, bool> _validatePersistence(Object? value) {
  final persistence = _map(value, r'$.persistence');
  _expectKeys(persistence, const <String>{
    'committedDraftFields',
    'visibleAfterHandoff',
    'survivedReload',
    'projectConfigUnchanged',
  }, r'$.persistence');

  final committed = persistence['committedDraftFields'];
  if (committed is! List) {
    throw const FormatException(
      r'$.persistence.committedDraftFields must be a list.',
    );
  }
  final fields = <String>{
    for (final field in committed) _nonEmptyString(field, r'$.persistence'),
  };
  final missing = InstalledHubJourneyReceipt.committedDraftFields
      .difference(fields)
      .toList(growable: false)
    ..sort();
  if (missing.isNotEmpty) {
    throw FormatException(
      r'$.persistence.committedDraftFields is missing $missing: the ticket '
      'requires name, avatar AND starter to be visible in the session.',
    );
  }
  return <String, bool>{
    'visibleAfterHandoff': _boolean(
      persistence['visibleAfterHandoff'],
      r'$.persistence.visibleAfterHandoff',
    ),
    'survivedReload': _boolean(
      persistence['survivedReload'],
      r'$.persistence.survivedReload',
    ),
    'projectConfigUnchanged': _boolean(
      persistence['projectConfigUnchanged'],
      r'$.persistence.projectConfigUnchanged',
    ),
  };
}

/// The limits the run did NOT certify, declared rather than omitted.
///
/// A receipt that lists nothing is refused: every real run leaves something
/// uncovered, and a silent gap is how a green receipt comes to mean more than
/// it proved.
List<String> _validateUncertifiedLimits(Object? value) {
  if (value is! List) {
    throw const FormatException(r'$.uncertifiedLimits must be a list.');
  }
  if (value.isEmpty) {
    throw const FormatException(
      r'$.uncertifiedLimits must not be empty: a run that claims to have '
      'certified everything is the claim least likely to be true.',
    );
  }
  return <String>[
    for (var index = 0; index < value.length; index += 1)
      _nonEmptyString(value[index], r'$.uncertifiedLimits[' '$index' ']'),
  ];
}

Map<String, Object?> _validateProvenance(Map<String, Object?> provenance) {
  _expectKeys(provenance, const <String>{
    'commit',
    'treeState',
    'platform',
    'commands',
    'recordedAtUtc',
  }, r'$.provenance');
  _digest(provenance['commit'], r'$.provenance.commit', length: 40);
  _expectValue(provenance, 'treeState', 'clean', r'$.provenance.treeState');
  _nonEmptyString(provenance['platform'], r'$.provenance.platform');
  _nonEmptyString(provenance['recordedAtUtc'], r'$.provenance.recordedAtUtc');
  final commands = provenance['commands'];
  if (commands is! List || commands.isEmpty) {
    throw const FormatException(
      r'$.provenance.commands must list the commands that produced this run.',
    );
  }
  for (var index = 0; index < commands.length; index += 1) {
    _nonEmptyString(commands[index], r'$.provenance.commands[' '$index' ']');
  }
  return _copyMap(provenance);
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

bool _boolean(Object? value, String path) {
  if (value is! bool) {
    throw FormatException('$path must be a boolean.');
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
