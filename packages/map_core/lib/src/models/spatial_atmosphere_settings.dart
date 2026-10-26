import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;
import 'project_model3d.dart';
import 'spatial_weather_settings.dart';

final class SpatialAtmosphereDocument {
  SpatialAtmosphereDocument({required String mapId, required this.settings})
    : mapId = _mapId(mapId);
  final String mapId;
  final SpatialAtmosphereSettings settings;
  static const schemaVersion = 2;
  static const lightWorkshopSchemaVersion = 3;
  static const weatherSchemaVersion = 4;
  static const weatherSoundSchemaVersion = 5;
  static const presentationOnly = true;
  static const absentDefaultsDisabled = true;
  static const maxBytes = 65536;
  static String relativePathForMap(String mapId) =>
      'maps/${_mapId(mapId)}.atmosphere.json';
  factory SpatialAtmosphereDocument.fromJson(Map<String, dynamic> json) {
    _keys(json, {'schemaVersion', 'mapId', 'settings'});
    if (json['schemaVersion'] is! int ||
        !{
          1,
          schemaVersion,
          lightWorkshopSchemaVersion,
          weatherSchemaVersion,
          weatherSoundSchemaVersion,
        }.contains(json['schemaVersion'])) {
      throw const FormatException('Unsupported atmosphere schema version.');
    }
    final settings = _object(json['settings']);
    final weather = settings['weather'];
    if ((json['schemaVersion'] as int) < weatherSoundSchemaVersion &&
        weather is Map &&
        weather.keys.any(SpatialWeatherSettings.soundKeys.contains)) {
      throw const FormatException(
        'Weather audio requires atmosphere schema 5.',
      );
    }
    if ((json['schemaVersion'] as int) < weatherSchemaVersion &&
        settings.containsKey('weather')) {
      throw const FormatException('Weather requires atmosphere schema 4.');
    }
    if (json['schemaVersion'] == 1 &&
        settings.keys.any(
          SpatialAtmosphereSettings.presentationKeys.contains,
        )) {
      throw const FormatException(
        'Presentation extensions require atmosphere schema 2.',
      );
    }
    if ((json['schemaVersion'] as int) < lightWorkshopSchemaVersion &&
        settings.keys.any(
          SpatialAtmosphereSettings.fireflyStyleKeys.contains,
        )) {
      throw const FormatException(
        'Firefly lighting requires atmosphere schema 3.',
      );
    }
    return SpatialAtmosphereDocument(
      mapId: _string(json['mapId']),
      settings: SpatialAtmosphereSettings.fromJson(settings),
    );
  }
  Map<String, dynamic> toJson() => {
    'schemaVersion': settings.weather.hasSoundSettings
        ? weatherSoundSchemaVersion
        : settings.weather.hasSettings
        ? weatherSchemaVersion
        : settings.hasFireflyStyle
        ? lightWorkshopSchemaVersion
        : schemaVersion,
    'mapId': mapId,
    'settings': settings.toJson(),
  };
}

final class SpatialAtmosphereMaterialTarget {
  SpatialAtmosphereMaterialTarget({
    this.instanceId,
    required String materialName,
  }) : materialName = _name(materialName) {
    if (instanceId != null) _name(instanceId!);
  }
  SpatialAtmosphereMaterialTarget.groundTileset(String tilesetId)
    : instanceId = null,
      materialName = 'ground:${_name(tilesetId)}';
  final String? instanceId;
  final String materialName;
  factory SpatialAtmosphereMaterialTarget.fromJson(Map<String, dynamic> json) {
    _keys(json, {'instanceId', 'materialName'});
    return SpatialAtmosphereMaterialTarget(
      instanceId: json['instanceId'] == null
          ? null
          : _string(json['instanceId']),
      materialName: _string(json['materialName']),
    );
  }
  Map<String, dynamic> toJson() => {
    'instanceId': instanceId,
    'materialName': materialName,
  };
}

