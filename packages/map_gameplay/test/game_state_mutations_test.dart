import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final mutations = const GameStateMutations();

  group('GameStateMutations - giveItem', () {
    test('giveItem adds a new item to an empty Bag', () {
      final initialState = GameState(
        saveId: 'test-save',
        bag: const Bag(entries: []),
        metadata: {'existing_meta': 'some_value'},
      );

      final newState = mutations.giveItem(initialState, 'potion', 2);

      // Verify item was added to the bag
      expect(newState.bag.entries.length, equals(1));
      expect(newState.bag.entries[0].itemId, equals('potion'));
      expect(newState.bag.entries[0].categoryId, equals('medicine'));
      expect(newState.bag.entries[0].quantity, equals(2));

      // Verify metadata remains unchanged
      expect(newState.metadata, equals({'existing_meta': 'some_value'}));
    });

    test('giveItem adds a new item of default category items', () {
      final initialState = GameState(
        saveId: 'test-save',
        bag: const Bag(entries: []),
      );

      final newState = mutations.giveItem(initialState, 'poke-ball', 3);

      expect(newState.bag.entries.length, equals(1));
      expect(newState.bag.entries[0].itemId, equals('poke-ball'));
      expect(newState.bag.entries[0].categoryId, equals('items'));
      expect(newState.bag.entries[0].quantity, equals(3));
    });

    test('giveItem accumulates quantity if the item already exists', () {
      final initialState = GameState(
        saveId: 'test-save',
        bag: const Bag(
          entries: [
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
          ],
        ),
      );

      final newState = mutations.giveItem(initialState, 'potion', 3);

      expect(newState.bag.entries.length, equals(1));
      expect(newState.bag.entries[0].itemId, equals('potion'));
      expect(newState.bag.entries[0].quantity, equals(5));
    });

    test('giveItem preserves other items in the Bag', () {
      final initialState = GameState(
        saveId: 'test-save',
        bag: const Bag(
          entries: [
            BagEntry(itemId: 'poke-ball', categoryId: 'items', quantity: 5),
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
          ],
        ),
      );

      final newState = mutations.giveItem(initialState, 'potion', 1);

      expect(newState.bag.entries.length, equals(2));
      
      // Entries are normalized and sorted by category then itemId
      final pokeBallEntry = newState.bag.entries.firstWhere((e) => e.itemId == 'poke-ball');
      final potionEntry = newState.bag.entries.firstWhere((e) => e.itemId == 'potion');

      expect(pokeBallEntry.quantity, equals(5));
      expect(potionEntry.quantity, equals(3));
    });

    test('giveItem does nothing (no-op) when quantity <= 0', () {
      final initialState = GameState(
        saveId: 'test-save',
        bag: const Bag(
          entries: [
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
          ],
        ),
        metadata: {'some': 'meta'},
      );

      // giveItem with quantity = 0
      final newState1 = mutations.giveItem(initialState, 'potion', 0);
      expect(newState1, same(initialState));

      // giveItem with quantity = -5
      final newState2 = mutations.giveItem(initialState, 'potion', -5);
      expect(newState2, same(initialState));
    });

    test('giveItem does nothing (no-op) when itemId is empty or whitespace-only', () {
      final initialState = GameState(
        saveId: 'test-save',
        bag: const Bag(
          entries: [
            BagEntry(itemId: 'potion', categoryId: 'medicine', quantity: 2),
          ],
        ),
      );

      final newState1 = mutations.giveItem(initialState, '', 3);
      expect(newState1, same(initialState));

      final newState2 = mutations.giveItem(initialState, '   ', 3);
      expect(newState2, same(initialState));
    });
  });
}
