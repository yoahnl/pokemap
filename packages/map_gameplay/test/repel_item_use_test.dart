import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final service = PlayerItemUseService(
      snapshot: ItemCatalogSnapshot.fromCatalog(
          const ProjectItemCatalog(schemaVersion: 1, entries: [
    ProjectItemDefinition(
        id: 'repel',
        displayName: 'Repousse',
        pocketId: 'items',
        uses: [
          ProjectItemUseDefinition(
              contexts: {ProjectItemUseContext.overworld},
              target: ProjectItemTargetKind.world,
              consumption: ProjectItemConsumptionPolicy.onApplied,
              effect: ProjectItemEffectDefinition.repel(steps: 100))
        ]),
  ])));
  GameState state() => const GameState(
      saveId: 'repel',
      metadata: {'keep': 'yes'},
      bag: Bag(entries: [BagEntry(itemId: 'repel', quantity: 2)]));
  PlayerItemUseResult use(GameState state,
          {ProjectItemUseContext context = ProjectItemUseContext.overworld}) =>
      service.use(PlayerItemUseRequest(
          state: state, itemId: 'repel', context: context));
  test('world repel needs no party and consumes exactly once after activation',
      () {
    final result = use(state());
    expect(result.isSuccess, isTrue);
    expect(result.state.repelState.remainingSteps, 100);
    expect(result.state.repelState.itemId, 'repel');
    expect(result.state.bag.entries.single.quantity, 1);
    expect(result.state.metadata, {'keep': 'yes'});
    final duplicate = use(result.state);
    expect(duplicate.failure, PlayerItemUseFailure.noEffect);
    expect(duplicate.state, result.state);
  });
  test('missing inventory and battle context leave state untouched', () {
    final empty = state().copyWith(bag: const Bag());
    expect(use(empty).failure, PlayerItemUseFailure.insufficientQuantity);
    expect(use(empty).state, empty);
    final initial = state();
    expect(
        use(initial, context: ProjectItemUseContext.battle).isSuccess, isFalse);
    expect(use(initial, context: ProjectItemUseContext.battle).state, initial);
  });
  test('Repousse rejects a Pokemon target without consuming or claiming unsupported', () {
    final wrongTargetService = PlayerItemUseService(snapshot: ItemCatalogSnapshot.fromCatalog(const ProjectItemCatalog(schemaVersion: 1, entries: [
      ProjectItemDefinition(id: 'repel', displayName: 'Repousse', pocketId: 'items', uses: [
        ProjectItemUseDefinition(contexts: {ProjectItemUseContext.overworld}, target: ProjectItemTargetKind.partyMember,
          consumption: ProjectItemConsumptionPolicy.onApplied, effect: ProjectItemEffectDefinition.repel(steps: 100)),
      ]),
    ])));
    final initial = state().copyWith(party: const PlayerParty(members: [PlayerPokemon(speciesId: 'lead', natureId: 'hardy', abilityId: 'unknown')]));
    final result = wrongTargetService.use(PlayerItemUseRequest(state: initial, itemId: 'repel', context: ProjectItemUseContext.overworld, partyIndex: 0, maxHp: 10));
    expect(result.failure, PlayerItemUseFailure.wrongTarget);
    expect(result.state, initial);
    expect(result.consumptionReceipt, isNull);
  });

  test('expired repel can explicitly be reused', () {
    final expired = use(state()).state;
    final result =
        use(expired.copyWith(repelState: expired.repelState.advance(100)));
    expect(result.isSuccess, isTrue);
    expect(result.state.repelState.remainingSteps, 100);
    expect(result.state.repelState.expirationPending, isFalse);
    expect(result.state.bag.entries, isEmpty);
  });
}
