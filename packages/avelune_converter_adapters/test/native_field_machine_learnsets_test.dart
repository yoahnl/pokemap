import 'package:avelune_converter_adapters/src/native_field_machine_learnsets.dart';
import 'package:avelune_converter_adapters/src/native_psdk_catalog.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final catalog = NativePsdkCatalogManifest.builtin();
  for (final row in [('charizard', 'fly'), ('pikachu', 'flash')]) {
    test(
        'native ${row.$1} retains TM and acquires HM compatibility for ${row.$2}',
        () {
      final before = catalog.learnsetsBySpeciesId[row.$1]!;
      final after = projectNativeFieldMachineLearnset(before);
      expect(before.tm.map((entry) => entry.moveId), contains(row.$2));
      expect(after.hm.map((entry) => entry.moveId), contains(row.$2));
      expect(after.tm.map((entry) => entry.toJson()).toList(),
          before.tm.map((entry) => entry.toJson()).toList());
      expect({...after.toJson(), 'hm': before.toJson()['hm']}, before.toJson());
      expect(projectNativeFieldMachineLearnset(after).toJson(), after.toJson());
      for (final consume in [false, true]) {
        final item = ProjectItemDefinition(
            id: 'machine',
            displayName: 'Machine',
            pocketId: 'machines',
            machine: ProjectMoveMachineItemDefinition(
                moveId: row.$2,
                kind: consume
                    ? ProjectMoveMachineKind.tm
                    : ProjectMoveMachineKind.hm,
                consumable: consume));
        final result = const PokemonMoveMachineService().apply(
            GameState(
                saveId: 'native-machine',
                party: PlayerParty(members: [
                  PlayerPokemon(
                      speciesId: row.$1,
                      natureId: 'hardy',
                      abilityId: 'static',
                      currentHp: 20,
                      knownMoveIds: const [])
                ]),
                bag: const Bag(
                    entries: [BagEntry(itemId: 'machine', quantity: 1)])),
            ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            partyIndex: 0,
            candidate: PokemonMoveMachineCandidate(
                itemId: 'machine',
                moveId: row.$2,
                maxPp: catalog.movesById[row.$2]!.pp,
                consumable: consume),
            decision: const PokemonMoveMachineDecision.learn(),
            itemCatalog: ItemCatalogSnapshot.fromCatalog(
                ProjectItemCatalog(schemaVersion: 1, entries: [item])));
        expect(result.status, PokemonMoveMachineUseStatus.learned);
        expect(result.state.party.members.single.knownMoveIds, [row.$2]);
        expect(
            result.state.bag.entries
                .fold<int>(0, (sum, entry) => sum + entry.quantity),
            consume ? 0 : 1);
        expect(
            GameState.fromJson(result.state.toJson())
                .party
                .members
                .single
                .knownMoveIds,
            [row.$2]);
      }
    });
  }
  test('incompatible species do not acquire field-machine compatibility', () {
    final before = catalog.learnsetsBySpeciesId['caterpie']!;
    final after = projectNativeFieldMachineLearnset(before);
    expect(after.hm.map((entry) => entry.moveId), isNot(contains('fly')));
    expect(after.hm.map((entry) => entry.moveId), isNot(contains('flash')));
    expect(after.toJson(), before.toJson());
  });
}
