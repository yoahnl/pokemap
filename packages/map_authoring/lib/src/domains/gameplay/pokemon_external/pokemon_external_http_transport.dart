import 'dart:async';
import 'dart:typed_data';

Future<Uint8List> collectPokemonExternalBytes(
  Stream<List<int>> stream, {
  required int maximumBytes,
  required Duration timeout,
}) async {
  if (maximumBytes <= 0 || timeout <= Duration.zero) {
    throw ArgumentError('Limits must be positive.');
  }
  final iterator = StreamIterator<List<int>>(stream);
  final watch = Stopwatch()..start();
  final buffer = BytesBuilder(copy: false);
  try {
    while (true) {
      final remaining = timeout - watch.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException('Stream timed out.');
      }
      if (!await iterator.moveNext().timeout(remaining)) break;
      final chunk = iterator.current;
      if (buffer.length + chunk.length > maximumBytes) {
        throw const FormatException('Response exceeds the byte limit.');
      }
      buffer.add(chunk);
    }
    return buffer.takeBytes();
  } finally {
    await iterator.cancel();
  }
}

abstract interface class PokemonBoundedExternalHttpTransport {
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  });
}

abstract interface class PokemonExternalHttpTransport {
  Future<PokemonExternalHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  });
}

final class PokemonExternalHttpResponse {
  const PokemonExternalHttpResponse({
    required this.statusCode,
    required this.headers,
    required this.body,
    required this.bodyBytes,
  });

  final int statusCode;
  final Map<String, String> headers;
  final String body;
  final Uint8List bodyBytes;
}
