import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'pokemon_external_http_transport.dart';

final class IoPokemonExternalTransport
    implements PokemonBoundedExternalHttpTransport {
  IoPokemonExternalTransport() : _client = HttpClient();

  final HttpClient _client;

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        maximumBytes <= 0 ||
        timeout <= Duration.zero) {
      throw ArgumentError('Invalid Pokemon media request.');
    }
    final watch = Stopwatch()..start();
    final request = await _client.getUrl(uri).timeout(timeout);
    request.followRedirects = false;
    headers.forEach(request.headers.set);
    final timer = Timer(timeout - watch.elapsed, () {
      request.abort(TimeoutException('Pokemon media request timed out.'));
    });
    try {
      final remaining = timeout - watch.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException('Pokemon media request timed out.');
      }
      final response = await request.close().timeout(remaining);
      if (response.contentLength > maximumBytes) {
        await response.listen(null).cancel();
        throw const FormatException('Response exceeds the byte limit.');
      }
      final bodyTime = timeout - watch.elapsed;
      if (bodyTime <= Duration.zero) {
        throw TimeoutException('Pokemon media request timed out.');
      }
      final bytes = await collectPokemonExternalBytes(response,
          maximumBytes: maximumBytes, timeout: bodyTime);
      final responseHeaders = <String, String>{};
      response.headers
          .forEach((name, values) => responseHeaders[name] = values.join(','));
      final text = response.statusCode >= 200 &&
              response.statusCode < 300 &&
              uri.path.contains('/owners/')
          ? utf8.decode(bytes)
          : '';
      return PokemonExternalHttpResponse(
        statusCode: response.statusCode,
        headers: responseHeaders,
        body: text,
        bodyBytes: bytes,
      );
    } finally {
      timer.cancel();
    }
  }

  void close() => _client.close(force: true);
}
