import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import '../../application/runtime_move_catalog_loader.dart';
import 'battle_move_visual_catalog.dart';
import 'battle_sdk_rmxp_animation_catalog.dart';

enum BattleMoveVisualSource {
  exactRuby,
  exactRmxp,
  adapted,
  sdkFamily,
  semanticFallback,
  noAnimation,
}

class BattleResolvedMoveVisual {
  const BattleResolvedMoveVisual({
    required this.localMoveId,
    required this.sdkMoveId,
    required this.recipeId,
    required this.usesFallback,
    required this.canonicalMove,
    this.sdkNumericMoveId,
    this.rmxpUserAnimationId,
    this.rmxpTargetAnimationId,
    this.visualSource = BattleMoveVisualSource.sdkFamily,
  });

  final String localMoveId;
  final String? sdkMoveId;
  final int? sdkNumericMoveId;
  final int? rmxpUserAnimationId;
  final int? rmxpTargetAnimationId;
  final BattleMoveVisualSource visualSource;
  final BattleMoveVisualRecipeId recipeId;
  final bool usesFallback;
  final PokemonMove? canonicalMove;
}

final class BattleMoveVisualResolver {
  BattleMoveVisualResolver(this._runtimeMoveCatalog);

  final RuntimeMoveCatalog _runtimeMoveCatalog;

  BattleResolvedMoveVisual resolve(BattleMove move) {
    final canonicalMove = _runtimeMoveCatalog.lookup(move.id);
    final sdkMoveId = BattleMoveVisualCatalog.normalizeSDKMoveId(
      canonicalMove?.sourceRefs.showdownMoveId ?? move.id,
    );
    final sdkNumericMoveId = sdkMoveId == null
        ? null
        : BattleSdkMoveIdCatalog.sdkMoveIdByNormalizedMoveId[sdkMoveId];
    final resolvedRecipe = _resolveDirectRecipe(sdkMoveId);
    final directRecipe = resolvedRecipe?.recipeId;
    if (directRecipe == BattleMoveVisualRecipeId.noAnimation) {
      return BattleResolvedMoveVisual(
        localMoveId: move.id,
        sdkMoveId: sdkMoveId,
        sdkNumericMoveId: sdkNumericMoveId,
        recipeId: BattleMoveVisualRecipeId.noAnimation,
        usesFallback: false,
        canonicalMove: canonicalMove,
        visualSource: BattleMoveVisualSource.noAnimation,
      );
    }
    if (directRecipe != null && _isExactRubySDKMove(sdkMoveId, directRecipe)) {
      return BattleResolvedMoveVisual(
        localMoveId: move.id,
        sdkMoveId: sdkMoveId,
        sdkNumericMoveId: sdkNumericMoveId,
        recipeId: directRecipe,
        usesFallback: false,
        canonicalMove: canonicalMove,
        visualSource: BattleMoveVisualSource.exactRuby,
      );
    }

    final rmxpTargetAnimationId = sdkNumericMoveId == null
        ? null
        : BattleSdkRmxpAnimationCatalog
            .moveTargetAnimationIdBySdkMoveId[sdkNumericMoveId];
    final rmxpUserAnimationId = sdkNumericMoveId == null
        ? null
        : BattleSdkRmxpAnimationCatalog
            .moveUserAnimationIdBySdkMoveId[sdkNumericMoveId];
    if (rmxpUserAnimationId != null || rmxpTargetAnimationId != null) {
      return BattleResolvedMoveVisual(
        localMoveId: move.id,
        sdkMoveId: sdkMoveId,
        sdkNumericMoveId: sdkNumericMoveId,
        rmxpUserAnimationId: rmxpUserAnimationId,
        rmxpTargetAnimationId: rmxpTargetAnimationId,
        recipeId: BattleMoveVisualRecipeId.sdkRmxpMoveAnimation,
        usesFallback: false,
        canonicalMove: canonicalMove,
        visualSource: BattleMoveVisualSource.exactRmxp,
      );
    }

    if (directRecipe != null) {
      return BattleResolvedMoveVisual(
        localMoveId: move.id,
        sdkMoveId: sdkMoveId,
        sdkNumericMoveId: sdkNumericMoveId,
        recipeId: directRecipe,
        usesFallback: false,
        canonicalMove: canonicalMove,
        visualSource: _isAdaptedSDKMove(
          sdkMoveId,
          resolvedRecipe?.resolvedSDKMoveId,
        )
            ? BattleMoveVisualSource.adapted
            : BattleMoveVisualSource.sdkFamily,
      );
    }

    final fallbackRecipe =
        _resolveFallbackRecipe(canonicalMove: canonicalMove, move: move);
    return BattleResolvedMoveVisual(
      localMoveId: move.id,
      sdkMoveId: sdkMoveId,
      sdkNumericMoveId: sdkNumericMoveId,
      recipeId: fallbackRecipe,
      usesFallback: true,
      canonicalMove: canonicalMove,
      visualSource: fallbackRecipe == BattleMoveVisualRecipeId.noAnimation
          ? BattleMoveVisualSource.noAnimation
          : BattleMoveVisualSource.semanticFallback,
    );
  }

