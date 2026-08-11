import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'item_system_certification.dart';

enum ItemSystemExecutionVerdict { passed, partial, failed }

extension ItemSystemExecutionVerdictWireName on ItemSystemExecutionVerdict {
  String get wireName => switch (this) {
    ItemSystemExecutionVerdict.passed => 'PASSED',
    ItemSystemExecutionVerdict.partial => 'PARTIAL',
    ItemSystemExecutionVerdict.failed => 'FAILED',
  };
}

final class ItemSystemExecutionReceipt {
  ItemSystemExecutionReceipt._({
    required this.level,
    required this.sourceRevision,
    required this.fixtureSha256,
    required this.payloadSha256,
    required this.payload,
    required this.attemptedCapabilities,
    required this.succeededCapabilities,
    required this.failedCapabilities,
    required this.producer,
    required this.runnerVersion,
    required this.recordedAtUtc,
    required this.verdict,
  });

  factory ItemSystemExecutionReceipt.record({
    required ItemSystemProofLevel level,
    required String sourceRevision,
    required String fixtureSha256,
    required Map<String, Object?> payload,
    required Iterable<String> attemptedCapabilities,
    required Iterable<String> succeededCapabilities,
    Iterable<String> failedCapabilities = const <String>[],
    required String producer,
    required String runnerVersion,
    required DateTime recordedAtUtc,
  }) {
    final canonicalPayload = _canonicalPayload(payload);
    final attempted = _capabilities(
      attemptedCapabilities,
      'attemptedCapabilities',
    );
    final succeeded = _capabilities(
      succeededCapabilities,
      'succeededCapabilities',
    );
    final failed = _capabilities(failedCapabilities, 'failedCapabilities');
    final allowed = ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
      level,
    );
    final unknown = attempted.difference(allowed);
    if (unknown.isNotEmpty) {
      throw FormatException(
        'Unknown ${level.wireName} capabilities: ${_sorted(unknown).join(', ')}.',
      );
    }
    if (attempted.isEmpty) {
      throw const FormatException(
        'An execution receipt must attempt at least one capability.',
      );
    }
    final unattempted = <String>{
      ...succeeded.difference(attempted),
      ...failed.difference(attempted),
    };
    if (unattempted.isNotEmpty) {
      throw FormatException(
        'Capabilities have outcomes without execution: ${_sorted(unattempted).join(', ')}.',
      );
    }
    final conflicting = succeeded.intersection(failed);
    if (conflicting.isNotEmpty) {
      throw FormatException(
        'Capabilities cannot both succeed and fail: ${_sorted(conflicting).join(', ')}.',
      );
    }
    final missingOutcome = attempted.difference(<String>{
      ...succeeded,
      ...failed,
    });
    if (missingOutcome.isNotEmpty) {
      throw FormatException(
        'Attempted capabilities have no outcome: ${_sorted(missingOutcome).join(', ')}.',
      );
    }
    final normalizedRevision = _sourceRevision(sourceRevision);
    final normalizedFixture = _sha256(fixtureSha256, 'fixtureSha256');
    final normalizedProducer = _notBlank(producer, 'producer');
    final normalizedRunnerVersion = _notBlank(runnerVersion, 'runnerVersion');
    final timestamp = recordedAtUtc.toUtc();
    final payloadDigest = sha256
        .convert(utf8.encode(jsonEncode(canonicalPayload)))
        .toString();
    final verdict = failed.isNotEmpty
        ? ItemSystemExecutionVerdict.failed
        : succeeded.containsAll(allowed)
        ? ItemSystemExecutionVerdict.passed
        : ItemSystemExecutionVerdict.partial;
    return ItemSystemExecutionReceipt._(
      level: level,
      sourceRevision: normalizedRevision,
      fixtureSha256: normalizedFixture,
      payloadSha256: payloadDigest,
      payload: Map<String, Object?>.unmodifiable(canonicalPayload),
      attemptedCapabilities: Set<String>.unmodifiable(attempted),
      succeededCapabilities: Set<String>.unmodifiable(succeeded),
      failedCapabilities: Set<String>.unmodifiable(failed),
      producer: normalizedProducer,
      runnerVersion: normalizedRunnerVersion,
      recordedAtUtc: timestamp,
      verdict: verdict,
    );
  }

  factory ItemSystemExecutionReceipt.fromJson(
    Map<String, Object?> json, {
    required String expectedSourceRevision,
    required String expectedFixtureSha256,
  }) {
    _exactKeys(json, const <String>{
      'schemaVersion',
      'domain',
      'level',
      'sourceRevision',
      'fixtureSha256',
      'payloadSha256',
      'payload',
      'attemptedCapabilities',
      'succeededCapabilities',
      'failedCapabilities',
      'producer',
      'runnerVersion',
      'recordedAtUtc',
      'verdict',
    });
    if (json['schemaVersion'] != 1 || json['domain'] != 'item_system_v1') {
      throw const FormatException('Execution receipt identity is invalid.');
    }
    final levelName = json['level'];
    final levels = ItemSystemProofLevel.values.where(
      (candidate) => candidate.wireName == levelName,
    );
    if (levels.length != 1) {
      throw FormatException('Unknown Item System proof level: $levelName.');
    }
    final sourceRevision = _string(json['sourceRevision'], 'sourceRevision');
    if (sourceRevision != _sourceRevision(expectedSourceRevision)) {
      throw const FormatException(
        'Execution receipt source revision does not match the runner revision.',
      );
    }
    final fixtureSha256 = _sha256(
      _string(json['fixtureSha256'], 'fixtureSha256'),
      'fixtureSha256',
    );
    if (fixtureSha256 !=
        _sha256(expectedFixtureSha256, 'expectedFixtureSha256')) {
      throw const FormatException(
        'Execution receipt fixture digest does not match the runner fixture.',
      );
    }
    final payload = json['payload'];
    if (payload is! Map<String, Object?>) {
      throw const FormatException('payload must be a JSON object.');
    }
    final timestampValue = _string(json['recordedAtUtc'], 'recordedAtUtc');
    final timestamp = DateTime.tryParse(timestampValue);
    if (timestamp == null || !timestamp.isUtc) {
      throw const FormatException('recordedAtUtc must be a UTC timestamp.');
    }
    final receipt = ItemSystemExecutionReceipt.record(
      level: levels.single,
      sourceRevision: sourceRevision,
      fixtureSha256: fixtureSha256,
      payload: payload,
      attemptedCapabilities: _stringList(
        json['attemptedCapabilities'],
        'attemptedCapabilities',
      ),
      succeededCapabilities: _stringList(
        json['succeededCapabilities'],
        'succeededCapabilities',
      ),
      failedCapabilities: _stringList(
        json['failedCapabilities'],
        'failedCapabilities',
      ),
      producer: _string(json['producer'], 'producer'),
      runnerVersion: _string(json['runnerVersion'], 'runnerVersion'),
      recordedAtUtc: timestamp,
    );
    final claimedDigest = _sha256(
      _string(json['payloadSha256'], 'payloadSha256'),
      'payloadSha256',
    );
    if (claimedDigest != receipt.payloadSha256) {
      throw const FormatException(
        'Execution receipt payload digest does not match its payload.',
      );
    }
    if (json['verdict'] != receipt.verdict.wireName) {
      throw const FormatException(
        'Execution receipt verdict does not match its outcomes.',
      );
    }
    return receipt;
  }

  final ItemSystemProofLevel level;
  final String sourceRevision;
  final String fixtureSha256;
  final String payloadSha256;
  final Map<String, Object?> payload;
  final Set<String> attemptedCapabilities;
  final Set<String> succeededCapabilities;
  final Set<String> failedCapabilities;
  final String producer;
  final String runnerVersion;
  final DateTime recordedAtUtc;
  final ItemSystemExecutionVerdict verdict;

  String get evidenceSha256 {
    final evidence = toJson()..remove('recordedAtUtc');
    return sha256
        .convert(utf8.encode(jsonEncode(_canonicalJson(evidence, r'$'))))
        .toString();
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    'domain': 'item_system_v1',
    'level': level.wireName,
    'sourceRevision': sourceRevision,
    'fixtureSha256': fixtureSha256,
    'payloadSha256': payloadSha256,
    'payload': payload,
    'attemptedCapabilities': _sorted(attemptedCapabilities),
    'succeededCapabilities': _sorted(succeededCapabilities),
    'failedCapabilities': _sorted(failedCapabilities),
    'producer': producer,
    'runnerVersion': runnerVersion,
    'recordedAtUtc': recordedAtUtc.toIso8601String(),
    'verdict': verdict.wireName,
  };
}

