import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_parameters.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_battle_script_source.dart';
import 'package:map_authoring/src/domains/gameplay/pokemon_external/gen5_spl_particle_converter.dart';
import 'package:map_core/map_core.dart';
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
  test('preserves the oriented polygon used by the Surf wave', () {
    final source = _source();
    final emitter = (source['emitters'] as List).single as Map<String, dynamic>;
    emitter['drawType'] = 'directional_polygon';
    emitter['dirFromPosition'] = true;
    emitter['randomInitAngle'] = false;
    final bytes = _bytes(source);
    final converted = Gen5SplParticleConverter.convert(
      bytes,
      particleId: 218,
      sourceRevision: _revision,
      sourcePath: _path,
      expectedSha256: sha256.convert(bytes).toString(),
      textureResourceIds: const {
        'base': 'base-id',
        'first': 'frame-1',
        'second': 'frame-2',
      },
      experimentalSourceEmitterIndices: const [0],
    );
    final appearance = converted.definition.emitters.single.toJson()['appearance'] as Map;
    expect(appearance['draw'], 'directionalPolygon');
    expect(appearance['dirFromPosition'], isTrue);
    expect(() => _convert(source), throwsFormatException);
  });

  test('preserves the uniform circle shape used by the Surf source', () {
    final source = _source();
    final emitter = (source['emitters'] as List).single as Map<String, dynamic>;
    emitter['emissionType'] = 'circle_border_uniform';
    emitter['emissionAxis'] = 'y';
    emitter['radius'] = 8832;
    final bytes = _bytes(source);
    final converted = Gen5SplParticleConverter.convert(
      bytes,
      particleId: 218,
      sourceRevision: _revision,
      sourcePath: _path,
      expectedSha256: sha256.convert(bytes).toString(),
      textureResourceIds: const {
        'base': 'base-id',
        'first': 'frame-1',
        'second': 'frame-2',
      },
      experimentalSourceEmitterIndices: const [0],
    );
    final emission = converted.definition.emitters.single.toJson()['emission'] as Map;
    expect(emission['shape'], 'circleBorderUniform');
    expect(emission['radius'], 8832);
    expect(() => _convert(source), throwsFormatException);
  });

  test('preserves Surf convergence and its relative experimental origin', () {
    final source = _source();
    final emitter = (source['emitters'] as List).single as Map<String, dynamic>;
    emitter['relativeToBasePos'] = true;
    emitter['convergenceBehavior'] = {
      'target': {'x': 0, 'y': 0, 'z': 0},
      'force': 274,
    };
    final bytes = _bytes(source);
    final converted = Gen5SplParticleConverter.convert(
      bytes,
      particleId: 218,
      sourceRevision: _revision,
      sourcePath: _path,
      expectedSha256: sha256.convert(bytes).toString(),
      textureResourceIds: const {
        'base': 'base-id',
        'first': 'frame-1',
        'second': 'frame-2',
      },
      experimentalSourceEmitterIndices: const [0],
    );
    final motion = converted.definition.emitters.single.toJson()['motion'] as Map;
    expect(motion['convergence'], {
      'target': {'x': 0, 'y': 0, 'z': 0},
      'force': 274,
    });
    expect(() => _convert(source), throwsFormatException);
    (emitter['emitterBasePos'] as Map<String, dynamic>)['y'] = -3350;
    final nonzeroBytes = _bytes(source);
    final relative = Gen5SplParticleConverter.convert(
      nonzeroBytes,
      particleId: 218,
      sourceRevision: _revision,
      sourcePath: _path,
      expectedSha256: sha256.convert(nonzeroBytes).toString(),
      textureResourceIds: const {
        'base': 'base-id',
        'first': 'frame-1',
        'second': 'frame-2',
      },
      experimentalSourceEmitterIndices: const [0],
    ).definition.emitters.single.toJson();
    expect((relative['emission'] as Map)['origin'], {'x': 0, 'y': -3350, 'z': 0});
    expect((relative['appearance'] as Map)['relativeToBasePos'], isTrue);
  });

  test('preserves Surf source polygon offsets for experimental emitters', () {
    final source = _source();
    final emitter = (source['emitters'] as List).single as Map<String, dynamic>;
    emitter['polygonX'] = 2048;
    emitter['polygonY'] = -4096;
    final bytes = _bytes(source);
    final converted = Gen5SplParticleConverter.convert(
      bytes,
      particleId: 218,
      sourceRevision: _revision,
      sourcePath: _path,
      expectedSha256: sha256.convert(bytes).toString(),
      textureResourceIds: const {
        'base': 'base-id',
        'first': 'frame-1',
        'second': 'frame-2',
      },
      experimentalSourceEmitterIndices: const [0],
    );
    final appearance = (converted.definition.emitters.single.toJson()['appearance'] as Map);
    expect(appearance['polygonX'], 2048);
    expect(appearance['polygonY'], -4096);
    expect(() => _convert(source), throwsFormatException);
  });

  test('admits the five emitters used by the pinned Surf source',
      () async {
    const path = 'res/particles/btlv_effvm_particles/222/particles.json';
    const hash =
        '3e191c2e53d6eb9ff35b21e232c3ff8371516d09d4a55e8d0595cd43c149b8cc';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client
        .getUrl(Uri.https('raw.githubusercontent.com',
            '/fuddlesworth/pokebw2/$_revision/$path'))
        .timeout(const Duration(seconds: 20));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 20));
    expect(response.statusCode, HttpStatus.ok);
    final input = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      if (input.length + chunk.length > 262144) {
        throw const FormatException('Particle source too large');
      }
      input.add(chunk);
    }
    final bytes = input.takeBytes();
    Gen5SplParticleConversion convert(List<int> indices) =>
        Gen5SplParticleConverter.convert(
          bytes,
          particleId: 222,
          sourceRevision: _revision,
          sourcePath: path,
          expectedSha256: hash,
          textureResourceIds: const {
            'texture00': 'texture00',
            'texture01': 'texture01',
            'texture02': 'texture02',
            'texture03': 'texture03'
          },
          experimentalSourceEmitterIndices: indices,
        );
    final result = convert([2]);
    expect(result.sourceEmitterIndices, [2]);
    expect(result.definition.textureIds, {'texture00'});
    final emitter =
        (result.definition.toJson()['emitters'] as List).single as Map;
    expect(emitter['emission']['shape'], 'circleBorder');
    expect(emitter['emission']['radius'], 9745);
    expect(emitter['emission']['emissionAxis'], 'y');
    expect(emitter['appearance']['scale']['start'], 4096);
    expect(emitter['appearance']['scale']['end'], 4096);
    final wave = convert([4]).definition.emitters.single.toJson();
    expect((wave['appearance'] as Map)['polygonY'], -4096);
    expect((wave['appearance'] as Map)['initialTexture'], 'texture03');
    final convergence = convert([1]).definition.emitters.single.toJson();
    expect((convergence['motion'] as Map)['convergence'], {
      'target': {'x': 0, 'y': 0, 'z': 0},
      'force': 274,
    });
    expect((convergence['appearance'] as Map)['polygonY'], 4096);
    final ring = convert([3]).definition.emitters.single.toJson();
    expect((ring['emission'] as Map)['shape'], 'circleBorderUniform');
    expect((ring['emission'] as Map)['origin'], {'x': 0, 'y': -3350, 'z': 0});
    expect((ring['appearance'] as Map)['relativeToBasePos'], isTrue);
    expect((ring['appearance'] as Map)['polygonY'], 4096);
    final plane = convert([5]).definition.emitters.single.toJson();
    expect((plane['appearance'] as Map)['draw'], 'directionalPolygon');
    expect((plane['appearance'] as Map)['dirFromPosition'], isTrue);
    expect(() => convert([0]), throwsFormatException);
  }, skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1');

  test('converts a childless source circle with an absent scale animation', () {
    final source = _source();
    final emitter = (source['emitters'] as List).single as Map<String, dynamic>;
    emitter['emissionType'] = 'circle_border';
    emitter['emissionAxis'] = 'y';
    emitter['radius'] = 9745;
    emitter['drawChildrenFirst'] = true;
    emitter.remove('scaleAnim');
    (source['textures'] as List).add({
      'name': 'unselected_palette',
      'format': 'palette16',
      'repeat': 'none',
      'flip': 'none',
      'palColor0': true,
    });
    Gen5SplParticleConversion convert() {
      final bytes = _bytes(source);
      return Gen5SplParticleConverter.convert(
        bytes,
        particleId: 218,
        sourceRevision: _revision,
        sourcePath: _path,
        expectedSha256: sha256.convert(bytes).toString(),
        textureResourceIds: const {
          'base': 'base-id',
          'first': 'frame-1',
          'second': 'frame-2'
        },
        experimentalSourceEmitterIndices: const [0],
      );
    }

    expect(() => _convert(source), throwsFormatException);
    expect(() => convert(), returnsNormally);
    final result = convert();
    final selected =
        (result.definition.toJson()['emitters'] as List).single as Map;
    expect(selected['emission']['shape'], 'circleBorder');
    expect(selected['emission']['emissionAxis'], 'y');
    expect(selected['appearance']['scale'], {
      'start': 4096,
      'middle': 4096,
      'end': 4096,
      'fadeIn': 0,
      'fadeOut': 254,
      'loop': false,
    });
    emitter['childResource'] = <String, dynamic>{};
    expect(() => convert(), throwsFormatException);
  });

  test('converts the two selected emitters of pinned BW2 particle source 220',
      () async {
    const path = 'res/particles/btlv_effvm_particles/220/particles.json';
    const hash =
        'c50300370f0a622a514d45bea7cce595d4794d2197122cdc8ee90cb6c8a0afb1';
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client
        .getUrl(Uri.https('raw.githubusercontent.com',
            '/fuddlesworth/pokebw2/$_revision/$path'))
        .timeout(const Duration(seconds: 20));
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 20));
    expect(response.statusCode, HttpStatus.ok);
    final input = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(const Duration(seconds: 20))) {
      if (input.length + chunk.length > 262144) {
        throw const FormatException('Particle source too large');
      }
      input.add(chunk);
    }
    final bytes = input.takeBytes();
    Gen5SplParticleConversion convert(List<int>? indices) =>
        Gen5SplParticleConverter.convert(
          bytes,
          particleId: 220,
          sourceRevision: _revision,
          sourcePath: path,
          expectedSha256: hash,
          textureResourceIds: const {
            'texture00': 'texture00',
            'texture01': 'texture01',
            'texture02': 'texture02'
          },
          experimentalSourceEmitterIndices: indices,
        );
    expect(() => convert(null), throwsFormatException);
    expect(convert([0, 4]).sourceEmitterIndices, [0, 4]);
    final result = convert([0, 1]);
    expect(result.sourceEmitterIndices, [0, 1]);
    expect(() => result.sourceEmitterIndices.clear(), throwsUnsupportedError);
    expect(result.definition.textureIds, {'texture00', 'texture01'});
    final emitters = result.definition.toJson()['emitters'] as List;
    final first = emitters[0] as Map;
    final second = emitters[1] as Map;
    expect(first['emission']['shape'], 'hemisphereSurface');
    expect(first['emission']['radius'], 0);
    expect(first['emission']['emissionAxis'], 'x');
    expect(first['appearance']['hasRotation'], isTrue);
    expect(first['appearance']['minRotation'], 2558);
    expect(first['appearance']['maxRotation'], -2559);
    expect(first['appearance']['dirFromPosition'], isTrue);
    expect(second['emission']['velocityVariance'], 27);
    expect(second['child']['texture'], 'texture00');
    expect(second['child']['rotation'], 'angleAndVelocity');
    expect(
        () => BattleSplParticleDefinition.fromJson(result.definition.toJson()),
        throwsFormatException);
    final reversed = convert([1, 0]);
    expect(reversed.sourceEmitterIndices, [1, 0]);
    final reversedEmitters = reversed.definition.toJson()['emitters'] as List;
    expect((reversedEmitters.first as Map)['emission']['shape'], 'point');
    expect((reversedEmitters.last as Map)['emission']['shape'],
        'hemisphereSurface');
  }, skip: Platform.environment['AVELUNE_BW2_SCRIPT_TEST'] != '1');

  test(
      'selects source emitters without admitting experimental data as a legacy SPL definition',
      () {
    final source = _source();
    final values = source['emitters'] as List;
    final first = values.single as Map<String, dynamic>;
    first['emissionType'] = 'hemisphere_surface';
    first['emissionAxis'] = 'x';
    first['drawType'] = 'directional_billboard';
    first['hasRotation'] = true;
    first['minRotation'] = 2558;
    first['maxRotation'] = -2559;
    first['dirFromPosition'] = true;
    final second = jsonDecode(jsonEncode(first)) as Map<String, dynamic>;
    second['emissionType'] = 'point';
    second['hasRotation'] = false;
    second['dirFromPosition'] = false;
    second['velocityVariance'] = 27;
    final other = jsonDecode(jsonEncode(second)) as Map<String, dynamic>;
    other['emissionType'] = 'cylinder_surface';
    values.addAll([second, other]);
    final bytes = _bytes(source);
    Gen5SplParticleConversion selected(List<int> indices) =>
        Gen5SplParticleConverter.convert(
          bytes,
          particleId: 218,
          sourceRevision: _revision,
          sourcePath: _path,
          expectedSha256: sha256.convert(bytes).toString(),
          textureResourceIds: const {
            'base': 'base-id',
            'first': 'frame-1',
            'second': 'frame-2',
          },
          experimentalSourceEmitterIndices: indices,
        );

    expect(() => _convert(source), throwsFormatException);
    expect(() => selected([0, 1]), returnsNormally);
    final result = selected([0, 1]);
    expect(result.sourceEmitterIndices, [0, 1]);
    final json = result.definition.toJson();
    expect(json['schemaVersion'], 5);
    final emitters = json['emitters'] as List;
    expect((emitters[0] as Map)['emission']['shape'], 'hemisphereSurface');
    expect((emitters[0] as Map)['emission']['emissionAxis'], 'x');
    expect((emitters[0] as Map)['appearance']['hasRotation'], isTrue);
    expect((emitters[0] as Map)['appearance']['minRotation'], 2558);
    expect((emitters[0] as Map)['appearance']['maxRotation'], -2559);
    expect((emitters[0] as Map)['appearance']['dirFromPosition'], isTrue);
    expect((emitters[1] as Map)['emission']['velocityVariance'], 27);
    expect(() => BattleSplParticleDefinition.fromJson(json),
        throwsFormatException);
    expect(() => selected([0, 2]), throwsFormatException);
    expect(() => selected([1, 1]), throwsFormatException);
    expect(() => selected([3]), throwsFormatException);
    expect(() => selected([]), throwsFormatException);
  });

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
