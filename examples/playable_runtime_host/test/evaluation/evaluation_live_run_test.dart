import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_event.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_run_control.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_run_store.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_web_server.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_worker_pool.dart';
import 'package:pokemap_loader/src/evaluation/worker/evaluation_worker_protocol.dart';

void main() {
  group('EvaluationWorkerPool', () {
    test('reuses one healthy worker and serializes project runs', () async {
      final factory = _FakeWorkerFactory();
      final pool = EvaluationWorkerPool(factory: factory);
      addTearDown(pool.close);

      final first = pool.run(
        projectId: 'selbrume',
        request: _request('run-1'),
      );
      final second = pool.run(
        projectId: 'selbrume',
        request: _request('run-2'),
      );
      await Future.wait(<Future<EvaluationWorkerResult>>[first, second]);

      expect(factory.createdWorkers, 1);
      expect(factory.handles.single.maxConcurrentRuns, 1);
      expect(factory.handles.single.runIds, <String>['run-1', 'run-2']);
    });

    test('restarts unhealthy workers and isolates release candidates',
        () async {
      final factory = _FakeWorkerFactory();
      final pool = EvaluationWorkerPool(factory: factory);
      addTearDown(pool.close);

      await pool.run(projectId: 'selbrume', request: _request('run-1'));
      factory.handles.single.healthy = false;
      await pool.run(projectId: 'selbrume', request: _request('run-2'));
      await pool.run(
        projectId: 'selbrume',
        request: _request('run-release'),
        releaseEvidenceCandidate: true,
      );

      expect(factory.createdWorkers, 3);
      expect(factory.handles.last.closeCount, 1);
    });
  });

  test('persistent worker resets between runs and relays controls', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final client = await Socket.connect(server.address, server.port);
    final workerSocket = await server.first;
    await server.close();
    addTearDown(client.destroy);

    var executions = 0;
    final worker = servePersistentEvaluationWorker(
      socket: workerSocket,
      token: 'worker-token',
      execute: (request, control, eventSink) async {
        executions += 1;
        eventSink(_event(request.runId, 1, 'run.started'));
        if (request.runId == 'run-1') {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await control.beforeStep();
        }
        return EvaluationWorkerResult.completed(
          runId: request.runId,
          status: EvaluationRunStatus.succeeded,
          exitCode: 0,
        );
      },
    );
    final envelopes = StreamIterator<String>(
      utf8.decoder.bind(client).transform(const LineSplitter()),
    );

    expect((await _nextEnvelope(envelopes))['type'], 'ready');
    _sendEnvelope(client, <String, Object?>{
      'type': 'run',
      'request': _request('run-1').toJson(),
    });
    expect((await _nextEnvelope(envelopes))['type'], 'event');
    _sendEnvelope(client, const <String, Object?>{
      'type': 'control',
      'commandId': 'pause-1',
      'runId': 'run-1',
      'action': 'pause',
    });
    final paused = await _nextEnvelope(envelopes);
    expect(paused['type'], 'control.ack');
    expect(paused['state'], 'paused');
    _sendEnvelope(client, const <String, Object?>{
      'type': 'control',
      'commandId': 'step-1',
      'runId': 'run-1',
      'action': 'step',
    });
    expect((await _nextEnvelope(envelopes))['type'], 'control.ack');
    expect((await _nextEnvelope(envelopes))['type'], 'result');

    _sendEnvelope(client, <String, Object?>{
      'type': 'run',
      'request': _request('run-2').toJson(),
    });
    expect((await _nextEnvelope(envelopes))['type'], 'event');
    final secondResult = await _nextEnvelope(envelopes);
    expect(secondResult['type'], 'result');
    expect(
      (secondResult['result']! as Map<Object?, Object?>)['runId'],
      'run-2',
    );
    expect(executions, 2);

    _sendEnvelope(client, const <String, Object?>{'type': 'shutdown'});
    expect((await _nextEnvelope(envelopes))['type'], 'shutdown.ack');
    await worker.timeout(const Duration(seconds: 2));
    await envelopes.cancel();
  });

  group('live web run', () {
    late Directory root;
    late EvaluationRunStore store;
    late _LiveOrchestrator orchestrator;
    late EvaluationWebServer server;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('pokemap-eval-live-');
      final assets = Directory(p.join(root.path, 'assets'));
      await assets.create();
      await File(p.join(assets.path, 'index.html')).writeAsString(
        '<meta name="pokemap-eval-token" '
        'content="__POKEMAP_EVAL_TOKEN__">PokeMap Eval',
      );
      await File(p.join(assets.path, 'app.css')).writeAsString('');
      await File(p.join(assets.path, 'app.js')).writeAsString('');
      store = EvaluationRunStore(
        historyRoot: Directory(p.join(root.path, 'history')),
      );
      orchestrator = _LiveOrchestrator(store);
      server = await EvaluationWebServer.start(
        port: 0,
        assetsRoot: assets,
        orchestrator: orchestrator,
      );
    });

    tearDown(() async {
      await server.close();
      if (root.existsSync()) await root.delete(recursive: true);
    });

    test('SSE replays existing events then streams new events', () async {
      orchestrator.createRun('run-live');
      store.append(_event('run-live', 1, 'run.started'));

      final connection = await _openSse(
        server.uri.resolve('/api/runs/run-live/events'),
      );
      addTearDown(connection.close);
      store.append(_event('run-live', 2, 'step.started'));

      final events = await connection.events
          .take(2)
          .toList()
          .timeout(const Duration(seconds: 2));

      expect(events.map((event) => event['sequence']), <int>[1, 2]);
      expect(events.map((event) => event['type']), <String>[
        'run.started',
        'step.started',
      ]);
    });

    test('control routes drive the run control and reject terminal runs',
        () async {
      orchestrator.createRun('run-controlled');

      final pause = await _postControl(server, 'run-controlled', 'pause');
      final step = await _postControl(server, 'run-controlled', 'step');
      final resume = await _postControl(server, 'run-controlled', 'resume');
      final cancel = await _postControl(server, 'run-controlled', 'cancel');
      final invalid = await _postControl(
        server,
        'run-controlled',
        'resume',
      );

      expect(pause.statusCode, HttpStatus.ok);
      expect(pause.json['state'], 'paused');
      expect(step.statusCode, HttpStatus.ok);
      expect(resume.json['state'], 'running');
      expect(cancel.json['state'], 'cancelled');
      expect(invalid.statusCode, HttpStatus.conflict);
    });
  });
}

