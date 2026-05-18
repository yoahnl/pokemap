import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/data/generated/psdk_ability_effect_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK ability effect manifest', () {
    test('tracks all PSDK ability registrations without duplicates', () {
      final ids = psdkAbilityEffectManifest.map((entry) => entry.abilityId);

      expect(psdkAbilityEffectManifest.length, 276);
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
        'aura_break',
        'blaze',
        'air_lock',
        'battery',
        'chlorophyll',
        'cloud_nine',
        'comatose',
        'compound_eyes',
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
        'guts',
        'heatproof',
        'huge_power',
        'hustle',
        'ice_scales',
        'immunity',
        'iron_barbs',
        'iron_fist',
        'insomnia',
        'intrepid_sword',
        'intimidate',
        'justified',
        'leaf_guard',
        'levitate',
        'lightning_rod',
        'limber',
        'magma_armor',
        'marvel_scale',
        'mega_launcher',
        'misty_surge',
        'motor_drive',
        'neuroforce',
        'no_guard',
        'overgrow',
        'pastel_veil',
        'psychic_surge',
        'purifying_salt',
        'power_spot',
        'propeller_tail',
        'poison_point',
        'poison_touch',
        'punk_rock',
        'pure_power',
        'queenly_majesty',
        'quick_feet',
        'rain_dish',
        'reckless',
        'rock_head',
        'rocky_payload',
        'rough_skin',
        'sap_sipper',
        'sand_force',
        'sand_rush',
        'sand_veil',
        'sharpness',
        'shadow_tag',
        'arena_trap',
        'skill_link',
        'magnet_pull',
        'sand_stream',
        'snow_warning',
        'snow_cloak',
        'slush_rush',
        'soundproof',
        'stamina',
        'stakeout',
        'stalwart',
        'static',
        'steelworker',
        'steely_spirit',
        'steam_engine',
        'storm_drain',
        'strong_jaw',
        'swarm',
        'sweet_veil',
        'swift_swim',
        'tangling_hair',
        'technician',
        'thick_fat',
        'torrent',
        'tough_claws',
        'transistor',
        'toxic_boost',
        'toxic_chain',
        'vital_spirit',
        'volt_absorb',
        'victory_star',
        'water_veil',
        'water_bubble',
        'water_compaction',
        'water_absorb',
        'weak_armor',
        'wonder_skin',
      ]) {
        final entry = byId[abilityId];

        expect(entry, isNotNull, reason: abilityId);
        expect(entry!.status, PsdkAbilityPortStatus.ported);
        expect(entry.dartEffect, isNotNull, reason: abilityId);
        expect(registry.create(abilityId), isNotNull, reason: abilityId);
      }

      for (final abilityId in <String>[
        'speed_boost',
      ]) {
        final entry = byId[abilityId];

        expect(entry, isNotNull, reason: abilityId);
        expect(entry!.status, PsdkAbilityPortStatus.partial);
        expect(entry.dartEffect, isNotNull, reason: abilityId);
        expect(registry.create(abilityId), isNotNull, reason: abilityId);
      }
    });

    test('unknown abilities hydrate as safe inert ability markers', () {
      final effect = AbilityEffectRegistry().create('totally_unknown_ability');

      expect(effect, isNotNull);
      expect(effect!.id, 'ability:totally_unknown_ability');
      expect(effect.scope, isA<LocalBattleEffectScope>());
    });

    test('registry coverage keeps manifest evidence and factories aligned', () {
      final coverage = AbilityEffectRegistry().manifestCoverage();

      expect(coverage.totalManifestAbilities, 276);
      expect(coverage.factoryIdsOutsideManifest, isEmpty);
      expect(coverage.declaredEffectsWithoutFactory, isEmpty);
      expect(coverage.concreteFactoryAbilityIds, contains('imposter'));
      expect(coverage.concreteFactoryAbilityIds, contains('shadow_tag'));
      expect(coverage.manifestAbilityIds, contains('zero_to_hero'));
      expect(coverage.missingAbilityIds, contains('zero_to_hero'));
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
  });
}
