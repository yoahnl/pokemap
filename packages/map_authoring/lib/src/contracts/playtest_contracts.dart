import '../support/authoring_fingerprint.dart';
import 'authoring_receipt.dart';
import 'json_contract_support.dart';

/// Lifecycle exposed by a sandboxed runtime session.
///
/// `failed` is terminal: adapters must release their driver before publishing
/// it, so a client never has to guess whether a failed run still owns files or
/// processes.
enum PlaytestSessionState {
  running,
  paused,
  stopped,
  failed;

  static PlaytestSessionState fromWireName(String value) {
    return values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => throw FormatException(
        'Unknown playtest session state: $value',
      ),
    );
  }
}

/// Immutable identity of the exact project snapshot a runtime may execute.
final class PlaytestStartRequest {
  PlaytestStartRequest({
    required String sessionId,
    required String projectId,
    required String projectRevision,
    required String scenarioId,
    required this.seed,
    String? checkpointId,
  })  : sessionId = _nonBlank(sessionId, 'sessionId'),
        projectId = _nonBlank(projectId, 'projectId'),
        projectRevision = _revision(projectRevision, 'projectRevision'),
        scenarioId = _nonBlank(scenarioId, 'scenarioId'),
        checkpointId = checkpointId == null
            ? null
            : _nonBlank(checkpointId, 'checkpointId');