EvaluationWorkerRequest _request(String runId) {
  return EvaluationWorkerRequest.run(
    runId: runId,
    projectRoot: 'selbrume',
    scenarioPath: 'evaluation/scenario.json',
    outputDirectory: 'build/pokemap-eval/runs/$runId',
  );
}

EvaluationEvent _event(String runId, int sequence, String type) {
  return EvaluationEvent(
    runId: runId,
    sequence: sequence,
    type: type,
    payload: const <String, Object?>{},
  );
}

final class _FakeWorkerFactory implements EvaluationWorkerFactory {
  final List<_FakeWorkerHandle> handles = <_FakeWorkerHandle>[];

  int get createdWorkers => handles.length;

  @override
  Future<EvaluationWorkerHandle> create(String projectId) async {
    final handle = _FakeWorkerHandle();
    handles.add(handle);
    return handle;
  }
}

final class _FakeWorkerHandle implements EvaluationWorkerHandle {
  @override
  bool healthy = true;
  final List<String> runIds = <String>[];
  var concurrentRuns = 0;
  var maxConcurrentRuns = 0;
  var closeCount = 0;

  @override
  Future<EvaluationWorkerResult> run(
    EvaluationWorkerRequest request, {
    EvaluationWorkerEventSink? eventSink,
  }) async {
    concurrentRuns += 1;
    maxConcurrentRuns =
        concurrentRuns > maxConcurrentRuns ? concurrentRuns : maxConcurrentRuns;
    runIds.add(request.runId);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    concurrentRuns -= 1;
    return EvaluationWorkerResult.completed(
      runId: request.runId,
      status: EvaluationRunStatus.succeeded,
      exitCode: 0,
    );
  }