final class SpatialAtmosphereUvRect {
  SpatialAtmosphereUvRect({
    required num left,
    required num top,
    required num right,
    required num bottom,
  }) : left = _range(left, 0, 1),
       top = _range(top, 0, 1),
       right = _range(right, 0, 1),
       bottom = _range(bottom, 0, 1) {
    if (this.left >= this.right || this.top >= this.bottom) {
      throw const FormatException(
        'Atmosphere UV mask must have positive area.',
      );
    }
  }
  final double left, top, right, bottom;
  factory SpatialAtmosphereUvRect.fromJson(Map<String, dynamic> json) {
    _keys(json, {'left', 'top', 'right', 'bottom'});
    return SpatialAtmosphereUvRect(
      left: _number(json['left']),
      top: _number(json['top']),
      right: _number(json['right']),
      bottom: _number(json['bottom']),
    );
  }
  Map<String, dynamic> toJson() => {
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };
}

final class SpatialAtmosphereWindow {
  SpatialAtmosphereWindow({
    required this.target,
    required List<SpatialAtmosphereUvRect> uvRects,
    this.colorRgb = 0xffcf73,
    num strength = .8,
  }) : uvRects = List.unmodifiable(uvRects),
       strength = _range(strength, 0, 2) {
    if (uvRects.isEmpty ||
        uvRects.length > 8 ||
        colorRgb < 0 ||
        colorRgb > 0xffffff) {
      throw const FormatException('Invalid atmosphere window.');
    }
  }
  final SpatialAtmosphereMaterialTarget target;
  final List<SpatialAtmosphereUvRect> uvRects;
  final int colorRgb;
  final double strength;
  factory SpatialAtmosphereWindow.fromJson(Map<String, dynamic> json) {
    _keys(json, {'target', 'uvRects', 'colorRgb', 'strength'});
    return SpatialAtmosphereWindow(
      target: SpatialAtmosphereMaterialTarget.fromJson(_object(json['target'])),
      uvRects: _list(
        json['uvRects'],
        8,
      ).map((r) => SpatialAtmosphereUvRect.fromJson(_object(r))).toList(),
      colorRgb: _integer(json['colorRgb']),
      strength: _number(json['strength']),
    );
  }
  Map<String, dynamic> toJson() => {
    'target': target.toJson(),
    'uvRects': uvRects.map((r) => r.toJson()).toList(),
    'colorRgb': colorRgb,
    'strength': strength,
  };
}

final class SpatialAtmosphereFireflyZone {
  SpatialAtmosphereFireflyZone({
    required this.bounds,
    this.count = 12,
    this.seed = 1,
  }) {
    final size = bounds.size;
    if (count < 1 ||
        count > 64 ||
        seed < 0 ||
        seed > 0x7fffffff ||
        size.x <= 0 ||
        size.y <= 0 ||
        size.z <= 0) {
      throw const FormatException('Invalid atmosphere firefly zone.');
    }
  }
  final Model3dBounds bounds;
  final int count, seed;
  factory SpatialAtmosphereFireflyZone.fromJson(Map<String, dynamic> json) {
    _keys(json, {'bounds', 'count', 'seed'});
    return SpatialAtmosphereFireflyZone(
      bounds: Model3dBounds.fromJson(_object(json['bounds'])),
      count: _integer(json['count']),
      seed: _integer(json['seed']),
    );
  }
  Map<String, dynamic> toJson() => {
    'bounds': bounds.toJson(),
    'count': count,
    'seed': seed,
  };
}

