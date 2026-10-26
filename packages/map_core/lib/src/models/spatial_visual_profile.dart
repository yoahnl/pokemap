import 'map_spatial_scene.dart';
import 'spatial_atmosphere_settings.dart';
import 'spatial_day_night_cycle.dart';

enum SpatialVisualParameter {
  pitchDegrees(1, 89),
  yawDegrees(-360, 360),
  fieldOfViewDegrees(1.01, 119.99),
  cameraDistance(.01, 10000),
  lockVerticalFraming.boolean(),
  dayNightEnabled.boolean(),
  dayDurationSeconds(10, 86400),
  minuteOfDay(0, 1439),
  depthOfFieldEnabled.boolean(),
  depthOfFieldStrength(0, 1),
  depthOfFieldFocusRange(2, 40),
  halosEnabled.boolean(),
  haloStrength(0, 2),
  haloSpread(.1, 3),
  depthFogEnabled.boolean(),
  fogOpacity(0, .5),
  fogStart(0, 99999.99),
  fogEnd(.01, 100000),
  waterAnimated.boolean(),
  waterStrength(0, 2),
  waterSpeed(0, 3),
  windowsLit.boolean(),
  windowStrength(0, 2),
  fireflies.boolean(),
  fireflyDensity(0, 2);

  const SpatialVisualParameter(this.minimum, this.maximum) : isBoolean = false;
  const SpatialVisualParameter.boolean()
    : minimum = 0,
      maximum = 1,
      isBoolean = true;
  final double minimum, maximum;
  final bool isBoolean;
  bool get isCamera => index <= lockVerticalFraming.index;
  bool get isClock =>
      index >= dayNightEnabled.index && index <= minuteOfDay.index;
  bool get isAtmosphere => !isCamera && !isClock;

  Object normalize(Object? value) {
    if (isBoolean) {
      if (value is bool) return value;
    } else if (value is num &&
        value.isFinite &&
        value >= minimum &&
        value <= maximum) {
      return value.toDouble();
    }
    throw FormatException('Invalid visual parameter $name.');
  }
}

final class SpatialVisualPatch {
  SpatialVisualPatch([Map<SpatialVisualParameter, Object> values = const {}])
    : values = Map.unmodifiable({
        for (final e in values.entries) e.key: e.key.normalize(e.value),
      }) {
    final start = number(SpatialVisualParameter.fogStart);
    final end = number(SpatialVisualParameter.fogEnd);
    if (start != null && end != null && start >= end) {
      throw const FormatException('Fog must end after its start.');
    }
  }
  final Map<SpatialVisualParameter, Object> values;
  bool get isEmpty => values.isEmpty;
  Object? value(SpatialVisualParameter parameter) => values[parameter];
  double? number(SpatialVisualParameter parameter) =>
      values[parameter] as double?;
  bool? enabled(SpatialVisualParameter parameter) => values[parameter] as bool?;

  factory SpatialVisualPatch.fromScene({
    required SpatialCameraProfile camera,
    required SpatialAtmosphereSettings atmosphere,
    SpatialDayNightCycle? cycle,
  }) => SpatialVisualPatch.fromJson({
    'pitchDegrees': camera.pitchDegrees,
    'yawDegrees': camera.yawDegrees,
    'fieldOfViewDegrees': camera.fieldOfViewDegrees,
    'cameraDistance': camera.distance,
    'lockVerticalFraming': false,
    'dayNightEnabled': cycle != null,
    'dayDurationSeconds': cycle?.durationSeconds ?? 1200,
    'minuteOfDay': cycle?.startMinuteOfDay ?? 720,
    for (final e in atmosphere.toJson().entries)
      if (SpatialVisualParameter.values.any(
        (p) => p.isAtmosphere && p.name == e.key,
      ))
        e.key: e.value,
  });

  factory SpatialVisualPatch.fromJson(Map<String, dynamic> json) {
    final result = <SpatialVisualParameter, Object>{};
    for (final e in json.entries) {
      final parameter = SpatialVisualParameter.values
          .where((p) => p.name == e.key)
          .firstOrNull;
      if (parameter == null) {
        throw FormatException('Unknown visual parameter ${e.key}.');
      }
      result[parameter] = parameter.normalize(e.value);
    }
    return SpatialVisualPatch(result);
  }

  Map<String, dynamic> toJson() => {
    for (final e in values.entries) e.key.name: e.value,
  };
  SpatialVisualPatch set(SpatialVisualParameter parameter, Object? value) =>
      SpatialVisualPatch(
        {...values, if (value != null) parameter: parameter.normalize(value)}
          ..removeWhere((key, _) => key == parameter && value == null),
      );
  SpatialVisualPatch overriddenBy(SpatialVisualPatch override) {
    if (override.isEmpty) return this;
    final merged = {...values, ...override.values};
    final start = merged[SpatialVisualParameter.fogStart] as double?;
    final end = merged[SpatialVisualParameter.fogEnd] as double?;
    if (start != null && end != null && start >= end) {
      if (override.value(SpatialVisualParameter.fogStart) != null) {
        merged[SpatialVisualParameter.fogEnd] = start + .01;
      } else {
        merged[SpatialVisualParameter.fogStart] = (end - .01).clamp(0, end);
      }
    }
    return SpatialVisualPatch(merged);
  }

