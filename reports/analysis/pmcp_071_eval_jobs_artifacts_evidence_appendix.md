# PMCP-071 — Annexe des fichiers Dart créés

Cette annexe reproduit intégralement les fichiers Dart créés par le lot.

## `packages/map_authoring/lib/src/contracts/artifact_contracts.dart`

```dart
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
```

## `packages/map_authoring/lib/src/contracts/job_contracts.dart`

```dart
import 'json_contract_support.dart';

enum AuthoringJobState {
  queued,
  running,
  paused,
  cancelling,
  succeeded,
  failed,
  cancelled;

  static AuthoringJobState fromWireName(String value) {
    return values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => throw FormatException('Unknown job state: $value'),
    );
  }

  bool get isTerminal =>
      this == succeeded || this == failed || this == cancelled;

  bool canTransitionTo(AuthoringJobState next) {
    if (this == next) return true;
    return switch (this) {
      queued => next == running || next == cancelling || next == cancelled,
      running => next == paused ||
          next == cancelling ||
          next == succeeded ||
          next == failed ||
          next == cancelled,
      paused => next == running || next == cancelling || next == cancelled,
      cancelling => next == cancelled || next == failed,
      succeeded || failed || cancelled => false,
    };
  }
}

final class AuthoringJobRequest {
  AuthoringJobRequest({
    required String requestId,
    required String kind,
    required String projectId,
    required String projectRevision,
    Map<String, Object?> input = const {},
  })  : requestId = _nonBlank(requestId, 'requestId'),
        kind = _operation(kind),
        projectId = _nonBlank(projectId, 'projectId'),
        projectRevision = _revision(projectRevision),
        input = freezeContractJsonObject(input, field: 'input');

  factory AuthoringJobRequest.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _requestKeys);
    final rawInput = json['input'];
    if (rawInput is! Map) {
      throw const FormatException('input must be a JSON object');
    }
    try {
      return AuthoringJobRequest(
        requestId: requireContractString(json['requestId'], 'requestId'),
        kind: requireContractString(json['kind'], 'kind'),
        projectId: requireContractString(json['projectId'], 'projectId'),
        projectRevision: requireContractString(
          json['projectRevision'],
          'projectRevision',
        ),
        input: Map<String, Object?>.from(rawInput),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String requestId;
  final String kind;
  final String projectId;
  final String projectRevision;
  final Map<String, Object?> input;

  Map<String, Object?> toJson() => <String, Object?>{
        'requestId': requestId,
        'kind': kind,
        'projectId': projectId,
        'projectRevision': projectRevision,
        'input': input,
      };
}

final class AuthoringJobSnapshot {
  AuthoringJobSnapshot({
    required String jobId,
    required this.request,
    required int attempt,
    required this.state,
    required String createdAtUtc,
    required String updatedAtUtc,
    required int lastEventSequence,
    String? retryOfJobId,
    String? errorCode,
    String? errorMessage,
  })  : jobId = _nonBlank(jobId, 'jobId'),
        attempt = _positive(attempt, 'attempt'),
        createdAtUtc = _utcTimestamp(createdAtUtc, 'createdAtUtc'),
        updatedAtUtc = _utcTimestamp(updatedAtUtc, 'updatedAtUtc'),
        lastEventSequence = _nonNegative(
          lastEventSequence,
          'lastEventSequence',
        ),
        retryOfJobId = _optionalNonBlank(retryOfJobId, 'retryOfJobId'),
        errorCode = _optionalNonBlank(errorCode, 'errorCode'),
        errorMessage = _optionalNonBlank(errorMessage, 'errorMessage') {
    if ((errorCode == null) != (errorMessage == null)) {
      throw ArgumentError(
        'errorCode and errorMessage must both be present or absent',
      );
    }
    if (state == AuthoringJobState.failed && errorCode == null) {
      throw ArgumentError('failed jobs must expose a stable error');
    }
  }

  factory AuthoringJobSnapshot.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _snapshotKeys);
    final rawRequest = json['request'];
    if (rawRequest is! Map) {
      throw const FormatException('request must be a JSON object');
    }
    try {
      return AuthoringJobSnapshot(
        jobId: requireContractString(json['jobId'], 'jobId'),
        request: AuthoringJobRequest.fromJson(
          Map<String, dynamic>.from(rawRequest),
        ),
        attempt: _readInt(json['attempt'], 'attempt'),
        state: AuthoringJobState.fromWireName(
          requireContractString(json['state'], 'state'),
        ),
        createdAtUtc:
            requireContractString(json['createdAtUtc'], 'createdAtUtc'),
        updatedAtUtc:
            requireContractString(json['updatedAtUtc'], 'updatedAtUtc'),
        lastEventSequence: _readInt(
          json['lastEventSequence'],
          'lastEventSequence',
        ),
        retryOfJobId: readOptionalContractString(
          json['retryOfJobId'],
          'retryOfJobId',
        ),
        errorCode: readOptionalContractString(json['errorCode'], 'errorCode'),
        errorMessage:
            readOptionalContractString(json['errorMessage'], 'errorMessage'),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String jobId;
  final AuthoringJobRequest request;
  final int attempt;
  final AuthoringJobState state;
  final String createdAtUtc;
  final String updatedAtUtc;
  final int lastEventSequence;
  final String? retryOfJobId;
  final String? errorCode;
  final String? errorMessage;

  Map<String, Object?> toJson() => <String, Object?>{
        'jobId': jobId,
        'request': request.toJson(),
        'attempt': attempt,
        'state': state.name,
        'createdAtUtc': createdAtUtc,
        'updatedAtUtc': updatedAtUtc,
        'lastEventSequence': lastEventSequence,
        if (retryOfJobId != null) 'retryOfJobId': retryOfJobId,
        if (errorCode != null) 'errorCode': errorCode,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };
}

final class AuthoringJobEvent {
  AuthoringJobEvent({
    required String jobId,
    required int sequence,
    required String type,
    required this.state,
    required String occurredAtUtc,
    Map<String, Object?> payload = const {},
  })  : jobId = _nonBlank(jobId, 'jobId'),
        sequence = _positive(sequence, 'sequence'),
        type = _operation(type),
        occurredAtUtc = _utcTimestamp(occurredAtUtc, 'occurredAtUtc'),
        payload = freezeContractJsonObject(payload, field: 'payload');

  factory AuthoringJobEvent.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _eventKeys);
    final rawPayload = json['payload'];
    if (rawPayload is! Map) {
      throw const FormatException('payload must be a JSON object');
    }
    try {
      return AuthoringJobEvent(
        jobId: requireContractString(json['jobId'], 'jobId'),
        sequence: _readInt(json['sequence'], 'sequence'),
        type: requireContractString(json['type'], 'type'),
        state: AuthoringJobState.fromWireName(
          requireContractString(json['state'], 'state'),
        ),
        occurredAtUtc:
            requireContractString(json['occurredAtUtc'], 'occurredAtUtc'),
        payload: Map<String, Object?>.from(rawPayload),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String jobId;
  final int sequence;
  final String type;
  final AuthoringJobState state;
  final String occurredAtUtc;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => <String, Object?>{
        'jobId': jobId,
        'sequence': sequence,
        'type': type,
        'state': state.name,
        'occurredAtUtc': occurredAtUtc,
        'payload': payload,
      };
}

final class AuthoringJobCancellation {
  AuthoringJobCancellation({
    required String jobId,
    required this.state,
    required this.bounded,
    required int timeoutMilliseconds,
  })  : jobId = _nonBlank(jobId, 'jobId'),
        timeoutMilliseconds = _positive(
          timeoutMilliseconds,
          'timeoutMilliseconds',
        ) {
    if (state != AuthoringJobState.cancelled &&
        state != AuthoringJobState.cancelling) {
      throw ArgumentError.value(
        state,
        'state',
        'cancellation state must be cancelling or cancelled',
      );
    }
  }

  final String jobId;
  final AuthoringJobState state;
  final bool bounded;
  final int timeoutMilliseconds;
}

/// Transport-neutral long-running operation port used by the API and MCP.
abstract interface class AuthoringJobPort {
  Future<AuthoringJobSnapshot> start(AuthoringJobRequest request);

  Future<AuthoringJobSnapshot> get(String jobId);

  Future<List<AuthoringJobEvent>> events(
    String jobId, {
    int afterSequence = 0,
  });

  Future<AuthoringJobCancellation> cancel(
    String jobId, {
    required Duration timeout,
  });

  Future<AuthoringJobSnapshot> retry(String jobId);
}

const _requestKeys = <String>{
  'requestId',
  'kind',
  'projectId',
  'projectRevision',
  'input',
};
const _snapshotKeys = <String>{
  'jobId',
  'request',
  'attempt',
  'state',
  'createdAtUtc',
  'updatedAtUtc',
  'lastEventSequence',
  'retryOfJobId',
  'errorCode',
  'errorMessage',
};
const _eventKeys = <String>{
  'jobId',
  'sequence',
  'type',
  'state',
  'occurredAtUtc',
  'payload',
};

String _nonBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return value.trim();
}

String? _optionalNonBlank(String? value, String field) {
  return value == null ? null : _nonBlank(value, field);
}

String _operation(String value) {
  final normalized = _nonBlank(value, 'operation');
  if (!RegExp(r'^[a-z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)+$')
      .hasMatch(normalized)) {
    throw ArgumentError.value(value, 'operation', 'must be a dotted name');
  }
  return normalized;
}

String _revision(String value) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'projectRevision',
      'must be a lowercase SHA-256 revision',
    );
  }
  return value;
}

int _positive(int value, String field) {
  if (value <= 0) {
    throw ArgumentError.value(value, field, 'must be positive');
  }
  return value;
}

int _nonNegative(int value, String field) {
  if (value < 0) {
    throw ArgumentError.value(value, field, 'must not be negative');
  }
  return value;
}

int _readInt(Object? value, String field) {
  if (value is! int) throw FormatException('$field must be an integer');
  return value;
}

String _utcTimestamp(String value, String field) {
  final timestamp = DateTime.tryParse(value);
  if (timestamp == null || !timestamp.isUtc || !value.endsWith('Z')) {
    throw ArgumentError.value(
      value,
      field,
      'must be an ISO-8601 UTC timestamp',
    );
  }
  return value;
}
```

