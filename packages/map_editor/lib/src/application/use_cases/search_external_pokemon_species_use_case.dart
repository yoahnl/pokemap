import '../errors/application_errors.dart';
import '../models/pokemon_external_query_resolution.dart';
import '../models/pokemon_external_species_search_result.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../services/pokemon_external_query_resolver.dart';

/// Recherche applicative mono-espèce pour le wizard Pokédex.
///
/// Ce use case prolonge le lot 1 sans le contourner :
/// - le résolveur du lot 1 comprend la saisie brute ;
/// - ce use case décide si cette saisie relève bien du flux mono-espèce ;
/// - puis il interroge une source légère de suggestions déjà présente dans le
///   pipeline externe existant.
///
/// Non-objectifs explicites :
/// - aucun import ;
/// - aucune preview d'import ;
/// - aucune logique batch ;
/// - aucune logique UI ;
/// - aucun nouveau port externe parallèle.
class SearchExternalPokemonSpeciesUseCase {
  SearchExternalPokemonSpeciesUseCase({
    required this.externalSourceRepository,
    required this.queryResolver,
    this.maxSuggestions = 8,
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonExternalQueryResolver queryResolver;
  final int maxSuggestions;

  Future<List<_IndexedExternalSpeciesSuggestion>>? _cachedIndexFuture;

  /// Exécute une recherche mono-espèce structurée.
  Future<PokemonExternalSpeciesSearchResult> execute(String rawQuery) async {
    final resolution = queryResolver.resolve(rawQuery);

    if (resolution is PokemonExternalInvalidQueryResolution) {
      if (resolution.code == PokemonExternalInvalidQueryCode.emptyQuery) {
        return PokemonExternalSpeciesSearchResult.empty(
          rawQuery: resolution.rawQuery,
          normalizedQuery: resolution.normalizedQuery,
        );
      }
      return PokemonExternalSpeciesSearchResult.invalidQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: resolution.message,
      );
    }

    if (resolution is! PokemonExternalSingleQueryResolution) {
      return PokemonExternalSpeciesSearchResult.outOfScopeQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: _buildOutOfScopeMessage(resolution.kind),
      );
    }

    try {
      final index = await _loadSuggestionIndex();
      final suggestions = _searchSuggestions(
        index,
        resolution.query,
      );

      if (suggestions.isEmpty) {
        return PokemonExternalSpeciesSearchResult.noResults(
          rawQuery: resolution.rawQuery,
          normalizedQuery: resolution.normalizedQuery,
          resolution: resolution,
          message:
              'Aucun Pokémon externe trouvé pour cette requête mono-espèce.',
        );
      }

      return PokemonExternalSpeciesSearchResult.suggestions(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        suggestions: suggestions,
      );
    } on EditorApplicationException catch (error) {
      return PokemonExternalSpeciesSearchResult.error(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: error.message,
      );
    } catch (error) {
      return PokemonExternalSpeciesSearchResult.error(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Recherche externe indisponible : $error',
      );
    }
  }

  String _buildOutOfScopeMessage(PokemonExternalQueryResolutionKind kind) {
    return switch (kind) {
      PokemonExternalQueryResolutionKind.explicitList =>
        'Cette étape ne gère qu’une espèce à la fois. Les listes explicites '
            'ne sont pas prises en charge ici.',
      PokemonExternalQueryResolutionKind.nationalDexRange =>
        'Cette étape mono-espèce ne gère pas encore les plages Pokédex.',
      PokemonExternalQueryResolutionKind.generation =>
        'Cette étape mono-espèce ne gère pas encore les imports par '
            'génération.',
      PokemonExternalQueryResolutionKind.singleQuery ||
      PokemonExternalQueryResolutionKind.invalid =>
        'La requête ne relève pas de cette étape mono-espèce.',
    };
  }

  Future<List<_IndexedExternalSpeciesSuggestion>> _loadSuggestionIndex() {
    final cached = _cachedIndexFuture;
    if (cached != null) {
      return cached;
    }

    final future = () async {
      final snapshot =
          await externalSourceRepository.fetchShowdownPokedexSnapshot();
      return _buildSuggestionIndex(snapshot);
    }();

    _cachedIndexFuture = future;
    return future;
  }

