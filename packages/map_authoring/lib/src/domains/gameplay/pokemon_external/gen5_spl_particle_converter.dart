import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

final class Gen5SplParticleConversion {
  const Gen5SplParticleConversion._({
    required this.sourceRevision,
    required this.sourcePath,
    required this.sourceSha256,
    required this.definition,
  });

  final String sourceRevision;
  final String sourcePath;
  final String sourceSha256;
  final BattleSplParticleDefinition definition;
}

abstract final class Gen5SplParticleConverter {
  static Gen5SplParticleConversion convert(
    Uint8List sourceBytes, {
    required int particleId,
    required String sourceRevision,
    required String sourcePath,
    required String expectedSha256,
    required Map<String, String> textureResourceIds,
  }) {
    if (particleId < 0 ||
        particleId > 65535 ||
        sourceRevision.isEmpty ||
        sourceRevision.trim() != sourceRevision ||
        sourceRevision.length > 256 ||
        sourcePath !=
            'res/particles/btlv_effvm_particles/$particleId/particles.json' ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(expectedSha256) ||
        sourceBytes.isEmpty ||
        sourceBytes.length > 262144 ||
        textureResourceIds.length > 64) {
      throw const FormatException('Invalid SPL source identity');
    }
    final bytes = Uint8List.fromList(sourceBytes);
    if (sha256.convert(bytes).toString() != expectedSha256) {
      throw const FormatException('SPL source digest mismatch');
    }
    final source =
        _map(decodeBoundedBattleJson(bytes, maxDepth: 16, label: 'SPL source'));
    _keys(source, {r'$schema', 'textures', 'emitters'});
    if (source[r'$schema'] != '../../particles.schema.json') {
      throw const FormatException('Unsupported SPL source schema');
    }
    final rawTextures = _list(source['textures']);
    final rawEmitters = _list(source['emitters']);
    if (rawTextures.isEmpty ||
        rawTextures.length > 64 ||
        rawEmitters.isEmpty ||
        rawEmitters.length > 32) {
      throw const FormatException('Invalid SPL source inventory');
    }
    final declared = <String>{};
    for (final value in rawTextures) {
      final texture = _map(value);
      _keys(texture, {'name', 'format', 'repeat', 'flip', 'palColor0'});
      final name = _text(texture['name']);
      if (!RegExp(r'^[A-Za-z0-9_]{1,64}$').hasMatch(name) ||
          !declared.add(name) ||
          !{'a3i5', 'a5i3'}.contains(texture['format']) ||
          texture['repeat'] != 'none' ||
          texture['flip'] != 'none' ||
          texture['palColor0'] is! bool) {
        throw const FormatException('Unsupported SPL source texture');
      }
    }
    if (textureResourceIds.keys.any((name) => !declared.contains(name))) {
      throw const FormatException('Unknown SPL source texture mapping');
    }
    String texture(Object? value) {
      final name = _text(value);
      final id = textureResourceIds[name];
      if (!declared.contains(name) || id == null) {
        throw const FormatException('Missing SPL source texture mapping');
      }
      return _text(id);
    }

    final converted = [
      for (final raw in rawEmitters) _emitter(_map(raw), texture),
    ];
    final definition = BattleSplParticleDefinition.fromJson({
      'schemaVersion': 2,
      'emitters': converted,
    });
    return Gen5SplParticleConversion._(
      sourceRevision: sourceRevision,
      sourcePath: sourcePath,
      sourceSha256: expectedSha256,
      definition: definition,
    );
  }
}

