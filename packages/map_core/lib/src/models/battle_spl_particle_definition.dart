import 'dart:convert';

final class BattleSplParticleDefinition {
  BattleSplParticleDefinition._(
    this.schemaVersion,
    this.emitters,
    this.textureIds,
  );

  final int schemaVersion;
  final List<BattleSplEmitterDefinition> emitters;
  final Set<String> textureIds;

  factory BattleSplParticleDefinition.fromJson(Map<String, dynamic> json) =>
      _parse(json, experimental: false);

  factory BattleSplParticleDefinition.fromExperimentalJson(
    Map<String, dynamic> json,
  ) => _parse(json, experimental: true);

  static BattleSplParticleDefinition _parse(
    Map<String, dynamic> json, {
    required bool experimental,
  }) {
    final Map<String, dynamic> copy;
    try {
      copy = (jsonDecode(jsonEncode(json)) as Map).cast<String, dynamic>();
    } on Object {
      throw const FormatException('Invalid SPL particle definition');
    }
    _fields(copy, {'schemaVersion', 'emitters'});
    if (copy['schemaVersion'] is! int ||
        !(experimental ? {5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16} : {2, 3, 4}).contains(copy['schemaVersion'])) {
      throw const FormatException('Unsupported SPL particle version');
    }
    final values = _list(copy['emitters']);
    if (values.isEmpty || values.length > 32) {
      throw const FormatException('Invalid SPL emitter count');
    }
    final textures = <String>{};
    final emitters = <BattleSplEmitterDefinition>[];
    for (final value in values) {
      final emitter = _map(value);
      _validateEmitter(emitter, textures, copy['schemaVersion'] as int);
      emitters.add(BattleSplEmitterDefinition._(emitter, copy['schemaVersion'] as int));
    }
    return BattleSplParticleDefinition._(
      copy['schemaVersion'] as int,
      List.unmodifiable(emitters),
      Set.unmodifiable(textures),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'emitters': [for (final emitter in emitters) emitter.toJson()],
  };
}

final class BattleSplEmitterDefinition {
  const BattleSplEmitterDefinition._(this._json, this.schemaVersion);

  final Map<String, dynamic> _json;
  final int schemaVersion;

