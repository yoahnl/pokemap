import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import '../../application/runtime_move_catalog_loader.dart';
import 'battle_move_visual_catalog.dart';

class BattleResolvedMoveVisual {
  const BattleResolvedMoveVisual({
    required this.localMoveId,
    required this.showdownMoveId,
    required this.recipeId,
    required this.usesFallback,
    required this.canonicalMove,
  });

  final String localMoveId;
  final String? showdownMoveId;
  final BattleMoveVisualRecipeId recipeId;
  final bool usesFallback;
  final PokemonMove? canonicalMove;
}

final class BattleMoveVisualResolver {
  BattleMoveVisualResolver(this._runtimeMoveCatalog);

  final RuntimeMoveCatalog _runtimeMoveCatalog;

  BattleResolvedMoveVisual resolve(BattleMove move) {
    final canonicalMove = _runtimeMoveCatalog.lookup(move.id);
    final showdownMoveId = BattleMoveVisualCatalog.normalizeShowdownMoveId(
      canonicalMove?.sourceRefs.showdownMoveId ?? move.id,
    );
    final directRecipe = _resolveDirectRecipe(showdownMoveId);
    if (directRecipe != null) {
      return BattleResolvedMoveVisual(
        localMoveId: move.id,
        showdownMoveId: showdownMoveId,
        recipeId: directRecipe,
        usesFallback: false,
        canonicalMove: canonicalMove,
      );
    }

    final fallbackRecipe =
        _resolveFallbackRecipe(canonicalMove: canonicalMove, move: move);
    return BattleResolvedMoveVisual(
      localMoveId: move.id,
      showdownMoveId: showdownMoveId,
      recipeId: fallbackRecipe,
      usesFallback: true,
      canonicalMove: canonicalMove,
    );
  }

  BattleMoveVisualRecipeId? _resolveDirectRecipe(String? showdownMoveId) {
    if (showdownMoveId == null) {
      return null;
    }
    if (BattleMoveVisualCatalog.explicitNoAnimationShowdownIds
        .contains(showdownMoveId)) {
      return BattleMoveVisualRecipeId.noAnimation;
    }
    final direct =
        BattleMoveVisualCatalog.recipeByShowdownMoveId[showdownMoveId];
    if (direct != null) {
      return direct;
    }

    final visited = <String>{showdownMoveId};
    var current = showdownMoveId;
    while (true) {
      final next = BattleMoveVisualCatalog.aliasByShowdownMoveId[current];
      if (next == null || !visited.add(next)) {
        return null;
      }
      final recipe = BattleMoveVisualCatalog.recipeByShowdownMoveId[next];
      if (recipe != null) {
        return recipe;
      }
      current = next;
    }
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
              BattleMoveVisualCatalog.normalizeShowdownMoveId(weatherId);
          if (normalizedWeatherId == 'rain') {
            return BattleMoveVisualRecipeId.weatherRain;
          }
          if (normalizedWeatherId == 'sandstorm') {
            return BattleMoveVisualRecipeId.weatherSandstorm;
          }
        case PokemonMoveEffectSetPseudoWeather(:final pseudoWeatherId):
          final normalizedPseudoWeatherId =
              BattleMoveVisualCatalog.normalizeShowdownMoveId(pseudoWeatherId);
          if (normalizedPseudoWeatherId == 'trickroom') {
            return BattleMoveVisualRecipeId.pseudoWeatherTrickRoom;
          }
        case PokemonMoveEffectSetSideCondition(:final conditionId):
          final normalizedConditionId =
              BattleMoveVisualCatalog.normalizeShowdownMoveId(conditionId);
          if (normalizedConditionId == 'stealthrock') {
            return BattleMoveVisualRecipeId.setStealthRock;
          }
          if (normalizedConditionId == 'spikes') {
            return BattleMoveVisualRecipeId.setSpikes;
          }
          if (normalizedConditionId == 'reflect') {
            return BattleMoveVisualRecipeId.showdownReflect;
          }
          if (normalizedConditionId == 'lightscreen') {
            return BattleMoveVisualRecipeId.showdownLightScreen;
          }
          if (normalizedConditionId == 'mist') {
            return BattleMoveVisualRecipeId.showdownMist;
          }
          if (normalizedConditionId == 'auroraveil') {
            return BattleMoveVisualRecipeId.showdownAuroraVeil;
          }
          if (normalizedConditionId == 'safeguard') {
            return BattleMoveVisualRecipeId.showdownSafeguard;
          }
          if (normalizedConditionId == 'quickguard') {
            return BattleMoveVisualRecipeId.showdownQuickGuard;
          }
          if (normalizedConditionId == 'wideguard') {
            return BattleMoveVisualRecipeId.showdownWideGuard;
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
        BattleMoveVisualCatalog.normalizeShowdownMoveId(type) ?? 'unknown';
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
