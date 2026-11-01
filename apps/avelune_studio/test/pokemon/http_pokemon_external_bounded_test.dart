import 'dart:async';

import 'package:avelune_studio/features/pokemon/data/http_pokemon_external_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring.dart';

class _Client extends http.BaseClient {
  _Client({this.contentLength});

  final int? contentLength;
  final controller = StreamController<List<int>>();
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(
      controller.stream,
      200,
      contentLength: contentLength,
    );
  }
}

class _NeverClient extends http.BaseClient {
  final response = Completer<http.StreamedResponse>();
  http.AbortableRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    this.request = request as http.AbortableRequest;
    return response.future;
  }
}

void main() {
  test('bounded transport stops reading oversized responses', () async {
    final client = _Client();
    final transport = HttpPokemonExternalTransport(
      client,
    ) as PokemonBoundedExternalHttpTransport;
    final result = transport.getBounded(
      Uri.https('example.test', '/media'),
      headers: {},
      maximumBytes: 3,
      timeout: const Duration(seconds: 1),
    );
    await Future<void>.delayed(Duration.zero);
    expect(client.request!.followRedirects, isFalse);
    client.controller.add([1, 2]);
    client.controller.add([3, 4]);
    await expectLater(result, throwsFormatException);
    expect(client.controller.hasListener, isFalse);
    await client.controller.close();
    client.close();
  });

  test('bounded transport refuses an oversized declared length', () async {
    final client = _Client(contentLength: 4);
    final transport = HttpPokemonExternalTransport(
      client,
    ) as PokemonBoundedExternalHttpTransport;
    await expectLater(
      transport.getBounded(
        Uri.https('example.test', '/media'),
        headers: {},
        maximumBytes: 3,
        timeout: const Duration(seconds: 1),
      ),
      throwsFormatException,
    );
    expect(client.controller.hasListener, isFalse);
    await client.controller.close();
    client.close();
  });

  test('bounded transport cancels a stalled response', () async {
    final client = _Client();
    final transport = HttpPokemonExternalTransport(
      client,
    ) as PokemonBoundedExternalHttpTransport;
    await expectLater(
      transport.getBounded(
        Uri.https('example.test', '/media'),
        headers: {},
        maximumBytes: 3,
        timeout: const Duration(milliseconds: 30),
      ),
      throwsA(isA<TimeoutException>()),
    );
    expect(client.controller.hasListener, isFalse);
    await client.controller.close();
    client.close();
  });

  test('bounded transport aborts when response headers never arrive', () async {
    final client = _NeverClient();
    final transport = HttpPokemonExternalTransport(
      client,
    ) as PokemonBoundedExternalHttpTransport;
    await expectLater(
      transport.getBounded(
        Uri.https('example.test', '/media'),
        headers: {},
        maximumBytes: 3,
        timeout: const Duration(milliseconds: 30),
      ),
      throwsA(isA<TimeoutException>()),
    );
    await client.request!.abortTrigger!.timeout(const Duration(seconds: 1));
    client.close();
  });
}
