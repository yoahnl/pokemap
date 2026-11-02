import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

final class _Transport implements PokemonBoundedExternalHttpTransport {
  final requests = <Uri>[];
  final bounds = <int>[];
  Uint8List gif =
      base64Decode('R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw==');
  Map<String, Object?> species = {
    'id': 386,
    'name': 'deoxys',
    'varieties': [
      {
        'is_default': false,
        'pokemon': {'name': 'deoxys-attack'}
      },
      {
        'is_default': true,
        'pokemon': {'name': 'deoxys-normal'}
      },
    ],
  };
  bool duplicate = false;
  bool corrupt = false;
  bool invalidGif = false;
  bool missingBack = false;
  bool wrongDimensions = false;

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    requests.add(uri);
    bounds.add(maximumBytes);
    Object? data;
    if (uri.path.contains('/pokemon-species/')) {
      data = species;
    } else if (uri.path.contains('/owners/pokemon/')) {
      Map<String, Object?> entry(String id, String form, String view,
              {bool shiny = false, String? gender}) =>
          {
            'id': id,
            'sha256': sha256.convert(invalidGif ? [1, 2, 3] : gif).toString(),
            'contentType': 'image/gif',
            'usage': 'battle',
            'representation': 'sprite2d',
            'style': 'gen5',
            'metadata': {
              'formId': form,
              'view': view,
              if (wrongDimensions) 'width': 2,
              if (shiny) 'shiny': true,
              if (gender != null) 'gender': gender,
            },
          };
      data = [
        entry('normal-front', 'deoxys-normal', 'front'),
        if (!missingBack) entry('normal-back', 'deoxys-normal', 'back'),
        entry('shiny-front', 'deoxys-normal', 'front', shiny: true),
        entry('shiny-back', 'deoxys-normal', 'back', shiny: true),
        entry('other-form', 'deoxys-attack', 'front'),
        entry('female-front', 'deoxys-normal', 'front', gender: 'female'),
        if (duplicate) entry('duplicate-front', 'deoxys-normal', 'front'),
      ];
    }
    final bytes = data == null
        ? Uint8List.fromList(corrupt
            ? [9]
            : invalidGif
                ? [1, 2, 3]
                : gif)
        : Uint8List.fromList(utf8.encode(jsonEncode(data)));
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: data == null ? '' : utf8.decode(bytes),
      bodyBytes: bytes,
    );
  }
}

