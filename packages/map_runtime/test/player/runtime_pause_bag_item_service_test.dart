import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('pause bag item use commits one effect and consumes exactly one item',
      () async {
    var state = const GameState(
      saveId: 'bag-use',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'lead',
            natureId: 'hardy',
            abilityId: 'steadfast',
            currentHp: 5,
          ),
        ],
      ),
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'potion',
            categoryId: 'medicine',
            quantity: 2,
          ),
          BagEntry(
            itemId: 'harbor-pass',
            categoryId: 'key-items',
            quantity: 1,
          ),
        ],
      ),
    );
    final commits = <GameState>[];
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (next) async {
        commits.add(next);
        state = next;
      },
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{0: 30},
      ),
    );
    addTearDown(controller.dispose);

    final used = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'potion',
        partyTargetId: 'party.0',
      ),
    );

    expect(used.status, RuntimePlayerPauseCommandStatus.accepted);
    expect(commits, hasLength(1));
    expect(state.party.members.single.currentHp, 25);
    expect(
      state.bag.entries
          .firstWhere((entry) => entry.itemId == 'potion')
          .quantity,
      1,
    );

    final refused = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'harbor-pass',
        partyTargetId: 'party.0',
      ),
    );

    expect(refused.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(commits, hasLength(1));
    expect(
      state.bag.entries
          .firstWhere((entry) => entry.itemId == 'harbor-pass')
          .quantity,
      1,
    );
  });

  test('pause bag does not consume an item when it would have no effect',
      () async {
    const state = GameState(
      saveId: 'bag-no-effect',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'lead',
            natureId: 'hardy',
            abilityId: 'steadfast',
            currentHp: 30,
          ),
        ],
      ),
      bag: Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'potion',
            categoryId: 'medicine',
            quantity: 1,
          ),
        ],
      ),
    );
    final controller = PlayerServiceRuntimeController.contextual(
      currentGameState: () => state,
      commitAndSave: (_) async => fail('No mutation should be committed.'),
      setInputLocked: (_) {},
      loadRecoveryCaps: (_) async => const RuntimePlayerServiceRecoveryCaps(
        maxHpByPartyIndex: <int, int>{0: 30},
      ),
    );
    addTearDown(controller.dispose);

    final result = await controller.useBagItemOutsideBattle(
      const RuntimePlayerPauseCommand.useBagItem(
        itemTargetId: 'potion',
        partyTargetId: 'party.0',
      ),
    );

    expect(result.status, RuntimePlayerPauseCommandStatus.unavailable);
    expect(result.safeMessage, contains('aucun effet'));
    expect(state.bag.entries.single.quantity, 1);
  });
}
