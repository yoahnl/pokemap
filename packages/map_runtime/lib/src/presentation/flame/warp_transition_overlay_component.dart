import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class WarpTransitionOverlayComponent extends PositionComponent {
  WarpTransitionOverlayComponent({
    required Vector2 viewportSize,
  }) : super(
          size: viewportSize,
          anchor: Anchor.topLeft,
          priority: 98,
        );

  final Paint _paint = Paint()..color = const Color(0x00000000);
  late final RectangleComponent _blocker;
  Completer<void>? _animationCompleter;
  double _fromOpacity = 0.0;
  double _toOpacity = 0.0;
  double _durationSeconds = 0.0;
  double _elapsedSeconds = 0.0;

  @override
  Future<void> onLoad() async {
    _blocker = RectangleComponent(
      size: size.clone(),
      paint: _paint,
      anchor: Anchor.topLeft,
      priority: 0,
    );
    add(_blocker);
  }

  Future<void> fadeOut({
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return _animateTo(1.0, duration);
  }

  Future<void> fadeIn({
    Duration duration = const Duration(milliseconds: 180),
  }) {
    return _animateTo(0.0, duration);
  }

  Future<void> _animateTo(double targetOpacity, Duration duration) {
    final target = targetOpacity.clamp(0.0, 1.0);
    if (duration <= Duration.zero) {
      _setOpacity(target);
      return Future<void>.value();
    }
    _completeAnimation();
    _animationCompleter = Completer<void>();
    _fromOpacity = _currentOpacity;
    _toOpacity = target;
    _durationSeconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
    _elapsedSeconds = 0.0;
    return _animationCompleter!.future;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final completer = _animationCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }
    _elapsedSeconds += dt;
    final progress = (_elapsedSeconds / _durationSeconds).clamp(0.0, 1.0);
    final opacity = _fromOpacity + (_toOpacity - _fromOpacity) * progress;
    _setOpacity(opacity);
    if (progress >= 1.0) {
      _completeAnimation();
    }
  }

  double get _currentOpacity => _paint.color.a;

  void _setOpacity(double value) {
    final clamped = value.clamp(0.0, 1.0);
    _paint.color = Color.fromRGBO(0, 0, 0, clamped);
  }

  void close() {
    _completeAnimation();
    removeFromParent();
  }

  void _completeAnimation() {
    final completer = _animationCompleter;
    if (completer == null) {
      return;
    }
    if (!completer.isCompleted) {
      completer.complete();
    }
    _animationCompleter = null;
  }
}
