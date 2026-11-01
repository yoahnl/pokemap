import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const _release = 'public-2026-11';

Map<String, Object?> _asset(String path, List<int> bytes) => {
      'path': path,
      'size': bytes.length,
      'sha256': sha256.convert(bytes).toString(),
      'encoding': 'base64',
      'data': base64.encode(bytes),
    };

Map<String, Object?> _document() {
  final script = utf8.encode('''ScriptHeader 1
ScriptVariant Demo
Demo:
ParticleLoad 218
EmitterMove 218, 0, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 4096, 4096, 0
PlaySE SEQ_EXAMPLE, 1, EFFVM_ATTACKER, 0, 0, 100, 0, 0, 0
End
''');
  var definition = jsonEncode({
    'emitters': [
      {
        'texture': 'texture00',
        'textureAnim': {
          'textures': ['texture01']
        },
      },
    ],
    'textures': [
      {'name': 'texture00', 'format': 'a5i3'},
      {'name': 'texture01', 'format': 'a3i5'},
    ],
  });
  while (utf8.encode(definition).length % 3 != 1) {
    definition += ' ';
  }
  final png = image.encodePng(image.Image(width: 2, height: 2));
  return {
    'release': _release,
    'format': 'gen5-move-source-v1',
    'game': 'black2-white2',
    'move': {'id': 'flamethrower', 'sourceId': 53},
    'source': {
      'repository': 'fuddlesworth/pokebw2',
      'revision': _revision,
      'redistributionStatus': 'unverified',
    },
    'completeness': {
      'audio': 'missing-sequences-banks-and-commands',
      'playback': 'not-supported',
    },
    'script': _asset('res/battle/animations/moves/flamethrower.s', script),
    'particles': [
      {
        'id': 218,
        'definition': _asset(
          'res/particles/btlv_effvm_particles/218/particles.json',
          utf8.encode(definition),
        ),
        'textures': [
          for (final name in ['texture00', 'texture01'])
            {
              'name': name,
              ..._asset(
                  'res/particles/btlv_effvm_particles/218/$name.png', png),
            },
        ],
      },
    ],
  };
}

final class _Transport implements PokemonBoundedExternalHttpTransport {
  Map<String, Object?> document = _document();
  Uint8List? overrideBytes;
  int status = 200;
  Map<String, String> responseHeaders = {'x-source-revision': _revision};
  Uri? uri;
  int? maximum;

  @override
  Future<PokemonExternalHttpResponse> getBounded(
    Uri uri, {
    required Map<String, String> headers,
    required int maximumBytes,
    required Duration timeout,
  }) async {
    this.uri = uri;
    maximum = maximumBytes;
    return PokemonExternalHttpResponse(
      statusCode: status,
      headers: responseHeaders,
      body: '',
      bodyBytes: overrideBytes ??
          Uint8List.fromList(utf8.encode(jsonEncode(document))),
    );
  }
}

