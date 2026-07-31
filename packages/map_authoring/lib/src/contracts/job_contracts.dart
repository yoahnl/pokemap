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
