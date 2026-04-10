import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/pokedex_providers.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../infrastructure/filesystem/project_filesystem.dart';
import 'pokedex_workspace_loader.dart';
import 'pokedex_workspace_views.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';

/// Workspace central Pokédex du lot 13.
///
/// Le widget public reste volontairement lisible :
/// - il lit le contexte éditeur existant ;
/// - il délègue le chargement par défaut à un helper local dédié ;
/// - il compose les quatre états UI strictement nécessaires.
///
/// On évite ainsi deux extrêmes :
/// - un gros widget fourre-tout mêlant UI et instanciation infra ;
/// - une nouvelle architecture Pokédex "future-ready" disproportionnée.
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}

class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
  String _selectedType = _allTypesFilterValue;
  String _selectedGeneration = _allGenerationsFilterValue;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _buildEntriesFuture();
  }

  @override
  void didUpdateWidget(covariant _PokedexWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.loader != widget.loader) {
      _entriesFuture = _buildEntriesFuture();
      // Les raffinements UI des lots 14 et 15 restent purement locaux :
      // quand on change de workspace projet ou de source de chargement, on
      // réinitialise la query et les filtres pour éviter de conserver des
      // critères devenus trompeurs sur une autre liste déjà chargée.
      _searchQuery = '';
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
    }
  }

  Future<List<PokemonDatabaseIndexEntry>> _buildEntriesFuture() {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return Future<List<PokemonDatabaseIndexEntry>>.value(
        const <PokemonDatabaseIndexEntry>[],
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    return widget.loader(workspace);
  }

  @override
  Widget build(BuildContext context) {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return const PokedexWorkspaceStateCard(
        title: 'Pokédex',
        message:
            'Chargez un projet pour afficher la liste locale des espèces importées.',
      );
    }

    return FutureBuilder<List<PokemonDatabaseIndexEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceLoadingState();
        }

        if (snapshot.hasError) {
          return PokedexWorkspaceErrorState(error: snapshot.error);
        }

        final entries = snapshot.data ?? const <PokemonDatabaseIndexEntry>[];
        if (entries.isEmpty) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-empty-state'),
            title: 'Pokédex',
            message:
                'Aucune espèce importée pour le moment. Les prochains imports ou seeds rempliront cette liste.',
          );
        }

        final availableTypes = _buildAvailableTypes(entries);
        final availableGenerations = _buildAvailableGenerations(entries);

        // Les lots 14 et 15 restent volontairement locaux à la UI :
        // - on ne recharge pas le disque à chaque frappe ou changement de filtre ;
        // - on ne crée pas de provider/notifier Pokédex dédié ;
        // - on filtre simplement la liste déjà chargée en mémoire ;
        // - on conserve l'ordre fourni par l'index local existant.
        final filteredEntries = _filterEntries(entries);
        if (filteredEntries.isEmpty) {
          // Important produit :
          // - "aucune espèce importée" = la liste source est réellement vide ;
          // - "aucun résultat" = la liste source existe mais les critères
          //   locaux courants (recherche et/ou filtres) ne matchent rien.
          //
          // On garde donc deux états distincts, mais on laisse le champ de
          // recherche et les filtres visibles ici pour que la correction des
          // critères reste immédiate et naturelle.
          return PokedexWorkspaceSpeciesList(
            entries: filteredEntries,
            query: _searchQuery,
            onQueryChanged: _updateSearchQuery,
            availableTypes: availableTypes,
            selectedType: _selectedType,
            onTypeChanged: _updateSelectedType,
            availableGenerations: availableGenerations,
            selectedGeneration: _selectedGeneration,
            onGenerationChanged: _updateSelectedGeneration,
            emptyResultsChild: PokedexWorkspaceNoResultsState(
              query: _searchQuery,
              selectedType:
                  _selectedType == _allTypesFilterValue ? null : _selectedType,
              selectedGeneration:
                  _selectedGeneration == _allGenerationsFilterValue
                      ? null
                      : _selectedGeneration,
            ),
          );
        }

        return PokedexWorkspaceSpeciesList(
          entries: filteredEntries,
          query: _searchQuery,
          onQueryChanged: _updateSearchQuery,
          availableTypes: availableTypes,
          selectedType: _selectedType,
          onTypeChanged: _updateSelectedType,
          availableGenerations: availableGenerations,
          selectedGeneration: _selectedGeneration,
          onGenerationChanged: _updateSelectedGeneration,
        );
      },
    );
  }

  void _updateSearchQuery(String value) {
    if (value == _searchQuery) return;
    setState(() => _searchQuery = value);
  }

  void _updateSelectedType(String value) {
    if (value == _selectedType) return;
    setState(() => _selectedType = value);
  }

  void _updateSelectedGeneration(String value) {
    if (value == _selectedGeneration) return;
    setState(() => _selectedGeneration = value);
  }

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

      return matchesSearch && matchesType && matchesGeneration;
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
