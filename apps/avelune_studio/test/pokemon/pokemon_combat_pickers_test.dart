import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/pokemon/application/pokemon_combat_choices.dart';
import 'package:flutter_test/flutter_test.dart';

PokemonSpeciesSummary _species(
  String id,
  String name,
  int dex,
  List<String> types, {
  bool enabled = true,
}) => PokemonSpeciesSummary(
  id: id,
  name: name,
  nationalDex: dex,
  generation: 1,
  types: types,
  formIds: const [],
  mediaRelativePath: '',
  enabled: enabled,
  relativePath: 'data/pokemon/$id.json',
);

final _index = PokemonWorkspaceIndex(
  enabled: true,
  entries: [
    _species('pikachu', 'Pikachu', 25, ['electric']),
    _species('onix', 'Onix', 95, ['rock', 'ground']),
    _species('missingno', 'MissingNo', 0, const [], enabled: false),
  ],
  moves: const PokemonMovesCatalogView(
    relativePath: 'data/moves.json',
    entries: [
      PokemonMoveSummary(
        id: 'thunderbolt',
        name: 'Tonnerre',
        type: 'electric',
        category: 'special',
        power: 90,
        accuracy: '100',
      ),
      PokemonMoveSummary(
        id: 'growl',
        name: 'Rugissement',
        type: 'normal',
        category: 'status',
        accuracy: '100',
      ),
      PokemonMoveSummary(
        id: 'rock-throw',
        name: 'Jet-Pierres',
        type: 'rock',
        category: 'physical',
        power: 50,
        accuracy: '90',
      ),
    ],
  ),
  types: const [],
  items: const {},
);

void main() {
  test('species and moves describe themselves with useful details', () {
    expect(
      combatSpeciesDetails(_index.entries[1]),
      'n° 095 · Roche / Sol · Génération 1',
    );
    expect(
      combatMoveDetails(_index.moves.entries.first),
      'Électrik · Spéciale · Puissance 90 · Précision 100',
    );
    expect(
      combatMoveDetails(_index.moves.entries[1]),
      'Normal · Statut · Sans puissance · Précision 100',
    );
  });

  test('a species is searched by type with its details and disabled species are excluded', () {
    final choices = combatSpeciesChoices(_index);
    expect(choices, hasLength(2));
    expect(choices.map((choice) => choice.id), isNot(contains('missingno')));
    final matches = combatChoiceSearch(choices, 'roche');
    expect(matches.single.id, 'onix');
    expect(matches.single.details, 'n° 095 · Roche / Sol · Génération 1');
  });

  test('a move already known is not offered again and category search resolves its identity', () {
    final choices = combatMoveChoices(_index, exclude: const ['thunderbolt']);
    expect(choices, hasLength(2));
    expect(choices.map((choice) => choice.id), isNot(contains('thunderbolt')));
    expect(combatChoiceSearch(choices, 'physique').single.id, 'rock-throw');
    expect(combatChoiceSearch(choices, 'SPÉCIALE'), isEmpty);
  });

  test('building and filtering choices leave the source catalogue intact', () {
    final entries = _index.moves.entries;
    final species = _index.entries;
    final selected = combatChoiceSearch(combatMoveChoices(_index), 'unknown');
    expect(selected, isEmpty);
    final choices = combatMoveChoices(_index)..clear();
    expect(choices, isEmpty);
    expect(_index.moves.entries, same(entries));
    expect(_index.moves.entries, hasLength(3));
    expect(_index.entries, same(species));
    expect(_index.entries, hasLength(3));
  });
}
