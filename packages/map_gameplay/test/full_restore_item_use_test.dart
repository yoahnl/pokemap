import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('battle confusion is explicit and cannot be injected outside battle',
      () {
    final initial = _state(50, '');
    for (final context in ProjectItemUseContext.values) {
      final result = _service().use(PlayerItemUseRequest(
        state: initial,
        itemId: 'full-restore',
        context: context,
        partyIndex: 0,
        maxHp: 50,
        targetHasBattleConfusion: true,
      ));
      if (context == ProjectItemUseContext.battle) {
        expect(result.isSuccess, isTrue);
        expect(result.state.bag.entries.single.quantity, 1);
        expect(result.state.party, initial.party);
      } else {
        expect(result.failure, PlayerItemUseFailure.invalidRequest);
        expect(result.state, initial);
        expect(result.consumptionReceipt, isNull);
      }
    }
  });
  for (final input in [(7, 'burn'), (50, 'sleep'), (2, '')]) {
    test('full restore applies HP/status once for ${input.$1}/${input.$2}', () {
      final initial = _state(input.$1, input.$2);
      final result = _service().use(_request(initial));
      expect(result.isSuccess, isTrue);
      final target = result.state.party.members.single;
      expect(target.currentHp, 50);
      expect(target.statusId, isEmpty);
      expect(target.currentPpByMoveId, {'tackle': 3});
      expect(result.state.bag.entries.single.quantity, 1);
      expect(result.consumptionReceipt?.quantity, 1);
      expect(initial.party.members.single.currentHp, input.$1);
      expect(initial.party.members.single.statusId, input.$2);
      expect(initial.bag.entries.single.quantity, 2);
    });
  }
  for (final input in [
    (50, '', PlayerItemUseFailure.noEffect),
    (0, 'poison', PlayerItemUseFailure.wrongTarget)
  ]) {
    test('full restore rejects ${input.$1}/${input.$2} without consumption',
        () {
      final initial = _state(input.$1, input.$2);
      final result = _service().use(_request(initial));
      expect(result.failure, input.$3);
      expect(result.state, initial);
      expect(result.consumptionReceipt, isNull);
    });
  }
}

PlayerItemUseService _service() => PlayerItemUseService(
      snapshot: ItemCatalogSnapshot.fromCatalog(ProjectItemCatalog(
        schemaVersion: 1,
        entries: [
          ProjectItemDefinition(
            id: 'full-restore',
            displayName: 'Soin Total',
            pocketId: 'medicine',
            uses: [
              ProjectItemUseDefinition(
                contexts: {
                  ProjectItemUseContext.overworld,
                  ProjectItemUseContext.battle
                },
                target: ProjectItemTargetKind.partyMember,
                consumption: ProjectItemConsumptionPolicy.onApplied,
                effect: const ProjectItemEffectDefinition.fullRestore(),
              )
            ],
          )
        ],
      )),
    );
GameState _state(int hp, String status) => GameState(
      saveId: 'full-restore-test',
      party: PlayerParty(members: [
        PlayerPokemon(
          speciesId: 'bulbasaur',
          level: 5,
          natureId: 'hardy',
          abilityId: 'overgrow',
          currentHp: hp,
          statusId: status,
          knownMoveIds: ['tackle'],
          currentPpByMoveId: {'tackle': 3},
        )
      ]),
      bag: const Bag(entries: [BagEntry(itemId: 'full-restore', quantity: 2)]),
    );
PlayerItemUseRequest _request(GameState state) => PlayerItemUseRequest(
      state: state,
      itemId: 'full-restore',
      context: ProjectItemUseContext.overworld,
      partyIndex: 0,
      maxHp: 50,
    );
