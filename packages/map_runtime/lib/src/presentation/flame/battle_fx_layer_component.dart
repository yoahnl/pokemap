import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:map_battle/map_battle.dart';

import 'battle_animation_plan.dart';
import 'battle_fx_bundle_cache.dart';
import 'battle_fx_catalog.dart';
import 'battle_fx_sprite_component.dart';
import 'battle_fx_sprite_sheet_component.dart';
import 'battle_rmxp_animation_component.dart';
import 'battle_sdk_particle_component.dart';
import 'battle_sdk_rmxp_animation_catalog.dart';

typedef BattleVisualAnchorResolver = Vector2 Function({
  required BattleVisualAnchor anchor,
  required BattleSideId attackerSide,
  required BattleSideId defenderSide,
});

final class BattleFxRuntimeContext {
  const BattleFxRuntimeContext({
    required this.sceneSize,
    required this.resolveAnchor,
    this.stageRect,
  });

  final Vector2 sceneSize;
  final Rect? stageRect;
  final BattleVisualAnchorResolver resolveAnchor;
}

final class BattleFxLayerComponent extends PositionComponent {
  BattleFxLayerComponent({
    required Vector2 size,
    required this.fxBundleCache,
  }) : super(
          size: size,
          anchor: Anchor.topLeft,
          priority: 18,
        );

  final BattleFxBundleCache fxBundleCache;
  _BattleWeatherAmbientComponent? _weatherAmbient;
  _BattlePseudoWeatherAmbientComponent? _pseudoWeatherAmbient;

  int get activeFxCount => children
      .whereType<BattleFxSpriteComponent>()
      .where((component) => !component.isAnimationComplete)
      .length;

  int get activeSpriteSheetFxCount => children
      .whereType<BattleFxSpriteSheetComponent>()
      .where((component) => !component.isAnimationComplete)
      .length;

  int get activeRmxpFxCount => children
      .whereType<BattleRmxpAnimationComponent>()
      .where((component) => !component.isAnimationComplete)
      .length;

  int get activeSdkParticleCount => children
      .whereType<BattleSdkParticleComponent>()
      .where((component) => !component.isAnimationComplete)
      .length;

  @visibleForTesting
  int get activeScreenFlashCount => children
      .whereType<_BattleScreenFlashComponent>()
      .where((component) => !component.isExpired)
      .length;

  @visibleForTesting
  int get activeBarrierCount => children
      .whereType<_BattleBarrierPulseComponent>()
      .where((component) => !component.isExpired)
      .length;

  bool get hasWeatherAmbient => _weatherAmbient?.parent == this;

  bool get hasPseudoWeatherAmbient => _pseudoWeatherAmbient?.parent == this;

  @override
  void update(double dt) {
    super.update(dt);
    if (_weatherAmbient != null) {
      _weatherAmbient!.size = size.clone();
    }
    if (_pseudoWeatherAmbient != null) {
      _pseudoWeatherAmbient!.size = size.clone();
    }
    for (final component
        in children.whereType<BattleFxSpriteComponent>().toList()) {
      if (component.isAnimationComplete) {
        component.removeFromParent();
      }
    }
    for (final component
        in children.whereType<BattleFxSpriteSheetComponent>().toList()) {
      if (component.isAnimationComplete) {
        component.removeFromParent();
      }
    }
    for (final component
        in children.whereType<BattleRmxpAnimationComponent>().toList()) {
      if (component.isAnimationComplete) {
        component.removeFromParent();
      }
    }
    for (final component
        in children.whereType<BattleSdkParticleComponent>().toList()) {
      if (component.isAnimationComplete) {
        component.removeFromParent();
      }
    }
    for (final component
        in children.whereType<_BattleScreenFlashComponent>().toList()) {
      if (component.isExpired) {
        component.removeFromParent();
      }
    }
    for (final component
        in children.whereType<_BattleBarrierPulseComponent>().toList()) {
      if (component.isExpired) {
        component.removeFromParent();
      }
    }
  }

  void syncFieldAmbient({
    required BattleWeatherId? weather,
    required BattlePseudoWeatherId? pseudoWeather,
  }) {
    _syncWeatherAmbient(weather);
    _syncPseudoWeatherAmbient(pseudoWeather);
  }

