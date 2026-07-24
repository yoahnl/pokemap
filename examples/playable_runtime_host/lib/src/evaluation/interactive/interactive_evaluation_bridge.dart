import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import '../contracts/evaluation_event.dart';
import '../contracts/evaluation_receipt.dart';
import '../driver/evaluation_driver.dart';
import '../driver/selbrume_evaluation_driver.dart';
import '../runner/evaluation_scenario_runner.dart';
import '../scenario/evaluation_policy_validator.dart';
import '../scenario/evaluation_scenario_parser.dart';
import 'interactive_evaluation_config.dart';

const interactiveEvaluationProtocolVersion = 1;
const _maximumEnvelopeLength = 1024 * 1024;

typedef InteractiveEvaluationEventSink = void Function(EvaluationEvent event);

final class InteractiveEvaluationBridge {
  InteractiveEvaluationBridge({
    required this.config,
    required this.driver,
    this.eventSink,
  });

  final InteractiveEvaluationConfig config;
  final EvaluationDriver driver;
  final InteractiveEvaluationEventSink? eventSink;

  Socket? _socket;
  StreamSubscription<String>? _subscription;
  Completer<void>? _handshake;
  Future<void> _commandQueue = Future<void>.value();
  bool _authenticated = false;
  bool _disposed = false;

  static Future<InteractiveEvaluationBridge> attach({
    required InteractiveEvaluationConfig config,
    required PlayableMapGame game,
    required ProjectManifest project,
    required Directory projectRoot,
    required EvaluationPlayerServiceAutomation services,
    InteractiveEvaluationEventSink? eventSink,
  }) async {
    final driver = SelbrumeEvaluationDriver.attach(
      game: game,
      project: project,
      projectRoot: projectRoot,
      services: services,
      playbackRate: config.playbackRate,
    );
    final bridge = InteractiveEvaluationBridge(
      config: config,
      driver: driver,
      eventSink: eventSink,
    );
    try {
      await driver.waitUntilRuntimeReady();
      await bridge.connect();
      return bridge;
    } catch (_) {
      await bridge.dispose();
      rethrow;
    }
  }

  Future<void> connect({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_disposed) {
      throw StateError('The interactive evaluation bridge is disposed.');
    }
    if (_socket != null) {
      throw StateError('The interactive evaluation bridge is already open.');
    }
    if (!config.enabled) {
      throw StateError('Interactive evaluation is disabled.');
    }

    final socket = await Socket.connect(config.host!, config.port!);
    _socket = socket;
    final handshake = Completer<void>();
    _handshake = handshake;
    _subscription = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _onLine,
          onError: _onSocketError,
          onDone: _onSocketDone,
          cancelOnError: true,
        );
    _send(<String, Object?>{
      'type': 'bridge.hello',
      'token': config.token,
      'target': 'interactive',
      'protocolVersion': interactiveEvaluationProtocolVersion,
    });

