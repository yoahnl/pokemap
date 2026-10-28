enum ModelLightProximityMode { near, far }

enum ModelLightFlameStyle { candle, brazier }

final class ModelLightFlame {
  ModelLightFlame({
    num height = .35,
    num flicker = .12,
    this.style = ModelLightFlameStyle.candle,
    num embers = 0,
    num crackleVolume = 0,
  }) : height = _range(height, .03, 8),
       flicker = _range(flicker, 0, .4),
       embers = _range(embers, 0, 1),
       crackleVolume = _range(crackleVolume, 0, 1);

  final double height, flicker, embers, crackleVolume;
  final ModelLightFlameStyle style;

  factory ModelLightFlame.fromJson(Map<String, dynamic> json) {
    _keys(json, {'height', 'flicker', 'style', 'embers', 'crackleVolume'});
    return ModelLightFlame(
      height: _number(json['height'] ?? .35),
      flicker: _number(json['flicker'] ?? .12),
      embers: _number(json['embers'] ?? 0),
      crackleVolume: _number(json['crackleVolume'] ?? 0),
      style: switch (json['style']) {
        null || 'candle' => ModelLightFlameStyle.candle,
        'brazier' => ModelLightFlameStyle.brazier,
        _ => throw const FormatException('Unknown flame style.'),
      },
    );
  }

  Map<String, dynamic> toJson() => {
    'height': height,
    'flicker': flicker,
    if (style != ModelLightFlameStyle.candle) 'style': style.name,
    if (embers > 0) 'embers': embers,
    if (crackleVolume > 0) 'crackleVolume': crackleVolume,
  };

  @override
  bool operator ==(Object other) =>
      other is ModelLightFlame &&
      height == other.height &&
      flicker == other.flicker &&
      style == other.style &&
      embers == other.embers &&
      crackleVolume == other.crackleVolume;

  @override
  int get hashCode =>
      Object.hash(height, flicker, style, embers, crackleVolume);
}

final class ModelLightColorCycle {
  ModelLightColorCycle({required List<int> colors, num periodSeconds = 10})
    : colors = List.unmodifiable(colors),
      periodSeconds = _range(periodSeconds, 2, 300) {
    if (colors.length < 2 ||
        colors.length > 8 ||
        colors.any((color) => color < 0 || color > 0xffffff)) {
      throw const FormatException(
        'A light cycle needs two to eight RGB colors.',
      );
    }
  }
  final List<int> colors;
  final double periodSeconds;
  factory ModelLightColorCycle.fromJson(Map<String, dynamic> json) {
    _keys(json, {'colors', 'periodSeconds'});
    final colors = json['colors'];
    if (colors is! List || colors.any((color) => color is! int)) {
      throw const FormatException('Light cycle colors must be RGB integers.');
    }
    return ModelLightColorCycle(
      colors: colors.cast<int>(),
      periodSeconds: _number(json['periodSeconds'] ?? 10),
    );
  }
  Map<String, dynamic> toJson() => {
    'colors': colors,
    'periodSeconds': periodSeconds,
  };
  int sample(double elapsedSeconds) {
    if (!elapsedSeconds.isFinite) {
      throw ArgumentError.value(elapsedSeconds, 'elapsedSeconds');
    }
    final phase =
        (elapsedSeconds % periodSeconds) / periodSeconds * colors.length;
    final index = phase.floor(), t = phase - phase.floor();
    final a = colors[index], b = colors[(index + 1) % colors.length];
    int channel(int shift) =>
        (((a >> shift) & 255) +
                (((b >> shift) & 255) - ((a >> shift) & 255)) * t)
            .round();
    return channel(16) << 16 | channel(8) << 8 | channel(0);
  }

  @override
  bool operator ==(Object other) =>
      other is ModelLightColorCycle &&
      periodSeconds == other.periodSeconds &&
      colors.length == other.colors.length &&
      colors.indexed.every((entry) => entry.$2 == other.colors[entry.$1]);
  @override
  int get hashCode => Object.hash(periodSeconds, Object.hashAll(colors));
}

final class ModelLightProximity {
  ModelLightProximity({
    this.mode = ModelLightProximityMode.near,
    num enterDistance = 3,
    num exitDistance = 4,
    num fadeSeconds = .35,
  }) : enterDistance = _range(enterDistance, .25, 64),
       exitDistance = _range(exitDistance, .26, 128),
       fadeSeconds = _range(fadeSeconds, .05, 5) {
    if (this.exitDistance <= this.enterDistance) {
      throw const FormatException(
        'The leave distance must exceed the approach distance.',
      );
    }
  }
  final ModelLightProximityMode mode;
  final double enterDistance, exitDistance, fadeSeconds;
  factory ModelLightProximity.fromJson(Map<String, dynamic> json) {
    _keys(json, {'mode', 'enterDistance', 'exitDistance', 'fadeSeconds'});
    final mode = ModelLightProximityMode.values
        .where((v) => v.name == json['mode'])
        .firstOrNull;
    if (mode == null) {
      throw const FormatException('Invalid light proximity mode.');
    }
    return ModelLightProximity(
      mode: mode,
      enterDistance: _number(json['enterDistance'] ?? 3),
      exitDistance: _number(json['exitDistance'] ?? 4),
      fadeSeconds: _number(json['fadeSeconds'] ?? .35),
    );
  }
  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'enterDistance': enterDistance,
    'exitDistance': exitDistance,
    'fadeSeconds': fadeSeconds,
  };
  @override
  bool operator ==(Object other) =>
      other is ModelLightProximity &&
      mode == other.mode &&
      enterDistance == other.enterDistance &&
      exitDistance == other.exitDistance &&
      fadeSeconds == other.fadeSeconds;
  @override
  int get hashCode =>
      Object.hash(mode, enterDistance, exitDistance, fadeSeconds);
}

double _number(Object? value) {
  if (value is! num || !value.isFinite) {
    throw const FormatException('A finite light value is required.');
  }
  return value.toDouble();
}

double _range(num value, double min, double max) {
  if (!value.isFinite || value < min || value > max) {
    throw const FormatException(
      'Light behavior value is outside its supported range.',
    );
  }
  return value.toDouble();
}

void _keys(Map<String, dynamic> json, Set<String> allowed) {
  if (json.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Unknown light behavior property.');
  }
}
