import 'pokemon_external_query_resolution.dart';

class PokemonExternalSpeciesSuggestion {
  const PokemonExternalSpeciesSuggestion({
    required this.speciesId,
    required this.primaryName,
    required this.nationalDex,
    this.generation,
  });

  final String speciesId;
  final String primaryName;
  final int nationalDex;
  final int? generation;
}

enum PokemonExternalSpeciesSearchResultKind {
  empty,
  suggestions,
  noResults,
  invalidQuery,
  outOfScopeQuery,
  error,
}

class PokemonExternalSpeciesSearchResult {
  const PokemonExternalSpeciesSearchResult._({
    required this.kind,
    required this.rawQuery,
    required this.normalizedQuery,
    this.resolution,
    this.suggestions = const <PokemonExternalSpeciesSuggestion>[],
    this.message,
  });

  const PokemonExternalSpeciesSearchResult.empty({
    required String rawQuery,
    required String normalizedQuery,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.empty,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );

  const PokemonExternalSpeciesSearchResult.suggestions({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required List<PokemonExternalSpeciesSuggestion> suggestions,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.suggestions,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          suggestions: suggestions,
        );

  const PokemonExternalSpeciesSearchResult.noResults({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.noResults,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          message: message,
        );

  const PokemonExternalSpeciesSearchResult.invalidQuery({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.invalidQuery,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          message: message,
        );

  const PokemonExternalSpeciesSearchResult.outOfScopeQuery({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.outOfScopeQuery,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          message: message,
        );

  const PokemonExternalSpeciesSearchResult.error({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) : this._(
          kind: PokemonExternalSpeciesSearchResultKind.error,
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
          resolution: resolution,
          message: message,
        );

  final PokemonExternalSpeciesSearchResultKind kind;
  final String rawQuery;
  final String normalizedQuery;

  final PokemonExternalQueryResolution? resolution;

  final List<PokemonExternalSpeciesSuggestion> suggestions;

  final String? message;

  bool get hasSuggestions =>
      kind == PokemonExternalSpeciesSearchResultKind.suggestions &&
      suggestions.isNotEmpty;
}
