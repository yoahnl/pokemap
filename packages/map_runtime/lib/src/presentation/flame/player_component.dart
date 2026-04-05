import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../application/runtime_map_bundle.dart';
import 'overworld_actor_component.dart';

class PlayerComponent extends PositionComponent {
  static const double kDefaultStepSeconds = 0.12;

  PlayerComponent({
    required this.bundle,
    required GameplayPlayerState state,
    this.characterEntry,
    this.tileImages = const {},
    Vector2? mapOrigin,
  })  : _state = state,
        _mapOrigin = mapOrigin?.clone() ?? Vector2.zero(),
        super(
          anchor: Anchor.topLeft,
          position: Vector2(
            (mapOrigin?.x ?? 0) + state.pos.x * bundle.cellWidth,
            (mapOrigin?.y ?? 0) + state.pos.y * bundle.cellHeight,
          ),
          size: Vector2(bundle.cellWidth, bundle.cellHeight),
        );

  final RuntimeMapBundle bundle;
  final ProjectCharacterEntry? characterEntry;
  final Map<String, ui.Image> tileImages;

  GameplayPlayerState _state;
  Vector2 _mapOrigin;
  OverworldActorComponent? _actor;
  Vector2? _moveFrom;
  Vector2? _moveTo;
  double _moveRemaining = 0.0;
  double _stepDurationSeconds = kDefaultStepSeconds;

  bool get isStepping => _moveTo != null && _moveRemaining > 0;
  Vector2 get focusPoint => Vector2(
        position.x + bundle.cellWidth / 2,
        position.y + bundle.cellHeight / 2,
      );
  Vector2 get footPoint => Vector2(
        position.x + bundle.cellWidth / 2,
        position.y + bundle.cellHeight,
      );

  Vector2 get mapOrigin => _mapOrigin.clone();

  void _snapToStatePosition() {
    final target = Vector2(
      _mapOrigin.x + _state.pos.x * bundle.cellWidth,
      _mapOrigin.y + _state.pos.y * bundle.cellHeight,
    );
    position = Vector2(
      target.x.roundToDouble(),
      target.y.roundToDouble(),
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
      final extraWidthTiles = math.max(0, actor.frameWidthTiles - 1);
      final offsetX = -(extraWidthTiles * bundle.cellWidth) / 2;
      actor.position = Vector2(offsetX, -actor.footOffsetY);
      _actor = actor;
      await add(actor);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isStepping && _moveFrom != null && _moveTo != null) {
      _moveRemaining = (_moveRemaining - dt).clamp(0.0, _stepDurationSeconds);
      final progress =
          ((_stepDurationSeconds - _moveRemaining) / _stepDurationSeconds)
              .clamp(0.0, 1.0);
      final next = Vector2(
        _moveFrom!.x + (_moveTo!.x - _moveFrom!.x) * progress,
        _moveFrom!.y + (_moveTo!.y - _moveFrom!.y) * progress,
      );
      position = Vector2(
        next.x.roundToDouble(),
        next.y.roundToDouble(),
      );
      if (_moveRemaining <= 0) {
        position = _moveTo!.clone();
        _moveFrom = null;
        _moveTo = null;
        _moveRemaining = 0.0;
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

  void syncState(GameplayPlayerState state, {bool snapToGrid = false}) {
    _state = state;
    final facing = EntityFacing.values.byName(state.facing.name);
    if (snapToGrid || !isStepping) {
      _moveFrom = null;
      _moveTo = null;
      _moveRemaining = 0.0;
      _snapToStatePosition();
      _actor?.setMotion(facing, CharacterAnimationState.idle);
    } else {
      // Ne pas forcer idle pendant l’interpolation d’un pas (sinon tout appel
      // à syncState — ex. changement de mode — écrase l’anim marche).
      _actor?.setMotion(facing, CharacterAnimationState.walk);
    }
  }

  void startStep(
    GameplayPlayerState state, {
    double durationSeconds = kDefaultStepSeconds,
  }) {
    _state = state;
    _stepDurationSeconds = durationSeconds;
    _moveFrom = position.clone();
    _moveTo = Vector2(
      _mapOrigin.x + state.pos.x * bundle.cellWidth,
      _mapOrigin.y + state.pos.y * bundle.cellHeight,
    );
    _moveRemaining = durationSeconds;
    _actor?.setMotion(
      EntityFacing.values.byName(state.facing.name),
      CharacterAnimationState.walk,
    );
  }

  void updateState(GameplayPlayerState state) {
    syncState(state, snapToGrid: true);
  }

  void setMapOrigin(Vector2 origin, {bool snapToGrid = false}) {
    _mapOrigin = origin.clone();
    if (snapToGrid) {
      _snapToStatePosition();
    }
  }
}
