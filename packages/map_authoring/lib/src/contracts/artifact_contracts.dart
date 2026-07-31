import 'authoring_receipt.dart';
import 'json_contract_support.dart';

enum ArtifactKind {
  image('image'),
  log('log'),
  receipt('receipt');

  const ArtifactKind(this.wireName);

  final String wireName;

  static ArtifactKind fromWireName(String value) {
    return values.firstWhere(
      (candidate) => candidate.wireName == value,
      orElse: () => throw FormatException('Unknown artifact kind: $value'),
    );
  }
}

/// Ordered evidence emitted by one asynchronous Authoring API job.
final class AuthoringJobArtifact {
  AuthoringJobArtifact({
    required String jobId,
    required int sequence,
    required this.kind,
    required String createdAtUtc,
    required this.reference,
  })  : jobId = _nonBlank(jobId, 'jobId'),
        sequence = _positive(sequence, 'sequence'),
        createdAtUtc = _utcTimestamp(createdAtUtc);

  factory AuthoringJobArtifact.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _artifactKeys);
    final rawReference = json['reference'];
    if (rawReference is! Map) {
      throw const FormatException('reference must be a JSON object');
    }
    try {
      return AuthoringJobArtifact(
        jobId: requireContractString(json['jobId'], 'jobId'),
        sequence: _readPositive(json['sequence'], 'sequence'),
        kind: ArtifactKind.fromWireName(
          requireContractString(json['kind'], 'kind'),
        ),
        createdAtUtc:
            requireContractString(json['createdAtUtc'], 'createdAtUtc'),
        reference: AuthoringArtifactRef.fromJson(
          Map<String, dynamic>.from(rawReference),
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String jobId;
  final int sequence;
  final ArtifactKind kind;
  final String createdAtUtc;
  final AuthoringArtifactRef reference;

  Map<String, Object?> toJson() => <String, Object?>{
        'jobId': jobId,
        'sequence': sequence,
        'kind': kind.wireName,
        'createdAtUtc': createdAtUtc,
        'reference': reference.toJson(),
      };
}

final class AuthoringArtifactManifest {
  AuthoringArtifactManifest({
    required String jobId,
    Iterable<AuthoringJobArtifact> artifacts = const [],
  })  : jobId = _nonBlank(jobId, 'jobId'),
        artifacts = _orderedArtifacts(jobId, artifacts);

  factory AuthoringArtifactManifest.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _manifestKeys);
    final rawArtifacts = json['artifacts'];
    if (rawArtifacts is! List) {
      throw const FormatException('artifacts must be a JSON list');
    }
    try {
      return AuthoringArtifactManifest(
        jobId: requireContractString(json['jobId'], 'jobId'),
        artifacts: rawArtifacts.map((raw) {
          if (raw is! Map) {
            throw const FormatException('artifact must be a JSON object');
          }
          return AuthoringJobArtifact.fromJson(
            Map<String, dynamic>.from(raw),
          );
        }),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String jobId;
  final List<AuthoringJobArtifact> artifacts;

  Map<String, Object?> toJson() => <String, Object?>{
        'jobId': jobId,
        'artifacts': artifacts.map((artifact) => artifact.toJson()).toList(),
      };
}

/// Content-based assertion suitable for screenshots and other job evidence.
///
/// A path is deliberately absent: visual checks remain portable across local,
/// worker, and future remote MCP transports.
final class ArtifactAssertion {
  ArtifactAssertion({
    required String artifactId,
    required this.expectedKind,
    required String expectedMediaType,
    String? expectedSha256,
    int? expectedByteLength,
  })  : artifactId = _nonBlank(artifactId, 'artifactId'),
        expectedMediaType = _nonBlank(expectedMediaType, 'expectedMediaType'),
        expectedSha256 = expectedSha256 == null
            ? null
            : _sha256(expectedSha256, 'expectedSha256'),
        expectedByteLength = _nonNegative(
          expectedByteLength,
          'expectedByteLength',
        );

  factory ArtifactAssertion.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _assertionKeys);
    final rawLength = json['expectedByteLength'];
    if (rawLength != null && rawLength is! int) {
      throw const FormatException('expectedByteLength must be an integer');
    }
    try {
      return ArtifactAssertion(
        artifactId: requireContractString(json['artifactId'], 'artifactId'),
        expectedKind: ArtifactKind.fromWireName(
          requireContractString(json['expectedKind'], 'expectedKind'),
        ),
        expectedMediaType: requireContractString(
          json['expectedMediaType'],
          'expectedMediaType',
        ),
        expectedSha256: readOptionalContractString(
          json['expectedSha256'],
          'expectedSha256',
        ),
        expectedByteLength: rawLength as int?,
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String artifactId;
  final ArtifactKind expectedKind;
  final String expectedMediaType;
  final String? expectedSha256;
  final int? expectedByteLength;

  bool matches(AuthoringJobArtifact artifact) {
    return artifact.reference.id == artifactId &&
        artifact.kind == expectedKind &&
        artifact.reference.mediaType == expectedMediaType &&
        (expectedSha256 == null ||
            artifact.reference.sha256 == expectedSha256) &&
        (expectedByteLength == null ||
            artifact.reference.byteLength == expectedByteLength);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'artifactId': artifactId,
        'expectedKind': expectedKind.wireName,
        'expectedMediaType': expectedMediaType,
        if (expectedSha256 != null) 'expectedSha256': expectedSha256,
        if (expectedByteLength != null)
          'expectedByteLength': expectedByteLength,
      };
}

const _artifactKeys = <String>{
  'jobId',
  'sequence',
  'kind',
  'createdAtUtc',
  'reference',
};
const _manifestKeys = <String>{'jobId', 'artifacts'};
const _assertionKeys = <String>{
  'artifactId',
  'expectedKind',
  'expectedMediaType',
  'expectedSha256',
  'expectedByteLength',
};

List<AuthoringJobArtifact> _orderedArtifacts(
  String jobId,
  Iterable<AuthoringJobArtifact> artifacts,
) {
  final ordered = artifacts.toList()
    ..sort((left, right) => left.sequence.compareTo(right.sequence));
  var previousSequence = 0;
  final ids = <String>{};
  for (final artifact in ordered) {
    if (artifact.jobId != jobId) {
      throw ArgumentError.value(
        artifact.jobId,
        'artifacts',
        'artifact jobId must match manifest jobId',
      );
    }
    if (artifact.sequence <= previousSequence) {
      throw ArgumentError.value(
        artifact.sequence,
        'artifacts',
        'artifact sequences must be unique',
      );
    }
    if (!ids.add(artifact.reference.id)) {
      throw ArgumentError.value(
        artifact.reference.id,
        'artifacts',
        'artifact ids must be unique',
      );
    }
    previousSequence = artifact.sequence;
  }
  return List.unmodifiable(ordered);
}

String _nonBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return value.trim();
}

int _positive(int value, String field) {
  if (value <= 0) {
    throw ArgumentError.value(value, field, 'must be positive');
  }
  return value;
}

int _readPositive(Object? value, String field) {
  if (value is! int) throw FormatException('$field must be an integer');
  return value;
}

int? _nonNegative(int? value, String field) {
  if (value != null && value < 0) {
    throw ArgumentError.value(value, field, 'must not be negative');
  }
  return value;
}

String _sha256(String value, String field) {
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a lowercase SHA-256');
  }
  return value;
}

String _utcTimestamp(String value) {
  final timestamp = DateTime.tryParse(value);
  if (timestamp == null || !timestamp.isUtc || !value.endsWith('Z')) {
    throw ArgumentError.value(
      value,
      'createdAtUtc',
      'must be an ISO-8601 UTC timestamp',
    );
  }
  return value;
}