final class SpatialAtmosphereHalo {
  SpatialAtmosphereHalo({
    required String instanceId,
    required this.localPosition,
    num radiusX = .55,
    num radiusY = .55,
    num opacity = .22,
    this.colorRgb = 0xffcf83,
    this.window = false,
  }) : instanceId = _name(instanceId),
       radiusX = _range(radiusX, .01, 3),
       radiusY = _range(radiusY, .01, 3),
       opacity = _range(opacity, 0, .5) {
    for (final v in [localPosition.x, localPosition.y, localPosition.z]) {
      _range(v, -100000, 100000);
    }
    if (colorRgb < 0 || colorRgb > 0xffffff) {
      throw const FormatException('Invalid halo color.');
    }
  }
  final String instanceId;
  final Model3dVector3 localPosition;
  final double radiusX, radiusY, opacity;
  final int colorRgb;
  final bool window;
  factory SpatialAtmosphereHalo.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      'instanceId',
      'localPosition',
      'radiusX',
      'radiusY',
      'opacity',
      'colorRgb',
      'window',
    });
    return SpatialAtmosphereHalo(
      instanceId: _string(json['instanceId']),
      localPosition: Model3dVector3.fromJson(_object(json['localPosition'])),
      radiusX: _number(json['radiusX'] ?? .55),
      radiusY: _number(json['radiusY'] ?? .55),
      opacity: _number(json['opacity'] ?? .22),
      colorRgb: _integer(json['colorRgb'] ?? 0xffcf83),
      window: _boolean(json['window'], false),
    );
  }
  Map<String, dynamic> toJson() => {
    'instanceId': instanceId,
    'localPosition': localPosition.toJson(),
    'radiusX': radiusX,
    'radiusY': radiusY,
    'opacity': opacity,
    'colorRgb': colorRgb,
    'window': window,
  };
}

