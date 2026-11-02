import 'dart:convert';
import 'dart:io';
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

Map<String, Object?> _v2Document({
  String status = 'complete',
  List<int> missingParticleIds = const [],
  List<Map<String, Object?>> missingTextures = const [],
}) {
  final document = _document();
  document['format'] = 'gen5-move-source-v2';
  document['completeness'] = {
    'audio': 'missing-sequences-banks-and-commands',
    'playback': 'not-supported',
    'dependencies': {
      'status': status,
      'missingParticleIds': missingParticleIds,
      'missingTextures': missingTextures,
    },
  };
  return document;
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

  test('loads expanded BW2 script commands without claiming playback',
      () async {
    final transport = _Transport();
    final script = utf8.encode('''ScriptHeader 1
ScriptVariant Demo
Demo:
ParticleLoad 218
EmitterMove 218, 0, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 4096, 4096, 0
McssSetVanish EFFVM_DEFENDER, TRUE
McssScale EFFVM_DEFENDER, 2, 0x19a, -0x19a, 2, 0, 1
Wait EFFVM_WAIT_PARTICLES
Wait EFFVM_WAIT_SE
McssSetVanish EFFVM_DEFENDER, FALSE
End
.balign 4
''');
    transport.document['script'] =
        _asset('res/battle/animations/moves/flamethrower.s', script);
    final snapshot = await AveluneGen5MoveSource(client: transport)
        .fetch(moveId: 'flamethrower', sourceMoveId: 53);

    expect(snapshot!.playbackStatus, 'not-supported');
    expect(snapshot.diagnostic.emitterOrder, [0]);
    expect(
        snapshot.diagnostic.blockers,
        containsAll({
          Gen5BattleSourceBlocker.combatantVisualState,
          Gen5BattleSourceBlocker.soundPlayback,
          Gen5BattleSourceBlocker.soundAutomation,
          Gen5BattleSourceBlocker.recipeConverter,
        }));
    expect(snapshot.diagnostic.requireConvertible, throwsStateError);
  });

  test('loads a v2 source with no particle dependency', () async {
    final transport = _Transport()..document = _v2Document();
    transport.document['particles'] = <Object?>[];
    transport.document['script'] = _asset(
      'res/battle/animations/moves/flamethrower.s',
      utf8.encode('ScriptHeader 1\nScriptVariant Demo\nDemo:\nEnd\n'),
    );
    final snapshot = (await AveluneGen5MoveSource(client: transport)
        .fetch(moveId: 'flamethrower', sourceMoveId: 53))!;

    expect(snapshot.reportedDependencyStatus, 'complete');
    expect(snapshot.effectiveDependencyStatus, 'complete');
    expect(snapshot.particleDependencyInventoryVerified, isTrue);
    expect(snapshot.particles, isEmpty);
    expect(snapshot.missingParticleIds, isEmpty);
    expect(snapshot.missingTextures, isEmpty);
    expect(snapshot.playbackStatus, 'not-supported');
    expect(() => snapshot.particleBytes, throwsStateError);
    expect(() => snapshot.diagnostic, throwsStateError);
  });

  test('loads several v2 particles and preserves explicit missing resources',
      () async {
    final transport = _Transport()
      ..document = _v2Document(
        status: 'partial',
        missingParticleIds: [222],
        missingTextures: [
          {'particleId': 219, 'name': 'texture01'},
        ],
      );
    final particles = <Object?>[...transport.document['particles']! as List];
    transport.document['particles'] = particles;
    final second = (jsonDecode(jsonEncode(particles.single)) as Map)
        .cast<String, dynamic>();
    second['id'] = 219;
    final definition = (second['definition'] as Map).cast<String, dynamic>();
    definition['path'] =
        'res/particles/btlv_effvm_particles/219/particles.json';
    final textures = second['textures'] as List;
    textures.removeLast();
    for (final raw in textures) {
      final entry = (raw as Map).cast<String, dynamic>();
      entry['path'] =
          'res/particles/btlv_effvm_particles/219/${entry['name']}.png';
    }
    particles.add(second);
    transport.document['script'] = _asset(
      'res/battle/animations/moves/flamethrower.s',
      utf8.encode('''ScriptHeader 1
ScriptVariant Demo
Demo:
ParticleLoad 218
EmitterAdd 218, 0, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0, 4096, 4096, 4096, 4096
ParticleLoad 219
EmitterAdd 219, 0, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0, 4096, 4096, 4096, 4096
ParticleLoad 222
End
'''),
    );
    final snapshot = (await AveluneGen5MoveSource(client: transport)
        .fetch(moveId: 'flamethrower', sourceMoveId: 53))!;

    expect(snapshot.reportedDependencyStatus, 'partial');
    expect(snapshot.effectiveDependencyStatus, 'partial');
    expect(snapshot.particleDependencyInventoryVerified, isTrue);
    expect(snapshot.particles.keys, [218, 219]);
    expect(snapshot.missingParticleIds, [222]);
    expect(snapshot.missingTextures, [
      (particleId: 219, name: 'texture01'),
    ]);
    expect(snapshot.playbackStatus, 'not-supported');
    expect(() => snapshot.particleBytes, throwsStateError);
    expect(() => snapshot.diagnostic, throwsStateError);
    expect(() => snapshot.particles.clear(), throwsUnsupportedError);
    expect(() => snapshot.particles[218]!.definitionBytes[0] = 0,
        throwsUnsupportedError);
    expect(() => snapshot.particles[219]!.textureBytes.clear(),
        throwsUnsupportedError);
  });

  test('keeps unknown v2 dependencies distinct from complete', () async {
    final transport = _Transport()..document = _v2Document(status: 'unknown');
    transport.document['particles'] = <Object?>[];
    final snapshot = (await AveluneGen5MoveSource(client: transport)
        .fetch(moveId: 'flamethrower', sourceMoveId: 53))!;
    expect(snapshot.reportedDependencyStatus, 'unknown');
    expect(snapshot.effectiveDependencyStatus, 'unknown');
    expect(snapshot.particleDependencyInventoryVerified, isFalse);
    expect(snapshot.particles, isEmpty);
    expect(snapshot.playbackStatus, 'not-supported');
  });

  test('does not trust complete v2 dependencies for an unsupported script',
      () async {
    final transport = _Transport()..document = _v2Document();
    transport.document['particles'] = <Object?>[];
    transport.document['script'] = _asset(
      'res/battle/animations/moves/flamethrower.s',
      utf8.encode(
          'ScriptHeader 1\nScriptVariant Demo\nDemo:\nFutureCommand 1\nEnd\n'),
    );
    final snapshot = (await AveluneGen5MoveSource(client: transport)
        .fetch(moveId: 'flamethrower', sourceMoveId: 53))!;
    expect(snapshot.reportedDependencyStatus, 'complete');
    expect(snapshot.effectiveDependencyStatus, 'unknown');
    expect(snapshot.particleDependencyInventoryVerified, isFalse);
    expect(snapshot.playbackStatus, 'not-supported');
    expect(() => snapshot.diagnostic, throwsStateError);
  });

  test('does not verify v2 dependency semantics for an unknown revision',
      () async {
    final transport = _Transport()..document = _v2Document();
    final source =
        (transport.document['source']! as Map).cast<String, Object?>();
    source['revision'] = '0' * 40;
    transport.responseHeaders = {'x-source-revision': '0' * 40};
    transport.document['particles'] = <Object?>[];
    transport.document['script'] = _asset(
      'res/battle/animations/moves/flamethrower.s',
      utf8.encode('ScriptHeader 1\nScriptVariant Demo\nDemo:\nEnd\n'),
    );
    final snapshot = (await AveluneGen5MoveSource(client: transport)
        .fetch(moveId: 'flamethrower', sourceMoveId: 53))!;
    expect(snapshot.reportedDependencyStatus, 'complete');
    expect(snapshot.effectiveDependencyStatus, 'unknown');
    expect(snapshot.particleDependencyInventoryVerified, isFalse);
  });

  test('rejects contradictory v2 dependency reports', () async {
    final cases = [
      _v2Document(status: 'complete', missingParticleIds: [222]),
      _v2Document(status: 'partial'),
      _v2Document(status: 'partial', missingParticleIds: [222, 222]),
      _v2Document(status: 'partial', missingParticleIds: [223, 222]),
      _v2Document(status: 'partial', missingParticleIds: [218]),
      _v2Document(status: 'partial', missingTextures: [
        {'particleId': 218, 'name': 'texture00'},
      ]),
    ];
    for (final document in cases) {
      final transport = _Transport()..document = document;
      await expectLater(
        AveluneGen5MoveSource(client: transport)
            .fetch(moveId: 'flamethrower', sourceMoveId: 53),
        throwsFormatException,
      );
    }
    final missingDefinition = _v2Document()..['particles'] = <Object?>[];
    await expectLater(
      AveluneGen5MoveSource(client: _Transport()..document = missingDefinition)
          .fetch(moveId: 'flamethrower', sourceMoveId: 53),
      throwsFormatException,
    );
  });

  test('rejects corrupt v2 resources even when dependencies are unknown',
      () async {
    final document = _v2Document(status: 'unknown');
    final particle = (document['particles']! as List).single as Map;
    final textures = particle['textures'] as List;
    final entry = textures.first as Map<String, Object?>;
    entry.addAll(_asset(
      'res/particles/btlv_effvm_particles/218/texture00.png',
      [1, 2, 3],
    ));
    await expectLater(
      AveluneGen5MoveSource(client: _Transport()..document = document)
          .fetch(moveId: 'flamethrower', sourceMoveId: 53),
      throwsFormatException,
    );
  });

  test('rejects invalid v2 particle definitions and altered source bytes',
      () async {
    for (final bytes in [
      utf8.encode('{"emitters":[],"emitters":[],"textures":[]}'),
      utf8.encode(jsonEncode({
        'emitters': [
          {'texture': 'undeclared'},
        ],
        'textures': [
          {'name': 'texture00', 'format': 'a5i3'},
        ],
      })),
    ]) {
      final document = _v2Document(status: 'unknown');
      final particle = (document['particles']! as List).single as Map;
      particle['definition'] = _asset(
        'res/particles/btlv_effvm_particles/218/particles.json',
        bytes,
      );
      await expectLater(
        AveluneGen5MoveSource(client: _Transport()..document = document)
            .fetch(moveId: 'flamethrower', sourceMoveId: 53),
        throwsFormatException,
      );
    }
    final document = _v2Document(status: 'unknown');
    final script = (document['script']! as Map).cast<String, Object?>();
    script['sha256'] = '0' * 64;
    await expectLater(
      AveluneGen5MoveSource(client: _Transport()..document = document)
          .fetch(moveId: 'flamethrower', sourceMoveId: 53),
      throwsFormatException,
    );
  });

  test('rejects duplicate v2 particles and duplicate missing textures',
      () async {
    final duplicate = _v2Document(status: 'unknown');
    final particles = <Object?>[...duplicate['particles']! as List];
    particles.add(particles.single);
    duplicate['particles'] = particles;
    await expectLater(
      AveluneGen5MoveSource(client: _Transport()..document = duplicate)
          .fetch(moveId: 'flamethrower', sourceMoveId: 53),
      throwsFormatException,
    );
    final missing = _v2Document(status: 'unknown', missingTextures: [
      {'particleId': 219, 'name': 'texture01'},
      {'particleId': 219, 'name': 'texture01'},
    ]);
    await expectLater(
      AveluneGen5MoveSource(client: _Transport()..document = missing)
          .fetch(moveId: 'flamethrower', sourceMoveId: 53),
      throwsFormatException,
    );
  });

  test('converts verified BW2 particles from a simulated v2 source response',
      () async {
    const hashes = {
      'res/battle/animations/moves/flamethrower.s':
          '4cec7ed1fd757ee10d8e6f07941cefcd709cbaaac365ecf7782593a5dcc897f9',
      'res/particles/btlv_effvm_particles/218/particles.json':
          'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9',
      'res/particles/btlv_effvm_particles/218/texture00.png':
          'd03979b4d9e7cc4146cd28313006fc7e770e8aa83c8bffb06797f8cb5076bab1',
      'res/particles/btlv_effvm_particles/218/texture01.png':
          'a3dbf0ea435572f668f8ba2beb676587036035fdb6989a4583605dfa68d9e06e',
      'res/particles/btlv_effvm_particles/218/texture02.png':
          '3d10133124483c7c68bf8ef9df9e50d8a2bab9ed4c0f9882b5291ce8bc96260f',
      'res/particles/btlv_effvm_particles/218/texture03.png':
          '3eee20e4f1adbc946d4623f42fe12203fcd4919ec23988aa8fb2b932203bf137',
      'res/particles/btlv_effvm_particles/218/texture04.png':
          'ebce49dd55ea712ac46fa7032218fce2e8109062ff6380c55257172d6e0d44f0',
      'res/particles/btlv_effvm_particles/218/texture05.png':
          '9c83ad9fe9503947791501b1ecbe2705ccb67564f21e6c7aa26950c338da7e6e',
    };
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    Future<Uint8List> fetch(String path, String expected) async {
      final request = await client.getUrl(Uri.https(
        'raw.githubusercontent.com',
        '/fuddlesworth/pokebw2/$_revision/$path',
      ));
      request.followRedirects = false;
      final response =
          await request.close().timeout(const Duration(seconds: 20));
      expect(response.statusCode, HttpStatus.ok);
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        if (bytes.length + chunk.length > 262144) {
          throw const FormatException('BW2 source exceeds test budget');
        }
        bytes.add(chunk);
      }
      final result = bytes.takeBytes();
      expect(sha256.convert(result).toString(), expected);
      return result;
    }

    final entries = await Future.wait(hashes.entries.map((entry) async =>
        MapEntry(entry.key, await fetch(entry.key, entry.value))));
    final bytes = Map<String, Uint8List>.fromEntries(entries);
    final document = _v2Document();
    const scriptPath = 'res/battle/animations/moves/flamethrower.s';
    const particlePath =
        'res/particles/btlv_effvm_particles/218/particles.json';
    document['script'] = _asset(scriptPath, bytes[scriptPath]!);
    document['particles'] = [
      {
        'id': 218,
        'definition': _asset(particlePath, bytes[particlePath]!),
        'textures': [
          for (var i = 0; i < 6; i++)
            {
              'name': 'texture0$i',
              ..._asset(
                  'res/particles/btlv_effvm_particles/218/texture0$i.png',
                  bytes[
                      'res/particles/btlv_effvm_particles/218/texture0$i.png']!),
            },
        ],
      },
    ];
    final snapshot = (await AveluneGen5MoveSource(
      client: _Transport()..document = document,
    ).fetch(moveId: 'flamethrower', sourceMoveId: 53))!;
    expect(snapshot.effectiveDependencyStatus, 'complete');
    expect(snapshot.particleDependencyInventoryVerified, isTrue);
    expect(snapshot.playbackStatus, 'not-supported');
    final particle = snapshot.particles[218]!;
    final converted = Gen5SplParticleConverter.convert(
      particle.definitionBytes,
      particleId: particle.id,
      sourceRevision: snapshot.sourceRevision,
      sourcePath: particlePath,
      expectedSha256: particle.definitionSha256,
      textureResourceIds: {
        for (final name in particle.textureBytes.keys) name: name,
      },
    );
    expect(converted.definition.emitters, hasLength(4));
    expect(converted.definition.textureIds, {
      for (var i = 0; i < 6; i++) 'texture0$i',
    });
    expect(() => snapshot.diagnostic, throwsStateError);
  }, skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1');

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
