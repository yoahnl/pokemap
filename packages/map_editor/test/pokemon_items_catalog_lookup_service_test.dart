import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/local_catalog_lookup_service.dart';
import 'package:map_editor/src/application/services/pokemon_items_catalog_lookup_service.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';

void main() {
  const service = PokemonItemsCatalogLookupService();

  group('PokemonItemsCatalogLookupService', () {
    test('reuses the shared progressive local catalog lookup service', () {
      expect(
        service,
        isA<
            ProgressiveLocalCatalogLookupService<
                PokemonItemCatalogEntryView>>(),
      );
    });

    test('finds an item by its exact local id', () {
      final entry = service.findById(_entries, 'oran_berry');

      expect(entry, isNotNull);
      expect(entry!.name, 'Oran Berry');
    });

    test('searches by item label, id and aliases', () {
      final labelResults = service.search(_entries, 'leftovers');
      final idResults = service.search(_entries, 'oran');
      final aliasResults = service.search(_entries, 'berry');

      expect(labelResults.first.id, 'leftovers');
      expect(idResults.first.id, 'oran_berry');
      expect(aliasResults.map((entry) => entry.id), contains('oran_berry'));
    });
  });
}

const List<PokemonItemCatalogEntryView> _entries =
    <PokemonItemCatalogEntryView>[
  PokemonItemCatalogEntryView(
    id: 'oran_berry',
    name: 'Oran Berry',
    aliases: <String>['oran', 'berry'],
    shortDesc: 'Heals 10 HP.',
  ),
  PokemonItemCatalogEntryView(
    id: 'leftovers',
    name: 'Leftovers',
    aliases: <String>['lefties'],
    shortDesc: 'Restores HP every turn.',
  ),
];