  Future<void> playFx(
    SpawnFxStep step,
    BattleFxRuntimeContext ctx,
  ) async {
    final sprite = await fxBundleCache.loadSprite(step.effectId);
    final startPosition = ctx
        .resolveAnchor(
          anchor: step.from,
          attackerSide: step.attackerSide,
          defenderSide: step.defenderSide,
        )
        .clone()
      ..add(Vector2(step.fromOffsetX, step.fromOffsetY));
    final endPosition = ctx
        .resolveAnchor(
          anchor: step.to,
          attackerSide: step.attackerSide,
          defenderSide: step.defenderSide,
        )
        .clone()
      ..add(Vector2(step.toOffsetX, step.toOffsetY));
    final component = BattleFxSpriteComponent(
      sprite: sprite,
      startPosition: startPosition,
      endPosition: endPosition,
      durationSeconds: step.durationSeconds,
      startDelaySeconds: step.startDelaySeconds,
      curve: step.curve,
      afterEffect: step.afterEffect,
      startScale: step.startScale,
      endScale: step.endScale,
      startOpacity: step.startOpacity,
      endOpacity: step.endOpacity,
    );
    await add(component);
  }

  Future<void> playSpriteSheetFx(
    PlaySpriteSheetFxStep step,
    BattleFxRuntimeContext ctx,
  ) async {
    final spec = BattleFxCatalog.require(step.assetId);
    final image = await fxBundleCache.loadImage(step.assetId);
    final anchorPosition = ctx
        .resolveAnchor(
          anchor: step.anchor,
          attackerSide: step.attackerSide,
          defenderSide: step.defenderSide,
        )
        .clone()
      ..add(Vector2(step.offsetX, step.offsetY));
    await add(
      BattleFxSpriteSheetComponent(
        image: image,
        anchorPosition: anchorPosition,
        frameWidth: step.frameWidth,
        frameHeight: step.frameHeight,
        frameCount: step.frameCount,
        frameDurationSeconds: step.frameDurationSeconds,
        columns: step.columns ?? spec.columns,
        originX: step.originX ?? spec.originX,
        originY: step.originY ?? spec.originY,
        displayScale: step.scale * spec.defaultScale,
        opacity: step.opacity,
        startDelaySeconds: step.startDelaySeconds,
        frameSequence: step.frameSequence,
        frameDurationsSeconds: step.frameDurationsSeconds,
      ),
    );
  }

  Future<void> playSpriteSheetOnCombatant(
    SpriteSheetOnCombatantStep step,
    BattleFxRuntimeContext ctx,
  ) async {
    final attackerSide = step.attackerSide ?? step.side;
    final defenderSide = step.defenderSide ??
        (step.side == BattleSideId.player
            ? BattleSideId.enemy
            : BattleSideId.player);
    final anchor = step.side == attackerSide
        ? BattleVisualAnchor.attackerCenter
        : BattleVisualAnchor.defenderCenter;
    await playSpriteSheetFx(
      PlaySpriteSheetFxStep(
        assetId: step.assetId,
        attackerSide: attackerSide,
        defenderSide: defenderSide,
        anchor: anchor,
        frameWidth: step.frameWidth,
        frameHeight: step.frameHeight,
        frameCount: step.frameCount,
        frameDurationSeconds: step.frameDurationSeconds,
        columns: step.columns,
        originX: step.originX,
        originY: step.originY,
        scale: step.scale,
        opacity: step.opacity,
        offsetX: step.offsetX,
        offsetY: step.offsetY,
        startDelaySeconds: step.startDelaySeconds,
        frameSequence: step.frameSequence,
        frameDurationsSeconds: step.frameDurationsSeconds,
      ),
      ctx,
    );
  }

