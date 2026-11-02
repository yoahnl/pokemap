import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_parameters.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_source.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_spl_particle_converter.dart';
import 'package:test/test.dart';

const _revision = '41f42ca1afe6291f00b0ba0ec3f6099b9ff1346c';
const _path = 'res/particles/btlv_effvm_particles/218/particles.json';

Map<String, dynamic> _source() => jsonDecode(jsonEncode({
      r'$schema': '../../particles.schema.json',
      'textures': [
        for (final name in ['base', 'first', 'second'])
          {
            'name': name,
            'format': 'a3i5',
            'repeat': 'none',
            'flip': 'none',
            'palColor0': true
          },
      ],
      'emitters': [
        {
          'emissionType': 'point',
          'drawType': 'billboard',
          'emissionAxis': 'z',
          'hasRotation': false,
          'randomInitAngle': true,
          'autoTerminate': true,
          'followEmitter': true,
          'polygonRotAxis': 'y',
          'polygonReferencePlane': 'xy',
          'randomLoopOffset': false,
          'drawChildrenFirst': false,
          'hideParent': false,
          'relativeToBasePos': false,
          'fixedPolygonID': false,
          'childFixedPolygonID': false,
          'emitterBasePos': {'x': 0, 'y': 0, 'z': 0},
          'emissionCount': 4096,
          'radius': 0,
          'length': 0,
          'axis': {'x': 4096, 'y': 0, 'z': 0},
          'color': {'red': 20, 'green': 8, 'blue': 0},
          'initVelPositionAmplifier': 0,
          'initVelAxisAmplifier': 1000,
          'baseScale': 4096,
          'aspectRatio': 4096,
          'startDelay': 0,
          'minRotation': 0,
          'maxRotation': 0,
          'initAngle': 0,
          'emitterLifeTime': 3,
          'particleLifeTime': 10,
          'scaleVariance': 0,
          'lifeTimeVariance': 0,
          'velocityVariance': 0,
          'emissionInterval': 1,
          'baseAlpha': 31,
          'airResistance': 128,
          'texture': 'base',
          'loopTime': 9,
          'dirStretch': 0,
          'textureRepeatShiftS': 0,
          'textureRepeatShiftT': 0,
          'scaleAnimDir': 'xy',
          'dirFromPosition': false,
          'flipTextureS': false,
          'flipTextureT': false,
          'polygonX': 0,
          'polygonY': 0,
          'scaleAnim': {
            'start': 4096,
            'mid': 4096,
            'end': 0,
            'in': 128,
            'out': 128,
            'loop': false
          },
          'colorAnim': {
            'start': {'red': 31, 'green': 20, 'blue': 0},
            'end': {'red': 0, 'green': 0, 'blue': 0},
            'in': 0,
            'peak': 128,
            'out': 255,
            'randomStart': false,
            'loop': false,
            'interpolate': true,
          },
          'alphaAnim': {
            'start': 31,
            'mid': 31,
            'end': 0,
            'randomRange': 0,
            'loop': false,
            'in': 128,
            'out': 128
          },
          'textureAnim': {
            'textures': ['first', 'second'],
            'step': 128,
            'randomStart': false,
            'loop': true
          },
          'gravityBehavior': {
            'magnitude': {'x': 0, 'y': 1, 'z': 0}
          },
        },
      ],
    })) as Map<String, dynamic>;

Uint8List _bytes(Map<String, dynamic> source) =>
    Uint8List.fromList(utf8.encode(jsonEncode(source)));

Gen5SplParticleConversion _convert(
  Map<String, dynamic> source, {
  String? hash,
  String path = _path,
  Map<String, String> textures = const {
    'base': 'base-id',
    'first': 'frame-1',
    'second': 'frame-2'
  },
}) {
  final bytes = _bytes(source);
  return Gen5SplParticleConverter.convert(
    bytes,
    particleId: 218,
    sourceRevision: _revision,
    sourcePath: path,
    expectedSha256: hash ?? sha256.convert(bytes).toString(),
    textureResourceIds: textures,
  );
}

