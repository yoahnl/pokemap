import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/data/generated/psdk_item_effect_manifest.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK item effect manifest', () {
    test('tracks PSDK item registrations and local held-item checks', () {
      final ids = psdkItemEffectManifest.map((entry) => entry.itemId);

      expect(psdkItemEffectManifest.length, 183);
      expect(ids.toSet(), hasLength(psdkItemEffectManifest.length));
      expect(
        ids,
        containsAll(<String>[
          'leftovers',
          'black_sludge',
          'air_balloon',
          'choice_band',
          'life_orb',
          'loaded_dice',
          'terrain_extender',
          'damp_rock',
        ]),
      );
    });

    test('known local items are marked and hydrate through the registry', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'air_balloon',
        'black_sludge',
        'big_root',
        'binding_band',
        'chesto_berry',
        'choice_band',
        'choice_scarf',
        'choice_specs',
        'charcoal',
        'grip_claw',
        'liechi_berry',
        'iron_ball',
        'leftovers',
        'life_orb',
        'loaded_dice',
        'lum_berry',
        'normal_gem',
        'oran_berry',
        'shed_shell',
        'sitrus_berry',
        'terrain_extender',
        'damp_rock',
        'heat_rock',
        'smooth_rock',
        'icy_rock',
      ]) {
        final entry = byId[itemId];

        expect(entry, isNotNull, reason: itemId);
        expect(entry!.status, PsdkItemPortStatus.partial, reason: itemId);
        expect(entry.dartEffect, isNotNull, reason: itemId);
        expect(
          registry.create(itemId, owner: psdkPlayerSlot),
          isNotNull,
          reason: itemId,
        );
      }
    });

    test('unknown items stay explicit and inert', () {
      final registry = ItemEffectRegistry();

      expect(registry.registeredItemIds, contains('leftovers'));
      expect(
          registry.registeredItemIds, isNot(contains('totally_unknown_item')));
      expect(
        registry.create('totally_unknown_item', owner: psdkPlayerSlot),
        isNull,
      );
    });
  });
}
