import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring.dart';

final class HttpPokemonExternalTransport
    implements PokemonExternalHttpTransport {
  const HttpPokemonExternalTransport(this.client);

  final http.Client client;

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
