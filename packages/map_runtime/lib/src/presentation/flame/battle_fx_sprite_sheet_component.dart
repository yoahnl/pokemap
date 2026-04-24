import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

final class BattleFxSpriteSheetComponent extends PositionComponent {
  BattleFxSpriteSheetComponent({
    required this.image,
    required Vector2 anchorPosition,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
    required this.frameDurationSeconds,
    required this.columns,
    required this.originX,
    required this.originY,
    required this.displayScale,
    required this.opacity,
    this.startDelaySeconds = 0,
    this.frameSequence,
    this.frameDurationsSeconds,
  }) : super(
          position: Vector2(
            anchorPosition.x - (originX * displayScale),
            anchorPosition.y - (originY * displayScale),
          ),
          size: Vector2(
            frameWidth * displayScale,
            frameHeight * displayScale,
          ),
          anchor: Anchor.topLeft,
          priority: 17,
        );

  final ui.Image image;
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final double frameDurationSeconds;
  final int columns;
  final double originX;
  final double originY;
  final double displayScale;
  final double opacity;
  final double startDelaySeconds;
  final List<int>? frameSequence;
  final List<double>? frameDurationsSeconds;

  double _elapsed = 0;
  bool _isComplete = false;

  bool get isAnimationComplete => _isComplete;

  @visibleForTesting
  int get currentTimelineFrameIndex {
    if (_elapsed < startDelaySeconds) {
      return 0;
    }
    final localElapsed = _elapsed - startDelaySeconds;
    final durations = frameDurationsSeconds;
    if (durations != null && durations.isNotEmpty) {
      var elapsed = localElapsed;
      for (var index = 0; index < durations.length; index++) {
        final duration = durations[index] <= 0 ? 0.0001 : durations[index];
        if (elapsed < duration) {
          return index;
        }
        elapsed -= duration;
      }
      return durations.length - 1;
    }
    final frameDuration =
        frameDurationSeconds <= 0 ? 0.0001 : frameDurationSeconds;
    final timelineFrameCount = frameSequence?.length ?? frameCount;
    return (localElapsed / frameDuration)
        .floor()
        .clamp(0, timelineFrameCount - 1);
  }

  @visibleForTesting
  int get currentFrameIndex => currentSourceFrameIndex;

  @visibleForTesting
  int get currentSourceFrameIndex {
    final timelineIndex = currentTimelineFrameIndex;
    final sequence = frameSequence;
    final sourceFrame =
        sequence == null ? timelineIndex : sequence[timelineIndex];
    return sourceFrame.clamp(0, frameCount - 1);
  }

  @visibleForTesting
  Rect get currentSourceRect {
    final safeColumns = columns <= 0 ? 1 : columns;
    final frame = currentSourceFrameIndex;
    final sourceColumn = frame % safeColumns;
    final sourceRow = frame ~/ safeColumns;
    return Rect.fromLTWH(
      (sourceColumn * frameWidth).toDouble(),
      (sourceRow * frameHeight).toDouble(),
      frameWidth.toDouble(),
      frameHeight.toDouble(),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isComplete) {
      return;
    }
    _elapsed += dt;
    final totalDuration = startDelaySeconds + _playbackDurationSeconds;
    if (_elapsed >= totalDuration) {
      _isComplete = true;
    }
  }

  double get _playbackDurationSeconds {
    final durations = frameDurationsSeconds;
    if (durations != null) {
      return durations.fold<double>(0, (total, duration) => total + duration);
    }
    return (frameSequence?.length ?? frameCount) * frameDurationSeconds;
  }

  @override
  void render(Canvas canvas) {
    if (_elapsed < startDelaySeconds || _isComplete) {
      return;
    }
    final sourceRect = currentSourceRect;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..color = Colors.white.withValues(
        alpha: opacity.clamp(0.0, 1.0).toDouble(),
      );
    canvas.drawImageRect(
      image,
      sourceRect,
      Offset.zero & Size(size.x, size.y),
      paint,
    );
  }
}