void main() {
  test('preserves radial velocity in a versioned particle definition', () {
    final source = _source();
    final emitter = (source['emitters'] as List).single as Map<String, dynamic>;
    emitter['emissionType'] = 'sphere_surface';
    emitter['radius'] = 1218;
    emitter['initVelPositionAmplifier'] = 914;

    final converted = _convert(source).definition.toJson();
    expect(converted['schemaVersion'], 3);
    final emission =
        ((converted['emitters'] as List).single as Map)['emission'] as Map;
    expect(emission['positionVelocity'], 914);
    expect(emission['axisVelocity'], 1000);
  });

  test('converts a verified source without losing the initial texture', () {
    final source = _source();
    final result = _convert(source);
    expect(result.sourceRevision, _revision);
    expect(result.sourcePath, _path);
    expect(result.sourceSha256, sha256.convert(_bytes(source)).toString());
    expect(result.definition.textureIds, {'base-id', 'frame-1', 'frame-2'});
    final emitter =
        (result.definition.toJson()['emitters'] as List).single as Map;
    final appearance = emitter['appearance'] as Map;
    expect(appearance['initialTexture'], 'base-id');
    expect((appearance['textureAnimation'] as Map)['textures'],
        ['frame-1', 'frame-2']);
    expect((emitter['emission'] as Map)['followEmitter'], isTrue);
    expect((emitter['motion'] as Map)['gravity'], {'x': 0, 'y': 1, 'z': 0});
  });

  test('converts an emitter without gravity as zero acceleration', () {
    final source = _source();
    final emitter = (source['emitters'] as List).single as Map<String, dynamic>;
    emitter.remove('gravityBehavior');

    final converted = _convert(source).definition.toJson();
    final motion =
        ((converted['emitters'] as List).single as Map)['motion'] as Map;
    expect(motion['gravity'], {'x': 0, 'y': 0, 'z': 0});

    emitter['gravityBehavior'] = null;
    expect(() => _convert(source), throwsFormatException);
  });

  test('ignores source radius and length where BW2 does not use them', () {
    final source = _source();
    final emitter = (source['emitters'] as List).single as Map<String, dynamic>;
    emitter['radius'] = 8222;
    emitter['length'] = 1234;
    final point = (_convert(source).definition.toJson()['emitters'] as List)
        .single as Map;
    expect((point['emission'] as Map)['radius'], 0);

    emitter['emissionType'] = 'sphere_surface';
    emitter['radius'] = 2741;
    emitter['length'] = 0;
    final sphere = (_convert(source).definition.toJson()['emitters'] as List)
        .single as Map;
    expect((sphere['emission'] as Map)['radius'], 2741);

    emitter['length'] = 'invalid';
    expect(() => _convert(source), throwsFormatException);
  });

  test('rejects altered identities, missing textures and unsupported features',
      () {
    expect(() => _convert(_source(), hash: '0' * 64), throwsFormatException);
    expect(() => _convert(_source(), path: '../particles.json'),
        throwsFormatException);
    expect(() => _convert(_source(), textures: const {'base': 'base-id'}),
        throwsFormatException);
    for (final change in <void Function(Map<String, dynamic>)>[
      (emitter) => emitter['unknownBehavior'] = <String, dynamic>{},
      (emitter) => emitter['drawChildrenFirst'] = true,
      (emitter) => emitter['velocityVariance'] = 1,
      (emitter) => emitter['flipTextureS'] = true,
      (emitter) => (emitter['textureAnim'] as Map)['randomStart'] = true,
      (emitter) => (emitter['colorAnim'] as Map)['unknown'] = true,
    ]) {
      final source = _source();
      change((source['emitters'] as List).single as Map<String, dynamic>);
      expect(() => _convert(source), throwsFormatException);
    }
  });

  test('converts all four emitters from the pinned source 218', () async {
    const hash =
        'c69c571dbb9f9f20fe0a85bcba82aac97333e9c2c69ca968c597fe4f77b2f0e9';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client
        .getUrl(Uri.https(
          'raw.githubusercontent.com',
          '/fuddlesworth/pokebw2/$_revision/$_path',
        ))
        .timeout(const Duration(seconds: 20));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 20));
    expect(response.statusCode, HttpStatus.ok);
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      if (bytes.length + chunk.length > 262144) {
        throw const FormatException('Particle source too large');
      }
      bytes.add(chunk);
    }
    final result = Gen5SplParticleConverter.convert(
      bytes.takeBytes(),
      particleId: 218,
      sourceRevision: _revision,
      sourcePath: _path,
      expectedSha256: hash,
      textureResourceIds: {
        for (var i = 0; i < 6; i++) 'texture0$i': 'texture0$i'
      },
    );
    expect(result.definition.emitters, hasLength(4));
    expect(result.definition.textureIds,
        {for (var i = 0; i < 6; i++) 'texture0$i'});
    final emitters = result.definition.toJson()['emitters'] as List;
    expect(((emitters[2] as Map)['child'] as Map)['texture'], 'texture05');
    expect(((emitters[3] as Map)['emission'] as Map)['shape'], 'sphereSurface');
  }, skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1');

  test('reads the BW2 Disable script and converts particle source 215',
      () async {
    const path = 'res/particles/btlv_effvm_particles/215/particles.json';
    const hash =
        '2c39c15cf21c1ddd6800d1038c874ef54119da684d3e628ede2d2af03b571ffe';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client
        .getUrl(Uri.https(
          'raw.githubusercontent.com',
          '/fuddlesworth/pokebw2/$_revision/$path',
        ))
        .timeout(const Duration(seconds: 20));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 20));
    expect(response.statusCode, HttpStatus.ok);
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      if (bytes.length + chunk.length > 262144) {
        throw const FormatException('Particle source too large');
      }
      bytes.add(chunk);
    }
    final result = Gen5SplParticleConverter.convert(
      bytes.takeBytes(),
      particleId: 215,
      sourceRevision: _revision,
      sourcePath: path,
      expectedSha256: hash,
      textureResourceIds: const {'texture00': 'texture00'},
    );
    expect(result.definition.emitters, hasLength(2));
    for (final emitter in result.definition.toJson()['emitters'] as List) {
      expect(((emitter as Map)['motion'] as Map)['gravity'],
          {'x': 0, 'y': 0, 'z': 0});
    }

    const scriptPath = 'res/battle/animations/moves/disable.s';
    final scriptRequest = await client
        .getUrl(Uri.https(
          'raw.githubusercontent.com',
          '/fuddlesworth/pokebw2/$_revision/$scriptPath',
        ))
        .timeout(const Duration(seconds: 20));
    scriptRequest.followRedirects = false;
    final scriptResponse =
        await scriptRequest.close().timeout(const Duration(seconds: 20));
    expect(scriptResponse.statusCode, HttpStatus.ok);
    final scriptBytes = BytesBuilder(copy: false);
    await for (final chunk
        in scriptResponse.timeout(const Duration(seconds: 20))) {
      if (scriptBytes.length + chunk.length > 65536) {
        throw const FormatException('Battle script too large');
      }
      scriptBytes.add(chunk);
    }
    final script = Gen5BattleScriptParameters.read(Gen5BattleScriptSource.read(
      scriptBytes.takeBytes(),
      sourceRevision: _revision,
      sourcePath: scriptPath,
      expectedSha256:
          '5e933ee61006fbcb31452e4d0c95c07457f8d6a2f2c9c7edaf2a64c6830e8362',
    ));
    final emitters = script.instructions
        .where((instruction) => instruction.instruction.name == 'EmitterAdd')
        .toList();
    expect(emitters, hasLength(2));
    expect(emitters.map((e) => e.parameters['particle']!.raw), ['215', '215']);
    expect(emitters.map((e) => e.parameters['emitter']!.raw), ['0', '1']);
  }, skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1');

  test('converts radial velocity in BW2 particle source 199', () async {
    const path = 'res/particles/btlv_effvm_particles/199/particles.json';
    const hash =
        '0a2edc30e578f3f9d7650d6f3b6916fb673b8a494547d22557e2c5a34915955e';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client
        .getUrl(Uri.https(
          'raw.githubusercontent.com',
          '/fuddlesworth/pokebw2/$_revision/$path',
        ))
        .timeout(const Duration(seconds: 20));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 20));
    expect(response.statusCode, HttpStatus.ok);
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      if (bytes.length + chunk.length > 262144) {
        throw const FormatException('Particle source too large');
      }
      bytes.add(chunk);
    }
    final converted = Gen5SplParticleConverter.convert(
      bytes.takeBytes(),
      particleId: 199,
      sourceRevision: _revision,
      sourcePath: path,
      expectedSha256: hash,
      textureResourceIds: {
        for (var i = 0; i < 5; i++) 'texture0$i': 'texture0$i'
      },
    );
    final definition = converted.definition.toJson();
    expect(definition['schemaVersion'], 3);
    expect(
      (definition['emitters'] as List).map((emitter) =>
          ((emitter as Map)['emission'] as Map)['positionVelocity']),
      [914, 0],
    );
  }, skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1');
}