final class SpatialAtmosphereSettings {
  static const presentationKeys = {
    'halosEnabled',
    'haloStrength',
    'haloSpread',
    'halos',
    'depthFogEnabled',
    'depthOfFieldEnabled',
    'depthOfFieldStrength',
    'depthOfFieldFocusRange',
    'fogOpacity',
    'fogStart',
    'fogEnd',
  };
  static const fireflyStyleKeys = {
    'fireflyLighting',
    'fireflyYellowAmount',
    'fireflyGreenAmount',
    'fireflyBlueAmount',
    'fireflyPinkAmount',
    'fireflyLightStrength',
    'fireflyLightRadius',
  };
  SpatialAtmosphereSettings({
    SpatialWeatherSettings? weather,
    this.waterAnimated = false,
    this.windowsLit = false,
    this.fireflies = false,
    this.fireflyLighting = false,
    num fireflyYellowAmount = 1,
    num fireflyGreenAmount = 0,
    num fireflyBlueAmount = 0,
    num fireflyPinkAmount = 0,
    num fireflyLightStrength = 0.18,
    num fireflyLightRadius = 1.2,

    this.halosEnabled = false,
    this.depthFogEnabled = false,
    this.depthOfFieldEnabled = false,
    num depthOfFieldStrength = .35,
    num depthOfFieldFocusRange = 12,
    num haloStrength = 1,
    num haloSpread = 1,
    num fogOpacity = .2,
    num fogStart = 14,
    num fogEnd = 35,
    List<SpatialAtmosphereHalo> halos = const [],
    num waterStrength = 1,
    num waterSpeed = 1,
    num windowStrength = 1,
    num fireflyDensity = 1,
    List<SpatialAtmosphereMaterialTarget> waterTargets = const [],
    List<SpatialAtmosphereWindow> windows = const [],
    List<SpatialAtmosphereFireflyZone> fireflyZones = const [],
  }) : weather = weather ?? SpatialWeatherSettings(),
       fireflyYellowAmount = _range(fireflyYellowAmount, 0, 1),
       fireflyGreenAmount = _range(fireflyGreenAmount, 0, 1),
       fireflyBlueAmount = _range(fireflyBlueAmount, 0, 1),
       fireflyPinkAmount = _range(fireflyPinkAmount, 0, 1),
       fireflyLightStrength = _range(fireflyLightStrength, 0, 1),
       fireflyLightRadius = _range(fireflyLightRadius, .25, 2.5),
       depthOfFieldStrength = _range(depthOfFieldStrength, 0, 1),
       depthOfFieldFocusRange = _range(depthOfFieldFocusRange, 2, 40),
       haloStrength = _range(haloStrength, 0, 2),
       haloSpread = _range(haloSpread, .1, 3),
       fogOpacity = _range(fogOpacity, 0, .5),
       fogStart = _range(fogStart, 0, 100000),
       fogEnd = _range(fogEnd, 0, 100000),
       halos = List.unmodifiable(halos),
       waterStrength = _range(waterStrength, 0, 2),
       waterSpeed = _range(waterSpeed, 0, 3),
       windowStrength = _range(windowStrength, 0, 2),
       fireflyDensity = _range(fireflyDensity, 0, 2),
       waterTargets = List.unmodifiable(waterTargets),
       windows = List.unmodifiable(windows),
       fireflyZones = List.unmodifiable(fireflyZones) {
    if (this.fogEnd <= this.fogStart ||
        halos.length > 32 ||
        waterTargets.length > 128 ||
        windows.length > 128 ||
        fireflyZones.length > 16 ||
        fireflyZones.fold<int>(0, (n, z) => n + z.count) > 64) {
      throw const FormatException(
        'Atmosphere settings exceed presentation limits.',
      );
    }
  }
  final bool fireflyLighting;
  final SpatialWeatherSettings weather;
  final double fireflyYellowAmount,
      fireflyGreenAmount,
      fireflyBlueAmount,
      fireflyPinkAmount,
      fireflyLightStrength,
      fireflyLightRadius;
  bool get hasFireflyStyle =>
      fireflyLighting ||
      fireflyYellowAmount != 1 ||
      fireflyGreenAmount != 0 ||
      fireflyBlueAmount != 0 ||
      fireflyPinkAmount != 0 ||
      fireflyLightStrength != 0.18 ||
      fireflyLightRadius != 1.2;
  final bool waterAnimated, windowsLit, fireflies;
  final bool halosEnabled, depthFogEnabled, depthOfFieldEnabled;
  final double depthOfFieldStrength, depthOfFieldFocusRange;
  final double haloStrength, haloSpread, fogOpacity, fogStart, fogEnd;
  final List<SpatialAtmosphereHalo> halos;
  final double waterStrength, waterSpeed, windowStrength, fireflyDensity;
  final List<SpatialAtmosphereMaterialTarget> waterTargets;
  final List<SpatialAtmosphereWindow> windows;
  final List<SpatialAtmosphereFireflyZone> fireflyZones;
  factory SpatialAtmosphereSettings.fromJson(Map<String, dynamic> json) {
    _keys(json, {
      ...presentationKeys,
      ...fireflyStyleKeys,
      'weather',
      'waterAnimated',
      'windowsLit',
      'fireflies',
      'waterStrength',
      'waterSpeed',
      'windowStrength',
      'fireflyDensity',
      'waterTargets',
      'windows',
      'fireflyZones',
    });
    return SpatialAtmosphereSettings(
      weather: json['weather'] == null
          ? null
          : SpatialWeatherSettings.fromJson(_object(json['weather'])),
      fireflyLighting: _boolean(json['fireflyLighting'], false),
      fireflyYellowAmount: _number(json['fireflyYellowAmount'] ?? 1),
      fireflyGreenAmount: _number(json['fireflyGreenAmount'] ?? 0),
      fireflyBlueAmount: _number(json['fireflyBlueAmount'] ?? 0),
      fireflyPinkAmount: _number(json['fireflyPinkAmount'] ?? 0),
      fireflyLightStrength: _number(json['fireflyLightStrength'] ?? 0.18),
      fireflyLightRadius: _number(json['fireflyLightRadius'] ?? 1.2),
      halosEnabled: _boolean(json['halosEnabled'], false),
      depthFogEnabled: _boolean(json['depthFogEnabled'], false),
      depthOfFieldEnabled: _boolean(json['depthOfFieldEnabled'], false),
      depthOfFieldStrength: _number(json['depthOfFieldStrength'] ?? .35),
      depthOfFieldFocusRange: _number(json['depthOfFieldFocusRange'] ?? 12),
      haloStrength: _number(json['haloStrength'] ?? 1),
      haloSpread: _number(json['haloSpread'] ?? 1),
      fogOpacity: _number(json['fogOpacity'] ?? .2),
      fogStart: _number(json['fogStart'] ?? 14),
      fogEnd: _number(json['fogEnd'] ?? 35),
      halos: _list(
        json['halos'] ?? [],
        32,
      ).map((v) => SpatialAtmosphereHalo.fromJson(_object(v))).toList(),
      waterAnimated: _boolean(json['waterAnimated'], false),
      windowsLit: _boolean(json['windowsLit'], false),
      fireflies: _boolean(json['fireflies'], false),
      waterStrength: _number(json['waterStrength'] ?? 1),
      waterSpeed: _number(json['waterSpeed'] ?? 1),
      windowStrength: _number(json['windowStrength'] ?? 1),
      fireflyDensity: _number(json['fireflyDensity'] ?? 1),
      waterTargets: _list(json['waterTargets'] ?? [], 128)
          .map((v) => SpatialAtmosphereMaterialTarget.fromJson(_object(v)))
          .toList(),
      windows: _list(
        json['windows'] ?? [],
        128,
      ).map((v) => SpatialAtmosphereWindow.fromJson(_object(v))).toList(),
      fireflyZones: _list(
        json['fireflyZones'] ?? [],
        16,
      ).map((v) => SpatialAtmosphereFireflyZone.fromJson(_object(v))).toList(),
    );
  }
  SpatialAtmosphereSettings copyWith({
    SpatialWeatherSettings? weather,
    bool? fireflyLighting,
    num? fireflyYellowAmount,
    num? fireflyGreenAmount,
    num? fireflyBlueAmount,
    num? fireflyPinkAmount,
    num? fireflyLightStrength,
    num? fireflyLightRadius,

    bool? halosEnabled,
    bool? depthFogEnabled,
    bool? depthOfFieldEnabled,
    num? depthOfFieldStrength,
    num? depthOfFieldFocusRange,
    num? haloStrength,
    num? haloSpread,
    num? fogOpacity,
    num? fogStart,
    num? fogEnd,
    List<SpatialAtmosphereHalo>? halos,
    bool? waterAnimated,
    bool? windowsLit,
    bool? fireflies,
    num? waterStrength,
    num? waterSpeed,
    num? windowStrength,
    num? fireflyDensity,
    List<SpatialAtmosphereMaterialTarget>? waterTargets,
    List<SpatialAtmosphereWindow>? windows,
    List<SpatialAtmosphereFireflyZone>? fireflyZones,
  }) => SpatialAtmosphereSettings(
    weather: weather ?? this.weather,
    fireflyLighting: fireflyLighting ?? this.fireflyLighting,
    fireflyYellowAmount: fireflyYellowAmount ?? this.fireflyYellowAmount,
    fireflyGreenAmount: fireflyGreenAmount ?? this.fireflyGreenAmount,
    fireflyBlueAmount: fireflyBlueAmount ?? this.fireflyBlueAmount,
    fireflyPinkAmount: fireflyPinkAmount ?? this.fireflyPinkAmount,
    fireflyLightStrength: fireflyLightStrength ?? this.fireflyLightStrength,
    fireflyLightRadius: fireflyLightRadius ?? this.fireflyLightRadius,
    halosEnabled: halosEnabled ?? this.halosEnabled,
    depthFogEnabled: depthFogEnabled ?? this.depthFogEnabled,
    depthOfFieldEnabled: depthOfFieldEnabled ?? this.depthOfFieldEnabled,
    depthOfFieldStrength: depthOfFieldStrength ?? this.depthOfFieldStrength,
    depthOfFieldFocusRange:
        depthOfFieldFocusRange ?? this.depthOfFieldFocusRange,
    haloStrength: haloStrength ?? this.haloStrength,
    haloSpread: haloSpread ?? this.haloSpread,
    fogOpacity: fogOpacity ?? this.fogOpacity,
    fogStart: fogStart ?? this.fogStart,
    fogEnd: fogEnd ?? this.fogEnd,
    halos: halos ?? this.halos,
    waterAnimated: waterAnimated ?? this.waterAnimated,
    windowsLit: windowsLit ?? this.windowsLit,
    fireflies: fireflies ?? this.fireflies,
    waterStrength: waterStrength ?? this.waterStrength,
    waterSpeed: waterSpeed ?? this.waterSpeed,
    windowStrength: windowStrength ?? this.windowStrength,
    fireflyDensity: fireflyDensity ?? this.fireflyDensity,
    waterTargets: waterTargets ?? this.waterTargets,
    windows: windows ?? this.windows,
    fireflyZones: fireflyZones ?? this.fireflyZones,
  );
  Map<String, dynamic> toJson() => {
    if (weather.hasSettings) 'weather': weather.toJson(),
    if (hasFireflyStyle) ...{
      'fireflyLighting': fireflyLighting,
      'fireflyYellowAmount': fireflyYellowAmount,
      'fireflyGreenAmount': fireflyGreenAmount,
      'fireflyBlueAmount': fireflyBlueAmount,
      'fireflyPinkAmount': fireflyPinkAmount,
      'fireflyLightStrength': fireflyLightStrength,
      'fireflyLightRadius': fireflyLightRadius,
    },
    'halosEnabled': halosEnabled,
    'depthFogEnabled': depthFogEnabled,
    'depthOfFieldEnabled': depthOfFieldEnabled,
    'depthOfFieldStrength': depthOfFieldStrength,
    'depthOfFieldFocusRange': depthOfFieldFocusRange,
    'haloStrength': haloStrength,
    'haloSpread': haloSpread,
    'fogOpacity': fogOpacity,
    'fogStart': fogStart,
    'fogEnd': fogEnd,
    'halos': halos.map((v) => v.toJson()).toList(),
    'waterAnimated': waterAnimated,
    'windowsLit': windowsLit,
    'fireflies': fireflies,
    'waterStrength': waterStrength,
    'waterSpeed': waterSpeed,
    'windowStrength': windowStrength,
    'fireflyDensity': fireflyDensity,
    'waterTargets': waterTargets.map((v) => v.toJson()).toList(),
    'windows': windows.map((v) => v.toJson()).toList(),
    'fireflyZones': fireflyZones.map((v) => v.toJson()).toList(),
  };
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpatialAtmosphereSettings &&
          const DeepCollectionEquality().equals(toJson(), other.toJson());
  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());
}

