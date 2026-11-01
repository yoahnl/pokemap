import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

final class _Transport
    implements
        PokemonExternalHttpTransport,
        PokemonBoundedExternalHttpTransport {
  final urls = <Uri>[];
  final bounds = <int>[];
  final bytes = Uint8List.fromList([1, 2, 3]);
  bool corrupt = false;

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) {
    bounds.add(maximumBytes);
    return get(uri, headers: headers);
  }

  @override
  Future<PokemonExternalHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    urls.add(uri);
    final body = uri.path.endsWith('/owners/pokemon/bulbasaur')
        ? jsonEncode([
            if (uri.queryParameters['after'] == null)
              {
                'id': 'bulbasaur-gen5-front-animated',
                'sha256': sha256.convert(bytes).toString(),
                'contentType': 'image/gif',
                'usage': 'battle',
                'representation': 'sprite2d',
                'style': 'gen5',
                'metadata': {'formId': 'bulbasaur', 'view': 'front'},
              },
          ])
        : '';
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: body,
      bodyBytes: body.isNotEmpty
          ? Uint8List.fromList(utf8.encode(body))
          : corrupt
              ? Uint8List.fromList([9])
              : bytes,
    );
  }
}

final class _PagedTransport
    implements
        PokemonExternalHttpTransport,
        PokemonBoundedExternalHttpTransport {
  final requests = <Uri>[];
  bool repeat = false;

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
          {required Map<String, String> headers,
          required int maximumBytes,
          required Duration timeout}) =>
      get(uri, headers: headers);

  @override
  Future<PokemonExternalHttpResponse> get(
    Uri uri, {
    required Map<String, String> headers,
  }) async {
    requests.add(uri);
    final after = uri.queryParameters['after'];
    final start = after == null || repeat ? 0 : 100;
    final count = start == 0 ? 100 : 1;
    final body = jsonEncode([
      for (var i = start; i < start + count; i++)
        {
          'id': 'media-${i.toString().padLeft(3, '0')}',
          'sha256': 'a' * 64,
          'contentType': 'image/png',
          'usage': 'menu',
          'representation': 'sprite2d',
          'style': 'gen5',
          'metadata': <String, Object?>{},
        },
    ]);
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: body,
      bodyBytes: Uint8List.fromList(utf8.encode(body)),
    );
  }
}

void main() {
  test('published media are enumerated and downloaded with verified digest',
      () async {
    final transport = _Transport();
    final source = AvelunePokemonMediaSource(client: transport);
    final entries = await source.listPokemonMedia('bulbasaur');
    expect(entries, hasLength(1));
    expect(entries.single.contentType, 'image/gif');
    expect(entries.single.metadata['formId'], 'bulbasaur');
    expect(await source.readMedia(entries.single), transport.bytes);
    expect(transport.bounds, [8 * 1024 * 1024, 64 * 1024 * 1024]);
    expect(
        transport.urls
            .every((uri) => uri.origin == 'https://pokemon-api.yoahn.me'),
        isTrue);
    expect(transport.urls.last.path,
        '/v1/media/public-2026-10/bulbasaur-gen5-front-animated');

    transport.corrupt = true;
    await expectLater(source.readMedia(entries.single), throwsFormatException);
    await expectLater(
        source.listPokemonMedia('../bulbasaur'), throwsArgumentError);
  });

  test('pagination retrieves all pages and rejects a repeated page', () async {
    final transport = _PagedTransport();
    final source = AvelunePokemonMediaSource(client: transport);
    final entries = await source.listPokemonMedia('bulbasaur');
    expect(entries, hasLength(101));
    expect(entries.last.id, 'media-100');
    expect(transport.requests[1].queryParameters['after'], 'media-099');
    transport.repeat = true;
    await expectLater(
        source.listPokemonMedia('bulbasaur'), throwsFormatException);
  });
}
