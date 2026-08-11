import 'package:map_core/map_core.dart';
import 'package:map_gameplay/src/items/bag_operation_result.dart';
import 'package:map_gameplay/src/items/item_catalog_snapshot.dart';
import 'package:map_gameplay/src/items/mvp_item_catalog.dart';
import 'package:map_gameplay/src/items/player_item_use_service.dart';
import 'package:map_gameplay/src/player_item_effects.dart';
import 'package:test/test.dart';

void main() {
  final catalog = ProjectItemCatalog(
    schemaVersion: 1,
    entries: [
      ...mvpItemCatalog.entries,
      const ProjectItemDefinition(
        id: 'field-tonic',
        displayName: 'Field Tonic',
        pocketId: 'medicine',
        uses: [
          ProjectItemUseDefinition(
            contexts: {ProjectItemUseContext.overworld},
            target: ProjectItemTargetKind.partyMember,
            consumption: ProjectItemConsumptionPolicy.onApplied,
            effect: ProjectItemEffectDefinition.healHp(
              mode: ProjectItemAmountMode.flat,
              amount: 5,
            ),
          ),
        ],
      ),
    ],
  ).normalized();
  final service = PlayerItemUseService(
    snapshot: ItemCatalogSnapshot.fromCatalog(catalog),
  );

  PlayerPokemon pokemon({
    int currentHp = 10,
    String statusId = '',
    List<String> knownMoveIds = const ['tackle'],
    Map<String, int>? currentPpByMoveId,
  }) {
    return PlayerPokemon(
      speciesId: 'bulbasaur',
      level: 5,
      natureId: 'hardy',
      abilityId: 'overgrow',
      currentHp: currentHp,
      statusId: statusId,
      knownMoveIds: knownMoveIds,
      currentPpByMoveId: currentPpByMoveId,
    );
  }

  GameState stateFor(String itemId, PlayerPokemon target, {int quantity = 2}) {
    return GameState(
      saveId: 'item-use',
      party: PlayerParty(members: [target]),
      bag: Bag(entries: [BagEntry(itemId: itemId, quantity: quantity)]),
    );
  }

  PlayerItemUseRequest request(
    GameState state,
    String itemId, {
    ProjectItemUseContext context = ProjectItemUseContext.overworld,
    int maxHp = 50,
    String? moveId,
    Map<String, int> maxPpByMoveId = const {},
  }) {
    return PlayerItemUseRequest(
      state: state,
      itemId: itemId,
      context: context,
      partyIndex: 0,
      maxHp: maxHp,
      moveId: moveId,
      maxPpByMoveId: maxPpByMoveId,
    );
  }

  group('PlayerItemUseService healing', () {
    test('applies flat healing and returns the exact consumption receipt', () {
      final initial = stateFor('potion', pokemon(currentHp: 10));

      final result = service.use(request(initial, 'potion'));

      expect(result.isSuccess, isTrue);
      expect(result.state.party.members.single.currentHp, 30);
      expect(result.state.bag.entries.single.quantity, 1);
      expect(
        result.consumptionReceipt,
        const ItemConsumptionReceipt(
          itemId: 'potion',
          quantity: 1,
          quantityBefore: 2,
          quantityAfter: 1,
          reason: ItemConsumptionReason.appliedEffect,
        ),
      );
    });

    test('applies full healing from the canonical effect mode', () {
      final initial = stateFor('max-potion', pokemon(currentHp: 3));

      final result = service.use(request(initial, 'max-potion', maxHp: 73));

      expect(result.state.party.members.single.currentHp, 73);
      expect(result.state.bag.entries.single.quantity, 1);
    });
  });

  group('PlayerItemUseService status and revive', () {
    test('applies listed and any-status cures', () {
      final poisoned = stateFor(
        'antidote',
        pokemon(statusId: 'poison'),
      );
      final burned = stateFor(
        'full-heal',
        pokemon(statusId: 'burn'),
      );

      final listed = service.use(request(poisoned, 'antidote'));
      final any = service.use(request(burned, 'full-heal'));

      expect(listed.state.party.members.single.statusId, isEmpty);
      expect(any.state.party.members.single.statusId, isEmpty);
    });

    test('revives a fainted target using the canonical ratio', () {
      final initial = stateFor('revive', pokemon(currentHp: 0));

      final result = service.use(request(initial, 'revive', maxHp: 51));

      expect(result.state.party.members.single.currentHp, 26);
      expect(result.state.bag.entries.single.quantity, 1);
    });
  });

  test('restores PP only on the selected known move', () {
    final initial = stateFor(
      'ether',
      pokemon(
        knownMoveIds: const ['tackle', 'growl'],
        currentPpByMoveId: const {'tackle': 2, 'growl': 4},
      ),
    );

    final result = service.use(
      request(
        initial,
        'ether',
        moveId: 'tackle',
        maxPpByMoveId: const {'tackle': 35, 'growl': 40},
      ),
    );

    expect(result.state.party.members.single.currentPpByMoveId, {
      'tackle': 12,
      'growl': 4,
    });
  });

  group('PlayerItemUseService failures', () {
    test('rejects the wrong target without consuming', () {
      final initial = stateFor('revive', pokemon(currentHp: 10));

      final result = service.use(request(initial, 'revive'));

      expect(result.failure, PlayerItemUseFailure.wrongTarget);
      expect(result.state, same(initial));
      expect(result.consumptionReceipt, isNull);
    });

    test('rejects a context absent from the canonical use definition', () {
      final initial = stateFor('field-tonic', pokemon(currentHp: 10));

      final result = service.use(
        request(
          initial,
          'field-tonic',
          context: ProjectItemUseContext.battle,
        ),
      );

      expect(result.failure, PlayerItemUseFailure.unavailableInContext);
      expect(result.state, same(initial));
    });

    test('rejects no-effect and unknown definitions without consuming', () {
      final fullHp = stateFor('potion', pokemon(currentHp: 50));
      final unknown = stateFor('mystery-item', pokemon(currentHp: 10));

      final noEffect = service.use(request(fullHp, 'potion'));
      final missing = service.use(request(unknown, 'mystery-item'));

      expect(noEffect.failure, PlayerItemUseFailure.noEffect);
      expect(missing.failure, PlayerItemUseFailure.unknownDefinition);
      expect(noEffect.state, same(fullHp));
      expect(missing.state, same(unknown));
    });
  });
}
