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
        'blaze',
        'damp',
        'dragon_s_maw',
        'earth_eater',
        'flash_fire',
        'immunity',
        'iron_barbs',
        'iron_fist',
        'insomnia',
        'levitate',
        'lightning_rod',
        'limber',
        'magma_armor',
        'motor_drive',
        'no_guard',
        'overgrow',
        'punk_rock',
        'reckless',
        'rock_head',
        'rocky_payload',
        'rough_skin',
        'sap_sipper',
        'sharpness',
        'shadow_tag',
        'arena_trap',
        'skill_link',
        'magnet_pull',
        'soundproof',
        'steelworker',
        'storm_drain',
        'swarm',
        'technician',
        'torrent',
        'tough_claws',
        'transistor',
        'vital_spirit',
        'volt_absorb',
        'water_veil',
        'water_absorb',
      ]) {
        final entry = byId[abilityId];

        expect(entry, isNotNull, reason: abilityId);
        expect(entry!.status, PsdkAbilityPortStatus.ported);
        expect(entry.dartEffect, isNotNull, reason: abilityId);
        expect(registry.create(abilityId), isNotNull, reason: abilityId);
      }

      for (final abilityId in <String>[
        'air_lock',
        'cloud_nine',
        'drizzle',
        'drought',
        'dry_skin',
        'electric_surge',
        'grassy_surge',
        'intimidate',
        'misty_surge',
        'psychic_surge',
        'rain_dish',
        'sand_stream',
        'snow_warning',
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
  });
}
