import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/web/evaluation_web_server.dart';

void main() {
  late Directory assetsRoot;
  late _FakeOrchestrator orchestrator;
  late EvaluationWebServer server;

  setUp(() async {
    assetsRoot =
        await Directory.systemTemp.createTemp('pokemap-eval-web-assets-');
    await File(p.join(assetsRoot.path, 'index.html')).writeAsString(
      '<!doctype html><html><head>'
      '<meta name="pokemap-eval-token" '
      'content="__POKEMAP_EVAL_TOKEN__">'
      '</head><body>PokeMap Eval</body></html>',
    );
    await File(p.join(assetsRoot.path, 'app.css')).writeAsString('body {}');
    await File(p.join(assetsRoot.path, 'app.js')).writeAsString(
      'console.log("PokeMap Eval");',
    );
    orchestrator = _FakeOrchestrator();
    server = await EvaluationWebServer.start(
      port: 0,
      assetsRoot: assetsRoot,
      orchestrator: orchestrator,
    );
  });

  tearDown(() async {
    await server.close();
    if (assetsRoot.existsSync()) {
      await assetsRoot.delete(recursive: true);
    }
  });

  test('binds loopback and serves a security-hardened cockpit shell', () async {
    expect(server.address.address, InternetAddress.loopbackIPv4.address);

    final response = await _request(server.uri);

    expect(response.statusCode, HttpStatus.ok);
    expect(response.body, contains('PokeMap Eval'));
    expect(response.body, contains('name="pokemap-eval-token"'));
    expect(response.body, contains(server.sessionToken));
    expect(response.body, isNot(contains('__POKEMAP_EVAL_TOKEN__')));
    expect(
      response.headers.value('content-security-policy'),
      contains("default-src 'self'"),
    );
    expect(response.headers.value('x-content-type-options'), 'nosniff');
    expect(response.headers.value('referrer-policy'), 'no-referrer');
    expect(response.headers.value('cache-control'), 'no-store');
  });

  test('mutating routes require the exact ephemeral token', () async {
    final missing = await _request(
      server.uri.resolve('/api/runs'),
      method: 'POST',
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      },
      body: '{"scenarioId":"selbrume.mvp"}',
    );
    final wrong = await _request(
      server.uri.resolve('/api/runs'),
      method: 'POST',
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
        EvaluationWebServer.tokenHeader: 'wrong-token',
      },
      body: '{"scenarioId":"selbrume.mvp"}',
    );

    expect(missing.statusCode, HttpStatus.forbidden);
    expect(wrong.statusCode, HttpStatus.forbidden);
  });

  test('rejects unsafe methods, media types, and oversized bodies', () async {
    final wrongMethod = await _request(
      server.uri.resolve('/app.js'),
      method: 'POST',
      headers: <String, String>{
        EvaluationWebServer.tokenHeader: server.sessionToken,
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      },
      body: '{}',
    );
    final wrongType = await _request(
      server.uri.resolve('/api/runs'),
      method: 'POST',
      headers: <String, String>{
        EvaluationWebServer.tokenHeader: server.sessionToken,
        HttpHeaders.contentTypeHeader: ContentType.text.mimeType,
      },
      body: '{}',
    );
    final oversized = await _request(
      server.uri.resolve('/api/runs'),
      method: 'POST',
      headers: <String, String>{
        EvaluationWebServer.tokenHeader: server.sessionToken,
        HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
      },
      body: jsonEncode(<String, Object?>{
        'value': List<String>.filled(64 * 1024, 'x').join(),
      }),
    );

    expect(wrongMethod.statusCode, HttpStatus.methodNotAllowed);
    expect(wrongType.statusCode, HttpStatus.unsupportedMediaType);
    expect(oversized.statusCode, HttpStatus.requestEntityTooLarge);
  });

  test('serves only allowlisted assets and rejects malformed API IDs',
      () async {
    final css = await _request(server.uri.resolve('/app.css'));
    final traversal = await _request(
      server.uri.resolve('/..%2F..%2Fproject.json'),
    );
    final unknown = await _request(server.uri.resolve('/project.json'));
    final malformed = await _request(
      server.uri.resolve('/api/runs/bad%20id'),
    );

    expect(css.statusCode, HttpStatus.ok);
    expect(css.headers.contentType?.mimeType, 'text/css');
    expect(traversal.statusCode, HttpStatus.notFound);
    expect(unknown.statusCode, HttpStatus.notFound);
    expect(malformed.statusCode, HttpStatus.badRequest);
  });

  test('startup rejects an invalid token template', () async {
    await server.close();
    await File(p.join(assetsRoot.path, 'index.html')).writeAsString(
      '<html><body>No placeholder</body></html>',
    );

    await expectLater(
      EvaluationWebServer.start(
        port: 0,
        assetsRoot: assetsRoot,
        orchestrator: orchestrator,
      ),
      throwsA(isA<StateError>()),
    );
  });
}

final class _HttpResponse {
  const _HttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final HttpHeaders headers;
  final String body;
}

Future<_HttpResponse> _request(
  Uri uri, {
  String method = 'GET',
  Map<String, String> headers = const <String, String>{},
  String? body,
}) async {
  final client = HttpClient();
  try {
    final request = await client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (body != null) request.write(body);
    final response = await request.close();
    return _HttpResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: await utf8.decoder.bind(response).join(),
    );
  } finally {
    client.close(force: true);
  }
}

final class _FakeOrchestrator extends EvaluationWebOrchestrator {
  var closeCount = 0;

  @override
  Future<void> close() async {
    closeCount += 1;
  }
}
