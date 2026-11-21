import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../contracts/evaluation_event.dart';
import '../contracts/evaluation_policy.dart';
import '../runner/evaluation_run_control.dart';
import 'evaluation_run_store.dart';
import 'evaluation_worker_pool.dart';

final class EvaluationWebProjectDescriptor {
  EvaluationWebProjectDescriptor({
    required String id,
    required String label,
  })  : id = _validatedIdentifier(id, 'project id'),
        label = _nonBlank(label, 'project label');

  final String id;
  final String label;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'label': label,
      };
}

final class EvaluationWebScenarioDescriptor {
  EvaluationWebScenarioDescriptor({
    required String id,
    required String title,
    required String projectId,
    required this.policy,
    required this.stepCount,
    required List<String> criterionIds,
  })  : id = _validatedIdentifier(id, 'scenario id'),
        title = _nonBlank(title, 'scenario title'),
        projectId = _validatedIdentifier(projectId, 'scenario project id'),
        criterionIds = List<String>.unmodifiable(
          criterionIds.map(
            (criterionId) => _validatedIdentifier(criterionId, 'criterion id'),
          ),
        ) {
    if (stepCount < 0) {
      throw ArgumentError.value(
        stepCount,
        'stepCount',
        'Step count must not be negative.',
      );
    }
  }

  final String id;
  final String title;
  final String projectId;
  final EvaluationPolicy policy;
  final int stepCount;
  final List<String> criterionIds;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'title': title,
        'projectId': projectId,
        'policy': policy.name,
        'stepCount': stepCount,
        'criterionIds': criterionIds,
      };
}

final class EvaluationWebArtifact {
  EvaluationWebArtifact({
    required String id,
    required this.contentType,
    required List<int> bytes,
  })  : id = _validatedIdentifier(id, 'artifact id'),
        bytes = List<int>.unmodifiable(bytes);

  final String id;
  final ContentType contentType;
  final List<int> bytes;
}

abstract base class EvaluationWebOrchestrator {
  Set<EvaluationTarget> get availableTargets =>
      const <EvaluationTarget>{EvaluationTarget.headless};

  Future<List<EvaluationWebProjectDescriptor>> listProjects() async {
    return const <EvaluationWebProjectDescriptor>[];
  }

  Future<List<EvaluationWebScenarioDescriptor>> listScenarios({
    String? projectId,
  }) async {
    return const <EvaluationWebScenarioDescriptor>[];
  }

  Future<List<EvaluationRunRecord>> listActiveRuns() async {
    return const <EvaluationRunRecord>[];
  }

  Future<List<EvaluationRunHistoryRecord>> loadHistory() async {
    return const <EvaluationRunHistoryRecord>[];
  }

  Future<EvaluationRunRecord> startRun({
    required EvaluationWebScenarioDescriptor scenario,
    required EvaluationTarget target,
    double playbackRate = 1,
  }) {
    throw UnsupportedError('This orchestrator cannot start evaluation runs.');
  }

  Future<EvaluationWebArtifact?> readArtifact(String artifactId) async {
    return null;
  }

  EvaluationRunRecord? activeRun(String runId) => null;

  Stream<EvaluationEvent>? eventsFor(String runId) => null;

  Future<EvaluationControlState> controlRun(
    String runId,
    EvaluationWorkerControlAction action,
  ) {
    throw StateError('Run $runId cannot be controlled.');
  }

  Future<void> close();
}

final class EvaluationWebServer {
  EvaluationWebServer._({
    required HttpServer server,
    required this.sessionToken,
    required this.orchestrator,
    required Map<String, _StaticAsset> assets,
  })  : _server = server,
        _assets = Map<String, _StaticAsset>.unmodifiable(assets);

  static const tokenHeader = 'X-PokeMap-Eval-Token';
  static const _tokenPlaceholder = '__POKEMAP_EVAL_TOKEN__';
  static const _maxBodyBytes = 64 * 1024;

