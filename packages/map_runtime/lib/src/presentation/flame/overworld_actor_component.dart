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

  /// Masque le sprite sans retirer le composant (visibilité conditionnelle PNJ).
  bool _gameplayVisible = true;

  /// Vrai si on affiche une anim « idle » (ou peu de frames) pendant un pas
  /// alors que l’état logique demande marche/course — léger bob pour éviter
  /// l’effet « lévitation » quand le tileset n’a pas de strip walk pour cette direction.
  bool _strideBobActive = false;

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

  void setGameplayVisible(bool visible) {
    _gameplayVisible = visible;
  }

  int get frameWidthTiles => _frameWidthTiles;
  int get frameHeightTiles => _frameHeightTiles;
  double get footOffsetY => (_frameHeightTiles - 1) * _cellHeight;
  double get depthSortY => position.y + size.y;
  bool get isStepping => _moveTo != null && _moveRemaining > 0;
  GridPos? get gridPos => _gridPos;

  void setMotion(EntityFacing facing, CharacterAnimationState animState) {
    // Guard rail:
    // pendant un pas interpolé, certains appels externes peuvent demander
    // "idle" avant la fin visuelle du déplacement (resync runtime, update état).
    // Ignorer cet idle empêche d'éteindre l'animation de marche en plein step.
    if (animState == CharacterAnimationState.idle &&
        isStepping &&
        (_animState == CharacterAnimationState.walk ||
            _animState == CharacterAnimationState.run)) {
      if (_facing != facing) {
        _facing = facing;
        _animElapsed = 0.0;
      }
      return;
    }

    if (_facing == facing && _animState == animState) {
      return;
    }

    // Cause racine du "ça glisse sans animation":
    // - les steps runtime sont courts (~120ms),
    // - les frames walk sont souvent à 150ms,
    // - si on reset _animElapsed à chaque transition idle<->walk, on reste
    //   bloqué sur la première frame à chaque pas.
    //
    // Stratégie:
    // - on conserve la phase d'animation quand on alterne idle <-> walk/run
    //   avec la même direction,
    // - on reset uniquement sur changement de direction ou changement de mode
    //   animation "fort" (ex: walk->run).
    //
    // Résultat:
    // - player + NPC continuent d'animer leurs jambes de façon visible même
    //   avec des pas rapides.
    final previousFacing = _facing;
    final previousState = _animState;
    final togglesMovementIdle =
        (previousState == CharacterAnimationState.idle &&
                (animState == CharacterAnimationState.walk ||
                    animState == CharacterAnimationState.run)) ||
            ((previousState == CharacterAnimationState.walk ||
                    previousState == CharacterAnimationState.run) &&
                animState == CharacterAnimationState.idle);
    final preserveAnimationPhase =
        previousFacing == facing && togglesMovementIdle;

    _facing = facing;
    _animState = animState;
    if (!preserveAnimationPhase) {
      _animElapsed = 0.0;
    }
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
    if (!_gameplayVisible) {
      return;
    }
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
    final strideTimeScale =
        _strideBobActive && anim.frames.length <= 3 ? 2.4 : 1.0;
    final frame = _pickFrame(anim.frames, timeScale: strideTimeScale);
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
    final bobY = _strideBobActive
        ? math.sin(_animElapsed * math.pi * 2 * 5.5) *
            (0.04 * math.min(_cellHeight, _cellWidth))
        : 0.0;
    canvas.save();
    canvas.translate(0, bobY);
    canvas.drawImageRect(
      image,
      srcRect,
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..filterQuality = FilterQuality.none,
    );
    canvas.restore();
  }

  static bool _hasFrames(CharacterAnimation? a) =>
      a != null && a.frames.isNotEmpty;

  CharacterAnimation? _findAnimation() {
    _strideBobActive = false;

    CharacterAnimation? exactFacing;
    CharacterAnimation? idleFacing;
    CharacterAnimation? walkFacing;
    CharacterAnimation? runFacing;
    CharacterAnimation? walkAny;
    CharacterAnimation? runAny;
    CharacterAnimation? idleAny;

    for (final a in character.animations) {
      if (!_hasFrames(a)) continue;
      if (a.direction == _facing) {
        if (a.state == _animState) exactFacing = a;
        switch (a.state) {
          case CharacterAnimationState.idle:
            idleFacing = a;
            break;
          case CharacterAnimationState.walk:
            walkFacing = a;
            break;
          case CharacterAnimationState.run:
            runFacing = a;
            break;
        }
      } else {
        switch (a.state) {
          case CharacterAnimationState.walk:
            walkAny ??= a;
            break;
          case CharacterAnimationState.run:
            runAny ??= a;
            break;
          case CharacterAnimationState.idle:
            idleAny ??= a;
            break;
        }
      }
    }

    if (_hasFrames(exactFacing)) {
      return exactFacing;
    }

    final wantsMotion = _animState == CharacterAnimationState.walk ||
        _animState == CharacterAnimationState.run;

    if (wantsMotion) {
      final List<CharacterAnimation?> cascade =
          _animState == CharacterAnimationState.walk
              ? <CharacterAnimation?>[
                  walkFacing,
                  runFacing,
                  walkAny,
                  runAny,
                  idleFacing,
                  idleAny,
                ]
              : <CharacterAnimation?>[
                  runFacing,
                  walkFacing,
                  runAny,
                  walkAny,
                  idleFacing,
                  idleAny,
                ];

      for (final candidate in cascade) {
        if (!_hasFrames(candidate)) continue;
        if (candidate!.state == CharacterAnimationState.idle && isStepping) {
          _strideBobActive = true;
        }
        return candidate;
      }
    }

    return idleFacing ?? idleAny;
  }

  CharacterAnimationFrame _pickFrame(
    List<CharacterAnimationFrame> frames, {
    double timeScale = 1.0,
  }) {
    if (frames.length == 1) return frames.first;
    final elapsedMs = (_animElapsed * 1000 * timeScale).toInt();
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
