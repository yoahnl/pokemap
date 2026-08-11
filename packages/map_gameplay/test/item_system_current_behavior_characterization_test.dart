import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/items/item_catalog_snapshot.dart';
import 'package:map_gameplay/src/items/mvp_item_catalog.dart';
import 'package:map_gameplay/src/items/player_item_use_service.dart';
import 'package:map_gameplay/src/player_item_effects.dart';
import 'package:test/test.dart';

void main() {
  final snapshot = ItemCatalogSnapshot.fromCatalog(mvpItemCatalog);
  final service = PlayerItemUseService(snapshot: snapshot);

  group('canonical overworld item behavior', () {
    const cases = <_HealCase>[
      _HealCase(itemId: 'potion', expectedHp: 30),
      _HealCase(itemId: 'super-potion', expectedHp: 60),
      _HealCase(itemId: 'hyper-potion', expectedHp: 130),
      _HealCase(itemId: 'max-potion', expectedHp: 500),
    ];

    for (final itemCase in cases) {
      test('${itemCase.itemId} preserves its exact HP delta and consumption',
          () {
        final result = service.use(
          PlayerItemUseRequest(
            state: _state(
              itemId: itemCase.itemId,
              quantity: 2,
              currentHp: 10,
            ),
            itemId: itemCase.itemId,
            context: ProjectItemUseContext.overworld,
            partyIndex: 0,
            maxHp: 500,
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(result.state.party.members.single.currentHp, itemCase.expectedHp);
        expect(result.state.bag.entries.single.quantity, 1);
      });
    }

    test('no-effect use preserves the original state and stock', () {
      final state = _state(itemId: 'potion', quantity: 2, currentHp: 500);

      final result = service.use(
        PlayerItemUseRequest(
          state: state,
          itemId: 'potion',
          context: ProjectItemUseContext.overworld,
          partyIndex: 0,
          maxHp: 500,
        ),
      );

      expect(result.failure, PlayerItemUseFailure.noEffect);
      expect(result.state, same(state));
      expect(result.state.bag.entries.single.quantity, 2);
    });

    test('catalog snapshot owns capture metadata and heal values', () {
      final potion = snapshot.definitionFor('potion')!;
      final pokeBall = snapshot.definitionFor('poke-ball')!;

      expect(
        potion.uses.single.effect,
        const ProjectItemEffectDefinition.healHp(
          mode: ProjectItemAmountMode.flat,
          amount: 20,
        ),
      );
      expect(pokeBall.capture?.rateNumerator, 1);
      expect(pokeBall.capture?.rateDenominator, 1);
    });
  });

  group('canonical Bag wire behavior', () {
    test('BagEntry JSON contains only itemId and quantity', () {
      const entry = BagEntry(itemId: 'synthetic-potion', quantity: 2);

      expect(entry.toJson(), <String, Object?>{
        'itemId': 'synthetic-potion',
        'quantity': 2,
      });
    });

    test('Bag normalization identifies stacks only by itemId', () {
      const bag = Bag(
        entries: <BagEntry>[
          BagEntry(itemId: 'synthetic-potion', quantity: 1),
          BagEntry(itemId: 'synthetic-potion', quantity: 2),
        ],
      );

      expect(bag.normalized().entries, const <BagEntry>[
        BagEntry(itemId: 'synthetic-potion', quantity: 3),
      ]);
    });
  });
}

GameState _state({
  required String itemId,
  required int quantity,
  required int currentHp,
}) {
  return GameState(
    saveId: 'itm-001-characterization-save',
    currentMapId: 'itm-001-characterization-map',
    party: PlayerParty(
      members: <PlayerPokemon>[
        PlayerPokemon(
          speciesId: 'itm-001-characterization-species',
          level: 10,
          natureId: 'hardy',
          abilityId: 'overgrow',
          knownMoveIds: const <String>['tackle'],
          currentHp: currentHp,
        ),
      ],
    ),
    bag: Bag(
      entries: <BagEntry>[
        BagEntry(itemId: itemId, quantity: quantity),
      ],
    ),
  );
}

final class _HealCase {
  const _HealCase({required this.itemId, required this.expectedHp});

  final String itemId;
  final int expectedHp;
}
