import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  test('friendship loss composes after an authored vitamin friendship gain', () {
    final use = useJson('energy-powder')..['effect'] = {'kind': 'vitamin', 'stat': 'attack', 'amount': 10,
      'maximumPerStat': 100, 'maximumTotal': 510, 'friendshipGainLow': 5, 'friendshipGainMedium': 3, 'friendshipGainHigh': 2};
    use['friendshipLoss'] = {'low': 5, 'medium': 7, 'high': 10};
    final catalog = decodeProjectItemCatalog({'schemaVersion': 1, 'entries': [itemJson('energy-powder', use)]});
    final service = PlayerItemUseService(snapshot: ItemCatalogSnapshot.fromCatalog(catalog));
    final result = service.use(request(state('energy-powder', 70), 'energy-powder', ProjectItemUseContext.overworld));
    expect(result.isSuccess, isTrue);
    expect(result.state.party.members.single.friendship, 70);
    expect(result.state.party.members.single.evs.attack, 10);
    expect(result.consumptionReceipt?.quantity, 1);
    final crossing = service.use(request(state('energy-powder', 99), 'energy-powder', ProjectItemUseContext.overworld));
    expect(crossing.state.party.members.single.friendship, 97);
  });
  for (final context in ProjectItemUseContext.values) {
    for (final powder in ['energy-powder', 'heal-powder']) {
      test('$powder applies once with bounded friendship loss in $context', () {
        for (final friendship in [0, 3, 99, 100, 199, 200, 255]) {
          final initial = state(powder, friendship);
          final result = service(powder).use(request(initial, powder, context));
          expect(result.isSuccess, isTrue);
          final target = result.state.party.members.single;
          expect(target.friendship, (friendship - (friendship < 200 ? 5 : 10)).clamp(0, 255));
          expect(target.currentHp, powder == 'energy-powder' ? 100 : 50);
          expect(target.statusId, powder == 'heal-powder' ? '' : 'poison');
          expect(result.consumptionReceipt?.quantity, 1);
          expect(result.state.bag.entries.single.quantity, 1);
          expect(GameState.fromJson(result.state.toJson()), result.state);
          expect(initial.party.members.single.friendship, friendship);
        }
      });
      test('$powder refusals preserve friendship, target and inventory in $context', () {
        final initial = state(powder, 200);
        for (final source in [
          initial.copyWith(party: PlayerParty(members: [initial.party.members.single.copyWith(currentHp: powder == 'energy-powder' ? 100 : 50, statusId: '')])),
          initial.copyWith(party: PlayerParty(members: [initial.party.members.single.copyWith(currentHp: 0)])),
          initial.copyWith(bag: const Bag()),
        ]) {
          final result = service(powder).use(request(source, powder, context));
          expect(result.isSuccess, isFalse);
          expect(result.state, source);
          expect(result.consumptionReceipt, isNull);
        }
        final invalid = service(powder).use(PlayerItemUseRequest(state: initial, itemId: powder, context: context, partyIndex: 8, maxHp: 100));
        expect(invalid.failure, PlayerItemUseFailure.invalidTarget);
        expect(invalid.state, initial);
      });
    }
  }
  test('heal powder cures battle confusion without a major status', () {
    final initial = state('heal-powder', 200);
    final clear = initial.copyWith(party: PlayerParty(members: [initial.party.members.single.copyWith(statusId: '')]));
    final result = service('heal-powder').use(PlayerItemUseRequest(state: clear, itemId: 'heal-powder', context: ProjectItemUseContext.battle,
      partyIndex: 0, maxHp: 100, targetHasBattleConfusion: true));
    expect(result.isSuccess, isTrue);
    expect(result.state.party.members.single.friendship, 190);
  });
  test('legacy item use JSON remains unchanged without friendship loss', () {
    final json = useJson('energy-powder')..remove('friendshipLoss');
    expect(ProjectItemUseDefinition.fromJson(json).toJson(), json);
  });
  test('friendship loss rejects malformed tiers and non-party uses', () {
    for (final loss in [
      {'low': -1, 'medium': 5, 'high': 10},
      {'low': 5.5, 'medium': 5, 'high': 10},
      {'low': 5, 'medium': 5, 'high': 256},
      {'low': 5, 'medium': 5, 'high': 10, 'unexpected': 1},
    ]) {
      expect(() => decodeProjectItemCatalog({'schemaVersion': 1, 'entries': [itemJson('energy-powder', useJson('energy-powder')..['friendshipLoss'] = loss)]}), throwsA(isA<FormatException>()));
    }
    expect(() => ProjectItemUseDefinition.fromJson(useJson('energy-powder')..['target'] = 'world'), throwsStateError);
    expect(() => ProjectItemUseDefinition.fromJson(useJson('energy-powder')..['consumption'] = 'never'), throwsStateError);
  });
}

Map<String, dynamic> useJson(String powder) => {
  'contexts': ['overworld', 'battle'], 'target': 'party_member', 'consumption': 'on_applied',
  'effect': powder == 'energy-powder' ? {'kind': 'heal_hp', 'mode': 'flat', 'amount': 50} : {'kind': 'cure_status', 'mode': 'all', 'statusIds': <String>[], 'curesConfusion': true},
  'friendshipLoss': {'low': 5, 'medium': 5, 'high': 10},
};
Map<String, dynamic> itemJson(String powder, Map<String, dynamic> use) => {'id': powder, 'displayName': powder, 'pocketId': 'medicine', 'uses': [use]};
PlayerItemUseService service(String powder) => PlayerItemUseService(snapshot: ItemCatalogSnapshot.fromCatalog(decodeProjectItemCatalog({
  'schemaVersion': 1, 'entries': [itemJson(powder, useJson(powder))],
})));
GameState state(String powder, int friendship) => GameState(saveId: 'bitter', party: PlayerParty(members: [PlayerPokemon(
  speciesId: 'bulbasaur', level: 5, natureId: 'hardy', abilityId: 'overgrow', currentHp: 50, statusId: 'poison', friendship: friendship,
)]), bag: Bag(entries: [BagEntry(itemId: powder, quantity: 2)]));
PlayerItemUseRequest request(GameState state, String powder, ProjectItemUseContext context) => PlayerItemUseRequest(
  state: state, itemId: powder, context: context, partyIndex: 0, maxHp: 100,
);
