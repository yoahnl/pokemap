import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

const _revision = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

Map<String, Object?> _document() {
  const names = [
    'front.png',
    'back.png',
    'front_animations.nanr.lz11',
    'back_animations.nanr.lz11',
    'front_cells.ncer',
    'back_cells.ncer',
    'front_multi_cells.nmcr',
    'back_multi_cells.nmcr',
    'front_multi_animations.nmar',
    'back_multi_animations.nmar',
    'front_info.bin',
    'back_info.bin',
    'normal.pal',
    'shiny.pal',
  ];
  final assets = <String, Object?>{};
  for (var i = 0; i < names.length; i++) {
    final bytes = [i + 1, 255 - i];
    assets[names[i]] = {
      'encoding': 'base64',
      'size': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
      'data': base64.encode(bytes),
    };
  }
  return {
    'format': 'gen5-battle-source-v1',
    'game': 'black2-white2',
    'scope': 'default-form',
    'species': 'oshawott',
    'nationalDex': 501,
    'reconstruction': 'not-yet-validated',
    'source': {
      'repository': 'fuddlesworth/pokebw2',
      'revision': _revision,
      'directory': 'res/pokemon/oshawott',
      'redistributionStatus': 'unverified',
    },
    'assets': assets,
  };
}

final class _Transport implements PokemonBoundedExternalHttpTransport {
  Map<String, Object?> document = _document();
  int status = 200;
  String revision = _revision;
  String revisionHeader = 'x-source-revision';
  Uint8List? overrideBytes;
  Uri? uri;
  int? requestedMaximum;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    this.uri = uri;
    requestedMaximum = maximumBytes;
    final bytes =
        overrideBytes ?? Uint8List.fromList(utf8.encode(jsonEncode(document)));
    return PokemonExternalHttpResponse(
      statusCode: status,
      headers: {revisionHeader: revision},
      body: '',
      bodyBytes: bytes,
    );
  }
}

void main() {
  test('loads and verifies an immutable source for the requested species',
      () async {
    final transport = _Transport()..revisionHeader = 'X-Source-Revision';
    final source = AveluneGen5BattleSource(client: transport);
    final record = await source.fetch(species: 'oshawott', nationalDex: 501);
    expect(transport.uri!.path, '/v1/snapshots/public-2026-11/gen5-battle/501');
    expect(transport.requestedMaximum, 20 * 1024 * 1024);
    expect(record!.species, 'oshawott');
    expect(record.nationalDex, 501);
    expect(record.sourceRepository, 'fuddlesworth/pokebw2');
    expect(record.sourceRevision, _revision);
    expect(record.sourceDirectory, 'res/pokemon/oshawott');
    expect(record.reconstruction, 'not-yet-validated');
    expect(record.redistributionStatus, 'unverified');
    expect(record.assets.length, 14);
    expect(record.assets['front.png'], [1, 255]);
    expect(() => record.assets['front.png']![0] = 0, throwsUnsupportedError);
    expect(() => record.assets.clear(), throwsUnsupportedError);
  });

  test('returns unavailable for a missing published source', () async {
    final transport = _Transport()..status = 404;
    final result = await AveluneGen5BattleSource(client: transport).fetch(
      species: 'oshawott',
      nationalDex: 501,
    );
    expect(result, isNull);
  });

  test('keeps an explicitly selected older catalog release', () async {
    final transport = _Transport();
    final source = AveluneGen5BattleSource(
      client: transport,
      release: 'public-2026-10',
    );
    final record = await source.fetch(species: 'oshawott', nationalDex: 501);
    expect(transport.uri!.path, '/v1/snapshots/public-2026-10/gen5-battle/501');
    expect(record!.release, 'public-2026-10');
  });

  test('rejects identity, provenance and asset integrity mismatches', () async {
    final transport = _Transport();
    final source = AveluneGen5BattleSource(client: transport);
    Future<void> rejected() => expectLater(
          source.fetch(species: 'oshawott', nationalDex: 501),
          throwsFormatException,
        );
    transport.document['species'] = 'tepig';
    await rejected();
    transport.document = _document()..['nationalDex'] = 500;
    await rejected();
    transport.document = _document();
    transport.revision = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    await rejected();
    transport.revision = _revision;
    final assets = transport.document['assets']! as Map<String, Object?>;
    (assets['front.png']! as Map<String, Object?>)['data'] = 'AQA=';
    await rejected();
    transport.document = _document();
    final another = transport.document['assets']! as Map<String, Object?>;
    (another['front.png']! as Map<String, Object?>)['data'] = 'Af9=';
    await rejected();
    transport.document = _document();
    final oversized = transport.document['assets']! as Map<String, Object?>;
    (oversized['front.png']! as Map<String, Object?>)['size'] = 1048577;
    await rejected();
    transport.document = _document();
    (transport.document['source']! as Map<String, Object?>)['directory'] =
        '../other';
    await rejected();
    transport.document = _document();
    (transport.document['assets']! as Map<String, Object?>).remove('back.png');
    await rejected();
  });

  test('rejects invalid requests and responses exceeding the configured bound',
      () async {
    final transport = _Transport();
    final source =
        AveluneGen5BattleSource(client: transport, maximumBytes: 512);
    expect(
        () => AveluneGen5BattleSource(
            client: transport, baseUri: 'http://example.test'),
        throwsArgumentError);
    await expectLater(source.fetch(species: '../oshawott', nationalDex: 501),
        throwsArgumentError);
    await expectLater(source.fetch(species: 'oshawott', nationalDex: 650),
        throwsArgumentError);
    await expectLater(source.fetch(species: 'oshawott', nationalDex: 501),
        throwsFormatException);
    transport.status = 503;
    await expectLater(source.fetch(species: 'oshawott', nationalDex: 501),
        throwsA(isA<Exception>()));
  });
}
