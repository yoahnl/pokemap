final class BattleMotionPolicy {
  BattleMotionPolicy({
    this.playbackSpeed = 1,
    this.reducedMotion = false,
    this.effectIntensity = 1,
  }) {
    if (!playbackSpeed.isFinite || playbackSpeed <= 0) {
      throw ArgumentError.value(
        playbackSpeed,
        'playbackSpeed',
        'Must be finite and positive',
      );
    }
    if (!effectIntensity.isFinite ||
        effectIntensity < 0 ||
        effectIntensity > 1) {
      throw ArgumentError.value(
        effectIntensity,
        'effectIntensity',
        'Must be finite and within [0, 1]',
      );
    }
  }

  factory BattleMotionPolicy.legacy(double motionScale) {
    if (!motionScale.isFinite) {
      throw ArgumentError.value(motionScale, 'motionScale', 'Must be finite');
    }
    return BattleMotionPolicy(
      playbackSpeed: motionScale <= 0 ? 1 : motionScale,
      reducedMotion: motionScale > 1,
    );
  }

  final double playbackSpeed;
  final bool reducedMotion;
  final double effectIntensity;

  factory BattleMotionPolicy.fromJson(Object? value) {
    if (value is! Map || value.length != 3 ||
        value['playbackSpeed'] is! num ||
        value['reducedMotion'] is! bool ||
        value['effectIntensity'] is! num) {
      throw const FormatException('Invalid battle motion preferences.');
    }
    try {
      return BattleMotionPolicy(
        playbackSpeed: (value['playbackSpeed'] as num).toDouble(),
        reducedMotion: value['reducedMotion'] as bool,
        effectIntensity: (value['effectIntensity'] as num).toDouble(),
      );
    } on ArgumentError {
      throw const FormatException('Invalid battle motion preferences.');
    }
  }

  BattleMotionPolicy copyWith({
    double? playbackSpeed,
    bool? reducedMotion,
    double? effectIntensity,
  }) => BattleMotionPolicy(
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    reducedMotion: reducedMotion ?? this.reducedMotion,
    effectIntensity: effectIntensity ?? this.effectIntensity,
  );

  Map<String, Object?> toJson() => {
    'playbackSpeed': playbackSpeed,
    'reducedMotion': reducedMotion,
    'effectIntensity': effectIntensity,
  };

  @override
  bool operator ==(Object other) => other is BattleMotionPolicy &&
      playbackSpeed == other.playbackSpeed &&
      reducedMotion == other.reducedMotion &&
      effectIntensity == other.effectIntensity;

  @override
  int get hashCode => Object.hash(playbackSpeed, reducedMotion, effectIntensity);
}
