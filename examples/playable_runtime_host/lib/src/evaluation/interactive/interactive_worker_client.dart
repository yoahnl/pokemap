import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../contracts/evaluation_event.dart';
import '../contracts/evaluation_receipt.dart';
import '../worker/evaluation_worker_protocol.dart';

const _interactiveProtocolVersion = 1;

abstract interface class InteractiveProcessRunner {
  Future<InteractiveChildProcess> start(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required bool runInShell,
  });
}

abstract interface class InteractiveChildProcess {
  int get pid;
  Stream<List<int>> get stdout;
  Stream<List<int>> get stderr;
  Future<int> get exitCode;

  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);
}

final class IoInteractiveProcessRunner implements InteractiveProcessRunner {
  const IoInteractiveProcessRunner();

  @override
  Future<InteractiveChildProcess> start(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required bool runInShell,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: runInShell,
    );
    return _IoInteractiveChildProcess(process);
  }
}

final class InteractiveWorkerClient {
  InteractiveWorkerClient({
    required Directory repositoryRoot,
    Directory? packageRoot,
    InteractiveProcessRunner processRunner = const IoInteractiveProcessRunner(),
    String Function()? tokenGenerator,
    this.readyTimeout = const Duration(seconds: 60),
    void Function(String chunk)? stderrSink,
    this.flutterExecutable = 'flutter',
  })  : repositoryRoot = repositoryRoot.absolute,
        packageRoot = (packageRoot ??
                Directory(
                  p.join(
                    repositoryRoot.path,
                    'examples',
                    'playable_runtime_host',
                  ),
                ))
            .absolute,
        _processRunner = processRunner,
        _tokenGenerator = tokenGenerator ?? _secureToken,
        _stderrSink = stderrSink ?? stderr.write;

  final Directory repositoryRoot;
  final Directory packageRoot;
  final InteractiveProcessRunner _processRunner;
  final String Function() _tokenGenerator;
  final Duration readyTimeout;
  final void Function(String chunk) _stderrSink;
  final String flutterExecutable;

  Future<InteractiveWorkerLaunch> launch({
    required String projectFile,
    double playbackRate = 1,
  }) async {
    _validatePortablePath(projectFile, 'projectFile');
    if (!playbackRate.isFinite || playbackRate <= 0 || playbackRate > 4) {
      throw ArgumentError.value(
        playbackRate,
        'playbackRate',
        'Playback rate must be greater than 0 and at most 4.',
      );
    }
    final token = _tokenGenerator();
    if (token.length < 32 ||
        token.length > 512 ||
        token.codeUnits.any(_isWhitespace)) {
      throw StateError(
        'Interactive token generator returned an invalid token.',
      );
    }

    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    InteractiveChildProcess? child;
    try {
      child = await _processRunner.start(
        flutterExecutable,
        <String>[
          'run',
          '-d',
          'macos',
          '--debug',
          '--dart-define=POKEMAP_EVAL_INTERACTIVE=true',
          '--dart-define=POKEMAP_EVAL_HOST=127.0.0.1',
          '--dart-define=POKEMAP_EVAL_PORT=${listener.port}',
          '--dart-define=POKEMAP_EVAL_TOKEN=$token',
          '--dart-define=POKEMAP_EVAL_PROJECT=$projectFile',
          '--dart-define=POKEMAP_EVAL_PLAYBACK_RATE=$playbackRate',
        ],
        workingDirectory: packageRoot.path,
        runInShell: false,
      );
      return InteractiveWorkerLaunch._(
        listener: listener,
        child: child,
        token: token,
        readyTimeout: readyTimeout,
        stderrSink: _stderrSink,
      );
    } catch (_) {
      await listener.close();
      child?.kill();
      rethrow;
    }
  }

  Future<EvaluationWorkerResult> run(
    EvaluationWorkerRequest request, {
    double playbackRate = 1,
    void Function(EvaluationEvent event)? eventSink,
  }) async {
    InteractiveWorkerLaunch? session;
    try {
      final scenarioFile = File(
        p.join(repositoryRoot.path, request.scenarioPath),
      );
      final scenarioSource = await scenarioFile.readAsString();
      session = await launch(
        projectFile: '${request.projectRoot}/project.json',
        playbackRate: playbackRate,
      );
      return await session.run(
        request: request,
        scenarioSource: scenarioSource,
        eventSink: eventSink,
      );
    } on TimeoutException catch (failure) {
      return EvaluationWorkerResult.infrastructureFailure(
        runId: request.runId,
        message: 'Timed out waiting for the interactive runtime: '
            '${failure.message ?? 'no bridge.ready envelope'}',
      );
    } on Object catch (failure) {
      return EvaluationWorkerResult.infrastructureFailure(
        runId: request.runId,
        message: 'Interactive runtime failed: $failure',
      );
    } finally {
      await session?.close();
    }
  }
}

