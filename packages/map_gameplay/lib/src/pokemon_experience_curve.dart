/// Canonical cumulative Pokemon experience curve used by project species.
///
/// The accepted ids match the seven ids already validated by the runtime
/// species loader. Levels are deliberately bounded to `1..100`, so all
/// intermediate integer products remain small and deterministic on every Dart
/// target. Experience totals above the level-100 threshold simply resolve to
/// level 100.
final class PokemonExperienceCurve {
  const PokemonExperienceCurve._(this.id);

  factory PokemonExperienceCurve.fromId(String id) {
    final normalizedId = id.trim().toLowerCase();
    if (!supportedIds.contains(normalizedId)) {
      throw ArgumentError.value(id, 'id', 'unsupported Pokemon growth curve');
    }
    return PokemonExperienceCurve._(normalizedId);
  }

  static const supportedIds = <String>{
    'fast',
    'fast_then_very_slow',
    'medium',
    'medium_fast',
    'medium_slow',
    'slow',
    'slow_then_very_fast',
  };

  final String id;

  /// Returns the total cumulative XP threshold for [level].
  int totalExperienceForLevel(int level) {
    RangeError.checkValueInInterval(level, 1, 100, 'level');
    final cubed = level * level * level;
    final experience = switch (id) {
      'fast' => (4 * cubed) ~/ 5,
      'medium' || 'medium_fast' => cubed,
      'medium_slow' =>
        ((6 * cubed) ~/ 5) - (15 * level * level) + (100 * level) - 140,
      'slow' => (5 * cubed) ~/ 4,
      'slow_then_very_fast' => _erraticExperience(level, cubed),
      'fast_then_very_slow' => _fluctuatingExperience(level, cubed),
      _ => throw StateError('Validated Pokemon growth curve became invalid.'),
    };

    // The classic medium-slow expression is negative at level one, while the
    // persisted cumulative XP contract is non-negative.
    return experience < 0 ? 0 : experience;
  }

  /// Resolves the greatest level whose cumulative threshold is reached.
  int levelForExperience(int experience) {
    RangeError.checkNotNegative(experience, 'experience');
    if (experience >= totalExperienceForLevel(100)) return 100;

    var low = 1;
    var high = 99;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (totalExperienceForLevel(middle) <= experience) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }
}

int _erraticExperience(int level, int cubed) {
  if (level <= 50) return (cubed * (100 - level)) ~/ 50;
  if (level <= 68) return (cubed * (150 - level)) ~/ 100;
  if (level <= 98) {
    return (cubed * ((1911 - (10 * level)) ~/ 3)) ~/ 500;
  }
  return (cubed * (160 - level)) ~/ 100;
}

int _fluctuatingExperience(int level, int cubed) {
  if (level <= 15) {
    return (cubed * (((level + 1) ~/ 3) + 24)) ~/ 50;
  }
  if (level <= 35) return (cubed * (level + 14)) ~/ 50;
  return (cubed * ((level ~/ 2) + 32)) ~/ 50;
}
