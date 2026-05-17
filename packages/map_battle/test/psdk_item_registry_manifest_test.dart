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
        'assault_vest',
        'black_sludge',
        'choice_band',
        'choice_scarf',
        'choice_specs',
        'deep_sea_scale',
        'deep_sea_tooth',
        'expert_belt',
        'leftovers',
        'light_ball',
        'metal_powder',
        'quick_powder',
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
      expect(byId['air_balloon']!.status, PsdkItemPortStatus.partial);
      expect(registry.statusOf('LEFTOVERS'), PsdkItemPortStatus.ported);
      expect(
          registry.portedItemIds,
          containsAll(<String>[
            'leftovers',
            'black_sludge',
          ]));
      expect(registry.partialItemIds, contains('air_balloon'));
      expect(registry.portedItemIds, isNot(contains('air_balloon')));
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