void main() {
  test('loads a bounded snapshot and diagnoses its verified dependencies',
      () async {
    final transport = _Transport();
    final source = AveluneGen5MoveSource(client: transport);
    final snapshot =
        await source.fetch(moveId: 'flamethrower', sourceMoveId: 53);

    expect(transport.uri!.path, '/v1/snapshots/$_release/gen5-move/53');
    expect(transport.maximum, 2 * 1024 * 1024);
    expect(snapshot!.moveId, 'flamethrower');
    expect(snapshot.sourceMoveId, 53);
    expect(snapshot.sourceRevision, _revision);
    expect(snapshot.redistributionStatus, 'unverified');
    expect(snapshot.audioStatus, 'missing-sequences-banks-and-commands');
    expect(snapshot.playbackStatus, 'not-supported');
    expect(snapshot.diagnostic.emitterOrder, [0]);
    expect(snapshot.diagnostic.requiredTextures, {'texture00', 'texture01'});
    expect(snapshot.diagnostic.missingTextures, isEmpty);
    expect(snapshot.diagnostic.soundReferences, ['SEQ_EXAMPLE']);
    expect(snapshot.diagnostic.requireConvertible, throwsStateError);
    expect(() => snapshot.scriptBytes[0] = 0, throwsUnsupportedError);
    expect(() => snapshot.scriptBytes.buffer.asUint8List()[0] = 0,
        throwsUnsupportedError);
    expect(() => snapshot.particleBytes[0] = 0, throwsUnsupportedError);
    expect(() => snapshot.textureBytes['texture00']![0] = 0,
        throwsUnsupportedError);
    expect(() => snapshot.textureBytes.clear(), throwsUnsupportedError);
  });

  test('returns no snapshot on 404 and rejects invalid requests', () async {
    final transport = _Transport()..status = 404;
    final source = AveluneGen5MoveSource(client: transport);
    expect(
        await source.fetch(moveId: 'flamethrower', sourceMoveId: 53), isNull);
    transport.status = 503;
    await expectLater(
      source.fetch(moveId: 'flamethrower', sourceMoveId: 53),
      throwsA(isA<Exception>()),
    );
    await expectLater(source.fetch(moveId: '../other', sourceMoveId: 53),
        throwsArgumentError);
    await expectLater(source.fetch(moveId: 'flamethrower', sourceMoveId: 0),
        throwsArgumentError);
    expect(
        () => AveluneGen5MoveSource(
            client: transport, baseUri: 'http://example.test'),
        throwsArgumentError);
  });

  test('rejects a snapshot that omits a required texture', () async {
    final transport = _Transport();
    final particle = (transport.document['particles']! as List).single
        as Map<String, Object?>;
    (particle['textures']! as List).removeLast();
    await expectLater(
      AveluneGen5MoveSource(client: transport)
          .fetch(moveId: 'flamethrower', sourceMoveId: 53),
      throwsFormatException,
    );
  });

  test('rejects mismatched release, move identity and source metadata',
      () async {
    final transport = _Transport();
    final source = AveluneGen5MoveSource(client: transport);
    Future<void> reject() => expectLater(
          source.fetch(moveId: 'flamethrower', sourceMoveId: 53),
          throwsFormatException,
        );
    transport.document['release'] = 'another-release';
    await reject();
    transport.document = _document();
    (transport.document['move']! as Map<String, Object?>)['sourceId'] = 54;
    await reject();
    transport.document = _document();
    (transport.document['move']! as Map<String, Object?>)['id'] = 'another';
    await reject();
    transport.document = _document();
    (transport.document['source']! as Map<String, Object?>)['revision'] =
        '0' * 40;
    await reject();
    transport.document = _document();
    (transport.document['completeness']! as Map<String, Object?>)['playback'] =
        'supported';
    await reject();
    transport.document = _document();
    transport.responseHeaders = {
      'x-source-revision': _revision,
      'X-Source-Revision': _revision
    };
    await reject();
  });

  test('rejects mutated data, paths, duplicate names and noncanonical base64',
      () async {
    final transport = _Transport();
    final source = AveluneGen5MoveSource(client: transport);
    Future<void> reject() => expectLater(
          source.fetch(moveId: 'flamethrower', sourceMoveId: 53),
          throwsFormatException,
        );
    var script = transport.document['script']! as Map<String, Object?>;
    script['sha256'] = '0' * 64;
    await reject();
    transport.document = _document();
    script = transport.document['script']! as Map<String, Object?>;
    script['path'] = 'res/battle/animations/moves/../other.s';
    await reject();
    transport.document = _document();
    var particle = (transport.document['particles']! as List).single
        as Map<String, Object?>;
    var textures = particle['textures']! as List;
    (textures[1] as Map<String, Object?>)['name'] = 'texture00';
    await reject();
    transport.document = _document();
    particle = (transport.document['particles']! as List).single
        as Map<String, Object?>;
    final definition = particle['definition']! as Map<String, Object?>;
    final encoded = definition['data']! as String;
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final index = encoded.indexOf('=') - 1;
    final alternate = alphabet[alphabet.indexOf(encoded[index]) + 1];
    definition['data'] =
        encoded.substring(0, index) + alternate + encoded.substring(index + 1);
    await reject();
  });

  test('rejects duplicate JSON and response or decoded-byte budget excess',
      () async {
    final transport = _Transport();
    final source = AveluneGen5MoveSource(client: transport);
    transport.overrideBytes =
        Uint8List.fromList(utf8.encode('{"release":"x","release":"y"}'));
    await expectLater(source.fetch(moveId: 'flamethrower', sourceMoveId: 53),
        throwsFormatException);
    transport.overrideBytes = Uint8List(2 * 1024 * 1024 + 1);
    await expectLater(source.fetch(moveId: 'flamethrower', sourceMoveId: 53),
        throwsFormatException);
    transport.overrideBytes = null;
    final particle = (transport.document['particles']! as List).single
        as Map<String, Object?>;
    final textures = particle['textures']! as List;
    for (final raw in textures) {
      final entry = raw as Map<String, Object?>;
      final name = entry['name'] as String;
      entry.addAll(_asset('res/particles/btlv_effvm_particles/218/$name.png',
          Uint8List(600000)));
    }
    await expectLater(source.fetch(moveId: 'flamethrower', sourceMoveId: 53),
        throwsFormatException);
  });
}