  @override
  Future<void> control(
    String runId,
    EvaluationWorkerControlAction action,
  ) async {}

  @override
  Future<void> close() async {
    closeCount += 1;
    healthy = false;
  }
}

final class _LiveOrchestrator extends EvaluationWebOrchestrator {
  _LiveOrchestrator(this.store);

  final EvaluationRunStore store;
  final Map<String, EvaluationRunControl> controls =
      <String, EvaluationRunControl>{};

  void createRun(String runId) {
    store.create(
      EvaluationRunDescriptor(
        runId: runId,
        projectId: 'selbrume',
        scenarioId: 'selbrume.shop.after-lysa',
        policy: EvaluationPolicy.probe,
        target: EvaluationTarget.headless,
        createdAt: DateTime.utc(2026, 7, 24, 12),
      ),
    );
    controls[runId] = EvaluationRunControl.running();
  }

  @override
  Future<List<EvaluationRunRecord>> listActiveRuns() async => store.activeRuns;

  @override
  EvaluationRunRecord? activeRun(String runId) {
    try {
      return store.requireRun(runId);
    } on StateError {
      return null;
    }
  }

  @override
  Stream<EvaluationEvent>? eventsFor(String runId) {
    return activeRun(runId) == null ? null : store.eventsFor(runId);
  }

  @override
  Future<EvaluationControlState> controlRun(
    String runId,
    EvaluationWorkerControlAction action,
  ) async {
    final control = controls[runId];
    if (control == null) throw StateError('Unknown run.');
    switch (action) {
      case EvaluationWorkerControlAction.pause:
        control.pause();
      case EvaluationWorkerControlAction.step:
        control.step();
      case EvaluationWorkerControlAction.resume:
        control.resume();
      case EvaluationWorkerControlAction.cancel:
        control.cancel();
    }
    return control.state;
  }

  @override
  Future<void> close() async {
    for (final control in controls.values) {
      await control.close();
    }
    await store.close();
  }
}

final class _SseConnection {
  const _SseConnection({
    required this.events,
    required this.client,
  });

  final Stream<Map<String, Object?>> events;
  final HttpClient client;

  void close() => client.close(force: true);
}

Future<_SseConnection> _openSse(Uri uri) async {
  final client = HttpClient();
  final request = await client.getUrl(uri);
  final response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    final body = await utf8.decoder.bind(response).join();
    client.close(force: true);
    throw StateError('SSE failed with ${response.statusCode}: $body');
  }
  final events = response
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .where((line) => line.startsWith('data: '))
      .map(
        (line) => Map<String, Object?>.from(
          jsonDecode(line.substring(6)) as Map,
        ),
      );
  return _SseConnection(events: events, client: client);
}

final class _JsonResponse {
  const _JsonResponse(this.statusCode, this.json);

  final int statusCode;
  final Map<String, Object?> json;
}

Future<_JsonResponse> _postControl(
  EvaluationWebServer server,
  String runId,
  String action,
) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      server.uri.resolve('/api/runs/$runId/$action'),
    );
    request.headers
      ..contentType = ContentType.json
      ..set(EvaluationWebServer.tokenHeader, server.sessionToken);
    request.write('{}');
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    return _JsonResponse(
      response.statusCode,
      Map<String, Object?>.from(jsonDecode(body) as Map),
    );
  } finally {
    client.close(force: true);
  }
}

void _sendEnvelope(Socket socket, Map<String, Object?> envelope) {
  socket.writeln(jsonEncode(envelope));
}

Future<Map<String, Object?>> _nextEnvelope(
  StreamIterator<String> envelopes,
) async {
  if (!await envelopes.moveNext().timeout(const Duration(seconds: 2))) {
    throw StateError('Persistent worker closed before the next envelope.');
  }
  return Map<String, Object?>.from(jsonDecode(envelopes.current) as Map);
}