  Future<void> playParticleBurst(
    ParticleBurstStep step,
    BattleFxRuntimeContext ctx,
  ) async {
    final sprite = await fxBundleCache.loadSprite(step.assetId);
    final anchorSide = step.side == BattleSideId.player
        ? BattleSideId.player
        : BattleSideId.enemy;
    final center = ctx
        .resolveAnchor(
          anchor: step.anchor,
          attackerSide: anchorSide,
          defenderSide: anchorSide,
        )
        .clone();
    final count = step.particleCount.clamp(0, 160);
    for (var i = 0; i < count; i++) {
      final radius = step.radiusPx * (0.45 + ((i % 5) * 0.14));
      final endPosition = center.clone()
        ..add(Vector2(
          radius * ui.lerpDouble(1, -1, i.isEven ? 0 : 1)! * (i % 3 + 1) / 3,
          radius * (i % 2 == 0 ? -0.55 : 0.55),
        ))
        ..add(Vector2(radius * 0.22 * i / (count == 0 ? 1 : count), 0));
      final startPosition = center.clone()
        ..add(Vector2(
          step.radiusPx * 0.18 * (i % 3 - 1),
          step.radiusPx * 0.12 * (i % 5 - 2),
        ));
      await add(
        BattleFxSpriteComponent(
          sprite: sprite,
          startPosition: startPosition,
          endPosition: endPosition,
          durationSeconds: step.durationSeconds,
          startDelaySeconds: step.startDelaySeconds + (i * 0.015),
          curve: BattleFxMotionCurve.easeOut,
          afterEffect: BattleFxAfterEffect.fade,
          startScale: step.startScale,
          endScale: step.endScale,
          startOpacity: step.startOpacity,
          endOpacity: step.endOpacity,
          tintColor: step.colorArgb == null ? null : Color(step.colorArgb!),
        ),
      );
    }
  }

  Future<void> playSdkParticleSequence(
    PlaySdkParticleSequenceStep step,
    BattleFxRuntimeContext ctx,
  ) async {
    for (final particle in step.particles) {
      final sprite = await fxBundleCache.loadSprite(particle.assetId);
      final anchorPosition = ctx
          .resolveAnchor(
            anchor: particle.anchor,
            attackerSide: step.attackerSide,
            defenderSide: step.defenderSide,
          )
          .clone();
      await add(
        BattleSdkParticleComponent(
          sprite: sprite,
          startPosition: anchorPosition.clone()
            ..add(Vector2(particle.startOffsetX, particle.startOffsetY)),
          endPosition: anchorPosition.clone()
            ..add(Vector2(particle.endOffsetX, particle.endOffsetY)),
          startScaleX: particle.startScaleX,
          startScaleY: particle.startScaleY,
          endScaleX: particle.endScaleX,
          endScaleY: particle.endScaleY,
          startOpacity: particle.startOpacity,
          endOpacity: particle.endOpacity,
          delaySeconds: particle.delaySeconds,
          durationSeconds: particle.durationSeconds,
          rotationTurns: particle.rotationTurns,
          tintColor:
              particle.colorArgb == null ? null : Color(particle.colorArgb!),
        ),
      );
    }
  }

