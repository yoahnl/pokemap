import 'dart:convert';

final class BattleSplParticleDefinition {
  BattleSplParticleDefinition._(this.emitters, this.textureIds);

  final List<BattleSplEmitterDefinition> emitters;
  final Set<String> textureIds;

  factory BattleSplParticleDefinition.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> copy;
    try {
      copy = (jsonDecode(jsonEncode(json)) as Map).cast<String, dynamic>();
    } on Object {
      throw const FormatException('Invalid SPL particle definition');
    }
    _fields(copy, {'schemaVersion', 'emitters'});
    if (copy['schemaVersion'] is! int || copy['schemaVersion'] != 2) {
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
      _validateEmitter(emitter, textures);
      emitters.add(BattleSplEmitterDefinition._(emitter));
    }
    return BattleSplParticleDefinition._(
      List.unmodifiable(emitters),
      Set.unmodifiable(textures),
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 2,
    'emitters': [for (final emitter in emitters) emitter.toJson()],
  };
}

final class BattleSplEmitterDefinition {
  const BattleSplEmitterDefinition._(this._json);

  final Map<String, dynamic> _json;

  Map<String, dynamic> toJson() =>
      (jsonDecode(jsonEncode(_json)) as Map).cast<String, dynamic>();
}

void _validateEmitter(Map<String, dynamic> emitter, Set<String> textures) {
  _fields(emitter, {'emission', 'appearance', 'motion', 'child'});
  final emission = _map(emitter['emission']);
  _fields(emission, {
    'shape',
    'origin',
    'axis',
    'radius',
    'axisVelocity',
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
  });
  _choice(emission['shape'], {'point', 'sphereSurface'});
  _vector(emission['origin'], -2147483648, 2147483647);
  _vector(emission['axis'], -32768, 32767);
  final radius = _integer(emission['radius'], 0, 32767);
  if (emission['shape'] == 'point' && radius != 0) {
    throw const FormatException('Point SPL emitter cannot have a radius');
  }
  if (emission['shape'] == 'sphereSurface' && radius == 0) {
    throw const FormatException('Zero-radius SPL sphere is unsupported');
  }
  _integer(emission['axisVelocity'], -32768, 32767);
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
  });
  _choice(appearance['draw'], {'billboard', 'directionalBillboard'});
  _choice(appearance['scaleAxis'], {'x', 'y', 'xy'});
  final baseScale = _integer(appearance['baseScale'], 0, 32767);
  final maxVariedScale = (baseScale * (255 + scaleVariance)) >> 8;
  if (maxVariedScale > 32767) {
    throw const FormatException('SPL initial scale exceeds supported range');
  }
  _integer(appearance['aspectRatio'], 0, 32767);
  _integer(appearance['baseAlpha'], 0, 31);
  _integer(appearance['loopTime'], 1, 65535);
  _curve(appearance['scale'], 32767);
  _curve(appearance['alpha'], 31, alpha: true);
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
  _fields(motion, {'gravity', 'airResistance'});
  _vector(motion['gravity'], -32768, 32767);
  _integer(motion['airResistance'], 0, 255);

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
    final effectiveLifetime = ((lifetime * 255) >> 8) + 1;
    if (effectiveLifetime < 2 || effectiveLifetime * delay > 524287) {
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
    if (childScale > 32767) {
      throw const FormatException('SPL child scale exceeds supported range');
    }
  }
}

void _curve(Object? value, int maximum, {bool alpha = false}) {
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
  if (fadeIn > fadeOut) throw const FormatException('Invalid SPL curve');
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
