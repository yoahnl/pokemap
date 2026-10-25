import 'package:freezed_annotation/freezed_annotation.dart'
    show DeepCollectionEquality;
import 'project_model3d.dart';

final class SpatialAtmosphereDocument {
  SpatialAtmosphereDocument({required String mapId, required this.settings})
    : mapId = _mapId(mapId);
  final String mapId;
  final SpatialAtmosphereSettings settings;
  static const schemaVersion = 1;
  static const maxBytes = 65536;
  static String relativePathForMap(String mapId) =>
      'maps/${_mapId(mapId)}.atmosphere.json';
  factory SpatialAtmosphereDocument.fromJson(Map<String, dynamic> json) {
    _keys(json, {'schemaVersion', 'mapId', 'settings'});
    if (json['schemaVersion'] != schemaVersion)
      throw const FormatException('Unsupported atmosphere schema version.');
    return SpatialAtmosphereDocument(
      mapId: _string(json['mapId']),
      settings: SpatialAtmosphereSettings.fromJson(_object(json['settings'])),
    );
  }
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
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
    if (this.left >= this.right || this.top >= this.bottom)
      throw const FormatException(
        'Atmosphere UV mask must have positive area.',
      );
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
        colorRgb > 0xffffff)
      throw const FormatException('Invalid atmosphere window.');
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
        size.z <= 0)
      throw const FormatException('Invalid atmosphere firefly zone.');
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

final class SpatialAtmosphereSettings {
  SpatialAtmosphereSettings({
    this.waterAnimated = false,
    this.windowsLit = false,
    this.fireflies = false,
    num waterStrength = 1,
    num waterSpeed = 1,
    num windowStrength = 1,
    num fireflyDensity = 1,
    List<SpatialAtmosphereMaterialTarget> waterTargets = const [],
    List<SpatialAtmosphereWindow> windows = const [],
    List<SpatialAtmosphereFireflyZone> fireflyZones = const [],
  }) : waterStrength = _range(waterStrength, 0, 2),
       waterSpeed = _range(waterSpeed, 0, 3),
       windowStrength = _range(windowStrength, 0, 2),
       fireflyDensity = _range(fireflyDensity, 0, 2),
       waterTargets = List.unmodifiable(waterTargets),
       windows = List.unmodifiable(windows),
       fireflyZones = List.unmodifiable(fireflyZones) {
    if (waterTargets.length > 128 ||
        windows.length > 128 ||
        fireflyZones.length > 16 ||
        fireflyZones.fold<int>(0, (n, z) => n + z.count) > 64)
      throw const FormatException(
        'Atmosphere settings exceed presentation limits.',
      );
  }
  final bool waterAnimated, windowsLit, fireflies;
  final double waterStrength, waterSpeed, windowStrength, fireflyDensity;
  final List<SpatialAtmosphereMaterialTarget> waterTargets;
  final List<SpatialAtmosphereWindow> windows;
  final List<SpatialAtmosphereFireflyZone> fireflyZones;
  factory SpatialAtmosphereSettings.fromJson(Map<String, dynamic> json) {
    _keys(json, {
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
  if (json.keys.any((k) => !allowed.contains(k)))
    throw const FormatException('Unknown atmosphere property.');
}

Map<String, dynamic> _object(Object? v) {
  if (v is! Map<String, dynamic>)
    throw const FormatException('Expected atmosphere object.');
  return v;
}

List<dynamic> _list(Object? v, int max) {
  if (v is! List || v.length > max)
    throw const FormatException('Invalid atmosphere list.');
  return v;
}

String _string(Object? v) {
  if (v is! String) throw const FormatException('Expected atmosphere string.');
  return v;
}

String _name(String v) {
  if (v.trim().isEmpty || v.length > 256 || v.contains('\u0000'))
    throw const FormatException('Invalid atmosphere name.');
  return v;
}

String _mapId(String v) {
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$').hasMatch(v) ||
      v.contains('..'))
    throw const FormatException('Invalid atmosphere map id.');
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
  if (!v.isFinite || v < min || v > max)
    throw const FormatException('Atmosphere number outside supported range.');
  return v.toDouble();
}
