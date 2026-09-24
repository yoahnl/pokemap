import 'dart:typed_data';

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
