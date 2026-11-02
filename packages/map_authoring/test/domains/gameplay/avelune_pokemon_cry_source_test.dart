import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

Uint8List wav() {
  final data = Uint8List(108);
  data.setRange(0, 4, ascii.encode('RIFF'));
  data.setRange(8, 16, ascii.encode('WAVEfmt '));
  data.setRange(36, 40, ascii.encode('data'));
  ByteData.sublistView(data)
    ..setUint32(4, data.length - 8, Endian.little)
    ..setUint32(16, 16, Endian.little)
    ..setUint16(20, 1, Endian.little)
    ..setUint16(22, 1, Endian.little)
    ..setUint32(24, 8000, Endian.little)
    ..setUint32(28, 16000, Endian.little)
    ..setUint16(32, 2, Endian.little)
    ..setUint16(34, 16, Endian.little)
    ..setUint32(40, 64, Endian.little);
  data[44] = 1;
  return data;
}

final class CryTransport implements PokemonBoundedExternalHttpTransport {
  CryTransport(this.entries, this.files);
  final List<Map<String, Object?>> entries;
  final Map<String, Uint8List> files;
  final List<String> fetched = [];

  @override
  Future<PokemonExternalHttpResponse> getBounded(Uri uri,
      {required Map<String, String> headers,
      required int maximumBytes,
      required Duration timeout}) async {
    final isList = uri.path.contains('/owners/pokemon/');
    if (!isList) fetched.add(uri.pathSegments.last);
    final bytes = isList
        ? Uint8List.fromList(utf8.encode(jsonEncode(entries)))
        : files[uri.pathSegments.last] ?? Uint8List(0);
    return PokemonExternalHttpResponse(
      statusCode: 200,
      headers: const {},
      body: isList ? utf8.decode(bytes) : '',
      bodyBytes: bytes,
    );
  }
}

Map<String, Object?> entry(
        String id, String form, String style, String mime, Uint8List bytes) =>
    {
      'id': id,
      'sha256': sha256.convert(bytes).toString(),
      'contentType': mime,
      'usage': 'cry',
      'representation': 'audio',
      'style': style,
      'metadata': {'formId': form},
    };

void main() {
  test('selects the default form and prefers latest WAV', () async {
    final sound = wav();
    final mp3 =
        await File('../map_runtime/assets/audio/battle/se/stat_fall_down.mp3')
            .readAsBytes();
    final transport = CryTransport([
      entry('alt-wav', 'deoxys-attack', 'latest', 'audio/wav', sound),
      entry('legacy-wav', 'deoxys-normal', 'legacy', 'audio/wav', sound),
      entry('latest-mp3', 'deoxys-normal', 'latest', 'audio/mpeg', mp3),
      entry(
          'latest-original-wav', 'deoxys-normal', 'latest', 'audio/wav', sound),
      {
        ...entry('latest-wav', 'deoxys-normal', 'latest', 'audio/wav', sound),
        'metadata': {
          'formId': 'deoxys-normal',
          'provenance': {'source': 'avelune/cry-wav'}
        }
      },
    ], {
      'latest-wav': sound
    });
    final source = AvelunePokemonCrySource(
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    );
    final selected =
        await source.fetch(speciesId: 'deoxys', formId: 'deoxys-normal');
    expect(selected?.mediaType, 'audio/wav');
    expect(selected?.bytes, sound);
    expect(transport.fetched, ['latest-wav']);
  });

  test('uses MP3 when no WAV is available and rejects damaged bytes', () async {
    final mp3 =
        await File('../map_runtime/assets/audio/battle/se/stat_fall_down.mp3')
            .readAsBytes();
    final meta = entry('pikachu-mp3', 'pikachu', 'latest', 'audio/mpeg', mp3);
    final transport = CryTransport([meta], {'pikachu-mp3': mp3});
    final source = AvelunePokemonCrySource(
      media: AvelunePokemonMediaSource(client: transport, release: 'test'),
    );
    expect(
        (await source.fetch(speciesId: 'pikachu', formId: 'pikachu'))
            ?.mediaType,
        'audio/mpeg');
    transport.files['pikachu-mp3'] = Uint8List.fromList([1, 2, 3]);
    await expectLater(source.fetch(speciesId: 'pikachu', formId: 'pikachu'),
        throwsFormatException);
  });

  test('does not import Ogg or guess between ambiguous matching cries',
      () async {
    final sound = wav();
    final ogg = entry('pikachu-ogg', 'pikachu', 'latest', 'audio/ogg', sound);
    final first = CryTransport([ogg], {});
    final source = AvelunePokemonCrySource(
        media: AvelunePokemonMediaSource(client: first, release: 'test'));
    expect(await source.fetch(speciesId: 'pikachu', formId: 'pikachu'), isNull);
    final duplicate = CryTransport([
      entry('pikachu-a', 'pikachu', 'latest', 'audio/wav', sound),
      entry('pikachu-b', 'pikachu', 'latest', 'audio/wav', sound),
    ], {});
    final ambiguous = AvelunePokemonCrySource(
        media: AvelunePokemonMediaSource(client: duplicate, release: 'test'));
    await expectLater(ambiguous.fetch(speciesId: 'pikachu', formId: 'pikachu'),
        throwsFormatException);
  });
}
