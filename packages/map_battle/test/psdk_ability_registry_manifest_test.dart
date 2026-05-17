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
        'air_lock',
        'blaze',
        'cloud_nine',
        'damp',
        'dragon_s_maw',
        'drizzle',
        'drought',
        'dry_skin',
        'earth_eater',
        'electric_surge',
        'flash_fire',
        'grassy_surge',
        'intimidate',
        'iron_barbs',
        'iron_fist',
        'levitate',
        'lightning_rod',
        'motor_drive',
        'misty_surge',
        'no_guard',
        'overgrow',
        'punk_rock',
        'psychic_surge',
        'rain_dish',
        'reckless',
        'rock_head',
        'rocky_payload',
        'rough_skin',
        'sap_sipper',
        'sand_stream',
        'shadow_tag',
        'arena_trap',
        'magnet_pull',
        'sharpness',
        'skill_link',
        'snow_warning',
        'soundproof',
        'speed_boost',
        'steelworker',
        'storm_drain',
        'swarm',
        'technician',
        'torrent',
        'tough_claws',
        'transistor',
        'volt_absorb',
        'water_absorb',
        'immunity',
        'insomnia',
        'vital_spirit',
        'limber',
        'magma_armor',
        'water_veil',
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
  });
}