  factory PlaytestStartRequest.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _startRequestKeys);
    final rawSeed = json['seed'];
    if (rawSeed is! int) throw const FormatException('seed must be an integer');
    try {
      return PlaytestStartRequest(
        sessionId: requireContractString(json['sessionId'], 'sessionId'),
        projectId: requireContractString(json['projectId'], 'projectId'),
        projectRevision: requireContractString(
          json['projectRevision'],
          'projectRevision',
        ),
        scenarioId: requireContractString(json['scenarioId'], 'scenarioId'),
        seed: rawSeed,
        checkpointId: readOptionalContractString(
          json['checkpointId'],
          'checkpointId',
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String sessionId;
  final String projectId;
  final String projectRevision;
  final String scenarioId;
  final int seed;
  final String? checkpointId;

  Map<String, Object?> toJson() => <String, Object?>{
        'sessionId': sessionId,
        'projectId': projectId,
        'projectRevision': projectRevision,
        'scenarioId': scenarioId,
        'seed': seed,
        if (checkpointId != null) 'checkpointId': checkpointId,
      };
}

/// One user-visible runtime action.
///
/// Operations are intentionally named rather than accepting opaque scripts:
/// the runtime adapter must dispatch every operation through a reviewed path.
final class PlaytestCommand {
  PlaytestCommand({
    required String commandId,
    required String operation,
    Map<String, Object?> arguments = const <String, Object?>{},
  })  : commandId = _nonBlank(commandId, 'commandId'),
        operation = _operation(operation),
        arguments = freezeContractJsonObject(
          arguments,
          field: 'arguments',
        );

  factory PlaytestCommand.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _commandKeys);
    final rawArguments = json['arguments'];
    if (rawArguments is! Map) {
      throw const FormatException('arguments must be a JSON object');
    }
    try {
      return PlaytestCommand(
        commandId: requireContractString(json['commandId'], 'commandId'),
        operation: requireContractString(json['operation'], 'operation'),
        arguments: Map<String, Object?>.from(rawArguments),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String commandId;
  final String operation;
  final Map<String, Object?> arguments;

  Map<String, Object?> toJson() => <String, Object?>{
        'commandId': commandId,
        'operation': operation,
        'arguments': arguments,
      };
}

/// Ordered observable emitted by a playtest session.
final class PlaytestEvent {
  PlaytestEvent({
    required this.sequence,
    required String type,
    Map<String, Object?> payload = const <String, Object?>{},
  })  : type = _operation(type),
        payload = freezeContractJsonObject(payload, field: 'payload') {
    if (sequence <= 0) {
      throw ArgumentError.value(sequence, 'sequence', 'must be positive');
    }
  }

  final int sequence;
  final String type;
  final Map<String, Object?> payload;

  Map<String, Object?> toJson() => <String, Object?>{
        'sequence': sequence,
        'type': type,
        'payload': payload,
      };
}

/// Path-level change between two runtime snapshots.
final class PlaytestStateChange {
  PlaytestStateChange({
    required String path,
    required Object? before,
    required Object? after,
  })  : path = _nonBlank(path, 'path'),
        before = freezeContractJsonValue(before, field: 'before'),
        after = freezeContractJsonValue(after, field: 'after');

  final String path;
  final Object? before;
  final Object? after;

  Map<String, Object?> toJson() => <String, Object?>{
        'path': path,
        'before': before,
        'after': after,
      };
}

/// Deterministically ordered state delta for one command.
final class PlaytestStateDiff {
  PlaytestStateDiff(Iterable<PlaytestStateChange> changes)
      : changes = List<PlaytestStateChange>.unmodifiable(
          changes.toList()
            ..sort((left, right) => left.path.compareTo(right.path)),
        );

  final List<PlaytestStateChange> changes;

  bool get isEmpty => changes.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
        'changes': changes.map((change) => change.toJson()).toList(),
      };
}

/// Path-free immutable runtime observation.
final class PlaytestSnapshot {
  PlaytestSnapshot({
    required String projectRevision,
    required this.sequence,
    required Map<String, Object?> state,
  })  : projectRevision = _revision(projectRevision, 'projectRevision'),
        state = freezeContractJsonObject(state, field: 'state') {
    if (sequence < 0) {
      throw ArgumentError.value(sequence, 'sequence', 'must not be negative');
    }
  }

  final String projectRevision;
  final int sequence;
  final Map<String, Object?> state;

  String get stateDigest => computeAuthoringJsonFingerprint(
        state,
        logicalName: 'playtest-state',
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'projectRevision': projectRevision,
        'sequence': sequence,
        'stateDigest': stateDigest,
        'state': state,
      };
}

/// Result of one completely dispatched runtime command.
final class PlaytestCommandResult {
  const PlaytestCommandResult({
    required this.commandId,
    required this.snapshot,
    required this.diff,
  });

  final String commandId;
  final PlaytestSnapshot snapshot;
  final PlaytestStateDiff diff;

  Map<String, Object?> toJson() => <String, Object?>{
        'commandId': commandId,
        'snapshot': snapshot.toJson(),
        'diff': diff.toJson(),
      };
}

/// Terminal evidence for one sandboxed run.
final class PlaytestReceipt {
  PlaytestReceipt({
    required String receiptId,
    required String sessionId,
    required String projectId,
    required String projectRevision,
    required String scenarioId,
    required this.seed,
    required this.terminalState,
    required String startedAtUtc,
    required String finishedAtUtc,
    required this.commandCount,
    required String finalSnapshotDigest,
    Iterable<AuthoringArtifactRef> artifacts = const <AuthoringArtifactRef>[],
  })  : receiptId = _nonBlank(receiptId, 'receiptId'),
        sessionId = _nonBlank(sessionId, 'sessionId'),
        projectId = _nonBlank(projectId, 'projectId'),
        projectRevision = _revision(projectRevision, 'projectRevision'),
        scenarioId = _nonBlank(scenarioId, 'scenarioId'),
        startedAtUtc = _utcTimestamp(startedAtUtc, 'startedAtUtc'),
        finishedAtUtc = _utcTimestamp(finishedAtUtc, 'finishedAtUtc'),
        finalSnapshotDigest = _revision(
          finalSnapshotDigest,
          'finalSnapshotDigest',
        ),
        artifacts = List<AuthoringArtifactRef>.unmodifiable(
          artifacts.toList()
            ..sort((left, right) => left.id.compareTo(right.id)),
        ) {
    if (terminalState != PlaytestSessionState.stopped &&
        terminalState != PlaytestSessionState.failed) {
      throw ArgumentError.value(
        terminalState,
        'terminalState',
        'must be stopped or failed',
      );
    }
    if (commandCount < 0) {
      throw ArgumentError.value(
        commandCount,
        'commandCount',
        'must not be negative',
      );
    }
    if (DateTime.parse(this.finishedAtUtc)
        .isBefore(DateTime.parse(this.startedAtUtc))) {
      throw ArgumentError('finishedAtUtc must not precede startedAtUtc');
    }
  }

  factory PlaytestReceipt.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _receiptKeys);
    final rawSeed = json['seed'];
    final rawCount = json['commandCount'];
    final rawArtifacts = json['artifacts'];
    if (rawSeed is! int) throw const FormatException('seed must be an integer');
    if (rawCount is! int) {
      throw const FormatException('commandCount must be an integer');
    }
    if (rawArtifacts is! List) {
      throw const FormatException('artifacts must be a JSON list');
    }
    try {
      return PlaytestReceipt(
        receiptId: requireContractString(json['receiptId'], 'receiptId'),
        sessionId: requireContractString(json['sessionId'], 'sessionId'),
        projectId: requireContractString(json['projectId'], 'projectId'),
        projectRevision: requireContractString(
          json['projectRevision'],
          'projectRevision',
        ),
        scenarioId: requireContractString(json['scenarioId'], 'scenarioId'),
        seed: rawSeed,
        terminalState: PlaytestSessionState.fromWireName(
          requireContractString(json['terminalState'], 'terminalState'),
        ),
        startedAtUtc:
            requireContractString(json['startedAtUtc'], 'startedAtUtc'),
        finishedAtUtc:
            requireContractString(json['finishedAtUtc'], 'finishedAtUtc'),
        commandCount: rawCount,
        finalSnapshotDigest: requireContractString(
          json['finalSnapshotDigest'],
          'finalSnapshotDigest',
        ),
        artifacts: rawArtifacts.map((raw) {
          if (raw is! Map) {
            throw const FormatException('artifact must be a JSON object');
          }
          return AuthoringArtifactRef.fromJson(Map<String, dynamic>.from(raw));
        }),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String receiptId;
  final String sessionId;
  final String projectId;
  final String projectRevision;
  final String scenarioId;
  final int seed;
  final PlaytestSessionState terminalState;
  final String startedAtUtc;
  final String finishedAtUtc;
  final int commandCount;
  final String finalSnapshotDigest;
  final List<AuthoringArtifactRef> artifacts;

  Map<String, Object?> toJson() => <String, Object?>{
        'receiptId': receiptId,
        'sessionId': sessionId,
        'projectId': projectId,
        'projectRevision': projectRevision,
        'scenarioId': scenarioId,
        'seed': seed,
        'terminalState': terminalState.name,
        'startedAtUtc': startedAtUtc,
        'finishedAtUtc': finishedAtUtc,
        'commandCount': commandCount,
        'finalSnapshotDigest': finalSnapshotDigest,
        'artifacts': artifacts.map((artifact) => artifact.toJson()).toList(),
      };
}

const _startRequestKeys = <String>{
  'sessionId',
  'projectId',
  'projectRevision',
  'scenarioId',
  'seed',
  'checkpointId',
};
const _commandKeys = <String>{'commandId', 'operation', 'arguments'};
const _receiptKeys = <String>{
  'receiptId',
  'sessionId',
  'projectId',
  'projectRevision',
  'scenarioId',
  'seed',
  'terminalState',
  'startedAtUtc',
  'finishedAtUtc',
  'commandCount',
  'finalSnapshotDigest',
  'artifacts',
};

String _nonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return normalized;
}

String _operation(String value) {
  final normalized = _nonBlank(value, 'operation');
  if (!RegExp(r'^[a-z][a-zA-Z0-9]*(?:\.[a-zA-Z0-9]+)+$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'operation',
      'must be a dotted stable operation name',
    );
  }
  return normalized;
}

String _revision(String value, String field) {
  final normalized = _nonBlank(value, field);
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      field,
      'must be a lowercase SHA-256 digest',
    );
  }
  return normalized;
}

String _utcTimestamp(String value, String field) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc || parsed.toIso8601String() != value) {
    throw ArgumentError.value(
      value,
      field,
      'must be a canonical UTC ISO-8601 timestamp',
    );
  }
  return value;
}
