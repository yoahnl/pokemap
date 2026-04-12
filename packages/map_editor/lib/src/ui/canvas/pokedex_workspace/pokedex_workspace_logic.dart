part of 'pokedex_workspace_page.dart';

// Helpers locaux du workspace.
//
// On garde ici les opérations purement UI : filtrage mémoire, résolution de la
// sélection visible et normalisation de la recherche dex. La source de vérité
// métier reste l'index et la fiche relus depuis le disque via les loaders.

extension _PokedexWorkspaceBodyStateLogic on _PokedexWorkspaceBodyState {
  List<PokemonDatabaseIndexEntry> _filterEntries(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final normalizedQuery = _searchQuery.trim();
    final normalizedTextQuery = normalizedQuery.toLowerCase();
    final normalizedDexQuery = _normalizeDexQuery(normalizedQuery);
    final hasExactDexQuery = RegExp(r'^\d+$').hasMatch(normalizedDexQuery);

    // Le lot 15 demande des filtres simples, pas un moteur de règles :
    // chaque critère local vaut soit "tout", soit une valeur unique exacte.
    final typeFilter = _selectedType.toLowerCase();
    final hasTypeFilter = _selectedType != _allTypesFilterValue;
    final hasGenerationFilter =
        _selectedGeneration != _allGenerationsFilterValue;
    final hasStatusFilter = _selectedStatus != _allStatusesFilterValue;

    return entries.where((entry) {
      final matchesSearch = _matchesSearchQuery(
        entry: entry,
        normalizedQuery: normalizedQuery,
        normalizedTextQuery: normalizedTextQuery,
        normalizedDexQuery: normalizedDexQuery,
        hasExactDexQuery: hasExactDexQuery,
      );

      final matchesType = !hasTypeFilter ||
          entry.types.any((type) => type.toLowerCase() == typeFilter);
      final matchesGeneration = !hasGenerationFilter ||
          entry.genIntroduced.toString() == _selectedGeneration;
      final matchesStatus = !hasStatusFilter ||
          (_selectedStatus == _enabledStatusFilterValue
              ? entry.isEnabledInProject
              : !entry.isEnabledInProject);

      return matchesSearch && matchesType && matchesGeneration && matchesStatus;
    }).toList(growable: false);
  }

  bool _matchesSearchQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedQuery,
    required String normalizedTextQuery,
    required String normalizedDexQuery,
    required bool hasExactDexQuery,
  }) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final matchesName =
        entry.primaryName.toLowerCase().contains(normalizedTextQuery);
    final matchesId = entry.id.toLowerCase().contains(normalizedTextQuery);

    // Règle produit explicite du lot 14 :
    // - si la query ressemble à un numéro dex, on ne fait pas un `contains`
    //   numérique ;
    // - on compare exactement `1`, `0001`, `#1`, `#0001` au dex courant ;
    // - cela évite qu'une recherche "1" remonte 10, 11, 21, etc.
    final matchesDex = hasExactDexQuery &&
        _matchesExactDexQuery(
          entry: entry,
          normalizedDexQuery: normalizedDexQuery,
        );

    return matchesName || matchesId || matchesDex;
  }

  List<String> _buildAvailableTypes(List<PokemonDatabaseIndexEntry> entries) {
    final uniqueTypes = entries
        .expand((entry) => entry.types)
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort(
          (left, right) => left.toLowerCase().compareTo(right.toLowerCase()));

    return uniqueTypes;
  }

  List<String> _buildAvailableGenerations(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final uniqueGenerations = entries
        .map((entry) => entry.genIntroduced)
        .toSet()
        .toList(growable: false)
      ..sort();

    return uniqueGenerations
        .map((generation) => generation.toString())
        .toList(growable: false);
  }

  PokemonDatabaseIndexEntry? _resolveSelectedEntry(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    for (final entry in entries) {
      if (entry.id == selectedId) {
        return entry;
      }
    }
    return null;
  }

  String _normalizeDexQuery(String query) {
    final trimmed = query.trim();
    if (!trimmed.startsWith('#')) {
      return trimmed;
    }
    return trimmed.substring(1).trim();
  }

  bool _matchesExactDexQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedDexQuery,
  }) {
    final rawDex = entry.nationalDex.toString();
    final paddedDex = entry.nationalDex.toString().padLeft(4, '0');
    return normalizedDexQuery == rawDex || normalizedDexQuery == paddedDex;
  }
}
