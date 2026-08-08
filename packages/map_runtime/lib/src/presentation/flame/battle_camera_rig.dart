import 'package:flame/components.dart';

import 'battle_animation_plan.dart';

final class BattleCameraRig {
  final Vector2 _offset = Vector2.zero();
  final Vector2 _startOffset = Vector2.zero();
  final Vector2 _targetOffset = Vector2.zero();
  double _scale = 1.0;
  double _startScale = 1.0;
  double _targetScale = 1.0;
  double _elapsed = 0;
  double _duration = 0;
  BattleFxMotionCurve _curve = BattleFxMotionCurve.easeOut;
  bool _active = false;

  /// Vue directe sur l'offset interne : `update` tourne à chaque frame, un
  /// clone par lecture générait du churn. Les consommateurs copient via les
  /// setters Flame (`position = ...` fait un setFrom) et ne mutent jamais.
  Vector2 get offset => _offset;

  double get scale => _scale;

  bool get isActive => _active;

  void focusUser({required double durationSeconds}) {
    moveTo(
      offset: Vector2(18, -12),
      scale: 1.055,
      durationSeconds: durationSeconds,
      curve: BattleFxMotionCurve.easeOut,
    );
  }

  void focusTarget({required double durationSeconds}) {
    moveTo(
      offset: Vector2(-18, 12),
      scale: 1.055,
      durationSeconds: durationSeconds,
      curve: BattleFxMotionCurve.easeOut,
    );
  }

  void centerScene({required double durationSeconds}) {
    moveTo(
      offset: Vector2.zero(),
      scale: 1.02,
      durationSeconds: durationSeconds,
      curve: BattleFxMotionCurve.easeOut,
    );
  }

  void moveTo({
    required Vector2 offset,
    required double scale,
    required double durationSeconds,
    BattleFxMotionCurve curve = BattleFxMotionCurve.easeOut,
  }) {
    _startOffset.setFrom(_offset);
    _targetOffset.setFrom(offset);
    _startScale = _scale;
    _targetScale = scale;
    _elapsed = 0;
    _duration = durationSeconds <= 0 ? 0.0001 : durationSeconds;
    _curve = curve;
    _active = true;
    if (durationSeconds <= 0) {
      _finishMove();
    }
  }

  void reset({required double durationSeconds}) {
    moveTo(
      offset: Vector2.zero(),
      scale: 1.0,
      durationSeconds: durationSeconds,
      curve: BattleFxMotionCurve.easeOut,
    );
  }

  void cancel() {
    _active = false;
    _elapsed = 0;
    _duration = 0;
    _offset.setZero();
    _startOffset.setZero();
    _targetOffset.setZero();
    _scale = 1.0;
    _startScale = 1.0;
    _targetScale = 1.0;
  }

  void update(double dt) {
    if (!_active) {
      return;
    }
    _elapsed += dt;
    final progress = (_elapsed / _duration).clamp(0.0, 1.0);
    final curvedProgress = _applyCurve(progress);
    _offset.setValues(
      _startOffset.x + (_targetOffset.x - _startOffset.x) * curvedProgress,
      _startOffset.y + (_targetOffset.y - _startOffset.y) * curvedProgress,
    );
    _scale = _startScale + ((_targetScale - _startScale) * curvedProgress);
    if (progress >= 1) {
      _finishMove();
    }
  }

  void _finishMove() {
    _offset.setFrom(_targetOffset);
    _scale = _targetScale;
    _elapsed = _duration;
    _active = false;
  }

  double _applyCurve(double progress) {
    final remaining = 1 - progress;
    return switch (_curve) {
      BattleFxMotionCurve.linear => progress,
      BattleFxMotionCurve.easeOut ||
      BattleFxMotionCurve.arcUnder ||
      BattleFxMotionCurve.arcOver =>
        1 - remaining * remaining,
    };
  }
}
