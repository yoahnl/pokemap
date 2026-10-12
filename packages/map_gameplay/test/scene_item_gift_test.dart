import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('gift refusal retains the bag and retry delivers after space is freed',
      () {
    final full = GameState(
      saveId: 'gift',
      bag: const Bag(entries: [
        BagEntry(itemId: 'tm23', quantity: maximumBagEntryQuantity),
      ]),
      trainerProfile:
          const TrainerProfile(name: 'Johto', badgeIds: ['mineral']),
    );
    final command =
        SceneGiveItemInteractiveCommand(itemId: 'tm23', quantity: 1);
    final blocked = executeSceneItemGift(command: command, gameState: full);
    expect(blocked.outcome.name, 'bagFull');
    expect(blocked.gameState, full);
    final freed = full.copyWith(
      bag: const BagOperations()
          .take(BagTakeRequest(bag: full.bag, itemId: 'tm23', quantity: 1))
          .bag,
    );
    final received = executeSceneItemGift(command: command, gameState: freed);
    expect(received.outcome.name, 'received');
    expect(received.gameState.bag, full.bag);
    expect(received.gameState.trainerProfile.badgeIds, ['mineral']);
  });

  test('gift adds the entire quantity or adds nothing', () {
    final state = GameState(
      saveId: 'gift',
      bag: const Bag(entries: [
        BagEntry(itemId: 'potion', quantity: maximumBagEntryQuantity - 1),
      ]),
    );
    final result = executeSceneItemGift(
      command: SceneGiveItemInteractiveCommand(itemId: 'potion', quantity: 2),
      gameState: state,
    );
    expect(result.outcome.name, 'bagFull');
    expect(result.gameState, state);
  });
}
