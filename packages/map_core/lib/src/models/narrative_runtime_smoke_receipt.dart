import 'package:meta/meta.dart' show immutable;

enum NarrativeRuntimeSmokeResult { pass, fail }

@immutable
final class NarrativeRuntimeSmokeProfile {
  NarrativeRuntimeSmokeProfile({
    required this.id,
    required this.version,
    required List<String> requiredSuiteIds,
  }) : requiredSuiteIds = _profileSuiteIds(requiredSuiteIds) {
    if (id.isEmpty || id != id.trim() || version < 1) {
      throw ArgumentError('Runtime smoke profiles require an ID and positive version.');
    }
  }

  factory NarrativeRuntimeSmokeProfile.fromJson(Object? source) {
    if (source is! Map ||
        source.length != 3 ||
        source.keys.any((key) => !const {'id', 'version', 'requiredSuiteIds'}.contains(key)) ||
        source['id'] is! String ||
        source['version'] is! int ||
        source['requiredSuiteIds'] is! List ||
        (source['requiredSuiteIds'] as List).any((value) => value is! String)) {
      throw const FormatException('Invalid runtime smoke profile.');
    }
    return NarrativeRuntimeSmokeProfile(
      id: source['id'] as String,
      version: source['version'] as int,
      requiredSuiteIds: (source['requiredSuiteIds'] as List).cast<String>(),
    );
  }

  final String id;
  final int version;
  final List<String> requiredSuiteIds;

  Map<String, Object?> toJson() => {
        'id': id,
        'version': version,
        'requiredSuiteIds': requiredSuiteIds,
      };

  bool acceptsSuites(Iterable<String> suiteIds) {
    final actual = suiteIds.toSet();
    return requiredSuiteIds.every(actual.contains);
  }

  @override
  bool operator ==(Object other) =>
      other is NarrativeRuntimeSmokeProfile &&
      id == other.id &&
      version == other.version &&
      requiredSuiteIds.length == other.requiredSuiteIds.length &&
      requiredSuiteIds.indexed.every((entry) => other.requiredSuiteIds[entry.$1] == entry.$2);

  @override
  int get hashCode => Object.hash(id, version, Object.hashAll(requiredSuiteIds));
}

List<String> _profileSuiteIds(List<String> values) {
  if (values.isEmpty ||
      values.any((value) => value.isEmpty || value != value.trim()) ||
      values.toSet().length != values.length) {
    throw ArgumentError('Runtime smoke profiles require distinct non-empty suite IDs.');
  }
  return _stableStrings(values);
}

@immutable
final class NarrativeRuntimeSmokeReceipt {
  NarrativeRuntimeSmokeReceipt({
    this.schemaVersion = 1,
    required this.projectFingerprint,
    required this.validatorVersion,
    required this.profileId,
    required this.profileVersion,
    required List<String> suiteIds,
    required this.fixtureId,
    required this.result,
    required DateTime completedAt,
    List<String> limitations = const <String>[],
  })  : suiteIds = _stableStrings(suiteIds),
        completedAt = completedAt.toUtc(),
        limitations = _stableStrings(limitations) {
    if (schemaVersion != 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion');
    }
    if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(projectFingerprint)) {
      throw ArgumentError.value(projectFingerprint, 'projectFingerprint');
    }
  }

  factory NarrativeRuntimeSmokeReceipt.fromJson(Map<String, dynamic> json) {
    return NarrativeRuntimeSmokeReceipt(
      schemaVersion: _requiredInt(json, 'schemaVersion'),
      projectFingerprint: _requiredString(json, 'projectFingerprint'),
      validatorVersion: _requiredString(json, 'validatorVersion'),
      profileId: _requiredString(json, 'profileId'),
      profileVersion: _requiredInt(json, 'profileVersion'),
      suiteIds: _stringList(json, 'suiteIds'),
      fixtureId: _requiredString(json, 'fixtureId'),
      result: _result(json['result']),
      completedAt: DateTime.parse(_requiredString(json, 'completedAt')),
      limitations: _stringList(json, 'limitations'),
    );
  }

  final int schemaVersion;
  final String projectFingerprint;
  final String validatorVersion;
  final String profileId;
  final int profileVersion;
  final List<String> suiteIds;
  final String fixtureId;
  final NarrativeRuntimeSmokeResult result;
  final DateTime completedAt;
  final List<String> limitations;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'projectFingerprint': projectFingerprint,
        'validatorVersion': validatorVersion,
        'profileId': profileId,
        'profileVersion': profileVersion,
        'suiteIds': suiteIds,
        'fixtureId': fixtureId,
        'result': result.name,
        'completedAt': completedAt.toIso8601String(),
        'limitations': limitations,
      };
}

NarrativeRuntimeSmokeResult _result(Object? value) {
  return switch (value) {
    'pass' => NarrativeRuntimeSmokeResult.pass,
    'fail' => NarrativeRuntimeSmokeResult.fail,
    _ => throw FormatException('Unknown runtime smoke result "$value".'),
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$key must be a string list.');
  }
  return List<String>.from(value);
}

List<String> _stableStrings(Iterable<String> values) {
  final result = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return List.unmodifiable(result);
}
