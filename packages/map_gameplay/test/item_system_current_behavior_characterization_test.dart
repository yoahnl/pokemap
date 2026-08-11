import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const operations = PlayerItemOperations();

  group('current overworld item behavior', () {
    const cases = <_HealCase>[
      _HealCase(itemId: 'potion', expectedHp: 30),
      _HealCase(itemId: 'super-potion', expectedHp: 60),
      _HealCase(itemId: 'hyper-potion', expectedHp: 130),
      _HealCase(itemId: 'max-potion', expectedHp: 500),
    ];

    for (final itemCase in cases) {
      test('${itemCase.itemId} preserves its exact HP delta and consumption',
          () {
        final result = operations.useOnPartyMember(
          _state(
            itemId: itemCase.itemId,
            quantity: 2,
            currentHp: 10,
          ),
          itemId: itemCase.itemId,
          partyIndex: 0,
          maxHp: 500,
        );

        expect(result.isSuccess, isTrue);
        expect(
          result.state.party.members.single.currentHp,
          itemCase.expectedHp,
        );
        expect(result.state.bag.entries.single.quantity, 1);
      });
    }

    test('no-effect use preserves the original state and stock', () {
      final state = _state(
        itemId: 'potion',
        quantity: 2,
        currentHp: 500,
      );

      final result = operations.useOnPartyMember(
        state,
        itemId: 'potion',
        partyIndex: 0,
        maxHp: 500,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failure, PlayerItemUseFailure.noEffect);
      expect(result.state, same(state));
      expect(result.state.bag.entries.single.quantity, 2);
    });

    test('overworld item use ignores the persisted categoryId', () {
      final result = operations.useOnPartyMember(
        _state(
          itemId: 'potion',
          categoryId: 'synthetic-heals',
          quantity: 2,
          currentHp: 10,
        ),
        itemId: 'potion',
        partyIndex: 0,
        maxHp: 500,
      );

      expect(result.isSuccess, isTrue);
      expect(result.state.party.members.single.currentHp, 30);
      expect(result.state.bag.entries.single.quantity, 1);
    });

    test('MVP registry owns capture metadata and current heal values', () {
      const registry = PlayerItemEffectRegistry.mvp();

      expect(registry.effectFor('potion')?.amount, 20);
      expect(registry.effectFor('super-potion')?.amount, 50);
      expect(registry.effectFor('hyper-potion')?.amount, 120);
      expect(registry.effectFor('max-potion')?.amount, 0x7fffffff);
      expect(
        registry.effectFor('poke-ball')?.kind,
        PlayerItemEffectKind.ballMetadata,
      );
      expect(registry.effectFor('poke-ball')?.ballMultiplier, 1);
    });
  });

  group('current Bag wire behavior', () {
    test('BagEntry JSON requires categoryId', () {
      const entry = BagEntry(
        itemId: 'synthetic-potion',
        categoryId: 'synthetic-medicine',
        quantity: 2,
      );

      expect(entry.toJson(), <String, Object?>{
        'itemId': 'synthetic-potion',
        'categoryId': 'synthetic-medicine',
        'quantity': 2,
      });
    });

    test('Bag normalization identifies stacks by categoryId and itemId', () {
      const bag = Bag(
        entries: <BagEntry>[
          BagEntry(
            itemId: 'synthetic-potion',
            categoryId: 'synthetic-medicine',
            quantity: 1,
          ),
          BagEntry(
            itemId: 'synthetic-potion',
            categoryId: 'synthetic-medicine',
            quantity: 2,
          ),
          BagEntry(
            itemId: 'synthetic-potion',
            categoryId: 'synthetic-items',
            quantity: 4,
          ),
        ],
      );

      final normalized = bag.normalized();

      expect(normalized.entries, hasLength(2));
      expect(
        normalized.entries
            .singleWhere(
              (entry) => entry.categoryId == 'synthetic-medicine',
            )
            .quantity,
        3,
      );
      expect(
        normalized.entries
            .singleWhere(
              (entry) => entry.categoryId == 'synthetic-items',
            )
            .quantity,
        4,
      );
    });
  });
}

GameState _state({
  required String itemId,
  String categoryId = 'medicine',
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
        BagEntry(
          itemId: itemId,
          categoryId: categoryId,
          quantity: quantity,
        ),
      ],
    ),
  );
}

final class _HealCase {
  const _HealCase({
    required this.itemId,
    required this.expectedHp,
  });

  final String itemId;
  final int expectedHp;
}