final class InteractiveWorkerLaunch {
  InteractiveWorkerLaunch._({
    required ServerSocket listener,
    required InteractiveChildProcess child,
    required String token,
    required Duration readyTimeout,
    required void Function(String chunk) stderrSink,
  })  : _listener = listener,
        _child = child,
        _token = token,
        _readyTimeout = readyTimeout {
    _stdoutSubscription = child.stdout.listen((_) {});
    _stderrSubscription =
        child.stderr.transform(utf8.decoder).listen(stderrSink);
  }

  final ServerSocket _listener;
  final InteractiveChildProcess _child;
  final String _token;
  final Duration _readyTimeout;
  late final StreamSubscription<List<int>> _stdoutSubscription;
  late final StreamSubscription<String> _stderrSubscription;
  Socket? _socket;
  StreamIterator<String>? _lines;
  bool _closed = false;

  Future<EvaluationWorkerResult> run({
    required EvaluationWorkerRequest request,
    required String scenarioSource,
    void Function(EvaluationEvent event)? eventSink,
  }) async {
    final socket = await _listener.first.timeout(_readyTimeout);
    _socket = socket;
    if (!socket.remoteAddress.isLoopback) {
      socket.writeln(jsonEncode(const <String, Object?>{
        'type': 'bridge.rejected',
        'reason': 'interactive bridge must originate from loopback',
      }));
      throw const InteractiveWorkerAuthenticationException(
        'Interactive bridge did not originate from loopback.',
      );
    }

    final lines = StreamIterator<String>(
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter()),
    );
    _lines = lines;
    final hello = await _nextEnvelope(lines).timeout(_readyTimeout);
    if (!_validHello(hello)) {
      socket.writeln(jsonEncode(const <String, Object?>{
        'type': 'bridge.rejected',
        'reason': 'invalid interactive authentication',
      }));
      throw const InteractiveWorkerAuthenticationException(
        'Interactive bridge authentication failed.',
      );
    }

    socket.writeln(jsonEncode(const <String, Object?>{
      'type': 'bridge.accepted',
      'protocolVersion': _interactiveProtocolVersion,
    }));
    final ready = await _nextEnvelope(lines).timeout(_readyTimeout);
    _validateReady(ready, expectedProjectId: request.projectRoot);

    socket.writeln(
      jsonEncode(<String, Object?>{
        'type': 'run',
        'requestId': request.runId,
        'runId': request.runId,
        'scenario': scenarioSource,
      }),
    );

    Map<String, Object?>? lastEvent;
    while (true) {
      final Map<String, Object?> envelope;
      try {
        envelope = await _nextEnvelope(lines).timeout(_readyTimeout);
      } on TimeoutException {
        throw TimeoutException(
          'No interactive envelope arrived within '
          '${_readyTimeout.inSeconds}s; lastEvent=${jsonEncode(lastEvent)}',
        );
      }
      switch (envelope['type']) {
        case 'bridge.event':
          final event = envelope['event'];
          lastEvent = event is Map
              ? Map<String, Object?>.from(event)
              : <String, Object?>{'invalidEvent': event};
          eventSink?.call(_evaluationEventFromJson(lastEvent));
          continue;
        case 'bridge.error':
          throw FormatException(
            'Interactive bridge rejected an envelope: '
            '${envelope['message'] ?? envelope['code']}',
          );
        case 'bridge.result':
          return _resultFromEnvelope(envelope, request);
        default:
          throw FormatException(
            'Unsupported interactive bridge response "${envelope['type']}".',
          );
      }
    }
  }

  bool _validHello(Map<String, Object?> envelope) {
    const expectedKeys = <String>{
      'type',
      'token',
      'target',
      'protocolVersion',
    };
    return envelope.keys.toSet().difference(expectedKeys).isEmpty &&
        expectedKeys.difference(envelope.keys.toSet()).isEmpty &&
        envelope['type'] == 'bridge.hello' &&
        envelope['target'] == 'interactive' &&
        envelope['protocolVersion'] == _interactiveProtocolVersion &&
        envelope['token'] is String &&
        _constantTimeEquals(envelope['token']! as String, _token);
  }

  void _validateReady(
    Map<String, Object?> envelope, {
    required String expectedProjectId,
  }) {
    const expectedKeys = <String>{
      'type',
      'target',
      'protocolVersion',
      'projectId',
    };
    if (envelope.keys.toSet().difference(expectedKeys).isNotEmpty ||
        expectedKeys.difference(envelope.keys.toSet()).isNotEmpty ||
        envelope['type'] != 'bridge.ready' ||
        envelope['target'] != 'interactive' ||
        envelope['protocolVersion'] != _interactiveProtocolVersion ||
        envelope['projectId'] != expectedProjectId) {
      throw const FormatException('Invalid bridge.ready envelope.');
    }
  }

  EvaluationWorkerResult _resultFromEnvelope(
    Map<String, Object?> envelope,
    EvaluationWorkerRequest request,
  ) {
    if (envelope['requestId'] != request.runId ||
        envelope['runId'] != request.runId) {
      throw const FormatException(
        'Interactive result does not match its request.',
      );
    }
    final status = switch (envelope['status']) {
      'succeeded' => EvaluationRunStatus.succeeded,
      'failed' => EvaluationRunStatus.failed,
      'invalidScenario' => EvaluationRunStatus.invalidScenario,
      'infrastructureFailure' => EvaluationRunStatus.infrastructureFailure,
      'policyViolation' => EvaluationRunStatus.policyViolation,
      'cancelled' => EvaluationRunStatus.cancelled,
      _ => throw const FormatException('Unknown interactive result status.'),
    };
    final exitCode = envelope['exitCode'];
    if (exitCode is! int) {
      throw const FormatException(
        'Interactive result exitCode must be an integer.',
      );
    }
    final error = envelope['error'];
    return EvaluationWorkerResult.completed(
      runId: request.runId,
      status: status,
      exitCode: exitCode,
      message: error == null ? null : jsonEncode(error),
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _lines?.cancel();
    try {
      await _socket?.close();
    } on StateError {
      // The runtime may close first after receiving its result.
    }
    await _listener.close();
    await _stdoutSubscription.cancel();
    await _stderrSubscription.cancel();
    _child.kill();
    try {
      await _child.exitCode.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      _child.kill(ProcessSignal.sigkill);
    }
  }
}

