import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../contracts/evaluation_event.dart';
import '../runner/evaluation_run_control.dart';
import '../worker/evaluation_worker_protocol.dart';
import '../worker/headless_worker_process.dart';

const pokeMapEvalWorkerModeEnvironmentKey = 'POKEMAP_EVAL_WORKER_MODE';
const pokeMapEvalWorkerModeServe = 'serve';
const pokeMapEvalWorkerControlHostEnvironmentKey =
    'POKEMAP_EVAL_WORKER_CONTROL_HOST';
const pokeMapEvalWorkerControlPortEnvironmentKey =
    'POKEMAP_EVAL_WORKER_CONTROL_PORT';
const pokeMapEvalWorkerControlTokenEnvironmentKey =
    'POKEMAP_EVAL_WORKER_CONTROL_TOKEN';

typedef EvaluationWorkerEventSink = void Function(EvaluationEvent event);
typedef EvaluationWorkerRequestExecutor = Future<EvaluationWorkerResult>
    Function(
  EvaluationWorkerRequest request,
  EvaluationRunControl runControl,
  EvaluationWorkerEventSink eventSink,
);

enum EvaluationWorkerControlAction {
  step,
  pause,
  resume,
  cancel,
}

abstract interface class EvaluationWorkerFactory {
  Future<EvaluationWorkerHandle> create(String projectId);
}

abstract interface class EvaluationWorkerHandle {
  bool get healthy;

  Future<EvaluationWorkerResult> run(
    EvaluationWorkerRequest request, {
    EvaluationWorkerEventSink? eventSink,
  });

  Future<void> control(
    String runId,
    EvaluationWorkerControlAction action,
  );

  Future<void> close();
}

final class PersistentEvaluationWorkerFactory
    implements EvaluationWorkerFactory {
  PersistentEvaluationWorkerFactory({
    this.flutterExecutable = 'flutter',
    Directory? hostRoot,
    Directory? packageRoot,
    void Function(String chunk)? stderrSink,
  })  : hostRoot = (hostRoot ?? _discoverHostRoot()).absolute,
        packageRoot = (packageRoot ??
                Directory(
                  p.join(
                    (hostRoot ?? _discoverHostRoot()).path,
                    'examples',
                    'playable_runtime_host',
                  ),
                ))
            .absolute,
        stderrSink = stderrSink ?? stderr.write;

  final String flutterExecutable;
  final Directory hostRoot;
  final Directory packageRoot;
  final void Function(String chunk) stderrSink;

  @override
  Future<EvaluationWorkerHandle> create(String projectId) async {
    final server = await ServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
      shared: false,
    );
    final token = _createWorkerToken();
    Process? process;
    Socket? socket;
    try {
      process = await Process.start(
        flutterExecutable,
        const <String>[
          'test',
          '--reporter',
          'compact',
          'test/evaluation/pokemap_eval_headless_worker_test.dart',
          '--plain-name',
          'PokeMap Eval persistent headless worker',
        ],
        workingDirectory: packageRoot.path,
        environment: <String, String>{
          ...Platform.environment,
          pokeMapEvalWorkerModeEnvironmentKey: pokeMapEvalWorkerModeServe,
          pokeMapEvalWorkerControlHostEnvironmentKey: server.address.address,
          pokeMapEvalWorkerControlPortEnvironmentKey: '${server.port}',
          pokeMapEvalWorkerControlTokenEnvironmentKey: token,
          pokeMapEvalHostRootEnvironmentKey: hostRoot.path,
        },
        runInShell: false,
      );
      socket = await server.first.timeout(const Duration(seconds: 30));
      final handle = _PersistentEvaluationWorkerHandle(
        projectId: projectId,
        token: token,
        process: process,
        socket: socket,
        stderrSink: stderrSink,
      );
      await handle.ready.timeout(const Duration(seconds: 30));
      return handle;
    } on Object {
      socket?.destroy();
      process?.kill();
      rethrow;
    } finally {
      await server.close();
    }
  }
}

final class EvaluationWorkerPool {
  EvaluationWorkerPool({required this.factory});

  final EvaluationWorkerFactory factory;
  final Map<String, EvaluationWorkerHandle> _workers =
      <String, EvaluationWorkerHandle>{};
  final Map<String, Future<void>> _tails = <String, Future<void>>{};
  bool _closed = false;

  Future<EvaluationWorkerResult> run({
    required String projectId,
    required EvaluationWorkerRequest request,
    EvaluationWorkerEventSink? eventSink,
    bool releaseEvidenceCandidate = false,
  }) {
    _ensureOpen();
    return _serialize(projectId, () async {
      if (releaseEvidenceCandidate) {
        final worker = await factory.create(projectId);
        try {
          return await worker.run(request, eventSink: eventSink);
        } finally {
          await worker.close();
        }
      }
      final worker = await _healthyWorkerFor(projectId);
      return worker.run(request, eventSink: eventSink);
    });
  }

