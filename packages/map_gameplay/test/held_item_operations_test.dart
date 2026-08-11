import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const operations = HeldItemOperations();

  test('equips one item from the Bag', () {
    final result = operations.equip(
      _state(bagEntries: const <BagEntry>[
        BagEntry(itemId: 'leftovers-charm', quantity: 2),
      ]),
      partyIndex: 0,
      itemId: 'leftovers-charm',
    );

    expect(result.status, HeldItemTransferStatus.equipped);
    expect(result.state.party.members.single.heldItemId, 'leftovers-charm');
    expect(result.state.bag.entries.single.quantity, 1);
  });

  test('swaps held items without losing either quantity', () {
    final result = operations.equip(
      _state(
        heldItemId: 'oran-charm',
        bagEntries: const <BagEntry>[
          BagEntry(itemId: 'leftovers-charm', quantity: 1),
        ],
      ),
      partyIndex: 0,
      itemId: 'leftovers-charm',
    );

    expect(result.status, HeldItemTransferStatus.swapped);
    expect(result.previousHeldItemId, 'oran-charm');
    expect(result.state.party.members.single.heldItemId, 'leftovers-charm');
    expect(
      result.state.bag.entries,
      const <BagEntry>[BagEntry(itemId: 'oran-charm', quantity: 1)],
    );
  });

  test('unequips into the Bag and survives save load', () {
    final result = operations.unequip(
      _state(heldItemId: 'leftovers-charm'),
      partyIndex: 0,
    );
    final reloaded = GameState.fromJson(
      jsonDecode(jsonEncode(result.state.toJson())) as Map<String, dynamic>,
    );

    expect(result.status, HeldItemTransferStatus.unequipped);
    expect(reloaded.party.members.single.heldItemId, isEmpty);
    expect(
      reloaded.bag.entries,
      const <BagEntry>[BagEntry(itemId: 'leftovers-charm', quantity: 1)],
    );
  });

  test('invalid target and absent item never mutate', () {
    final state = _state();
    final invalidTarget = operations.equip(
      state,
      partyIndex: 1,
      itemId: 'leftovers-charm',
    );
    final missing = operations.equip(
      state,
      partyIndex: 0,
      itemId: 'leftovers-charm',
    );

    expect(invalidTarget.failure, HeldItemTransferFailure.invalidTarget);
    expect(invalidTarget.state, same(state));
    expect(missing.failure, HeldItemTransferFailure.itemMissing);
    expect(missing.state, same(state));
  });

  test('swap overflow and duplicate equip preserve the exact state', () {
    final overflow = _state(
      heldItemId: 'oran-charm',
      bagEntries: const <BagEntry>[
        BagEntry(itemId: 'leftovers-charm', quantity: 1),
        BagEntry(itemId: 'oran-charm', quantity: maximumBagEntryQuantity),
      ],
    );
    final duplicate = _state(
      heldItemId: 'leftovers-charm',
      bagEntries: const <BagEntry>[
        BagEntry(itemId: 'leftovers-charm', quantity: 1),
      ],
    );

    final overflowResult = operations.equip(
      overflow,
      partyIndex: 0,
      itemId: 'leftovers-charm',
    );
    final duplicateResult = operations.equip(
      duplicate,
      partyIndex: 0,
      itemId: 'leftovers-charm',
    );

    expect(overflowResult.failure, HeldItemTransferFailure.quantityOverflow);
    expect(overflowResult.state, same(overflow));
    expect(duplicateResult.failure, HeldItemTransferFailure.alreadyEquipped);
    expect(duplicateResult.state, same(duplicate));
  });
}

GameState _state({
  String heldItemId = '',
  List<BagEntry> bagEntries = const <BagEntry>[],
}) {
  return GameState(
    saveId: 'held-items',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'hardy',
          abilityId: 'overgrow',
          heldItemId: heldItemId,
          currentHp: 20,
        ),
      ],
    ),
    bag: Bag(entries: bagEntries),
  );
}