  Future<void> playSdkFallingParticles(
    SdkFallingParticlesStep step,
    BattleFxRuntimeContext ctx,
  ) async {
    final sprite = await fxBundleCache.loadSprite(step.assetId);
    final anchorPosition = ctx.resolveAnchor(
      anchor: step.anchor,
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    final count = step.particleCount.clamp(0, 160);
    for (var i = 0; i < count; i++) {
      final spreadProgress = count <= 1 ? 0.5 : i / (count - 1);
      final startX = (spreadProgress - 0.5) * step.startAreaWidth;
      final driftDirection = i.isEven ? -1.0 : 1.0;
      final drift = driftDirection * step.driftX * (0.35 + spreadProgress);
      await add(
        BattleSdkParticleComponent(
          sprite: sprite,
          startPosition: anchorPosition.clone()
            ..add(Vector2(startX, step.startOffsetY - (i % 3) * 4)),
          endPosition: anchorPosition.clone()
            ..add(Vector2(
                startX + drift, step.startOffsetY + step.fallDistanceY)),
          startScaleX: step.startScaleX,
          startScaleY: step.startScaleY,
          endScaleX: step.endScaleX,
          endScaleY: step.endScaleY,
          startOpacity: step.startOpacity,
          endOpacity: step.endOpacity,
          delaySeconds: i * step.intervalSeconds,
          durationSeconds: step.durationSeconds,
          rotationTurns: (i.isEven ? -0.18 : 0.18) * (1 + (i % 3)),
          tintColor: step.colorArgb == null ? null : Color(step.colorArgb!),
        ),
      );
    }
  }

  Future<void> playSdkRadiusParticles(
    SdkRadiusParticleStep step,
    BattleFxRuntimeContext ctx,
  ) async {
    final sprite = await fxBundleCache.loadSprite(step.assetId);
    final anchorPosition = ctx.resolveAnchor(
      anchor: step.anchor,
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    final count = step.particleCount.clamp(0, 160);
    for (var i = 0; i < count; i++) {
      final angleTurns = step.startAngleTurns + (i / math.max(1, count));
      final angleRadians = angleTurns * math.pi * 2;
      final startOffset = Vector2(
        math.cos(angleRadians) * step.startRadiusPx,
        math.sin(angleRadians) * step.startRadiusPx,
      );
      final endOffset = Vector2(
        math.cos(angleRadians) * step.endRadiusPx,
        math.sin(angleRadians) * step.endRadiusPx,
      );
      await add(
        BattleSdkParticleComponent(
          sprite: sprite,
          startPosition: anchorPosition.clone()..add(startOffset),
          endPosition: anchorPosition.clone()..add(endOffset),
          startScaleX: step.startScale,
          startScaleY: step.startScale,
          endScaleX: step.endScale,
          endScaleY: step.endScale,
          startOpacity: step.startOpacity,
          endOpacity: step.endOpacity,
          delaySeconds: i * step.intervalSeconds,
          durationSeconds: step.durationSeconds,
          rotationTurns: 0.2 + (i * 0.03),
          tintColor: step.colorArgb == null ? null : Color(step.colorArgb!),
        ),
      );
    }
  }

  Future<void> playSdkScalarParticle(
    SdkScalarParticleStep step,
    BattleFxRuntimeContext ctx,
  ) async {
    final sprite = await fxBundleCache.loadSprite(step.assetId);
    final anchorPosition = ctx.resolveAnchor(
      anchor: step.anchor,
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    await add(
      BattleSdkParticleComponent(
        sprite: sprite,
        startPosition: anchorPosition.clone()
          ..add(Vector2(step.offsetX, step.offsetY)),
        endPosition: anchorPosition.clone()
          ..add(Vector2(step.endOffsetX, step.endOffsetY)),
        startScaleX: step.startScaleX,
        startScaleY: step.startScaleY,
        endScaleX: step.endScaleX,
        endScaleY: step.endScaleY,
        startOpacity: step.startOpacity,
        endOpacity: step.endOpacity,
        delaySeconds: step.delaySeconds,
        durationSeconds: step.durationSeconds,
        rotationTurns: step.rotationTurns,
        tintColor: step.colorArgb == null ? null : Color(step.colorArgb!),
      ),
    );
  }

  Future<void> playSdkParticleZoom(
    SdkParticleZoomStep step,
    BattleFxRuntimeContext ctx,
  ) async {
    final sprite = await fxBundleCache.loadSprite(step.assetId);
    final anchorPosition = ctx.resolveAnchor(
      anchor: step.anchor,
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    await add(
      BattleSdkParticleComponent(
        sprite: sprite,
        startPosition: anchorPosition.clone()
          ..add(Vector2(step.offsetX, step.offsetY)),
        endPosition: anchorPosition.clone()
          ..add(Vector2(step.offsetX, step.offsetY)),
        startScaleX: step.startScale,
        startScaleY: step.startScale,
        endScaleX: step.endScale,
        endScaleY: step.endScale,
        startOpacity: step.startOpacity,
        endOpacity: step.endOpacity,
        delaySeconds: step.delaySeconds,
        durationSeconds: step.durationSeconds,
        rotationTurns: step.rotationTurns,
        tintColor: step.colorArgb == null ? null : Color(step.colorArgb!),
      ),
    );
  }

  Future<void> playRmxpAnimation(
    PlayRmxpAnimationStep step,
    BattleFxRuntimeContext ctx, {
    RmxpCombatantTransformCallback? onCombatantTransform,
    RmxpVoidCallback? onCombatantTransformCleared,
    RmxpFlashCallback? onPokemonFlash,
    RmxpFlashCallback? onSceneFlash,
    RmxpVisibilityCallback? onVisibilityChanged,
  }) async {
    final animation = BattleSdkRmxpAnimationCatalog.require(step.animationId);
    final image = await fxBundleCache.loadImage(animation.assetId);
    final subjectAnchor = step.subjectSide == step.attackerSide
        ? BattleVisualAnchor.attackerBody
        : BattleVisualAnchor.defenderImpact;
    final anchorPosition = ctx.resolveAnchor(
      anchor: subjectAnchor,
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    final placementAnchorPosition = ctx.resolveAnchor(
      anchor: step.placementSpec.anchor ??
          _defaultAnchorForRmxpPlacement(step, subjectAnchor),
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    final projectileSourceAnchorPosition = ctx.resolveAnchor(
      anchor:
          step.placementSpec.sourceAnchor ?? BattleVisualAnchor.attackerMouth,
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    final projectileTargetAnchorPosition = ctx.resolveAnchor(
      anchor:
          step.placementSpec.targetAnchor ?? BattleVisualAnchor.defenderImpact,
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    final attackerAnchorPosition = ctx.resolveAnchor(
      anchor: BattleVisualAnchor.attackerCenter,
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    final defenderAnchorPosition = ctx.resolveAnchor(
      anchor: BattleVisualAnchor.defenderCenter,
      attackerSide: step.attackerSide,
      defenderSide: step.defenderSide,
    );
    await add(
      BattleRmxpAnimationComponent(
        image: image,
        animation: animation,
        sourceAnchorPosition: anchorPosition,
        placementSpec: step.placementSpec,
        placementAnchorPosition: placementAnchorPosition,
        attackerAnchorPosition: attackerAnchorPosition,
        defenderAnchorPosition: defenderAnchorPosition,
        projectileSourceAnchorPosition: projectileSourceAnchorPosition,
        projectileTargetAnchorPosition: projectileTargetAnchorPosition,
        stageRect: ctx.stageRect,
        sceneSize: ctx.sceneSize.clone(),
        reverse: step.reverse && !animation.forceNoReverse,
        onCombatantTransform: onCombatantTransform,
        onCombatantTransformCleared: onCombatantTransformCleared,
        onPokemonFlash: onPokemonFlash,
        onSceneFlash: onSceneFlash,
        onVisibilityChanged: onVisibilityChanged,
      ),
    );
  }

  BattleVisualAnchor _defaultAnchorForRmxpPlacement(
    PlayRmxpAnimationStep step,
    BattleVisualAnchor subjectAnchor,
  ) {
    return switch (step.placementSpec.policy) {
      RmxpPlacementPolicy.targetImpact => BattleVisualAnchor.defenderImpact,
      RmxpPlacementPolicy.attackerCast => BattleVisualAnchor.attackerBody,
      RmxpPlacementPolicy.projectileLine => BattleVisualAnchor.attackerMouth,
      RmxpPlacementPolicy.sdkStage ||
      RmxpPlacementPolicy.screenGlobal =>
        BattleVisualAnchor.stageCenter,
      RmxpPlacementPolicy.subjectAttached => subjectAnchor,
    };
  }

  Future<void> playWeatherParticles(WeatherParticleStep step) async {
    final sprite = await fxBundleCache.loadSprite(step.assetId);
    final count = step.particleCount.clamp(0, 240);
    for (var i = 0; i < count; i++) {
      final startX = ((i * 37.0) % (size.x + 80)) - 40;
      final startY = -24.0 - ((i * 19.0) % size.y);
      await add(
        BattleFxSpriteComponent(
          sprite: sprite,
          startPosition: Vector2(startX, startY),
          endPosition: Vector2(startX + 80, size.y + 48),
          durationSeconds: step.durationSeconds,
          startDelaySeconds: i * 0.01,
          curve: BattleFxMotionCurve.linear,
          afterEffect: BattleFxAfterEffect.fade,
          startScale: 1,
          endScale: 1,
          startOpacity: 1,
          endOpacity: 0.2,
        ),
      );
    }
  }

  void playScreenFlash(ScreenFlashStep step) {
    add(
      _BattleScreenFlashComponent(
        size: size.clone(),
        color: Color(step.colorArgb),
        durationSeconds: step.durationSeconds,
      ),
    );
  }

  void playSceneTint(SceneTintStep step) {
    playScreenFlash(
      ScreenFlashStep(
        colorArgb: step.colorArgb,
        durationSeconds: step.durationSeconds,
      ),
    );
  }

  void playBarrierPulse(
    BarrierPulseStep step, {
    required Rect targetRect,
  }) {
    add(
      _BattleBarrierPulseComponent(
        targetRect: targetRect,
        color: Color(step.colorArgb),
        durationSeconds: step.durationSeconds,
        style: step.style,
      ),
    );
  }

  void clearAll() {
    for (final child in List<Component>.from(children)) {
      child.removeFromParent();
    }
    _weatherAmbient = null;
    _pseudoWeatherAmbient = null;
  }

  void _syncWeatherAmbient(BattleWeatherId? weather) {
    final current = _weatherAmbient;
    if (weather == null) {
      current?.removeFromParent();
      _weatherAmbient = null;
      return;
    }
    if (current != null &&
        current.parent == this &&
        current.weather == weather) {
      current.size = size.clone();
      return;
    }
    current?.removeFromParent();
    final next = _BattleWeatherAmbientComponent(
      weather: weather,
      size: size.clone(),
    );
    _weatherAmbient = next;
    add(next);
  }

  void _syncPseudoWeatherAmbient(BattlePseudoWeatherId? pseudoWeather) {
    final current = _pseudoWeatherAmbient;
    if (pseudoWeather == null) {
      current?.removeFromParent();
      _pseudoWeatherAmbient = null;
      return;
    }
    if (current != null &&
        current.parent == this &&
        current.pseudoWeather == pseudoWeather) {
      current.size = size.clone();
      return;
    }
    current?.removeFromParent();
    final next = _BattlePseudoWeatherAmbientComponent(
      pseudoWeather: pseudoWeather,
      size: size.clone(),
    );
    _pseudoWeatherAmbient = next;
    add(next);
  }
}

final class _BattleScreenFlashComponent extends PositionComponent {
  _BattleScreenFlashComponent({
    required Vector2 size,
    required this.color,
    required this.durationSeconds,
  }) : super(
          size: size,
          anchor: Anchor.topLeft,
          priority: 19,
        );

  final Color color;
  final double durationSeconds;
  double _elapsed = 0;

  bool get isExpired => _elapsed >= durationSeconds;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    final progress =
        (_elapsed / (durationSeconds <= 0 ? 0.0001 : durationSeconds))
            .clamp(0.0, 1.0);
    canvas.drawRect(
      Offset.zero & Size(size.x, size.y),
      Paint()..color = color.withValues(alpha: color.a * (1 - progress)),
    );
  }
}

final class _BattleBarrierPulseComponent extends PositionComponent {
  _BattleBarrierPulseComponent({
    required Rect targetRect,
    required this.color,
    required this.durationSeconds,
    required this.style,
  })  : _targetRect = targetRect,
        super(
          position: Vector2(targetRect.left, targetRect.top),
          size: Vector2(targetRect.width, targetRect.height),
          anchor: Anchor.topLeft,
          priority: 19,
        );

  final Rect _targetRect;
  final Color color;
  final double durationSeconds;
  final BattleBarrierStyle style;
  double _elapsed = 0;

  bool get isExpired => _elapsed >= durationSeconds;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    final progress =
        (_elapsed / (durationSeconds <= 0 ? 0.0001 : durationSeconds))
            .clamp(0.0, 1.0);
    final grownRect = Rect.fromCenter(
      center: _targetRect.center - _targetRect.topLeft,
      width: _targetRect.width * (1 + (progress * 0.18)),
      height: _targetRect.height * (1 + (progress * 0.18)),
    );
    final pulseColor = color.withValues(alpha: color.a * (1 - progress));
    switch (style) {
      case BattleBarrierStyle.protect:
      case BattleBarrierStyle.quickGuard:
      case BattleBarrierStyle.wideGuard:
        _renderShieldRings(
          canvas,
          grownRect,
          pulseColor,
          fillAlphaScale: style == BattleBarrierStyle.wideGuard ? 0.18 : 0.24,
        );
      case BattleBarrierStyle.reflect:
        _renderPanelBarrier(
          canvas,
          grownRect,
          pulseColor,
          stripeColor: pulseColor.withValues(alpha: pulseColor.a * 0.26),
        );
      case BattleBarrierStyle.lightScreen:
        _renderScreenGrid(
          canvas,
          grownRect,
          pulseColor,
        );
      case BattleBarrierStyle.mist:
        _renderMistVeil(
          canvas,
          grownRect,
          pulseColor,
        );
      case BattleBarrierStyle.auroraVeil:
        _renderAuroraVeil(
          canvas,
          grownRect,
          pulseColor,
        );
      case BattleBarrierStyle.safeguard:
        _renderShieldRings(
          canvas,
          grownRect,
          pulseColor,
          fillAlphaScale: 0.16,
        );
    }
  }

  void _renderShieldRings(
    Canvas canvas,
    Rect rect,
    Color pulseColor, {
    required double fillAlphaScale,
  }) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = pulseColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(6), const Radius.circular(24)),
      Paint()
        ..color = pulseColor.withValues(alpha: pulseColor.a * fillAlphaScale),
    );
  }

  void _renderPanelBarrier(
    Canvas canvas,
    Rect rect,
    Color pulseColor, {
    required Color stripeColor,
  }) {
    _renderShieldRings(canvas, rect, pulseColor, fillAlphaScale: 0.14);
    final stripePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = stripeColor;
    for (var i = 1; i <= 3; i++) {
      final dx = rect.left + ((rect.width / 4) * i);
      canvas.drawLine(
        Offset(dx, rect.top + 10),
        Offset(dx, rect.bottom - 10),
        stripePaint,
      );
    }
  }

  void _renderScreenGrid(
    Canvas canvas,
    Rect rect,
    Color pulseColor,
  ) {
    _renderShieldRings(canvas, rect, pulseColor, fillAlphaScale: 0.18);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = pulseColor.withValues(alpha: pulseColor.a * 0.28);
    for (var i = 1; i <= 2; i++) {
      final y = rect.top + ((rect.height / 3) * i);
      canvas.drawLine(
        Offset(rect.left + 12, y),
        Offset(rect.right - 12, y),
        linePaint,
      );
    }
  }

  void _renderMistVeil(
    Canvas canvas,
    Rect rect,
    Color pulseColor,
  ) {
    final fogPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = pulseColor.withValues(alpha: pulseColor.a * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(28)),
      fogPaint,
    );
    for (var i = 0; i < 3; i++) {
      final centerY = rect.top + (rect.height * (0.25 + (i * 0.22)));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(rect.center.dx, centerY),
          width: rect.width * (0.72 - (i * 0.08)),
          height: rect.height * 0.22,
        ),
        Paint()..color = pulseColor.withValues(alpha: pulseColor.a * 0.10),
      );
    }
  }

  void _renderAuroraVeil(
    Canvas canvas,
    Rect rect,
    Color pulseColor,
  ) {
    _renderShieldRings(canvas, rect, pulseColor, fillAlphaScale: 0.12);
    final auroraPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(rect.left, rect.top),
        Offset(rect.right, rect.bottom),
        <Color>[
          const Color(0x66A8F7FF),
          const Color(0x66C4A4FF),
          const Color(0x66F1D6FF),
        ],
      );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(10), const Radius.circular(22)),
      auroraPaint,
    );
  }
}