  Future<void> control({
    required String projectId,
    required String runId,
    required EvaluationWorkerControlAction action,
  }) async {
    _ensureOpen();
    final worker = _workers[projectId];
    if (worker == null || !worker.healthy) {
      throw StateError('No healthy worker is running for $projectId.');
    }
    await worker.control(runId, action);
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await Future.wait<void>(_tails.values);
    final workers = _workers.values.toList(growable: false);
    _workers.clear();
    await Future.wait<void>(workers.map((worker) => worker.close()));
  }

  Future<EvaluationWorkerHandle> _healthyWorkerFor(String projectId) async {
    final existing = _workers[projectId];
    if (existing != null && existing.healthy) return existing;
    if (existing != null) await existing.close();
    final worker = await factory.create(projectId);
    if (!worker.healthy) {
      await worker.close();
      throw StateError('Worker factory returned an unhealthy worker.');
    }
    _workers[projectId] = worker;
    return worker;
  }

  Future<T> _serialize<T>(
    String projectId,
    Future<T> Function() operation,
  ) {
    final result = Completer<T>();
    final previous = _tails[projectId] ?? Future<void>.value();
    late Future<void> next;
    next = previous.catchError((Object _) {}).then((_) async {
      try {
        result.complete(await operation());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    }).whenComplete(() {
      if (identical(_tails[projectId], next)) {
        _tails.remove(projectId);
      }
    });
    _tails[projectId] = next;
    return result.future;
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Evaluation worker pool is closed.');
  }
}

final class _PersistentEvaluationWorkerHandle
    implements EvaluationWorkerHandle {
  _PersistentEvaluationWorkerHandle({
    required this.projectId,
    required this.token,
    required this.process,
    required this.socket,
    required void Function(String chunk) stderrSink,
  }) {
    _stdoutDone = process.stdout.drain<void>();
    _stderrDone = process.stderr.transform(utf8.decoder).forEach(stderrSink);
    _subscription =
        utf8.decoder.bind(socket).transform(const LineSplitter()).listen(
              _handleEnvelope,
              onError: _handleConnectionFailure,
              onDone: _handleConnectionClosed,
              cancelOnError: true,
            );
    unawaited(
      process.exitCode.then((exitCode) {
        if (!_closing && _healthy) {
          _failPending(
            StateError(
              'Persistent evaluation worker exited with code $exitCode.',
            ),
          );
        }
        _healthy = false;
      }),
    );
  }

  final String projectId;
  final String token;
  final Process process;
  final Socket socket;
  final Completer<void> _ready = Completer<void>();
  final Map<String, Completer<void>> _controlReplies =
      <String, Completer<void>>{};
  late final StreamSubscription<String> _subscription;
  late final Future<void> _stdoutDone;
  late final Future<void> _stderrDone;

  Completer<EvaluationWorkerResult>? _result;
  Completer<void>? _shutdownReply;
  EvaluationWorkerEventSink? _eventSink;
  String? _runId;
  var _commandSequence = 0;
  var _healthy = true;
  var _closing = false;

  Future<void> get ready => _ready.future;

  @override
  bool get healthy => _healthy && !_closing;

  @override
  Future<EvaluationWorkerResult> run(
    EvaluationWorkerRequest request, {
    EvaluationWorkerEventSink? eventSink,
  }) async {
    _ensureHealthy();
    if (_runId != null) {
      throw StateError('Worker for $projectId already has an active run.');
    }
    final result = Completer<EvaluationWorkerResult>();
    _runId = request.runId;
    _result = result;
    _eventSink = eventSink;
    _send(<String, Object?>{
      'type': 'run',
      'request': request.toJson(),
    });
    try {
      final completed = await result.future;
      if (completed.runId != request.runId) {
        throw StateError('Persistent worker returned the wrong run id.');
      }
      return completed;
    } finally {
      _runId = null;
      _result = null;
      _eventSink = null;
    }
  }

  @override
  Future<void> control(
    String runId,
    EvaluationWorkerControlAction action,
  ) async {
    _ensureHealthy();
    if (_runId != runId || _result == null) {
      throw StateError('Run $runId is not active on the project worker.');
    }
    final commandId = 'control-${++_commandSequence}';
    final reply = Completer<void>();
    _controlReplies[commandId] = reply;
    _send(<String, Object?>{
      'type': 'control',
      'commandId': commandId,
      'runId': runId,
      'action': action.name,
    });
    try {
      await reply.future;
    } finally {
      _controlReplies.remove(commandId);
    }
  }

  @override
  Future<void> close() async {
    if (_closing) return;
    _closing = true;
    if (_healthy) {
      final reply = Completer<void>();
      _shutdownReply = reply;
      _send(const <String, Object?>{'type': 'shutdown'});
      try {
        await reply.future.timeout(const Duration(seconds: 10));
      } on Object {
        // The process is terminated below if graceful shutdown did not finish.
      }
    }
    _healthy = false;
    await _subscription.cancel();
    await socket.close();
    try {
      await process.exitCode.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      process.kill();
      await process.exitCode;
    }
    await Future.wait<void>(<Future<void>>[_stdoutDone, _stderrDone]);
    _failPending(StateError('Persistent evaluation worker is closed.'));
  }

  void _handleEnvelope(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        throw const FormatException('Worker envelope must be an object.');
      }
      final envelope = Map<String, Object?>.from(decoded);
      switch (envelope['type']) {
        case 'ready':
          if (envelope['token'] != token) {
            throw const FormatException('Worker authentication failed.');
          }
          if (!_ready.isCompleted) _ready.complete();
        case 'event':
          final event = _eventFromJson(
            Map<String, Object?>.from(envelope['event']! as Map),
          );
          if (event.runId != _runId) {
            throw const FormatException('Worker event run id mismatch.');
          }
          _eventSink?.call(event);
        case 'result':
          final result = EvaluationWorkerResult.fromJson(
            Map<String, Object?>.from(envelope['result']! as Map),
          );
          final pending = _result;
          if (pending == null || pending.isCompleted) {
            throw const FormatException('Unexpected worker result.');
          }
          pending.complete(result);
        case 'control.ack':
          final commandId = envelope['commandId'];
          if (commandId is! String) {
            throw const FormatException('Control reply is missing its id.');
          }
          _controlReplies[commandId]?.complete();
        case 'shutdown.ack':
          final pending = _shutdownReply;
          if (pending != null && !pending.isCompleted) pending.complete();
        case 'error':
          _handleRemoteError(envelope);
        default:
          throw const FormatException('Unknown worker envelope.');
      }
    } on Object catch (error, stackTrace) {
      _handleConnectionFailure(error, stackTrace);
    }
  }

  void _handleRemoteError(Map<String, Object?> envelope) {
    final message = envelope['message'];
    final failure = StateError(
      message is String ? message : 'Persistent worker rejected a command.',
    );
    final commandId = envelope['commandId'];
    if (commandId is String) {
      final pending = _controlReplies[commandId];
      if (pending != null && !pending.isCompleted) {
        pending.completeError(failure);
      }
      return;
    }
    final pending = _result;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(failure);
    }
  }

  void _handleConnectionFailure(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    if (!_ready.isCompleted) {
      _ready.completeError(error, stackTrace);
    }
    _healthy = false;
    _failPending(error, stackTrace);
    socket.destroy();
  }

  void _handleConnectionClosed() {
    if (_closing) return;
    _handleConnectionFailure(
      StateError('Persistent evaluation worker disconnected.'),
    );
  }

  void _failPending(Object error, [StackTrace? stackTrace]) {
    final result = _result;
    if (result != null && !result.isCompleted) {
      result.completeError(error, stackTrace);
    }
    for (final reply in _controlReplies.values) {
      if (!reply.isCompleted) reply.completeError(error, stackTrace);
    }
    final shutdown = _shutdownReply;
    if (shutdown != null && !shutdown.isCompleted) {
      shutdown.completeError(error, stackTrace);
    }
  }

  void _ensureHealthy() {
    if (!healthy) {
      throw StateError('Persistent evaluation worker is not healthy.');
    }
  }

  void _send(Map<String, Object?> envelope) {
    socket.writeln(jsonEncode(envelope));
  }
}

