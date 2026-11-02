import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_parameters.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_source.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_source_dependencies.dart';
import 'package:test/test.dart';

const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const _particlePath = 'res/particles/btlv_effvm_particles/218/particles.json';

Gen5BattleScriptParameters _script(String body) {
  final bytes = Uint8List.fromList(
    utf8.encode('ScriptHeader 1\nScriptVariant Demo\nDemo:\n$body\n'),
  );
  return Gen5BattleScriptParameters.read(Gen5BattleScriptSource.read(
    bytes,
    sourceRevision: _revision,
    sourcePath: 'res/battle/animations/moves/example.s',
    expectedSha256: sha256.convert(bytes).toString(),
  ));
}

final _scriptWithDependencies = _script('''
ParticleLoad 218
EmitterMove 218, 0, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 4096, 4096, 0
PlaySE SEQ_EXAMPLE, 1, EFFVM_ATTACKER, 0, 0, 100, 0, 0, 0
EmitterAdd 218, 1, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0, 4096, 4096, 4096, 4096
End''');

Uint8List _definition({String? childTexture, String? baseTexture}) =>
    Uint8List.fromList(utf8.encode(jsonEncode({
      'emitters': [
        {
          'texture': baseTexture ?? 'one',
          'textureAnim': {
            'textures': ['two', 'three']
          },
        },
        {
          'texture': 'three',
          'childResource': {'texture': childTexture ?? 'four'},
        },
      ],
      'textures': [
        for (final name in ['one', 'two', 'three', 'four'])
          {'name': name, 'format': 'a3i5'},
      ],
    })));

Gen5BattleSourceDependencies _inspect({
  Gen5BattleScriptParameters? script,
  Uint8List? definition,
  String revision = _revision,
  String path = _particlePath,
  String? digest,
  Map<String, Gen5BattleTextureSource> textures = const {},
}) {
  final bytes = definition ?? _definition();
  return Gen5BattleSourceDependencies.inspect(
    script: script ?? _scriptWithDependencies,
    particleId: 218,
    particleBytes: bytes,
    particleRevision: revision,
    particlePath: path,
    particleSha256: digest ?? sha256.convert(bytes).toString(),
    textures: textures,
  );
}

Gen5BattleTextureSource _texture(String name, Uint8List bytes,
        {String? path, String? digest, int? size}) =>
    Gen5BattleTextureSource(
      sourcePath: path ?? 'res/particles/btlv_effvm_particles/218/$name.png',
      sizeBytes: size ?? bytes.length,
      sha256Hex: digest ?? sha256.convert(bytes).toString(),
      bytes: bytes,
    );

