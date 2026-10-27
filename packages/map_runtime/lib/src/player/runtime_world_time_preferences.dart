import 'package:map_core/map_core.dart';

final class RuntimeWorldTimePreferences {
  const RuntimeWorldTimePreferences({this.chosenMinuteOfDay})
    : assert(
        chosenMinuteOfDay == null ||
            (chosenMinuteOfDay >= 0 && chosenMinuteOfDay < 1440),
        'chosenMinuteOfDay must be within a day',
      );

  factory RuntimeWorldTimePreferences.fromJson(Map<String, Object?> json) {
    final minute = json['chosenMinuteOfDay'];
    if (json.keys.any((key) => key != 'chosenMinuteOfDay') ||
        minute != null && (minute is! int || minute < 0 || minute >= 1440)) {
      throw const FormatException('Invalid world time preferences.');
    }
    return RuntimeWorldTimePreferences(chosenMinuteOfDay: minute as int?);
  }

  final int? chosenMinuteOfDay;

  DateTime worldTime(DateTime now) => switch (chosenMinuteOfDay) {
    final minute? => now.copyWith(
      hour: minute ~/ 60,
      minute: minute % 60,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    ),
    _ => now,
  };

  SpatialVisualPatch get visualOverrides => switch (chosenMinuteOfDay) {
    final minute? => SpatialVisualPatch({
      SpatialVisualParameter.timeMode: WorldTimeMode.fixed.name,
      SpatialVisualParameter.minuteOfDay: minute,
    }),
    _ => SpatialVisualPatch(),
  };

  static bool hasWorldClock(SpatialVisualPatch profile) =>
      profile.choice(SpatialVisualParameter.timeMode) != null ||
      profile.enabled(SpatialVisualParameter.dayNightEnabled) == true;

  Map<String, Object?> toJson() => {
    if (chosenMinuteOfDay != null) 'chosenMinuteOfDay': chosenMinuteOfDay,
  };

  @override
  bool operator ==(Object other) =>
      other is RuntimeWorldTimePreferences &&
      chosenMinuteOfDay == other.chosenMinuteOfDay;

  @override
  int get hashCode => chosenMinuteOfDay.hashCode;
}
