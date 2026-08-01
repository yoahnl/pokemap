import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_event.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/interactive/interactive_worker_client.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';

const _token = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('client launches debug macOS with isolated dart defines', () async {
    final root = await Directory.systemTemp.createTemp('interactive-launch-');
    addTearDown(() => root.delete(recursive: true));
    final process = _RecordingProcessRunner();
    final client = InteractiveWorkerClient(
      repositoryRoot: root,
      packageRoot: Directory(p.join(root.path, 'host')),
      processRunner: process,
      tokenGenerator: () => _token,
    );

    final launch = await client.launch(
      projectFile: 'selbrume/project.json',
      playbackRate: 2,
    );
    addTearDown(launch.close);

    expect(process.executable, 'flutter');
    expect(
      process.arguments,
      containsAll(<String>[
        'run',
        '-d',
        'macos',
        '--debug',
        '--dart-define=POKEMAP_EVAL_INTERACTIVE=true',
        '--dart-define=POKEMAP_EVAL_HOST=127.0.0.1',
        '--dart-define=POKEMAP_EVAL_TOKEN=$_token',
        '--dart-define=POKEMAP_EVAL_PROJECT=selbrume/project.json',
        '--dart-define=POKEMAP_EVAL_PLAYBACK_RATE=2.0',
      ]),
    );
    expect(
      process.arguments.any((argument) => argument.contains('COLLISION')),
      isFalse,
    );
    expect(process.runInShell, isFalse);
    expect(process.workingDirectory, p.join(root.path, 'host'));
  });

  test('client forwards profile mode to the Flutter process', () async {
    final root = await Directory.systemTemp.createTemp('interactive-profile-');
    addTearDown(() => root.delete(recursive: true));
    final process = _RecordingProcessRunner();
    final client = InteractiveWorkerClient(
      repositoryRoot: root,
      packageRoot: Directory(p.join(root.path, 'host')),
      processRunner: process,
      tokenGenerator: () => _token,
    );

    final launch = await client.launch(
      projectFile: 'selbrume/project.json',
      buildMode: EvaluationBuildMode.profile,
    );
    addTearDown(launch.close);

    expect(process.arguments, contains('--profile'));
    expect(process.arguments, isNot(contains('--debug')));
  });

  test('client times out and terminates only its child process', () async {
    final root = await Directory.systemTemp.createTemp('interactive-timeout-');
    addTearDown(() => root.delete(recursive: true));
    final scenario = File(p.join(root.path, 'scenario.json'));
    await scenario.writeAsString('{}');
    final process = _RecordingProcessRunner();
    final client = InteractiveWorkerClient(
      repositoryRoot: root,
      packageRoot: Directory(p.join(root.path, 'host')),
      processRunner: process,
      tokenGenerator: () => _token,
      readyTimeout: const Duration(milliseconds: 20),
    );

    final result = await client.run(
      EvaluationWorkerRequest.run(
        runId: 'interactive-timeout',
        projectRoot: 'selbrume',
        scenarioPath: 'scenario.json',
        outputDirectory: 'build/run',
      ),
    );

    expect(result.status, EvaluationRunStatus.infrastructureFailure);
    expect(result.exitCode, 3);
    expect(result.message, contains('Timed out'));
    expect(process.child.killCalls, 1);
  });

  test('client authenticates a runtime and returns its typed result', () async {
    final root = await Directory.systemTemp.createTemp('interactive-run-');
    addTearDown(() => root.delete(recursive: true));
    final scenario = File(p.join(root.path, 'scenario.json'));
    await scenario.writeAsString('{"schemaVersion":1}');
    final process = _BridgeProcessRunner();
    final client = InteractiveWorkerClient(
      repositoryRoot: root,
      packageRoot: Directory(p.join(root.path, 'host')),
      processRunner: process,
      tokenGenerator: () => _token,
      readyTimeout: const Duration(seconds: 1),
    );

    final events = <EvaluationEvent>[];
    final result = await client.run(
      EvaluationWorkerRequest.run(
        runId: 'interactive-success',
        projectRoot: 'selbrume',
        scenarioPath: 'scenario.json',
        outputDirectory: 'build/run',
      ),
      eventSink: events.add,
    );

    expect(result.status, EvaluationRunStatus.succeeded);
    expect(result.exitCode, 0);
    expect(events.single.type, 'run.started');
    expect(process.child.killCalls, 1);
  });
}

final class _RecordingProcessRunner implements InteractiveProcessRunner {
  String? executable;
  List<String> arguments = const <String>[];
  String? workingDirectory;
  bool? runInShell;
  final _RecordingChildProcess child = _RecordingChildProcess();

  @override
  Future<InteractiveChildProcess> start(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required bool runInShell,
  }) async {
    this.executable = executable;
    this.arguments = List<String>.of(arguments);
    this.workingDirectory = workingDirectory;
    this.runInShell = runInShell;
    return child;
  }
}

final class _RecordingChildProcess implements InteractiveChildProcess {
  final Completer<int> _exitCode = Completer<int>();
  var killCalls = 0;

  @override
  int get pid => 42;

  @override
  Stream<List<int>> get stdout => const Stream<List<int>>.empty();

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    killCalls += 1;
    if (!_exitCode.isCompleted) _exitCode.complete(0);
    return true;
  }
}

final class _BridgeProcessRunner implements InteractiveProcessRunner {
  final _RecordingChildProcess child = _RecordingChildProcess();

  @override
  Future<InteractiveChildProcess> start(
    String executable,
    List<String> arguments, {
    required String workingDirectory,
    required bool runInShell,
  }) async {
    final port = int.parse(_define(arguments, 'POKEMAP_EVAL_PORT'));
    final token = _define(arguments, 'POKEMAP_EVAL_TOKEN');
    unawaited(_serve(port: port, token: token));
    return child;
  }

  Future<void> _serve({
    required int port,
    required String token,
  }) async {
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    final lines = StreamIterator<String>(
      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter()),
    );
    socket.writeln(jsonEncode(<String, Object?>{
      'type': 'bridge.hello',
      'token': token,
      'target': 'interactive',
      'protocolVersion': 1,
    }));
    await _nextJson(lines);
    socket.writeln(jsonEncode(const <String, Object?>{
      'type': 'bridge.ready',
      'target': 'interactive',
      'protocolVersion': 1,
      'projectId': 'selbrume',
    }));
    final request = await _nextJson(lines);
    socket.writeln(jsonEncode(<String, Object?>{
      'type': 'bridge.event',
      'requestId': request['requestId'],
      'runId': request['runId'],
      'event': <String, Object?>{
        'schemaVersion': 1,
        'runId': request['runId'],
        'sequence': 1,
        'type': 'run.started',
        'payload': const <String, Object?>{},
      },
    }));
    socket.writeln(jsonEncode(<String, Object?>{
      'type': 'bridge.result',
      'requestId': request['requestId'],
      'runId': request['runId'],
      'status': 'succeeded',
      'exitCode': 0,
    }));
    await lines.cancel();
    await socket.close();
  }
}

String _define(List<String> arguments, String name) {
  final prefix = '--dart-define=$name=';
  return arguments
      .singleWhere((argument) => argument.startsWith(prefix))
      .substring(
        prefix.length,
      );
}

Future<Map<String, Object?>> _nextJson(StreamIterator<String> lines) async {
  if (!await lines.moveNext()) throw StateError('Socket closed.');
  return Map<String, Object?>.from(jsonDecode(lines.current) as Map);
}