  static Future<EvaluationWebServer> start({
    required int port,
    required Directory assetsRoot,
    required EvaluationWebOrchestrator orchestrator,
  }) async {
    if (port < 0 || port > 65535) {
      throw ArgumentError.value(port, 'port', 'Expected a valid TCP port.');
    }
    final assets = await _loadAssets(assetsRoot.absolute);
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
      shared: false,
    );
    final result = EvaluationWebServer._(
      server: server,
      sessionToken: _createSessionToken(),
      orchestrator: orchestrator,
      assets: assets,
    );
    server.listen((request) {
      unawaited(result._handle(request));
    });
    return result;
  }

  final HttpServer _server;
  final Map<String, _StaticAsset> _assets;
  final EvaluationWebOrchestrator orchestrator;
  final String sessionToken;
  bool _closed = false;

  InternetAddress get address => _server.address;
  int get port => _server.port;
  Uri get uri => Uri(
        scheme: 'http',
        host: address.address,
        port: port,
        path: '/',
      );

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _server.close(force: true);
    await orchestrator.close();
  }

  Future<void> _handle(HttpRequest request) async {
    _setSecurityHeaders(request.response);
    try {
      final path = request.uri.path;
      final asset = _assets[path];
      if (asset != null) {
        if (request.method != 'GET') {
          await _writeError(
            request.response,
            HttpStatus.methodNotAllowed,
            'method_not_allowed',
          );
          return;
        }
        await _serveAsset(request.response, asset);
        return;
      }

      if (!path.startsWith('/api/')) {
        await _writeError(
          request.response,
          HttpStatus.notFound,
          'not_found',
        );
        return;
      }

      if (!_hasValidApiIdentifiers(request.uri.pathSegments)) {
        await _writeError(
          request.response,
          HttpStatus.badRequest,
          'invalid_identifier',
        );
        return;
      }

      String? mutationBody;
      if (_isMutation(request.method)) {
        if (request.headers.value(tokenHeader) != sessionToken) {
          await _writeError(
            request.response,
            HttpStatus.forbidden,
            'forbidden',
          );
          return;
        }
        final contentType = request.headers.contentType;
        if (contentType?.mimeType != ContentType.json.mimeType) {
          await _writeError(
            request.response,
            HttpStatus.unsupportedMediaType,
            'json_required',
          );
          return;
        }
        mutationBody = await _readBody(request);
        if (mutationBody == null) {
          await _writeError(
            request.response,
            HttpStatus.requestEntityTooLarge,
            'body_too_large',
          );
          return;
        }
      } else if (request.method != 'GET') {
        await _writeError(
          request.response,
          HttpStatus.methodNotAllowed,
          'method_not_allowed',
        );
        return;
      }

      await _handleApi(request, mutationBody);
    } on Object {
      try {
        await _writeError(
          request.response,
          HttpStatus.internalServerError,
          'internal_error',
        );
      } on Object {
        await request.response.close();
      }
    }
  }

  Future<void> _handleApi(
    HttpRequest request,
    String? mutationBody,
  ) async {
    final segments = request.uri.pathSegments;
    if (_matches(segments, const <String>['api', 'capabilities'])) {
      if (request.method != 'GET') {
        await _writeError(
          request.response,
          HttpStatus.methodNotAllowed,
          'method_not_allowed',
        );
        return;
      }
      if (request.uri.queryParameters.isNotEmpty) {
        await _writeError(
          request.response,
          HttpStatus.badRequest,
          'invalid_query',
        );
        return;
      }
      final targets = EvaluationTarget.values
          .where(orchestrator.availableTargets.contains)
          .map((target) => target.name)
          .toList(growable: false);
      await _writeJson(request.response, HttpStatus.ok, <String, Object?>{
        'targets': targets,
        if (orchestrator.availableTargets
            .contains(EvaluationTarget.interactive))
          'interactive': <String, Object?>{
            'platform': 'macos',
            'frameMetrics': true,
            'capture': true,
            'playbackRates': <double>[0.5, 1, 2],
          },
      });
      return;
    }

    if (_matches(segments, const <String>['api', 'projects'])) {
      if (request.method != 'GET') {
        await _writeError(
          request.response,
          HttpStatus.methodNotAllowed,
          'method_not_allowed',
        );
        return;
      }
      if (request.uri.queryParameters.isNotEmpty) {
        await _writeError(
          request.response,
          HttpStatus.badRequest,
          'invalid_query',
        );
        return;
      }
      final projects = await orchestrator.listProjects();
      await _writeJson(request.response, HttpStatus.ok, <String, Object?>{
        'projects':
            projects.map((project) => project.toJson()).toList(growable: false),
      });
      return;
    }

    if (_matches(segments, const <String>['api', 'scenarios'])) {
      if (request.method != 'GET') {
        await _writeError(
          request.response,
          HttpStatus.methodNotAllowed,
          'method_not_allowed',
        );
        return;
      }
      if (request.uri.queryParameters.keys.any((key) => key != 'project')) {
        await _writeError(
          request.response,
          HttpStatus.badRequest,
          'invalid_query',
        );
        return;
      }
      final projectId = request.uri.queryParameters['project'];
      if (projectId != null && !_isIdentifier(projectId)) {
        await _writeError(
          request.response,
          HttpStatus.badRequest,
          'invalid_identifier',
        );
        return;
      }
      final scenarios = await orchestrator.listScenarios(
        projectId: projectId,
      );
      await _writeJson(request.response, HttpStatus.ok, <String, Object?>{
        'scenarios': scenarios
            .map((scenario) => scenario.toJson())
            .toList(growable: false),
      });
      return;
    }

    if (_matches(segments, const <String>['api', 'runs'])) {
      if (request.method == 'GET') {
        final active = await orchestrator.listActiveRuns();
        final history = await orchestrator.loadHistory();
        await _writeJson(request.response, HttpStatus.ok, <String, Object?>{
          'runs': <Map<String, Object?>>[
            for (final run in active)
              <String, Object?>{
                ...run.toJson(),
                'source': 'active',
              },
            for (final run in history)
              <String, Object?>{
                ...run.toJson(),
                'source': 'history',
              },
          ],
        });
        return;
      }
      if (request.method == 'POST') {
        await _startRun(request.response, mutationBody!);
        return;
      }
      await _writeError(
        request.response,
        HttpStatus.methodNotAllowed,
        'method_not_allowed',
      );
      return;
    }

    if (segments.length == 4 &&
        segments[0] == 'api' &&
        segments[1] == 'runs' &&
        segments[3] == 'events') {
      if (request.method != 'GET') {
        await _writeError(
          request.response,
          HttpStatus.methodNotAllowed,
          'method_not_allowed',
        );
        return;
      }
      await _streamRunEvents(request.response, segments[2]);
      return;
    }

    if (segments.length == 4 && segments[0] == 'api' && segments[1] == 'runs') {
      if (request.method != 'POST') {
        await _writeError(
          request.response,
          HttpStatus.methodNotAllowed,
          'method_not_allowed',
        );
        return;
      }
      await _controlRun(
        request.response,
        runId: segments[2],
        actionName: segments[3],
        body: mutationBody!,
      );
      return;
    }

    if (segments.length == 3 && segments[0] == 'api' && segments[1] == 'runs') {
      if (request.method != 'GET') {
        await _writeError(
          request.response,
          HttpStatus.methodNotAllowed,
          'method_not_allowed',
        );
        return;
      }
      final runId = segments[2];
      final history = await orchestrator.loadHistory();
      for (final run in history) {
        if (run.runId == runId) {
          await _writeJson(request.response, HttpStatus.ok, <String, Object?>{
            'run': <String, Object?>{
              ...run.toJson(),
              'source': 'history',
              'receipt': run.receipt.toJson(),
            },
          });
          return;
        }
      }
      final active = await orchestrator.listActiveRuns();
      for (final run in active) {
        if (run.runId == runId) {
          await _writeJson(request.response, HttpStatus.ok, <String, Object?>{
            'run': <String, Object?>{
              ...run.toJson(),
              'source': 'active',
            },
          });
          return;
        }
      }
      await _writeError(
        request.response,
        HttpStatus.notFound,
        'run_not_found',
      );
      return;
    }

    if (segments.length == 3 &&
        segments[0] == 'api' &&
        segments[1] == 'artifacts') {
      if (request.method != 'GET') {
        await _writeError(
          request.response,
          HttpStatus.methodNotAllowed,
          'method_not_allowed',
        );
        return;
      }
      final artifact = await orchestrator.readArtifact(segments[2]);
      if (artifact == null) {
        await _writeError(
          request.response,
          HttpStatus.notFound,
          'artifact_not_found',
        );
        return;
      }
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = artifact.contentType
        ..add(artifact.bytes);
      await request.response.close();
      return;
    }

    await _writeError(
      request.response,
      HttpStatus.notFound,
      'not_found',
    );
  }

  Future<void> _streamRunEvents(
    HttpResponse response,
    String runId,
  ) async {
    final snapshot = orchestrator.activeRun(runId);
    final liveEvents = orchestrator.eventsFor(runId);
    if (snapshot == null || liveEvents == null) {
      await _writeError(
        response,
        HttpStatus.notFound,
        'run_not_found',
      );
      return;
    }

    response
      ..statusCode = HttpStatus.ok
      ..bufferOutput = false
      ..headers.contentType = ContentType(
        'text',
        'event-stream',
        charset: 'utf-8',
      );
    response.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-cache')
      ..set(HttpHeaders.connectionHeader, 'keep-alive');

    final streamEnded = Completer<void>();
    void finishStream() {
      if (!streamEnded.isCompleted) streamEnded.complete();
    }

    late final StreamSubscription<EvaluationEvent> subscription;
    subscription = liveEvents.listen(
      (event) {
        _writeServerSentEvent(response, event);
      },
      onError: (Object _, StackTrace __) => finishStream(),
      onDone: finishStream,
      cancelOnError: true,
    );
    subscription.pause();
    try {
      for (final event in snapshot.events) {
        _writeServerSentEvent(response, event);
      }
      await response.flush();
      subscription.resume();
      // Stream completion and browser disconnection race each other. Waiting
      // for either one here keeps response.close() single-owner and prevents
      // concurrent HttpResponse closes during application shutdown.
      await Future.any<void>(<Future<void>>[
        response.done,
        streamEnded.future,
      ]);
    } on Object {
      // A disconnected browser is a normal end to a live SSE subscription.
    } finally {
      await subscription.cancel();
      try {
        await response.close();
      } on Object {
        // The browser or HttpServer may already own the completed response.
      }
    }
  }

  Future<void> _controlRun(
    HttpResponse response, {
    required String runId,
    required String actionName,
    required String body,
  }) async {
    final action = EvaluationWorkerControlAction.values
        .where((candidate) => candidate.name == actionName)
        .firstOrNull;
    if (action == null) {
      await _writeError(response, HttpStatus.notFound, 'action_not_found');
      return;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map || decoded.isNotEmpty) {
        throw const FormatException('Control body must be empty.');
      }
    } on Object {
      await _writeError(response, HttpStatus.badRequest, 'invalid_body');
      return;
    }

    if (orchestrator.activeRun(runId) == null) {
      final history = await orchestrator.loadHistory();
      final isFinished = history.any((run) => run.runId == runId);
      await _writeError(
        response,
        isFinished ? HttpStatus.conflict : HttpStatus.notFound,
        isFinished ? 'run_finished' : 'run_not_found',
      );
      return;
    }

    try {
      final state = await orchestrator.controlRun(runId, action);
      await _writeJson(response, HttpStatus.ok, <String, Object?>{
        'runId': runId,
        'action': action.name,
        'state': state.name,
      });
    } on EvaluationRunCancelled {
      await _writeError(response, HttpStatus.conflict, 'run_cancelled');
    } on StateError {
      await _writeError(response, HttpStatus.conflict, 'invalid_run_state');
    }
  }

  Future<void> _startRun(HttpResponse response, String body) async {
    final Map<String, Object?> json;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const FormatException('Body must be an object.');
      }
      json = Map<String, Object?>.from(decoded);
    } on Object {
      await _writeError(response, HttpStatus.badRequest, 'invalid_body');
      return;
    }
    const allowedKeys = <String>{
      'scenarioId',
      'target',
      'playbackRate',
    };
    if (json.length < 2 ||
        json.length > 3 ||
        json.keys.any((key) => !allowedKeys.contains(key)) ||
        !json.containsKey('scenarioId') ||
        !json.containsKey('target') ||
        json['scenarioId'] is! String ||
        json['target'] is! String) {
      await _writeError(response, HttpStatus.badRequest, 'invalid_body');
      return;
    }
    final scenarioId = json['scenarioId']! as String;
    if (!_isIdentifier(scenarioId)) {
      await _writeError(
        response,
        HttpStatus.badRequest,
        'invalid_identifier',
      );
      return;
    }
    final targetName = json['target']! as String;
    final target = EvaluationTarget.values
        .where((candidate) => candidate.name == targetName)
        .firstOrNull;
    if (target == null) {
      await _writeError(response, HttpStatus.badRequest, 'invalid_target');
      return;
    }
    if (!orchestrator.availableTargets.contains(target)) {
      await _writeError(
        response,
        HttpStatus.conflict,
        'target_unavailable',
      );
      return;
    }
    final playbackValue = json['playbackRate'] ?? 1;
    if (playbackValue is! num ||
        !const <double>[0.5, 1, 2].contains(playbackValue.toDouble())) {
      await _writeError(
        response,
        HttpStatus.badRequest,
        'invalid_playback_rate',
      );
      return;
    }
    final playbackRate = playbackValue.toDouble();
    final matches = (await orchestrator.listScenarios())
        .where((scenario) => scenario.id == scenarioId)
        .toList(growable: false);
    if (matches.isEmpty) {
      await _writeError(
        response,
        HttpStatus.notFound,
        'scenario_not_found',
      );
      return;
    }
    if (matches.length != 1) {
      await _writeError(
        response,
        HttpStatus.conflict,
        'scenario_ambiguous',
      );
      return;
    }
    final run = await orchestrator.startRun(
      scenario: matches.single,
      target: target,
      playbackRate: playbackRate,
    );
    await _writeJson(response, HttpStatus.accepted, <String, Object?>{
      'runId': run.runId,
      'run': run.toJson(),
    });
  }

  Future<void> _serveAsset(
    HttpResponse response,
    _StaticAsset asset,
  ) async {
    response.statusCode = HttpStatus.ok;
    response.headers.contentType = asset.contentType;
    final content = asset.injectToken
        ? asset.content.replaceFirst(_tokenPlaceholder, sessionToken)
        : asset.content;
    response.write(content);
    await response.close();
  }

  static Future<String?> _readBody(HttpRequest request) async {
    if (request.contentLength > _maxBodyBytes) return null;
    final bytes = <int>[];
    await for (final chunk in request) {
      bytes.addAll(chunk);
      if (bytes.length > _maxBodyBytes) return null;
    }
    return utf8.decode(bytes);
  }

  static void _setSecurityHeaders(HttpResponse response) {
    response.headers
      ..set(
        'Content-Security-Policy',
        "default-src 'self'; base-uri 'none'; frame-ancestors 'none'; "
            "form-action 'none'; object-src 'none'; connect-src 'self'",
      )
      ..set('X-Content-Type-Options', 'nosniff')
      ..set('Referrer-Policy', 'no-referrer')
      ..set(HttpHeaders.cacheControlHeader, 'no-store');
  }

  static Future<void> _writeError(
    HttpResponse response,
    int statusCode,
    String code,
  ) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(<String, Object?>{'error': code}));
    await response.close();
  }

  static Future<void> _writeJson(
    HttpResponse response,
    int statusCode,
    Map<String, Object?> json,
  ) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(json));
    await response.close();
  }
}