void main() {
  test('loads the four validated GIFs for the actual default form', () async {
    final transport = _Transport();
    final result = await AveluneBattleGifSource(client: transport)
        .fetch(speciesId: 'deoxys', nationalDex: 386);
    expect(result.speciesId, 'deoxys');
    expect(result.defaultFormId, 'deoxys-normal');
    expect(result.media.keys.toSet(), PokemonBattleGifRole.values.toSet());
    expect(result.missing, isEmpty);
    expect(
        result.media.values
            .every((item) => item.bytes.length == transport.gif.length),
        isTrue);
    expect(
        () => result.media.values.first.bytes[0] = 0, throwsUnsupportedError);
    expect(transport.requests.where((uri) => uri.path.endsWith('other-form')),
        isEmpty);
    expect(transport.requests.where((uri) => uri.path.endsWith('female-front')),
        isEmpty);
    expect(
        transport.requests
            .where((uri) => uri.path.contains('/owners/pokemon/deoxys')),
        hasLength(1));
  });

  test('downloads only the missing roles requested by the caller', () async {
    final transport = _Transport();
    final result = await AveluneBattleGifSource(client: transport).fetch(
      speciesId: 'deoxys',
      nationalDex: 386,
      roles: {
        PokemonBattleGifRole.backAnimated,
        PokemonBattleGifRole.frontShinyAnimated
      },
    );
    expect(result.media.keys.toSet(), {
      PokemonBattleGifRole.backAnimated,
      PokemonBattleGifRole.frontShinyAnimated
    });
    expect(
        transport.requests.where((uri) => uri.path.endsWith('/normal-front')),
        isEmpty);
    expect(transport.requests.where((uri) => uri.path.endsWith('/shiny-back')),
        isEmpty);
  });

  test('reports unavailable roles without fabricating a substitute', () async {
    final result =
        await AveluneBattleGifSource(client: _Transport()..missingBack = true)
            .fetch(speciesId: 'deoxys', nationalDex: 386);
    expect(result.media, hasLength(3));
    expect(result.missing, {PokemonBattleGifRole.backAnimated});
  });

  test('rejects ambiguous species and media identities', () async {
    final transport = _Transport();
    final source = AveluneBattleGifSource(client: transport);
    transport.species['id'] = 25;
    await expectLater(source.fetch(speciesId: 'deoxys', nationalDex: 386),
        throwsFormatException);
    transport.species['id'] = 386;
    transport.species['name'] = 'another-species';
    await expectLater(source.fetch(speciesId: 'deoxys', nationalDex: 386),
        throwsFormatException);
    transport.species['name'] = 'deoxys';
    (transport.species['varieties'] as List).add({
      'is_default': true,
      'pokemon': {'name': 'deoxys-attack'}
    });
    await expectLater(source.fetch(speciesId: 'deoxys', nationalDex: 386),
        throwsFormatException);
    (transport.species['varieties'] as List).removeLast();
    transport.duplicate = true;
    await expectLater(source.fetch(speciesId: 'deoxys', nationalDex: 386),
        throwsFormatException);
  });

  test('rejects corrupt hashes and structurally invalid GIFs', () async {
    final transport = _Transport()..corrupt = true;
    final source = AveluneBattleGifSource(client: transport);
    await expectLater(source.fetch(speciesId: 'deoxys', nationalDex: 386),
        throwsFormatException);
    transport.corrupt = false;
    transport.invalidGif = true;
    await expectLater(source.fetch(speciesId: 'deoxys', nationalDex: 386),
        throwsFormatException);
    transport.invalidGif = false;
    transport.wrongDimensions = true;
    await expectLater(source.fetch(speciesId: 'deoxys', nationalDex: 386),
        throwsFormatException);
  });

  test('accepts GIFs above 256 frames within the export memory limit',
      () async {
    final transport = _Transport();
    final bytes = transport.gif;
    final start = bytes.indexOf(0x2c);
    expect(start, greaterThan(0));
    final frame = bytes.sublist(start, bytes.length - 1);
    transport.gif = Uint8List.fromList([
      ...bytes.sublist(0, start),
      for (var i = 0; i < 338; i++) ...frame,
      0x3b,
    ]);
    final result = await AveluneBattleGifSource(client: transport).fetch(
      speciesId: 'deoxys',
      nationalDex: 386,
      roles: {PokemonBattleGifRole.frontAnimated},
    );
    expect(result.media, hasLength(1));
    transport.gif = Uint8List.fromList([
      ...bytes.sublist(0, start),
      for (var i = 0; i < 501; i++) ...frame,
      0x3b,
    ]);
    await expectLater(
      AveluneBattleGifSource(client: transport).fetch(
        speciesId: 'deoxys',
        nationalDex: 386,
        roles: {PokemonBattleGifRole.frontAnimated},
      ),
      throwsFormatException,
    );
  });

  test('uses the same explicitly selected release for species and media',
      () async {
    final transport = _Transport();
    final result = await AveluneBattleGifSource(
      client: transport,
      release: 'public-2026-10',
    ).fetch(speciesId: 'deoxys', nationalDex: 386);
    expect(
        result.media.values.every((item) => item.release == 'public-2026-10'),
        isTrue);
    expect(
        transport.requests.every((uri) => uri.path.contains('public-2026-10')),
        isTrue);
    expect(
      () => AveluneBattleGifSource(
          client: transport,
          release: 'public-2026-10',
          compatBaseUri:
              'https://pokemon-api.yoahn.me/v1/compat/public-2026-11/pokeapi'),
      throwsArgumentError,
    );
  });

  test('resolves species aliases through their national number', () async {
    final transport = _Transport();
    transport.species = {
      'id': 122,
      'name': 'mr-mime',
      'varieties': [
        {
          'is_default': true,
          'pokemon': {'name': 'mr-mime'}
        },
      ],
    };
    final result = await AveluneBattleGifSource(client: transport).fetch(
      speciesId: 'mrmime',
      nationalDex: 122,
      roles: {},
    );
    expect(result.speciesId, 'mr-mime');
    expect(transport.requests.first.path, endsWith('/pokemon-species/122'));
    expect(transport.requests[1].path, endsWith('/owners/pokemon/mr-mime'));
  });
}