  List<_IndexedExternalSpeciesSuggestion> _buildSuggestionIndex(
    Map<String, dynamic> snapshot,
  ) {
    final indexedSuggestions = <_IndexedExternalSpeciesSuggestion>[];

    for (final entry in snapshot.entries) {
      final rawPayload = entry.value;
      if (rawPayload is! Map) {
        continue;
      }

      final speciesId = entry.key.trim().toLowerCase();
      if (speciesId.isEmpty) {
        continue;
      }

      final payload = rawPayload.cast<String, dynamic>();
      final nationalDex = (payload['num'] as num?)?.toInt() ?? 0;
      if (nationalDex <= 0) {
        // Le lot 2 veut une surface mono-espèce honnête. On ignore donc les
        // entrées Showdown qui ne décrivent pas une espèce exploitable
        // simplement côté dex produit.
        continue;
      }

      final primaryName = (payload['name'] as String?)?.trim();
      if (primaryName == null || primaryName.isEmpty) {
        continue;
      }

      final generation = (payload['gen'] as num?)?.toInt();
      final suggestion = PokemonExternalSpeciesSuggestion(
        speciesId: speciesId,
        primaryName: primaryName,
        nationalDex: nationalDex,
        generation: generation,
      );
      indexedSuggestions.add(
        _IndexedExternalSpeciesSuggestion(
          suggestion: suggestion,
          normalizedSpeciesId: _normalizeLookupToken(speciesId),
          normalizedPrimaryName: _normalizeLookupToken(primaryName),
        ),
      );
    }

    indexedSuggestions.sort((left, right) {
      final dexCompare =
          left.suggestion.nationalDex.compareTo(right.suggestion.nationalDex);
      if (dexCompare != 0) {
        return dexCompare;
      }
      return left.suggestion.speciesId.compareTo(right.suggestion.speciesId);
    });
    return List<_IndexedExternalSpeciesSuggestion>.unmodifiable(
      indexedSuggestions,
    );
  }

  List<PokemonExternalSpeciesSuggestion> _searchSuggestions(
    List<_IndexedExternalSpeciesSuggestion> index,
    PokemonExternalSingleQuery query,
  ) {
    return switch (query.kind) {
      PokemonExternalSingleQueryKind.nationalDex =>
        _searchByNationalDex(index, query.nationalDex!),
      PokemonExternalSingleQueryKind.species =>
        _searchBySpeciesTerm(index, query.normalizedValue!),
    };
  }

  List<PokemonExternalSpeciesSuggestion> _searchByNationalDex(
    List<_IndexedExternalSpeciesSuggestion> index,
    int nationalDex,
  ) {
    final matches = index
        .where((entry) => entry.suggestion.nationalDex == nationalDex)
        .take(maxSuggestions)
        .map((entry) => entry.suggestion)
        .toList(growable: false);
    return matches;
  }

  List<PokemonExternalSpeciesSuggestion> _searchBySpeciesTerm(
    List<_IndexedExternalSpeciesSuggestion> index,
    String rawTerm,
  ) {
    final normalizedTerm = _normalizeLookupToken(rawTerm);
    if (normalizedTerm.isEmpty) {
      return const <PokemonExternalSpeciesSuggestion>[];
    }

    final matches = <_RankedExternalSpeciesSuggestion>[];
    for (final entry in index) {
      final score = _computeMatchScore(entry, normalizedTerm);
      if (score == null) {
        continue;
      }
      matches.add(
        _RankedExternalSpeciesSuggestion(
          suggestion: entry.suggestion,
          score: score,
        ),
      );
    }

    matches.sort((left, right) {
      final scoreCompare = left.score.compareTo(right.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final dexCompare =
          left.suggestion.nationalDex.compareTo(right.suggestion.nationalDex);
      if (dexCompare != 0) {
        return dexCompare;
      }
      return left.suggestion.speciesId.compareTo(right.suggestion.speciesId);
    });

    return matches
        .take(maxSuggestions)
        .map((match) => match.suggestion)
        .toList(growable: false);
  }

  int? _computeMatchScore(
    _IndexedExternalSpeciesSuggestion entry,
    String normalizedTerm,
  ) {
    final id = entry.normalizedSpeciesId;
    final name = entry.normalizedPrimaryName;

    if (id == normalizedTerm || name == normalizedTerm) {
      return 0;
    }
    if (id.startsWith(normalizedTerm) || name.startsWith(normalizedTerm)) {
      return 1;
    }
    if (id.contains(normalizedTerm) || name.contains(normalizedTerm)) {
      return 2;
    }
    return null;
  }

  String _normalizeLookupToken(String rawValue) {
    final lowered = rawValue.trim().toLowerCase();
    return lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

class _IndexedExternalSpeciesSuggestion {
  const _IndexedExternalSpeciesSuggestion({
    required this.suggestion,
    required this.normalizedSpeciesId,
    required this.normalizedPrimaryName,
  });

  final PokemonExternalSpeciesSuggestion suggestion;
  final String normalizedSpeciesId;
  final String normalizedPrimaryName;
}

class _RankedExternalSpeciesSuggestion {
  const _RankedExternalSpeciesSuggestion({
    required this.suggestion,
    required this.score,
  });

  final PokemonExternalSpeciesSuggestion suggestion;
  final int score;
}