void _writeServerSentEvent(
  HttpResponse response,
  EvaluationEvent event,
) {
  response
    ..write('id: ${event.sequence}\n')
    ..write('event: ${event.type}\n')
    ..write('data: ${jsonEncode(event.toJson())}\n\n');
}

final class _StaticAsset {
  const _StaticAsset({
    required this.content,
    required this.contentType,
    this.injectToken = false,
  });

  final String content;
  final ContentType contentType;
  final bool injectToken;
}

Future<Map<String, _StaticAsset>> _loadAssets(Directory assetsRoot) async {
  final index = await _readRequiredAsset(assetsRoot, 'index.html');
  final placeholderCount =
      _allOccurrences(index, EvaluationWebServer._tokenPlaceholder);
  if (placeholderCount != 1) {
    throw StateError(
      'index.html must contain exactly one '
      '${EvaluationWebServer._tokenPlaceholder} placeholder.',
    );
  }
  return <String, _StaticAsset>{
    '/': _StaticAsset(
      content: index,
      contentType: ContentType.html,
      injectToken: true,
    ),
    '/app.css': _StaticAsset(
      content: await _readRequiredAsset(assetsRoot, 'app.css'),
      contentType: ContentType('text', 'css', charset: 'utf-8'),
    ),
    '/app.js': _StaticAsset(
      content: await _readRequiredAsset(assetsRoot, 'app.js'),
      contentType: ContentType(
        'application',
        'javascript',
        charset: 'utf-8',
      ),
    ),
  };
}

Future<String> _readRequiredAsset(Directory root, String name) async {
  final file = File(p.join(root.path, name));
  if (!await file.exists()) {
    throw StateError('Missing PokeMap Eval web asset $name.');
  }
  return file.readAsString();
}

String _createSessionToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

int _allOccurrences(String value, String pattern) {
  var count = 0;
  var offset = 0;
  while (true) {
    final index = value.indexOf(pattern, offset);
    if (index < 0) return count;
    count += 1;
    offset = index + pattern.length;
  }
}

bool _isMutation(String method) {
  return switch (method) {
    'POST' || 'PUT' || 'PATCH' || 'DELETE' => true,
    _ => false,
  };
}

bool _hasValidApiIdentifiers(List<String> segments) {
  if (segments.length < 3) return true;
  final collection = segments[1];
  if (collection != 'runs' && collection != 'artifacts') return true;
  final identifier = segments[2];
  return _isIdentifier(identifier);
}

bool _matches(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _validatedIdentifier(String value, String name) {
  if (!_isIdentifier(value)) {
    throw ArgumentError.value(value, name, 'Invalid identifier.');
  }
  return value;
}

bool _isIdentifier(String value) {
  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(value);
}

String _nonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'Value must not be blank.');
  }
  return value;
}
