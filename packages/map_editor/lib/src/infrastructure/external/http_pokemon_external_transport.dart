import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring.dart';

final class HttpPokemonExternalTransport
    implements
        PokemonExternalHttpTransport,
        PokemonBoundedExternalHttpTransport {
  const HttpPokemonExternalTransport(this.client);

  final http.Client client;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    if (maximumBytes <= 0 || timeout <= Duration.zero) {
      throw ArgumentError('Limits must be positive.');
    }
    final abort = Completer<void>();
    final timer = Timer(timeout, abort.complete);
    final watch = Stopwatch()..start();
    try {
      final request =
          http.AbortableRequest('GET', uri, abortTrigger: abort.future)
            ..followRedirects = false
            ..headers.addAll(headers);
      final response = await client.send(request).timeout(timeout);
      final remaining = timeout - watch.elapsed;
      if (remaining <= Duration.zero ||
          (response.contentLength != null &&
              response.contentLength! > maximumBytes)) {
        await response.stream.listen(null).cancel();
        if (remaining <= Duration.zero) {
          throw TimeoutException('Request timed out.');
        }
        throw const FormatException('Response exceeds the byte limit.');
      }
      final bytes = await collectPokemonExternalBytes(
        response.stream,
        maximumBytes: maximumBytes,
        timeout: remaining,
      );
      final body = (response.headers['content-type'] ?? '').contains('json')
          ? http.Response.bytes(
              bytes,
              response.statusCode,
              headers: response.headers,
            ).body
          : '';
      return PokemonExternalHttpResponse(
        statusCode: response.statusCode,
        headers: response.headers,
        body: body,
        bodyBytes: bytes,
      );
    } finally {
      timer.cancel();
      if (!abort.isCompleted) abort.complete();
    }
  }

  @override
  Future<PokemonExternalHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    final request = http.Request('GET', uri)..headers.addAll(headers);
    final response = await http.Response.fromStream(await client.send(request));
    return PokemonExternalHttpResponse(
      statusCode: response.statusCode,
      headers: response.headers,
      body: response.body,
      bodyBytes: response.bodyBytes,
    );
  }
}
