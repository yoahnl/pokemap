import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

class OverworldActorComponent extends PositionComponent {
  OverworldActorComponent({
    required this.character,
    required this.tileImages,
    required int tileWidth,
    required int tileHeight,
    required double cellWidth,
    required double cellHeight,
    EntityFacing facing = EntityFacing.south,
    CharacterAnimationState animState = CharacterAnimationState.idle,
  })  : _facing = facing,
        _animState = animState,
        _tileWidth = tileWidth,
        _tileHeight = tileHeight,
        _cellWidth = cellWidth,
        _cellHeight = cellHeight,
        super(
          anchor: Anchor.topLeft,
          size: Vector2(
            character.frameWidth * cellWidth,
            character.frameHeight * cellHeight,
          ),
        );

  final ProjectCharacterEntry character;
  final Map<String, ui.Image> tileImages;
  final int _tileWidth;
  final int _tileHeight;
  final double _cellWidth;
  final double _cellHeight;

  EntityFacing _facing;
  CharacterAnimationState _animState;
  double _animElapsed = 0.0;

  void setMotion(EntityFacing facing, CharacterAnimationState animState) {
    if (_facing == facing && _animState == animState) return;
    _facing = facing;
    _animState = animState;
    _animElapsed = 0.0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animElapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    final anim = _findAnimation();
    if (anim == null || anim.frames.isEmpty) {
      _renderFallback(canvas);
      return;
    }
    final image = tileImages[character.tilesetId];
    if (image == null) {
      _renderFallback(canvas);
      return;
    }
    final frame = _pickFrame(anim.frames);
    final src = frame.source;
    final srcW = character.frameWidth * _tileWidth;
    final srcH = character.frameHeight * _tileHeight;
    final srcRect = Rect.fromLTWH(
      (src.x * _tileWidth).toDouble(),
      (src.y * _tileHeight).toDouble(),
      srcW.toDouble(),
      srcH.toDouble(),
    );
    if (srcRect.right > image.width || srcRect.bottom > image.height) {
      _renderFallback(canvas);
      return;
    }
    canvas.drawImageRect(
      image,
      srcRect,
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  CharacterAnimation? _findAnimation() {
    CharacterAnimation? idleFallback;
    for (final a in character.animations) {
      if (a.direction != _facing) continue;
      if (a.state == _animState) return a;
      if (a.state == CharacterAnimationState.idle) idleFallback = a;
    }
    return idleFallback;
  }

  CharacterAnimationFrame _pickFrame(List<CharacterAnimationFrame> frames) {
    if (frames.length == 1) return frames.first;
    final elapsedMs = (_animElapsed * 1000).toInt();
    var total = 0;
    for (final f in frames) {
      total += f.durationMs;
    }
    if (total <= 0) return frames.first;
    var t = elapsedMs % total;
    for (final f in frames) {
      if (t < f.durationMs) return f;
      t -= f.durationMs;
    }
    return frames.last;
  }

  void _renderFallback(Canvas canvas) {
    final cx = _cellWidth / 2;
    final cy = (character.frameHeight - 0.5) * _cellHeight;
    final r = math.min(_cellWidth, _cellHeight) * 0.28;
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = const Color(0xCC4CAF50),
    );
  }
}
