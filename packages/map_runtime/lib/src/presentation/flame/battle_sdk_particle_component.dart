import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

final class BattleSdkParticleComponent extends PositionComponent {
  BattleSdkParticleComponent({
    required this.sprite,
    required Vector2 startPosition,
    required Vector2 endPosition,
    required this.startScaleX,
    required this.startScaleY,
    required this.endScaleX,
    required this.endScaleY,
    required this.startOpacity,
    required this.endOpacity,
    required this.delaySeconds,
    required this.durationSeconds,
    this.rotationTurns = 0,
    this.tintColor,
  })  : _startPosition = startPosition.clone(),
        _endPosition = endPosition.clone(),
        super(
          position: startPosition.clone(),
          size: sprite.srcSize.clone(),
          anchor: Anchor.center,
          priority: 17,
        ) {
    _applyVisualState(
        progress: delaySeconds > 0 ? 0 : 0, hidden: delaySeconds > 0);
  }

  final Sprite sprite;
  final Vector2 _startPosition;
  final Vector2 _endPosition;
  final double startScaleX;
  final double startScaleY;
  final double endScaleX;
  final double endScaleY;
  final double startOpacity;
  final double endOpacity;
  final double delaySeconds;
  final double durationSeconds;
  final double rotationTurns;
  final Color? tintColor;

  double _elapsed = 0;
  bool _isAnimationComplete = false;
  double _currentScaleX = 1;
  double _currentScaleY = 1;
  double _currentOpacity = 1;
  double _currentRotationRadians = 0;

  bool get isAnimationComplete => _isAnimationComplete;

  @visibleForTesting
  double get currentScaleX => _currentScaleX;

  @visibleForTesting
  double get currentScaleY => _currentScaleY;

  @visibleForTesting
  double get currentOpacity => _currentOpacity;

  @visibleForTesting
  double get currentRotationRadians => _currentRotationRadians;

  @override
  void update(double dt) {
    super.update(dt);
    if (_isAnimationComplete) {
      return;
    }
    _elapsed += dt;
    if (_elapsed < delaySeconds) {
      _applyVisualState(progress: 0, hidden: true);
      return;
    }
    final localElapsed = _elapsed - delaySeconds;
    final duration = durationSeconds <= 0 ? 0.0001 : durationSeconds;
    final progress = (localElapsed / duration).clamp(0.0, 1.0);
    _applyVisualState(progress: progress, hidden: false);
    if (progress >= 1) {
      _isAnimationComplete = true;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_currentOpacity <= 0) {
      return;
    }
    final paint = Paint()..filterQuality = FilterQuality.none;
    final tint = tintColor;
    if (tint != null) {
      paint.colorFilter = ColorFilter.mode(
        tint.withValues(alpha: tint.a * _currentOpacity),
        BlendMode.modulate,
      );
    } else if (_currentOpacity < 0.999) {
      paint.colorFilter = ColorFilter.mode(
        Colors.white.withValues(alpha: _currentOpacity),
        BlendMode.modulate,
      );
    }
    canvas.save();
    canvas.rotate(_currentRotationRadians);
    canvas.scale(_currentScaleX, _currentScaleY);
    sprite.render(
      canvas,
      size: size,
      overridePaint: paint,
    );
    canvas.restore();
  }

  void _applyVisualState({
    required double progress,
    required bool hidden,
  }) {
    position = Vector2(
      _lerpDouble(_startPosition.x, _endPosition.x, progress),
      _lerpDouble(_startPosition.y, _endPosition.y, progress),
    );
    _currentScaleX = _lerpDouble(startScaleX, endScaleX, progress);
    _currentScaleY = _lerpDouble(startScaleY, endScaleY, progress);
    _currentOpacity = hidden
        ? 0
        : _lerpDouble(startOpacity, endOpacity, progress).clamp(0.0, 1.0);
    _currentRotationRadians = math.pi * 2 * rotationTurns * progress;
  }
}

double _lerpDouble(double a, double b, double t) {
  return a + ((b - a) * t);
}
