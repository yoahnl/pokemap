enum WorldTimeMode { cycle, real, fixed }

enum WorldWeatherMode { fixed, automatic, real, occasional }

final class WorldEnvironmentState {
  const WorldEnvironmentState.empty() : elapsedSeconds = 0;

  WorldEnvironmentState({num elapsedSeconds = 0})
    : elapsedSeconds = _elapsed(elapsedSeconds);

  final double elapsedSeconds;

  factory WorldEnvironmentState.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1 ||
        json.keys.any(
          (key) => !{'schemaVersion', 'elapsedSeconds'}.contains(key),
        ) ||
        json['elapsedSeconds'] is! num) {
      throw const FormatException(
        'Invalid or unsupported world environment state.',
      );
    }
    return WorldEnvironmentState(elapsedSeconds: json['elapsedSeconds'] as num);
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'elapsedSeconds': elapsedSeconds,
  };

  @override
  bool operator ==(Object other) =>
      other is WorldEnvironmentState && other.elapsedSeconds == elapsedSeconds;
  @override
  int get hashCode => elapsedSeconds.hashCode;
}

double _elapsed(num value) {
  if (!value.isFinite || value < 0 || value > 1e12) {
    throw const FormatException('Invalid world environment elapsed time.');
  }
  return value.toDouble();
}