Future<void> connectAndServePersistentEvaluationWorker({
  required EvaluationWorkerRequestExecutor execute,
}) async {
  final host = Platform.environment[pokeMapEvalWorkerControlHostEnvironmentKey];
  final portSource =
      Platform.environment[pokeMapEvalWorkerControlPortEnvironmentKey];
  final token =
      Platform.environment[pokeMapEvalWorkerControlTokenEnvironmentKey];
  final port = int.tryParse(portSource ?? '');
  if (host == null ||
      host.trim().isEmpty ||
      port == null ||
      port < 1 ||
      port > 65535 ||
      token == null ||
      token.trim().isEmpty) {
    throw StateError('Persistent worker control socket is not configured.');
  }
  final socket = await Socket.connect(host, port);
  await servePersistentEvaluationWorker(
    socket: socket,
    token: token,
    execute: execute,
  );
}

Future<void> servePersistentEvaluationWorker({
  required Socket socket,
  required String token,
  required EvaluationWorkerRequestExecutor execute,
}) async {
  EvaluationRunControl? control;
  String? activeRunId;
  Future<void>? activeRun;

  void send(Map<String, Object?> envelope) {
    socket.writeln(jsonEncode(envelope));
  }

  send(<String, Object?>{'type': 'ready', 'token': token});
  await socket.flush();
  try {
    await for (final line
        in utf8.decoder.bind(socket).transform(const LineSplitter())) {
      final decoded = jsonDecode(line);
      if (decoded is! Map) {
        send(const <String, Object?>{
          'type': 'error',
          'message': 'Worker envelope must be an object.',
        });
        continue;
      }
      final envelope = Map<String, Object?>.from(decoded);
      switch (envelope['type']) {
        case 'run':
          if (activeRun != null) {
            send(const <String, Object?>{
              'type': 'error',
              'message': 'The persistent worker is already running.',
            });
            continue;
          }
          final request = EvaluationWorkerRequest.fromJson(
            Map<String, Object?>.from(envelope['request']! as Map),
          );
          final currentControl = EvaluationRunControl.running();
          control = currentControl;
          activeRunId = request.runId;
          activeRun = () async {
            try {
              final result = await execute(
                request,
                currentControl,
                (event) => send(<String, Object?>{
                  'type': 'event',
                  'event': event.toJson(),
                }),
              );
              send(<String, Object?>{
                'type': 'result',
                'result': result.toJson(),
              });
            } on Object catch (error) {
              send(<String, Object?>{
                'type': 'error',
                'message': 'Persistent worker run failed: $error',
              });
            } finally {
              await currentControl.close();
              control = null;
              activeRunId = null;
              activeRun = null;
            }
          }();
        case 'control':
          final commandId = envelope['commandId'];
          final runId = envelope['runId'];
          final actionName = envelope['action'];
          final currentControl = control;
          if (commandId is! String ||
              runId is! String ||
              actionName is! String ||
              currentControl == null ||
              runId != activeRunId) {
            send(<String, Object?>{
              'type': 'error',
              'commandId': commandId,
              'message': 'The requested run is not active.',
            });
            continue;
          }
          final action = EvaluationWorkerControlAction.values
              .where((candidate) => candidate.name == actionName)
              .firstOrNull;
          if (action == null) {
            send(<String, Object?>{
              'type': 'error',
              'commandId': commandId,
              'message': 'Unknown worker control action.',
            });
            continue;
          }
          try {
            switch (action) {
              case EvaluationWorkerControlAction.step:
                currentControl.step();
              case EvaluationWorkerControlAction.pause:
                currentControl.pause();
              case EvaluationWorkerControlAction.resume:
                currentControl.resume();
              case EvaluationWorkerControlAction.cancel:
                currentControl.cancel();
            }
            send(<String, Object?>{
              'type': 'control.ack',
              'commandId': commandId,
              'state': currentControl.state.name,
            });
          } on Object catch (error) {
            send(<String, Object?>{
              'type': 'error',
              'commandId': commandId,
              'message': '$error',
            });
          }
        case 'shutdown':
          final currentControl = control;
          if (currentControl != null) currentControl.cancel();
          final currentRun = activeRun;
          if (currentRun != null) await currentRun;
          send(const <String, Object?>{'type': 'shutdown.ack'});
          await socket.flush();
          return;
        default:
          send(const <String, Object?>{
            'type': 'error',
            'message': 'Unknown worker envelope.',
          });
      }
    }
  } finally {
    final currentControl = control;
    if (currentControl != null) currentControl.cancel();
    final currentRun = activeRun;
    if (currentRun != null) await currentRun;
    socket.destroy();
  }
}

EvaluationEvent _eventFromJson(Map<String, Object?> json) {
  if (json['schemaVersion'] != EvaluationEvent.schemaVersion ||
      json['runId'] is! String ||
      json['sequence'] is! int ||
      json['type'] is! String ||
      json['payload'] is! Map) {
    throw const FormatException('Invalid persistent worker event.');
  }
  return EvaluationEvent(
    runId: json['runId']! as String,
    sequence: json['sequence']! as int,
    type: json['type']! as String,
    payload: Map<String, Object?>.from(json['payload']! as Map),
  );
}

String _createWorkerToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

Directory _discoverHostRoot() {
  final current = Directory.current.absolute;
  if (File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
    return current;
  }
  return Directory(p.normalize(p.join(current.path, '..', '..')));
}
