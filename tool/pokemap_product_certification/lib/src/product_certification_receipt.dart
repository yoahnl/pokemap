import 'dart:convert';

enum ProductCertificationEvidenceId {
  neutralGame,
  offlineJourney,
  releaseLifecycle,
  killAndPerformance,
  macosDistribution,
}

enum ProductCertificationEvidenceStatus { passed, failed, blocked }

enum ProductCertificationVerdict { go, noGo }

final class ProductCertificationEvidence {
  const ProductCertificationEvidence({
    required this.id,
    required this.status,
    required this.summary,
    required this.command,
    required this.resultSha256,
  });

  factory ProductCertificationEvidence.fromJson(Map<String, Object?> json) {
    _expectKeys(
      json,
      const <String>{
        'id',
        'status',
        'summary',
        'command',
        'resultSha256',
      },
    );
    return ProductCertificationEvidence(
      id: _enumByName(
        ProductCertificationEvidenceId.values,
        json['id'],
        r'$.evidence[].id',
      ),
      status: _enumByName(
        ProductCertificationEvidenceStatus.values,
        json['status'],
        r'$.evidence[].status',
      ),
      summary: _string(json['summary'], r'$.evidence[].summary'),
      command: _nullableString(json['command'], r'$.evidence[].command'),
      resultSha256: _nullableString(
        json['resultSha256'],
        r'$.evidence[].resultSha256',
      ),
    );
  }

  final ProductCertificationEvidenceId id;
  final ProductCertificationEvidenceStatus status;
  final String summary;
  final String? command;
  final String? resultSha256;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id.name,
        'status': status.name,
        'summary': summary,
        'command': command,
        'resultSha256': resultSha256,
      };
}

final class ProductCertificationReceipt {
  ProductCertificationReceipt({
    this.schemaVersion = 1,
    required this.runId,
    required DateTime createdAt,
    required this.releaseCommit,
    required this.gameId,
    required this.gameVersion,
    required this.packageSha256,
    required this.installedTreeSha256,
    required List<ProductCertificationEvidence> evidence,
  })  : createdAt = createdAt.toUtc(),
        evidence = List<ProductCertificationEvidence>.unmodifiable(
          evidence.toList()
            ..sort((left, right) => left.id.index.compareTo(right.id.index)),
        ) {
    _validate();
  }

  factory ProductCertificationReceipt.fromJson(Map<String, Object?> json) {
    _expectKeys(
      json,
      const <String>{
        'schemaVersion',
        'runId',
        'createdAt',
        'releaseCommit',
        'gameId',
        'gameVersion',
        'packageSha256',
        'installedTreeSha256',
        'verdict',
        'evidence',
      },
    );
    final rawEvidence = json['evidence'];
    if (rawEvidence is! List<Object?>) {
      throw const FormatException(r'$.evidence must be an array.');
    }
    final receipt = ProductCertificationReceipt(
      schemaVersion: _integer(json['schemaVersion'], r'$.schemaVersion'),
      runId: _string(json['runId'], r'$.runId'),
      createdAt: DateTime.parse(_string(json['createdAt'], r'$.createdAt')),
      releaseCommit: _string(json['releaseCommit'], r'$.releaseCommit'),
      gameId: _string(json['gameId'], r'$.gameId'),
      gameVersion: _string(json['gameVersion'], r'$.gameVersion'),
      packageSha256: _string(json['packageSha256'], r'$.packageSha256'),
      installedTreeSha256:
          _string(json['installedTreeSha256'], r'$.installedTreeSha256'),
      evidence: rawEvidence.map((entry) {
        if (entry is! Map<String, Object?>) {
          throw const FormatException(
            r'$.evidence entries must be objects.',
          );
        }
        return ProductCertificationEvidence.fromJson(entry);
      }).toList(growable: false),
    );
    if (json['verdict'] != receipt.verdict.name) {
      throw const FormatException(r'$.verdict does not match evidence.');
    }
    return receipt;
  }

  final int schemaVersion;
  final String runId;
  final DateTime createdAt;
  final String releaseCommit;
  final String gameId;
  final String gameVersion;
  final String packageSha256;
  final String installedTreeSha256;
  final List<ProductCertificationEvidence> evidence;

  ProductCertificationVerdict get verdict => evidence.every(
        (entry) => entry.status == ProductCertificationEvidenceStatus.passed,
      )
          ? ProductCertificationVerdict.go
          : ProductCertificationVerdict.noGo;

