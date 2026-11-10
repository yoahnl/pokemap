import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:avelune_gen5_sprite_native/avelune_gen5_sprite_native.dart';
import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_gif_animation.dart';
import '../../infrastructure/runtime_gif_atlas.dart';
import '../../infrastructure/tile_image_loader.dart';
import 'battle_pokemon_sprite_resolver.dart';
import 'battle_gen5_mosaic.dart';
import 'battle_camera_subject_geometry.dart';
import 'battle_visual_asset_cache.dart';

const _gen5SceneScaleReference = 68.0;
const _battleSpriteDisplayScale = 1.08;

class BattleSceneCombatantComponent extends PositionComponent {
  BattleSceneCombatantComponent({
    required Rect sceneSpriteRect,
    required Rect scenePlatformRect,
    required Offset sceneFootAnchor,
    required double spriteFootXRatio,
    required this.isPlayerSide,
    required String speciesLabel,
    this.visualAssetCache,
    RuntimeResourceBudget? resourceBudget,
    BattleCombatantSpriteSpec initialSpriteSpec =
        const BattleCombatantSpriteSpec(
      facing: BattleCombatantSpriteFacing.front,
    ),
  })  : _resourceBudget = resourceBudget ??
            visualAssetCache?.resourceBudget ??
            RuntimeResourceBudget(),
        _ownsResourceBudget = resourceBudget == null && visualAssetCache == null,
        _speciesLabel = speciesLabel,
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
  RuntimeResourceBudget _resourceBudget;
  final bool _ownsResourceBudget;

  String _speciesLabel;
  BattleCombatantSpriteSpec _spriteSpec;
  Rect _spriteRect;
  Rect _platformRect;
  Offset _footAnchor;
  final double _spriteFootXRatio;
  ui.Image? _spriteImage;
  ui.Image? _ownedStaticSpriteImage;
  Rect? _spriteOpaqueSourceRect;
  String? _spriteSourcePath;
  (String?, String?, String?, bool?)? _loadedSpritePaths;
  (String?, String?, String?, bool?)? _pendingSpritePaths;
  Future<void>? _pendingSpriteLoad;
  bool Function()? _pendingSpriteIsCurrent;
  int _spriteGeneration = 0;
  bool _spriteClosed = false;
  bool _spriteMounted = false;
  RuntimeGifAnimation? _gifAnimation;
  RuntimeGifAtlas? _gifAtlas;
  double _gifElapsedSeconds = 0;
  Gen5NativeSprite? _gen5Sprite;
  ui.Image? _ownedGen5Image;
  Rect? _gen5ReferenceRect;
  RuntimeResourceReservation? _gen5Reservation;
  (String, bool)? _failedGen5Source;
  double _gen5ElapsedSeconds = 0;
  int _gen5RenderedTick = 0;
  bool _gen5FramePending = false;
  bool _didSpriteLoadFail = false;
  double _hitFlashRemaining = 0;
  double _hitFlashIntensity = 1;
  TextComponent? _speciesText;
  TextComponent? _monogramText;
  Vector2 _basePosition = Vector2.zero();
  final Vector2 _sceneCameraOffset = Vector2.zero();
  double _sceneCameraScale = 1.0;
  bool _rmxpTransformApplied = false;
  Object? _rmxpTransformOwner;
  Object? _rmxpVisibilityOwner;
  final Set<Object> _battleSpriteAnimationPauseOwners = Set.identity();
  int _battleSpriteAnimationPauseEpoch = 0;

  @visibleForTesting
  bool get debugBattleSpriteAnimationPaused => _battleSpriteAnimationPauseOwners.isNotEmpty;

  Rect get currentEffectAttachmentSpriteRect {
    if (!_rmxpTransformApplied || _animation != _CombatantPresentationAnimation.none) {
      return currentRenderedSpriteRect;
    }
    final local = _spriteRectForSize(_currentRenderedSpriteDestinationSize());
    final origin = Offset(_basePosition.x + _idleLateralOffset, _basePosition.y);
    return Rect.fromLTRB(
      (origin.dx + local.left) * _sceneCameraScale + _sceneCameraOffset.x,
      (origin.dy + local.top) * _sceneCameraScale + _sceneCameraOffset.y,
      (origin.dx + local.right) * _sceneCameraScale + _sceneCameraOffset.x,
      (origin.dy + local.bottom) * _sceneCameraScale + _sceneCameraOffset.y);
  }

  Offset get currentEffectAttachmentFootAnchor =>
      !_rmxpTransformApplied || _animation != _CombatantPresentationAnimation.none
      ? currentFootAnchor : Offset(
        (_basePosition.x + _idleLateralOffset + _footAnchor.dx) * _sceneCameraScale + _sceneCameraOffset.x,
        (_basePosition.y + _footAnchor.dy) * _sceneCameraScale + _sceneCameraOffset.y);

  /// Dernière opacité (quantifiée 0-255) appliquée aux TextPaint : réassigner
  /// `textRenderer` invalide le cache texte de Flame, donc on ne le fait que
  /// quand l'opacité visible a réellement changé.
  int? _lastTextOpacityQuantized;
  Paint? _auraPaint;
  Rect? _auraPaintRect;
  int? _auraPaintAlpha;
  Offset _visualOffset = Offset.zero;
  double _visualOpacity = 1.0;
  double _visualScaleX = 1.0;
  double _visualScaleY = 1.0;
  double _visualRotation = 0.0;
  Color? _visualToneColor;
  double _visualToneStrength = 0;
  double _effectIntensity = 1;

  void setEffectIntensity(double intensity) {
    _effectIntensity = intensity.isFinite ? intensity.clamp(0, 1) : 0;
    setHitFlashIntensity(_effectIntensity);
  }

  double get _toneIntensity => _visualToneMaxMix == 1 ? 1 : _effectIntensity;

  /// Le mélange MAXIMAL de la teinte — BETA-BAT-031.
  ///
  /// 0,35 pour les teintes d'état (poison, brûlure) : elles colorent sans
  /// masquer le sprite. 1,0 pour une SILHOUETTE — l'entrée en ombre du
  /// sauvage et la matérialisation dans la Ball, où l'on ne doit justement
  /// plus reconnaître le Pokémon.
  double _visualToneMaxMix = 0.35;
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

  Offset get currentFootAnchor => Offset(
    position.x + _footAnchor.dx * _sceneCameraScale,
    position.y + _footAnchor.dy * _sceneCameraScale,
  );

  Rect get currentRenderedSpriteRect =>
      _projectLocalRect(_currentRenderedSpriteRectLocal());

