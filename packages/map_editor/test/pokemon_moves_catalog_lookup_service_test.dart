import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/pokemon_moves_catalog_lookup_service.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';

void main() {
  const service = PokemonMovesCatalogLookupService();

  group('PokemonMovesCatalogLookupService', () {
    test('finds a move by its exact local id', () {
      final entry = service.findById(_entries, 'vine_whip');

      expect(entry, isNotNull);
      expect(entry!.name, 'Vine Whip');
    });

    test('searches by move id and name with stable local results', () {
      final idResults = service.search(_entries, 'vine');
      final nameResults = service.search(_entries, 'tackle');

      expect(
        idResults.map((entry) => entry.id).toList(growable: false),
        contains('vine_whip'),
      );
      expect(nameResults.first.id, 'tackle');
    });

    test('returns no result for an unknown local move query', () {
      final results = service.search(_entries, 'missing_move');

      expect(results, isEmpty);
    });
  });
}

const List<PokemonMoveCatalogEntryView> _entries =
    <PokemonMoveCatalogEntryView>[
  PokemonMoveCatalogEntryView(
    id: 'growl',
    name: 'Growl',
    type: 'normal',
    category: 'status',
    pp: 40,
  ),
  PokemonMoveCatalogEntryView(
    id: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: 'physical',
    power: 40,
    accuracy: 100,
    pp: 35,
  ),
  PokemonMoveCatalogEntryView(
    id: 'vine_whip',
    name: 'Vine Whip',
    type: 'grass',
    category: 'physical',
    power: 45,
    accuracy: 100,
    pp: 25,
  ),
];