EvaluationEvent _evaluationEventFromJson(Map<String, Object?> json) {
  const expectedKeys = <String>{
    'schemaVersion',
    'runId',
    'sequence',
    'type',
    'payload',
  };
  if (json.keys.toSet().difference(expectedKeys).isNotEmpty ||
      expectedKeys.difference(json.keys.toSet()).isNotEmpty ||
      json['schemaVersion'] != EvaluationEvent.schemaVersion ||
      json['runId'] is! String ||
      json['sequence'] is! int ||
      json['type'] is! String ||
      json['payload'] is! Map) {
    throw const FormatException('Invalid interactive evaluation event.');
  }
  return EvaluationEvent(
    runId: json['runId']! as String,
    sequence: json['sequence']! as int,
    type: json['type']! as String,
    payload: Map<String, Object?>.from(json['payload']! as Map),
  );
}

final class InteractiveWorkerAuthenticationException implements Exception {
  const InteractiveWorkerAuthenticationException(this.message);

  final String message;

  @override
  String toString() => 'InteractiveWorkerAuthenticationException: $message';
}

final class _IoInteractiveChildProcess implements InteractiveChildProcess {
  const _IoInteractiveChildProcess(this.process);

  final Process process;

  @override
  int get pid => process.pid;

  @override
  Stream<List<int>> get stdout => process.stdout;

  @override
  Stream<List<int>> get stderr => process.stderr;

  @override
  Future<int> get exitCode => process.exitCode;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) =>
      process.kill(signal);
}

Future<Map<String, Object?>> _nextEnvelope(
  StreamIterator<String> lines,
) async {
  if (!await lines.moveNext()) {
    throw const FormatException(
      'Interactive runtime closed before sending an envelope.',
    );
  }
  if (lines.current.length > 1024 * 1024) {
    throw const FormatException(
      'Interactive runtime envelope exceeds one megabyte.',
    );
  }
  final decoded = jsonDecode(lines.current);
  if (decoded is! Map) {
    throw const FormatException(
      'Interactive runtime envelope must be a JSON object.',
    );
  }
  return Map<String, Object?>.from(decoded);
}

void _validatePortablePath(String value, String name) {
  final normalized = value.replaceAll(r'\', '/');
  if (normalized.trim().isEmpty ||
      normalized.startsWith('/') ||
      normalized.split('/').any(
            (segment) => segment.isEmpty || segment == '.' || segment == '..',
          )) {
    throw ArgumentError.value(
      value,
      name,
      'Expected a portable repository-relative path.',
    );
  }
}

bool _constantTimeEquals(String left, String right) {
  var difference = left.length ^ right.length;
  final length = max(left.length, right.length);
  for (var index = 0; index < length; index++) {
    final leftCode = index < left.length ? left.codeUnitAt(index) : 0;
    final rightCode = index < right.length ? right.codeUnitAt(index) : 0;
    difference |= leftCode ^ rightCode;
  }
  return difference == 0;
}

String _secureToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

bool _isWhitespace(int codeUnit) =>
    codeUnit == 0x20 ||
    codeUnit == 0x09 ||
    codeUnit == 0x0a ||
    codeUnit == 0x0d;