## `packages/map_authoring/test/contracts/job_contract_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('authoring job contracts', () {
    test('round-trips a retryable job and keeps event order explicit', () {
      final request = AuthoringJobRequest(
        requestId: 'request-071',
        kind: 'playtest.run',
        projectId: 'selbrume',
        projectRevision: 'sha256:${'a' * 64}',
        input: <String, Object?>{
          'scenarioId': 'golden.slice',
          'seed': 42,
        },
      );
      final snapshot = AuthoringJobSnapshot(
        jobId: 'job-071',
        request: request,
        attempt: 2,
        state: AuthoringJobState.running,
        createdAtUtc: '2026-07-31T12:00:00.000Z',
        updatedAtUtc: '2026-07-31T12:00:01.000Z',
        lastEventSequence: 3,
        retryOfJobId: 'job-070',
      );
      final event = AuthoringJobEvent(
        jobId: 'job-071',
        sequence: 3,
        type: 'runtime.snapshot',
        state: AuthoringJobState.running,
        occurredAtUtc: '2026-07-31T12:00:01.000Z',
        payload: const <String, Object?>{'mapId': 'selbrume_depart'},
      );

      expect(
        AuthoringJobSnapshot.fromJson(snapshot.toJson()).toJson(),
        snapshot.toJson(),
      );
      expect(
        AuthoringJobEvent.fromJson(event.toJson()).toJson(),
        event.toJson(),
      );
      expect(snapshot.request.input['seed'], 42);
    });

    test('rejects invalid transition and sequence values', () {
      expect(
        () => AuthoringJobEvent(
          jobId: 'job-071',
          sequence: 0,
          type: 'queued',
          state: AuthoringJobState.queued,
          occurredAtUtc: '2026-07-31T12:00:00.000Z',
        ),
        throwsArgumentError,
      );
      expect(
        AuthoringJobState.succeeded.canTransitionTo(
          AuthoringJobState.running,
        ),
        isFalse,
      );
      expect(
        AuthoringJobState.running.canTransitionTo(
          AuthoringJobState.cancelled,
        ),
        isTrue,
      );
    });

    test('binds image, log, and receipt artifacts without local paths', () {
      final artifacts = <AuthoringJobArtifact>[
        _artifact(ArtifactKind.image, 'image/png', 'a'),
        _artifact(ArtifactKind.log, 'application/x-ndjson', 'b'),
        _artifact(ArtifactKind.receipt, 'application/json', 'c'),
      ];
      final manifest = AuthoringArtifactManifest(
        jobId: 'job-071',
        artifacts: artifacts,
      );

      expect(
        AuthoringArtifactManifest.fromJson(manifest.toJson()).toJson(),
        manifest.toJson(),
      );
      expect(
        manifest.artifacts.map((artifact) => artifact.kind),
        containsAll(ArtifactKind.values),
      );
      expect(
        manifest.artifacts.every(
          (artifact) => artifact.reference.uri.startsWith('artifact://'),
        ),
        isTrue,
      );
    });

    test('visual assertions require content identity, not a file path', () {
      final assertion = ArtifactAssertion(
        artifactId: 'artifact-image',
        expectedKind: ArtifactKind.image,
        expectedMediaType: 'image/png',
        expectedSha256: 'a' * 64,
        expectedByteLength: 128,
      );

      expect(
        assertion.matches(_artifact(ArtifactKind.image, 'image/png', 'a')),
        isTrue,
      );
      expect(
        assertion.matches(_artifact(ArtifactKind.image, 'image/png', 'd')),
        isFalse,
      );
    });
  });
}

