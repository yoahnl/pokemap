import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../map_warp_transition_overlay.dart';

class WarpTransitionOverlayComponent extends PositionComponent {
  WarpTransitionOverlayComponent({
    required Vector2 viewportSize,
    this.transition = const MapWarpTransition(),
  }) : super(size: viewportSize, anchor: Anchor.topLeft, priority: 98);

  final MapWarpTransition transition;
  Completer<void>? _animationCompleter;
  double _coverage = 0.0;
  double _fromCoverage = 0.0;
  double _toCoverage = 0.0;
  double _durationSeconds = 0.0;
  double _elapsedSeconds = 0.0;
  bool _revealing = false;

  Future<void> fadeOut({Duration? duration}) {
    _revealing = false;
    return _animateTo(1.0, duration ?? _configuredDuration);
  }

  Future<void> fadeIn({Duration? duration}) {
    _revealing = true;
    return _animateTo(0.0, duration ?? _configuredDuration);
  }

  Duration get _configuredDuration => Duration(
    microseconds: (transition.durationSeconds * Duration.microsecondsPerSecond)
        .round(),
  );

  Future<void> _animateTo(double targetCoverage, Duration duration) {
    _completeAnimation();
    if (transition.type == MapWarpTransitionType.none ||
        duration <= Duration.zero) {
      _coverage = transition.type == MapWarpTransitionType.none
          ? 0
          : targetCoverage;
      return Future<void>.value();
    }
    _animationCompleter = Completer<void>();
    _fromCoverage = _coverage;
    _toCoverage = targetCoverage;
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
    _coverage = _fromCoverage + (_toCoverage - _fromCoverage) * progress;
    if (progress >= 1.0) {
      _completeAnimation();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    paintMapWarpTransition(
      canvas,
      Size(size.x, size.y),
      transition,
      _coverage,
      revealing: _revealing,
    );
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
