import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  PlayerItemUseResult use({
    Map<String, int>? pp = const {
      'tackle': 30,
      'growl': 0,
      'rest': 5,
      'foreign': 1
    },
    Map<String, int> maxima = const {'tackle': 35, 'growl': 40, 'rest': 5},
    ProjectItemUseContext context = ProjectItemUseContext.overworld,
    String mode = 'flat',
    int quantity = 2,
  }) {
    final effect = ProjectItemEffectDefinition.fromJson({
      'kind': 'restore_pp',
      'mode': mode,
      if (mode == 'flat') 'amount': 10,
      'scope': 'all_moves',
    });
    final snapshot = ItemCatalogSnapshot.fromCatalog(ProjectItemCatalog(
      schemaVersion: 1,
      entries: [
        ProjectItemDefinition(
          id: 'elixir',
          displayName: 'Élixir',
          pocketId: 'medicine',
          uses: [
            ProjectItemUseDefinition(
              contexts: {
                ProjectItemUseContext.overworld,
                ProjectItemUseContext.battle
              },
              target: ProjectItemTargetKind.partyMember,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: effect,
            )
          ],
        )
      ],
    ));
    return PlayerItemUseService(snapshot: snapshot).use(PlayerItemUseRequest(
      state: GameState(
          saveId: 'all-pp',
          bag: Bag(entries: [
            if (quantity > 0) BagEntry(itemId: 'elixir', quantity: quantity)
          ]),
          party: PlayerParty(members: [
            PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              currentHp: 0,
              knownMoveIds: ['tackle', 'growl', 'rest'],
              currentPpByMoveId: pp,
            )
          ])),
      itemId: 'elixir',
      context: context,
      partyIndex: 0,
      maxHp: 40,
      maxPpByMoveId: maxima,
    ));
  }

  for (final context in ProjectItemUseContext.values) {
    test(
        'restores every valid move once and preserves unrelated state in ${context.name}',
        () {
      final result = use(context: context);
      expect(result.isSuccess, isTrue);
      expect(result.state.party.members.single.currentPpByMoveId,
          {'tackle': 35, 'growl': 10, 'rest': 5, 'foreign': 1});
      expect(result.state.party.members.single.currentHp, 0);
      expect(result.state.bag.entries.single.quantity, 1);
      expect(result.consumptionReceipt!.quantity, 1);
    });
  }
  test('full restoration caps each move at its own maximum', () {
    final result = use(mode: 'full');
    expect(result.isSuccess, isTrue);
    expect(result.state.party.members.single.currentPpByMoveId,
        {'tackle': 35, 'growl': 40, 'rest': 5, 'foreign': 1});
  });
  test('absent slots and invalid maxima do not acquire PP', () {
    final result = use(
        pp: {'tackle': 1, 'rest': 2},
        maxima: {'tackle': 35, 'growl': 40, 'rest': 0});
    expect(result.isSuccess, isTrue);
    expect(result.state.party.members.single.currentPpByMoveId,
        {'tackle': 11, 'rest': 2});
  });
  test('all-full, absent PP and an empty bag refuse without consumption', () {
    for (final result in [
      use(pp: {'tackle': 35, 'growl': 40, 'rest': 5}),
      use(pp: null),
      use(quantity: 0)
    ]) {
      expect(result.isSuccess, isFalse);
      expect(result.consumptionReceipt, isNull);
      expect(
          result.state.bag.entries.isEmpty ||
              result.state.bag.entries.single.quantity == 2,
          isTrue);
    }
  });
}
