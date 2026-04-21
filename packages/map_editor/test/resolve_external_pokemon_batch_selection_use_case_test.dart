import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_external_batch_selection.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/services/pokemon_external_query_resolver.dart';
import 'package:map_editor/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart';

void main() {
  group('ResolveExternalPokemonBatchSelectionUseCase', () {
    test('returns empty without hitting the external repository', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('   ');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.empty);
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('returns out of scope for a mono-species query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('pikachu');

      expect(
          result.kind, PokemonExternalBatchSelectionResultKind.outOfScopeQuery);
      expect(result.message, contains('liste explicite'));
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('resolves an explicit list with stable deduplication after mapping',
        () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('25, pikachu, bulbasaur');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.resolved);
      expect(
        result.targets.map((target) => target.speciesId).toList(),
        <String>['pikachu', 'bulbasaur'],
      );
      expect(
        result.targets.first.requestedInputs,
        <String>['25', 'pikachu'],
      );
    });

    test('resolves a dex range with base species only', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('25-26');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.resolved);
      expect(
        result.targets.map((target) => target.speciesId).toList(),
        <String>['pikachu', 'raichu'],
      );
    });

    test('resolves a generation with base species only and stable ordering',
        () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('gen 2');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.resolved);
      expect(
        result.targets.map((target) => target.speciesId).toList(),
        <String>['chikorita'],
      );
    });

    test('reports unresolved explicit entries without dropping resolved ones',
        () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('bulbasaur, missingno');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.invalidQuery);
      expect(
          result.targets.map((target) => target.speciesId).toList(), <String>[
        'bulbasaur',
      ]);
      expect(result.message, contains('missingno'));
    });

    test('returns no results for an unknown generation', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('generation 42');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.noResults);
      expect(result.message, contains('génération'));
    });

    test('maps repository failures to an error result', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshotError: const EditorPersistenceException(
          'Snapshot batch indisponible',
        ),
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('gen 1');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.error);
      expect(result.message, 'Snapshot batch indisponible');
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

const Map<String, dynamic> _sampleSnapshot = <String, dynamic>{
  'bulbasaur': <String, dynamic>{
    'name': 'Bulbasaur',
    'num': 1,
    'gen': 1,
  },
  'pikachu': <String, dynamic>{
    'name': 'Pikachu',
    'num': 25,
    'gen': 1,
  },
  'pikachugmax': <String, dynamic>{
    'name': 'Pikachu-Gmax',
    'num': 25,
    'gen': 8,
    'baseSpecies': 'Pikachu',
    'forme': 'Gmax',
  },
  'raichu': <String, dynamic>{
    'name': 'Raichu',
    'num': 26,
    'gen': 1,
  },
  'chikorita': <String, dynamic>{
    'name': 'Chikorita',
    'num': 152,
    'gen': 2,
  },
};
