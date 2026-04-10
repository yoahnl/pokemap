import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/models/pokemon_database_index.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../infrastructure/filesystem/project_filesystem.dart';
import 'pokedex_workspace_loader.dart';
import 'pokedex_workspace_views.dart';

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
    this.loader = loadPokedexEntriesForWorkspace,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de provider ou de notifier dédié.
  final PokedexEntryLoader loader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: loader,
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
      // La recherche du lot 14 reste un raffinement purement local de la vue :
      // quand on change de workspace projet ou de source de chargement, on
      // réinitialise la query pour éviter de conserver un filtre devenu
      // trompeur sur une autre liste déjà chargée.
      _searchQuery = '';
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

        // Le lot 14 reste volontairement local à la UI :
        // - on ne recharge pas le disque à chaque frappe ;
        // - on ne crée pas de provider/notifier Pokédex dédié ;
        // - on filtre simplement la liste déjà chargée en mémoire.
        final filteredEntries = _filterEntries(entries, _searchQuery);
        if (filteredEntries.isEmpty) {
          // Important produit :
          // - "aucune espèce importée" = la liste source est réellement vide ;
          // - "aucun résultat" = la liste source existe mais la recherche ne
          //   matche rien.
          //
          // On garde donc deux états distincts, mais on laisse le champ de
          // recherche visible ici pour que la correction de la query reste
          // immédiate et naturelle.
          return PokedexWorkspaceSpeciesList(
            entries: filteredEntries,
            query: _searchQuery,
            onQueryChanged: _updateSearchQuery,
            emptyResultsChild:
                PokedexWorkspaceNoResultsState(query: _searchQuery),
          );
        }

        return PokedexWorkspaceSpeciesList(
          entries: filteredEntries,
          query: _searchQuery,
          onQueryChanged: _updateSearchQuery,
        );
      },
    );
  }

  void _updateSearchQuery(String value) {
    if (value == _searchQuery) return;
    setState(() => _searchQuery = value);
  }

  List<PokemonDatabaseIndexEntry> _filterEntries(
    List<PokemonDatabaseIndexEntry> entries,
    String query,
  ) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return entries;
    }

    final normalizedTextQuery = normalizedQuery.toLowerCase();
    final normalizedDexQuery = _normalizeDexQuery(normalizedQuery);
    final hasExactDexQuery = RegExp(r'^\d+$').hasMatch(normalizedDexQuery);

    return entries.where((entry) {
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
    }).toList(growable: false);
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