final class _BattleWeatherAmbientComponent extends PositionComponent {
  _BattleWeatherAmbientComponent({
    required this.weather,
    required Vector2 size,
  }) : super(
          size: size,
          anchor: Anchor.topLeft,
          priority: 8,
        );

  final BattleWeatherId weather;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    switch (weather) {
      case BattleWeatherId.rain:
        _renderRain(canvas);
      case BattleWeatherId.sandstorm:
        _renderSandstorm(canvas);
    }
  }

  void _renderRain(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0x4D89C7FF)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 28; i++) {
      final x = ((i * 37.0) + (_elapsed * 110)) % (size.x + 40) - 20;
      final y = ((i * 19.0) + (_elapsed * 180)) % (size.y + 36) - 18;
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 8, y + 18),
        paint,
      );
    }
  }

  void _renderSandstorm(Canvas canvas) {
    final dustPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x33D6AA63);
    for (var i = 0; i < 24; i++) {
      final x = ((i * 41.0) - (_elapsed * 70)) % (size.x + 60);
      final y = ((i * 23.0) + (_elapsed * 32)) % (size.y + 24);
      final radius = 2.0 + (i % 3);
      canvas.drawCircle(
        Offset(x, y),
        radius,
        dustPaint,
      );
    }
  }
}

final class _BattlePseudoWeatherAmbientComponent extends PositionComponent {
  _BattlePseudoWeatherAmbientComponent({
    required this.pseudoWeather,
    required Vector2 size,
  }) : super(
          size: size,
          anchor: Anchor.topLeft,
          priority: 9,
        );

  final BattlePseudoWeatherId pseudoWeather;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    switch (pseudoWeather) {
      case BattlePseudoWeatherId.trickRoom:
        final tintPaint = Paint()..color = const Color(0x149F6BFF);
        canvas.drawRect(
          Offset.zero & Size(size.x, size.y),
          tintPaint,
        );
        final latticePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0x339F6BFF);
        for (var i = 0; i < 5; i++) {
          final offset = ((_elapsed * 22) + (i * 42)) % (size.x + 48) - 24;
          canvas.drawLine(
            Offset(offset, 0),
            Offset(offset + 60, size.y),
            latticePaint,
          );
        }
    }
  }
}
