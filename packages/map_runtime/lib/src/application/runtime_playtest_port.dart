import 'dart:async';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

typedef RuntimePlaytestDriverFactory = Future<RuntimePlaytestDriver> Function(
  PlaytestStartRequest request,
);
typedef RuntimePokemonCatalogPreflight =
    Future<PokemonCatalogCoherenceReport> Function(
  PlaytestStartRequest request,
);

final class RuntimePlaytestReadinessException implements Exception {
  const RuntimePlaytestReadinessException(this.report);

  final PokemonCatalogCoherenceReport report;

  @override
  String toString() => 'RuntimePlaytestReadinessException('
      '${report.errorCount} Pokemon catalog errors)';
}

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
    required this.pokemonCatalogPreflight,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final RuntimePlaytestDriverFactory driverFactory;
  final RuntimePokemonCatalogPreflight pokemonCatalogPreflight;
  final DateTime Function() _clock;

  @override
  Future<PlaytestSession> start(PlaytestStartRequest request) async {
    final readiness = await pokemonCatalogPreflight(request);
    if (!readiness.canPlaytest) {
      throw RuntimePlaytestReadinessException(readiness);
    }
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
