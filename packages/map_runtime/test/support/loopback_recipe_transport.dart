import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring.dart';

import '../../../../apps/avelune_studio/lib/features/pokemon/data/http_pokemon_external_transport.dart';

final class LoopbackRecipeTransport
    implements PokemonBoundedExternalHttpTransport {
  LoopbackRecipeTransport(String endpoint)
    : _endpoint = Uri.parse(endpoint),
      _client = http.Client() {
    if (_endpoint.scheme != 'http' ||
        _endpoint.host != InternetAddress.loopbackIPv4.address ||
        !_endpoint.hasPort ||
        _endpoint.userInfo.isNotEmpty ||
        _endpoint.hasQuery ||
        _endpoint.hasFragment ||
        !{'', '/'}.contains(_endpoint.path)) {
      _client.close();
      throw ArgumentError.value(endpoint, 'endpoint');
    }
  }

  final Uri _endpoint;
  final http.Client _client;
  final List<Uri> requests = [];

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    if (uri.scheme != 'https' ||
        uri.host != 'recipe-test.invalid' ||
        !uri.path.startsWith('/v1/media/')) {
      throw ArgumentError.value(uri, 'uri');
    }
    final target = _endpoint.replace(
      path: uri.path,
      query: uri.hasQuery ? uri.query : null,
    );
    requests.add(target);
    return HttpPokemonExternalTransport(_client).getBounded(
      target,
      headers: headers,
      maximumBytes: maximumBytes,
      timeout: timeout,
    );
  }

  void close() => _client.close();
}