void _keys(Map<String, dynamic> json, Set<String> allowed) {
  if (json.keys.any((k) => !allowed.contains(k))) {
    throw const FormatException('Unknown atmosphere property.');
  }
}

Map<String, dynamic> _object(Object? v) {
  if (v is! Map<String, dynamic>) {
    throw const FormatException('Expected atmosphere object.');
  }
  return v;
}

List<dynamic> _list(Object? v, int max) {
  if (v is! List || v.length > max) {
    throw const FormatException('Invalid atmosphere list.');
  }
  return v;
}

String _string(Object? v) {
  if (v is! String) throw const FormatException('Expected atmosphere string.');
  return v;
}

String _name(String v) {
  if (v.trim().isEmpty || v.length > 256 || v.contains('\u0000')) {
    throw const FormatException('Invalid atmosphere name.');
  }
  return v;
}

String _mapId(String v) {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$').hasMatch(v) ||
      v.contains('..')) {
    throw const FormatException('Invalid atmosphere map id.');
  }
  return v;
}

num _number(Object? v) {
  if (v is! num) throw const FormatException('Expected atmosphere number.');
  return v;
}

int _integer(Object? v) {
  if (v is! int) throw const FormatException('Expected atmosphere integer.');
  return v;
}

bool _boolean(Object? v, bool fallback) {
  if (v == null) return fallback;
  if (v is! bool) throw const FormatException('Expected atmosphere boolean.');
  return v;
}

double _range(num v, double min, double max) {
  if (!v.isFinite || v < min || v > max) {
    throw const FormatException('Atmosphere number outside supported range.');
  }
  return v.toDouble();
}
