import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_external_species_search_result.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/search_external_pokemon_species_use_case.dart';
import 'package:map_editor/src/application/services/pokemon_external_query_resolver.dart';

void main() {
  group('SearchExternalPokemonSpeciesUseCase', () {
    test('returns empty without hitting the external repository', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('   ');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.empty);
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('returns invalid for an ambiguous whitespace query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('pikachu eevee abra');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.invalidQuery);
      expect(result.message, contains('Utilisez des virgules'));
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('returns out-of-scope for a dex range query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('1-151');

      expect(
          result.kind, PokemonExternalSpeciesSearchResultKind.outOfScopeQuery);
      expect(result.message, contains('plages Pokédex'));
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('returns suggestions for a mono-species textual query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: <String, dynamic>{
          'bulbasaur': <String, dynamic>{
            'name': 'Bulbasaur',
            'num': 1,
            'gen': 1,
          },
          'ivysaur': <String, dynamic>{
            'name': 'Ivysaur',
            'num': 2,
            'gen': 1,
          },
          'pikachu': <String, dynamic>{
            'name': 'Pikachu',
            'num': 25,
            'gen': 1,
          },
        },
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('bulb');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.suggestions);
      expect(result.suggestions.length, 1);
      expect(result.suggestions.single.speciesId, 'bulbasaur');
      expect(result.suggestions.single.primaryName, 'Bulbasaur');
      expect(result.suggestions.single.nationalDex, 1);
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 1);
    });

    test('returns suggestions for a dex query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: <String, dynamic>{
          'pikachu': <String, dynamic>{
            'name': 'Pikachu',
            'num': 25,
            'gen': 1,
          },
          'raichu': <String, dynamic>{
            'name': 'Raichu',
            'num': 26,
            'gen': 1,
          },
        },
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('025');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.suggestions);
      expect(result.suggestions.map((entry) => entry.speciesId), <String>[
        'pikachu',
      ]);
    });

    test('returns noResults for a valid mono-species query with no match',
        () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: <String, dynamic>{
          'pikachu': <String, dynamic>{
            'name': 'Pikachu',
            'num': 25,
            'gen': 1,
          },
        },
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('bulbasaur');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.noResults);
      expect(result.message, contains('Aucun Pokémon externe trouvé'));
    });

    test('maps repository failures to an error result', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshotError: const EditorPersistenceException(
          'Showdown snapshot indisponible',
        ),
      );
      final useCase = SearchExternalPokemonSpeciesUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('pikachu');

      expect(result.kind, PokemonExternalSpeciesSearchResultKind.error);
      expect(result.message, 'Showdown snapshot indisponible');
    });
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  _FakePokemonExternalSourceRepository({
    this.showdownPokedexSnapshot = const <String, dynamic>{},
    this.showdownPokedexSnapshotError,
  });

  final Map<String, dynamic> showdownPokedexSnapshot;
  final EditorApplicationException? showdownPokedexSnapshotError;
  int fetchShowdownPokedexSnapshotCallCount = 0;

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() async {
    fetchShowdownPokedexSnapshotCallCount += 1;
    final error = showdownPokedexSnapshotError;
    if (error != null) {
      throw error;
    }
    return showdownPokedexSnapshot;
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemsResourceList({
    required int limit,
    required int offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiItemPayload(String itemIdOrName) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    throw UnimplementedError();
  }
}
