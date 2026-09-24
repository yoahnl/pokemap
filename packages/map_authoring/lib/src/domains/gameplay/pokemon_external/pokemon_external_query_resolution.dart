enum PokemonExternalQueryResolutionKind {
  singleQuery,
  explicitList,
  nationalDexRange,
  generation,
  invalid,
}

enum PokemonExternalSingleQueryKind {
  species,
  nationalDex,
}

enum PokemonExternalInvalidQueryCode {
  emptyQuery,
  ambiguousWhitespaceSeparatedTerms,
  invalidNationalDex,
  invalidNationalDexRange,
  invalidGeneration,
  invalidExplicitList,
  unsupportedFormat,
}

class PokemonExternalSingleQuery {
  const PokemonExternalSingleQuery.species({
    required this.rawValue,
    required this.normalizedValue,
  })  : kind = PokemonExternalSingleQueryKind.species,
        nationalDex = null;

  const PokemonExternalSingleQuery.nationalDex({
    required this.rawValue,
    required this.nationalDex,
  })  : kind = PokemonExternalSingleQueryKind.nationalDex,
        normalizedValue = null;

  final PokemonExternalSingleQueryKind kind;

  final String rawValue;

  final String? normalizedValue;

  final int? nationalDex;

  String get deduplicationKey => switch (kind) {
        PokemonExternalSingleQueryKind.species => 'species:$normalizedValue',
        PokemonExternalSingleQueryKind.nationalDex => 'dex:$nationalDex',
      };
}

sealed class PokemonExternalQueryResolution {
  const PokemonExternalQueryResolution({
    required this.rawQuery,
    required this.normalizedQuery,
  });

  final String rawQuery;
  final String normalizedQuery;

  PokemonExternalQueryResolutionKind get kind;
}

final class PokemonExternalSingleQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalSingleQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.query,
  });

  final PokemonExternalSingleQuery query;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.singleQuery;
}

final class PokemonExternalExplicitListQueryResolution
    extends PokemonExternalQueryResolution {
  PokemonExternalExplicitListQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required List<PokemonExternalSingleQuery> queries,
  }) : queries = List<PokemonExternalSingleQuery>.unmodifiable(queries);

  final List<PokemonExternalSingleQuery> queries;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.explicitList;
}

final class PokemonExternalNationalDexRangeQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalNationalDexRangeQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.startNationalDex,
    required this.endNationalDex,
  });

  final int startNationalDex;
  final int endNationalDex;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.nationalDexRange;
}

final class PokemonExternalGenerationQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalGenerationQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.generation,
  });

  final int generation;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.generation;
}

final class PokemonExternalInvalidQueryResolution
    extends PokemonExternalQueryResolution {
  const PokemonExternalInvalidQueryResolution({
    required super.rawQuery,
    required super.normalizedQuery,
    required this.code,
    required this.message,
  });

  final PokemonExternalInvalidQueryCode code;
  final String message;

  @override
  PokemonExternalQueryResolutionKind get kind =>
      PokemonExternalQueryResolutionKind.invalid;
}