Map<String, Object?> _canonicalPayload(Map<String, Object?> payload) {
  return _canonicalJson(payload, r'$') as Map<String, Object?>;
}

Object? _canonicalJson(Object? value, String path) {
  if (value == null || value is bool || value is String || value is int) {
    return value;
  }
  if (value is double) {
    if (!value.isFinite) {
      throw FormatException('$path must contain finite JSON numbers.');
    }
    return value;
  }
  if (value is List) {
    return List<Object?>.unmodifiable(<Object?>[
      for (var index = 0; index < value.length; index += 1)
        _canonicalJson(value[index], '$path[$index]'),
    ]);
  }
  if (value is Map) {
    if (value.keys.any((key) => key is! String)) {
      throw FormatException('$path must contain only string object keys.');
    }
    final keys = value.keys.cast<String>().toList()..sort();
    return Map<String, Object?>.unmodifiable(<String, Object?>{
      for (final key in keys) key: _canonicalJson(value[key], '$path.$key'),
    });
  }
  throw FormatException('$path contains a non-JSON value.');
}

Set<String> _capabilities(Iterable<String> values, String field) {
  final list = values.toList(growable: false);
  final normalized = <String>{};
  for (final value in list) {
    final capability = _notBlank(value, field);
    if (!normalized.add(capability)) {
      throw FormatException(
        '$field contains duplicate capability $capability.',
      );
    }
  }
  return normalized;
}

List<String> _stringList(Object? value, String field) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$field must be a string list.');
  }
  return value.cast<String>();
}

String _string(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

String _notBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw FormatException('$field must not be blank.');
  return normalized;
}

String _sourceRevision(String value) {
  final normalized = value.trim();
  if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(normalized)) {
    throw const FormatException(
      'sourceRevision must be a lowercase 40-character Git revision.',
    );
  }
  return normalized;
}

String _sha256(String value, String field) {
  final normalized = value.trim();
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(normalized)) {
    throw FormatException('$field must be a lowercase SHA-256 digest.');
  }
  return normalized;
}

List<String> _sorted(Iterable<String> values) => values.toList()..sort();

void _exactKeys(Map<String, Object?> json, Set<String> expected) {
  if (json.length != expected.length ||
      !json.keys.toSet().containsAll(expected)) {
    throw const FormatException('Execution receipt fields are invalid.');
  }
}
