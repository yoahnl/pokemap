import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';

final class Gen5SplParticleConversion {
  Gen5SplParticleConversion._({
    required this.sourceRevision,
    required this.sourcePath,
    required this.sourceSha256,
    required this.definition,
    required List<int> sourceEmitterIndices,
  }) : sourceEmitterIndices = List.unmodifiable(sourceEmitterIndices);

  final String sourceRevision;
  final String sourcePath;
  final String sourceSha256;
  final BattleSplParticleDefinition definition;
  final List<int> sourceEmitterIndices;
}

abstract final class Gen5SplParticleConverter {
  static Gen5SplParticleConversion convert(
    Uint8List sourceBytes, {
    required int particleId,
    required String sourceRevision,
    required String sourcePath,
    required String expectedSha256,
    required Map<String, String> textureResourceIds,
    List<int>? experimentalSourceEmitterIndices,
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
    final indices = experimentalSourceEmitterIndices == null
        ? List<int>.generate(rawEmitters.length, (index) => index)
        : List<int>.of(experimentalSourceEmitterIndices);
    if (indices.isEmpty ||
        indices.length > rawEmitters.length ||
        indices.toSet().length != indices.length ||
        indices.any((index) => index < 0 || index >= rawEmitters.length)) {
      throw const FormatException('Invalid SPL source emitter selection');
    }
    final declared = <String>{};
    for (final value in rawTextures) {
      final texture = _map(value);
      _keys(texture, {'name', 'format', 'repeat', 'flip', 'palColor0'});
      final name = _text(texture['name']);
      if (!RegExp(r'^[A-Za-z0-9_]{1,64}$').hasMatch(name) ||
          !declared.add(name) ||
          !{
            'a3i5',
            'a5i3',
            if (experimentalSourceEmitterIndices != null) 'palette16',
          }.contains(texture['format']) ||
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

    final selectedEmitters = [for (final index in indices) rawEmitters[index]];
    final needsExperimentalV16 = selectedEmitters.any((raw) {
      final emitter = _map(raw);
      return emitter['drawType'] == 'polygon' &&
          (emitter['polygonRotAxis'] != 'xyz' ||
              emitter['polygonReferencePlane'] != 'xy' ||
              emitter['childResource'] != null);
    });
    final needsExperimentalV15 = selectedEmitters.any(
      (raw) => _map(raw)['drawType'] == 'polygon',
    );
    final needsExperimentalV14 = selectedEmitters.any(
      (raw) => _map(raw).containsKey('randomBehavior'),
    );
    final needsExperimentalV13 = selectedEmitters.any(
      (raw) => _map(raw)['hideParent'] == true,
    );
    final needsExperimentalV12 = selectedEmitters.any((raw) {
      final emitter = _map(raw);
      final child = emitter['childResource'];
      if (child is! Map) return false;
      if (emitter['particleLifeTime'] == 1) return true;
      final base = emitter['baseScale'];
      final variance = emitter['scaleVariance'];
      final ratio = child['scaleRatio'];
      final animation = emitter['scaleAnim'];
      final phases = animation == null
          ? [4096]
          : animation is Map
              ? [animation['start'], animation['mid'], animation['end']]
              : [];
      if (base is! int || variance is! int || ratio is! int ||
          phases.isEmpty || phases.any((value) => value is! int)) {
        return false;
      }
      final largest = phases.cast<int>().reduce((a, b) => a > b ? a : b);
      final varied = (base * (255 + variance)) >> 8;
      return ((varied * largest) ~/ 4096 * (ratio + 1)) ~/ 64 > 32767;
    });
    final needsExperimentalV11 = selectedEmitters.any((raw) {
      final child = _map(raw)['childResource'];
      return child is Map && child['followEmitter'] == true;
    });
    final needsExperimentalV10 = selectedEmitters.any((raw) {
      final emitter = _map(raw);
      return ['scaleAnim', 'alphaAnim'].any((name) {
        final curve = emitter[name];
        return curve is Map && curve['in'] is int && curve['out'] is int &&
            (curve['in'] as int) > (curve['out'] as int);
      });
    });
    final needsExperimentalV9 = selectedEmitters.any(
      (raw) => {'circle', 'sphere', 'hemisphere', 'cylinder'}
          .contains(_map(raw)['emissionType']),
    );
    final needsExperimentalV8 = selectedEmitters.any(
      (raw) => _map(raw)['emissionType'] == 'cylinder_surface',
    );
    final needsExperimentalV7 = selectedEmitters.any(
      (raw) => _map(raw)['lifeTimeVariance'] != 0,
    );
    final needsExperimentalV6 = selectedEmitters.any((raw) {
      final emitter = _map(raw);
      final child = emitter['childResource'];
      final color = emitter['colorAnim'];
      final textureAnimation = emitter['textureAnim'];
      return !emitter.containsKey('alphaAnim') ||
          emitter.containsKey('spinBehavior') ||
          (color is Map && color['randomStart'] == true) ||
          (textureAnimation is Map && textureAnimation['randomStart'] == true) ||
          (child is Map &&
              (emitter['drawChildrenFirst'] == true ||
                  child['useChildColor'] == false));
    });
    final version = experimentalSourceEmitterIndices != null
        ? (needsExperimentalV16 ? 16 : needsExperimentalV15 ? 15 : needsExperimentalV14 ? 14 : needsExperimentalV13 ? 13 : needsExperimentalV12 ? 12 : needsExperimentalV11 ? 11 : needsExperimentalV10 ? 10 : needsExperimentalV9 ? 9 : needsExperimentalV8 ? 8 : needsExperimentalV7 ? 7 : needsExperimentalV6 ? 6 : 5)
        : rawEmitters.any((raw) => _map(raw).containsKey('magnetBehavior'))
            ? 4
            : rawEmitters
                    .any((raw) => _map(raw)['initVelPositionAmplifier'] != 0)
                ? 3
                : 2;
    final converted = [
      for (final raw in selectedEmitters) _emitter(_map(raw), texture, version),
    ];
    final output = <String, dynamic>{
      'schemaVersion': version,
      'emitters': converted,
    };
    final definition = experimentalSourceEmitterIndices == null
        ? BattleSplParticleDefinition.fromJson(output)
        : BattleSplParticleDefinition.fromExperimentalJson(output);
    return Gen5SplParticleConversion._(
      sourceRevision: sourceRevision,
      sourcePath: sourcePath,
      sourceSha256: expectedSha256,
      definition: definition,
      sourceEmitterIndices: indices,
    );
  }
}

Map<String, dynamic> _emitter(
  Map<String, dynamic> source,
  String Function(Object?) texture,
  int version,
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
    'magnetBehavior',
    'convergenceBehavior',
    'spinBehavior',
    'randomBehavior',
  });
  final shape = switch (source['emissionType']) {
    'point' => 'point',
    'sphere_surface' => 'sphereSurface',
    'hemisphere_surface' when version >= 5 => 'hemisphereSurface',
    'circle_border' when version >= 5 => 'circleBorder',
    'circle_border_uniform' when version >= 5 => 'circleBorderUniform',
    'cylinder_surface' when version >= 8 => 'cylinderSurface',
    'circle' when version >= 9 => 'circleDisk',
    'sphere' when version >= 9 => 'sphereVolume',
    'hemisphere' when version >= 9 => 'hemisphereVolume',
    'cylinder' when version >= 9 => 'cylinderVolume',
    _ => throw const FormatException('Unsupported SPL emission shape'),
  };
  final draw = switch (source['drawType']) {
    'billboard' => 'billboard',
    'directional_billboard' => 'directionalBillboard',
    'directional_polygon' when version >= 5 => 'directionalPolygon',
    'polygon' when version >= 15 => 'polygon',
    _ => throw const FormatException('Unsupported SPL draw type'),
  };
  if (!{'x', 'y', 'z'}.contains(source['emissionAxis']) ||
      !(draw == 'polygon' && version >= 16
          ? {'xyz', 'y'}.contains(source['polygonRotAxis'])
          : source['polygonRotAxis'] == (draw == 'polygon' ? 'xyz' : 'y')) ||
      !(draw == 'polygon' && version >= 16
          ? {'xy', 'xz'}.contains(source['polygonReferencePlane'])
          : source['polygonReferencePlane'] == 'xy') ||
      !_isSignedWord(source['length']) ||
      !_isSignedWord(source['radius']) ||
      source['minRotation'] is! int ||
      source['maxRotation'] is! int) {
    throw const FormatException('Unsupported SPL source geometry');
  }
  if (draw == 'polygon' &&
      ((version < 16 && source['childResource'] != null) ||
          source['relativeToBasePos'] != false ||
          source['dirFromPosition'] != false ||
          source['polygonX'] != 0 ||
          source['polygonY'] != 0)) {
    throw const FormatException('Unsupported SPL source polygon');
  }
  if ({'cylinderSurface', 'cylinderVolume'}.contains(shape) &&
      (source['length'] as int) < 0) {
    throw const FormatException('Unsupported SPL cylinder length');
  }
  for (final field in [
    if (version < 5) 'hasRotation',
    'randomLoopOffset',
    if (version < 5 || (version < 6 && source['childResource'] != null))
      'drawChildrenFirst',
    if (version < 13) 'hideParent',
    'fixedPolygonID',
    'childFixedPolygonID',
    if (version < 5) 'dirFromPosition',
    'flipTextureS',
    'flipTextureT',
  ]) {
    if (source[field] != false) {
      throw FormatException('Unsupported SPL source field: $field');
    }
  }
  if (source['relativeToBasePos'] != false) {
    if (version < 5 || source['relativeToBasePos'] != true) {
      throw const FormatException('Unsupported SPL relative base position');
    }
  }
  for (final field in [
    if (version < 7) 'lifeTimeVariance',
    if (version < 5) 'velocityVariance',
    'dirStretch',
    'textureRepeatShiftS',
    'textureRepeatShiftT',
    if (version < 5) 'polygonX',
    if (version < 5) 'polygonY',
  ]) {
    if (source[field] is! int || source[field] != 0) {
      throw FormatException('Unsupported SPL source field: $field');
    }
  }
  if (version >= 7 &&
      (source['lifeTimeVariance'] is! int ||
          (source['lifeTimeVariance'] as int) < 0 ||
          (source['lifeTimeVariance'] as int) > 255)) {
    throw const FormatException('Unsupported SPL particle lifetime variance');
  }
  if (version >= 5 &&
      (source['hasRotation'] is! bool ||
          source['dirFromPosition'] is! bool ||
          source['drawChildrenFirst'] is! bool ||
          (version >= 13 && source['hideParent'] is! bool) ||
          (source['dirFromPosition'] == true &&
              draw != 'directionalBillboard' && draw != 'directionalPolygon') ||
          !_isSignedWord(source['minRotation']) ||
          !_isSignedWord(source['maxRotation']) ||
          source['polygonX'] is! int ||
          (source['polygonX'] as int) < -32768 ||
          (source['polygonX'] as int) > 32767 ||
          source['polygonY'] is! int ||
          (source['polygonY'] as int) < -32768 ||
          (source['polygonY'] as int) > 32767 ||
          source['velocityVariance'] is! int ||
          (source['velocityVariance'] as int) < 0 ||
          (source['velocityVariance'] as int) > 255)) {
    throw const FormatException('Unsupported experimental SPL source field');
  }
  _optionalUnused(source);
  final scale = version >= 5 && !source.containsKey('scaleAnim')
      ? <String, dynamic>{
          'start': 4096,
          'mid': 4096,
          'end': 4096,
          'in': 0,
          'out': 254,
          'loop': false,
        }
      : _map(source['scaleAnim']);
  _keys(scale, {'start', 'mid', 'end', 'in', 'out', 'loop', 'unused'});
  _optionalUnused(scale);
  final color = source['colorAnim'] == null
      ? <String, dynamic>{
          'start': source['color'],
          'end': source['color'],
          'in': 0,
          'peak': 0,
          'out': 0,
          'randomStart': false,
          'loop': false,
          'interpolate': false,
        }
      : _map(source['colorAnim']);
  _keys(color, {
    'start',
    'end',
    'in',
    'peak',
    'out',
    'randomStart',
    'loop',
    'interpolate',
    'unused'
  });
  _optionalUnused(color);
  if (color['randomStart'] is! bool ||
      (version < 6 && color['randomStart'] != false)) {
    throw const FormatException('Unsupported SPL random color start');
  }
  final alpha = version >= 6 && !source.containsKey('alphaAnim')
      ? <String, dynamic>{
          'start': 31,
          'mid': 31,
          'end': 31,
          'randomRange': 0,
          'loop': false,
          'in': 0,
          'out': 254,
        }
      : _map(source['alphaAnim']);
  _keys(alpha,
      {'start', 'mid', 'end', 'randomRange', 'loop', 'in', 'out', 'unused'});
  _optionalUnused(alpha);
  final gravity = source.containsKey('gravityBehavior')
      ? _map(source['gravityBehavior'])
      : <String, dynamic>{
          'magnitude': {'x': 0, 'y': 0, 'z': 0},
        };
  _keys(gravity, {'magnitude'});
  final magnet = source.containsKey('magnetBehavior')
      ? _map(source['magnetBehavior'])
      : null;
  if (magnet != null) _keys(magnet, {'target', 'force'});
  final random = source.containsKey('randomBehavior')
      ? _map(source['randomBehavior'])
      : null;
  if (random != null) {
    if (version < 14) throw const FormatException('Unsupported SPL random force');
    _keys(random, {'magnitude', 'applyInterval'});
  }
  final convergence = source.containsKey('convergenceBehavior')
      ? _map(source['convergenceBehavior'])
      : null;
  if (convergence != null) {
    if (version < 5) throw const FormatException('Unsupported SPL convergence');
    _keys(convergence, {'target', 'force'});
  }
  final spin = source.containsKey('spinBehavior')
      ? _map(source['spinBehavior'])
      : null;
  if (spin != null) {
    if (version < 6) throw const FormatException('Unsupported SPL spin');
    _keys(spin, {'axis', 'angle'});
  }
  final rawTextureAnimation = source['textureAnim'];
  Map<String, dynamic>? textureAnimation;
  if (rawTextureAnimation != null) {
    final animation = _map(rawTextureAnimation);
    _keys(animation, {'textures', 'step', 'randomStart', 'loop'});
    if (animation['randomStart'] is! bool ||
        (version < 6 && animation['randomStart'] != false)) {
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
      if (version >= 3) 'positionVelocity': source['initVelPositionAmplifier'],
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
      if (version >= 5) 'emissionAxis': source['emissionAxis'],
      if (version >= 5) 'velocityVariance': source['velocityVariance'],
      if (version >= 7) 'particleLifetimeVariance': source['lifeTimeVariance'],
      if ({'cylinderSurface', 'cylinderVolume'}.contains(shape))
        'length': source['length'],
    },
    'appearance': {
      'draw': draw,
      if (draw == 'polygon') 'polygonRotationAxis': source['polygonRotAxis'],
      if (draw == 'polygon') 'polygonReferencePlane': source['polygonReferencePlane'],
      'scaleAxis': source['scaleAnimDir'],
      if (version >= 5 && source['polygonX'] != 0)
        'polygonX': source['polygonX'],
      if (version >= 5 && source['polygonY'] != 0)
        'polygonY': source['polygonY'],
      if (version >= 5 && source['relativeToBasePos'] == true)
        'relativeToBasePos': true,
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
      if (version >= 5) 'hasRotation': source['hasRotation'],
      if (version >= 5) 'minRotation': source['minRotation'],
      if (version >= 5) 'maxRotation': source['maxRotation'],
      if (version >= 5) 'dirFromPosition': source['dirFromPosition'],
      if (version >= 6) 'drawChildrenFirst': source['drawChildrenFirst'],
      if (version >= 13 && source['hideParent'] == true) 'hideParent': true,
      if (version >= 6 && !source.containsKey('alphaAnim'))
        'hasAlphaAnimation': false,
      if (version >= 6 && color['randomStart'] == true)
        'randomColorStart': true,
      if (version >= 6 && rawTextureAnimation is Map &&
          rawTextureAnimation['randomStart'] == true)
        'randomTextureStart': true,
    },
    'motion': {
      'gravity': gravity['magnitude'],
      'airResistance': source['airResistance'],
      if (version >= 4) 'magnet': magnet,
      if (convergence != null) 'convergence': convergence,
      if (spin != null) 'spin': spin,
      if (random != null) 'random': random,
    },
    'child': rawChild == null ? null : _child(_map(rawChild), texture, version),
  };
}

Map<String, dynamic> _child(Map<String, dynamic> source,
    String Function(Object?) texture, int version) {
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
    if (version < 11) 'followEmitter',
    'flipTextureS',
    'flipTextureT',
    'dirFromPosition'
  ]) {
    if (source[field] != false) {
      throw FormatException('Unsupported SPL child field: $field');
    }
  }
  if (version >= 11 && source['followEmitter'] is! bool) {
    throw const FormatException('Unsupported SPL child field: followEmitter');
  }
  if (source['hasBehaviors'] is! bool ||
      (source['hasBehaviors'] == true && version < 4)) {
    throw const FormatException('Unsupported SPL child field: hasBehaviors');
  }
  if (source['hasScaleAnim'] is! bool ||
      (source['hasScaleAnim'] == true && version < 4)) {
    throw const FormatException('Unsupported SPL child field: hasScaleAnim');
  }
  for (final field in ['textureRepeatShiftS', 'textureRepeatShiftT']) {
    if (source[field] is! int || source[field] != 0) {
      throw FormatException('Unsupported SPL child field: $field');
    }
  }
  if (source['endScale'] is! int ||
      (source['hasScaleAnim'] == false && source['endScale'] != 0)) {
    throw const FormatException('Unsupported SPL child field: endScale');
  }
  if ((version < 6
          ? source['useChildColor'] != true
          : source['useChildColor'] is! bool) ||
      !(source['drawType'] == 'billboard' ||
          (version >= 4 && source['drawType'] == 'directional_billboard')) ||
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
    if (version >= 4)
      'scaleEnd': source['hasScaleAnim'] == true ? source['endScale'] : null,
    if (version >= 4) 'inheritBehaviors': source['hasBehaviors'],
    if (version >= 6) 'inheritColor': source['useChildColor'] == false,
    if (version >= 11) 'followEmitter': source['followEmitter'],
    if (version >= 4)
      'draw': source['drawType'] == 'billboard'
          ? 'billboard'
          : 'directionalBillboard',
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