  List<ProductCertificationEvidenceId> get blockingEvidenceIds =>
      List<ProductCertificationEvidenceId>.unmodifiable(
        evidence
            .where(
              (entry) =>
                  entry.status != ProductCertificationEvidenceStatus.passed,
            )
            .map((entry) => entry.id),
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'runId': runId,
        'createdAt': createdAt.toIso8601String(),
        'releaseCommit': releaseCommit,
        'gameId': gameId,
        'gameVersion': gameVersion,
        'packageSha256': packageSha256,
        'installedTreeSha256': installedTreeSha256,
        'verdict': verdict.name,
        'evidence':
            evidence.map((entry) => entry.toJson()).toList(growable: false),
      };

  String encodeCanonical() => jsonEncode(toJson());

  void _validate() {
    if (schemaVersion != 1) {
      throw const FormatException(r'$.schemaVersion must be 1.');
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{2,79}$').hasMatch(runId)) {
      throw const FormatException(r'$.runId is invalid.');
    }
    if (!RegExp(r'^[0-9a-f]{7,40}$').hasMatch(releaseCommit)) {
      throw const FormatException(r'$.releaseCommit is invalid.');
    }
    if (!RegExp(r'^[a-z0-9]+(?:[._-][a-z0-9]+){2,}$').hasMatch(gameId)) {
      throw const FormatException(r'$.gameId is invalid.');
    }
    if (!RegExp(r'^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$')
        .hasMatch(gameVersion)) {
      throw const FormatException(r'$.gameVersion is invalid.');
    }
    _validateSha256(packageSha256, r'$.packageSha256');
    _validateSha256(installedTreeSha256, r'$.installedTreeSha256');
    if (evidence.length != ProductCertificationEvidenceId.values.length ||
        evidence.map((entry) => entry.id).toSet().length != evidence.length ||
        !ProductCertificationEvidenceId.values.every(
          (id) => evidence.any((entry) => entry.id == id),
        )) {
      throw const FormatException(
        r'$.evidence must contain every phase 8 gate exactly once.',
      );
    }
    for (final entry in evidence) {
      _validateSafeSummary(entry.summary);
      if (entry.status == ProductCertificationEvidenceStatus.passed) {
        final command = entry.command;
        final resultSha256 = entry.resultSha256;
        if (command == null || resultSha256 == null) {
          throw const FormatException(
            'Passed evidence requires an executed command and result digest.',
          );
        }
        _validateSafeSummary(command);
        _validateSha256(resultSha256, r'$.evidence[].resultSha256');
      } else if (entry.command != null || entry.resultSha256 != null) {
        throw const FormatException(
          'Failed or blocked evidence cannot claim an executed result.',
        );
      }
    }
  }
}

void _validateSha256(String value, String path) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw FormatException('$path must be a lowercase SHA-256 digest.');
  }
}

void _validateSafeSummary(String summary) {
  final value = summary.trim();
  if (value.isEmpty || value.length > 240) {
    throw const FormatException('Evidence summaries must contain 1–240 chars.');
  }
  final hasAbsolutePath = RegExp(
    r'(?:file://)?/(?:Users|home|private|tmp|var|Volumes)/|[a-z]:[\\/]',
    caseSensitive: false,
  ).hasMatch(value);
  final hasSecret = RegExp(
    r'\b(?:password|token|secret|api[_-]?key|notary[_-]?password)'
    r'\s*[:=]|'
    r'\bbearer\s+[a-z0-9._~+/-]{8,}|'
    r'\bsk-[a-z0-9_-]{8,}|'
    r'private\s+key',
    caseSensitive: false,
  ).hasMatch(value);
  if (hasAbsolutePath || hasSecret) {
    throw const FormatException(
      'Evidence summaries must not contain paths or secrets.',
    );
  }
}

void _expectKeys(Map<String, Object?> json, Set<String> expected) {
  if (json.keys.toSet().difference(expected).isNotEmpty ||
      expected.difference(json.keys.toSet()).isNotEmpty) {
    throw const FormatException('Certification JSON keys are invalid.');
  }
}

T _enumByName<T extends Enum>(
  List<T> values,
  Object? value,
  String path,
) {
  final name = _string(value, path);
  for (final candidate in values) {
    if (candidate.name == name) return candidate;
  }
  throw FormatException('$path is invalid.');
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

int _integer(Object? value, String path) {
  if (value is! int) throw FormatException('$path must be an integer.');
  return value;
}