void main() {
  test('connects script emitters to animated and child texture references', () {
    final result = _inspect();
    expect(result.particleId, 218);
    expect(result.sourceRevision, _revision);
    expect(result.scriptSha256, _scriptWithDependencies.source.sha256Hex);
    expect(result.particlePath, _particlePath);
    expect(result.particleSha256, sha256.convert(_definition()).toString());
    expect(result.emitterOrder, [0, 1]);
    expect(result.texturesByEmitter, {
      0: {'one', 'two', 'three'},
      1: {'three', 'four'},
    });
    expect(result.requiredTextures, {'one', 'two', 'three', 'four'});
    expect(result.textureFormats['one'], 'a3i5');
    expect(result.missingTextures, result.requiredTextures);
    expect(result.soundReferences, ['SEQ_EXAMPLE']);
    expect(result.unresolvedSymbols, contains('SEQ_EXAMPLE'));
    expect(result.blockers, contains(Gen5BattleSourceBlocker.recipeConverter));
    expect(result.blockers, contains(Gen5BattleSourceBlocker.particleRuntime));
    expect(result.blockers, contains(Gen5BattleSourceBlocker.childParticles));
    expect(result.blockers, contains(Gen5BattleSourceBlocker.soundPlayback));
    expect(result.blockers, contains(Gen5BattleSourceBlocker.missingTextures));
    expect(result.requireConvertible, throwsStateError);
    expect(() => result.emitterOrder.clear(), throwsUnsupportedError);
    expect(() => result.texturesByEmitter[0]!.clear(), throwsUnsupportedError);
  });

  test('verifies texture path, byte length, hash and bounded PNG dimensions',
      () {
    final bytes =
        Uint8List.fromList(image.encodePng(image.Image(width: 2, height: 2)));
    final inputs = {
      for (final name in ['one', 'two', 'three', 'four'])
        name: _texture(name, bytes),
    };
    final result = _inspect(textures: inputs);
    expect(result.missingTextures, isEmpty);
    expect(result.integrityCheckedTextures, {'one', 'two', 'three', 'four'});
    expect(result.textureSha256ByName['one'], sha256.convert(bytes).toString());
    expect(result.blockers,
        isNot(contains(Gen5BattleSourceBlocker.missingTextures)));
    expect(result.requireConvertible, throwsStateError);

    for (final bad in [
      _texture('one', bytes, path: 'res/particles/../one.png'),
      _texture('one', bytes, digest: '0' * 64),
      _texture('one', bytes, size: bytes.length + 1),
      _texture('one', Uint8List.fromList([1, 2, 3])),
    ]) {
      expect(() => _inspect(textures: {...inputs, 'one': bad}),
          throwsFormatException);
    }
    expect(
        () =>
            _inspect(textures: {...inputs, 'extra': _texture('extra', bytes)}),
        throwsFormatException);
  });

  test('rejects wrong revisions, identities and definition hashes', () {
    expect(() => _inspect(revision: '0' * 40), throwsFormatException);
    expect(
        () => _inspect(
            path: 'res/particles/btlv_effvm_particles/219/particles.json'),
        throwsFormatException);
    expect(() => _inspect(digest: '0' * 64), throwsFormatException);
    expect(() => _inspect(definition: _definition(baseTexture: 'missing')),
        throwsFormatException);
    expect(() => _inspect(definition: _definition(childTexture: 'missing')),
        throwsFormatException);
  });

  test('rejects an unloaded, unknown or symbolic emitter reference', () {
    const emitter =
        'EmitterMove 218, 2, 1, EFFVM_EMIT_ATTACKER, EFFVM_EMIT_DEFENDER, 0, 0, 0, 4096, 4096, 0';
    expect(() => _inspect(script: _script('ParticleLoad 218\n$emitter\nEnd')),
        throwsFormatException);
    expect(() => _inspect(script: _script('$emitter\nEnd')),
        throwsFormatException);
    expect(
        () => _inspect(script: _script('ParticleLoad UNKNOWN\n$emitter\nEnd')),
        throwsFormatException);
    expect(() => _inspect(script: _script('ParticleLoad 219\n$emitter\nEnd')),
        throwsFormatException);
  });

  test('keeps unknown non-audio symbols as a separate conversion blocker', () {
    final script = _script('''
ParticleLoad 218
EmitterMove 218, 0, 1, UNKNOWN_ANCHOR, EFFVM_EMIT_DEFENDER, 0, 0, 0, 4096, 4096, 0
End''');
    final result = _inspect(script: script);
    expect(result.unresolvedSymbols, contains('UNKNOWN_ANCHOR'));
    expect(
        result.blockers, contains(Gen5BattleSourceBlocker.unresolvedSymbols));
    expect(result.soundReferences, isEmpty);
  });

  test('reports unimplemented combatant visual state as a conversion blocker',
      () {
    for (final command in [
      'McssSetVanish EFFVM_DEFENDER, TRUE',
      'McssScale EFFVM_DEFENDER, 2, 0x19a, -0x19a, 2, 0, 1',
      'McssSetValue EFFVM_ATTACKER, 7',
    ]) {
      final script = _script('''
ParticleLoad 218
EmitterAdd 218, 0, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0, 4096, 4096, 4096, 4096
$command
End''');
      final result = _inspect(script: script);
      expect(result.blockers.map((blocker) => blocker.name),
          contains('combatantVisualState'),
          reason: command);
      expect(result.requireConvertible, throwsStateError, reason: command);
    }
  });

  test('reports sound playback and automation dependencies for sound waits',
      () {
    final script = _script('''
ParticleLoad 218
EmitterAdd 218, 0, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0, 4096, 4096, 4096, 4096
Wait EFFVM_WAIT_SE
End''');
    final result = _inspect(script: script);
    expect(result.blockers, contains(Gen5BattleSourceBlocker.soundPlayback));
    expect(result.blockers, contains(Gen5BattleSourceBlocker.soundAutomation));
    expect(result.requireConvertible, throwsStateError);
  });

  test('reports camera shake and combatant motion as conversion blockers', () {
    final cases = {
      'CameraShake 0, 0x19a, 4096, 1, 1, 14': 'cameraMotion',
      'McssCircle EFFVM_DEFENDER, 0, 0, 100, 200, 4, 1, 2, 3':
          'combatantMotion',
      'McssRotate EFFVM_DEFENDER, 1, -4096, 80, 0, 0': 'combatantMotion',
    };
    for (final entry in cases.entries) {
      final script = _script('''
ParticleLoad 218
EmitterAdd 218, 0, EFFVM_EMIT_DEFENDER, 0, 0, 0, 0, 4096, 4096, 4096, 4096
${entry.key}
End''');
      final result = _inspect(script: script);
      expect(
          result.blockers.map((blocker) => blocker.name), contains(entry.value),
          reason: entry.key);
      expect(result.requireConvertible, throwsStateError, reason: entry.key);
    }
  });

  test('does not hide a non-audio occurrence of a sound symbol', () {
    final script = _script('''
ParticleLoad 218
PlaySE UNKNOWN, 1, EFFVM_ATTACKER, 0, 0, 100, 0, 0, 0
EmitterMove 218, 0, 1, UNKNOWN, EFFVM_EMIT_DEFENDER, 0, 0, 0, 4096, 4096, 0
End''');
    final result = _inspect(script: script);
    expect(result.soundReferences, ['UNKNOWN']);
    expect(result.unresolvedSymbols, contains('UNKNOWN'));
    expect(
        result.blockers, contains(Gen5BattleSourceBlocker.unresolvedSymbols));
  });

  test('rejects duplicate and excessively nested JSON', () {
    final duplicate = Uint8List.fromList(utf8.encode(
      '{"emitters":[],"emitters":[],"textures":[]}',
    ));
    final nested = Uint8List.fromList(utf8.encode(
      '{"extra":${'[' * 40}0${']' * 40},"emitters":[],"textures":[]}',
    ));
    expect(() => _inspect(definition: duplicate), throwsFormatException);
    expect(() => _inspect(definition: nested), throwsFormatException);
  });

  test(
    'finds the dependencies and missing capabilities in the pinned pilot',
    () async {
      final client = HttpClient();
      Future<Uint8List> fetch(String path, String expectedDigest) async {
        final request = await client
            .getUrl(Uri.https(
              'raw.githubusercontent.com',
              '/fuddlesworth/pokebw2/$_revision/$path',
            ))
            .timeout(const Duration(seconds: 20));
        request.followRedirects = false;
        final response =
            await request.close().timeout(const Duration(seconds: 20));
        expect(response.statusCode, HttpStatus.ok);
        final bytes = BytesBuilder(copy: false);
        await for (final chunk
            in response.timeout(const Duration(seconds: 20))) {
          if (bytes.length + chunk.length > 262144) {
            throw const FormatException('Source exceeds test limit');
          }
          bytes.add(chunk);
        }
        final result = bytes.takeBytes();
        expect(sha256.convert(result).toString(), expectedDigest);
        return result;
      }

      try {
        const scriptPath = 'res/battle/animations/moves/flamethrower.s';
        const scriptHash =
            '4cec7ed1fd757ee10d8e6f07941cefcd709cbaaac365ecf7782593a5dcc897f9';
        const particleHash =
            'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9';
        final scriptBytes = await fetch(scriptPath, scriptHash);
        final particleBytes = await fetch(_particlePath, particleHash);
        final script =
            Gen5BattleScriptParameters.read(Gen5BattleScriptSource.read(
          scriptBytes,
          sourceRevision: _revision,
          sourcePath: scriptPath,
          expectedSha256: scriptHash,
        ));
        final result = _inspect(script: script, definition: particleBytes);
        expect(result.emitterOrder, [0, 1, 3, 2]);
        expect(result.texturesByEmitter, {
          0: {'texture00', 'texture01', 'texture02', 'texture03'},
          1: {'texture04'},
          2: {'texture00', 'texture05'},
          3: {'texture00', 'texture01', 'texture02', 'texture03'},
        });
        expect(result.requiredTextures, {
          'texture00',
          'texture01',
          'texture02',
          'texture03',
          'texture04',
          'texture05',
        });
        expect(result.missingTextures, result.requiredTextures);
        expect(result.soundReferences, [
          'SEQ_SE_W307_01',
          'SEQ_SE_W027_01',
          'SEQ_SE_W001_01',
          'SEQ_SE_BE_SE_016',
          'SEQ_SE_BE_SE_016',
          'SEQ_SE_W307_02',
        ]);
        expect(
            result.blockers,
            containsAll({
              Gen5BattleSourceBlocker.recipeConverter,
              Gen5BattleSourceBlocker.scriptScheduling,
              Gen5BattleSourceBlocker.cameraPresets,
              Gen5BattleSourceBlocker.paletteEffects,
              Gen5BattleSourceBlocker.combatantMotion,
              Gen5BattleSourceBlocker.particleRuntime,
              Gen5BattleSourceBlocker.childParticles,
              Gen5BattleSourceBlocker.missingTextures,
              Gen5BattleSourceBlocker.soundPlayback,
              Gen5BattleSourceBlocker.soundAutomation,
            }));
        expect(result.requireConvertible, throwsStateError);
      } finally {
        client.close(force: true);
      }
    },
    skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] == '1'
        ? false
        : 'Requires network access to the pinned source',
  );
}