AuthoringJobArtifact _artifact(
  ArtifactKind kind,
  String mediaType,
  String digestCharacter,
) {
  return AuthoringJobArtifact(
    jobId: 'job-071',
    sequence: kind.index + 1,
    kind: kind,
    createdAtUtc: '2026-07-31T12:00:0${kind.index}.000Z',
    reference: AuthoringArtifactRef(
      id: 'artifact-${kind.wireName}',
      mediaType: mediaType,
      uri: 'artifact://sha256/${digestCharacter * 64}',
      byteLength: kind == ArtifactKind.image ? 128 : 64,
      sha256: digestCharacter * 64,
    ),
  );
}
```

## `examples/playable_runtime_host/lib/src/evaluation/authoring/evaluation_authoring_job_service.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../contracts/evaluation_event.dart';
import '../contracts/evaluation_receipt.dart';
import '../web/evaluation_worker_pool.dart';
import '../worker/evaluation_worker_protocol.dart';

typedef EvaluationJobArtifactCollector = Future<List<AuthoringJobArtifact>>
    Function(
  AuthoringJobSnapshot snapshot,
  EvaluationWorkerResult result,
);
typedef EvaluationWorkerRequestFactory = EvaluationWorkerRequest Function(
  AuthoringJobSnapshot snapshot,
);

/// Converts the worker's private files into path-free, content-addressed API
/// artifacts. Receipt-declared files are resolved below the receipt directory
/// and symlinks are checked against the configured repository boundary.
final class EvaluationFileArtifactCollector {
  EvaluationFileArtifactCollector({required Directory repositoryRoot})
      : repositoryRoot = repositoryRoot.absolute;

  final Directory repositoryRoot;