  Map<String, dynamic> toJson() =>
      (jsonDecode(jsonEncode(_json)) as Map).cast<String, dynamic>();
}

void _validateEmitter(
  Map<String, dynamic> emitter,
  Set<String> textures,
  int version,
) {
  _fields(emitter, {'emission', 'appearance', 'motion', 'child'});
  final emission = _map(emitter['emission']);
  _fields(emission, {
    'shape',
    'origin',
    'axis',
    'radius',
    'axisVelocity',
    if (version >= 3) 'positionVelocity',
    'followEmitter',
    'rate',
    'startDelay',
    'interval',
    'duration',
    'particleLifetime',
    'autoTerminate',
    'scaleVariance',
    'randomInitialAngle',
    'initialAngle',
    if (version >= 5) 'emissionAxis',
    if (version >= 5) 'velocityVariance',
    if (version >= 7) 'particleLifetimeVariance',
    if (version >= 8 &&
        {'cylinderSurface', 'cylinderVolume'}.contains(emission['shape']))
      'length',
  });
  _choice(emission['shape'], {
    'point',
    'sphereSurface',
    if (version >= 5) 'hemisphereSurface',
    if (version >= 5) 'circleBorder',
    if (version >= 5) 'circleBorderUniform',
    if (version >= 8) 'cylinderSurface',
    if (version >= 9) ...{
      'circleDisk',
      'sphereVolume',
      'hemisphereVolume',
      'cylinderVolume',
    },
  });
  _vector(emission['origin'], -2147483648, 2147483647);
  _vector(emission['axis'], -32768, 32767);
  final radius = _integer(emission['radius'], 0, 32767);
  if ({'cylinderSurface', 'cylinderVolume'}.contains(emission['shape'])) {
    _integer(emission['length'], 0, 65535);
  }
  if (emission['shape'] == 'point' && radius != 0) {
    throw const FormatException('Point SPL emitter cannot have a radius');
  }
  if (emission['shape'] == 'sphereSurface' && radius == 0) {
    throw const FormatException('Zero-radius SPL sphere is unsupported');
  }
  _integer(emission['axisVelocity'], -32768, 32767);
  if (version >= 3) _integer(emission['positionVelocity'], -32768, 32767);
  _boolean(emission['followEmitter']);
  _integer(emission['rate'], 0, 64 * 4096);
  _integer(emission['startDelay'], 0, 65535);
  _integer(emission['interval'], 1, 255);
  _integer(emission['duration'], 1, 65534);
  final lifetime = _integer(emission['particleLifetime'], 1, 65535);
  if (emission['autoTerminate'] != true) {
    throw const FormatException('SPL emitter must terminate automatically');
  }
  final scaleVariance = _integer(emission['scaleVariance'], 0, 255);
  _boolean(emission['randomInitialAngle']);
  _integer(emission['initialAngle'], 0, 65535);
  if (version >= 5) {
    _choice(emission['emissionAxis'], {'x', 'y', 'z'});
    _integer(emission['velocityVariance'], 0, 255);
  }
  if (version >= 7) _integer(emission['particleLifetimeVariance'], 0, 255);

  final appearance = _map(emitter['appearance']);
  _fields(appearance, {
    'draw',
    'scaleAxis',
    'baseScale',
    'aspectRatio',
    'baseAlpha',
    'loopTime',
    'scale',
    'color',
    'alpha',
    'initialTexture',
    'textureAnimation',
    if (version >= 5) 'hasRotation',
    if (version >= 5) 'minRotation',
    if (version >= 5) 'maxRotation',
    if (version >= 5) 'dirFromPosition',
    if (version >= 6) 'drawChildrenFirst',
    if (version >= 13 && appearance.containsKey('hideParent')) 'hideParent',
    if (version >= 6 && appearance.containsKey('hasAlphaAnimation'))
      'hasAlphaAnimation',
    if (version >= 6 && appearance.containsKey('randomColorStart'))
      'randomColorStart',
    if (version >= 6 && appearance.containsKey('randomTextureStart'))
      'randomTextureStart',
    if (version >= 5 && appearance.containsKey('polygonX')) 'polygonX',
    if (version >= 5 && appearance.containsKey('polygonY')) 'polygonY',
    if (version >= 15 && appearance['draw'] == 'polygon') 'polygonRotationAxis',
    if (version >= 15 && appearance['draw'] == 'polygon') 'polygonReferencePlane',
    if (version >= 5 && appearance.containsKey('relativeToBasePos'))
      'relativeToBasePos',
  });
  _choice(appearance['draw'], {
    'billboard',
    'directionalBillboard',
    if (version >= 5) 'directionalPolygon',
    if (version >= 15) 'polygon',
  });
  if (version >= 5) {
    _boolean(appearance['hasRotation']);
    _integer(appearance['minRotation'], -32768, 32767);
    _integer(appearance['maxRotation'], -32768, 32767);
    _boolean(appearance['dirFromPosition']);
    if (version >= 6) _boolean(appearance['drawChildrenFirst']);
    if (version >= 13 && appearance.containsKey('hideParent')) {
      _boolean(appearance['hideParent']);
    }
    if (version >= 6 && appearance.containsKey('hasAlphaAnimation')) {
      _boolean(appearance['hasAlphaAnimation']);
    }
    if (version >= 6 && appearance.containsKey('randomColorStart')) {
      _boolean(appearance['randomColorStart']);
    }
    if (version >= 6 && appearance.containsKey('randomTextureStart')) {
      _boolean(appearance['randomTextureStart']);
      if (appearance['randomTextureStart'] == true &&
          appearance['textureAnimation'] == null) {
        throw const FormatException('Random SPL texture needs animation frames');
      }
    }
    if (appearance.containsKey('polygonX')) {
      _integer(appearance['polygonX'], -32768, 32767);
    }
    if (appearance.containsKey('polygonY')) {
      _integer(appearance['polygonY'], -32768, 32767);
    }
    if (appearance.containsKey('relativeToBasePos')) {
      _boolean(appearance['relativeToBasePos']);
    }
    if (appearance['dirFromPosition'] == true &&
        appearance['draw'] != 'directionalBillboard' &&
        appearance['draw'] != 'directionalPolygon') {
      throw const FormatException('Unsupported SPL directional mode');
    }
    if (appearance['draw'] == 'directionalPolygon' &&
        (appearance['dirFromPosition'] != true ||
            appearance['hasRotation'] != false ||
            emission['randomInitialAngle'] != false ||
            emission['initialAngle'] != 0 ||
            appearance['relativeToBasePos'] == true ||
            (appearance['polygonX'] ?? 0) != 0 ||
            (appearance['polygonY'] ?? 0) != 0 ||
            emitter['child'] != null)) {
      throw const FormatException('Unsupported SPL directional polygon');
    }
    if (appearance['draw'] == 'polygon') {
      _choice(appearance['polygonRotationAxis'], {'xyz', if (version >= 16) 'y'});
      _choice(appearance['polygonReferencePlane'], {'xy', if (version >= 16) 'xz'});
      if (appearance['dirFromPosition'] != false ||
          appearance['relativeToBasePos'] == true ||
          (appearance['polygonX'] ?? 0) != 0 ||
          (appearance['polygonY'] ?? 0) != 0 ||
          (version < 16 && emitter['child'] != null)) {
        throw const FormatException('Unsupported SPL polygon');
      }
    }
  }
  _choice(appearance['scaleAxis'], {'x', 'y', 'xy'});
  final baseScale = _integer(appearance['baseScale'], 0, 32767);
  final maxVariedScale = (baseScale * (255 + scaleVariance)) >> 8;
  if (maxVariedScale > 32767) {
    throw const FormatException('SPL initial scale exceeds supported range');
  }
  _integer(appearance['aspectRatio'], 0, 32767);
  _integer(appearance['baseAlpha'], 0, 31);
  _integer(appearance['loopTime'], 1, 65535);
  _curve(appearance['scale'], 32767, allowOverlap: version >= 10);
  _curve(appearance['alpha'], 31, alpha: true, allowOverlap: version >= 10);
  _colorCurve(appearance['color']);
  textures.add(_texture(appearance['initialTexture']));
  final textureAnimation = appearance['textureAnimation'];
  if (textureAnimation != null) {
    final animation = _map(textureAnimation);
    _fields(animation, {'textures', 'step', 'loop'});
    final frames = _list(animation['textures']);
    if (frames.isEmpty || frames.length > 8) {
      throw const FormatException('Invalid SPL texture animation');
    }
    for (final frame in frames) {
      textures.add(_texture(frame));
    }
    _integer(animation['step'], 1, 255);
    _boolean(animation['loop']);
  }

  final motion = _map(emitter['motion']);
  _fields(motion, {
    'gravity',
    'airResistance',
    if (version >= 4) 'magnet',
    if (version >= 5 && motion.containsKey('convergence')) 'convergence',
    if (version >= 6 && motion.containsKey('spin')) 'spin',
    if (version >= 14 && motion.containsKey('random')) 'random',
  });
  _vector(motion['gravity'], -32768, 32767);
  _integer(motion['airResistance'], 0, 255);
  if (version >= 4 && motion['magnet'] != null) {
    final magnet = _map(motion['magnet']);
    _fields(magnet, {'target', 'force'});
    _vector(magnet['target'], -2147483648, 2147483647);
    _integer(magnet['force'], -32768, 32767);
  }
  if (version >= 5 && motion.containsKey('convergence')) {
    final convergence = _map(motion['convergence']);
    _fields(convergence, {'target', 'force'});
    _vector(convergence['target'], -2147483648, 2147483647);
    _integer(convergence['force'], -32768, 32767);
  }
  if (version >= 6 && motion.containsKey('spin')) {
    final spin = _map(motion['spin']);
    _fields(spin, {'axis', 'angle'});
    _choice(spin['axis'], {'x', 'y', 'z'});
    _integer(spin['angle'], 0, 65535);
  }
  if (version >= 14 && motion.containsKey('random')) {
    final random = _map(motion['random']);
    _fields(random, {'magnitude', 'applyInterval'});
    _vector(random['magnitude'], 0, 32767);
    _integer(random['applyInterval'], 1, 65535);
  }

  final child = emitter['child'];
  if (child != null) {
    final fields = _map(child);
    _fields(fields, {
      'velocityRatio',
      'randomVelocityMagnitude',
      'scaleRatio',
      'color',
      'rotation',
      'lifetime',
      'texture',
      'emissionCount',
      'emissionDelay',
      'emissionInterval',
      'fadeAlpha',
      if (version >= 4) 'scaleEnd',
      if (version >= 4) 'inheritBehaviors',
      if (version >= 4) 'draw',
      if (version >= 6) 'inheritColor',
      if (version >= 11) 'followEmitter',
    });
    _integer(fields['velocityRatio'], 0, 255);
    _integer(fields['randomVelocityMagnitude'], 0, 32767);
    final scaleRatio = _integer(fields['scaleRatio'], 0, 255);
    _color(fields['color']);
    _choice(fields['rotation'], {'none', 'angle', 'angleAndVelocity'});
    _integer(fields['lifetime'], 1, 65534);
    textures.add(_texture(fields['texture']));
    _integer(fields['emissionCount'], 1, 64);
    final delay = _integer(fields['emissionDelay'], 0, 255);
    _integer(fields['emissionInterval'], 1, 255);
    _boolean(fields['fadeAlpha']);
    if (version >= 4 && fields['scaleEnd'] != null) {
      _integer(fields['scaleEnd'], 0, 32767);
    }
    if (version >= 4) {
      _boolean(fields['inheritBehaviors']);
      _choice(fields['draw'], {'billboard', 'directionalBillboard'});
    }
    if (version >= 6) _boolean(fields['inheritColor']);
    if (version >= 11) _boolean(fields['followEmitter']);
    final effectiveLifetime = ((lifetime * 255) >> 8) + 1;
    if ((version < 12 && effectiveLifetime < 2) || effectiveLifetime * delay > 524287) {
      throw const FormatException('Invalid SPL child timing');
    }
    final curve = _map(appearance['scale']);
    final maxScale = [
      curve['start'] as int,
      curve['middle'] as int,
      curve['end'] as int,
    ].reduce((first, second) => first > second ? first : second);
    final childScale =
        ((maxVariedScale * maxScale) ~/ 4096 * (scaleRatio + 1)) ~/ 64;
    if (childScale > (version >= 12 ? 1048512 : 32767)) {
      throw const FormatException('SPL child scale exceeds supported range');
    }
  }
}

void _curve(Object? value, int maximum, {bool alpha = false, bool allowOverlap = false}) {
  final curve = _map(value);
  _fields(curve, {
    'start',
    'middle',
    'end',
    'fadeIn',
    'fadeOut',
    'loop',
    if (alpha) 'randomRange',
  });
  for (final name in ['start', 'middle', 'end']) {
    _integer(curve[name], 0, maximum);
  }
  final fadeIn = _integer(curve['fadeIn'], 0, 254);
  final fadeOut = _integer(curve['fadeOut'], 0, 254);
  if (!allowOverlap && fadeIn > fadeOut) {
    throw const FormatException('Invalid SPL curve');
  }
  if (alpha) _integer(curve['randomRange'], 0, 255);
  _boolean(curve['loop']);
}

void _colorCurve(Object? value) {
  final curve = _map(value);
  _fields(curve, {
    'start',
    'middle',
    'end',
    'fadeIn',
    'peak',
    'fadeOut',
    'interpolate',
    'loop',
  });
  for (final name in ['start', 'middle', 'end']) {
    _color(curve[name]);
  }
  final fadeIn = _integer(curve['fadeIn'], 0, 255);
  final peak = _integer(curve['peak'], 0, 255);
  final fadeOut = _integer(curve['fadeOut'], 0, 255);
  if (fadeIn > peak || peak > fadeOut) {
    throw const FormatException('Invalid SPL color curve');
  }
  _boolean(curve['interpolate']);
  _boolean(curve['loop']);
}

void _vector(Object? value, int minimum, int maximum) {
  final vector = _map(value);
  _fields(vector, {'x', 'y', 'z'});
  for (final axis in ['x', 'y', 'z']) {
    _integer(vector[axis], minimum, maximum);
  }
}

void _color(Object? value) {
  final color = _map(value);
  _fields(color, {'red', 'green', 'blue'});
  for (final channel in ['red', 'green', 'blue']) {
    _integer(color[channel], 0, 31);
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid SPL object');
  }
  return value;
}

List<dynamic> _list(Object? value) {
  if (value is! List) throw const FormatException('Invalid SPL list');
  return value;
}

void _fields(Map<String, dynamic> value, Set<String> expected) {
  if (value.length != expected.length ||
      !value.keys.toSet().containsAll(expected)) {
    throw const FormatException('Invalid SPL fields');
  }
}

int _integer(Object? value, int minimum, int maximum) {
  if (value is! int || value < minimum || value > maximum) {
    throw const FormatException('Invalid SPL integer');
  }
  return value;
}

void _boolean(Object? value) {
  if (value is! bool) throw const FormatException('Invalid SPL boolean');
}

void _choice(Object? value, Set<String> choices) {
  if (value is! String || !choices.contains(value)) {
    throw const FormatException('Unsupported SPL choice');
  }
}

String _texture(Object? value) {
  if (value is! String ||
      value.isEmpty ||
      value.length > 256 ||
      value.trim() != value) {
    throw const FormatException('Invalid SPL texture reference');
  }
  return value;
}