    try {
      await handshake.future.timeout(timeout);
    } on TimeoutException {
      throw const InteractiveEvaluationConnectionException(
        'Timed out while authenticating the interactive runtime.',
      );
    }
  }

  void _onLine(String line) {
    if (_disposed) return;
    if (line.length > _maximumEnvelopeLength) {
      _rejectEnvelope(
        'envelope_too_large',
        'Interactive envelope exceeds the one-megabyte limit.',
      );
      return;
    }

    final Map<String, Object?> envelope;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        throw const FormatException('Envelope must be a JSON object.');
      }
      envelope = Map<String, Object?>.from(decoded);
    } on Object catch (failure) {
      _rejectEnvelope('invalid_json', 'Invalid JSONL envelope: $failure');
      return;
    }

    if (!_authenticated) {
      _handleHandshake(envelope);
      return;
    }
    _commandQueue = _commandQueue.then(
      (_) => _handleAuthenticatedEnvelope(envelope),
    );
  }

  void _handleHandshake(Map<String, Object?> envelope) {
    switch (envelope['type']) {
      case 'bridge.accepted':
        if (envelope.keys.toSet().difference(
              const <String>{'type', 'protocolVersion'},
            ).isNotEmpty ||
            envelope['protocolVersion'] !=
                interactiveEvaluationProtocolVersion) {
          _completeHandshakeError(
            const InteractiveEvaluationAuthenticationException(
              'The orchestrator accepted an unsupported bridge protocol.',
            ),
          );
          return;
        }
        _authenticated = true;
        _send(<String, Object?>{
          'type': 'bridge.ready',
          'target': 'interactive',
          'protocolVersion': interactiveEvaluationProtocolVersion,
          'projectId': driver.snapshot().projectId,
        });
        _handshake?.complete();
        return;
      case 'bridge.rejected':
        final reason = envelope['reason'];
        _completeHandshakeError(
          InteractiveEvaluationAuthenticationException(
            reason is String && reason.trim().isNotEmpty
                ? reason
                : 'The orchestrator rejected interactive authentication.',
          ),
        );
        return;
      default:
        _completeHandshakeError(
          const InteractiveEvaluationAuthenticationException(
            'Expected bridge.accepted before any runtime command.',
          ),
        );
        return;
    }
  }

  Future<void> _handleAuthenticatedEnvelope(
    Map<String, Object?> envelope,
  ) async {
    if (envelope['type'] != 'run') {
      _rejectEnvelope(
        'unsupported_envelope',
        'Only typed run envelopes are accepted by the runtime bridge.',
      );
      return;
    }
    const expectedKeys = <String>{
      'type',
      'requestId',
      'runId',
      'scenario',
    };
    if (envelope.keys.toSet().difference(expectedKeys).isNotEmpty ||
        expectedKeys.difference(envelope.keys.toSet()).isNotEmpty) {
      _rejectEnvelope(
        'invalid_envelope',
        'Run envelope fields do not match protocol V1.',
      );
      return;
    }

    final requestId = _nonBlankString(envelope['requestId']);
    final runId = _nonBlankString(envelope['runId']);
    final scenarioSource = _nonBlankString(envelope['scenario']);
    if (requestId == null || runId == null || scenarioSource == null) {
      _rejectEnvelope(
        'invalid_envelope',
        'requestId, runId, and scenario must be non-blank strings.',
      );
      return;
    }

    try {
      final scenario =
          const EvaluationScenarioParser().parseString(scenarioSource);
      if (scenario.projectId != driver.snapshot().projectId) {
        throw const EvaluationScenarioFormatException(
          r'$.projectId',
          'Scenario project does not match the visible runtime project.',
        );
      }
      try {
        const EvaluationPolicyValidator().validate(scenario);
      } on EvaluationPolicyViolation catch (failure) {
        _sendResult(
          requestId: requestId,
          runId: runId,
          status: EvaluationRunStatus.policyViolation,
          exitCode: 4,
          error: <String, Object?>{
            'kind': 'policyViolation',
            'stepId': failure.stepId,
            'operation': failure.operation,
            'message': failure.reason,
          },
        );
        return;
      }

      final result = await EvaluationScenarioRunner(
        driver: driver,
        runIdFactory: () => runId,
        eventSink: (event) {
          eventSink?.call(event);
          _send(<String, Object?>{
            'type': 'bridge.event',
            'requestId': requestId,
            'runId': runId,
            'event': event.toJson(),
          });
        },
      ).run(scenario);
      _sendResult(
        requestId: requestId,
        runId: runId,
        status: result.status,
        exitCode: _exitCodeFor(result.status),
        finalState: result.finalState.toJson(),
        error: result.error,
      );
    } on EvaluationScenarioFormatException catch (failure) {
      _sendResult(
        requestId: requestId,
        runId: runId,
        status: EvaluationRunStatus.invalidScenario,
        exitCode: 2,
        error: <String, Object?>{
          'kind': 'invalidScenario',
          'message': failure.toString(),
        },
      );
    } on Object catch (failure) {
      _sendResult(
        requestId: requestId,
        runId: runId,
        status: EvaluationRunStatus.infrastructureFailure,
        exitCode: 3,
        error: <String, Object?>{
          'kind': 'infrastructureFailure',
          'message': failure.toString(),
        },
      );
    }
  }

  void _sendResult({
    required String requestId,
    required String runId,
    required EvaluationRunStatus status,
    required int exitCode,
    Map<String, Object?>? finalState,
    Map<String, Object?>? error,
  }) {
    _send(<String, Object?>{
      'type': 'bridge.result',
      'requestId': requestId,
      'runId': runId,
      'status': status.name,
      'exitCode': exitCode,
      if (finalState != null) 'finalState': finalState,
      if (error != null) 'error': error,
    });
  }

  void _rejectEnvelope(String code, String message) {
    if (_authenticated) {
      _send(<String, Object?>{
        'type': 'bridge.error',
        'code': code,
        'message': message,
      });
      return;
    }
    _completeHandshakeError(
      InteractiveEvaluationAuthenticationException(message),
    );
  }

  void _send(Map<String, Object?> envelope) {
    if (_disposed) return;
    _socket?.writeln(jsonEncode(envelope));
  }

  void _onSocketError(Object error, StackTrace stackTrace) {
    _completeHandshakeError(
      InteractiveEvaluationConnectionException(
        'Interactive bridge socket failed: $error',
      ),
    );
  }

  void _onSocketDone() {
    _completeHandshakeError(
      const InteractiveEvaluationConnectionException(
        'Interactive bridge socket closed before authentication.',
      ),
    );
  }

  void _completeHandshakeError(Object error) {
    final handshake = _handshake;
    if (handshake != null && !handshake.isCompleted) {
      handshake.completeError(error);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _completeHandshakeError(
      const InteractiveEvaluationConnectionException(
        'Interactive bridge disposed before authentication.',
      ),
    );
    await _subscription?.cancel();
    try {
      await _socket?.close();
    } on StateError {
      // Closing an already-destroyed socket is harmless during replacement.
    }
    await driver.dispose();
  }
}

final class InteractiveEvaluationAuthenticationException implements Exception {
  const InteractiveEvaluationAuthenticationException(this.message);

  final String message;

  @override
  String toString() => 'InteractiveEvaluationAuthenticationException: $message';
}

final class InteractiveEvaluationConnectionException implements Exception {
  const InteractiveEvaluationConnectionException(this.message);

  final String message;

  @override
  String toString() => 'InteractiveEvaluationConnectionException: $message';
}

String? _nonBlankString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

int _exitCodeFor(EvaluationRunStatus status) => switch (status) {
      EvaluationRunStatus.succeeded => 0,
      EvaluationRunStatus.failed => 1,
      EvaluationRunStatus.invalidScenario => 2,
      EvaluationRunStatus.infrastructureFailure => 3,
      EvaluationRunStatus.policyViolation => 4,
      EvaluationRunStatus.cancelled => 130,
    };
