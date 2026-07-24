import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

abstract interface class EvaluationWebOrchestrator {
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
        final body = await _readBody(request);
        if (body == null) {
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

      await _writeError(
        request.response,
        HttpStatus.notFound,
        'not_found',
      );
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
  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(identifier);
}
