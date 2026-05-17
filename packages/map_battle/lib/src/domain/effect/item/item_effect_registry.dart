import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../data/generated/psdk_item_effect_manifest.dart';
import '../battle_effect.dart';
import '../battle_effect_scope.dart';
import 'air_balloon_effect.dart';
import 'berry_item_effect.dart';
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
    ..._berryFactories,
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

final Map<String, ItemEffectFactory> _berryFactories =
    <String, ItemEffectFactory>{
  'oran_berry': ({required scope}) => BerryItemEffect.hpHeal(
        itemId: 'oran_berry',
        scope: scope,
        healAmount: (battler) => battler.abilityId == 'ripen' ? 20 : 10,
      ),
  'sitrus_berry': ({required scope}) => BerryItemEffect.hpHeal(
        itemId: 'sitrus_berry',
        scope: scope,
        healAmount: (battler) =>
            ((battler.maxHp * (battler.abilityId == 'ripen' ? 2 : 1)) ~/ 4)
                .clamp(1, battler.maxHp)
                .toInt(),
      ),
  'berry_juice': ({required scope}) => BerryItemEffect.hpHeal(
        itemId: 'berry_juice',
        scope: scope,
        healAmount: (battler) => battler.abilityId == 'ripen' ? 40 : 20,
      ),
  for (final itemId in const <String>[
    'figy_berry',
    'wiki_berry',
    'mago_berry',
    'aguav_berry',
    'iapapa_berry',
  ])
    itemId: ({required scope}) => BerryItemEffect.hpHeal(
          itemId: itemId,
          scope: scope,
          hpThreshold: (battler) =>
              battler.abilityId == 'gluttony' ? 0.5 : 0.25,
          healAmount: (battler) =>
              ((battler.maxHp * (battler.abilityId == 'ripen' ? 2 : 1)) ~/ 3)
                  .clamp(1, battler.maxHp)
                  .toInt(),
          mayConfuseFromNature: true,
        ),
  'aspear_berry': ({required scope}) => BerryItemEffect.statusCure(
        itemId: 'aspear_berry',
        scope: scope,
        statuses: const <PsdkBattleMajorStatus>{PsdkBattleMajorStatus.freeze},
      ),
  'rawst_berry': ({required scope}) => BerryItemEffect.statusCure(
        itemId: 'rawst_berry',
        scope: scope,
        statuses: const <PsdkBattleMajorStatus>{PsdkBattleMajorStatus.burn},
      ),
  'pecha_berry': ({required scope}) => BerryItemEffect.statusCure(
        itemId: 'pecha_berry',
        scope: scope,
        statuses: const <PsdkBattleMajorStatus>{
          PsdkBattleMajorStatus.poison,
          PsdkBattleMajorStatus.toxic,
        },
      ),
  'chesto_berry': ({required scope}) => BerryItemEffect.statusCure(
        itemId: 'chesto_berry',
        scope: scope,
        statuses: const <PsdkBattleMajorStatus>{PsdkBattleMajorStatus.sleep},
      ),
  'cheri_berry': ({required scope}) => BerryItemEffect.statusCure(
        itemId: 'cheri_berry',
        scope: scope,
        statuses: const <PsdkBattleMajorStatus>{
          PsdkBattleMajorStatus.paralysis,
        },
      ),
  'lum_berry': ({required scope}) => BerryItemEffect.statusCure(
        itemId: 'lum_berry',
        scope: scope,
        statuses: const <PsdkBattleMajorStatus>{
          PsdkBattleMajorStatus.paralysis,
          PsdkBattleMajorStatus.burn,
          PsdkBattleMajorStatus.poison,
          PsdkBattleMajorStatus.toxic,
          PsdkBattleMajorStatus.sleep,
          PsdkBattleMajorStatus.freeze,
        },
      ),
  'liechi_berry': ({required scope}) => BerryItemEffect.statPinch(
        itemId: 'liechi_berry',
        scope: scope,
        stat: 'attack',
      ),
  'ganlon_berry': ({required scope}) => BerryItemEffect.statPinch(
        itemId: 'ganlon_berry',
        scope: scope,
        stat: 'defense',
      ),
  'salac_berry': ({required scope}) => BerryItemEffect.statPinch(
        itemId: 'salac_berry',
        scope: scope,
        stat: 'speed',
      ),
  'petaya_berry': ({required scope}) => BerryItemEffect.statPinch(
        itemId: 'petaya_berry',
        scope: scope,
        stat: 'specialAttack',
      ),
  'apicot_berry': ({required scope}) => BerryItemEffect.statPinch(
        itemId: 'apicot_berry',
        scope: scope,
        stat: 'specialDefense',
      ),
  'starf_berry': ({required scope}) => BerryItemEffect.statPinch(
        itemId: 'starf_berry',
        scope: scope,
        stat: 'random',
      ),
};
