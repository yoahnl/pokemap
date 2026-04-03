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
        _frameWidthTiles = math.max(2, character.frameWidth),
        _frameHeightTiles = math.max(2, character.frameHeight),
        _cellHeight = cellHeight,
        super(
          anchor: Anchor.topLeft,
          size: Vector2(
            math.max(2, character.frameWidth) * cellWidth,
            math.max(2, character.frameHeight) * cellHeight,
          ),
        );

  final ProjectCharacterEntry character;
  final Map<String, ui.Image> tileImages;
  final int _tileWidth;
  final int _tileHeight;
  final double _cellWidth;
  final double _cellHeight;
  final int _frameWidthTiles;
  final int _frameHeightTiles;

  EntityFacing _facing;
  CharacterAnimationState _animState;
  double _animElapsed = 0.0;

  // --- Déplacement grille interpolé (base cutscene runtime) -----------------
  //
  // On garde cette logique dans le composant acteur pour deux raisons:
  // 1) éviter d'alourdir PlayableMapGame avec de l'interpolation sprite;
  // 2) rendre réutilisable le déplacement scripté pour tout PNJ/entité actor.
  //
  // Le contrôleur applicatif décide "où aller". Ce composant anime "comment
  // on se déplace visuellement entre deux cases".
  GridPos? _gridPos;
  GridSize _entityFootprint = const GridSize(width: 1, height: 1);
  Vector2 _mapOrigin = Vector2.zero();
  Vector2? _moveFrom;
  Vector2? _moveTo;
  double _moveRemaining = 0;
  double _stepDurationSeconds = 0.12;

  int get frameWidthTiles => _frameWidthTiles;
  int get frameHeightTiles => _frameHeightTiles;
  double get footOffsetY => (_frameHeightTiles - 1) * _cellHeight;
  double get depthSortY => position.y + size.y;
  bool get isStepping => _moveTo != null && _moveRemaining > 0;
  GridPos? get gridPos => _gridPos;

  void setMotion(EntityFacing facing, CharacterAnimationState animState) {
    if (_facing == facing && _animState == animState) return;
    _facing = facing;
    _animState = animState;
    _animElapsed = 0.0;
  }

  /// Configure la position grille de référence de l'acteur.
  ///
  /// Appelé au montage map (et lors de resync). Cette configuration est
  /// indispensable pour convertir proprement une case grille -> pixels.
  void configureGridPlacement({
    required GridPos pos,
    required GridSize footprint,
    required Vector2 mapOrigin,
    bool snapToGrid = true,
  }) {
    _gridPos = pos;
    _entityFootprint = footprint;
    _mapOrigin = mapOrigin.clone();
    if (snapToGrid) {
      _moveFrom = null;
      _moveTo = null;
      _moveRemaining = 0;
      position = _gridToPixels(pos);
    }
  }

  /// Lance un pas animé vers la case [to].
  ///
  /// Retourne `false` si l'acteur n'a pas encore été configuré avec une
  /// position grille de départ.
  bool startGridStep({
    required GridPos to,
    required EntityFacing facing,
    double durationSeconds = 0.12,
  }) {
    final current = _gridPos;
    if (current == null) {
      return false;
    }
    setMotion(facing, CharacterAnimationState.walk);
    _stepDurationSeconds = durationSeconds <= 0 ? 0.12 : durationSeconds;
    _moveFrom = position.clone();
    _moveTo = _gridToPixels(to);
    _moveRemaining = _stepDurationSeconds;
    // On commit la case logique au démarrage du pas pour rester aligné avec
    // la simulation grille runtime.
    _gridPos = to;
    return true;
  }

  Vector2 _gridToPixels(GridPos pos) {
    final topY = pos.y + _entityFootprint.height - _frameHeightTiles;
    final extraWidthTiles =
        math.max(0, _frameWidthTiles - _entityFootprint.width);
    final offsetX = -(extraWidthTiles * _cellWidth) / 2;
    return Vector2(
      _mapOrigin.x + pos.x * _cellWidth + offsetX,
      _mapOrigin.y + topY * _cellHeight,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animElapsed += dt;
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
        _moveRemaining = 0;
        // Retour explicite en idle quand le pas est fini.
        setMotion(_facing, CharacterAnimationState.idle);
      }
    }
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
    final srcW = _frameWidthTiles * _tileWidth;
    final srcH = _frameHeightTiles * _tileHeight;
    final srcRect = Rect.fromLTWH(
      (src.x * srcW).toDouble(),
      (src.y * srcH).toDouble(),
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
      Paint()..filterQuality = FilterQuality.none,
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
    final cy = (_frameHeightTiles - 0.5) * _cellHeight;
    final r = math.min(_cellWidth, _cellHeight) * 0.28;
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = const Color(0xCC4CAF50),
    );
  }
}
