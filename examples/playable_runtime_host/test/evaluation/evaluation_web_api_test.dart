import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_run_store.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_web_server.dart';

void main() {
  late Directory root;
  late _FakeApiOrchestrator orchestrator;
  late EvaluationWebServer server;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('pokemap-eval-web-api-');
    final assetsRoot = Directory(p.join(root.path, 'assets'));
    await assetsRoot.create();
    await File(p.join(assetsRoot.path, 'index.html')).writeAsString(
      '<meta name="pokemap-eval-token" '
      'content="__POKEMAP_EVAL_TOKEN__">PokeMap Eval',
    );
    await File(p.join(assetsRoot.path, 'app.css')).writeAsString('');
    await File(p.join(assetsRoot.path, 'app.js')).writeAsString('');
    orchestrator = _FakeApiOrchestrator(
      store: EvaluationRunStore(
        historyRoot: Directory(p.join(root.path, 'history')),
      ),
    );
    server = await EvaluationWebServer.start(
      port: 0,
      assetsRoot: assetsRoot,
      orchestrator: orchestrator,
    );
  });

  tearDown(() async {
    await server.close();
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('GET projects and scenarios returns validated descriptors only',
      () async {
    final projects = await _requestJson(server.uri.resolve('/api/projects'));
    final scenarios = await _requestJson(
      server.uri.resolve('/api/scenarios?project=selbrume'),
    );

    expect(projects.statusCode, HttpStatus.ok);
    expect(
      projects.json['projects'],
      contains(containsPair('id', 'selbrume')),
    );
    expect(scenarios.statusCode, HttpStatus.ok);
    expect(
      scenarios.json['scenarios'],
      contains(
        allOf(
          containsPair('id', 'selbrume.shop.after-lysa'),
          containsPair('policy', 'probe'),
          isNot(contains('path')),
        ),
      ),
    );
  });

  test('POST runs starts an allowlisted headless scenario', () async {
    final response = await _requestJson(
      server.uri.resolve('/api/runs'),
      method: 'POST',
      token: server.sessionToken,
      jsonBody: <String, Object?>{
        'scenarioId': 'selbrume.shop.after-lysa',
        'target': 'headless',
      },
    );

    expect(response.statusCode, HttpStatus.accepted);
    expect(response.json['runId'], matches(RegExp(r'^run-[a-z0-9-]+$')));
    expect(orchestrator.startedScenarioIds, <String>[
      'selbrume.shop.after-lysa',
    ]);

    final runs = await _requestJson(server.uri.resolve('/api/runs'));
    final run = await _requestJson(
      server.uri.resolve('/api/runs/${response.json['runId']}'),
    );
    expect(runs.json['runs'], hasLength(1));
    expect(run.json['run'],
        containsPair('scenarioId', 'selbrume.shop.after-lysa'));
  });

  test('run creation rejects client policy and unavailable target', () async {
    final policyOverride = await _requestJson(
      server.uri.resolve('/api/runs'),
      method: 'POST',
      token: server.sessionToken,
      jsonBody: <String, Object?>{
        'scenarioId': 'selbrume.shop.after-lysa',
        'target': 'headless',
        'policy': 'certify',
      },
    );
    final interactive = await _requestJson(
      server.uri.resolve('/api/runs'),
      method: 'POST',
      token: server.sessionToken,
      jsonBody: <String, Object?>{
        'scenarioId': 'selbrume.shop.after-lysa',
        'target': 'interactive',
      },
    );

    expect(policyOverride.statusCode, HttpStatus.badRequest);
    expect(policyOverride.json['error'], 'invalid_body');
    expect(interactive.statusCode, HttpStatus.conflict);
    expect(interactive.json['error'], 'target_unavailable');
  });

  test('run creation forwards interactive target and playback rate', () async {
    orchestrator.availableTargets = const <EvaluationTarget>{
      EvaluationTarget.headless,
      EvaluationTarget.interactive,
    };

    final response = await _requestJson(
      server.uri.resolve('/api/runs'),
      method: 'POST',
      token: server.sessionToken,
      jsonBody: <String, Object?>{
        'scenarioId': 'selbrume.shop.after-lysa',
        'target': 'interactive',
        'playbackRate': 2,
      },
    );

    expect(response.statusCode, HttpStatus.accepted);
    expect(orchestrator.startedTargets, <EvaluationTarget>[
      EvaluationTarget.interactive,
    ]);
    expect(orchestrator.startedPlaybackRates, <double>[2]);
  });

  test('artifact IDs are opaque and cannot escape the run directory', () async {
    final artifact = await _request(
      server.uri.resolve('/api/artifacts/receipt-001'),
    );
    final traversal = await _requestJson(
      server.uri.resolve('/api/artifacts/..%2F..%2Fproject.json'),
    );

    expect(artifact.statusCode, HttpStatus.ok);
    expect(artifact.body, '{"status":"succeeded"}');
    expect(artifact.headers.contentType?.mimeType, ContentType.json.mimeType);
    expect(traversal.statusCode, HttpStatus.badRequest);
  });
}

final class _JsonResponse {
  const _JsonResponse({
    required this.statusCode,
    required this.json,
  });

  final int statusCode;
  final Map<String, Object?> json;
}

final class _Response {
  const _Response({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final HttpHeaders headers;
  final String body;
}

Future<_JsonResponse> _requestJson(
  Uri uri, {
  String method = 'GET',
  String? token,
  Map<String, Object?>? jsonBody,
}) async {
  final response = await _request(
    uri,
    method: method,
    token: token,
    body: jsonBody == null ? null : jsonEncode(jsonBody),
  );
  final decoded = jsonDecode(response.body);
  return _JsonResponse(
    statusCode: response.statusCode,
    json: Map<String, Object?>.from(decoded as Map),
  );
}

Future<_Response> _request(
  Uri uri, {
  String method = 'GET',
  String? token,
  String? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    if (token != null) {
      request.headers.set(EvaluationWebServer.tokenHeader, token);
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(body);
    }
    final response = await request.close();
    return _Response(
      statusCode: response.statusCode,
      headers: response.headers,
      body: await utf8.decoder.bind(response).join(),
    );
  } finally {
    client.close(force: true);
  }
}

final class _FakeApiOrchestrator extends EvaluationWebOrchestrator {
  _FakeApiOrchestrator({required this.store});

  final EvaluationRunStore store;
  final List<String> startedScenarioIds = <String>[];
  final List<EvaluationTarget> startedTargets = <EvaluationTarget>[];
  final List<double> startedPlaybackRates = <double>[];
  @override
  Set<EvaluationTarget> availableTargets = const <EvaluationTarget>{
    EvaluationTarget.headless
  };
  var _nextRun = 1;

  @override
  Future<List<EvaluationWebProjectDescriptor>> listProjects() async {
    return <EvaluationWebProjectDescriptor>[
      EvaluationWebProjectDescriptor(id: 'selbrume', label: 'Selbrume'),
    ];
  }

  @override
  Future<List<EvaluationWebScenarioDescriptor>> listScenarios({
    String? projectId,
  }) async {
    final scenarios = <EvaluationWebScenarioDescriptor>[
      EvaluationWebScenarioDescriptor(
        id: 'selbrume.shop.after-lysa',
        title: 'Boutique après Lysa',
        projectId: 'selbrume',
        policy: EvaluationPolicy.probe,
        stepCount: 10,
        criterionIds: const <String>[],
      ),
    ];
    return scenarios
        .where(
            (scenario) => projectId == null || scenario.projectId == projectId)
        .toList(growable: false);
  }

  @override
  Future<EvaluationRunRecord> startRun({
    required EvaluationWebScenarioDescriptor scenario,
    required EvaluationTarget target,
    double playbackRate = 1,
  }) async {
    startedScenarioIds.add(scenario.id);
    startedTargets.add(target);
    startedPlaybackRates.add(playbackRate);
    return store.create(
      EvaluationRunDescriptor(
        runId: 'run-api-${_nextRun++}',
        projectId: scenario.projectId,
        scenarioId: scenario.id,
        policy: scenario.policy,
        target: target,
        createdAt: DateTime.utc(2026, 7, 24, 12),
      ),
    );
  }

  @override
  Future<List<EvaluationRunRecord>> listActiveRuns() async => store.activeRuns;

  @override
  Future<List<EvaluationRunHistoryRecord>> loadHistory() {
    return store.loadHistory();
  }

  @override
  Future<EvaluationWebArtifact?> readArtifact(String artifactId) async {
    if (artifactId != 'receipt-001') return null;
    return EvaluationWebArtifact(
      id: artifactId,
      contentType: ContentType.json,
      bytes: utf8.encode('{"status":"succeeded"}'),
    );
  }

  @override
  Future<void> close() => store.close();
}
