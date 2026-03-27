import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_map_bundle.dart';
import 'overworld_actor_component.dart';

class PlayerComponent extends PositionComponent {
  PlayerComponent({
    required this.bundle,
    required GameplayPlayerState state,
    this.characterEntry,
    this.tileImages = const {},
  })  : _state = state,
        super(
          anchor: Anchor.topLeft,
          position: Vector2(
            state.pos.x * bundle.cellWidth,
            state.pos.y * bundle.cellHeight,
          ),
          size: Vector2(bundle.cellWidth, bundle.cellHeight),
        );

  final RuntimeMapBundle bundle;
  final ProjectCharacterEntry? characterEntry;
  final Map<String, ui.Image> tileImages;

  GameplayPlayerState _state;
  OverworldActorComponent? _actor;
  double _walkAnimRemaining = 0.0;
  static const double _kStepInterpolationSeconds = 0.12;
  Vector2? _moveFrom;
  Vector2? _moveTo;
  double _moveRemaining = 0.0;

  void _snapToStatePosition() {
    position = Vector2(
      _state.pos.x * bundle.cellWidth,
      _state.pos.y * bundle.cellHeight,
    );
  }

  @override
  Future<void> onLoad() async {
    _snapToStatePosition();
    final entry = characterEntry;
    if (entry != null) {
      final actor = OverworldActorComponent(
        character: entry,
        tileImages: tileImages,
        tileWidth: bundle.manifest.settings.tileWidth,
        tileHeight: bundle.manifest.settings.tileHeight,
        cellWidth: bundle.cellWidth,
        cellHeight: bundle.cellHeight,
        facing: EntityFacing.values.byName(_state.facing.name),
      );
      actor.position = Vector2(0, -actor.footOffsetY);
      _actor = actor;
      await add(actor);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_moveRemaining > 0 && _moveFrom != null && _moveTo != null) {
      _moveRemaining -= dt;
      final progress = ((_kStepInterpolationSeconds - _moveRemaining) /
              _kStepInterpolationSeconds)
          .clamp(0.0, 1.0);
      position = Vector2(
        _moveFrom!.x + (_moveTo!.x - _moveFrom!.x) * progress,
        _moveFrom!.y + (_moveTo!.y - _moveFrom!.y) * progress,
      );
      if (_moveRemaining <= 0) {
        position = _moveTo!.clone();
        _moveFrom = null;
        _moveTo = null;
        _moveRemaining = 0.0;
      }
    }
    if (_walkAnimRemaining > 0) {
      _walkAnimRemaining -= dt;
      if (_walkAnimRemaining <= 0) {
        _walkAnimRemaining = 0;
        _actor?.setMotion(
          EntityFacing.values.byName(_state.facing.name),
          CharacterAnimationState.idle,
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_actor != null) return;
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
    final moved = state.pos != _state.pos;
    _state = state;
    final target = Vector2(
      state.pos.x * bundle.cellWidth,
      state.pos.y * bundle.cellHeight,
    );
    if (moved) {
      _moveFrom = position.clone();
      _moveTo = target;
      _moveRemaining = _kStepInterpolationSeconds;
    } else {
      _moveFrom = null;
      _moveTo = null;
      _moveRemaining = 0.0;
      position = target;
    }
    final facing = EntityFacing.values.byName(state.facing.name);
    if (moved) {
      _walkAnimRemaining = _kStepInterpolationSeconds;
      _actor?.setMotion(facing, CharacterAnimationState.walk);
    } else {
      _actor?.setMotion(facing, CharacterAnimationState.idle);
    }
  }
}
