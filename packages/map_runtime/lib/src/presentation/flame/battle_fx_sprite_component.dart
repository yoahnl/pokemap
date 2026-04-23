import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'battle_animation_plan.dart';

final class BattleFxSpriteComponent extends PositionComponent {
  BattleFxSpriteComponent({
    required this.sprite,
    required Vector2 startPosition,
    required Vector2 endPosition,
    required this.durationSeconds,
    this.startDelaySeconds = 0,
    required this.curve,
    required this.afterEffect,
    required this.startScale,
    required this.endScale,
    required this.startOpacity,
    required this.endOpacity,
  })  : _startPosition = startPosition.clone(),
        _endPosition = endPosition.clone(),
        _baseDisplaySize = sprite.srcSize.clone(),
        super(
          position: startPosition.clone(),
          size: sprite.srcSize.clone(),
          anchor: Anchor.center,
          priority: 16,
        ) {
    _applyVisualState(
      position: _startPosition,
      scaleMultiplier: startScale,
      opacityMultiplier: startDelaySeconds > 0 ? 0 : startOpacity,
    );
  }

  final Sprite sprite;
  final Vector2 _startPosition;
  final Vector2 _endPosition;
  final Vector2 _baseDisplaySize;
  final double durationSeconds;
  final double startDelaySeconds;
  final BattleFxMotionCurve curve;
  final BattleFxAfterEffect afterEffect;
  final double startScale;
  final double endScale;
  final double startOpacity;
  final double endOpacity;

  static const double _afterEffectSeconds = 0.12;

  double _elapsed = 0;
  double _delayElapsed = 0;
  double _afterEffectElapsed = 0;
  bool _inAfterEffect = false;
  bool _isAnimationComplete = false;
  bool _delayCompleted = false;
  double _currentOpacityMultiplier = 1.0;
  double _currentScaleMultiplier = 1.0;

  @visibleForTesting
  double get currentOpacityMultiplier => _currentOpacityMultiplier;

  @visibleForTesting
  double get currentScaleMultiplier => _currentScaleMultiplier;

  bool get isAnimationComplete => _isAnimationComplete;

  @override
  void update(double dt) {
    super.update(dt);
    if (_isAnimationComplete) {
      return;
    }
    if (!_delayCompleted && startDelaySeconds > 0) {
      _delayElapsed += dt;
      if (_delayElapsed < startDelaySeconds) {
        return;
      }
      _delayCompleted = true;
      _applyVisualState(
        position: _startPosition,
        scaleMultiplier: startScale,
        opacityMultiplier: startOpacity,
      );
      dt = _delayElapsed - startDelaySeconds;
      _delayElapsed = startDelaySeconds;
      _elapsed = 0;
      if (dt <= 0) {
        return;
      }
    }
    if (_inAfterEffect) {
      _advanceAfterEffect(dt);
      return;
    }

    _elapsed += dt;
    final duration = durationSeconds <= 0 ? 0.0001 : durationSeconds;
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    _applyVisualState(
      position: _interpolatedPosition(progress),
      scaleMultiplier: _lerpDouble(startScale, endScale, progress),
      opacityMultiplier: _lerpDouble(startOpacity, endOpacity, progress),
    );

    if (progress >= 1.0) {
      if (afterEffect == BattleFxAfterEffect.none) {
        _completeAnimation();
      } else {
        _inAfterEffect = true;
        _afterEffectElapsed = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    if (_currentOpacityMultiplier < 0.999) {
      paint.colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: _currentOpacityMultiplier),
        BlendMode.modulate,
      );
    }
    sprite.render(
      canvas,
      size: size,
      overridePaint: paint,
    );
  }

  void _advanceAfterEffect(double dt) {
    _afterEffectElapsed += dt;
    final progress =
        (_afterEffectElapsed / _afterEffectSeconds).clamp(0.0, 1.0);
    switch (afterEffect) {
      case BattleFxAfterEffect.none:
        _completeAnimation();
      case BattleFxAfterEffect.fade:
        _applyVisualState(
          position: _endPosition,
          scaleMultiplier: endScale,
          opacityMultiplier: _lerpDouble(endOpacity, 0, progress),
        );
      case BattleFxAfterEffect.explode:
        _applyVisualState(
          position: _endPosition,
          scaleMultiplier: _lerpDouble(endScale, endScale * 1.6, progress),
          opacityMultiplier: _lerpDouble(endOpacity, 0, progress),
        );
    }
    if (progress >= 1.0) {
      _completeAnimation();
    }
  }

  void _applyVisualState({
    required Vector2 position,
    required double scaleMultiplier,
    required double opacityMultiplier,
  }) {
    this.position = position;
    _currentScaleMultiplier = scaleMultiplier;
    _currentOpacityMultiplier = opacityMultiplier.clamp(0.0, 1.0);
    final clampedScale = math.max(0.01, scaleMultiplier);
    size = Vector2(
      _baseDisplaySize.x * clampedScale,
      _baseDisplaySize.y * clampedScale,
    );
  }

  Vector2 _interpolatedPosition(double progress) {
    final curvedProgress = _curveProgress(progress);
    final linearPosition = Vector2(
      _lerpDouble(_startPosition.x, _endPosition.x, curvedProgress),
      _lerpDouble(_startPosition.y, _endPosition.y, curvedProgress),
    );
    switch (curve) {
      case BattleFxMotionCurve.linear:
      case BattleFxMotionCurve.easeOut:
        return linearPosition;
      case BattleFxMotionCurve.arcOver:
      case BattleFxMotionCurve.arcUnder:
        final distance = (_endPosition - _startPosition).length;
        final arcHeight = distance == 0 ? 22.0 : distance.clamp(18.0, 48.0);
        final arcOffset = math.sin(math.pi * progress) *
            arcHeight *
            (curve == BattleFxMotionCurve.arcOver ? -1 : 1);
        return Vector2(linearPosition.x, linearPosition.y + arcOffset);
    }
  }

  double _curveProgress(double progress) {
    return switch (curve) {
      BattleFxMotionCurve.linear => progress,
      BattleFxMotionCurve.easeOut => 1 - math.pow(1 - progress, 2).toDouble(),
      BattleFxMotionCurve.arcOver ||
      BattleFxMotionCurve.arcUnder =>
        1 - math.pow(1 - progress, 2).toDouble(),
    };
  }

  void _completeAnimation() {
    _isAnimationComplete = true;
  }
}

double _lerpDouble(double a, double b, double t) {
  return a + ((b - a) * t);
}
