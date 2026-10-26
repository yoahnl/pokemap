enum SpatialWeatherKind {
  clear,
  cloudy,
  drizzle,
  rain,
  downpour,
  storm,
  snow,
  blizzard,
  hail,
  mist,
  fog,
  dust,
  sandstorm,
  petals,
  leaves;

  static SpatialWeatherKind parse(Object? value) {
    for (final kind in values) {
      if (kind.name == value) return kind;
    }
    throw const FormatException('Unknown weather style.');
  }
}

final class SpatialWeatherSettings {
  SpatialWeatherSettings({
    this.enabled = false,
    this.kind = SpatialWeatherKind.rain,
    num intensity = .7,
    num density = .75,
    num speed = 1,
    num windStrength = .25,
    num windDirection = 15,
    num particleSize = 1,
    num opacity = .7,
    num cloudCover = .5,
    num fogStrength = .35,
    num transitionSeconds = .6,
    this.lightning = false,
    this.indoors = false,
  }) : intensity = _range(intensity, 0, 1),
       density = _range(density, 0, 1),
       speed = _range(speed, .1, 3),
       windStrength = _range(windStrength, 0, 2),
       windDirection = _range(windDirection, -180, 180),
       particleSize = _range(particleSize, .25, 2),
       opacity = _range(opacity, 0, 1),
       cloudCover = _range(cloudCover, 0, 1),
       fogStrength = _range(fogStrength, 0, 1),
       transitionSeconds = _range(transitionSeconds, 0, 5);

  final bool enabled, lightning, indoors;
  final SpatialWeatherKind kind;
  final double intensity, density, speed, windStrength, windDirection;
  final double particleSize,
      opacity,
      cloudCover,
      fogStrength,
      transitionSeconds;
  bool get active =>
      enabled && kind != SpatialWeatherKind.clear && intensity > 0;
  bool get hasSettings => this != SpatialWeatherSettings();

  factory SpatialWeatherSettings.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => !keys.contains(key))) {
      throw const FormatException('Unknown weather property.');
    }
    return SpatialWeatherSettings(
      enabled: _boolean(json['enabled'], false),
      kind: json.containsKey('kind')
          ? SpatialWeatherKind.parse(json['kind'])
          : SpatialWeatherKind.rain,
      intensity: _number(json['intensity'], .7),
      density: _number(json['density'], .75),
      speed: _number(json['speed'], 1),
      windStrength: _number(json['windStrength'], .25),
      windDirection: _number(json['windDirection'], 15),
      particleSize: _number(json['particleSize'], 1),
      opacity: _number(json['opacity'], .7),
      cloudCover: _number(json['cloudCover'], .5),
      fogStrength: _number(json['fogStrength'], .35),
      transitionSeconds: _number(json['transitionSeconds'], .6),
      lightning: _boolean(json['lightning'], false),
      indoors: _boolean(json['indoors'], false),
    );
  }

  static const keys = {
    'enabled',
    'kind',
    'intensity',
    'density',
    'speed',
    'windStrength',
    'windDirection',
    'particleSize',
    'opacity',
    'cloudCover',
    'fogStrength',
    'transitionSeconds',
    'lightning',
    'indoors',
  };

  SpatialWeatherSettings copyWith({
    bool? enabled,
    SpatialWeatherKind? kind,
    num? intensity,
    num? density,
    num? speed,
    num? windStrength,
    num? windDirection,
    num? particleSize,
    num? opacity,
    num? cloudCover,
    num? fogStrength,
    num? transitionSeconds,
    bool? lightning,
    bool? indoors,
  }) => SpatialWeatherSettings(
    enabled: enabled ?? this.enabled,
    kind: kind ?? this.kind,
    intensity: intensity ?? this.intensity,
    density: density ?? this.density,
    speed: speed ?? this.speed,
    windStrength: windStrength ?? this.windStrength,
    windDirection: windDirection ?? this.windDirection,
    particleSize: particleSize ?? this.particleSize,
    opacity: opacity ?? this.opacity,
    cloudCover: cloudCover ?? this.cloudCover,
    fogStrength: fogStrength ?? this.fogStrength,
    transitionSeconds: transitionSeconds ?? this.transitionSeconds,
    lightning: lightning ?? this.lightning,
    indoors: indoors ?? this.indoors,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'kind': kind.name,
    'intensity': intensity,
    'density': density,
    'speed': speed,
    'windStrength': windStrength,
    'windDirection': windDirection,
    'particleSize': particleSize,
    'opacity': opacity,
    'cloudCover': cloudCover,
    'fogStrength': fogStrength,
    'transitionSeconds': transitionSeconds,
    'lightning': lightning,
    'indoors': indoors,
  };

  @override
  bool operator ==(Object other) =>
      other is SpatialWeatherSettings &&
      enabled == other.enabled &&
      kind == other.kind &&
      intensity == other.intensity &&
      density == other.density &&
      speed == other.speed &&
      windStrength == other.windStrength &&
      windDirection == other.windDirection &&
      particleSize == other.particleSize &&
      opacity == other.opacity &&
      cloudCover == other.cloudCover &&
      fogStrength == other.fogStrength &&
      transitionSeconds == other.transitionSeconds &&
      lightning == other.lightning &&
      indoors == other.indoors;

  @override
  int get hashCode => Object.hash(
    enabled,
    kind,
    intensity,
    density,
    speed,
    windStrength,
    windDirection,
    particleSize,
    opacity,
    cloudCover,
    fogStrength,
    transitionSeconds,
    lightning,
    indoors,
  );
}

double _range(num value, double minimum, double maximum) {
  if (!value.isFinite || value < minimum || value > maximum) {
    throw const FormatException('Invalid weather parameter range.');
  }
  return value.toDouble();
}

num _number(Object? value, num fallback) {
  if (value == null) return fallback;
  if (value is num) return value;
  throw const FormatException('Expected numeric weather parameter.');
}

bool _boolean(Object? value, bool fallback) {
  if (value == null) return fallback;
  if (value is bool) return value;
  throw const FormatException('Expected boolean weather parameter.');
}