  SpatialCameraProfile applyCamera(SpatialCameraProfile base) =>
      values.keys.any(
        (p) => p.isCamera && p != SpatialVisualParameter.lockVerticalFraming,
      )
      ? base.copyWith(
          pitchDegrees: number(SpatialVisualParameter.pitchDegrees),
          yawDegrees: number(SpatialVisualParameter.yawDegrees),
          fieldOfViewDegrees: number(SpatialVisualParameter.fieldOfViewDegrees),
          distance: number(SpatialVisualParameter.cameraDistance),
        )
      : base;
  SpatialAtmosphereSettings applyAtmosphere(SpatialAtmosphereSettings base) {
    if (!values.keys.any((p) => p.isAtmosphere)) return base;
    final fog = SpatialVisualPatch({
      SpatialVisualParameter.fogStart: base.fogStart,
      SpatialVisualParameter.fogEnd: base.fogEnd,
    }).overriddenBy(this);
    return base.copyWith(
      depthOfFieldEnabled: enabled(SpatialVisualParameter.depthOfFieldEnabled),
      depthOfFieldStrength: number(SpatialVisualParameter.depthOfFieldStrength),
      depthOfFieldFocusRange: number(
        SpatialVisualParameter.depthOfFieldFocusRange,
      ),
      halosEnabled: enabled(SpatialVisualParameter.halosEnabled),
      haloStrength: number(SpatialVisualParameter.haloStrength),
      haloSpread: number(SpatialVisualParameter.haloSpread),
      depthFogEnabled: enabled(SpatialVisualParameter.depthFogEnabled),
      fogOpacity: number(SpatialVisualParameter.fogOpacity),
      fogStart: fog.number(SpatialVisualParameter.fogStart),
      fogEnd: fog.number(SpatialVisualParameter.fogEnd),
      waterAnimated: enabled(SpatialVisualParameter.waterAnimated),
      waterStrength: number(SpatialVisualParameter.waterStrength),
      waterSpeed: number(SpatialVisualParameter.waterSpeed),
      windowsLit: enabled(SpatialVisualParameter.windowsLit),
      windowStrength: number(SpatialVisualParameter.windowStrength),
      fireflies: enabled(SpatialVisualParameter.fireflies),
      fireflyDensity: number(SpatialVisualParameter.fireflyDensity),
    );
  }

  SpatialDayNightCycle? applyCycle(SpatialDayNightCycle? base) {
    if (!values.keys.any((p) => p.isClock)) return base;
    if (enabled(SpatialVisualParameter.dayNightEnabled) == false) return null;
    if (base == null &&
        enabled(SpatialVisualParameter.dayNightEnabled) != true) {
      return null;
    }
    return SpatialDayNightCycle(
      durationSeconds:
          number(SpatialVisualParameter.dayDurationSeconds) ??
          base?.durationSeconds ??
          1200,
      startMinuteOfDay:
          number(SpatialVisualParameter.minuteOfDay)?.round() ??
          base?.startMinuteOfDay ??
          720,
    );
  }

  static SpatialVisualPatch interpolate(
    SpatialVisualPatch from,
    SpatialVisualPatch to,
    double progress,
  ) {
    if (!progress.isFinite) {
      throw const FormatException('Invalid visual transition progress.');
    }
    final t = progress.clamp(0.0, 1.0);
    return SpatialVisualPatch({
      for (final p in from.values.keys.toSet().union(to.values.keys.toSet()))
        p: switch ((from.values[p], to.values[p])) {
          (final double a, final double b) => a + (b - a) * t,
          (final bool a, final bool b) => b || t >= 1 ? b : a,
          (_, final bool b) => b,
          (_, final Object b) => b,
          (final Object a, null) => a,
          _ => throw const FormatException('Missing visual transition value.'),
        },
    });
  }

  @override
  bool operator ==(Object other) =>
      other is SpatialVisualPatch &&
      values.length == other.values.length &&
      values.entries.every((entry) => other.values[entry.key] == entry.value);
  @override
  int get hashCode => Object.hashAllUnordered(
    values.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

final class SpatialVisualDocument {
  SpatialVisualDocument({required this.profile, this.mapId}) {
    if (mapId != null) relativePathForMap(mapId!);
  }
  static const capabilityId = 'map3d.visual-profile@1';
  static const schemaVersion = 1;
  static const maxBytes = 32768;
  static const projectRelativePath = 'project.visual.json';
  final String? mapId;
  final SpatialVisualPatch profile;
  String get relativePath =>
      mapId == null ? projectRelativePath : relativePathForMap(mapId!);
  static String relativePathForMap(String id) {
    if (id.isEmpty ||
        id.length > 120 ||
        id.trim() != id ||
        id.contains('/') ||
        id.contains('\\') ||
        id == '.' ||
        id == '..' ||
        id.runes.any((rune) => rune < 32 || rune == 127)) {
      throw const FormatException('Invalid visual map identity.');
    }
    return 'maps/$id.visual.json';
  }

  factory SpatialVisualDocument.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != schemaVersion ||
        json.keys.any(
          (key) => !{'schemaVersion', 'mapId', 'profile'}.contains(key),
        ) ||
        (json['mapId'] != null && json['mapId'] is! String) ||
        json['profile'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid or unsupported visual settings document.',
      );
    }
    return SpatialVisualDocument(
      mapId: json['mapId'] as String?,
      profile: SpatialVisualPatch.fromJson(
        json['profile'] as Map<String, dynamic>,
      ),
    );
  }
  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    if (mapId != null) 'mapId': mapId,
    'profile': profile.toJson(),
  };
}
