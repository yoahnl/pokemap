# PMCP-070 — Appendix: complete created Dart files

## `packages/map_authoring/lib/src/contracts/playtest_contracts.dart`

```dart
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
sed: printf: No such file or directory
sed: \n@@FILE_1@@\n: No such file or directory
import 'dart:async';

import '../contracts/authoring_receipt.dart';
import '../contracts/playtest_contracts.dart';

/// Runtime boundary consumed by the Authoring API and, later, the MCP layer.
///
/// Implementations own all platform resources. [PlaytestSession.stop] is
/// therefore idempotent and is the only successful terminal operation.
abstract interface class PlaytestPort {
  Future<PlaytestSession> start(PlaytestStartRequest request);
}

abstract interface class PlaytestSession {
  String get sessionId;

  PlaytestSessionState get state;

  Stream<PlaytestEvent> get events;

  Future<PlaytestSnapshot> snapshot();

  Future<PlaytestCommandResult> execute(PlaytestCommand command);

  Future<void> pause();

  Future<void> resume();

  Future<AuthoringArtifactRef> captureScreenshot(String name);

  Future<PlaytestReceipt> stop();
}
sed: printf: No such file or directory
sed: \n@@FILE_2@@\n: No such file or directory
sed: printf: No such file or directory
sed: \n@@FILE_3@@\n: No such file or directory
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('PlaytestStartRequest', () {
    test('round-trips the frozen project, seed, scenario, and checkpoint', () {
      final request = PlaytestStartRequest(
        sessionId: 'session-070',
        projectId: 'selbrume',
        projectRevision: 'sha256:${'a' * 64}',
        scenarioId: 'golden.slice',
        seed: 42,
        checkpointId: 'before-arene',
      );

      expect(
        PlaytestStartRequest.fromJson(request.toJson()).toJson(),
        request.toJson(),
      );
      expect(request.seed, 42);
    });

    test('rejects a non-digest project revision', () {
      expect(
        () => PlaytestStartRequest(
          sessionId: 'session-070',
          projectId: 'selbrume',
          projectRevision: 'working-copy',
          scenarioId: 'golden.slice',
          seed: 42,
        ),
        throwsArgumentError,
      );
    });
  });

  test('commands and snapshots freeze caller-owned JSON', () {
    final arguments = <String, Object?>{
      'quantities': <String, Object?>{'potion': 2},
    };
    final command = PlaytestCommand(
      commandId: 'command-1',
      operation: 'probe.seedBag',
      arguments: arguments,
    );
    final state = <String, Object?>{
      'bag': <String, Object?>{'potion': 2},
    };
    final snapshot = PlaytestSnapshot(
      projectRevision: 'sha256:${'a' * 64}',
      sequence: 1,
      state: state,
    );

    (arguments['quantities'] as Map<String, Object?>)['potion'] = 99;
    (state['bag'] as Map<String, Object?>)['potion'] = 99;

    expect(
      (command.arguments['quantities'] as Map<String, Object?>)['potion'],
      2,
    );
    expect((snapshot.state['bag'] as Map<String, Object?>)['potion'], 2);
    expect(snapshot.stateDigest, startsWith('sha256:'));
  });

  test('receipt binds revision, seed, scenario, terminal state, and artifacts',
      () {
    final artifact = AuthoringArtifactRef(
      id: 'screenshot-final',
      mediaType: 'image/png',
      uri: 'artifact://sha256/${'b' * 64}',
      byteLength: 4,
      sha256: 'b' * 64,
    );
    final receipt = PlaytestReceipt(
      receiptId: 'playtest-receipt-070',
      sessionId: 'session-070',
      projectId: 'selbrume',
      projectRevision: 'sha256:${'a' * 64}',
      scenarioId: 'golden.slice',
      seed: 42,
      terminalState: PlaytestSessionState.stopped,
      startedAtUtc: '2026-07-31T10:00:00.000Z',
      finishedAtUtc: '2026-07-31T10:00:01.000Z',
      commandCount: 3,
      finalSnapshotDigest: 'sha256:${'c' * 64}',
      artifacts: <AuthoringArtifactRef>[artifact],
    );

    expect(
        PlaytestReceipt.fromJson(receipt.toJson()).toJson(), receipt.toJson());
    expect(receipt.artifacts.single.id, 'screenshot-final');
  });
}
import 'dart:async';

import 'package:map_authoring/map_authoring.dart';

typedef RuntimePlaytestDriverFactory = Future<RuntimePlaytestDriver> Function(
  PlaytestStartRequest request,
);

/// Small protocol implemented by runtime hosts such as PokeMap Eval.
///
/// The protocol transports JSON-safe state and typed authoring commands only;
/// Flame components and filesystem paths never cross into `map_authoring`.
abstract interface class RuntimePlaytestDriver {
  Future<String> readProjectRevision();

  Map<String, Object?> snapshot();

  Future<void> execute(PlaytestCommand command);

  Future<AuthoringArtifactRef> captureScreenshot(String name);

  Future<void> dispose();
}

/// Adapts one isolated runtime driver into the canonical Authoring API port.
final class RuntimePlaytestPort implements PlaytestPort {
  RuntimePlaytestPort({
    required this.driverFactory,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final RuntimePlaytestDriverFactory driverFactory;
  final DateTime Function() _clock;

  @override
  Future<PlaytestSession> start(PlaytestStartRequest request) async {
    final driver = await driverFactory(request);
    try {
      final actualRevision = await driver.readProjectRevision();
      if (actualRevision != request.projectRevision) {
        throw StateError(
          'Playtest revision drift: expected ${request.projectRevision}, '
          'got $actualRevision.',
        );
      }
      return _RuntimePlaytestSession(
        request: request,
        driver: driver,
        clock: _clock,
      );
    } catch (_) {
      await driver.dispose();
      rethrow;
    }
  }
}

final class _RuntimePlaytestSession implements PlaytestSession {
  _RuntimePlaytestSession({
    required this.request,
    required this.driver,
    required this.clock,
  }) : _startedAt = clock().toUtc() {
    _emit('session.started', <String, Object?>{
      'projectId': request.projectId,
      'projectRevision': request.projectRevision,
      'scenarioId': request.scenarioId,
      'seed': request.seed,
      if (request.checkpointId != null) 'checkpointId': request.checkpointId,
    });
  }

  final PlaytestStartRequest request;
  final RuntimePlaytestDriver driver;
  final DateTime Function() clock;
  final DateTime _startedAt;
  final StreamController<PlaytestEvent> _eventController =
      StreamController<PlaytestEvent>.broadcast(sync: true);
  final List<PlaytestEvent> _eventHistory = <PlaytestEvent>[];
  final List<AuthoringArtifactRef> _artifacts = <AuthoringArtifactRef>[];
  final Set<String> _commandIds = <String>{};
  PlaytestSessionState _state = PlaytestSessionState.running;
  PlaytestReceipt? _receipt;
  var _eventSequence = 0;
  var _commandSequence = 0;
  var _driverDisposed = false;

  @override
  String get sessionId => request.sessionId;

  @override
  PlaytestSessionState get state => _state;

  @override
  Stream<PlaytestEvent> get events {
    // New listeners receive the lifecycle prefix before live events. This is
    // important for MCP clients that can only attach after `start` returns.
    return Stream<PlaytestEvent>.multi((controller) {
      for (final event in _eventHistory) {
        controller.addSync(event);
      }
      final subscription = _eventController.stream.listen(
        controller.addSync,
        onError: controller.addErrorSync,
        onDone: controller.closeSync,
      );
      controller.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  @override
  Future<PlaytestSnapshot> snapshot() async {
    _ensureObservable();
    try {
      await _verifyRevision();
      return _snapshot();
    } catch (_) {
      await _failAndDispose();
      rethrow;
    }
  }

  @override
  Future<PlaytestCommandResult> execute(PlaytestCommand command) async {
    _ensureRunning();
    if (!_commandIds.add(command.commandId)) {
      throw StateError('Duplicate playtest command id: ${command.commandId}.');
    }
    _emit('command.started', <String, Object?>{
      'commandId': command.commandId,
      'operation': command.operation,
    });
    try {
      await _verifyRevision();
      final before = _snapshot();
      await driver.execute(command);
      await _verifyRevision();
      _commandSequence += 1;
      final after = _snapshot();
      final diff = _diff(before.state, after.state);
      if (!diff.isEmpty) {
        _emit('state.changed', <String, Object?>{
          'commandId': command.commandId,
          'beforeDigest': before.stateDigest,
          'afterDigest': after.stateDigest,
          'diff': diff.toJson(),
        });
      }
      _emit('command.finished', <String, Object?>{
        'commandId': command.commandId,
        'operation': command.operation,
        'snapshotDigest': after.stateDigest,
      });
      return PlaytestCommandResult(
        commandId: command.commandId,
        snapshot: after,
        diff: diff,
      );
    } catch (error) {
      _emit('command.failed', <String, Object?>{
        'commandId': command.commandId,
        'operation': command.operation,
        'errorType': error.runtimeType.toString(),
      });
      await _failAndDispose();
      rethrow;
    }
  }

  @override
  Future<void> pause() async {
    _ensureRunning();
    _state = PlaytestSessionState.paused;
    _emit('session.paused');
  }

  @override
  Future<void> resume() async {
    if (_state != PlaytestSessionState.paused) {
      throw StateError('Only a paused playtest session can resume.');
    }
    _state = PlaytestSessionState.running;
    _emit('session.resumed');
  }

  @override
  Future<AuthoringArtifactRef> captureScreenshot(String name) async {
    _ensureRunning();
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be blank');
    }
    try {
      await _verifyRevision();
      final artifact = await driver.captureScreenshot(normalized);
      if (_artifacts.any((candidate) => candidate.id == artifact.id)) {
        throw StateError('Duplicate playtest artifact id: ${artifact.id}.');
      }
      _artifacts.add(artifact);
      _emit('artifact.created', <String, Object?>{
        'artifact': artifact.toJson(),
      });
      return artifact;
    } catch (_) {
      await _failAndDispose();
      rethrow;
    }
  }

  @override
  Future<PlaytestReceipt> stop() async {
    final existing = _receipt;
    if (existing != null) return existing;
    if (_state == PlaytestSessionState.failed) {
      throw StateError('A failed playtest session has no success receipt.');
    }
    if (_state != PlaytestSessionState.running &&
        _state != PlaytestSessionState.paused) {
      throw StateError('Playtest session is already terminal.');
    }

    try {
      await _verifyRevision();
      final finalSnapshot = _snapshot();
      final finishedAt = clock().toUtc();
      _state = PlaytestSessionState.stopped;
      _emit('session.stopped', <String, Object?>{
        'finalSnapshotDigest': finalSnapshot.stateDigest,
        'commandCount': _commandSequence,
      });
      await _disposeDriver();
      final receipt = PlaytestReceipt(
        receiptId: _receiptId(finalSnapshot.stateDigest),
        sessionId: request.sessionId,
        projectId: request.projectId,
        projectRevision: request.projectRevision,
        scenarioId: request.scenarioId,
        seed: request.seed,
        terminalState: PlaytestSessionState.stopped,
        startedAtUtc: _startedAt.toIso8601String(),
        finishedAtUtc: finishedAt.toIso8601String(),
        commandCount: _commandSequence,
        finalSnapshotDigest: finalSnapshot.stateDigest,
        artifacts: _artifacts,
      );
      _receipt = receipt;
      await _eventController.close();
      return receipt;
    } catch (_) {
      await _failAndDispose();
      rethrow;
    }
  }

  PlaytestSnapshot _snapshot() => PlaytestSnapshot(
        projectRevision: request.projectRevision,
        sequence: _commandSequence,
        state: driver.snapshot(),
      );

  Future<void> _verifyRevision() async {
    final actual = await driver.readProjectRevision();
    if (actual != request.projectRevision) {
      throw StateError(
        'Project revision changed during playtest: expected '
        '${request.projectRevision}, got $actual.',
      );
    }
  }

  Future<void> _failAndDispose() async {
    if (_state != PlaytestSessionState.failed) {
      _state = PlaytestSessionState.failed;
      _emit('session.failed');
    }
    await _disposeDriver();
    if (!_eventController.isClosed) await _eventController.close();
  }

  Future<void> _disposeDriver() async {
    if (_driverDisposed) return;
    _driverDisposed = true;
    await driver.dispose();
  }

  void _emit(
    String type, [
    Map<String, Object?> payload = const <String, Object?>{},
  ]) {
    final event = PlaytestEvent(
      sequence: ++_eventSequence,
      type: type,
      payload: payload,
    );
    _eventHistory.add(event);
    if (!_eventController.isClosed) _eventController.add(event);
  }

  void _ensureRunning() {
    if (_state != PlaytestSessionState.running) {
      throw StateError('Playtest session is ${_state.name}.');
    }
  }

  void _ensureObservable() {
    if (_state == PlaytestSessionState.failed) {
      throw StateError('Playtest session failed and released its driver.');
    }
  }

  String _receiptId(String finalDigest) {
    final fingerprint = computeAuthoringJsonFingerprint(
      <String, Object?>{
        'sessionId': request.sessionId,
        'projectRevision': request.projectRevision,
        'scenarioId': request.scenarioId,
        'seed': request.seed,
        'finalSnapshotDigest': finalDigest,
        'artifacts': _artifacts.map((artifact) => artifact.toJson()).toList(),
      },
      logicalName: 'playtest-receipt',
    );
    return 'playtest-${fingerprint.substring('sha256:'.length, 29)}';
  }
}

PlaytestStateDiff _diff(
  Map<String, Object?> before,
  Map<String, Object?> after,
) {
  final changes = <PlaytestStateChange>[];
  _collectChanges(before, after, '', changes);
  return PlaytestStateDiff(changes);
}

void _collectChanges(
  Object? before,
  Object? after,
  String path,
  List<PlaytestStateChange> changes,
) {
  if (before is Map<String, Object?> && after is Map<String, Object?>) {
    final keys = <String>{...before.keys, ...after.keys}.toList()..sort();
    for (final key in keys) {
      _collectChanges(
        before[key],
        after[key],
        path.isEmpty ? key : '$path.$key',
        changes,
      );
    }
    return;
  }
  if (canonicalAuthoringJson(before) == canonicalAuthoringJson(after)) return;
  changes.add(PlaytestStateChange(
    path: path.isEmpty ? r'$' : path,
    before: before,
    after: after,
  ));
}
sed: printf: No such file or directory
sed: \n@@FILE_4@@\n: No such file or directory
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('session orders events, supports pause/resume, and disposes once',
      () async {
    final driver = _FakeRuntimePlaytestDriver(
      projectRevision: 'sha256:${'a' * 64}',
    );
    final clock = _Clock(<DateTime>[
      DateTime.utc(2026, 7, 31, 10),
      DateTime.utc(2026, 7, 31, 10, 0, 1),
    ]);
    final port = RuntimePlaytestPort(
      driverFactory: (_) async => driver,
      clock: clock.call,
    );
    final session = await port.start(_request());
    final events = <PlaytestEvent>[];
    final subscription = session.events.listen(events.add);

    final execution = await session.execute(
      PlaytestCommand(
        commandId: 'money',
        operation: 'probe.setMoney',
        arguments: const <String, Object?>{'value': 750},
      ),
    );
    await session.pause();
    await expectLater(
      session.execute(
        PlaytestCommand(
          commandId: 'blocked',
          operation: 'save.write',
        ),
      ),
      throwsStateError,
    );
    await session.resume();
    final artifact = await session.captureScreenshot('final');
    final receipt = await session.stop();
    await subscription.cancel();

    expect(execution.diff.changes.single.path, 'trainer.money');
    expect(
        execution.snapshot.state['trainer'], <String, Object?>{'money': 750});
    expect(artifact.mediaType, 'image/png');
    expect(receipt.artifacts.single.id, artifact.id);
    expect(receipt.commandCount, 1);
    expect(driver.disposeCount, 1);
    expect(session.state, PlaytestSessionState.stopped);
    expect(
      events.map((event) => event.sequence),
      orderedEquals(List<int>.generate(events.length, (index) => index + 1)),
    );
    expect(
        events.map((event) => event.type),
        containsAll(<String>[
          'session.started',
          'command.started',
          'state.changed',
          'command.finished',
          'session.paused',
          'session.resumed',
          'artifact.created',
          'session.stopped',
        ]));

    expect((await session.stop()).toJson(), receipt.toJson());
    expect(driver.disposeCount, 1);
  });

  test('start rejects revision drift and cleans the rejected driver', () async {
    final driver = _FakeRuntimePlaytestDriver(
      projectRevision: 'sha256:${'b' * 64}',
    );
    final port = RuntimePlaytestPort(driverFactory: (_) async => driver);

    await expectLater(port.start(_request()), throwsStateError);
    expect(driver.disposeCount, 1);
  });

  test('revision drift during a command fails and releases the session',
      () async {
    final driver = _FakeRuntimePlaytestDriver(
      projectRevision: 'sha256:${'a' * 64}',
    );
    final port = RuntimePlaytestPort(driverFactory: (_) async => driver);
    final session = await port.start(_request());
    driver.projectRevision = 'sha256:${'b' * 64}';

    await expectLater(
      session.execute(
        PlaytestCommand(
          commandId: 'drifted',
          operation: 'probe.setMoney',
          arguments: const <String, Object?>{'value': 500},
        ),
      ),
      throwsStateError,
    );

    expect(session.state, PlaytestSessionState.failed);
    expect(driver.disposeCount, 1);
  });
}

PlaytestStartRequest _request() => PlaytestStartRequest(
      sessionId: 'session-070',
      projectId: 'selbrume',
      projectRevision: 'sha256:${'a' * 64}',
      scenarioId: 'golden.slice',
      seed: 42,
    );

final class _FakeRuntimePlaytestDriver implements RuntimePlaytestDriver {
  _FakeRuntimePlaytestDriver({required this.projectRevision});

  String projectRevision;
  var money = 1000;
  var disposeCount = 0;

  @override
  Map<String, Object?> snapshot() => <String, Object?>{
        'trainer': <String, Object?>{'money': money},
      };

  @override
  Future<String> readProjectRevision() async => projectRevision;

  @override
  Future<void> execute(PlaytestCommand command) async {
    money = command.arguments['value']! as int;
  }

  @override
  Future<AuthoringArtifactRef> captureScreenshot(String name) async {
    return AuthoringArtifactRef(
      id: 'screenshot-$name',
      mediaType: 'image/png',
      uri: 'artifact://sha256/${'d' * 64}',
      byteLength: 4,
      sha256: 'd' * 64,
    );
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }
}

final class _Clock {
  _Clock(this.values);

  final List<DateTime> values;

  DateTime call() => values.removeAt(0);
}
sed: printf: No such file or directory
sed: \n@@FILE_5@@\n: No such file or directory
import '../driver/evaluation_driver.dart';

typedef EvaluationCommandEvidenceCapture = Future<void> Function({
  required String stepId,
  String? name,
});

/// Single dispatcher shared by scenario runs and Authoring API playtests.
///
/// Keeping this switch unique prevents an API command from claiming support
/// while PokeMap Eval exercises a different or synthetic code path.
final class EvaluationCommandDispatcher {
  const EvaluationCommandDispatcher();

  Future<void> execute({
    required EvaluationDriver driver,
    required String commandId,
    required String operation,
    required Map<String, Object?> arguments,
    EvaluationCommandEvidenceCapture? evidenceCapture,
  }) async {
    final values = EvaluationCommandArguments(arguments);
    await switch (operation) {
      'game.new' => driver.startNewGame(),
      'save.write' => driver.save(),
      'save.reload' => driver.saveAndReload(),
      'movement.navigate' => driver.navigateTo(
          values.requireInt('x'),
          values.requireInt('y'),
        ),
      'movement.crossConnection' => driver.crossConnection(
          values.requireString('direction'),
          preferredAxis: values.optionalInt('preferredAxis'),
        ),
      'movement.enterGameplayZone' => driver.enterGameplayZone(
          values.requireString('zoneId'),
        ),
      'world.interact' => driver.interact(values.requireString('entityId')),
      'world.enterTrigger' => driver.enterTrigger(
          values.requireString('triggerId'),
          expectBattle: values.optionalBool('expectBattle') ?? false,
        ),
      'world.enterWarp' => driver.enterWarp(values.requireString('warpId')),
      'world.enterEncounter' => driver.enterWildEncounter(),
      'world.waitForFact' => driver.waitForFact(
          values.requireString('factId'),
          timeout: values.optionalDuration('timeoutMilliseconds'),
        ),
      'dialogue.advance' => driver.advanceDialogue(),
      'dialogue.choose' => driver.chooseDialogue(
          values.requireNonNegativeInt('choiceIndex'),
          linesBeforeChoice: values.optionalNonNegativeInt('linesBeforeChoice'),
        ),
      'battle.chooseMove' => driver.chooseBattleMove(
          values.requireNonNegativeInt('moveIndex'),
        ),
      'battle.useItem' => driver.useBattleItem(
          values.requireString('itemId'),
        ),
      'battle.capture' => driver.attemptCapture(),
      'battle.run' => driver.runFromBattle(),
      'battle.completePostBattle' => driver.completePostBattle(),
      'battle.resolve' => driver.resolveBattle(
          values.requireString('strategy'),
        ),
      'service.shop.inspect' => driver.inspectShop(),
      'service.shop.buy' => driver.buy(
          values.requireString('itemId'),
          values.requirePositiveInt('quantity'),
        ),
      'service.heal' => driver.healParty(),
      'service.pc.withdraw' => driver.withdrawFromPc(
          values.requireString('pokemonId'),
        ),
      'evidence.checkpoint' => driver.createCheckpoint(
          values.requireString('checkpointId'),
        ),
      'evidence.snapshot' => evidenceCapture == null
          ? Future<void>.value()
          : evidenceCapture(
              stepId: commandId,
              name: values.optionalString('name'),
            ),
      'probe.loadCheckpoint' => driver.probeLoadCheckpoint(
          values.requireString('checkpointId'),
        ),
      'probe.goto' => driver.probeGoto(
          values.requireString('mapId'),
          values.requireInt('x'),
          values.requireInt('y'),
        ),
      'probe.overrideFact' => driver.probeOverrideFact(
          values.requireString('factId'),
          values.requireBool('value'),
        ),
      'probe.setMoney' => driver.probeSetMoney(
          values.requireNonNegativeInt('value'),
        ),
      'probe.seedBag' => driver.probeSeedBag(
          values.requireIntMap('quantities'),
        ),
      'probe.seedParty' => driver.probeSeedParty(
          values.requireMapList('pokemon'),
        ),
      final unsupported => throw EvaluationScenarioExecutionError(
          'Operation "$unsupported" has no runtime dispatcher.',
        ),
    };
  }
}

final class EvaluationScenarioExecutionError implements Exception {
  const EvaluationScenarioExecutionError(this.message);

  final String message;

  @override
  String toString() => 'Invalid evaluation command: $message';
}

final class EvaluationCommandArguments {
  const EvaluationCommandArguments(this.values);

  final Map<String, Object?> values;

  String requireString(String key) {
    final value = values[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be a non-blank string.',
    );
  }

  int requireInt(String key) {
    final value = values[key];
    if (value is int) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be an integer.',
    );
  }

  int requireNonNegativeInt(String key) {
    final value = requireInt(key);
    if (value >= 0) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be non-negative.',
    );
  }

  int requirePositiveInt(String key) {
    final value = requireInt(key);
    if (value > 0) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be positive.',
    );
  }

  int? optionalInt(String key) {
    if (!values.containsKey(key)) return null;
    return requireInt(key);
  }

  String? optionalString(String key) {
    if (!values.containsKey(key)) return null;
    return requireString(key);
  }

  int? optionalNonNegativeInt(String key) {
    if (!values.containsKey(key)) return null;
    return requireNonNegativeInt(key);
  }

  Duration? optionalDuration(String key) {
    if (!values.containsKey(key)) return null;
    return Duration(milliseconds: requirePositiveInt(key));
  }

  bool requireBool(String key) {
    final value = values[key];
    if (value is bool) return value;
    throw EvaluationScenarioExecutionError(
      'Argument "$key" must be a boolean.',
    );
  }

  bool? optionalBool(String key) {
    if (!values.containsKey(key)) return null;
    return requireBool(key);
  }

  Map<String, int> requireIntMap(String key) {
    final value = values[key];
    if (value is! Map) {
      throw EvaluationScenarioExecutionError(
        'Argument "$key" must be an integer map.',
      );
    }
    final result = <String, int>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! int || entry.value < 0) {
        throw EvaluationScenarioExecutionError(
          'Argument "$key" must contain non-negative integer quantities.',
        );
      }
      result[entry.key as String] = entry.value as int;
    }
    return result;
  }

  List<Map<String, Object?>> requireMapList(String key) {
    final value = values[key];
    if (value is! List) {
      throw EvaluationScenarioExecutionError(
        'Argument "$key" must be a list of objects.',
      );
    }
    final result = <Map<String, Object?>>[];
    for (final item in value) {
      if (item is! Map) {
        throw EvaluationScenarioExecutionError(
          'Argument "$key" must contain only objects.',
        );
      }
      result.add(Map<String, Object?>.from(item));
    }
    return result;
  }
}
sed: printf: No such file or directory
sed: \n@@FILE_6@@\n: No such file or directory
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../../project_tree_digest.dart';
import '../runner/evaluation_command_dispatcher.dart';
import 'evaluation_driver.dart';

typedef EvaluationPlaytestDriverFactory = Future<EvaluationDriver> Function({
  required String runId,
  required int seed,
});
typedef EvaluationSurfaceCapture = Future<List<int>> Function();

/// PokeMap Eval adapter for one Authoring API playtest session.
///
/// The production project is read-only. Saves remain inside the evaluator's
/// in-memory repository, while transient captures live in a dedicated sandbox
/// that is recursively removed by [dispose].
final class EvaluationPlaytestDriver implements RuntimePlaytestDriver {
  EvaluationPlaytestDriver._({
    required this.request,
    required this.projectRoot,
    required this.sandboxRoot,
    required this.driver,
    required this.captureSurface,
  });

  static Future<EvaluationPlaytestDriver> start({
    required PlaytestStartRequest request,
    required Directory projectRoot,
    required EvaluationPlaytestDriverFactory driverFactory,
    EvaluationSurfaceCapture? captureSurface,
    void Function(Directory sandbox)? onSandboxCreated,
  }) async {
    final actualRevision = await computeEvaluationProjectRevision(projectRoot);
    if (actualRevision != request.projectRevision) {
      throw StateError(
        'Evaluation project revision mismatch: expected '
        '${request.projectRevision}, got $actualRevision.',
      );
    }

    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_playtest_${_safeSegment(request.sessionId)}_',
    );
    onSandboxCreated?.call(sandbox);
    EvaluationDriver? evaluationDriver;
    try {
      evaluationDriver = await driverFactory(
        runId: request.sessionId,
        seed: request.seed,
      );
      if (request.checkpointId case final checkpointId?) {
        await evaluationDriver.probeLoadCheckpoint(checkpointId);
      }
      return EvaluationPlaytestDriver._(
        request: request,
        projectRoot: projectRoot,
        sandboxRoot: sandbox,
        driver: evaluationDriver,
        captureSurface: captureSurface,
      );
    } catch (_) {
      if (evaluationDriver != null) await evaluationDriver.dispose();
      if (await sandbox.exists()) await sandbox.delete(recursive: true);
      rethrow;
    }
  }

  final PlaytestStartRequest request;
  final Directory projectRoot;
  final Directory sandboxRoot;
  final EvaluationDriver driver;
  final EvaluationSurfaceCapture? captureSurface;
  var _disposed = false;

  @override
  Future<String> readProjectRevision() {
    return computeEvaluationProjectRevision(projectRoot);
  }

  @override
  Map<String, Object?> snapshot() => driver.snapshot().toJson();

  @override
  Future<void> execute(PlaytestCommand command) {
    _ensureOpen();
    return const EvaluationCommandDispatcher().execute(
      driver: driver,
      commandId: command.commandId,
      operation: command.operation,
      arguments: command.arguments,
      evidenceCapture: ({required stepId, name}) async {
        await captureScreenshot(name ?? stepId);
      },
    );
  }

  @override
  Future<AuthoringArtifactRef> captureScreenshot(String name) async {
    _ensureOpen();
    final capture = captureSurface;
    if (capture == null) {
      throw StateError('Visible evaluation surface capture is unavailable.');
    }
    final bytes = await capture();
    if (bytes.isEmpty || bytes.any((byte) => byte < 0 || byte > 255)) {
      throw StateError('Evaluation surface returned invalid image bytes.');
    }
    final digest = sha256.convert(bytes).toString();
    final artifactId = 'screenshot-${_safeSegment(name)}';
    // The temporary file is intentionally not exposed through the public URI.
    // PMCP-071 installs the durable artifact job boundary; this lot only needs
    // content identity and deterministic cleanup.
    final file = File(p.join(sandboxRoot.path, '$artifactId.png'));
    await file.writeAsBytes(bytes, flush: true);
    return AuthoringArtifactRef(
      id: artifactId,
      mediaType: 'image/png',
      uri: 'artifact://sha256/$digest',
      byteLength: bytes.length,
      sha256: digest,
    );
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await driver.dispose();
    } finally {
      if (await sandboxRoot.exists()) {
        await sandboxRoot.delete(recursive: true);
      }
    }
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('Evaluation playtest driver is disposed.');
  }
}

Future<String> computeEvaluationProjectRevision(Directory projectRoot) async {
  final digest = await const ProjectTreeDigest().compute(projectRoot);
  return 'sha256:$digest';
}

String _safeSegment(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9._-]+'),
        '-',
      );
  final bounded =
      normalized.length <= 64 ? normalized : normalized.substring(0, 64);
  return bounded.isEmpty ? 'capture' : bounded;
}
sed: printf: No such file or directory
sed: \n@@FILE_7@@\n: No such file or directory
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_state_snapshot.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/driver/evaluation_playtest_adapter.dart';
import 'package:pokemap_loader/src/evaluation/driver/selbrume_evaluation_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('adapter isolates files, dispatches real driver commands, and cleans up',
      () async {
    final projectRoot =
        await Directory.systemTemp.createTemp('pmcp070_project_');
    addTearDown(() async {
      if (await projectRoot.exists()) await projectRoot.delete(recursive: true);
    });
    final projectFile = File('${projectRoot.path}/project.json');
    await projectFile.writeAsString('{"id":"selbrume"}');
    final beforeBytes = await projectFile.readAsBytes();
    final revision = await computeEvaluationProjectRevision(projectRoot);
    final sandboxes = <Directory>[];
    final driver = _FakeEvaluationDriver();

    final port = RuntimePlaytestPort(
      driverFactory: (request) => EvaluationPlaytestDriver.start(
        request: request,
        projectRoot: projectRoot,
        driverFactory: ({required runId, required seed}) async {
          expect(runId, request.sessionId);
          expect(seed, 42);
          return driver;
        },
        captureSurface: () async => <int>[137, 80, 78, 71],
        onSandboxCreated: sandboxes.add,
      ),
    );
    final session = await port.start(
      PlaytestStartRequest(
        sessionId: 'session-070',
        projectId: 'selbrume',
        projectRevision: revision,
        scenarioId: 'golden.slice',
        seed: 42,
      ),
    );

    await session.execute(
      PlaytestCommand(
        commandId: 'money',
        operation: 'probe.setMoney',
        arguments: const <String, Object?>{'value': 750},
      ),
    );
    await session.captureScreenshot('after-money');
    final receipt = await session.stop();

    expect(driver.money, 750);
    expect(driver.disposeCount, 1);
    expect(receipt.projectRevision, revision);
    expect(receipt.seed, 42);
    expect(receipt.scenarioId, 'golden.slice');
    expect(receipt.artifacts.single.mediaType, 'image/png');
    expect(await projectFile.readAsBytes(), beforeBytes);
    expect(sandboxes, hasLength(1));
    expect(await sandboxes.single.exists(), isFalse);
  });

  test('canonical port drives the real Selbrume evaluation runtime', () async {
    final projectRoot =
        Directory(p.join(_findRepositoryRoot().path, 'selbrume'));
    final revision = await computeEvaluationProjectRevision(projectRoot);
    final beforeRevision = await computeEvaluationProjectRevision(projectRoot);
    final port = RuntimePlaytestPort(
      driverFactory: (request) => EvaluationPlaytestDriver.start(
        request: request,
        projectRoot: projectRoot,
        driverFactory: ({required runId, required seed}) {
          expect(seed, 0);
          return SelbrumeEvaluationDriver.start(
            projectRoot: projectRoot,
            runId: runId,
          );
        },
      ),
    );
    final session = await port.start(
      PlaytestStartRequest(
        sessionId: 'session-070-selbrume',
        projectId: 'selbrume',
        projectRevision: revision,
        scenarioId: 'smoke.start',
        seed: 0,
      ),
    );

    final execution = await session.execute(
      PlaytestCommand(
        commandId: 'money',
        operation: 'probe.setMoney',
        arguments: const <String, Object?>{'value': 1123},
      ),
    );
    final receipt = await session.stop();

    expect(
      (execution.snapshot.state['trainer'] as Map)['money'],
      1123,
    );
    expect(receipt.terminalState, PlaytestSessionState.stopped);
    expect(await computeEvaluationProjectRevision(projectRoot), beforeRevision);
  });
}

final class _FakeEvaluationDriver implements EvaluationDriver {
  var money = 1000;
  var disposeCount = 0;

  @override
  EvaluationStateSnapshot snapshot() => EvaluationStateSnapshot(
        projectId: 'selbrume',
        runId: 'session-070',
        mapId: 'map_bourg_selbrume',
        x: 4,
        y: 7,
        movementMode: 'walk',
        money: money,
      );

  @override
  Future<void> probeSetMoney(int value) async {
    money = value;
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('pokemonProject repository root not found.');
    }
    current = current.parent;
  }
}
```
