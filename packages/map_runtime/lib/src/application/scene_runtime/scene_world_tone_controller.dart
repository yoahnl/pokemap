final class SceneWorldToneValue {
  SceneWorldToneValue({
    required this.red,
    required this.green,
    required this.blue,
    required this.gray,
  }) {
    _validateChannel(red, 'red', minimum: -255);
    _validateChannel(green, 'green', minimum: -255);
    _validateChannel(blue, 'blue', minimum: -255);
    _validateChannel(gray, 'gray', minimum: 0);
  }

  static final neutral = SceneWorldToneValue(
    red: 0,
    green: 0,
    blue: 0,
    gray: 0,
  );

  final double red;
  final double green;
  final double blue;
  final double gray;

  static void _validateChannel(
    double value,
    String name, {
    required double minimum,
  }) {
    if (!value.isFinite || value < minimum || value > 255) {
      throw ArgumentError.value(value, name, 'Expected $minimum to 255.');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SceneWorldToneValue &&
      other.red == red &&
      other.green == green &&
      other.blue == blue &&
      other.gray == gray;

  @override
  int get hashCode => Object.hash(red, green, blue, gray);
}

final class SceneWorldToneCheckpoint {
  SceneWorldToneCheckpoint._(
    this._owner,
    this._generation,
    this._settledValue,
    this._transition,
  );

  final Object _owner;
  final int _generation;
  final SceneWorldToneValue _settledValue;
  final _ToneTransition? _transition;
}

final class SceneWorldToneController {
  final _checkpointOwner = Object();
  int _generation = 0;
  double _clockSeconds = 0;
  bool _disposed = false;
  SceneWorldToneValue _settledValue = SceneWorldToneValue.neutral;
  _ToneTransition? _transition;

  SceneWorldToneValue get value =>
      _transition?.valueAt(_clockSeconds) ?? _settledValue;
  bool get isTransitioning => _transition != null;

  void setTone(SceneWorldToneValue tone, {required double durationSeconds}) {
    _ensureOpen();
    _validateTime(durationSeconds, 'durationSeconds');
    final current = value;
    if (durationSeconds == 0 || current == tone) {
      _settledValue = tone;
      _transition = null;
      return;
    }
    _transition = _ToneTransition(
      from: current,
      to: tone,
      startedAt: _clockSeconds,
      durationSeconds: durationSeconds,
    );
  }

  void advance(double dt) {
    _ensureOpen();
    _validateTime(dt, 'dt');
    final nextClock = _clockSeconds + dt;
    if (!nextClock.isFinite) {
      throw ArgumentError.value(dt, 'dt', 'Tone clock overflow.');
    }
    _clockSeconds = nextClock;
    _settleCompletedTransition();
  }

  SceneWorldToneCheckpoint captureCheckpoint() {
    _ensureOpen();
    return SceneWorldToneCheckpoint._(
      _checkpointOwner,
      _generation,
      _settledValue,
      _transition,
    );
  }

  void restoreCheckpoint(SceneWorldToneCheckpoint checkpoint) {
    _ensureOpen();
    if (!identical(checkpoint._owner, _checkpointOwner) ||
        checkpoint._generation != _generation) {
      throw StateError('The Tone checkpoint belongs to another session.');
    }
    _settledValue = checkpoint._settledValue;
    _transition = checkpoint._transition;
    _settleCompletedTransition();
  }

  void reset() {
    _ensureOpen();
    _resetTransientState();
  }

  void dispose() {
    if (_disposed) return;
    _resetTransientState();
    _disposed = true;
  }

  void _settleCompletedTransition() {
    final transition = _transition;
    if (transition != null &&
        _clockSeconds - transition.startedAt >= transition.durationSeconds) {
      _settledValue = transition.to;
      _transition = null;
    }
  }

  void _resetTransientState() {
    _generation++;
    _clockSeconds = 0;
    _settledValue = SceneWorldToneValue.neutral;
    _transition = null;
  }

  static void _validateTime(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, name, 'Expected finite positive time.');
    }
  }

  void _ensureOpen() {
    if (_disposed) throw StateError('The Tone controller is disposed.');
  }
}

final class _ToneTransition {
  _ToneTransition({
    required this.from,
    required this.to,
    required this.startedAt,
    required this.durationSeconds,
  });

  final SceneWorldToneValue from;
  final SceneWorldToneValue to;
  final double startedAt;
  final double durationSeconds;

  SceneWorldToneValue valueAt(double clock) {
    final fraction = ((clock - startedAt) / durationSeconds).clamp(0.0, 1.0);
    if (fraction == 0) return from;
    if (fraction == 1) return to;
    return SceneWorldToneValue(
      red: from.red + (to.red - from.red) * fraction,
      green: from.green + (to.green - from.green) * fraction,
      blue: from.blue + (to.blue - from.blue) * fraction,
      gray: from.gray + (to.gray - from.gray) * fraction,
    );
  }
}
