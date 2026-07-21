/// Player-selectable reveal cadence for runtime dialogue lines.
///
/// `instant` preserves the historical runtime behaviour and remains useful for
/// tests and accessibility. Timed modes are consumed by the Flame overlay;
/// they are not cosmetic host-only preferences.
enum RuntimeDialogueTextSpeed {
  slow,
  normal,
  fast,
  instant;

  Duration? get revealInterval => switch (this) {
        RuntimeDialogueTextSpeed.slow => const Duration(milliseconds: 45),
        RuntimeDialogueTextSpeed.normal => const Duration(milliseconds: 30),
        RuntimeDialogueTextSpeed.fast => const Duration(milliseconds: 15),
        RuntimeDialogueTextSpeed.instant => null,
      };

  static RuntimeDialogueTextSpeed fromStorage(
    Object? value, {
    RuntimeDialogueTextSpeed fallback = RuntimeDialogueTextSpeed.instant,
  }) {
    if (value is! String) {
      return fallback;
    }
    for (final speed in RuntimeDialogueTextSpeed.values) {
      if (speed.name == value.trim()) {
        return speed;
      }
    }
    return fallback;
  }
}
