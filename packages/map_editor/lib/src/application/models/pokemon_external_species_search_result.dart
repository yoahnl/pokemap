import 'pokemon_external_query_resolution.dart';

/// Suggestion concrète affichable dans l'auto-complétion mono-espèce.
///
/// Ce modèle reste volontairement léger :
/// - il ne représente pas un payload externe complet ;
/// - il ne représente pas non plus une espèce locale importée ;
/// - il sert uniquement à afficher une suggestion sélectionnable dans le
///   wizard Pokédex.
///
/// Les champs retenus sont ceux qui apportent une vraie valeur UX immédiate :
/// - l'id canonique à réutiliser pour preview/import ;
/// - le nom principal pour l'affichage ;
/// - le numéro dex pour aider la désambiguïsation ;
/// - la génération quand elle est connue dans le snapshot source.
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

/// État applicatif de la recherche mono-espèce.
///
/// Important :
/// - `loading` n'apparaît pas ici, car c'est un état d'interaction UI ;
/// - ce résultat ne fait qu'exprimer ce que la couche applicative a compris ;
/// - l'UI peut ensuite afficher un état vide, une erreur ou une liste sans
///   devoir réinterpréter la requête brute.
enum PokemonExternalSpeciesSearchResultKind {
  empty,
  suggestions,
  noResults,
  invalidQuery,
  outOfScopeQuery,
  error,
}

/// Résultat structuré de la recherche mono-espèce.
///
/// Le contrat est volontairement explicite :
/// - `empty` : rien à rechercher ;
/// - `suggestions` : la requête mono-espèce a produit des suggestions ;
/// - `noResults` : la requête mono-espèce est valide mais ne matche rien ;
/// - `invalidQuery` : la requête n'est pas comprise proprement ;
/// - `outOfScopeQuery` : la requête est comprise, mais relève d'un autre lot ;
/// - `error` : l'infrastructure de suggestion n'a pas pu répondre.
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

  /// Résolution issue du lot 1 quand une résolution existe vraiment.
  ///
  /// `null` est réservé au cas `empty`, où l'utilisateur n'a pas encore saisi
  /// de requête exploitable.
  final PokemonExternalQueryResolution? resolution;

  /// Suggestions concrètes uniquement pour l'état `suggestions`.
  final List<PokemonExternalSpeciesSuggestion> suggestions;

  /// Message lisible pour les états non-suggestions.
  final String? message;

  bool get hasSuggestions =>
      kind == PokemonExternalSpeciesSearchResultKind.suggestions &&
      suggestions.isNotEmpty;
}
