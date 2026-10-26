import 'spatial_visual_profile.dart';

final class RealWeatherLocation {
  RealWeatherLocation({
    required num latitude,
    required num longitude,
    required String label,
    String countryCode = '',
  }) : latitude = latitude.toDouble(),
       longitude = longitude.toDouble(),
       label = label.trim(),
       countryCode = countryCode.toUpperCase() {
    if (!this.latitude.isFinite ||
        this.latitude.abs() > 90 ||
        !this.longitude.isFinite ||
        this.longitude.abs() > 180 ||
        this.label.isEmpty ||
        this.label.length > 160 ||
        !RegExp(r'^[A-Z]{0,2}$').hasMatch(this.countryCode)) {
      throw const FormatException('Invalid weather location.');
    }
  }
  final double latitude, longitude;
  final String label, countryCode;
  factory RealWeatherLocation.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
          (key) =>
              !{'latitude', 'longitude', 'label', 'countryCode'}.contains(key),
        ) ||
        json['latitude'] is! num ||
        json['longitude'] is! num ||
        json['label'] is! String ||
        (json['countryCode'] != null && json['countryCode'] is! String)) {
      throw const FormatException('Invalid weather location.');
    }
    return RealWeatherLocation(
      latitude: json['latitude'] as num,
      longitude: json['longitude'] as num,
      label: json['label'] as String,
      countryCode: json['countryCode'] as String? ?? '',
    );
  }
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'label': label,
    'countryCode': countryCode,
  };
  @override
  bool operator ==(Object other) =>
      other is RealWeatherLocation &&
      latitude == other.latitude &&
      longitude == other.longitude &&
      label == other.label &&
      countryCode == other.countryCode;
  @override
  int get hashCode => Object.hash(latitude, longitude, label, countryCode);
}

final class RealWeatherPreferences {
  const RealWeatherPreferences({this.enabled = false, this.location});
  final bool enabled;
  final RealWeatherLocation? location;
  factory RealWeatherPreferences.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => !{'enabled', 'location'}.contains(key)) ||
        json['enabled'] is! bool ||
        (json['location'] != null &&
            json['location'] is! Map<String, dynamic>)) {
      throw const FormatException('Invalid real weather preferences.');
    }
    return RealWeatherPreferences(
      enabled: json['enabled'] as bool,
      location: json['location'] == null
          ? null
          : RealWeatherLocation.fromJson(
              json['location'] as Map<String, dynamic>,
            ),
    );
  }
  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    if (location != null) 'location': location!.toJson(),
  };
  @override
  bool operator ==(Object other) =>
      other is RealWeatherPreferences &&
      enabled == other.enabled &&
      location == other.location;
  @override
  int get hashCode => Object.hash(enabled, location);
}

final class RealWeatherSnapshot {
  RealWeatherSnapshot({
    required this.location,
    required this.conditions,
    required DateTime fetchedAt,
    this.fromIp = true,
    this.utcOffsetSeconds,
    this.timeZone,
  }) : fetchedAt = fetchedAt.toUtc() {
    if ((utcOffsetSeconds != null &&
            (utcOffsetSeconds! < -43200 || utcOffsetSeconds! > 50400)) ||
        (timeZone != null &&
            (utcOffsetSeconds == null ||
                !RegExp(r'^[A-Za-z0-9_+/-]{1,128}$').hasMatch(timeZone!)))) {
      throw const FormatException('Invalid weather time zone.');
    }
    if (conditions.values.keys.any((key) => !allowedConditions.contains(key)) ||
        conditions.choice(SpatialVisualParameter.weatherKind) == null) {
      throw const FormatException('Invalid real weather conditions.');
    }
  }
  static const allowedConditions = {
    SpatialVisualParameter.weatherKind,
    SpatialVisualParameter.weatherIntensity,
    SpatialVisualParameter.weatherCloudCover,
    SpatialVisualParameter.weatherWindStrength,
    SpatialVisualParameter.weatherWindDirection,
    SpatialVisualParameter.weatherFogStrength,
  };
  final RealWeatherLocation location;
  final SpatialVisualPatch conditions;
  final DateTime fetchedAt;
  final bool fromIp;
  final int? utcOffsetSeconds;
  final String? timeZone;
  bool usableAt(DateTime now) =>
      now.difference(fetchedAt) >= const Duration(minutes: -5) &&
      now.difference(fetchedAt) <= const Duration(hours: 24);
  factory RealWeatherSnapshot.fromJson(Map<String, dynamic> json) {
    if (!const {1, 2}.contains(json['schemaVersion']) ||
        json.keys.any(
          (key) => !{
            'schemaVersion',
            'location',
            'conditions',
            'fetchedAt',
            'fromIp',
            'utcOffsetSeconds',
            'timeZone',
          }.contains(key),
        ) ||
        (json['fromIp'] != null && json['fromIp'] is! bool) ||
        (json['schemaVersion'] == 1 &&
            (json['utcOffsetSeconds'] != null || json['timeZone'] != null)) ||
        (json['schemaVersion'] == 2 && json['utcOffsetSeconds'] is! int) ||
        (json['utcOffsetSeconds'] != null &&
            json['utcOffsetSeconds'] is! int) ||
        (json['timeZone'] != null && json['timeZone'] is! String) ||
        json['fetchedAt'] is! String ||
        json['location'] is! Map<String, dynamic> ||
        json['conditions'] is! Map<String, dynamic>) {
      throw const FormatException('Invalid real weather cache.');
    }
    return RealWeatherSnapshot(
      location: RealWeatherLocation.fromJson(
        json['location'] as Map<String, dynamic>,
      ),
      conditions: SpatialVisualPatch.fromJson(
        json['conditions'] as Map<String, dynamic>,
      ),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      fromIp: json['fromIp'] as bool? ?? true,
      utcOffsetSeconds: json['utcOffsetSeconds'] as int?,
      timeZone: json['timeZone'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
    'schemaVersion': utcOffsetSeconds == null ? 1 : 2,
    if (utcOffsetSeconds != null) 'utcOffsetSeconds': utcOffsetSeconds,
    if (timeZone != null) 'timeZone': timeZone,
    'fromIp': fromIp,
    'location': location.toJson(),
    'conditions': conditions.toJson(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };
}
