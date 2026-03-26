import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_map_bundle.dart';

class PlayerComponent extends PositionComponent {
  PlayerComponent({required this.bundle, required GameplayPlayerState state})
      : _state = state,
        super(
          anchor: Anchor.topLeft,
          position: Vector2(
            state.pos.x * bundle.cellWidth,
            state.pos.y * bundle.cellHeight,
          ),
          size: Vector2(bundle.cellWidth, bundle.cellHeight),
        );

  final RuntimeMapBundle bundle;
  GameplayPlayerState _state;

  @override
  void render(Canvas canvas) {
    final cw = bundle.cellWidth;
    final ch = bundle.cellHeight;
    final cx = cw / 2;
    final cy = ch / 2;
    final r = math.min(cw, ch) * 0.28;

    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = const Color(0xCC2196F3),
    );

    final angle = switch (_state.facing) {
      Direction.north => -math.pi / 2,
      Direction.south => math.pi / 2,
      Direction.east => 0.0,
      Direction.west => math.pi,
    };
    canvas.drawCircle(
      Offset(cx + math.cos(angle) * r * 0.65, cy + math.sin(angle) * r * 0.65),
      r * 0.28,
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  void updateState(GameplayPlayerState state) {
    _state = state;
    position = Vector2(
      state.pos.x * bundle.cellWidth,
      state.pos.y * bundle.cellHeight,
    );
  }
}
