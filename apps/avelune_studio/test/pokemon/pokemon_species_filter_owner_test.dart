import 'package:avelune_studio/features/pokemon/application/pokemon_workspace_controller.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Port implements PokemonWorkspacePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PokemonSpeciesSummary _species(String id, int generation, List<String> types) =>
    PokemonSpeciesSummary(
      id: id,
      name: id,
      nationalDex: generation,
      generation: generation,
      types: types,
      formIds: const [],
      mediaRelativePath: '',
      enabled: true,
      relativePath: '',
    );

PokemonWorkspaceController _owner(List<PokemonSpeciesSummary> entries) {
  final owner = PokemonWorkspaceController(_Port(), changed: () {});
  addTearDown(owner.dispose);
  owner.index = PokemonWorkspaceIndex(
    enabled: true,
    entries: entries,
    moves: const PokemonMovesCatalogView(entries: [], relativePath: ''),
    types: const [],
    items: const {},
  );
  return owner;
}

void main() {
  test('filter options list each type and generation once, sorted', () {
    final owner = _owner([
      _species('rondoudou', 3, ['fairy', 'normal']),
      _species('bulbasaur', 1, ['grass', 'poison']),
      _species('ivysaur', 1, ['grass', 'poison']),
      _species('sparkitten', 2, ['fire']),
    ]);

    expect(owner.speciesFilterTypes, [
      'fairy',
      'fire',
      'grass',
      'normal',
      'poison',
    ]);
    expect(owner.speciesFilterGenerations, [1, 2, 3]);
  });

  test('filter options do not depend on the active filters', () {
    final owner = _owner([
      _species('bulbasaur', 1, ['grass']),
      _species('sparkitten', 2, ['fire']),
    ]);

    owner.setFilters(type: 'fire', generation: 2);

    expect(owner.visibleSpecies.map((entry) => entry.id), ['sparkitten']);
    expect(owner.speciesFilterTypes, ['fire', 'grass']);
    expect(owner.speciesFilterGenerations, [1, 2]);
  });

  test('without an index there is nothing to filter by', () {
    final owner = PokemonWorkspaceController(_Port(), changed: () {});
    addTearDown(owner.dispose);

    expect(owner.speciesFilterTypes, isEmpty);
    expect(owner.speciesFilterGenerations, isEmpty);
  });
}