Map<String, dynamic> _emitter(
  Map<String, dynamic> source,
  String Function(Object?) texture,
) {
  _keys(source, {
    'emissionType',
    'drawType',
    'emissionAxis',
    'hasRotation',
    'randomInitAngle',
    'autoTerminate',
    'followEmitter',
    'polygonRotAxis',
    'polygonReferencePlane',
    'randomLoopOffset',
    'drawChildrenFirst',
    'hideParent',
    'relativeToBasePos',
    'fixedPolygonID',
    'childFixedPolygonID',
    'emitterBasePos',
    'emissionCount',
    'radius',
    'length',
    'axis',
    'color',
    'initVelPositionAmplifier',
    'initVelAxisAmplifier',
    'baseScale',
    'aspectRatio',
    'startDelay',
    'minRotation',
    'maxRotation',
    'initAngle',
    'emitterLifeTime',
    'particleLifeTime',
    'scaleVariance',
    'lifeTimeVariance',
    'velocityVariance',
    'emissionInterval',
    'baseAlpha',
    'airResistance',
    'texture',
    'loopTime',
    'dirStretch',
    'textureRepeatShiftS',
    'textureRepeatShiftT',
    'scaleAnimDir',
    'dirFromPosition',
    'flipTextureS',
    'flipTextureT',
    'polygonX',
    'polygonY',
    'unused',
    'scaleAnim',
    'colorAnim',
    'alphaAnim',
    'textureAnim',
    'childResource',
    'gravityBehavior',
  });
  final shape = switch (source['emissionType']) {
    'point' => 'point',
    'sphere_surface' => 'sphereSurface',
    _ => throw const FormatException('Unsupported SPL emission shape'),
  };
  final draw = switch (source['drawType']) {
    'billboard' => 'billboard',
    'directional_billboard' => 'directionalBillboard',
    _ => throw const FormatException('Unsupported SPL draw type'),
  };
  if (!{'x', 'y', 'z'}.contains(source['emissionAxis']) ||
      source['polygonRotAxis'] != 'y' ||
      source['polygonReferencePlane'] != 'xy' ||
      !_isSignedWord(source['length']) ||
      !_isSignedWord(source['radius']) ||
      source['minRotation'] is! int ||
      source['maxRotation'] is! int) {
    throw const FormatException('Unsupported SPL source geometry');
  }
  for (final field in [
    'hasRotation',
    'randomLoopOffset',
    'drawChildrenFirst',
    'hideParent',
    'relativeToBasePos',
    'fixedPolygonID',
    'childFixedPolygonID',
    'dirFromPosition',
    'flipTextureS',
    'flipTextureT',
  ]) {
    if (source[field] != false) {
      throw FormatException('Unsupported SPL source field: $field');
    }
  }
  for (final field in [
    'initVelPositionAmplifier',
    'lifeTimeVariance',
    'velocityVariance',
    'dirStretch',
    'textureRepeatShiftS',
    'textureRepeatShiftT',
    'polygonX',
    'polygonY',
  ]) {
    if (source[field] is! int || source[field] != 0) {
      throw FormatException('Unsupported SPL source field: $field');
    }
  }
  _optionalUnused(source);
  final scale = _map(source['scaleAnim']);
  _keys(scale, {'start', 'mid', 'end', 'in', 'out', 'loop', 'unused'});
  _optionalUnused(scale);
  final color = _map(source['colorAnim']);
  _keys(color, {
    'start',
    'end',
    'in',
    'peak',
    'out',
    'randomStart',
    'loop',
    'interpolate'
  });
  if (color['randomStart'] != false) {
    throw const FormatException('Unsupported SPL random color start');
  }
  final alpha = _map(source['alphaAnim']);
  _keys(alpha,
      {'start', 'mid', 'end', 'randomRange', 'loop', 'in', 'out', 'unused'});
  _optionalUnused(alpha);
  final gravity = source.containsKey('gravityBehavior')
      ? _map(source['gravityBehavior'])
      : <String, dynamic>{
          'magnitude': {'x': 0, 'y': 0, 'z': 0},
        };
  _keys(gravity, {'magnitude'});
  final rawTextureAnimation = source['textureAnim'];
  Map<String, dynamic>? textureAnimation;
  if (rawTextureAnimation != null) {
    final animation = _map(rawTextureAnimation);
    _keys(animation, {'textures', 'step', 'randomStart', 'loop'});
    if (animation['randomStart'] != false) {
      throw const FormatException('Unsupported SPL random texture start');
    }
    textureAnimation = {
      'textures': [
        for (final value in _list(animation['textures'])) texture(value)
      ],
      'step': animation['step'],
      'loop': animation['loop'],
    };
  }
  final rawChild = source['childResource'];
  return {
    'emission': {
      'shape': shape,
      'origin': source['emitterBasePos'],
      'axis': source['axis'],
      'radius': shape == 'point' ? 0 : source['radius'],
      'axisVelocity': source['initVelAxisAmplifier'],
      'followEmitter': source['followEmitter'],
      'rate': source['emissionCount'],
      'startDelay': source['startDelay'],
      'interval': source['emissionInterval'],
      'duration': source['emitterLifeTime'],
      'particleLifetime': source['particleLifeTime'],
      'autoTerminate': source['autoTerminate'],
      'scaleVariance': source['scaleVariance'],
      'randomInitialAngle': source['randomInitAngle'],
      'initialAngle': source['initAngle'],
    },
    'appearance': {
      'draw': draw,
      'scaleAxis': source['scaleAnimDir'],
      'baseScale': source['baseScale'],
      'aspectRatio': source['aspectRatio'],
      'baseAlpha': source['baseAlpha'],
      'loopTime': source['loopTime'],
      'scale': {
        'start': scale['start'],
        'middle': scale['mid'],
        'end': scale['end'],
        'fadeIn': scale['in'],
        'fadeOut': scale['out'],
        'loop': scale['loop'],
      },
      'color': {
        'start': color['start'],
        'middle': source['color'],
        'end': color['end'],
        'fadeIn': color['in'],
        'peak': color['peak'],
        'fadeOut': color['out'],
        'interpolate': color['interpolate'],
        'loop': color['loop'],
      },
      'alpha': {
        'start': alpha['start'],
        'middle': alpha['mid'],
        'end': alpha['end'],
        'fadeIn': alpha['in'],
        'fadeOut': alpha['out'],
        'randomRange': alpha['randomRange'],
        'loop': alpha['loop'],
      },
      'initialTexture': texture(source['texture']),
      'textureAnimation': textureAnimation,
    },
    'motion': {
      'gravity': gravity['magnitude'],
      'airResistance': source['airResistance']
    },
    'child': rawChild == null ? null : _child(_map(rawChild), texture),
  };
}

