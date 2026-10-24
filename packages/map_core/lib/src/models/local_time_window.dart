final class LocalTimeWindow {
  const LocalTimeWindow({required this.startMinute, required this.endMinute});

  final int startMinute;
  final int endMinute;

  bool get isValid =>
      startMinute >= 0 &&
      startMinute < 1440 &&
      endMinute >= 0 &&
      endMinute <= 1440 &&
      startMinute != endMinute;

  void validate() {
    if (!isValid) {
      throw ArgumentError(
        'A local time window requires distinct minute bounds in 0..1440, with start before 24:00.',
      );
    }
  }

  bool contains(int minute) {
    if (!isValid || minute < 0 || minute >= 1440) return false;
    return startMinute < endMinute
        ? minute >= startMinute && minute < endMinute
        : minute >= startMinute || minute < endMinute;
  }

  factory LocalTimeWindow.fromJson(Map<String, dynamic> json) {
    if (json.length != 2 ||
        json['startMinute'] is! int ||
        json['endMinute'] is! int) {
      throw const FormatException(
        'Local time windows require exactly two integer minute bounds.',
      );
    }
    final window = LocalTimeWindow(
      startMinute: json['startMinute'] as int,
      endMinute: json['endMinute'] as int,
    );
    if (!window.isValid) {
      throw const FormatException('Invalid local time window bounds.');
    }
    return window;
  }

  Map<String, Object?> toJson() => {
    'startMinute': startMinute,
    'endMinute': endMinute,
  };

  @override
  bool operator ==(Object other) =>
      other is LocalTimeWindow &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute;

  @override
  int get hashCode => Object.hash(startMinute, endMinute);
}