  ui.Image? get stageImage => _gifAnimation == null ? _spriteImage : null;
  bool get hasBattleSpriteImage => _spriteImage != null;
  Rect get stageSourceRect => _currentSpriteInputSubrect();
  Color get stageTint => _spriteModulationColor(_visualOpacity);
  final Set<Object> _battleScriptShadowOwners = {};
  Object? _battleScriptGroundClipOwner;

  double? get cameraNeutralBattleGroundClipY =>
      _battleScriptGroundClipOwner != null && _visualOffset.dy > 0
          ? _basePosition.y + _footAnchor.dy : null;

  void setBattleScriptGroundClip(bool enabled, {required Object owner}) {
    if (enabled) {
      _battleScriptGroundClipOwner = owner;
    } else if (identical(_battleScriptGroundClipOwner, owner)) {
      _battleScriptGroundClipOwner = null;
    }
  }

  final Set<Object> _battleScriptHiddenOwners = {};
  Object? _battleScriptAlphaOwner;
  int _battleScriptAlphaLevel = 31;
  Object? _battleScriptMosaicOwner;
  int _battleScriptMosaicLevel = 0;
  Object? _battleScriptPaletteOwner;
  double _battleScriptPaletteAmount = 0;
  Color _battleScriptPaletteColor = const Color(0xFFFFFFFF);

  bool get hasBattleScriptPalette => _battleScriptPaletteAmount > 0;
  bool get hasBattleScriptRotation => _visualRotation != 0;
  bool get isHiddenForBattleScript =>
      _battleScriptHiddenOwners.isNotEmpty || _visualOpacity <= 0;
  double get _battleScriptOpacity =>
      _battleScriptHiddenOwners.isEmpty
          ? _visualOpacity * _battleScriptAlphaLevel / 31
          : 0;
  Color get stageShadowTint => _battleScriptShadowOwners.isEmpty
      ? _applyOpacity(const Color(0x26000000))
      : const Color(0x00000000);

  void setBattleScriptShadowHidden(bool hidden, {required Object owner}) {
    if (hidden) {
      _battleScriptShadowOwners.add(owner);
    } else {
      _battleScriptShadowOwners.remove(owner);
    }
  }

  void setBattleScriptHidden(bool hidden, {required Object owner}) {
    final wasHidden = _battleScriptHiddenOwners.isNotEmpty;
    if (hidden) {
      _battleScriptHiddenOwners.add(owner);
    } else {
      _battleScriptHiddenOwners.remove(owner);
    }
    if (wasHidden != _battleScriptHiddenOwners.isNotEmpty) {
      _updateTextOpacity();
    }
  }

  void setBattleScriptAlpha(int level, {required Object owner}) {
    if (level < 0 || level > 31 ||
        (_battleScriptAlphaOwner != null &&
            !identical(_battleScriptAlphaOwner, owner))) {
      throw StateError('Battle alpha is unavailable');
    }
    _battleScriptAlphaOwner = owner;
    _battleScriptAlphaLevel = level;
    _updateTextOpacity();
  }

  void clearBattleScriptAlpha({required Object owner}) {
    if (!identical(_battleScriptAlphaOwner, owner)) return;
    _battleScriptAlphaOwner = null;
    _battleScriptAlphaLevel = 31;
    _updateTextOpacity();
  }

  @visibleForTesting
  int get debugBattleScriptMosaicLevel => _battleScriptMosaicLevel;

  bool get hasBattleScriptMosaic => _battleScriptMosaicOwner != null;

  void setBattleScriptMosaic(int level, {required Object owner}) {
    if (level < 0 || level > 15 ||
        (_battleScriptMosaicOwner != null &&
            !identical(_battleScriptMosaicOwner, owner))) {
      throw StateError('Battle mosaic is unavailable');
    }
    _battleScriptMosaicOwner = owner;
    _battleScriptMosaicLevel = level;
  }

  void clearBattleScriptMosaic({required Object owner}) {
    if (!identical(_battleScriptMosaicOwner, owner)) return;
    _battleScriptMosaicOwner = null;
    _battleScriptMosaicLevel = 0;
  }

  void setBattleScriptPalette({
    required Object owner,
    required int level,
    required Color color,
  }) {
    if (level < 0 || level > 16 ||
        (_battleScriptPaletteOwner != null &&
            !identical(_battleScriptPaletteOwner, owner))) {
      throw StateError('Battle palette is unavailable');
    }
    _battleScriptPaletteOwner = owner;
    _battleScriptPaletteAmount = level / 16;
    _battleScriptPaletteColor = color;
  }

  void clearBattleScriptPalette({required Object owner}) {
    if (!identical(_battleScriptPaletteOwner, owner)) return;
    _battleScriptPaletteOwner = null;
    _battleScriptPaletteAmount = 0;
  }
  Size get stageShadowMaskSize {
    final destination = _currentRenderedSpriteDestinationSize();
    return Size(
      destination.width * .55,
      (destination.height * .045).clamp(2.0, 10.0),
    );
  }

  Rect get currentCameraNeutralShadowRect =>
      _currentShadowRectLocal().shift(_cameraNeutralPosition);

  List<({Rect rect, Color tint})> get currentCameraNeutralDashTrails => [
    for (final trail in _currentDashTrails())
      (
        rect: _imageRectForReference(trail.rect).shift(_cameraNeutralPosition),
        tint: _spriteModulationColor(trail.opacity),
      ),
  ];
  bool renderedBy3DStage = false;
  double _idleLateralOffset = 0;

  void setIdleLateralOffset(double offset) {
    if (_idleLateralOffset == offset) return;
    _idleLateralOffset = offset;
    _applyVisualPresentation();
  }

  Rect _projectLocalRect(Rect rect) => Rect.fromLTWH(
    position.x + rect.left * _sceneCameraScale,
    position.y + rect.top * _sceneCameraScale,
    rect.width * _sceneCameraScale,
    rect.height * _sceneCameraScale,
  );

  BattleCameraSubjectGeometry get stableCameraGeometry {
    final position = Offset(_basePosition.x, _basePosition.y);
    final bounds = _spriteRectForSize(_currentRenderedSpriteDestinationSize())
        .shift(position);
    return BattleCameraSubjectGeometry(
      foot: _footAnchor + position,
      bounds: bounds,
      focusAnchor: Offset(bounds.center.dx, bounds.top + bounds.height * .42),
    );
  }

  Rect get currentCameraNeutralRenderedSpriteRect =>
      _currentRenderedSpriteRectLocal().shift(_cameraNeutralPosition);