Map<String, dynamic> _child(
    Map<String, dynamic> source, String Function(Object?) texture) {
  _keys(source, {
    'hasBehaviors',
    'hasScaleAnim',
    'hasAlphaAnim',
    'rotationType',
    'followEmitter',
    'useChildColor',
    'drawType',
    'polygonRotAxis',
    'polygonReferencePlane',
    'randomInitVelMag',
    'endScale',
    'lifeTime',
    'velocityRatio',
    'scaleRatio',
    'color',
    'emissionCount',
    'emissionDelay',
    'emissionInterval',
    'texture',
    'textureRepeatShiftS',
    'textureRepeatShiftT',
    'flipTextureS',
    'flipTextureT',
    'dirFromPosition',
    'unused',
  });
  for (final field in [
    'hasBehaviors',
    'hasScaleAnim',
    'followEmitter',
    'flipTextureS',
    'flipTextureT',
    'dirFromPosition'
  ]) {
    if (source[field] != false) {
      throw FormatException('Unsupported SPL child field: $field');
    }
  }
  for (final field in [
    'endScale',
    'textureRepeatShiftS',
    'textureRepeatShiftT'
  ]) {
    if (source[field] is! int || source[field] != 0) {
      throw FormatException('Unsupported SPL child field: $field');
    }
  }
  if (source['useChildColor'] != true ||
      source['drawType'] != 'billboard' ||
      source['polygonRotAxis'] != 'y' ||
      source['polygonReferencePlane'] != 'xy') {
    throw const FormatException('Unsupported SPL child appearance');
  }
  _optionalUnused(source);
  final rotation = switch (source['rotationType']) {
    'none' => 'none',
    'angle' => 'angle',
    'angle_and_velocity' => 'angleAndVelocity',
    _ => throw const FormatException('Unsupported SPL child rotation'),
  };
  return {
    'velocityRatio': source['velocityRatio'],
    'randomVelocityMagnitude': source['randomInitVelMag'],
    'scaleRatio': source['scaleRatio'],
    'color': source['color'],
    'rotation': rotation,
    'lifetime': source['lifeTime'],
    'texture': texture(source['texture']),
    'emissionCount': source['emissionCount'],
    'emissionDelay': source['emissionDelay'],
    'emissionInterval': source['emissionInterval'],
    'fadeAlpha': source['hasAlphaAnim'],
  };
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid SPL source object');
  }
  return value;
}

List<dynamic> _list(Object? value) {
  if (value is! List) throw const FormatException('Invalid SPL source list');
  return value;
}

void _keys(Map<String, dynamic> value, Set<String> allowed) {
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Unknown SPL source field');
  }
}

void _optionalUnused(Map<String, dynamic> value) {
  if (value.containsKey('unused') && value['unused'] is! Map<String, dynamic>) {
    throw const FormatException('Invalid SPL source metadata');
  }
}

String _text(Object? value) {
  if (value is! String ||
      value.isEmpty ||
      value.trim() != value ||
      value.length > 256) {
    throw const FormatException('Invalid SPL source text');
  }
  return value;
}

bool _isSignedWord(Object? value) =>
    value is int && value >= -2147483648 && value <= 2147483647;
