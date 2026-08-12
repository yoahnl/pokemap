import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const service = PokemonMoveMachineService();
  final itemCatalog = ItemCatalogSnapshot.fromCatalog(
    const ProjectItemCatalog(
      schemaVersion: 1,
      entries: <ProjectItemDefinition>[
        ProjectItemDefinition(
          id: 'tm-protect',
          displayName: 'TM Protect',
          pocketId: 'machines',
        ),
        ProjectItemDefinition(
          id: 'hm-surf',
          displayName: 'HM Surf',
          pocketId: 'machines',
        ),
        ProjectItemDefinition(
          id: 'vault-key-tm',
          displayName: 'Vault Key TM',
          pocketId: 'key-items',
          tags: <String>{'key-item'},
        ),
      ],
    ),
  );
  const machine = PokemonMoveMachineCandidate(
    itemId: 'tm-protect',
    moveId: 'protect',
    maxPp: 10,
    consumable: true,
  );

  test('learns into a free slot, initializes PP, and consumes one TM', () {
    final result = service.apply(
      _state(moves: const <String>['tackle', 'growl'], quantity: 2),
      partyIndex: 0,
      candidate: machine,
      decision: const PokemonMoveMachineDecision.learn(),
      itemCatalog: itemCatalog,
    );

    expect(result.status, PokemonMoveMachineUseStatus.learned);
    expect(
      result.state.party.members.single.knownMoveIds,
      <String>['tackle', 'growl', 'protect'],
    );
    expect(
      result.state.party.members.single.currentPpByMoveId,
      <String, int>{'tackle': 30, 'growl': 40, 'protect': 10},
    );
    expect(result.state.bag.entries.single.quantity, 1);
    expect(
      result.consumptionReceipt,
      const ItemConsumptionReceipt(
        itemId: 'tm-protect',
        quantity: 1,
        quantityBefore: 2,
        quantityAfter: 1,
        reason: ItemConsumptionReason.appliedEffect,
      ),
    );
    final reloaded = GameState.fromJson(
      jsonDecode(jsonEncode(result.state.toJson())) as Map<String, dynamic>,
    );
    expect(reloaded.party.members.single.knownMoveIds.last, 'protect');
    expect(reloaded.party.members.single.currentPpByMoveId!['protect'], 10);
    expect(reloaded.bag.entries.single.quantity, 1);
  });

  test('requires an exact replacement when the moveset is full', () {
    final state = _state(
      moves: const <String>['tackle', 'growl', 'vine-whip', 'sleep-powder'],
    );

    final pending = service.apply(
      state,
      partyIndex: 0,
      candidate: machine,
      decision: const PokemonMoveMachineDecision.learn(),
      itemCatalog: itemCatalog,
    );
    final replaced = service.apply(
      state,
      partyIndex: 0,
      candidate: machine,
      decision: const PokemonMoveMachineDecision.replace(
        expectedMoveId: 'growl',
      ),
      itemCatalog: itemCatalog,
    );

    expect(
      pending.status,
      PokemonMoveMachineUseStatus.replacementRequired,
    );
    expect(pending.state, same(state));
    expect(replaced.status, PokemonMoveMachineUseStatus.replaced);
    expect(
      replaced.state.party.members.single.knownMoveIds,
      <String>['tackle', 'protect', 'vine-whip', 'sleep-powder'],
    );
    expect(
      replaced.state.party.members.single.currentPpByMoveId,
      isNot(contains('growl')),
    );
    expect(
      replaced.state.party.members.single.currentPpByMoveId!['protect'],
      10,
    );
    expect(replaced.state.bag.entries, isEmpty);
  });

  test('decline and invalid replacement preserve both item and Pokemon', () {
    final state = _state(
      moves: const <String>['tackle', 'growl', 'vine-whip', 'sleep-powder'],
    );

    final declined = service.apply(
      state,
      partyIndex: 0,
      candidate: machine,
      decision: const PokemonMoveMachineDecision.decline(),
      itemCatalog: itemCatalog,
    );
    final stale = service.apply(
      state,
      partyIndex: 0,
      candidate: machine,
      decision: const PokemonMoveMachineDecision.replace(
        expectedMoveId: 'ember',
      ),
      itemCatalog: itemCatalog,
    );

    expect(declined.status, PokemonMoveMachineUseStatus.declined);
    expect(declined.state, same(state));
    expect(stale.status, PokemonMoveMachineUseStatus.failed);
    expect(stale.failure, PokemonMoveMachineUseFailure.invalidReplacement);
    expect(stale.state, same(state));
  });

  test('HM is reusable while duplicate learning has no effect', () {
    const hm = PokemonMoveMachineCandidate(
      itemId: 'hm-surf',
      moveId: 'surf',
      maxPp: 15,
      consumable: false,
    );
    final first = service.apply(
      _state(moves: const <String>['tackle'], itemId: 'hm-surf'),
      partyIndex: 0,
      candidate: hm,
      decision: const PokemonMoveMachineDecision.learn(),
      itemCatalog: itemCatalog,
    );
    final duplicate = service.apply(
      first.state,
      partyIndex: 0,
      candidate: hm,
      decision: const PokemonMoveMachineDecision.learn(),
      itemCatalog: itemCatalog,
    );

    expect(first.status, PokemonMoveMachineUseStatus.learned);
    expect(first.state.bag.entries.single.quantity, 1);
    expect(first.consumptionReceipt, isNull);
    expect(duplicate.status, PokemonMoveMachineUseStatus.failed);
    expect(duplicate.failure, PokemonMoveMachineUseFailure.alreadyKnown);
    expect(duplicate.state, same(first.state));
  });

  test('a consumable machine cannot consume a key item', () {
    const keyMachine = PokemonMoveMachineCandidate(
      itemId: 'vault-key-tm',
      moveId: 'protect',
      maxPp: 10,
      consumable: true,
    );
    final state = _state(
      moves: const <String>['tackle'],
      itemId: 'vault-key-tm',
    );

    final result = service.apply(
      state,
      partyIndex: 0,
      candidate: keyMachine,
      decision: const PokemonMoveMachineDecision.learn(),
      itemCatalog: itemCatalog,
    );

    expect(result.failure, PokemonMoveMachineUseFailure.protectedKeyItem);
    expect(result.state, same(state));
    expect(result.consumptionReceipt, isNull);
  });
}

GameState _state({
  required List<String> moves,
  int quantity = 1,
  String itemId = 'tm-protect',
}) {
  return GameState(
    saveId: 'move-machine',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'sproutle',
          natureId: 'hardy',
          abilityId: 'overgrow',
          currentHp: 20,
          knownMoveIds: moves,
          currentPpByMoveId: <String, int>{
            for (final moveId in moves)
              moveId: switch (moveId) {
                'tackle' => 30,
                'growl' => 40,
                'vine-whip' => 25,
                'sleep-powder' => 15,
                _ => 5,
              },
          },
        ),
      ],
    ),
    bag: Bag(
      entries: <BagEntry>[
        BagEntry(
          itemId: itemId,
          quantity: quantity,
        ),
      ],
    ),
  );
}
