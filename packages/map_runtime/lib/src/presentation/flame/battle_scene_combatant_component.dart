import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import '../../infrastructure/tile_image_loader.dart';
import 'battle_pokemon_sprite_resolver.dart';
import 'battle_visual_asset_cache.dart';

class BattleSceneCombatantComponent extends PositionComponent {
  BattleSceneCombatantComponent({
    required Rect sceneSpriteRect,
    required Rect scenePlatformRect,
    required Offset sceneFootAnchor,
    required double spriteFootXRatio,
    required this.isPlayerSide,
    required String speciesLabel,
    this.visualAssetCache,
    BattleCombatantSpriteSpec initialSpriteSpec =
        const BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
    ),
  })  : _speciesLabel = speciesLabel,
        _spriteSpec = initialSpriteSpec,
        _spriteRect = _toLocalRect(
          sceneSpriteRect,
          _sceneBounds(sceneSpriteRect, scenePlatformRect),
        ),
        _platformRect = _toLocalRect(
          scenePlatformRect,
          _sceneBounds(sceneSpriteRect, scenePlatformRect),
        ),
        _footAnchor = _toLocalOffset(
          sceneFootAnchor,
          _sceneBounds(sceneSpriteRect, scenePlatformRect),
        ),
        _spriteFootXRatio = spriteFootXRatio,
        super(
          position: Vector2(
            _sceneBounds(sceneSpriteRect, scenePlatformRect).left,
            _sceneBounds(sceneSpriteRect, scenePlatformRect).top,
          ),
          size: Vector2(
            _sceneBounds(sceneSpriteRect, scenePlatformRect).width,
            _sceneBounds(sceneSpriteRect, scenePlatformRect).height,
          ),
          anchor: Anchor.topLeft,
          priority: 10,
        ) {
    _basePosition = position.clone();
  }

  final bool isPlayerSide;
  final BattleVisualAssetCache? visualAssetCache;

  String _speciesLabel;
  BattleCombatantSpriteSpec _spriteSpec;
  Rect _spriteRect;
  Rect _platformRect;
  Offset _footAnchor;
  final double _spriteFootXRatio;
  ui.Image? _spriteImage;
  Rect? _spriteOpaqueSourceRect;
  String? _spriteSourcePath;
  String? _pendingSpriteSourcePath;
  bool _didSpriteLoadFail = false;
  double _hitFlashRemaining = 0;
  TextComponent? _speciesText;
  TextComponent? _monogramText;
  Vector2 _basePosition = Vector2.zero();
  Vector2 _sceneCameraOffset = Vector2.zero();
  double _sceneCameraScale = 1.0;
  Offset _visualOffset = Offset.zero;
  double _visualOpacity = 1.0;
  double _visualScaleX = 1.0;
  double _visualScaleY = 1.0;
  Color? _visualToneColor;
  double _visualToneStrength = 0;
  double _toneElapsed = 0;
  double _toneDuration = 0;
  _CombatantPresentationAnimation _animation =
      _CombatantPresentationAnimation.none;
  double _animationElapsed = 0;
  double _animationDuration = 0;
  double _animationDistancePx = 0;
  double _animationRadiusX = 0;
  double _animationRadiusY = 0;
  int _animationTurns = 1;
  double _animationScaleDeltaX = 0;
  double _animationScaleDeltaY = 0;
  int _animationIterations = 1;
  bool _animationTowardOpponent = true;

  @visibleForTesting
  bool get hasResolvedExplicitSprite => _spriteImage != null;

  @visibleForTesting
  bool get didExplicitSpriteLoadFail => _didSpriteLoadFail;

  @visibleForTesting
  String? get currentSpriteSourcePath => _spriteSourcePath;

  @visibleForTesting
  bool get belongsToPlayerSide => isPlayerSide;

  @visibleForTesting
  String get currentSpeciesLabel => _speciesLabel;

  @visibleForTesting
  Rect get currentSpriteRect =>
      _spriteRect.shift(Offset(position.x, position.y));

  @visibleForTesting
  Rect get currentPlatformRect =>
      _platformRect.shift(Offset(position.x, position.y));

  @visibleForTesting
  Offset get currentFootAnchor => _footAnchor.translate(position.x, position.y);

  Rect get currentRenderedSpriteRect =>
      _currentRenderedSpriteRectLocal().shift(Offset(position.x, position.y));

  Rect get currentCameraNeutralRenderedSpriteRect =>
      _currentRenderedSpriteRectLocal().shift(_cameraNeutralPosition);

  Rect get currentCameraNeutralPlatformRect =>
      _platformRect.shift(_cameraNeutralPosition);

  Offset get currentCameraNeutralFootAnchor => _footAnchor.translate(
      _cameraNeutralPosition.dx, _cameraNeutralPosition.dy);

  Offset currentCameraNeutralImpactAnchorToward({
    required Offset opponentCenter,
  }) {
    final spriteRect = currentCameraNeutralRenderedSpriteRect;
    final facingSign = opponentCenter.dx >= spriteRect.center.dx ? 1.0 : -1.0;
    return Offset(
      spriteRect.center.dx + (facingSign * spriteRect.width * 0.16),
      spriteRect.top + (spriteRect.height * 0.42),
    );
  }

  @visibleForTesting
  bool get isHitFlashActive => _hitFlashRemaining > 0;

  @visibleForTesting
  Offset get currentVisualOffset => _visualOffset;

  @visibleForTesting
  double get currentVisualOpacity => _visualOpacity;

  @visibleForTesting
  double get currentVisualScaleX => _visualScaleX;

  @visibleForTesting
  double get currentVisualScaleY => _visualScaleY;

  @visibleForTesting
  Color? get currentVisualToneColor => _visualToneColor;

  Offset get _cameraNeutralPosition => Offset(
        _basePosition.x + _visualOffset.dx,
        _basePosition.y + _visualOffset.dy,
      );

  @override
  Future<void> onLoad() async {
    _speciesText = TextComponent(
      text: _speciesLabel,
      position: Vector2(_spriteRect.left + 8, size.y - 4),
      anchor: Anchor.bottomLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFF8FBFF),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
      priority: 13,
    );
    await add(_speciesText!);

    _monogramText = TextComponent(
      text: _speciesMonogram(_speciesLabel),
      position: Vector2(_spriteRect.center.dx, _spriteRect.center.dy),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xF8FFFFFF),
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
      priority: 13,
    );
    await add(_monogramText!);
    await _syncSpriteImage();
  }

  Future<void> sync({
    required String speciesLabel,
    required BattleCombatantSpriteSpec spriteSpec,
  }) async {
    _speciesLabel = speciesLabel;
    _spriteSpec = spriteSpec;
    await _syncSpriteImage();
  }

  /// Repositionne le combattant quand le layout battle est recalculé.
  ///
  /// Ce seam reste strictement visuel :
  /// - aucune donnée métier battle n'est modifiée ;
  /// - on met seulement à jour les bounds calculés par `BattleSceneLayout` ;
  /// - cela permet au runtime de répondre proprement aux resize/orientation
  ///   sans reconstruire tout le combat.
  void updateSceneGeometry({
    required Rect sceneSpriteRect,
    required Rect scenePlatformRect,
    required Offset sceneFootAnchor,
  }) {
    final sceneBounds = _sceneBounds(sceneSpriteRect, scenePlatformRect);
    position = Vector2(sceneBounds.left, sceneBounds.top);
    _basePosition = position.clone();
    size = Vector2(sceneBounds.width, sceneBounds.height);
    _spriteRect = _toLocalRect(sceneSpriteRect, sceneBounds);
    _platformRect = _toLocalRect(scenePlatformRect, sceneBounds);
    _footAnchor = _toLocalOffset(sceneFootAnchor, sceneBounds);
    _speciesText?.position = Vector2(_spriteRect.left + 8, size.y - 4);
    _monogramText?.position =
        Vector2(_spriteRect.center.dx, _spriteRect.center.dy);
    _applyVisualPresentation();
  }

  void triggerHitFlash({
    double duration = 0.24,
  }) {
    _hitFlashRemaining = duration;
  }

  Future<void> playLunge({
    required bool towardOpponent,
    required double distancePx,
    required double durationSeconds,
  }) async {
    _animation = _CombatantPresentationAnimation.lunge;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
    _animationDistancePx = distancePx;
    _animationTowardOpponent = towardOpponent;
  }

  Future<void> playShake({
    required double amplitudePx,
    required double durationSeconds,
  }) async {
    _animation = _CombatantPresentationAnimation.shake;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
    _animationDistancePx = amplitudePx;
  }

  Future<void> playCompress({
    required double scaleX,
    required double scaleY,
    required double durationSeconds,
    int iteration = 1,
  }) async {
    _animation = _CombatantPresentationAnimation.compress;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
    _animationScaleDeltaX = scaleX;
    _animationScaleDeltaY = scaleY;
    _animationIterations = math.max(1, iteration);
  }

  Future<void> playEllipse({
    required double radiusX,
    required double radiusY,
    required int turns,
    required double durationSeconds,
  }) async {
    _animation = _CombatantPresentationAnimation.ellipse;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
    _animationRadiusX = radiusX;
    _animationRadiusY = radiusY;
    _animationTurns = math.max(1, turns);
  }

  Future<void> playTone({
    required Color color,
    required double durationSeconds,
  }) async {
    _visualToneColor = color;
    _visualToneStrength = 1;
    _toneElapsed = 0;
    _toneDuration = durationSeconds;
  }

  Future<void> playFastDash({
    required bool towardOpponent,
    required double distancePx,
    required double durationSeconds,
  }) async {
    _animation = _CombatantPresentationAnimation.fastDash;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
    _animationDistancePx = distancePx;
    _animationTowardOpponent = towardOpponent;
  }

  Future<void> playSwitchOut({
    required double durationSeconds,
  }) async {
    _animation = _CombatantPresentationAnimation.switchOut;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
    _animationDistancePx = 46;
  }

  Future<void> playSwitchIn({
    required double durationSeconds,
  }) async {
    _visualOffset = _switchTravelOffset(progress: 1);
    _visualOpacity = 0;
    _applyVisualPresentation();
    _animation = _CombatantPresentationAnimation.switchIn;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
    _animationDistancePx = 46;
  }

  Future<void> playFaint({
    required double durationSeconds,
  }) async {
    _animation = _CombatantPresentationAnimation.faint;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
    _animationDistancePx = 36;
  }

  void snapToBattlePose() {
    _animation = _CombatantPresentationAnimation.none;
    _animationElapsed = 0;
    _animationDuration = 0;
    _visualOffset = Offset.zero;
    _visualOpacity = 1;
    _visualScaleX = 1;
    _visualScaleY = 1;
    _visualToneColor = null;
    _visualToneStrength = 0;
    _toneElapsed = 0;
    _toneDuration = 0;
    _applyVisualPresentation();
  }

  void applyRmxpTransform({
    required Offset offset,
    required double scale,
  }) {
    _animation = _CombatantPresentationAnimation.none;
    _animationElapsed = 0;
    _visualOffset = offset;
    _visualScaleX = scale;
    _visualScaleY = scale;
    _visualOpacity = 1;
    _applyVisualPresentation();
  }

  void clearRmxpTransform() {
    _visualOffset = Offset.zero;
    _visualScaleX = 1;
    _visualScaleY = 1;
    _applyVisualPresentation();
  }

  void applyBattleCameraTransform({
    required Vector2 offset,
    required double scale,
  }) {
    _sceneCameraOffset = offset.clone();
    _sceneCameraScale = scale;
    _applyVisualPresentation();
  }

  void setRmxpHidden(bool hidden) {
    _visualOpacity = hidden ? 0 : 1;
    _applyVisualPresentation();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hitFlashRemaining > 0) {
      _hitFlashRemaining = (_hitFlashRemaining - dt).clamp(0, double.infinity);
    }
    _updateTone(dt);
    _updateAnimation(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawOval(
      _platformRect,
      Paint()
        ..color = _applyOpacity(
          isPlayerSide ? const Color(0x4431261A) : const Color(0x8B5E4E34),
        ),
    );
    canvas.drawOval(
      _platformRect.deflate(isPlayerSide ? 4 : 5),
      Paint()
        ..color = _applyOpacity(
          isPlayerSide ? const Color(0x7A8E7B61) : const Color(0xFFD8C59E),
        ),
    );

    final shadowRect = Rect.fromCenter(
      center: Offset(
        _platformRect.center.dx,
        _platformRect.center.dy - (_platformRect.height * 0.75),
      ),
      width: _platformRect.width * (isPlayerSide ? 0.6 : 0.48),
      height: _platformRect.height * 1.25,
    );
    canvas.drawOval(
      shadowRect,
      Paint()..color = _applyOpacity(const Color(0x33000000)),
    );

    final auraRect = Rect.fromCenter(
      center: Offset(
        _spriteRect.center.dx,
        _spriteRect.center.dy -
            (_spriteRect.height * (isPlayerSide ? 0.02 : 0.04)),
      ),
      width: _spriteRect.width * (isPlayerSide ? 0.78 : 0.72),
      height: _spriteRect.height * 0.6,
    );
    canvas.drawOval(
      auraRect,
      Paint()
        ..shader = RadialGradient(
          colors: isPlayerSide
              ? <Color>[
                  _applyOpacity(const Color(0x667AA9F4)),
                  _applyOpacity(const Color(0x00000000)),
                ]
              : <Color>[
                  _applyOpacity(const Color(0x66B9D27A)),
                  _applyOpacity(const Color(0x00000000)),
                ],
        ).createShader(auraRect),
    );

    if (_spriteImage != null) {
      _renderDashTrail(canvas);
      _renderSprite(canvas);
      return;
    }

    _renderSilhouette(canvas);
  }

  Future<void> _syncSpriteImage() async {
    final explicitImagePath = _spriteSpec.explicitImageAbsolutePath?.trim();
    _pendingSpriteSourcePath = explicitImagePath;
    if (explicitImagePath == null || explicitImagePath.isEmpty) {
      _spriteImage = null;
      _spriteOpaqueSourceRect = null;
      _spriteSourcePath = null;
      _didSpriteLoadFail = false;
      _syncTextVisibility();
      return;
    }
    if (_spriteImage != null && _spriteSourcePath == explicitImagePath) {
      _syncTextVisibility();
      return;
    }

    try {
      final image = visualAssetCache == null
          ? await loadImageFromFilePath(explicitImagePath)
          : await visualAssetCache!.loadImage(explicitImagePath);
      if (_pendingSpriteSourcePath != explicitImagePath) {
        return;
      }
      _spriteImage = image;
      _spriteOpaqueSourceRect = visualAssetCache == null
          ? await _computeOpaqueSourceRect(image)
          : await visualAssetCache!.loadOpaqueSourceRect(
              explicitImagePath,
              image: image,
            );
      _spriteSourcePath = explicitImagePath;
      _didSpriteLoadFail = false;
      _syncTextVisibility();
    } catch (_) {
      if (_pendingSpriteSourcePath != explicitImagePath) {
        return;
      }
      _spriteImage = null;
      _spriteOpaqueSourceRect = null;
      _spriteSourcePath = explicitImagePath;
      _didSpriteLoadFail = true;
      _syncTextVisibility();
    }
  }

  void _renderSprite(Canvas canvas) {
    final image = _spriteImage!;
    final inputSubrect = _currentSpriteInputSubrect();
    final outputSubrect = _computeRenderedSpriteRect(
      destinationSize: _currentRenderedSpriteDestinationSize(),
    );
    canvas.drawImageRect(image, inputSubrect, outputSubrect, _spritePaint());
  }

  void _renderDashTrail(Canvas canvas) {
    if (_animation != _CombatantPresentationAnimation.fastDash ||
        _spriteImage == null) {
      return;
    }
    final progress = (_animationElapsed /
            (_animationDuration <= 0 ? 0.0001 : _animationDuration))
        .clamp(0.0, 1.0);
    if (progress <= 0 || progress >= 0.75) {
      return;
    }
    final baseRect = _computeRenderedSpriteRect();
    final direction = _signedAnimationDistance().sign;
    final trailOpacity = (0.26 * (1 - progress)).clamp(0.0, 0.26);
    if (trailOpacity <= 0) {
      return;
    }
    _drawSpriteRect(
      canvas,
      outputSubrect: baseRect.shift(Offset(-direction * 14, 0)),
      opacity: trailOpacity,
    );
    _drawSpriteRect(
      canvas,
      outputSubrect: baseRect.shift(Offset(-direction * 28, 0)),
      opacity: trailOpacity * 0.58,
    );
  }

  void _drawSpriteRect(
    Canvas canvas, {
    required Rect outputSubrect,
    required double opacity,
  }) {
    final image = _spriteImage!;
    final inputSubrect = _spriteOpaqueSourceRect ??
        (Offset.zero &
            Size(
              image.width.toDouble(),
              image.height.toDouble(),
            ));
    canvas.drawImageRect(
      image,
      inputSubrect,
      outputSubrect,
      _spritePaint(opacityOverride: opacity),
    );
  }

  void _renderSilhouette(Canvas canvas) {
    final primaryColor = _flashAdjustedColor(
      isPlayerSide ? const Color(0xFF3E4B7E) : const Color(0xFF6B87B7),
    );
    final secondaryColor = _flashAdjustedColor(
      isPlayerSide ? const Color(0xFF7DB4F7) : const Color(0xFFD7E8FF),
    );

    final spriteRect = _computeRenderedSpriteRect(
      destinationSize: _fallbackDestinationSize(),
    );
    final bodyRect = Rect.fromCenter(
      center: Offset(
        spriteRect.left + (spriteRect.width * (isPlayerSide ? 0.42 : 0.6)),
        spriteRect.top + (spriteRect.height * (isPlayerSide ? 0.46 : 0.44)),
      ),
      width: spriteRect.width * (isPlayerSide ? 0.42 : 0.28),
      height: spriteRect.height * (isPlayerSide ? 0.48 : 0.36),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, const Radius.circular(34)),
      Paint()..color = primaryColor,
    );

    final chestRect = Rect.fromCenter(
      center: Offset(
        spriteRect.left + (spriteRect.width * (isPlayerSide ? 0.44 : 0.62)),
        spriteRect.top + (spriteRect.height * (isPlayerSide ? 0.48 : 0.46)),
      ),
      width: bodyRect.width * 0.72,
      height: bodyRect.height * 0.68,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chestRect, const Radius.circular(28)),
      Paint()..color = _applyOpacity(secondaryColor.withValues(alpha: 0.88)),
    );

    final headRect = Rect.fromCircle(
      center: Offset(
        spriteRect.left + (spriteRect.width * (isPlayerSide ? 0.36 : 0.56)),
        spriteRect.top + (spriteRect.height * (isPlayerSide ? 0.21 : 0.23)),
      ),
      radius: isPlayerSide ? spriteRect.width * 0.11 : spriteRect.width * 0.085,
    );
    canvas.drawOval(
      headRect,
      Paint()..color = secondaryColor,
    );

    final accentPath = Path();
    if (isPlayerSide) {
      accentPath
        ..moveTo(
          spriteRect.left + (spriteRect.width * 0.3),
          spriteRect.top + (spriteRect.height * 0.44),
        )
        ..lineTo(
          spriteRect.left + (spriteRect.width * 0.14),
          spriteRect.top + (spriteRect.height * 0.3),
        )
        ..lineTo(
          spriteRect.left + (spriteRect.width * 0.2),
          spriteRect.top + (spriteRect.height * 0.58),
        )
        ..close();
    } else {
      accentPath
        ..moveTo(
          spriteRect.left + (spriteRect.width * 0.6),
          spriteRect.top + (spriteRect.height * 0.34),
        )
        ..lineTo(
          spriteRect.left + (spriteRect.width * 0.8),
          spriteRect.top + (spriteRect.height * 0.2),
        )
        ..lineTo(
          spriteRect.left + (spriteRect.width * 0.74),
          spriteRect.top + (spriteRect.height * 0.5),
        )
        ..close();
    }
    canvas.drawPath(accentPath,
        Paint()..color = _applyOpacity(primaryColor.withValues(alpha: 0.92)));
  }

  void _syncTextVisibility() {
    final showFallbackText = _spriteImage == null;
    _speciesText?.text = showFallbackText ? _speciesLabel : '';
    _monogramText?.text =
        showFallbackText ? _speciesMonogram(_speciesLabel) : '';
  }

  String _speciesMonogram(String speciesLabel) {
    final trimmed = speciesLabel.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.substring(0, 1).toUpperCase();
  }

  Rect _computeRenderedSpriteRect({
    Size? destinationSize,
  }) {
    final targetSize = destinationSize ?? _fallbackDestinationSize();
    final scaledTargetSize = Size(
      targetSize.width * math.max(0.05, _visualScaleX),
      targetSize.height * math.max(0.05, _visualScaleY),
    );
    return _renderedSpriteRectFor(
      spriteRect: _spriteRect,
      footAnchor: _footAnchor,
      footXRatio: _spriteFootXRatio,
      destinationSize: scaledTargetSize,
    );
  }

  Size _fallbackDestinationSize() {
    final sourceSize =
        isPlayerSide ? const Size(172, 172) : const Size(132, 132);
    return applyBoxFit(BoxFit.contain, sourceSize, _spriteRect.size)
        .destination;
  }

  Rect _currentRenderedSpriteRectLocal() {
    return _computeRenderedSpriteRect(
      destinationSize: _currentRenderedSpriteDestinationSize(),
    );
  }

  Size _currentRenderedSpriteDestinationSize() {
    final image = _spriteImage;
    if (image == null) {
      return _fallbackDestinationSize();
    }
    final inputSubrect = _currentSpriteInputSubrect();
    return applyBoxFit(BoxFit.contain, inputSubrect.size, _spriteRect.size)
        .destination;
  }

  Rect _currentSpriteInputSubrect() {
    final image = _spriteImage;
    if (image == null) {
      return Offset.zero & _fallbackDestinationSize();
    }
    return _spriteOpaqueSourceRect ??
        (Offset.zero &
            Size(
              image.width.toDouble(),
              image.height.toDouble(),
            ));
  }

  Paint _spritePaint({
    double? opacityOverride,
  }) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    final opacity = (opacityOverride ?? _visualOpacity).clamp(0.0, 1.0);
    final modulationColor = _spriteModulationColor(opacity);
    if (modulationColor == const Color(0xFFFFFFFF)) {
      return paint;
    }
    paint.colorFilter = ColorFilter.mode(
      modulationColor,
      BlendMode.modulate,
    );
    return paint;
  }

  Color _flashAdjustedColor(Color color) {
    final toneAdjustedColor = _toneAdjustedColor(color);
    final adjustedColor = !_shouldRenderFlashTint
        ? toneAdjustedColor
        : (Color.lerp(toneAdjustedColor, const Color(0xFFF7FBFF), 0.45) ??
            toneAdjustedColor);
    if (_visualOpacity >= 0.999) {
      return adjustedColor;
    }
    return _applyOpacity(adjustedColor);
  }

  Color _spriteModulationColor(double opacity) {
    var color = const Color(0xFFFFFFFF);
    if (_visualToneColor != null && _visualToneStrength > 0) {
      color = Color.lerp(
            color,
            _visualToneColor,
            _visualToneStrength.clamp(0.0, 1.0),
          ) ??
          color;
    }
    if (_shouldRenderFlashTint) {
      color = Color.lerp(color, const Color(0xFFFFFFFF), 0.45) ?? color;
    }
    return color.withValues(alpha: color.a * opacity);
  }

  Color _toneAdjustedColor(Color color) {
    if (_visualToneColor == null || _visualToneStrength <= 0) {
      return color;
    }
    return Color.lerp(
          color,
          _visualToneColor,
          0.35 * _visualToneStrength.clamp(0.0, 1.0),
        ) ??
        color;
  }

  bool get _shouldRenderFlashTint {
    if (_hitFlashRemaining <= 0) {
      return false;
    }
    return ((_hitFlashRemaining * 18).floor() % 2) == 0;
  }

  void _updateTone(double dt) {
    if (_visualToneColor == null) {
      return;
    }
    _toneElapsed += dt;
    final duration = _toneDuration <= 0 ? 0.0001 : _toneDuration;
    final progress = (_toneElapsed / duration).clamp(0.0, 1.0);
    _visualToneStrength = 1 - progress;
    if (progress >= 1) {
      _visualToneColor = null;
      _visualToneStrength = 0;
    }
    _updateTextOpacity();
  }

  void _updateAnimation(double dt) {
    if (_animation == _CombatantPresentationAnimation.none) {
      return;
    }
    _animationElapsed += dt;
    final duration = _animationDuration <= 0 ? 0.0001 : _animationDuration;
    final progress = (_animationElapsed / duration).clamp(0.0, 1.0);

    switch (_animation) {
      case _CombatantPresentationAnimation.none:
        return;
      case _CombatantPresentationAnimation.lunge:
        final signedDistance = _animationDistancePx *
            (_animationTowardOpponent ? 1 : -1) *
            (isPlayerSide ? 1 : -1);
        final eased = math.sin(math.pi * progress);
        _visualOffset = Offset(
          signedDistance * eased,
          (isPlayerSide ? -1 : 1) * (_animationDistancePx * 0.16) * eased,
        );
        _visualOpacity = 1;
      case _CombatantPresentationAnimation.fastDash:
        final signedDistance = _signedAnimationDistance();
        final verticalLift = (isPlayerSide ? -1 : 1) *
            (_animationDistancePx * 0.08) *
            math.sin(progress * math.pi);
        if (progress < 0.55) {
          final phase = progress / 0.55;
          _visualOffset = Offset(signedDistance * phase, verticalLift);
          _visualOpacity = 1 - (phase * 0.55);
        } else if (progress < 0.75) {
          final phase = (progress - 0.55) / 0.20;
          _visualOffset = Offset(
            signedDistance * (1 + (phase * 0.16)),
            verticalLift * 0.5,
          );
          _visualOpacity = 0.45 * (1 - phase);
        } else if (progress < 0.82) {
          _visualOffset = Offset(-signedDistance * 0.42, 0);
          _visualOpacity = 0;
        } else {
          final phase = (progress - 0.82) / 0.18;
          _visualOffset = Offset((-signedDistance * 0.42) * (1 - phase), 0);
          _visualOpacity = phase;
        }
      case _CombatantPresentationAnimation.shake:
        final shake = math.sin(progress * math.pi * 6) * _animationDistancePx;
        _visualOffset = Offset(shake, 0);
        _visualOpacity = 1;
      case _CombatantPresentationAnimation.switchOut:
        _visualOffset = _switchTravelOffset(progress: progress);
        _visualOpacity = 1 - progress;
      case _CombatantPresentationAnimation.switchIn:
        _visualOffset = _switchTravelOffset(progress: 1 - progress);
        _visualOpacity = progress;
      case _CombatantPresentationAnimation.faint:
        _visualOffset = Offset(0, _animationDistancePx * progress);
        _visualOpacity = 1 - progress;
      case _CombatantPresentationAnimation.compress:
        final oscillation =
            math.sin(progress * math.pi * _animationIterations).abs();
        _visualScaleX = 1 + (_animationScaleDeltaX * oscillation);
        _visualScaleY = 1 + (_animationScaleDeltaY * oscillation);
        _visualOpacity = 1;
      case _CombatantPresentationAnimation.ellipse:
        final angle = progress * math.pi * 2 * _animationTurns;
        _visualOffset = Offset(
          math.sin(angle) * _animationRadiusX * (isPlayerSide ? 1 : -1),
          math.sin(angle * 0.5) * _animationRadiusY,
        );
        _visualOpacity = 1;
    }
    _applyVisualPresentation();
    if (progress < 1) {
      return;
    }

    switch (_animation) {
      case _CombatantPresentationAnimation.none:
        return;
      case _CombatantPresentationAnimation.lunge:
      case _CombatantPresentationAnimation.fastDash:
      case _CombatantPresentationAnimation.shake:
      case _CombatantPresentationAnimation.switchIn:
        _visualOffset = Offset.zero;
        _visualOpacity = 1;
        _visualScaleX = 1;
        _visualScaleY = 1;
      case _CombatantPresentationAnimation.switchOut:
        _visualOffset = _switchTravelOffset(progress: 1);
        _visualOpacity = 0;
      case _CombatantPresentationAnimation.faint:
        _visualOffset = Offset(0, _animationDistancePx);
        _visualOpacity = 0;
      case _CombatantPresentationAnimation.compress:
      case _CombatantPresentationAnimation.ellipse:
        _visualOffset = Offset.zero;
        _visualOpacity = 1;
        _visualScaleX = 1;
        _visualScaleY = 1;
    }

    _animation = _CombatantPresentationAnimation.none;
    _applyVisualPresentation();
  }

  Offset _switchTravelOffset({
    required double progress,
  }) {
    final horizontalDirection = isPlayerSide ? -1.0 : 1.0;
    final verticalDirection = isPlayerSide ? 1.0 : -1.0;
    return Offset(
      _animationDistancePx * horizontalDirection * progress,
      (_animationDistancePx * 0.36) * verticalDirection * progress,
    );
  }

  double _signedAnimationDistance() {
    return _animationDistancePx *
        (_animationTowardOpponent ? 1 : -1) *
        (isPlayerSide ? 1 : -1);
  }

  void _applyVisualPresentation() {
    position = Vector2(
      _basePosition.x + _visualOffset.dx + _sceneCameraOffset.x,
      _basePosition.y + _visualOffset.dy + _sceneCameraOffset.y,
    );
    scale = Vector2.all(_sceneCameraScale);
    _updateTextOpacity();
  }

  void _updateTextOpacity() {
    final speciesText = _speciesText;
    if (speciesText != null) {
      speciesText.textRenderer = TextPaint(
        style: TextStyle(
          color: _applyOpacity(const Color(0xFFF8FBFF)),
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    final monogramText = _monogramText;
    if (monogramText != null) {
      monogramText.textRenderer = TextPaint(
        style: TextStyle(
          color: _applyOpacity(const Color(0xF8FFFFFF)),
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      );
    }
  }

  Color _applyOpacity(Color color) {
    return color.withValues(alpha: color.a * _visualOpacity);
  }
}

enum _CombatantPresentationAnimation {
  none,
  lunge,
  fastDash,
  shake,
  switchOut,
  switchIn,
  faint,
  compress,
  ellipse,
}

Rect _renderedSpriteRectFor({
  required Rect spriteRect,
  required Offset footAnchor,
  required double footXRatio,
  required Size destinationSize,
}) {
  return Rect.fromLTWH(
    footAnchor.dx - (destinationSize.width * footXRatio),
    footAnchor.dy - destinationSize.height,
    destinationSize.width,
    destinationSize.height,
  );
}

Rect _sceneBounds(Rect sceneSpriteRect, Rect scenePlatformRect) {
  return sceneSpriteRect.expandToInclude(scenePlatformRect).inflate(12);
}

Rect _toLocalRect(Rect sceneRect, Rect boundsRect) {
  return sceneRect.shift(-boundsRect.topLeft);
}

Offset _toLocalOffset(Offset sceneOffset, Rect boundsRect) {
  return sceneOffset - boundsRect.topLeft;
}

Future<Rect?> _computeOpaqueSourceRect(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    return null;
  }
  final rgba = byteData.buffer.asUint8List();
  final width = image.width;
  final height = image.height;
  var minX = width;
  var minY = height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final alpha = rgba[((y * width) + x) * 4 + 3];
      if (alpha == 0) {
        continue;
      }
      if (x < minX) {
        minX = x;
      }
      if (x > maxX) {
        maxX = x;
      }
      if (y < minY) {
        minY = y;
      }
      if (y > maxY) {
        maxY = y;
      }
    }
  }
  if (maxX < minX || maxY < minY) {
    return null;
  }
  return Rect.fromLTRB(
    minX.toDouble(),
    minY.toDouble(),
    (maxX + 1).toDouble(),
    (maxY + 1).toDouble(),
  );
}
