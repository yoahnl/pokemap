import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/models/pokemon_external_query_resolution.dart';
import 'package:map_editor/src/application/services/pokemon_external_query_resolver.dart';

void main() {
  const resolver = PokemonExternalQueryResolver();

  group('PokemonExternalQueryResolver', () {
    group('single species queries', () {
      test('resolves a lowercase species name', () {
        final result = resolver.resolve('bulbasaur');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.kind, PokemonExternalQueryResolutionKind.singleQuery);
        expect(single.normalizedQuery, 'bulbasaur');
        expect(single.query.kind, PokemonExternalSingleQueryKind.species);
        expect(single.query.normalizedValue, 'bulbasaur');
      });

      test('normalizes case and surrounding spaces for a species query', () {
        final result = resolver.resolve('  Bulbasaur  ');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.normalizedQuery, 'Bulbasaur');
        expect(single.query.normalizedValue, 'bulbasaur');
      });
    });

    group('single national dex queries', () {
      test('resolves a raw dex number', () {
        final result = resolver.resolve('1');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.query.kind, PokemonExternalSingleQueryKind.nationalDex);
        expect(single.query.nationalDex, 1);
      });

      test('resolves a zero-padded dex number', () {
        final result = resolver.resolve('001');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.query.kind, PokemonExternalSingleQueryKind.nationalDex);
        expect(single.query.nationalDex, 1);
      });

      test('resolves a four-digit zero-padded dex number', () {
        final result = resolver.resolve('0001');

        expect(result, isA<PokemonExternalSingleQueryResolution>());
        final single = result as PokemonExternalSingleQueryResolution;
        expect(single.query.kind, PokemonExternalSingleQueryKind.nationalDex);
        expect(single.query.nationalDex, 1);
      });
    });

    group('national dex ranges', () {
      test('resolves a compact dex range', () {
        final result = resolver.resolve('1-151');

        expect(result, isA<PokemonExternalNationalDexRangeQueryResolution>());
        final range = result as PokemonExternalNationalDexRangeQueryResolution;
        expect(range.kind, PokemonExternalQueryResolutionKind.nationalDexRange);
        expect(range.startNationalDex, 1);
        expect(range.endNationalDex, 151);
      });

      test('resolves a dex range with spaces around the hyphen', () {
        final result = resolver.resolve('1 - 151');

        expect(result, isA<PokemonExternalNationalDexRangeQueryResolution>());
        final range = result as PokemonExternalNationalDexRangeQueryResolution;
        expect(range.startNationalDex, 1);
        expect(range.endNationalDex, 151);
      });

      test('rejects a descending dex range', () {
        final result = resolver.resolve('151-1');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidNationalDexRange,
        );
      });

      test('rejects an invalid dex range with a missing end', () {
        final result = resolver.resolve('1-');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidNationalDexRange,
        );
      });
    });

    group('generation queries', () {
      test('resolves a lower-case generation query', () {
        final result = resolver.resolve('gen 1');

        expect(result, isA<PokemonExternalGenerationQueryResolution>());
        final generation = result as PokemonExternalGenerationQueryResolution;
        expect(generation.kind, PokemonExternalQueryResolutionKind.generation);
        expect(generation.generation, 1);
      });

      test('resolves a mixed-case generation query', () {
        final result = resolver.resolve('Gen 1');

        expect(result, isA<PokemonExternalGenerationQueryResolution>());
        final generation = result as PokemonExternalGenerationQueryResolution;
        expect(generation.generation, 1);
      });

      test('resolves a long-form generation query', () {
        final result = resolver.resolve('generation 1');

        expect(result, isA<PokemonExternalGenerationQueryResolution>());
        final generation = result as PokemonExternalGenerationQueryResolution;
        expect(generation.generation, 1);
      });

      test('rejects an invalid generation number', () {
        final result = resolver.resolve('gen 0');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidGeneration,
        );
      });
    });

    group('explicit lists', () {
      test('resolves a compact explicit list', () {
        final result = resolver.resolve('pikachu,eevee,abra');

        expect(result, isA<PokemonExternalExplicitListQueryResolution>());
        final list = result as PokemonExternalExplicitListQueryResolution;
        expect(
          list.kind,
          PokemonExternalQueryResolutionKind.explicitList,
        );
        expect(list.queries.map((query) => query.normalizedValue).toList(),
            <String?>['pikachu', 'eevee', 'abra']);
      });

      test('resolves a spaced explicit list', () {
        final result = resolver.resolve('pikachu, eevee, abra');

        expect(result, isA<PokemonExternalExplicitListQueryResolution>());
        final list = result as PokemonExternalExplicitListQueryResolution;
        expect(list.queries.map((query) => query.normalizedValue).toList(),
            <String?>['pikachu', 'eevee', 'abra']);
      });

      test('deduplicates explicit list entries while preserving order', () {
        final result = resolver.resolve(
          'pikachu, eevee, pikachu, 025, 25, abra',
        );

        expect(result, isA<PokemonExternalExplicitListQueryResolution>());
        final list = result as PokemonExternalExplicitListQueryResolution;
        expect(list.queries.length, 4);
        expect(list.queries[0].normalizedValue, 'pikachu');
        expect(list.queries[1].normalizedValue, 'eevee');
        expect(list.queries[2].nationalDex, 25);
        expect(list.queries[3].normalizedValue, 'abra');
      });
    });

    group('ambiguous or invalid queries', () {
      test('rejects an empty query', () {
        final result = resolver.resolve('');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(invalid.code, PokemonExternalInvalidQueryCode.emptyQuery);
      });

      test('rejects a query containing only spaces', () {
        final result = resolver.resolve('   ');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(invalid.code, PokemonExternalInvalidQueryCode.emptyQuery);
      });

      test('rejects an ambiguous whitespace-separated list candidate', () {
        final result = resolver.resolve('pikachu eevee abra');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.ambiguousWhitespaceSeparatedTerms,
        );
      });

      test('rejects an explicit list with empty entries', () {
        final result = resolver.resolve('pikachu, , abra');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidExplicitList,
        );
      });

      test('rejects an explicit list with inconsistent separators', () {
        final result = resolver.resolve('pikachu, eevee abra');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidExplicitList,
        );
      });

      test('rejects a malformed generation query', () {
        final result = resolver.resolve('generation x');

        expect(result, isA<PokemonExternalInvalidQueryResolution>());
        final invalid = result as PokemonExternalInvalidQueryResolution;
        expect(
          invalid.code,
          PokemonExternalInvalidQueryCode.invalidGeneration,
        );
      });
    });
  });
}