  Rect get currentCameraNeutralRenderedImageRect =>
      _imageRectForReference(_currentRenderedSpriteRectLocal())
          .shift(_cameraNeutralPosition);

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
  bool get isHitFlashActive => _hitFlashRemaining > 0 && _hitFlashIntensity > 0;

  @visibleForTesting
  Offset get currentVisualOffset => _visualOffset;

  @visibleForTesting
  double get currentVisualRotation => _visualRotation;

  @visibleForTesting
  double get currentVisualOpacity => _visualOpacity;

  @visibleForTesting
  double get currentVisualScaleX => _visualScaleX;

  @visibleForTesting
  double get currentVisualScaleY => _visualScaleY;

  @visibleForTesting
  Color? get currentVisualToneColor => _visualToneColor;

  Offset get _cameraNeutralPosition => Offset(
        _basePosition.x + _visualOffset.dx + _idleLateralOffset,
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
    add(_speciesText!);

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
    add(_monogramText!);
    await _syncSpriteImage();
  }

  Future<void> sync({
    required String speciesLabel,
    required BattleCombatantSpriteSpec spriteSpec,
  }) async {
    _speciesLabel = speciesLabel;
    _spriteSpec = spriteSpec;
    _syncTextVisibility();
    await _syncSpriteImage();
  }

  @override
  void onMount() {
    super.onMount();
    _spriteMounted = true;
    final wasClosed = _spriteClosed;
    if (wasClosed) {
      _spriteClosed = false;
      if (_ownsResourceBudget) _resourceBudget = RuntimeResourceBudget();
    }
    if (wasClosed || _spriteSpec.gen5Source != null ||
        _spritePath(_spriteSpec.explicitAnimatedImageAbsolutePath) != null) {
      unawaited(_syncSpriteImage());
    }
  }

