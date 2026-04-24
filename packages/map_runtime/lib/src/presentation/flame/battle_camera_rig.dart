import 'dart:math' as math;

import 'package:flame/components.dart';

import 'battle_animation_plan.dart';

final class BattleCameraRig {
  Vector2 _offset = Vector2.zero();
  Vector2 _startOffset = Vector2.zero();
  Vector2 _targetOffset = Vector2.zero();
  double _scale = 1.0;
  double _startScale = 1.0;
  double _targetScale = 1.0;
  double _elapsed = 0;
  double _duration = 0;
  BattleFxMotionCurve _curve = BattleFxMotionCurve.easeOut;
  bool _active = false;

  Vector2 get offset => _offset.clone();

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
    _startOffset = _offset.clone();
    _targetOffset = offset.clone();
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
    _offset = Vector2.zero();
    _startOffset = Vector2.zero();
    _targetOffset = Vector2.zero();
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
    _offset = _startOffset + ((_targetOffset - _startOffset) * curvedProgress);
    _scale = _startScale + ((_targetScale - _startScale) * curvedProgress);
    if (progress >= 1) {
      _finishMove();
    }
  }

  void _finishMove() {
    _offset = _targetOffset.clone();
    _scale = _targetScale;
    _elapsed = _duration;
    _active = false;
  }

  double _applyCurve(double progress) {
    return switch (_curve) {
      BattleFxMotionCurve.linear => progress,
      BattleFxMotionCurve.easeOut ||
      BattleFxMotionCurve.arcUnder ||
      BattleFxMotionCurve.arcOver =>
        1 - math.pow(1 - progress, 2).toDouble(),
    };
  }
}