  _ResolvedMoveRecipe? _resolveDirectRecipe(String? sdkMoveId) {
    if (sdkMoveId == null) {
      return null;
    }
    if (BattleMoveVisualCatalog.explicitNoAnimationSDKIds.contains(sdkMoveId)) {
      return _ResolvedMoveRecipe(
        recipeId: BattleMoveVisualRecipeId.noAnimation,
        resolvedSDKMoveId: sdkMoveId,
      );
    }
    final direct = BattleMoveVisualCatalog.recipeBySDKMoveId[sdkMoveId];
    if (direct != null) {
      return _ResolvedMoveRecipe(
        recipeId: direct,
        resolvedSDKMoveId: sdkMoveId,
      );
    }

    final visited = <String>{sdkMoveId};
    var current = sdkMoveId;
    while (true) {
      final next = BattleMoveVisualCatalog.aliasBySDKMoveId[current];
      if (next == null || !visited.add(next)) {
        return null;
      }
      final recipe = BattleMoveVisualCatalog.recipeBySDKMoveId[next];
      if (recipe != null) {
        return _ResolvedMoveRecipe(
          recipeId: recipe,
          resolvedSDKMoveId: next,
        );
      }
      current = next;
    }
  }

  bool _isExactRubySDKMove(
    String? sdkMoveId,
    BattleMoveVisualRecipeId recipeId,
  ) {
    return sdkMoveId != null &&
        BattleMoveVisualCatalog.exactRubySDKMoveIds.contains(sdkMoveId) &&
        _isRubyExactRecipe(recipeId);
  }

  bool _isRubyExactRecipe(BattleMoveVisualRecipeId recipeId) {
    return switch (recipeId) {
      BattleMoveVisualRecipeId.sdkExactAcidArmor ||
      BattleMoveVisualRecipeId.sdkExactAcrobatics ||
      BattleMoveVisualRecipeId.sdkExactAerialAce ||
      BattleMoveVisualRecipeId.sdkExactAirSlash ||
      BattleMoveVisualRecipeId.sdkExactAquaRing ||
      BattleMoveVisualRecipeId.sdkExactAquaTail ||
      BattleMoveVisualRecipeId.sdkExactAssurance ||
      BattleMoveVisualRecipeId.sdkExactAstonish ||
      BattleMoveVisualRecipeId.sdkExactAvalanche ||
      BattleMoveVisualRecipeId.sdkExactKarateChop ||
      BattleMoveVisualRecipeId.sdkExactLeechSeed ||
      BattleMoveVisualRecipeId.sdkExactPoisonPowder ||
      BattleMoveVisualRecipeId.sdkExactRecover ||
      BattleMoveVisualRecipeId.sdkExactSleepPowder ||
      BattleMoveVisualRecipeId.sdkExactStunSpore ||
      BattleMoveVisualRecipeId.sdkExactTailWhip ||
      BattleMoveVisualRecipeId.sdkExactThunderWave ||
      BattleMoveVisualRecipeId.sdkExactVineWhip =>
        true,
      _ => false,
    };
  }

  bool _isAdaptedSDKMove(String? sdkMoveId, String? resolvedSDKMoveId) {
    return (sdkMoveId != null &&
            BattleMoveVisualCatalog.adaptedSDKMoveIds.contains(sdkMoveId)) ||
        (resolvedSDKMoveId != null &&
            BattleMoveVisualCatalog.adaptedSDKMoveIds
                .contains(resolvedSDKMoveId));
  }

