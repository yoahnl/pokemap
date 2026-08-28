import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'package:pokemap_hub/features/control/application/avelune_control_service.dart';
import 'package:pokemap_hub/features/control/domain/avelune_control_models.dart';

final class AveluneControlServer {
  AveluneControlServer({
    required this.service,
    required String token,
    required this.port,
    required this.uploadDirectory,
    this.maxPackageBytes = 2147483648,
  }) : token = token.trim() {
    if (this.token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'A token is required.');
    }
    if (port < 0 || port > 65535) {
      throw RangeError.range(port, 0, 65535, 'port');
    }
    if (maxPackageBytes < 1) {
      throw RangeError.range(maxPackageBytes, 1, null, 'maxPackageBytes');
    }
  }

  final AveluneControlService service;
  final String token;
  final int port;
  final Directory uploadDirectory;
  final int maxPackageBytes;
  HttpServer? _server;

  Uri get baseUri {
    final server = _server;
    if (server == null) throw StateError('The control server is not running.');
    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
    );
  }

  Future<void> start() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server = server;
    unawaited(
      server.forEach((request) async {
        await _handle(request);
      }),
    );
  }

  Future<void> close() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      _authorize(request);
      final path = request.uri.path;
      if (path == '/v1/describe') {
        _requireMethod(request, 'GET');
        await _writeJson(request.response, HttpStatus.ok, <String, Object?>{
          'name': 'Avelune Control API',
          'protocolVersion': AveluneControlState.protocolVersion,
          'capabilities': <String>['state', 'install', 'launch', 'returnToHub'],
        });
        return;
      }
      if (path == '/v1/state') {
        _requireMethod(request, 'GET');
        await _writeJson(
          request.response,
          HttpStatus.ok,
          service.state().toJson(),
        );
        return;
      }
      if (path == '/v1/install') {
        _requireMethod(request, 'POST');
        final package = await _receivePackage(request);
        late final AveluneControlState result;
        try {
          result = await service.install(package);
        } finally {
          if (await package.exists()) await package.delete();
        }
        await _writeJson(request.response, HttpStatus.ok, result.toJson());
        return;
      }
      if (path == '/v1/launch') {
        _requireMethod(request, 'POST');
        final body = await _readJsonObject(request);
        final gameId = body['gameId'];
        if (gameId is! String || gameId.trim().isEmpty) {
          throw const AveluneControlException(
            AveluneControlErrorCode.invalidRequest,
            'A non-empty gameId is required.',
          );
        }
        await _writeJson(
          request.response,
          HttpStatus.ok,
          service.launch(gameId.trim()).toJson(),
        );
        return;
      }
      if (path == '/v1/hub') {
        _requireMethod(request, 'POST');
        await _writeJson(
          request.response,
          HttpStatus.ok,
          (await service.returnToHub()).toJson(),
        );
        return;
      }
      throw const AveluneControlException(
        AveluneControlErrorCode.routeNotFound,
        'The requested control route does not exist.',
      );
    } on AveluneControlException catch (error) {
      await _writeError(request.response, error);
    } on FormatException {
      await _writeError(
        request.response,
        const AveluneControlException(
          AveluneControlErrorCode.invalidRequest,
          'The request body must be a JSON object.',
        ),
      );
    } on Object {
      await _writeError(
        request.response,
        const AveluneControlException(
          AveluneControlErrorCode.internalFailure,
          'The control request failed.',
        ),
      );
    }
  }

  void _authorize(HttpRequest request) {
    final authorization = request.headers.value(
      HttpHeaders.authorizationHeader,
    );
    if (authorization != 'Bearer $token') {
      throw const AveluneControlException(
        AveluneControlErrorCode.unauthorized,
        'A valid control token is required.',
      );
    }
  }

  void _requireMethod(HttpRequest request, String expected) {
    if (request.method == expected) return;
    throw AveluneControlException(
      AveluneControlErrorCode.methodNotAllowed,
      'The route requires $expected.',
    );
  }

  Future<Map<String, Object?>> _readJsonObject(HttpRequest request) async {
    if (request.contentLength > 16384) {
      throw const AveluneControlException(
        AveluneControlErrorCode.invalidRequest,
        'The request body is too large.',
      );
    }
    final source = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(source);
    if (decoded is! Map) throw const FormatException();
    return decoded.cast<String, Object?>();
  }

  Future<File> _receivePackage(HttpRequest request) async {
    final filename = request.uri.queryParameters['filename'];
    if (filename == null ||
        filename.isEmpty ||
        p.basename(filename) != filename ||
        p.extension(filename).toLowerCase() != '.avelunegame') {
      throw const AveluneControlException(
        AveluneControlErrorCode.invalidRequest,
        'A valid .avelunegame filename is required.',
      );
    }
    if (request.contentLength > maxPackageBytes) {
      throw const AveluneControlException(
        AveluneControlErrorCode.invalidRequest,
        'The Avelune package is too large.',
      );
    }
    await uploadDirectory.create(recursive: true);
    final nonce = Random.secure().nextInt(0x7fffffff).toRadixString(16);
    final package = File(
      p.join(
        uploadDirectory.path,
        '${DateTime.now().microsecondsSinceEpoch}-$nonce-$filename',
      ),
    );
    await package.create(exclusive: true);
    final sink = package.openWrite();
    var received = 0;
    try {
      await for (final chunk in request) {
        received += chunk.length;
        if (received > maxPackageBytes) {
          throw const AveluneControlException(
            AveluneControlErrorCode.invalidRequest,
            'The Avelune package is too large.',
          );
        }
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      return package;
    } on Object {
      await sink.close();
      if (await package.exists()) await package.delete();
      rethrow;
    }
  }

  Future<void> _writeError(
    HttpResponse response,
    AveluneControlException error,
  ) => _writeJson(response, _statusCode(error.code), <String, Object?>{
    'code': error.code.name,
    'message': error.message,
  });

  int _statusCode(AveluneControlErrorCode code) => switch (code) {
    AveluneControlErrorCode.invalidRequest => HttpStatus.badRequest,
    AveluneControlErrorCode.unauthorized => HttpStatus.unauthorized,
    AveluneControlErrorCode.gameNotFound ||
    AveluneControlErrorCode.routeNotFound => HttpStatus.notFound,
    AveluneControlErrorCode.methodNotAllowed => HttpStatus.methodNotAllowed,
    AveluneControlErrorCode.installFailed => HttpStatus.unprocessableEntity,
    AveluneControlErrorCode.hubNotReady ||
    AveluneControlErrorCode.gameUnavailable => HttpStatus.conflict,
    AveluneControlErrorCode.internalFailure => HttpStatus.internalServerError,
  };

  Future<void> _writeJson(
    HttpResponse response,
    int statusCode,
    Map<String, Object?> body,
  ) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }
}
