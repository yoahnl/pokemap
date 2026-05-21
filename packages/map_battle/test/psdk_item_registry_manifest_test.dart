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
      final expectedPorted = <String>{
        'air_balloon',
        'apicot_berry',
        'aspear_berry',
        'assault_vest',
        'berry_juice',
        'big_root',
        'black_sludge',
        'binding_band',
        'charcoal',
        'cheri_berry',
        'chesto_berry',
        'choice_band',
        'choice_scarf',
        'choice_specs',
        'damp_rock',
        'deep_sea_scale',
        'deep_sea_tooth',
        'expert_belt',
        'ganlon_berry',
        'grip_claw',
        'heat_rock',
        'icy_rock',
        'iron_ball',
        'leftovers',
        'light_ball',
        'life_orb',
        'loaded_dice',
        'liechi_berry',
        'lum_berry',
        'mental_herb',
        'metal_powder',
        'normal_gem',
        'oran_berry',
        'pecha_berry',
        'persim_berry',
        'petaya_berry',
        'quick_powder',
        'rawst_berry',
        'salac_berry',
        'shed_shell',
        'shell_bell',
        'sitrus_berry',
        'smooth_rock',
        'starf_berry',
        'terrain_extender',
        'throat_spray',
        'thick_club',
      };

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
        'mental_herb',
        'normal_gem',
        'oran_berry',
        'persim_berry',
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
        expect(
          entry!.status,
          expectedPorted.contains(itemId)
              ? PsdkItemPortStatus.ported
              : PsdkItemPortStatus.partial,
          reason: itemId,
        );
        expect(entry.dartEffect, isNotNull, reason: itemId);
        expect(
          registry.create(itemId, owner: psdkPlayerSlot),
          isNotNull,
          reason: itemId,
        );
      }
    });

    test('ported item effects can be promoted independently from partial ones',
        () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      expect(byId['leftovers']!.status, PsdkItemPortStatus.ported);
      expect(byId['black_sludge']!.status, PsdkItemPortStatus.ported);
      expect(byId['air_balloon']!.status, PsdkItemPortStatus.ported);
      expect(registry.statusOf('LEFTOVERS'), PsdkItemPortStatus.ported);
      expect(
          registry.portedItemIds,
          containsAll(<String>[
            'leftovers',
            'black_sludge',
          ]));
      expect(registry.portedItemIds, contains('air_balloon'));
    });

    test('Lot 102 passive item modifiers are promoted item-by-item', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'choice_band',
        'choice_scarf',
        'choice_specs',
        'deep_sea_scale',
        'deep_sea_tooth',
        'expert_belt',
        'light_ball',
        'metal_powder',
        'quick_powder',
        'thick_club',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 103 active item triggers are promoted item-by-item', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'air_balloon',
        'apicot_berry',
        'aspear_berry',
        'berry_juice',
        'cheri_berry',
        'chesto_berry',
        'damp_rock',
        'ganlon_berry',
        'heat_rock',
        'icy_rock',
        'liechi_berry',
        'oran_berry',
        'pecha_berry',
        'petaya_berry',
        'rawst_berry',
        'salac_berry',
        'sitrus_berry',
        'smooth_rock',
        'starf_berry',
        'terrain_extender',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 118 assigns remaining items to convergence batches', () {
      final remaining = psdkItemEffectManifest
          .where((entry) => entry.status != PsdkItemPortStatus.ported)
          .toList(growable: false);
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final counts = <PsdkItemEffectBatch, int>{
        for (final batch in PsdkItemEffectBatch.values) batch: 0,
      };

      for (final entry in remaining) {
        counts[entry.batch] = counts[entry.batch]! + 1;
      }

      expect(
        counts.values.fold<int>(0, (total, count) => total + count),
        remaining.length,
      );
      for (final batch in PsdkItemEffectBatch.values.where(
        (batch) =>
            batch != PsdkItemEffectBatch.weatherTerrainField &&
            batch != PsdkItemEffectBatch.damageTypeStatModifiers &&
            batch != PsdkItemEffectBatch.berries &&
            batch != PsdkItemEffectBatch.heldItemLifecycleConsumption,
      )) {
        expect(counts[batch], greaterThan(0), reason: batch.name);
      }
      expect(counts[PsdkItemEffectBatch.berries], 0);
      expect(counts[PsdkItemEffectBatch.weatherTerrainField], 0);
      expect(counts[PsdkItemEffectBatch.damageTypeStatModifiers], 0);
      expect(counts[PsdkItemEffectBatch.heldItemLifecycleConsumption], 0);
      expect(byId['babiri_berry']!.batch, PsdkItemEffectBatch.berries);
      expect(
        byId['adamant_orb']!.batch,
        PsdkItemEffectBatch.damageTypeStatModifiers,
      );
      expect(
        byId['eject_button']!.batch,
        PsdkItemEffectBatch.focusEjectChoiceOrb,
      );
      expect(
        byId['electric_seed']!.batch,
        PsdkItemEffectBatch.weatherTerrainField,
      );
      expect(
        byId['mental_herb']!.batch,
        PsdkItemEffectBatch.heldItemLifecycleConsumption,
      );
    });

    test('Lot 119 damage, type, stat, and accuracy item modifiers are promoted',
        () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'adamant_orb',
        'lustrous_orb',
        'griseous_orb',
        'soul_dew',
        'eviolite',
        'wide_lens',
        'lax_incense',
        'bright_powder',
        'zoom_lens',
        'douse_drive',
        'shock_drive',
        'burn_drive',
        'chill_drive',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 120 berry consumption effects are promoted item-by-item', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'babiri_berry',
        'charti_berry',
        'chilan_berry',
        'chople_berry',
        'coba_berry',
        'colbur_berry',
        'enigma_berry',
        'haban_berry',
        'jaboca_berry',
        'kasib_berry',
        'kebia_berry',
        'kee_berry',
        'maranga_berry',
        'occa_berry',
        'passho_berry',
        'payapa_berry',
        'persim_berry',
        'rindo_berry',
        'roseli_berry',
        'rowap_berry',
        'shuca_berry',
        'tanga_berry',
        'wacan_berry',
        'yache_berry',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 124 status and mental cleanup items are promoted', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'lum_berry',
        'mental_herb',
        'persim_berry',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 121 focus survival items are promoted item-by-item', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'flame_orb',
        'focus_band',
        'focus_sash',
        'power_herb',
        'toxic_orb',
        'white_herb',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 249 existing item modifier families are promoted as complete',
        () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'adamant_orb',
        'black_belt',
        'black_glasses',
        'charcoal',
        'draco_plate',
        'dragon_fang',
        'dread_plate',
        'earth_plate',
        'fist_plate',
        'flame_plate',
        'griseous_orb',
        'hard_stone',
        'icicle_plate',
        'insect_plate',
        'iron_plate',
        'lustrous_orb',
        'magnet',
        'meadow_plate',
        'metal_coat',
        'mind_plate',
        'miracle_seed',
        'muscle_band',
        'mystic_water',
        'never_melt_ice',
        'odd_incense',
        'pixie_plate',
        'punching_glove',
        'rock_incense',
        'rose_incense',
        'sea_incense',
        'sharp_beak',
        'silk_scarf',
        'silver_powder',
        'sky_plate',
        'soft_sand',
        'soul_dew',
        'spell_tag',
        'splash_plate',
        'spooky_plate',
        'stone_plate',
        'toxic_plate',
        'twisted_spoon',
        'wave_incense',
        'wise_glasses',
        'zap_plate',
        'bug_gem',
        'dark_gem',
        'dragon_gem',
        'electric_gem',
        'fairy_gem',
        'fighting_gem',
        'fire_gem',
        'flying_gem',
        'ghost_gem',
        'grass_gem',
        'ground_gem',
        'ice_gem',
        'normal_gem',
        'poison_gem',
        'psychic_gem',
        'rock_gem',
        'steel_gem',
        'water_gem',
        'big_root',
        'iron_ball',
        'macho_brace',
        'power_band',
        'power_belt',
        'power_bracer',
        'power_lens',
        'power_weight',
        'shed_shell',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 250 reactive post-damage held items are tracked honestly', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'absorb_bulb',
        'cell_battery',
        'king_s_rock',
        'luminous_moss',
        'razor_fang',
        'rocky_helmet',
        'shell_bell',
        'snowball',
        'weakness_policy',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 251 remaining hook-compatible held items are tracked', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'poison_barb',
        'safety_goggles',
        'smoke_ball',
        'sticky_barb',
        'throat_spray',
        'mirror_herb',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 252 switch, repeat, and special berry items are tracked', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'berserk_gene',
        'lansat_berry',
        'leppa_berry',
        'metronome',
        'micle_berry',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('Lot 256 duration and multi-hit helper items are strict', () {
      final byId = {
        for (final entry in psdkItemEffectManifest) entry.itemId: entry,
      };
      final registry = ItemEffectRegistry();

      for (final itemId in <String>[
        'binding_band',
        'grip_claw',
        'loaded_dice',
      ]) {
        expect(byId[itemId]!.status, PsdkItemPortStatus.ported, reason: itemId);
        expect(registry.statusOf(itemId), PsdkItemPortStatus.ported,
            reason: itemId);
        expect(registry.create(itemId, owner: psdkPlayerSlot), isNotNull,
            reason: itemId);
      }
    });

    test('item lifecycle snapshots distinguish held, consumed, and removed',
        () {
      final held = BattleItemLifecycleSnapshot.fromBattler(
        _combatant(heldItemId: 'leftovers'),
      );
      final consumed = BattleItemLifecycleSnapshot.fromBattler(
        _combatant(
          heldItemId: null,
          consumedItemId: 'oran_berry',
          itemConsumed: true,
        ),
      );
      final knockedOff = BattleItemLifecycleSnapshot.removed(
        itemId: 'choice_scarf',
        reason: BattleItemRemovalReason.knockedOff,
      );

      expect(held.state, BattleItemLifecycleState.held);
      expect(held.activeItemId, 'leftovers');
      expect(held.hasActiveHeldEffect, isTrue);
      expect(held.isRecyclable, isFalse);

      expect(consumed.state, BattleItemLifecycleState.consumed);
      expect(consumed.activeItemId, isNull);
      expect(consumed.lastKnownItemId, 'oran_berry');
      expect(consumed.isRecyclable, isTrue);

      expect(knockedOff.state, BattleItemLifecycleState.removed);
      expect(knockedOff.removalReason, BattleItemRemovalReason.knockedOff);
      expect(knockedOff.lastKnownItemId, 'choice_scarf');
      expect(knockedOff.isRecyclable, isFalse);
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

PsdkBattleCombatant _combatant({
  String? heldItemId,
  String? consumedItemId,
  bool itemConsumed = false,
}) {
  final state = PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: PsdkBattleCombatantSetup(
        id: 'player',
        speciesId: 'player',
        displayName: 'player',
        level: 20,
        maxHp: 100,
        currentHp: 100,
        types: const PsdkBattleTypes(primary: 'normal'),
        stats: const PsdkBattleStats(
          attack: 50,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: 50,
        ),
        heldItemId: heldItemId,
        consumedItemId: consumedItemId,
        itemConsumed: itemConsumed,
        moves: <PsdkBattleMoveData>[_move()],
      ),
      opponent: PsdkBattleCombatantSetup(
        id: 'opponent',
        speciesId: 'opponent',
        displayName: 'opponent',
        level: 20,
        maxHp: 100,
        currentHp: 100,
        types: const PsdkBattleTypes(primary: 'normal'),
        stats: const PsdkBattleStats(
          attack: 50,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: 50,
        ),
        moves: <PsdkBattleMoveData>[_move()],
      ),
      rngSeeds: const BattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ).psdkSeeds,
    ).psdkSetup,
  );
  return state.battlerAt(psdkPlayerSlot);
}

PsdkBattleMoveData _move() {
  return PsdkBattleMoveData(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'tackle',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