  BattleMoveVisualRecipeId _resolveFallbackRecipe({
    required PokemonMove? canonicalMove,
    required BattleMove move,
  }) {
    return _resolveFromPokemonMove(canonicalMove) ??
        _resolveFromBattleMove(move) ??
        BattleMoveVisualRecipeId.noAnimation;
  }

  BattleMoveVisualRecipeId? _resolveFromPokemonMove(PokemonMove? move) {
    if (move == null) {
      return null;
    }

    if (move.flags.contains(PokemonMoveFlag.slicing)) {
      return BattleMoveVisualRecipeId.genericSlash;
    }
    if (move.flags.contains(PokemonMoveFlag.punch)) {
      return BattleMoveVisualRecipeId.genericPunch;
    }
    if (move.flags.contains(PokemonMoveFlag.sound)) {
      return BattleMoveVisualRecipeId.genericStatusPulse;
    }
    if (move.flags.contains(PokemonMoveFlag.pulse)) {
      return BattleMoveVisualRecipeId.genericProjectilePulse;
    }
    if (move.flags.contains(PokemonMoveFlag.bullet)) {
      return BattleMoveVisualRecipeId.genericProjectileNeutral;
    }
    if (move.flags.contains(PokemonMoveFlag.bite)) {
      return BattleMoveVisualRecipeId.genericBite;
    }

    for (final effect in move.effects) {
      switch (effect) {
        case PokemonMoveEffectSetWeather(:final weatherId):
          final normalizedWeatherId =
              BattleMoveVisualCatalog.normalizeSDKMoveId(weatherId);
          if (normalizedWeatherId == 'rain') {
            return BattleMoveVisualRecipeId.weatherRain;
          }
          if (normalizedWeatherId == 'sandstorm') {
            return BattleMoveVisualRecipeId.weatherSandstorm;
          }
        case PokemonMoveEffectSetPseudoWeather(:final pseudoWeatherId):
          final normalizedPseudoWeatherId =
              BattleMoveVisualCatalog.normalizeSDKMoveId(pseudoWeatherId);
          if (normalizedPseudoWeatherId == 'trickroom') {
            return BattleMoveVisualRecipeId.pseudoWeatherTrickRoom;
          }
        case PokemonMoveEffectSetSideCondition(:final conditionId):
          final normalizedConditionId =
              BattleMoveVisualCatalog.normalizeSDKMoveId(conditionId);
          if (normalizedConditionId == 'stealthrock') {
            return BattleMoveVisualRecipeId.setStealthRock;
          }
          if (normalizedConditionId == 'spikes') {
            return BattleMoveVisualRecipeId.setSpikes;
          }
          if (normalizedConditionId == 'reflect') {
            return BattleMoveVisualRecipeId.sdkReflect;
          }
          if (normalizedConditionId == 'lightscreen') {
            return BattleMoveVisualRecipeId.sdkLightScreen;
          }
          if (normalizedConditionId == 'mist') {
            return BattleMoveVisualRecipeId.sdkMist;
          }
          if (normalizedConditionId == 'auroraveil') {
            return BattleMoveVisualRecipeId.sdkAuroraVeil;
          }
          if (normalizedConditionId == 'safeguard') {
            return BattleMoveVisualRecipeId.sdkSafeguard;
          }
          if (normalizedConditionId == 'quickguard') {
            return BattleMoveVisualRecipeId.sdkQuickGuard;
          }
          if (normalizedConditionId == 'wideguard') {
            return BattleMoveVisualRecipeId.sdkWideGuard;
          }
        case PokemonMoveEffectRequireRecharge():
          return BattleMoveVisualRecipeId.rechargePause;
        case PokemonMoveEffectChargeThenStrike():
          return BattleMoveVisualRecipeId.chargeUp;
        case PokemonMoveEffectModifyStats(:final stageChanges):
          final hasPositive = stageChanges.any((change) => change.stages > 0);
          final hasNegative = stageChanges.any((change) => change.stages < 0);
          if (move.category == PokemonMoveCategory.status &&
              move.target == PokemonMoveTarget.self &&
              hasPositive) {
            return BattleMoveVisualRecipeId.genericBuffSelf;
          }
          if (move.category == PokemonMoveCategory.status &&
              move.target != PokemonMoveTarget.self &&
              hasNegative) {
            return BattleMoveVisualRecipeId.genericDebuffTarget;
          }
        default:
          break;
      }
    }

    return _resolveFromMoveSemantics(
      type: move.type,
      category: move.category == PokemonMoveCategory.physical
          ? BattleMoveCategory.physical
          : move.category == PokemonMoveCategory.special
              ? BattleMoveCategory.special
              : BattleMoveCategory.status,
      target: move.target == PokemonMoveTarget.self
          ? BattleMoveTarget.self
          : move.target == PokemonMoveTarget.foeSide
              ? BattleMoveTarget.opponentSide
              : move.target == PokemonMoveTarget.normal
                  ? BattleMoveTarget.opponent
                  : BattleMoveTarget.unspecified,
      requiresRecharge: move.flags.contains(PokemonMoveFlag.recharge),
      setsStealthRock: false,
      setsSpikes: false,
      weatherEffect: null,
      pseudoWeatherEffect: null,
      power: move.basePower,
    );
  }