  Future<List<AuthoringJobArtifact>> collect(
    AuthoringJobSnapshot snapshot,
    EvaluationWorkerResult result,
  ) async {
    final receiptPath = result.receiptPath;
    if (receiptPath == null) return const <AuthoringJobArtifact>[];
    final rootPath = await repositoryRoot.resolveSymbolicLinks();
    final receipt = await _boundedFile(
      File(p.join(repositoryRoot.path, receiptPath)),
      rootPath,
    );
    final decoded = jsonDecode(await receipt.readAsString());
    if (decoded is! Map || decoded['artifacts'] is! List) {
      throw const FormatException(
        'Evaluation receipt must declare an artifacts list.',
      );
    }
    final files = <(ArtifactKind, File)>[(ArtifactKind.receipt, receipt)];
    for (final rawPath in decoded['artifacts']! as List) {
      if (rawPath is! String ||
          rawPath.trim().isEmpty ||
          p.isAbsolute(rawPath) ||
          p.split(rawPath).contains('..')) {
        throw const FormatException(
          'Evaluation receipt artifact paths must remain relative.',
        );
      }
      final file = await _boundedFile(
        File(p.join(receipt.parent.path, rawPath)),
        rootPath,
      );
      files.add((_kindFor(file.path), file));
    }

    final artifacts = <AuthoringJobArtifact>[];
    for (var index = 0; index < files.length; index += 1) {
      final (kind, file) = files[index];
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes).toString();
      final sequence = index + 1;
      artifacts.add(
        AuthoringJobArtifact(
          jobId: snapshot.jobId,
          sequence: sequence,
          kind: kind,
          createdAtUtc: (await file.lastModified()).toUtc().toIso8601String(),
          reference: AuthoringArtifactRef(
            id: '${kind.wireName}-$sequence',
            mediaType: _mediaTypeFor(file.path, kind),
            uri: 'artifact://sha256/$digest',
            byteLength: bytes.length,
            sha256: digest,
          ),
        ),
      );
    }
    return List<AuthoringJobArtifact>.unmodifiable(artifacts);
  }

  Future<File> _boundedFile(File candidate, String rootPath) async {
    if (!await candidate.exists()) {
      throw StateError('Declared evaluation artifact does not exist.');
    }
    final resolved = await candidate.resolveSymbolicLinks();
    if (resolved != rootPath && !p.isWithin(rootPath, resolved)) {
      throw StateError('Evaluation artifact escaped the repository boundary.');
    }
    return File(resolved);
  }
}

ArtifactKind _kindFor(String path) {
  return switch (p.extension(path).toLowerCase()) {
    '.png' || '.jpg' || '.jpeg' || '.webp' => ArtifactKind.image,
    _ => ArtifactKind.log,
  };
}

String _mediaTypeFor(String path, ArtifactKind kind) {
  if (kind == ArtifactKind.receipt) return 'application/json';
  return switch (p.extension(path).toLowerCase()) {
    '.png' => 'image/png',
    '.jpg' || '.jpeg' => 'image/jpeg',
    '.webp' => 'image/webp',
    '.json' => 'application/json',
    '.jsonl' || '.ndjson' => 'application/x-ndjson',
    _ => 'text/plain',
  };
}

abstract interface class EvaluationAuthoringJobExecutor {
  Future<EvaluationWorkerResult> run(
    AuthoringJobSnapshot snapshot,
    void Function(EvaluationEvent event) eventSink,
  );

  Future<bool> cancel(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  });

  Future<bool> forceStop(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  });
}

