import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/data/generated/psdk_ability_effect_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK ability effect manifest', () {
    test('tracks all PSDK ability registrations without duplicates', () {
      final ids = psdkAbilityEffectManifest.map((entry) => entry.abilityId);

      expect(psdkAbilityEffectManifest.length, 278);
      expect(ids.toSet(), hasLength(psdkAbilityEffectManifest.length));
      expect(
        ids,
        containsAll(<String>[
          'air_lock',
          'cloud_nine',
          'levitate',
          'soundproof',
          'wonder_guard',
          'zero_to_hero',
        ]),
      );
    });

    test('known local abilities are marked and hydrate through the registry',
        () {
      final byId = {
        for (final entry in psdkAbilityEffectManifest) entry.abilityId: entry,
      };
      final registry = AbilityEffectRegistry();

      for (final abilityId in <String>[
        'analytic',
        'anticipation',
        'aura_break',
        'blaze',
        'aftermath',
        'air_lock',
        'anger_point',
        'anger_shell',
        'armor_tail',
        'battery',
        'beast_boost',
        'berserk',
        'bulletproof',
        'chilling_neigh',
        'chlorophyll',
        'cloud_nine',
        'comatose',
        'compound_eyes',
        'cud_chew',
        'cursed_body',
        'damp',
        'dark_aura',
        'dauntless_shield',
        'dazzling',
        'download',
        'drizzle',
        'dragon_s_maw',
        'drought',
        'dry_skin',
        'earth_eater',
        'effect_spore',
        'electric_surge',
        'defeatist',
        'fairy_aura',
        'flash_fire',
        'flame_body',
        'flare_boost',
        'flower_veil',
        'fluffy',
        'friend_guard',
        'fur_coat',
        'gooey',
        'grass_pelt',
        'grassy_surge',
        'good_as_gold',
        'grim_neigh',
        'guts',
        'healer',
        'heatproof',
        'hospitality',
        'huge_power',
        'hustle',
        'hydration',
        'ice_body',
        'ice_scales',
        'immunity',
        'innards_out',
        'inner_focus',
        'iron_barbs',
        'iron_fist',
        'insomnia',
        'intrepid_sword',
        'intimidate',
        'justified',
        'own_tempo',
        'leaf_guard',
        'levitate',
        'lightning_rod',
        'limber',
        'lingering_aroma',
        'magician',
        'magma_armor',
        'marvel_scale',
        'mega_launcher',
        'misty_surge',
        'mold_breaker',
        'motor_drive',
        'moody',
        'mummy',
        'moxie',
        'natural_cure',
        'neuroforce',
        'no_guard',
        'overgrow',
        'opportunist',
        'pastel_veil',
        'perish_body',
        'pickpocket',
        'pressure',
        'psychic_surge',
        'purifying_salt',
        'power_spot',
        'prankster',
        'propeller_tail',
        'poison_point',
        'poison_touch',
        'punk_rock',
        'pure_power',
        'poison_puppeteer',
        'queenly_majesty',
        'quick_feet',
        'rain_dish',
        'reckless',
        'regenerator',
        'rock_head',
        'rocky_payload',
        'rough_skin',
        'sap_sipper',
        'sand_spit',
        'sand_force',
        'sand_rush',
        'sand_veil',
        'sharpness',
        'shadow_tag',
        'arena_trap',
        'skill_link',
        'magnet_pull',
        'speed_boost',
        'sand_stream',
        'screen_cleaner',
        'seed_sower',
        'snow_warning',
        'snow_cloak',
        'slush_rush',
        'soundproof',
        'solar_power',
        'stamina',
        'stakeout',
        'stalwart',
        'static',
        'steelworker',
        'steely_spirit',
        'steam_engine',
        'stench',
        'storm_drain',
        'strong_jaw',
        'surge_surfer',
        'swarm',
        'suction_cups',
        'sweet_veil',
        'synchronize',
        'swift_swim',
        'tangled_feet',
        'tangling_hair',
        'technician',
        'telepathy',
        'teravolt',
        'thermal_exchange',
        'thick_fat',
        'torrent',
        'tough_claws',
        'transistor',
        'triage',
        'truant',
        'toxic_boost',
        'toxic_chain',
        'toxic_debris',
        'turboblaze',
        'unnerve',
        'vital_spirit',
        'volt_absorb',
        'victory_star',
        'water_veil',
        'water_bubble',
        'water_compaction',
        'water_absorb',
        'wandering_spirit',
        'weak_armor',
        'well_baked_body',
        'wonder_skin',
        'run_away',
        'aroma_veil',
        'oblivious',
        'beads_of_ruin',
        'sword_of_ruin',
      ]) {
        final entry = byId[abilityId];

        expect(entry, isNotNull, reason: abilityId);
        expect(entry!.status, PsdkAbilityPortStatus.ported);
        expect(entry.dartEffect, isNotNull, reason: abilityId);
        expect(registry.create(abilityId), isNotNull, reason: abilityId);
      }

      for (final abilityId in <String>[
        'color_change',
        'cotton_down',
        'electromorphosis',
      ]) {
        final entry = byId[abilityId];

        expect(entry, isNotNull, reason: abilityId);
        expect(entry!.status, PsdkAbilityPortStatus.partial);
        expect(entry.dartEffect, isNotNull, reason: abilityId);
        expect(registry.create(abilityId), isNotNull, reason: abilityId);
      }
    });

    test('Lot 256 post-damage and stat-copy abilities are strict', () {
      final byId = {
        for (final entry in psdkAbilityEffectManifest) entry.abilityId: entry,
      };

      for (final abilityId in <String>[
        'anger_shell',
        'berserk',
        'opportunist',
      ]) {
        expect(
          byId[abilityId]?.status,
          PsdkAbilityPortStatus.ported,
          reason: abilityId,
        );
        expect(byId[abilityId]?.dartEffect, isNotNull, reason: abilityId);
        expect(AbilityEffectRegistry().create(abilityId), isNotNull,
            reason: abilityId);
      }
    });

    test('Lot 257 residual Speed Boost ability is strict', () {
      final byId = {
        for (final entry in psdkAbilityEffectManifest) entry.abilityId: entry,
      };

      expect(
        byId['speed_boost']?.status,
        PsdkAbilityPortStatus.ported,
      );
      expect(byId['speed_boost']?.dartEffect, 'SpeedBoostEffect');
      expect(AbilityEffectRegistry().create('speed_boost'), isNotNull);
    });

    test('unknown abilities hydrate as safe inert ability markers', () {
      final effect = AbilityEffectRegistry().create('totally_unknown_ability');

      expect(effect, isNotNull);
      expect(effect!.id, 'ability:totally_unknown_ability');
      expect(effect.scope, isA<LocalBattleEffectScope>());
    });

    test('registry coverage keeps manifest evidence and factories aligned', () {
      final coverage = AbilityEffectRegistry().manifestCoverage();

      expect(coverage.totalManifestAbilities, 278);
      expect(coverage.factoryIdsOutsideManifest, isEmpty);
      expect(coverage.declaredEffectsWithoutFactory, isEmpty);
      expect(coverage.concreteFactoryAbilityIds, contains('imposter'));
      expect(coverage.concreteFactoryAbilityIds, contains('shadow_tag'));
      expect(coverage.concreteFactoryAbilityIds, contains('zero_to_hero'));
      expect(coverage.manifestAbilityIds, contains('zero_to_hero'));
      expect(coverage.missingAbilityIds, contains('ball_fetch'));
    });

    test('Lot 98 damage type and accuracy abilities are strict', () {
      final byId = {
        for (final entry in psdkAbilityEffectManifest) entry.abilityId: entry,
      };

      for (final abilityId in <String>[
        'blaze',
        'overgrow',
        'torrent',
        'swarm',
        'dragon_s_maw',
        'steelworker',
        'transistor',
        'rocky_payload',
        'technician',
        'iron_fist',
        'tough_claws',
        'sharpness',
        'punk_rock',
        'water_absorb',
        'volt_absorb',
        'earth_eater',
        'flash_fire',
        'motor_drive',
        'lightning_rod',
        'storm_drain',
        'sap_sipper',
        'levitate',
        'no_guard',
        'reckless',
        'rock_head',
        'skill_link',
        'rough_skin',
        'iron_barbs',
      ]) {
        expect(
          byId[abilityId]?.status,
          PsdkAbilityPortStatus.ported,
          reason: abilityId,
        );
      }
    });

    test('Lot 99 status and selection guard abilities are strict', () {
      final byId = {
        for (final entry in psdkAbilityEffectManifest) entry.abilityId: entry,
      };

      for (final abilityId in <String>[
        'damp',
        'soundproof',
        'immunity',
        'insomnia',
        'vital_spirit',
        'limber',
        'magma_armor',
        'water_veil',
      ]) {
        expect(
          byId[abilityId]?.status,
          PsdkAbilityPortStatus.ported,
          reason: abilityId,
        );
      }
    });

    test('Lot 100 switch residual and form abilities are strict', () {
      final byId = {
        for (final entry in psdkAbilityEffectManifest) entry.abilityId: entry,
      };

      for (final abilityId in <String>[
        'drizzle',
        'drought',
        'sand_stream',
        'snow_warning',
        'electric_surge',
        'grassy_surge',
        'misty_surge',
        'psychic_surge',
        'intimidate',
        'rain_dish',
        'dry_skin',
      ]) {
        expect(
          byId[abilityId]?.status,
          PsdkAbilityPortStatus.ported,
          reason: abilityId,
        );
      }
    });

    test('Lot 119 weather form and high-value tera abilities are strict', () {
      final byId = {
        for (final entry in psdkAbilityEffectManifest) entry.abilityId: entry,
      };

      for (final abilityId in <String>[
        'forecast',
        'embody_aspect',
        'supreme_overlord',
        'tera_shell',
        'teraform_zero',
      ]) {
        expect(
          byId[abilityId]?.status,
          PsdkAbilityPortStatus.ported,
          reason: abilityId,
        );
      }
    });

    test('Lot 120 form-changing abilities are strict', () {
      final byId = {
        for (final entry in psdkAbilityEffectManifest) entry.abilityId: entry,
      };

      for (final abilityId in <String>[
        'battle_bond',
        'disguise',
        'gulp_missile',
        'hunger_switch',
        'ice_face',
        'power_construct',
        'schooling',
        'shields_down',
        'tera_shift',
        'zen_mode',
        'zero_to_hero',
      ]) {
        expect(
          byId[abilityId]?.status,
          PsdkAbilityPortStatus.ported,
          reason: abilityId,
        );
        expect(byId[abilityId]?.dartEffect, isNotNull, reason: abilityId);
        expect(AbilityEffectRegistry().create(abilityId), isNotNull,
            reason: abilityId);
      }
    });
  });
}
