final class GameplayCalendarState {
  const GameplayCalendarState.empty()
    : observedLocalDay = null,
      dayRevision = 0;

  GameplayCalendarState({
    required String? observedLocalDay,
    required this.dayRevision,
  }) : observedLocalDay = observedLocalDay {
    if (dayRevision < 0 ||
        dayRevision > maximumRevision ||
        (observedLocalDay == null && dayRevision != 0)) {
      throw const FormatException('Invalid gameplay calendar revision.');
    }
    if (observedLocalDay != null) localDayNumber(observedLocalDay);
  }

  static const maximumRevision = 9007199254740991;

  factory GameplayCalendarState.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json.length != 3 ||
        !json.containsKey('observedLocalDay') ||
        !json.containsKey('dayRevision') ||
        json['dayRevision'] is! int ||
        (json['observedLocalDay'] != null &&
            json['observedLocalDay'] is! String)) {
      throw const FormatException('Invalid or unsupported gameplay calendar.');
    }
    return GameplayCalendarState(
      observedLocalDay: json['observedLocalDay'] as String?,
      dayRevision: json['dayRevision'] as int,
    );
  }

  final String? observedLocalDay;
  final int dayRevision;
  bool get isInitialized => observedLocalDay != null;

  static int localDayNumber(String day) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day)) {
      throw const FormatException('A local calendar day requires YYYY-MM-DD.');
    }
    final year = int.parse(day.substring(0, 4));
    final month = int.parse(day.substring(5, 7));
    final date = int.parse(day.substring(8, 10));
    final value = DateTime.utc(year, month, date);
    if (year < 1 ||
        value.year != year ||
        value.month != month ||
        value.day != date) {
      throw const FormatException('Invalid local calendar day.');
    }
    return value.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'observedLocalDay': observedLocalDay,
    'dayRevision': dayRevision,
  };

  @override
  bool operator ==(Object other) =>
      other is GameplayCalendarState &&
      observedLocalDay == other.observedLocalDay &&
      dayRevision == other.dayRevision;

  @override
  int get hashCode => Object.hash(observedLocalDay, dayRevision);
}

Object? readGameplayCalendarStateJson(Map<dynamic, dynamic> json, String key) {
  if (json.containsKey(key) && json[key] == null) {
    throw const FormatException('Gameplay calendar state must not be null.');
  }
  return json[key];
}
