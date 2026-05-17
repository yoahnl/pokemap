import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../data/generated/psdk_item_effect_manifest.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'air_balloon_effect.dart';
import 'black_sludge_effect.dart';
import 'iron_ball_effect.dart';
import 'leftovers_effect.dart';
import 'loaded_dice_effect.dart';
import 'shed_shell_effect.dart';
import 'terrain_extender_effect.dart';
import 'weather_rock_effect.dart';

typedef ItemEffectFactory = BattleEffect Function({
  required BattleEffectScope scope,
});

final class ItemEffectRegistry {
  ItemEffectRegistry({
    Map<String, ItemEffectFactory>? factories,
  }) : _factories = factories ?? _defaultFactories;

  static final Map<String, ItemEffectFactory> _defaultFactories =
      <String, ItemEffectFactory>{
    'air_balloon': ({required scope}) => AirBalloonEffect(scope: scope),
    'black_sludge': ({required scope}) => BlackSludgeEffect(scope: scope),
    'iron_ball': ({required scope}) => IronBallEffect(scope: scope),
    'leftovers': ({required scope}) => LeftoversEffect(scope: scope),
    'loaded_dice': ({required scope}) => LoadedDiceEffect(scope: scope),
    'shed_shell': ({required scope}) => ShedShellEffect(scope: scope),
    'terrain_extender': ({required scope}) => TerrainExtenderEffect(
          scope: scope,
        ),
    'damp_rock': ({required scope}) => WeatherRockEffect(
          itemId: 'damp_rock',
          scope: scope,
          moveDbSymbols: const <String>['rain_dance'],
        ),
    'heat_rock': ({required scope}) => WeatherRockEffect(
          itemId: 'heat_rock',
          scope: scope,
          moveDbSymbols: const <String>['sunny_day'],
        ),
    'smooth_rock': ({required scope}) => WeatherRockEffect(
          itemId: 'smooth_rock',
          scope: scope,
          moveDbSymbols: const <String>['sandstorm'],
        ),
    'icy_rock': ({required scope}) => WeatherRockEffect(
          itemId: 'icy_rock',
          scope: scope,
          moveDbSymbols: const <String>['hail', 'snowscape'],
        ),
  };

  final Map<String, ItemEffectFactory> _factories;

  Set<String> get registeredItemIds {
    return <String>{
      for (final entry in psdkItemEffectManifest) entry.itemId,
    };
  }

  BattleEffect? create(String? itemId, {required PsdkBattleSlotRef owner}) {
    final normalized = _normalizeItemId(itemId);
    if (normalized == null) {
      return null;
    }
    final factory = _factories[normalized];
    if (factory == null) {
      return null;
    }
    return factory(scope: BattlerBattleEffectScope(owner));
  }

  PsdkBattleEffectStack hydrateEffects({
    required PsdkBattleEffectStack effects,
    required String? itemId,
    required PsdkBattleSlotRef owner,
    required bool itemConsumed,
  }) {
    final base = effects.withoutItemEffects();
    if (itemConsumed) {
      return base;
    }
    final effect = create(itemId, owner: owner);
    return effect == null ? base : base.addEffect(effect);
  }
}

String? _normalizeItemId(String? itemId) {
  if (itemId == null) {
    return null;
  }
  final normalized = itemId.trim().toLowerCase();
  return normalized.isEmpty ? null : normalized;
}
