import 'map_spatial_scene.dart';
import 'spatial_atmosphere_settings.dart';
import 'spatial_day_night_cycle.dart';
import 'spatial_weather_settings.dart';
import 'world_environment.dart';

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
  fireflyDensity(0, 2),
  fireflyLighting.boolean(),
  fireflyYellowAmount(0, 1),
  fireflyGreenAmount(0, 1),
  fireflyBlueAmount(0, 1),
  fireflyPinkAmount(0, 1),
  fireflyLightStrength(0, 1),
  fireflyLightRadius(.25, 2.5),
  weatherEnabled.boolean(),
  weatherKind.choice(),
  weatherIntensity(0, 1),
  weatherDensity(0, 1),
  weatherSpeed(.1, 3),
  weatherWindStrength(0, 2),
  weatherWindDirection(-180, 180),
  weatherParticleSize(.25, 2),
  weatherOpacity(0, 1),
  weatherCloudCover(0, 1),
  weatherFogStrength(0, 1),
  weatherTransitionSeconds(0, 5),
  weatherLightning.boolean(),
  weatherIndoors.boolean(),
  weatherSoundEnabled.boolean(),
  weatherRainVolume(0, 1),
  weatherWindVolume(0, 1),
  timeMode.choice(),
  weatherMode.choice(),
  weatherIntervalSeconds(10, 86400),
  weatherSequence(1, 20),
  weatherDryMinSeconds(10, 86400),
  weatherDryMaxSeconds(10, 86400),
  weatherEventMinSeconds(10, 3600),
  weatherEventMaxSeconds(10, 3600),
  weatherDrizzleWeight(0, 100),
  weatherRainWeight(0, 100),
  weatherDownpourWeight(0, 100),
  weatherStormWeight(0, 100);

  const SpatialVisualParameter(this.minimum, this.maximum)
    : isBoolean = false,
      isChoice = false;
  const SpatialVisualParameter.boolean()
    : minimum = 0,
      maximum = 1,
      isBoolean = true,
      isChoice = false;
  const SpatialVisualParameter.choice()
    : minimum = 0,
      maximum = 0,
      isBoolean = false,
      isChoice = true;
  final double minimum, maximum;
  final bool isBoolean;
  final bool isChoice;
  List<String> get choices => switch (this) {
    weatherKind => [for (final value in SpatialWeatherKind.values) value.name],
    timeMode => [for (final value in WorldTimeMode.values) value.name],
    weatherMode => [for (final value in WorldWeatherMode.values) value.name],
    _ => const [],
  };
  bool get isWeatherEpisode => index >= weatherDryMinSeconds.index;
  double? get defaultNumber => switch (this) {
    weatherDryMinSeconds => 900,
    weatherDryMaxSeconds => 1800,
    weatherEventMinSeconds => 120,
    weatherEventMaxSeconds => 300,
    weatherDrizzleWeight => 50,
    weatherRainWeight => 30,
    weatherDownpourWeight => 15,
    weatherStormWeight => 5,
    _ => null,
  };
  bool get isSequence => this == weatherSequence;
  bool get isCamera => index <= lockVerticalFraming.index;
  bool get isClock =>
      (index >= dayNightEnabled.index && index <= minuteOfDay.index) ||
      this == timeMode;
  bool get isAtmosphere => !isCamera && !isClock;
  bool get isLightWorkshop =>
      index >= fireflyLighting.index && index <= fireflyLightRadius.index;
  bool get isWeather =>
      (index >= weatherEnabled.index && index <= weatherWindVolume.index) ||
      this == weatherMode || this == weatherIntervalSeconds || isSequence || isWeatherEpisode;
  bool get isWeatherSound =>
      index >= weatherSoundEnabled.index && index <= weatherWindVolume.index;
  bool get isWorldEnvironment =>
      this == timeMode || this == weatherMode ||
      this == weatherIntervalSeconds || isSequence || isWeatherEpisode;

  Object normalize(Object? value) {
    if (isSequence) {
      if (value is! List || value.isEmpty || value.length > 20) {
        throw const FormatException('Choose between one and twenty weather styles.');
      }
      final kinds = [for (final kind in value) SpatialWeatherKind.parse(kind).name];
      if (kinds.toSet().length != kinds.length) {
        throw const FormatException('Weather styles must be unique.');
      }
      return List<String>.unmodifiable(kinds);
    }
    if (isChoice) {
      if (value is String && choices.contains(value)) return value;
      throw FormatException('Invalid choice for $name.');
    }
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
    for (final pair in const [
      (SpatialVisualParameter.weatherDryMinSeconds, SpatialVisualParameter.weatherDryMaxSeconds),
      (SpatialVisualParameter.weatherEventMinSeconds, SpatialVisualParameter.weatherEventMaxSeconds),
    ]) {
      final min = number(pair.$1), max = number(pair.$2);
      if (min != null && max != null && min > max) {
        throw const FormatException('Weather minimum must not exceed maximum.');
      }
    }
    if (const [SpatialVisualParameter.weatherDrizzleWeight, SpatialVisualParameter.weatherRainWeight, SpatialVisualParameter.weatherDownpourWeight, SpatialVisualParameter.weatherStormWeight].every((p) => (number(p) ?? p.defaultNumber!) == 0)) {
      throw const FormatException('Choose at least one occasional weather.');
    }
    final start = number(SpatialVisualParameter.fogStart);
    final end = number(SpatialVisualParameter.fogEnd);
    if (start != null && end != null && start >= end) {
      throw const FormatException('Fog must end after its start.');
    }
  }
  final Map<SpatialVisualParameter, Object> values;
  bool get isEmpty => values.isEmpty;
  bool get requiresLightWorkshop => values.keys.any((p) => p.isLightWorkshop);
  bool get requiresExtendedWeather =>
      (choice(SpatialVisualParameter.weatherKind) != null && SpatialWeatherKind.parse(choice(SpatialVisualParameter.weatherKind)).isExtended) ||
      ((value(SpatialVisualParameter.weatherSequence) as List<String>?) ?? const <String>[]).any((kind) => SpatialWeatherKind.parse(kind).isExtended);

  bool get requiresWeatherEpisodes =>
      choice(SpatialVisualParameter.weatherMode) == WorldWeatherMode.occasional.name || values.keys.any((p) => p.isWeatherEpisode);
  bool get requiresWeather => values.keys.any((p) => p.isWeather);
  bool get requiresWeatherSound => values.keys.any((p) => p.isWeatherSound);
  bool get requiresRealWeather => choice(SpatialVisualParameter.weatherMode) == WorldWeatherMode.real.name;
  bool get requiresWorldEnvironment => values.keys.any((p) => p.isWorldEnvironment);
  Object? value(SpatialVisualParameter parameter) => values[parameter];
  double? number(SpatialVisualParameter parameter) =>
      values[parameter] as double?;
  bool? enabled(SpatialVisualParameter parameter) => values[parameter] as bool?;
  String? choice(SpatialVisualParameter parameter) =>
      values[parameter] as String?;

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
    'weatherEnabled': atmosphere.weather.enabled,
    'weatherKind': atmosphere.weather.kind.name,
    'weatherIntensity': atmosphere.weather.intensity,
    'weatherDensity': atmosphere.weather.density,
    'weatherSpeed': atmosphere.weather.speed,
    'weatherWindStrength': atmosphere.weather.windStrength,
    'weatherWindDirection': atmosphere.weather.windDirection,
    'weatherParticleSize': atmosphere.weather.particleSize,
    'weatherOpacity': atmosphere.weather.opacity,
    'weatherCloudCover': atmosphere.weather.cloudCover,
    'weatherFogStrength': atmosphere.weather.fogStrength,
    'weatherTransitionSeconds': atmosphere.weather.transitionSeconds,
    'weatherLightning': atmosphere.weather.lightning,
    'weatherIndoors': atmosphere.weather.indoors,
    'weatherSoundEnabled': atmosphere.weather.soundEnabled,
    'weatherRainVolume': atmosphere.weather.rainVolume,
    'weatherWindVolume': atmosphere.weather.windVolume,
    'fireflyLighting': atmosphere.fireflyLighting,
    'fireflyYellowAmount': atmosphere.fireflyYellowAmount,
    'fireflyGreenAmount': atmosphere.fireflyGreenAmount,
    'fireflyBlueAmount': atmosphere.fireflyBlueAmount,
    'fireflyPinkAmount': atmosphere.fireflyPinkAmount,
    'fireflyLightStrength': atmosphere.fireflyLightStrength,
    'fireflyLightRadius': atmosphere.fireflyLightRadius,

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
    for (final pair in const [(SpatialVisualParameter.weatherDryMinSeconds, SpatialVisualParameter.weatherDryMaxSeconds), (SpatialVisualParameter.weatherEventMinSeconds, SpatialVisualParameter.weatherEventMaxSeconds)]) {
      final min = merged[pair.$1] as double?, max = merged[pair.$2] as double?;
      if (min != null && max != null && min > max) {
        if (override.value(pair.$1) != null) {
          merged[pair.$2] = min;
        } else {
          merged[pair.$1] = max;
        }
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
      weather: base.weather.copyWith(
        enabled: enabled(SpatialVisualParameter.weatherEnabled),
        kind: choice(SpatialVisualParameter.weatherKind) == null
            ? null
            : SpatialWeatherKind.parse(
                choice(SpatialVisualParameter.weatherKind),
              ),
        intensity: number(SpatialVisualParameter.weatherIntensity),
        density: number(SpatialVisualParameter.weatherDensity),
        speed: number(SpatialVisualParameter.weatherSpeed),
        windStrength: number(SpatialVisualParameter.weatherWindStrength),
        windDirection: number(SpatialVisualParameter.weatherWindDirection),
        particleSize: number(SpatialVisualParameter.weatherParticleSize),
        opacity: number(SpatialVisualParameter.weatherOpacity),
        cloudCover: number(SpatialVisualParameter.weatherCloudCover),
        fogStrength: number(SpatialVisualParameter.weatherFogStrength),
        transitionSeconds: number(
          SpatialVisualParameter.weatherTransitionSeconds,
        ),
        lightning: enabled(SpatialVisualParameter.weatherLightning),
        indoors: enabled(SpatialVisualParameter.weatherIndoors),
        soundEnabled: enabled(SpatialVisualParameter.weatherSoundEnabled),
        rainVolume: number(SpatialVisualParameter.weatherRainVolume),
        windVolume: number(SpatialVisualParameter.weatherWindVolume),
      ),
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
      fireflyLighting: enabled(SpatialVisualParameter.fireflyLighting),
      fireflyYellowAmount: number(SpatialVisualParameter.fireflyYellowAmount),
      fireflyGreenAmount: number(SpatialVisualParameter.fireflyGreenAmount),
      fireflyBlueAmount: number(SpatialVisualParameter.fireflyBlueAmount),
      fireflyPinkAmount: number(SpatialVisualParameter.fireflyPinkAmount),
      fireflyLightStrength: number(SpatialVisualParameter.fireflyLightStrength),
      fireflyLightRadius: number(SpatialVisualParameter.fireflyLightRadius),

      fireflyDensity: number(SpatialVisualParameter.fireflyDensity),
    );
  }

  SpatialDayNightCycle? applyCycle(SpatialDayNightCycle? base) {
    final mode = choice(SpatialVisualParameter.timeMode);
    if (mode == WorldTimeMode.real.name || mode == WorldTimeMode.fixed.name) {
      return null;
    }
    if (!values.keys.any((p) => p.isClock)) return base;
    if (mode == null && enabled(SpatialVisualParameter.dayNightEnabled) == false) {
      return null;
    }
    if (mode == null && base == null &&
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
      values.entries.every((entry) => _equalValue(other.values[entry.key], entry.value));
  @override
  int get hashCode => Object.hashAllUnordered(
    values.entries.map((entry) => Object.hash(entry.key, entry.value is List ? Object.hashAll(entry.value as List) : entry.value)),
  );
}

final class SpatialVisualDocument {
  SpatialVisualDocument({required this.profile, this.mapId}) {
    if (mapId != null) relativePathForMap(mapId!);
  }
  static const capabilityId = 'map3d.visual-profile@1';
  static const schemaVersion = 1;
  static const lightWorkshopSchemaVersion = 2;
  static const weatherSchemaVersion = 3;
  static const weatherSoundSchemaVersion = 4;
  static const worldEnvironmentSchemaVersion = 5;
  static const realWeatherSchemaVersion = 6;
  static const extendedWeatherSchemaVersion = 7;
  static const weatherEpisodesSchemaVersion = 8;
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
    if (!{
          schemaVersion,
          lightWorkshopSchemaVersion,
          weatherSchemaVersion,
          weatherSoundSchemaVersion,
          worldEnvironmentSchemaVersion,
          realWeatherSchemaVersion,
          extendedWeatherSchemaVersion,
          weatherEpisodesSchemaVersion,
        }.contains(json['schemaVersion']) ||
        json.keys.any(
          (key) => !{'schemaVersion', 'mapId', 'profile'}.contains(key),
        ) ||
        (json['mapId'] != null && json['mapId'] is! String) ||
        json['profile'] is! Map<String, dynamic>) {
      throw const FormatException(
        'Invalid or unsupported visual settings document.',
      );
    }
    final profile = SpatialVisualPatch.fromJson(
      json['profile'] as Map<String, dynamic>,
    );
    if ((json['schemaVersion'] as int) < weatherEpisodesSchemaVersion && profile.requiresWeatherEpisodes) {
      throw const FormatException('Occasional weather requires visual schema 8.');
    }
    if ((json['schemaVersion'] as int) < extendedWeatherSchemaVersion && profile.requiresExtendedWeather) {
      throw const FormatException('Extended weather requires visual schema 7.');
    }
    if ((json['schemaVersion'] as int) < realWeatherSchemaVersion && profile.requiresRealWeather) {
      throw const FormatException('Real weather requires visual schema 6.');
    }
    if ((json['schemaVersion'] as int) < worldEnvironmentSchemaVersion && profile.requiresWorldEnvironment) {
      throw const FormatException('World environment requires visual schema 5.');
    }
    if ((json['schemaVersion'] as int) < weatherSoundSchemaVersion &&
        profile.requiresWeatherSound) {
      throw const FormatException('Weather audio requires visual schema 4.');
    }
    if ((json['schemaVersion'] as int) < weatherSchemaVersion &&
        profile.requiresWeather) {
      throw const FormatException('Weather requires visual schema 3.');
    }
    if (json['schemaVersion'] == schemaVersion &&
        profile.requiresLightWorkshop) {
      throw const FormatException(
        'Extended lighting requires visual schema 2.',
      );
    }
    return SpatialVisualDocument(
      mapId: json['mapId'] as String?,
      profile: profile,
    );
  }
  Map<String, dynamic> toJson() => {
    'schemaVersion': profile.requiresWeatherEpisodes ? weatherEpisodesSchemaVersion : profile.requiresExtendedWeather ? extendedWeatherSchemaVersion : profile.requiresRealWeather ? realWeatherSchemaVersion : profile.requiresWorldEnvironment
        ? worldEnvironmentSchemaVersion
        : profile.requiresWeatherSound
        ? weatherSoundSchemaVersion
        : profile.requiresWeather
        ? weatherSchemaVersion
        : profile.requiresLightWorkshop
        ? lightWorkshopSchemaVersion
        : schemaVersion,
    if (mapId != null) 'mapId': mapId,
    'profile': profile.toJson(),
  };
}

bool _equalValue(Object? first, Object second) {
  if (first is List && second is List) return first.length == second.length && first.indexed.every((entry) => entry.$2 == second[entry.$1]);
  return first == second;
}
