import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/services/local_catalog_lookup_service.dart';
import 'package:map_editor/src/application/services/pokemon_species_lookup_service.dart';

void main() {
  const service = PokemonSpeciesLookupService();

  group('PokemonSpeciesLookupService', () {
    test('reuses the shared progressive local catalog lookup service', () {
      expect(
        service,
        isA<ProgressiveLocalCatalogLookupService<PokemonDatabaseIndexEntry>>(),
      );
    });

    test('finds a species by exact local id', () {
      final entry = service.findById(_entries, 'bulbasaur');

      expect(entry, isNotNull);
      expect(entry!.primaryName, 'Bulbasaur');
    });

    test('searches by name, id and padded dex number', () {
      final nameResults = service.search(_entries, 'pika');
      final idResults = service.search(_entries, 'bulba');
      final dexResults = service.search(_entries, '#0001');

      expect(nameResults.first.id, 'pikachu');
      expect(idResults.first.id, 'bulbasaur');
      expect(dexResults.first.id, 'bulbasaur');
    });
  });
}

const List<PokemonDatabaseIndexEntry> _entries = <PokemonDatabaseIndexEntry>[
  PokemonDatabaseIndexEntry(
    id: 'bulbasaur',
    nationalDex: 1,
    primaryName: 'Bulbasaur',
    genIntroduced: 1,
    types: <String>['grass', 'poison'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'bulbasaur',
      evolution: 'bulbasaur',
      media: 'bulbasaur',
    ),
  ),
  PokemonDatabaseIndexEntry(
    id: 'pikachu',
    nationalDex: 25,
    primaryName: 'Pikachu',
    genIntroduced: 1,
    types: <String>['electric'],
    isEnabledInProject: true,
    refs: PokemonDatabaseIndexRefs(
      learnset: 'pikachu',
      evolution: 'pikachu',
      media: 'pikachu',
    ),
  ),
];