  BattleMoveVisualRecipeId? _resolveFromBattleMove(BattleMove move) {
    return _resolveFromMoveSemantics(
      type: move.type,
      category: move.category ?? BattleMoveCategory.physical,
      target: move.target,
      requiresRecharge: move.requiresRecharge,
      setsStealthRock: move.setsStealthRock,
      setsSpikes: move.setsSpikes,
      weatherEffect: move.weatherEffect,
      pseudoWeatherEffect: move.pseudoWeatherEffect,
      power: move.power,
    );
  }

  BattleMoveVisualRecipeId? _resolveFromMoveSemantics({
    required String type,
    required BattleMoveCategory category,
    required BattleMoveTarget target,
    required bool requiresRecharge,
    required bool setsStealthRock,
    required bool setsSpikes,
    required BattleWeatherId? weatherEffect,
    required BattlePseudoWeatherId? pseudoWeatherEffect,
    required int power,
  }) {
    if (setsStealthRock) {
      return BattleMoveVisualRecipeId.setStealthRock;
    }
    if (setsSpikes) {
      return BattleMoveVisualRecipeId.setSpikes;
    }
    if (requiresRecharge) {
      return BattleMoveVisualRecipeId.rechargePause;
    }
    if (weatherEffect == BattleWeatherId.rain) {
      return BattleMoveVisualRecipeId.weatherRain;
    }
    if (weatherEffect == BattleWeatherId.sandstorm) {
      return BattleMoveVisualRecipeId.weatherSandstorm;
    }
    if (pseudoWeatherEffect == BattlePseudoWeatherId.trickRoom) {
      return BattleMoveVisualRecipeId.pseudoWeatherTrickRoom;
    }

    if (category == BattleMoveCategory.status) {
      if (target == BattleMoveTarget.self) {
        return BattleMoveVisualRecipeId.genericBuffSelf;
      }
      if (target == BattleMoveTarget.opponent ||
          target == BattleMoveTarget.opponentSide) {
        return BattleMoveVisualRecipeId.genericDebuffTarget;
      }
      return null;
    }

    final normalizedType =
        BattleMoveVisualCatalog.normalizeSDKMoveId(type) ?? 'unknown';
    if (category == BattleMoveCategory.special) {
      return switch (normalizedType) {
        'fire' => BattleMoveVisualRecipeId.genericProjectileFire,
        'water' => BattleMoveVisualRecipeId.genericProjectileWater,
        'electric' => BattleMoveVisualRecipeId.genericProjectileElectric,
        'ghost' => BattleMoveVisualRecipeId.genericProjectileGhost,
        'dark' => BattleMoveVisualRecipeId.genericProjectileDark,
        'fairy' => BattleMoveVisualRecipeId.genericProjectileFairy,
        'ice' => BattleMoveVisualRecipeId.genericProjectileIce,
        _ => BattleMoveVisualRecipeId.genericProjectileNeutral,
      };
    }

    if (category == BattleMoveCategory.physical) {
      return power >= 100
          ? BattleMoveVisualRecipeId.genericContactHeavy
          : BattleMoveVisualRecipeId.genericContactLight;
    }

    return null;
  }
}

final class _ResolvedMoveRecipe {
  const _ResolvedMoveRecipe({
    required this.recipeId,
    required this.resolvedSDKMoveId,
  });

  final BattleMoveVisualRecipeId recipeId;
  final String resolvedSDKMoveId;
}