/// Production adapter from transport-neutral Authoring jobs to PokeMap Eval's
/// persistent, project-serialized worker pool.
final class EvaluationWorkerPoolJobExecutor
    implements EvaluationAuthoringJobExecutor {
  EvaluationWorkerPoolJobExecutor({
    required this.workerPool,
    required this.requestFactory,
    this.releaseEvidenceCandidate = false,
  });

  final EvaluationWorkerPool workerPool;
  final EvaluationWorkerRequestFactory requestFactory;
  final bool releaseEvidenceCandidate;

  @override
  Future<EvaluationWorkerResult> run(
    AuthoringJobSnapshot snapshot,
    void Function(EvaluationEvent event) eventSink,
  ) {
    return workerPool.run(
      projectId: snapshot.request.projectId,
      request: requestFactory(snapshot),
      eventSink: eventSink,
      releaseEvidenceCandidate: releaseEvidenceCandidate,
    );
  }

  @override
  Future<bool> cancel(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async {
    try {
      await workerPool
          .control(
            projectId: snapshot.request.projectId,
            runId: snapshot.jobId,
            action: EvaluationWorkerControlAction.cancel,
          )
          .timeout(timeout);
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> forceStop(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) {
    return workerPool.forceStopProject(
      snapshot.request.projectId,
      timeout: timeout,
    );
  }
}

/// In-memory orchestration for `jobs.start/get/events/cancel/retry`.
///
/// Each lifecycle or worker event receives a fresh service-owned sequence, so
/// polling and streaming transports observe the same stable order even if a
/// worker uses a different sequence domain.
final class EvaluationAuthoringJobService implements AuthoringJobPort {
  EvaluationAuthoringJobService({
    required this.executor,
    DateTime Function()? clock,
    String Function()? jobIdFactory,
    EvaluationJobArtifactCollector? artifactCollector,
  })  : _clock = clock ?? DateTime.now,
        _jobIdFactory = jobIdFactory ?? _defaultJobId,
        _artifactCollector = artifactCollector ?? _noArtifacts;

  final EvaluationAuthoringJobExecutor executor;
  final DateTime Function() _clock;
  final String Function() _jobIdFactory;
  final EvaluationJobArtifactCollector _artifactCollector;
  final Map<String, _JobRecord> _jobs = <String, _JobRecord>{};
  var _closed = false;

  @override
  Future<AuthoringJobSnapshot> start(AuthoringJobRequest request) async {
    _ensureOpen();
    final jobId = _uniqueJobId();
    final record = _JobRecord(
      jobId: jobId,
      request: request,
      attempt: 1,
      createdAt: _clock().toUtc(),
    );
    _jobs[jobId] = record;
    _emit(record, 'job.queued', AuthoringJobState.queued);
    scheduleMicrotask(() => _execute(record));
    return record.snapshot();
  }

  @override
  Future<AuthoringJobSnapshot> get(String jobId) async {
    return _require(jobId).snapshot();
  }

  @override
  Future<List<AuthoringJobEvent>> events(
    String jobId, {
    int afterSequence = 0,
  }) async {
    if (afterSequence < 0) {
      throw ArgumentError.value(
        afterSequence,
        'afterSequence',
        'must not be negative',
      );
    }
    return List<AuthoringJobEvent>.unmodifiable(
      _require(jobId).events.where((event) => event.sequence > afterSequence),
    );
  }

  @override
  Future<AuthoringJobCancellation> cancel(
    String jobId, {
    required Duration timeout,
  }) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'must be positive');
    }
    final record = _require(jobId);
    if (record.state == AuthoringJobState.cancelled) {
      return AuthoringJobCancellation(
        jobId: jobId,
        state: AuthoringJobState.cancelled,
        bounded: true,
        timeoutMilliseconds: timeout.inMilliseconds,
      );
    }
    if (record.state.isTerminal) {
      throw StateError('Job $jobId is already ${record.state.name}.');
    }
    record.cancelRequested = true;
    if (record.state != AuthoringJobState.cancelling) {
      _emit(record, 'job.cancelling', AuthoringJobState.cancelling);
    }

    final stopwatch = Stopwatch()..start();
    final acknowledged = await _withinRemaining(
      () => executor.cancel(
        record.snapshot(),
        timeout: _remaining(timeout, stopwatch),
      ),
      timeout,
      stopwatch,
      fallback: false,
    );
    if (!acknowledged && !record.terminal.isCompleted) {
      final stopped = await _withinRemaining(
        () => executor.forceStop(
          record.snapshot(),
          timeout: _remaining(timeout, stopwatch),
        ),
        timeout,
        stopwatch,
        fallback: false,
      );
      if (stopped && !record.terminal.isCompleted) {
        _finishCancelled(record, forced: true);
      }
    }
    if (!record.terminal.isCompleted) {
      await _withinRemaining<void>(
        () => record.terminal.future,
        timeout,
        stopwatch,
        fallback: null,
      );
    }
    stopwatch.stop();
    final bounded = record.state == AuthoringJobState.cancelled;
    return AuthoringJobCancellation(
      jobId: jobId,
      state:
          bounded ? AuthoringJobState.cancelled : AuthoringJobState.cancelling,
      bounded: bounded,
      timeoutMilliseconds: timeout.inMilliseconds,
    );
  }

  @override
  Future<AuthoringJobSnapshot> retry(String jobId) async {
    _ensureOpen();
    final source = _require(jobId);
    if (source.state != AuthoringJobState.failed &&
        source.state != AuthoringJobState.cancelled) {
      throw StateError(
        'Only failed or cancelled jobs can be retried; '
        '$jobId is ${source.state.name}.',
      );
    }
    final retryId = _uniqueJobId();
    final record = _JobRecord(
      jobId: retryId,
      request: source.request,
      attempt: source.attempt + 1,
      createdAt: _clock().toUtc(),
      retryOfJobId: source.jobId,
    );
    _jobs[retryId] = record;
    _emit(
      record,
      'job.queued',
      AuthoringJobState.queued,
      <String, Object?>{'retryOfJobId': source.jobId},
    );
    scheduleMicrotask(() => _execute(record));
    return record.snapshot();
  }

  Future<AuthoringJobSnapshot> waitForTerminal(String jobId) async {
    final record = _require(jobId);
    if (!record.state.isTerminal) await record.terminal.future;
    return record.snapshot();
  }

  Future<AuthoringArtifactManifest> artifacts(String jobId) async {
    final record = _require(jobId);
    return AuthoringArtifactManifest(
      jobId: jobId,
      artifacts: record.artifacts,
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final active = _jobs.values.where((record) => !record.state.isTerminal);
    await Future.wait<void>(
      active.map((record) async {
        record.cancelRequested = true;
        if (!record.terminal.isCompleted) {
          await executor.forceStop(
            record.snapshot(),
            timeout: const Duration(seconds: 1),
          );
        }
      }),
    );
  }

  Future<void> _execute(_JobRecord record) async {
    if (record.cancelRequested) {
      _finishCancelled(record);
      return;
    }
    _emit(record, 'job.running', AuthoringJobState.running);
    try {
      final result = await executor.run(
        record.snapshot(),
        (workerEvent) {
          if (record.state.isTerminal) return;
          _emit(
            record,
            'worker.${workerEvent.type}',
            record.state,
            <String, Object?>{
              'workerSequence': workerEvent.sequence,
              ...workerEvent.payload,
            },
          );
        },
      );
      if (record.state.isTerminal) return;
      record.artifacts = await _artifactCollector(record.snapshot(), result);
      if (record.cancelRequested ||
          result.status == EvaluationRunStatus.cancelled) {
        _finishCancelled(record);
      } else if (result.status == EvaluationRunStatus.succeeded) {
        _finish(record, AuthoringJobState.succeeded, 'job.succeeded');
      } else {
        _finishFailed(
          record,
          'evaluation.${result.status.name}',
          result.message ?? 'Evaluation worker returned ${result.status.name}.',
        );
      }
    } on Object catch (error) {
      if (record.state.isTerminal) return;
      if (record.cancelRequested) {
        _finishCancelled(record, forced: true);
      } else {
        _finishFailed(record, 'evaluation.workerFailure', '$error');
      }
    }
  }

  void _finishCancelled(_JobRecord record, {bool forced = false}) {
    if (record.state.isTerminal) return;
    _finish(
      record,
      AuthoringJobState.cancelled,
      'job.cancelled',
      <String, Object?>{'forced': forced},
    );
  }

  void _finishFailed(_JobRecord record, String code, String message) {
    record
      ..errorCode = code
      ..errorMessage = message;
    _finish(
      record,
      AuthoringJobState.failed,
      'job.failed',
      <String, Object?>{'errorCode': code, 'message': message},
    );
  }

  void _finish(
    _JobRecord record,
    AuthoringJobState state,
    String type, [
    Map<String, Object?> payload = const <String, Object?>{},
  ]) {
    _emit(record, type, state, payload);
    if (!record.terminal.isCompleted) record.terminal.complete();
  }

  void _emit(
    _JobRecord record,
    String type,
    AuthoringJobState state, [
    Map<String, Object?> payload = const <String, Object?>{},
  ]) {
    if (!record.state.canTransitionTo(state)) {
      throw StateError(
        'Invalid job transition ${record.state.name} -> ${state.name}.',
      );
    }
    record
      ..state = state
      ..updatedAt = _clock().toUtc();
    record.events.add(
      AuthoringJobEvent(
        jobId: record.jobId,
        sequence: record.events.length + 1,
        type: type,
        state: state,
        occurredAtUtc: record.updatedAt.toIso8601String(),
        payload: payload,
      ),
    );
  }

  _JobRecord _require(String jobId) {
    final record = _jobs[jobId];
    if (record == null) throw StateError('Unknown authoring job $jobId.');
    return record;
  }

  String _uniqueJobId() {
    final id = _jobIdFactory().trim();
    if (id.isEmpty || _jobs.containsKey(id)) {
      throw StateError('Job id factory returned an invalid or duplicate id.');
    }
    return id;
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Authoring job service is closed.');
  }
}

final class _JobRecord {
  _JobRecord({
    required this.jobId,
    required this.request,
    required this.attempt,
    required this.createdAt,
    this.retryOfJobId,
  }) : updatedAt = createdAt;

  final String jobId;
  final AuthoringJobRequest request;
  final int attempt;
  final DateTime createdAt;
  final String? retryOfJobId;
  DateTime updatedAt;
  AuthoringJobState state = AuthoringJobState.queued;
  final List<AuthoringJobEvent> events = <AuthoringJobEvent>[];
  final Completer<void> terminal = Completer<void>();
  List<AuthoringJobArtifact> artifacts = <AuthoringJobArtifact>[];
  String? errorCode;
  String? errorMessage;
  bool cancelRequested = false;

  AuthoringJobSnapshot snapshot() => AuthoringJobSnapshot(
        jobId: jobId,
        request: request,
        attempt: attempt,
        state: state,
        createdAtUtc: createdAt.toIso8601String(),
        updatedAtUtc: updatedAt.toIso8601String(),
        lastEventSequence: events.length,
        retryOfJobId: retryOfJobId,
        errorCode: errorCode,
        errorMessage: errorMessage,
      );
}

Future<T> _withinRemaining<T>(
  Future<T> Function() operation,
  Duration total,
  Stopwatch stopwatch, {
  required T fallback,
}) async {
  final remaining = _remaining(total, stopwatch);
  if (remaining <= Duration.zero) return fallback;
  try {
    return await operation().timeout(remaining);
  } on Object {
    return fallback;
  }
}

Duration _remaining(Duration total, Stopwatch stopwatch) {
  final remaining = total - stopwatch.elapsed;
  return remaining.isNegative ? Duration.zero : remaining;
}

String _defaultJobId() =>
    'job-${DateTime.now().toUtc().microsecondsSinceEpoch}';

Future<List<AuthoringJobArtifact>> _noArtifacts(
  AuthoringJobSnapshot snapshot,
  EvaluationWorkerResult result,
) async =>
    const <AuthoringJobArtifact>[];
```

## `examples/playable_runtime_host/lib/src/evaluation/driver/runtime_player_shell_automation.dart`

```dart
import 'package:map_runtime/map_runtime.dart';

import 'evaluation_driver.dart';

/// Typed PokeMap Eval adapter over the production runtime-player state machine.
final class RuntimePlayerCoordinatorEvaluationShell
    implements EvaluationPlayerShellAutomation {
  RuntimePlayerCoordinatorEvaluationShell(this.coordinator);

  final RuntimePlayerCoordinator coordinator;

  @override
  Future<void> pause() => _dispatch(RuntimePlayerAction.openMenu);

  @override
  Future<void> resume() => _dispatch(RuntimePlayerAction.resume);

  @override
  Future<void> openOptions() => _dispatch(RuntimePlayerAction.openOptions);

  @override
  Future<void> openPokedex() => _dispatch(RuntimePlayerAction.openPokedex);

  @override
  Future<void> saveSlot() => _dispatch(RuntimePlayerAction.save);

  @override
  Future<void> loadSlot(String profileId, String slotId) {
    return _dispatch(
      RuntimePlayerAction.load,
      payload: RuntimePlayerLoadSlot(profileId: profileId, slotId: slotId),
    );
  }

  Future<void> _dispatch(RuntimePlayerAction action, {Object? payload}) async {
    final result = await coordinator.dispatch(
      RuntimePlayerCommand(
        action: action,
        snapshotRevision: coordinator.snapshot.revision,
        payload: payload,
      ),
    );
    if (result.status != RuntimePlayerCommandStatus.accepted) {
      throw StateError(
        'Player shell rejected ${action.name}: '
        '${result.safeMessage ?? result.status.name}.',
      );
    }
  }
}
```

## `examples/playable_runtime_host/test/evaluation/evaluation_authoring_job_service_test.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/authoring/evaluation_authoring_job_service.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_event.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';

void main() {
  test('jobs expose ordered events and cooperative bounded cancellation',
      () async {
    final executor = _ControlledExecutor();
    final service = EvaluationAuthoringJobService(
      executor: executor,
      clock: _Clock().call,
      jobIdFactory: _Ids(<String>['job-071']).next,
    );
    addTearDown(service.close);

    final started = await service.start(_request('request-071'));
    await executor.started.future;
    executor.emit(
      EvaluationEvent(
        runId: started.jobId,
        sequence: 7,
        type: 'step.finished',
        payload: const <String, Object?>{'stepId': 'new-game'},
      ),
    );
    final cancellation = await service.cancel(
      started.jobId,
      timeout: const Duration(milliseconds: 200),
    );

    expect(cancellation.bounded, isTrue);
    expect(cancellation.state, AuthoringJobState.cancelled);
    expect(executor.cancelCalls, 1);
    final events = await service.events(started.jobId);
    expect(
      events.map((event) => event.sequence),
      List<int>.generate(events.length, (index) => index + 1),
    );
    expect(
      events.map((event) => event.type),
      containsAllInOrder(<String>[
        'job.queued',
        'job.running',
        'worker.step.finished',
        'job.cancelling',
        'job.cancelled',
      ]),
    );
    expect(
      (events
          .firstWhere((event) => event.type == 'worker.step.finished')
          .payload['workerSequence']),
      7,
    );
  });

  test('cancellation call returns inside its bound when a worker is stuck',
      () async {
    final executor = _ControlledExecutor(ignoreCancellation: true);
    final service = EvaluationAuthoringJobService(
      executor: executor,
      clock: _Clock().call,
      jobIdFactory: _Ids(<String>['job-stuck']).next,
    );
    addTearDown(service.close);
    final started = await service.start(_request('request-stuck'));
    await executor.started.future;
    final stopwatch = Stopwatch()..start();

    final cancellation = await service.cancel(
      started.jobId,
      timeout: const Duration(milliseconds: 40),
    );

    stopwatch.stop();
    expect(cancellation.bounded, isFalse);
    expect(cancellation.state, AuthoringJobState.cancelling);
    expect(stopwatch.elapsed, lessThan(const Duration(milliseconds: 160)));
    executor.completeCancelled();
  });

  test('retry creates a traceable attempt and publishes safe artifacts',
      () async {
    final executor = _SequencedExecutor(<EvaluationWorkerResult>[
      EvaluationWorkerResult.infrastructureFailure(
        runId: 'placeholder',
        message: 'renderer unavailable',
      ),
      EvaluationWorkerResult.completed(
        runId: 'placeholder',
        status: EvaluationRunStatus.succeeded,
        exitCode: 0,
      ),
    ]);
    final service = EvaluationAuthoringJobService(
      executor: executor,
      clock: _Clock().call,
      jobIdFactory: _Ids(<String>['job-failed', 'job-retry']).next,
      artifactCollector: (snapshot, result) async => <AuthoringJobArtifact>[
        AuthoringJobArtifact(
          jobId: snapshot.jobId,
          sequence: 1,
          kind: ArtifactKind.receipt,
          createdAtUtc: '2026-07-31T12:00:09.000Z',
          reference: AuthoringArtifactRef(
            id: 'receipt-${snapshot.jobId}',
            mediaType: 'application/json',
            uri: 'artifact://sha256/${'a' * 64}',
            byteLength: 12,
            sha256: 'a' * 64,
          ),
        ),
      ],
    );
    addTearDown(service.close);

    final failed = await service.start(_request('request-retry'));
    await service.waitForTerminal(failed.jobId);
    final retried = await service.retry(failed.jobId);
    final terminal = await service.waitForTerminal(retried.jobId);
    final artifacts = await service.artifacts(retried.jobId);

    expect(terminal.state, AuthoringJobState.succeeded);
    expect(retried.retryOfJobId, failed.jobId);
    expect(retried.attempt, 2);
    expect(artifacts.artifacts.single.kind, ArtifactKind.receipt);
    expect(artifacts.artifacts.single.reference.uri, startsWith('artifact://'));
  });

  test('file collector converts image, log, and receipt into digest handles',
      () async {
    final root = await Directory.systemTemp.createTemp('pmcp071-artifacts-');
    addTearDown(() => root.delete(recursive: true));
    final output = Directory(p.join(root.path, 'runs', 'job-files'));
    await Directory(p.join(output.path, 'artifacts')).create(recursive: true);
    await File(p.join(output.path, 'events.jsonl')).writeAsString('{}\n');
    await File(p.join(output.path, 'artifacts', 'final.png'))
        .writeAsBytes(<int>[137, 80, 78, 71]);
    final receipt = File(p.join(output.path, 'receipt.json'));
    await receipt.writeAsString(
      jsonEncode(<String, Object?>{
        'artifacts': <String>['events.jsonl', 'artifacts/final.png'],
      }),
    );
    final snapshot = AuthoringJobSnapshot(
      jobId: 'job-files',
      request: _request('request-files'),
      attempt: 1,
      state: AuthoringJobState.succeeded,
      createdAtUtc: '2026-07-31T12:00:00.000Z',
      updatedAtUtc: '2026-07-31T12:00:01.000Z',
      lastEventSequence: 3,
    );

    final artifacts = await EvaluationFileArtifactCollector(
      repositoryRoot: root,
    ).collect(
      snapshot,
      EvaluationWorkerResult.completed(
        runId: snapshot.jobId,
        status: EvaluationRunStatus.succeeded,
        exitCode: 0,
        receiptPath: 'runs/job-files/receipt.json',
      ),
    );

    expect(
      artifacts.map((artifact) => artifact.kind),
      containsAll(ArtifactKind.values),
    );
    expect(
      artifacts.every(
        (artifact) =>
            artifact.reference.uri.startsWith('artifact://sha256/') &&
            !artifact.reference.toJson().toString().contains(root.path),
      ),
      isTrue,
    );
  });
}

AuthoringJobRequest _request(String requestId) {
  return AuthoringJobRequest(
    requestId: requestId,
    kind: 'playtest.run',
    projectId: 'selbrume',
    projectRevision: 'sha256:${'a' * 64}',
    input: const <String, Object?>{'scenarioId': 'golden.slice'},
  );
}

final class _ControlledExecutor implements EvaluationAuthoringJobExecutor {
  _ControlledExecutor({this.ignoreCancellation = false});

  final bool ignoreCancellation;
  final Completer<void> started = Completer<void>();
  final Completer<EvaluationWorkerResult> _result =
      Completer<EvaluationWorkerResult>();
  late void Function(EvaluationEvent event) emit;
  var cancelCalls = 0;

  @override
  Future<EvaluationWorkerResult> run(
    AuthoringJobSnapshot snapshot,
    void Function(EvaluationEvent event) eventSink,
  ) {
    emit = eventSink;
    if (!started.isCompleted) started.complete();
    return _result.future;
  }

  @override
  Future<bool> cancel(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async {
    cancelCalls += 1;
    if (!ignoreCancellation) completeCancelled();
    return !ignoreCancellation;
  }

  @override
  Future<bool> forceStop(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async =>
      false;

  void completeCancelled() {
    if (_result.isCompleted) return;
    _result.complete(
      EvaluationWorkerResult.completed(
        runId: 'placeholder',
        status: EvaluationRunStatus.cancelled,
        exitCode: 130,
      ),
    );
  }
}

final class _SequencedExecutor implements EvaluationAuthoringJobExecutor {
  _SequencedExecutor(this.results);

  final List<EvaluationWorkerResult> results;

  @override
  Future<EvaluationWorkerResult> run(
    AuthoringJobSnapshot snapshot,
    void Function(EvaluationEvent event) eventSink,
  ) async =>
      results.removeAt(0);

  @override
  Future<bool> cancel(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async =>
      true;

  @override
  Future<bool> forceStop(
    AuthoringJobSnapshot snapshot, {
    required Duration timeout,
  }) async =>
      true;
}

final class _Ids {
  _Ids(this.values);

  final List<String> values;

  String next() => values.removeAt(0);
}

final class _Clock {
  var milliseconds = 0;

  DateTime call() => DateTime.utc(2026, 7, 31, 12).add(
        Duration(milliseconds: milliseconds++),
      );
}
```

## `examples/playable_runtime_host/test/evaluation/evaluation_phase6_command_catalog_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_command_dispatcher.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_command_catalog.dart';

void main() {
  test('every applicable Phase 6 command has an explicit dispatcher path', () {
    const expected = <String>{
      'party.swap',
      'party.setLead',
      'bag.use',
      'service.pc.deposit',
      'service.pc.withdrawSlot',
      'service.pc.swap',
      'service.shop.sell',
      'battle.switch',
      'battle.chooseProgression',
      'battle.startTrainer',
      'battle.startStatic',
      'player.pause',
      'player.resume',
      'player.openOptions',
      'player.openPokedex',
      'player.saveSlot',
      'player.loadSlot',
    };

    expect(evaluationCommandCatalog.keys, containsAll(expected));
    expect(
      evaluationCommandCatalog.keys.toSet(),
      EvaluationCommandDispatcher.supportedOperations,
    );
    expect(
      expected.every(
        (operation) =>
            evaluationCommandCatalog[operation]?.sequenceKind ==
            EvaluationCommandSequenceKind.explicitUserAction,
      ),
      isTrue,
    );
    expect(
      evaluationCommandCatalog['player.pause']?.availability,
      EvaluationCommandAvailability.attachedPlayerShell,
    );
  });

  test('manual target choice is explicit capability truth, not a fake command',
      () {
    expect(evaluationCommandCatalog, isNot(contains('battle.chooseTarget')));
    expect(
      evaluationUnavailableCommandCapabilities['battle.chooseTarget']?.reason,
      contains('single-target'),
    );
  });
}
```

## `examples/playable_runtime_host/test/evaluation/evaluation_phase6_assertions_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_scenario.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_state_snapshot.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_assertion_evaluator.dart';

void main() {
  test('scene and outcome fields are first-class assertion roots', () {
    final snapshot = EvaluationStateSnapshot(
      projectId: 'selbrume',
      runId: 'run-071',
      mapId: 'map_port',
      x: 2,
      y: 3,
      movementMode: 'walk',
      money: 100,
      activeScene: const <String, Object?>{
        'active': true,
        'pendingBattle': false,
      },
      outcome: const <String, Object?>{
        'flowPhase': 'scene',
        'gameCompleted': false,
      },
    );
    const evaluator = EvaluationAssertionEvaluator();

    expect(
      evaluator
          .evaluate(
            EvaluationAssertionStep(
              id: 'scene-active',
              path: 'scene.active',
              matcher: 'isTrue',
              expected: true,
            ),
            snapshot,
          )
          .passed,
      isTrue,
    );
    expect(
      evaluator
          .evaluate(
            EvaluationAssertionStep(
              id: 'outcome-phase',
              path: 'outcome.flowPhase',
              matcher: 'equals',
              expected: 'scene',
            ),
            snapshot,
          )
          .passed,
      isTrue,
    );
  });
}
```
