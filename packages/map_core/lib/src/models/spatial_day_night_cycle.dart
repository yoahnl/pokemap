final class SpatialDayNightCycle {
  SpatialDayNightCycle({
    this.durationSeconds = 600,
    this.startMinuteOfDay = 720,
  }) {
    if (!durationSeconds.isFinite ||
        durationSeconds < 10 ||
        durationSeconds > 86400 ||
        startMinuteOfDay < 0 ||
        startMinuteOfDay > 1439) {
      throw const FormatException('Invalid visual day/night cycle timing.');
    }
  }

  final double durationSeconds;
  final int startMinuteOfDay;

  double minuteAtElapsed(double elapsedSeconds) {
    if (!elapsedSeconds.isFinite || elapsedSeconds < 0) {
      throw const FormatException(
        'Visual elapsed time must be finite and nonnegative.',
      );
    }
    return (startMinuteOfDay +
            (elapsedSeconds % durationSeconds) / durationSeconds * 1440) %
        1440;
  }

  SpatialDayNightCycle copyWith({
    double? durationSeconds,
    int? startMinuteOfDay,
  }) => SpatialDayNightCycle(
    durationSeconds: durationSeconds ?? this.durationSeconds,
    startMinuteOfDay: startMinuteOfDay ?? this.startMinuteOfDay,
  );

  factory SpatialDayNightCycle.fromJson(Map<String, dynamic> json) {
    if (json.keys.any(
          (key) => !{'durationSeconds', 'startMinuteOfDay'}.contains(key),
        ) ||
        (json.containsKey('durationSeconds') &&
            json['durationSeconds'] is! num) ||
        (json.containsKey('startMinuteOfDay') &&
            json['startMinuteOfDay'] is! int)) {
      throw const FormatException('Invalid visual day/night cycle fields.');
    }
    return SpatialDayNightCycle(
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 600,
      startMinuteOfDay: json['startMinuteOfDay'] as int? ?? 720,
    );
  }

  Map<String, dynamic> toJson() => {
    'durationSeconds': durationSeconds,
    'startMinuteOfDay': startMinuteOfDay,
  };

  @override
  bool operator ==(Object other) =>
      other is SpatialDayNightCycle &&
      durationSeconds == other.durationSeconds &&
      startMinuteOfDay == other.startMinuteOfDay;
  @override
  int get hashCode => Object.hash(durationSeconds, startMinuteOfDay);
}