  @override
  void onRemove() {
    if (!_spriteClosed) {
      _battleSpriteAnimationPauseOwners.clear();
      _spriteClosed = true;
      _spriteGeneration++;
      _loadedSpritePaths = null;
      _pendingSpritePaths = null;
      _pendingSpriteLoad = null;
      _pendingSpriteIsCurrent = null;
      _spriteMounted = false;
      _releaseGen5();
      _releaseGif();
      _spriteImage = null;
      _releaseOwnedStaticSprite();
      _spriteOpaqueSourceRect = null;
      _spriteSourcePath = null;
      if (_ownsResourceBudget) _resourceBudget.dispose();
    }
    super.onRemove();
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
    double intensity = 1,
  }) {
    setHitFlashIntensity(intensity);
    _hitFlashRemaining = duration;
  }

  void setHitFlashIntensity(double intensity) {
    _hitFlashIntensity = intensity.isFinite ? intensity.clamp(0.0, 1.0) : 0;
  }

  void reduceCurrentMotion() {
    _hitFlashRemaining = 0;
    switch (_animation) {
      case _CombatantPresentationAnimation.none:
        _visualOffset = Offset.zero;
        _visualScaleX = 1;
        _visualScaleY = 1;
        _idleLateralOffset = 0;
        _applyVisualPresentation();
      case _CombatantPresentationAnimation.lunge:
      case _CombatantPresentationAnimation.fastDash:
      case _CombatantPresentationAnimation.shake:
      case _CombatantPresentationAnimation.compress:
      case _CombatantPresentationAnimation.ellipse:
        _animation = _CombatantPresentationAnimation.none;
        _visualOpacity = 1;
        _visualOffset = Offset.zero;
        _visualScaleX = 1;
        _visualScaleY = 1;
        _idleLateralOffset = 0;
        _applyVisualPresentation();
      default:
        break;
    }
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
    _visualToneMaxMix = _defaultToneMaxMix;
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

  /// Apparition depuis la Poké Ball — BETA-BAT-022.
  ///
  /// Recette du 2026-08-24 : « l'animation avec les pokéballs continue à
  /// transformer le pokémon en tout petit mais ça reste visible ». Le
  /// `ya.scalar(0.1, self, :zoom=, 0, sprite_zoom)` de PSDK part de zéro,
  /// et une lueur pleine ne sauve pas une forme de quelques pixels : on
  /// reconnaît le Pokémon en miniature. La vidéo de référence (Platine) ne
  /// montre jamais ça — la forme d'énergie apparaît À SA TAILLE et prend ses
  /// couleurs. L'échelle ne descend donc plus sous [_materializeFloorScale] :
  /// l'apparition est portée par l'opacité et la lueur, pas par la taille.
  Future<void> playMaterializeIn({required double durationSeconds}) async {
    _visualScaleX = _materializeFloorScale;
    _visualScaleY = _materializeFloorScale;
    _visualOpacity = 0;
    _visualOffset = Offset.zero;
    _beginMaterializeGlow();
    _applyVisualPresentation();
    _animation = _CombatantPresentationAnimation.materializeIn;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
  }

  /// La lueur de matérialisation — recette du 2026-08-24 : « tu as rendu tout
  /// petit les pokémons ! mais on le voit quand même ».
  ///
  /// Un sprite détaillé réduit à quelques pixels reste un sprite : on
  /// reconnaît le Pokémon en miniature à côté de sa Ball. La référence
  /// (Pokémon Platine, vidéo de recette) ne montre jamais ça — le Pokémon
  /// entre et sort en SILHOUETTE LUMINEUSE, une forme d'énergie qui prend
  /// ses couleurs à la fin. Une teinte pleine masque les détails et donne
  /// exactement cette lecture.
  void _beginMaterializeGlow() {
    _materializeGlowActive = true;
    _visualToneColor = const Color(0xFFFFF4C8);
    _visualToneStrength = 1;
    _visualToneMaxMix = 1;
    _toneElapsed = 0;
    _toneDuration = 0;
  }

  void _clearMaterializeGlow() {
    if (!_materializeGlowActive) return;
    _materializeGlowActive = false;
    _visualToneColor = null;
    _visualToneStrength = 0;
    _visualToneMaxMix = _defaultToneMaxMix;
    _toneElapsed = 0;
    _toneDuration = 0;
  }

  /// Le plancher d'échelle d'une matérialisation : jamais de miniature.
  static const double _materializeFloorScale = 0.88;

  static double _materializeScaleAt(double progress) =>
      _materializeFloorScale +
      ((1 - _materializeFloorScale) * progress.clamp(0.0, 1.0));

  @visibleForTesting
  static double get debugMaterializeFloorScale => _materializeFloorScale;

  /// Vrai pendant une matérialisation (entrée ou sortie de Ball).
  bool _materializeGlowActive = false;

  @visibleForTesting
  bool get debugMaterializeGlowActive => _materializeGlowActive;

  @visibleForTesting
  double get debugVisualToneMaxMix => _visualToneMaxMix;

  /// Retour dans la Poké Ball — la forme se dissout en lumière.
  ///
  /// Même raison que [playMaterializeIn] : un rétrécissement jusqu'à zéro
  /// montre le Pokémon en miniature juste avant qu'il ne disparaisse.
  Future<void> playMaterializeOut({required double durationSeconds}) async {
    _visualOffset = Offset.zero;
    _visualOpacity = 1;
    _visualScaleX = 1;
    _visualScaleY = 1;
    _visualRotation = 0;
    _beginMaterializeGlow();
    _applyVisualPresentation();
    _animation = _CombatantPresentationAnimation.materializeOut;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
  }

  /// Tient le combattant invisible (échelle zéro) avant sa sortie de Ball —
  /// l'équivalent Ball de [holdIntroSlideOffscreen] : aucune image ne doit
  /// le montrer avant l'ouverture.
  void holdMaterializeHidden() {
    _rmxpTransformOwner = null;
    _rmxpVisibilityOwner = null;
    _rmxpTransformApplied = false;
    _animation = _CombatantPresentationAnimation.none;
    // Caché par l'opacité, pas par l'échelle : une échelle nulle qui remonte
    // produit exactement la miniature que la recette du 2026-08-24 a rejetée.
    _visualScaleX = _materializeFloorScale;
    _visualScaleY = _materializeFloorScale;
    _visualOpacity = 0;
    _visualOffset = Offset.zero;
    _applyVisualPresentation();
  }

  /// Pose le combattant hors écran, à sa position de départ d'intro —
  /// BETA-BAT-016. Appelé avant le premier rendu pour qu'aucune image ne le
  /// montre à sa place finale sous le noir de la pré-transition.
  void holdIntroSlideOffscreen({required double distancePx}) {
    _rmxpTransformOwner = null;
    _rmxpVisibilityOwner = null;
    _rmxpTransformApplied = false;
    _animationDistancePx = distancePx;
    _animation = _CombatantPresentationAnimation.none;
    _visualOffset = _introSlideOffset(progress: 1);
    _visualOpacity = 1;
    // BETA-BAT-028 : parité `create_enemy_sprites` — le Pokémon SAUVAGE
    // entre en SILHOUETTE noire (shader `color = [0,0,0,1]`) et ne se révèle
    // qu'à la fin de son glissement. Le joueur n'en a pas : de son côté,
    // c'est son dresseur qui entre.
    if (!isPlayerSide) {
      _introSilhouetteActive = true;
      _visualToneColor = const Color(0xFF000000);
      _visualToneStrength = 1;
      // Parité `color = [0,0,0,1]` : une VRAIE ombre, pas un sprite
      // assombri de 35 %.
      _visualToneMaxMix = 1;
      _toneElapsed = 0;
      _toneDuration = 0;
    }
    _applyVisualPresentation();
  }

  /// Vrai tant que la silhouette d'entrée n'a pas été levée — BETA-BAT-028.
  bool _introSilhouetteActive = false;

  @visibleForTesting
  bool get debugIntroSilhouetteActive => _introSilhouetteActive;

  void _clearIntroSilhouette() {
    if (!_introSilhouetteActive) return;
    _introSilhouetteActive = false;
    _visualToneColor = null;
    _visualToneStrength = 0;
    _visualToneMaxMix = _defaultToneMaxMix;
    _toneElapsed = 0;
    _toneDuration = 0;
  }

  /// Le mélange des teintes d'état : elles colorent sans masquer.
  static const double _defaultToneMaxMix = 0.35;

  /// Glissement d'entrée en combat (parité `create_sprite_move_animation`).
  Future<void> playIntroSlide({
    required double durationSeconds,
    required double distancePx,
  }) async {
    _animationDistancePx = distancePx;
    _visualOffset = _introSlideOffset(progress: 1);
    _visualOpacity = 1;
    _applyVisualPresentation();
    _animation = _CombatantPresentationAnimation.introSlide;
    _animationElapsed = 0;
    _animationDuration = durationSeconds;
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
    _rmxpTransformOwner = null;
    _rmxpVisibilityOwner = null;
    _rmxpTransformApplied = false;
    _battleSpriteAnimationPauseOwners.clear();
    // Une pose de combat nette n'a plus de silhouette d'entrée en attente,
    // ni de lueur de matérialisation.
    _introSilhouetteActive = false;
    _materializeGlowActive = false;
    _visualToneMaxMix = _defaultToneMaxMix;
    _animation = _CombatantPresentationAnimation.none;
    _animationElapsed = 0;
    _animationDuration = 0;
    _visualOffset = Offset.zero;
    _visualOpacity = 1;
    _visualScaleX = 1;
    _visualScaleY = 1;
    _visualRotation = 0;
    _visualToneColor = null;
    _visualToneStrength = 0;
    _toneElapsed = 0;
    _toneDuration = 0;
    _applyVisualPresentation();
  }

  void applyRmxpTransform({
    required Offset offset,
    required double scale,
    Object? owner,
  }) {
    _rmxpTransformOwner = owner;
    _rmxpTransformApplied = true;
    _animation = _CombatantPresentationAnimation.none;
    _animationElapsed = 0;
    _visualOffset = offset;
    _visualScaleX = scale;
    _visualScaleY = scale;
    _visualRotation = 0;
    _visualOpacity = 1;
    _applyVisualPresentation();
  }

  bool applyBattleScriptTransform({
    required Offset offset,
    required double scaleX,
    required double scaleY,
    double rotation = 0,
    required Object owner,
  }) {
    if (!offset.dx.isFinite || !offset.dy.isFinite ||
        !scaleX.isFinite || !scaleY.isFinite || !rotation.isFinite ||
        scaleX <= 0 || scaleX > 8 || scaleY <= 0 || scaleY > 8 ||
        _animation != _CombatantPresentationAnimation.none ||
        (_rmxpTransformApplied && !identical(_rmxpTransformOwner, owner))) {
      return false;
    }
    _rmxpTransformOwner = owner;
    _rmxpTransformApplied = true;
    _visualOffset = offset;
    _visualScaleX = scaleX;
    _visualScaleY = scaleY;
    _visualRotation = rotation;
    _applyVisualPresentation();
    return true;
  }

  void clearBattleScriptTransform({required Object owner}) {
    clearRmxpTransform(owner: owner);
  }

  bool ownsBattleScriptTransform(Object owner) => _rmxpTransformApplied &&
      identical(_rmxpTransformOwner, owner) &&
      _animation == _CombatantPresentationAnimation.none;

  bool ownsBattleSpriteAnimationPause(Object owner) =>
      _battleSpriteAnimationPauseOwners.contains(owner);

  void pauseBattleSpriteAnimation({required Object owner}) {
    if (_battleSpriteAnimationPauseOwners.add(owner)) {
      _battleSpriteAnimationPauseEpoch++;
    }
  }

  void resumeBattleSpriteAnimation({required Object owner}) {
    _battleSpriteAnimationPauseOwners.remove(owner);
  }

  void clearRmxpTransform({Object? owner}) {
    if (owner != null && (!identical(owner, _rmxpTransformOwner) ||
        _animation != _CombatantPresentationAnimation.none)) {
      return;
    }
    _rmxpTransformOwner = null;
    _rmxpTransformApplied = false;
    _visualOffset = Offset.zero;
    _visualScaleX = 1;
    _visualScaleY = 1;
    _visualRotation = 0;
    _applyVisualPresentation();
  }

  void applyBattleCameraTransform({
    required Vector2 offset,
    required double scale,
  }) {
    _sceneCameraOffset.setFrom(offset);
    _sceneCameraScale = scale;
    _applyVisualPresentation();
  }

  void setRmxpHidden(bool hidden, {Object? owner}) {
    if (!hidden && owner != null && (!identical(owner, _rmxpVisibilityOwner) ||
        _animation != _CombatantPresentationAnimation.none)) {
      return;
    }
    _rmxpVisibilityOwner = hidden ? owner : null;
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
    if (_battleSpriteAnimationPauseOwners.isEmpty && dt.isFinite && dt > 0 && _gen5Sprite != null) {
      _gen5ElapsedSeconds += dt;
      final tick = (_gen5ElapsedSeconds * 60).floor();
      if (!_gen5FramePending && tick != _gen5RenderedTick && tick <= 0x7fffffff) {
        unawaited(_updateGen5Frame(tick, _spriteGeneration));
      }
    }
    if (_battleSpriteAnimationPauseOwners.isEmpty && dt.isFinite && dt > 0 && (_gifAtlas != null || _gifAnimation != null)) {
      _gifElapsedSeconds += dt;
      final animation = _gifAnimation;
      if (animation != null) _spriteImage = animation.frameAt(_gifElapsed);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_spriteRect.isEmpty) return;

    if (_spriteImage != null) {
      if (renderedBy3DStage) return;
      if (_battleScriptShadowOwners.isEmpty) {
        canvas.drawOval(
          _currentShadowRectLocal(),
          Paint()
            ..color = _applyOpacity(const Color(0x26000000))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
        );
      }
      _renderDashTrail(canvas);
      final clipGround =
          _battleScriptGroundClipOwner != null && _visualOffset.dy > 0;
      if (clipGround) {
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(
          -100000, -100000, 100000, _footAnchor.dy - _visualOffset.dy,
        ));
      }
      if (_visualRotation == 0) {
        _renderSprite(canvas);
      } else {
        final center = _currentRenderedSpriteRectLocal().center;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_visualRotation);
        canvas.translate(-center.dx, -center.dy);
        _renderSprite(canvas);
        canvas.restore();
      }
      if (clipGround) canvas.restore();
      return;
    }

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

    final auraRect = Rect.fromCenter(
      center: Offset(
        _spriteRect.center.dx,
        _spriteRect.center.dy -
            (_spriteRect.height * (isPlayerSide ? 0.02 : 0.04)),
      ),
      width: _spriteRect.width * (isPlayerSide ? 0.78 : 0.72),
      height: _spriteRect.height * 0.6,
    );
    canvas.drawOval(auraRect, _auraPaintFor(auraRect));

    _renderSilhouette(canvas);
  }

  Duration get _gifElapsed =>
      Duration(microseconds: (_gifElapsedSeconds * 1000000).round());

  String? _spritePath(String? path) {
    final trimmed = path?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _syncSpriteImage() {
    if (_spriteClosed) return Future.value();
    final source = _spriteSpec.gen5Source;
    final paths = (
      _spritePath(_spriteSpec.explicitImageAbsolutePath),
      _spritePath(_spriteSpec.explicitAnimatedImageAbsolutePath),
      source?.speciesId,
      source?.shiny,
    );
    if (_loadedSpritePaths == paths) return Future.value();
    if (_pendingSpritePaths == paths &&
        _pendingSpriteLoad != null &&
        (_pendingSpriteIsCurrent?.call() ?? false)) {
      return _pendingSpriteLoad!;
    }
    final generation = ++_spriteGeneration;
    final loadingParent = parent;
    final loadingGame = findGame();
    bool isCurrent() =>
        !_spriteClosed &&
        _spriteGeneration == generation &&
        !isRemoving &&
        !isRemoved &&
        !(parent?.isRemoving ?? false) &&
        !(parent?.isRemoved ?? false) &&
        identical(parent, loadingParent) &&
        identical(findGame(), loadingGame);
    _pendingSpritePaths = paths;
    _pendingSpriteIsCurrent = isCurrent;
    _loadedSpritePaths = null;
    _releaseGen5();
    _releaseGif();
    final pending = _loadSprite(paths, source, generation, isCurrent);
    _pendingSpriteLoad = pending;
    return pending.whenComplete(() {
      if (_spriteGeneration == generation) {
        _pendingSpritePaths = null;
        _pendingSpriteLoad = null;
        _pendingSpriteIsCurrent = null;
      }
    });
  }

  Future<void> _loadSprite(
    (String?, String?, String?, bool?) paths,
    BattleGen5SpriteSource? source,
    int generation,
    bool Function() isCurrent,
  ) async {
    final staticPath = paths.$1;
    final animatedPath = paths.$2;
    try {
      await _loadStaticSprite(staticPath, isCurrent);
      if (!isCurrent()) return;
      if ((source != null || animatedPath != null) && !_spriteMounted) return;
      if (source != null && _failedGen5Source != (source.speciesId, source.shiny)) {
        if (await _loadGen5(source, isCurrent)) {
          if (isCurrent()) _loadedSpritePaths = paths;
          return;
        }
        if (!isCurrent()) return;
      }
      if (animatedPath != null) {
        RuntimeGifAnimation? animation;
        RuntimeGifAtlas? atlas;
        try {
          animation = await loadRuntimeGifFromFilePath(
            animatedPath,
            resourceBudget: _resourceBudget,
            isCurrent: isCurrent,
          );
          atlas = await buildRuntimeGifAtlas(animation, isCurrent: isCurrent);
          if (!isCurrent()) return;
          _gifElapsedSeconds = 0;
          if (atlas == null) {
            _gifAnimation = animation;
            _spriteImage = animation.frameByIndex(0);
            animation = null;
          } else {
            _gifAtlas = atlas;
            _spriteImage = atlas.image;
            atlas = null;
          }
          _releaseOwnedStaticSprite();
          _spriteOpaqueSourceRect = null;
          _spriteSourcePath = animatedPath;
          _didSpriteLoadFail = false;
          _syncTextVisibility();
        } catch (_) {
          if (!isCurrent()) return;
          if (_spriteImage == null) _didSpriteLoadFail = true;
        } finally {
          atlas?.dispose();
          animation?.dispose();
        }
      }
      if (isCurrent() &&
          (_spriteImage != null ||
              (staticPath == null && animatedPath == null))) {
        _loadedSpritePaths = paths;
      }
    } finally {
      if (_spriteGeneration == generation && !isCurrent()) {
        _releaseGen5();
        _releaseGif();
        _spriteImage = null;
        _releaseOwnedStaticSprite();
        _spriteOpaqueSourceRect = null;
        _spriteSourcePath = null;
      }
    }
  }

  Future<bool> _loadGen5(
    BattleGen5SpriteSource source,
    bool Function() isCurrent,
  ) async {
    Gen5NativeSprite? sprite;
    RuntimeResourceReservation? reservation;
    ui.Image? frame;
    try {
      final bundle = await source.load(isCurrent: isCurrent);
      if (bundle == null || !isCurrent()) return false;
      final bytes = bundle.assets.values.fold<int>(0, (sum, value) => sum + value.length);
      if (bytes > 2 * 1024 * 1024) return false;
      reservation = await _resourceBudget.acquire(
        residentBytes: bytes * 2 + 6 * 1024 * 1024,
        transientBytes: bytes * 2 + 2 * 1024 * 1024,
        isCurrent: isCurrent,
      );
      sprite = Gen5NativeSprite(
        assets: bundle.assets,
        side: isPlayerSide ? Gen5SpriteSide.back : Gen5SpriteSide.front,
        shiny: source.shiny,
        normalizeFiveBitPalette: true,
      );
      final rgba = sprite.renderRgba(0);
      final referenceRect = _opaqueSourceRect(
        rgba, Gen5NativeSprite.canvasWidth, Gen5NativeSprite.canvasHeight,
      );
      if (referenceRect == null) return false;
      frame = await _gen5Image(rgba);
      reservation.ensureCurrent();
      reservation.commit();
      _gen5Sprite = sprite;
      _gen5Reservation = reservation;
      _ownedGen5Image = frame;
      _gen5ReferenceRect = referenceRect;
      _spriteImage = frame;
      _spriteOpaqueSourceRect = null;
      _spriteSourcePath = 'gen5:${source.speciesId}';
      _gen5ElapsedSeconds = 0;
      _gen5RenderedTick = 0;
      _didSpriteLoadFail = false;
      _releaseOwnedStaticSprite();
      _syncTextVisibility();
      sprite = null;
      reservation = null;
      frame = null;
      return true;
    } catch (error) {
      if (isCurrent()) debugPrint('Gen 5 sprite unavailable: $error');
      return false;
    } finally {
      frame?.dispose();
      sprite?.dispose();
      reservation?.release();
    }
  }

  Future<void> _updateGen5Frame(int tick, int generation) async {
    final sprite = _gen5Sprite;
    if (sprite == null) return;
    final pauseEpoch = _battleSpriteAnimationPauseEpoch;
    _gen5FramePending = true;
    ui.Image? frame;
    try {
      frame = await _gen5Image(sprite.renderRgba(tick));
      if (_spriteClosed || generation != _spriteGeneration || !identical(sprite, _gen5Sprite) ||
          pauseEpoch != _battleSpriteAnimationPauseEpoch || _battleSpriteAnimationPauseOwners.isNotEmpty) return;
      final previous = _ownedGen5Image;
      _ownedGen5Image = frame;
      _spriteImage = frame;
      _gen5RenderedTick = tick;
      frame = null;
      previous?.dispose();
    } catch (error) {
      if (!_spriteClosed && generation == _spriteGeneration && identical(sprite, _gen5Sprite)) {
        debugPrint('Gen 5 sprite playback failed: $error');
        final source = _spriteSpec.gen5Source;
        if (source != null) _failedGen5Source = (source.speciesId, source.shiny);
        _loadedSpritePaths = null;
        unawaited(_syncSpriteImage());
      }
    } finally {
      frame?.dispose();
      _gen5FramePending = false;
    }
  }

  Future<ui.Image> _gen5Image(Uint8List rgba) {
    final result = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba, Gen5NativeSprite.canvasWidth, Gen5NativeSprite.canvasHeight,
      ui.PixelFormat.rgba8888, result.complete,
    );
    return result.future;
  }

  void _releaseGen5() {
    final image = _ownedGen5Image;
    if (identical(_spriteImage, image)) _spriteImage = null;
    _ownedGen5Image = null;
    _gen5ReferenceRect = null;
    image?.dispose();
    _gen5Sprite?.dispose();
    _gen5Sprite = null;
    _gen5Reservation?.release();
    _gen5Reservation = null;
    _gen5ElapsedSeconds = 0;
    _gen5RenderedTick = 0;
  }

  Future<void> _loadStaticSprite(
    String? explicitImagePath,
    bool Function() isCurrent,
  ) async {
    if (explicitImagePath == null) {
      _spriteImage = null;
      _releaseOwnedStaticSprite();
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

    ui.Image? image;
    try {
      image = visualAssetCache == null
          ? await loadImageFromFilePath(explicitImagePath)
          : await visualAssetCache!.loadImage(explicitImagePath);
      if (!isCurrent()) return;
      final opaqueRect = visualAssetCache == null
          ? await _computeOpaqueSourceRect(image)
          : await visualAssetCache!.loadOpaqueSourceRect(
              explicitImagePath,
              image: image,
            );
      if (!isCurrent()) return;
      _spriteImage = image;
      _releaseOwnedStaticSprite();
      if (visualAssetCache == null) _ownedStaticSpriteImage = image;
      _spriteOpaqueSourceRect = opaqueRect;
      _spriteSourcePath = explicitImagePath;
      _didSpriteLoadFail = false;
      _syncTextVisibility();
      image = null;
    } catch (_) {
      if (!isCurrent()) return;
      _spriteImage = null;
      _releaseOwnedStaticSprite();
      _spriteOpaqueSourceRect = null;
      _spriteSourcePath = explicitImagePath;
      _didSpriteLoadFail = true;
      _syncTextVisibility();
    } finally {
      if (visualAssetCache == null) image?.dispose();
    }
  }

  void _releaseOwnedStaticSprite() {
    final image = _ownedStaticSpriteImage;
    _ownedStaticSpriteImage = null;
    image?.dispose();
  }

  void _releaseGif() {
    final atlas = _gifAtlas;
    final animation = _gifAnimation;
    _gifAtlas = null;
    _gifAnimation = null;
    _gifElapsedSeconds = 0;
    if (atlas != null || animation != null) {
      _spriteImage = null;
      _spriteOpaqueSourceRect = null;
      _spriteSourcePath = null;
    }
    atlas?.dispose();
    animation?.dispose();
  }

  void _renderSprite(Canvas canvas) {
    final image = _spriteImage!;
    final inputSubrect = _currentSpriteInputSubrect();
    final outputSubrect = _imageRectForReference(
      _computeRenderedSpriteRect(
        destinationSize: _currentRenderedSpriteDestinationSize(),
      ),
    );
    drawBattleGen5Mosaic(canvas, image, inputSubrect, outputSubrect,
        _spritePaint(), _battleScriptMosaicLevel);
  }

  void _renderDashTrail(Canvas canvas) {
    for (final trail in _currentDashTrails()) {
      _drawSpriteRect(canvas, outputSubrect: trail.rect, opacity: trail.opacity);
    }
  }

  Rect _currentShadowRectLocal() {
    final rendered = _currentRenderedSpriteRectLocal();
    return Rect.fromCenter(
      center: _footAnchor + const Offset(0, 2),
      width: rendered.width * .55,
      height: (rendered.height * .045).clamp(2.0, 10.0),
    );
  }

  List<({Rect rect, double opacity})> _currentDashTrails() {
    if (_animation != _CombatantPresentationAnimation.fastDash ||
        _spriteImage == null) {
      return const [];
    }
    final progress = (_animationElapsed /
            (_animationDuration <= 0 ? 0.0001 : _animationDuration))
        .clamp(0.0, 1.0);
    if (progress <= 0 || progress >= 0.75) {
      return const [];
    }
    final baseRect = _computeRenderedSpriteRect();
    final direction = _signedAnimationDistance().sign;
    final trailOpacity = (0.26 * (1 - progress)).clamp(0.0, 0.26);
    if (trailOpacity <= 0) {
      return const [];
    }
    return [
      (
        rect: baseRect.shift(Offset(-direction * 14, 0)),
        opacity: trailOpacity,
      ),
      (
        rect: baseRect.shift(Offset(-direction * 28, 0)),
        opacity: trailOpacity * 0.58,
      ),
    ];
  }

  void _drawSpriteRect(
    Canvas canvas, {
    required Rect outputSubrect,
    required double opacity,
  }) {
    final image = _spriteImage!;
    final inputSubrect = _currentSpriteInputSubrect();
    canvas.drawImageRect(
      image,
      inputSubrect,
      _imageRectForReference(outputSubrect),
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
    return _spriteRectForSize(scaledTargetSize);
  }

  Rect _spriteRectForSize(Size destinationSize) {
    final reference = _gen5ReferenceRect;
    if (reference != null) {
      final scaleX = destinationSize.width / reference.width;
      final scaleY = destinationSize.height / reference.height;
      return Rect.fromLTWH(
        _footAnchor.dx + (reference.left - Gen5NativeSprite.canvasWidth / 2) * scaleX,
        _footAnchor.dy + (reference.top - Gen5NativeSprite.canvasHeight / 2) * scaleY,
        destinationSize.width,
        destinationSize.height,
      );
    }
    return _renderedSpriteRectFor(
      spriteRect: _spriteRect,
      footAnchor: _footAnchor,
      footXRatio: _spriteFootXRatio,
      destinationSize: destinationSize,
    );
  }

  Size _fallbackDestinationSize() {
    final sourceSize =
        isPlayerSide ? const Size(172, 172) : const Size(132, 132);
    final fitted = applyBoxFit(BoxFit.contain, sourceSize, _spriteRect.size);
    return fitted.destination * _battleSpriteDisplayScale;
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
    final reference = _gen5ReferenceRect;
    if (reference != null) {
      final scale = _spriteRect.shortestSide /
          _gen5SceneScaleReference *
          _battleSpriteDisplayScale;
      return Size(reference.width * scale, reference.height * scale);
    }
    final inputSubrect = _currentSpriteInputSubrect();
    final fitted = applyBoxFit(BoxFit.contain, inputSubrect.size, _spriteRect.size);
    return fitted.destination * _battleSpriteDisplayScale;
  }

  Rect _imageRectForReference(Rect visibleRect) {
    final reference = _gen5ReferenceRect;
    final image = _spriteImage;
    if (reference == null || image == null) return visibleRect;
    return gen5SpriteCanvasRectForReference(
      visibleRect,
      reference,
      Size(image.width.toDouble(), image.height.toDouble()),
    );
  }

  Rect _currentSpriteInputSubrect() {
    final atlas = _gifAtlas;
    if (atlas != null) return atlas.sourceAt(_gifElapsed);
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
    if (_battleScriptPaletteAmount > 0) {
      final amount = _battleScriptPaletteAmount;
      final remaining = 1 - amount;
      final color = _battleScriptPaletteColor;
      paint.colorFilter = ColorFilter.matrix([
        modulationColor.r * remaining, 0, 0, 0, color.r * 255 * amount,
        0, modulationColor.g * remaining, 0, 0, color.g * 255 * amount,
        0, 0, modulationColor.b * remaining, 0, color.b * 255 * amount,
        0, 0, 0, modulationColor.a, 0,
      ]);
      return paint;
    }
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
        : (Color.lerp(toneAdjustedColor, const Color(0xFFF7FBFF), 0.45 * _hitFlashIntensity) ??
            toneAdjustedColor);
    if (_battleScriptOpacity >= 0.999) {
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
            _visualToneStrength.clamp(0.0, 1.0) * _toneIntensity,
          ) ??
          color;
    }
    if (_shouldRenderFlashTint) {
      color = Color.lerp(color, const Color(0xFFFFFFFF), 0.45 * _hitFlashIntensity) ?? color;
    }
    return color.withValues(
      alpha: color.a * (_battleScriptHiddenOwners.isEmpty
          ? opacity * _battleScriptAlphaLevel / 31 : 0),
    );
  }

  Color _toneAdjustedColor(Color color) {
    if (_visualToneColor == null || _visualToneStrength <= 0) {
      return color;
    }
    return Color.lerp(
          color,
          _visualToneColor,
          _visualToneMaxMix * _visualToneStrength.clamp(0.0, 1.0) * _toneIntensity,
        ) ??
        color;
  }

  bool get _shouldRenderFlashTint {
    if (_hitFlashRemaining <= 0 || _hitFlashIntensity <= 0) {
      return false;
    }
    // BETA-BAT-013 : un basculement toutes les 0,1 s, donc un cycle complet de
    // 0,2 s. Sur la fenêtre de 0,6 s de la référence cela donne exactement 3
    // flashs. Le multiplicateur valait 18, soit 9 cycles par seconde, et une
    // fenêtre de 0,6 s aurait produit 5,4 flashs.
    return ((_hitFlashRemaining * 10).floor() % 2) == 0;
  }

  void _updateTone(double dt) {
    if (_visualToneColor == null) {
      return;
    }
    // La silhouette d'entrée TIENT jusqu'à sa levée explicite : la laisser
    // décroître donnerait un fondu, là où la référence révèle d'un coup.
    if (_introSilhouetteActive || _materializeGlowActive) return;
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
      case _CombatantPresentationAnimation.introSlide:
        _visualOffset = _introSlideOffset(progress: 1 - progress);
        _visualOpacity = 1;
      case _CombatantPresentationAnimation.materializeIn:
        _visualScaleX = _materializeScaleAt(progress);
        _visualScaleY = _visualScaleX;
        // L'opacité fait tout le travail d'apparition, sur le premier tiers.
        _visualOpacity = (progress * 3).clamp(0.0, 1.0);
      case _CombatantPresentationAnimation.materializeOut:
        _visualScaleX = _materializeScaleAt(1 - progress);
        _visualScaleY = _visualScaleX;
        _visualOpacity = (1 - progress).clamp(0.0, 1.0);
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

    // Parité `enemy_discover_animations` : la révélation tombe à la fin du
    // mouvement d'entrée, d'un coup.
    if (_animation == _CombatantPresentationAnimation.introSlide) {
      _clearIntroSilhouette();
    }
    // Le Pokémon SORTI de sa Ball reprend ses couleurs ; celui qui vient d'y
    // rentrer n'a plus rien à montrer (échelle nulle), donc la lueur peut
    // partir aussi.
    if (_animation == _CombatantPresentationAnimation.materializeIn ||
        _animation == _CombatantPresentationAnimation.materializeOut) {
      _clearMaterializeGlow();
    }

    switch (_animation) {
      case _CombatantPresentationAnimation.none:
        return;
      case _CombatantPresentationAnimation.lunge:
      case _CombatantPresentationAnimation.fastDash:
      case _CombatantPresentationAnimation.shake:
      case _CombatantPresentationAnimation.switchIn:
      case _CombatantPresentationAnimation.introSlide:
      case _CombatantPresentationAnimation.materializeIn:
        _visualOffset = Offset.zero;
        _visualOpacity = 1;
        _visualScaleX = 1;
        _visualScaleY = 1;
      case _CombatantPresentationAnimation.materializeOut:
        _visualScaleX = 1;
        _visualScaleY = 1;
        _visualOpacity = 0;
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

  /// Le départ du glissement d'intro : l'ennemi vient de la gauche, le
  /// joueur de la droite — la parité RBY où `enemy.x -= 360` et
  /// `actor.x += 360` avant que tout le monde glisse vers sa place.
  Offset _introSlideOffset({required double progress}) {
    final horizontalDirection = isPlayerSide ? 1.0 : -1.0;
    return Offset(_animationDistancePx * horizontalDirection * progress, 0);
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
    // Appelé à chaque frame d'animation et de caméra : mutation in place,
    // aucune allocation de Vector2.
    position.setValues(
      (_basePosition.x + _visualOffset.dx + _idleLateralOffset) * _sceneCameraScale + _sceneCameraOffset.x,
      (_basePosition.y + _visualOffset.dy) * _sceneCameraScale + _sceneCameraOffset.y,
    );
    scale.setValues(_sceneCameraScale, _sceneCameraScale);
    _updateTextOpacity();
  }

  void _updateTextOpacity() {
    final quantized = (_battleScriptOpacity.clamp(0.0, 1.0) * 255).round();
    if (quantized == _lastTextOpacityQuantized) {
      return;
    }
    _lastTextOpacityQuantized = quantized;
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
    return color.withValues(alpha: color.a * _battleScriptOpacity);
  }

  /// Le shader d'aura ne dépend que du rect du sprite, du côté et de
  /// l'opacité visible : reconstruit uniquement quand l'un d'eux change au
  /// lieu d'un `createShader` par combattant par frame.
  Paint _auraPaintFor(Rect auraRect) {
    final alpha = (_battleScriptOpacity.clamp(0.0, 1.0) * 255).round();
    final cached = _auraPaint;
    if (cached != null &&
        _auraPaintRect == auraRect &&
        _auraPaintAlpha == alpha) {
      return cached;
    }
    final paint = Paint()
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
      ).createShader(auraRect);
    _auraPaint = paint;
    _auraPaintRect = auraRect;
    _auraPaintAlpha = alpha;
    return paint;
  }
}

enum _CombatantPresentationAnimation {
  none,
  lunge,
  fastDash,
  shake,
  switchOut,
  switchIn,
  introSlide,
  materializeIn,
  materializeOut,
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
  return _opaqueSourceRect(
    byteData.buffer.asUint8List(),
    image.width,
    image.height,
  );
}

Rect? _opaqueSourceRect(Uint8List rgba, int width, int height) {
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

@visibleForTesting
Rect gen5SpriteCanvasRectForReference(
  Rect visibleRect,
  Rect referenceRect,
  Size canvasSize,
) {
  final scaleX = visibleRect.width / referenceRect.width;
  final scaleY = visibleRect.height / referenceRect.height;
  return Rect.fromLTWH(
    visibleRect.left - referenceRect.left * scaleX,
    visibleRect.top - referenceRect.top * scaleY,
    canvasSize.width * scaleX,
    canvasSize.height * scaleY,
  );
}
