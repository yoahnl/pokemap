part of 'pokedex_workspace_page.dart';

// Bloc minimal "catalogue local des attaques" pour l'onglet Learnset.
//
// Décision UI de la 11B :
// - on n'ouvre pas un nouveau workspace "Move Library" autonome ;
// - on ajoute la plus petite surface honnête là où le besoin produit existe
//   déjà : l'édition et la lecture du learnset ;
// - le bloc reste purement consommateur d'état applicatif injecté.
//
// Ce composant permet donc :
// - de voir si le catalogue local existe et combien d'entrées il contient ;
// - de prévisualiser un sync externe avant écriture ;
// - de lancer réellement le sync ;
// - de rechercher rapidement des ids/noms/types déjà importés.
class _PokedexMovesCatalogSection extends StatefulWidget {
  const _PokedexMovesCatalogSection({
    required this.loadCatalog,
    required this.previewSync,
    required this.syncCatalog,
    this.onCatalogChanged,
  });

  final Future<PokemonMovesCatalogView> Function() loadCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function() previewSync;
  final Future<PokemonMovesCatalogSyncResult> Function() syncCatalog;
  final VoidCallback? onCatalogChanged;

  @override
  State<_PokedexMovesCatalogSection> createState() =>
      _PokedexMovesCatalogSectionState();
}

class _PokedexMovesCatalogSectionState
    extends State<_PokedexMovesCatalogSection> {
  static const PokemonMovesCatalogLookupService _catalogLookupService =
      PokemonMovesCatalogLookupService();
  late final TextEditingController _searchController;
  late Future<PokemonMovesCatalogView> _catalogFuture;
  PokemonMovesCatalogSyncResult? _lastSyncReport;
  String? _operationError;
  bool _isPreviewing = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
    _catalogFuture = widget.loadCatalog();
  }

  @override
  void didUpdateWidget(covariant _PokedexMovesCatalogSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadCatalog != widget.loadCatalog ||
        oldWidget.previewSync != widget.previewSync ||
        oldWidget.syncCatalog != widget.syncCatalog) {
      _catalogFuture = widget.loadCatalog();
      _lastSyncReport = null;
      _operationError = null;
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _runPreview() async {
    if (_isPreviewing || _isSyncing) {
      return;
    }

    setState(() {
      _isPreviewing = true;
      _operationError = null;
    });

    try {
      final report = await widget.previewSync();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastSyncReport = report;
        _isPreviewing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPreviewing = false;
        _operationError = _formatOperationError(error);
      });
    }
  }

  Future<void> _runSync() async {
    if (_isPreviewing || _isSyncing) {
      return;
    }

    setState(() {
      _isSyncing = true;
      _operationError = null;
    });

    try {
      final report = await widget.syncCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastSyncReport = report;
        _catalogFuture = widget.loadCatalog();
        _isSyncing = false;
      });
      widget.onCatalogChanged?.call();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSyncing = false;
        _operationError = _formatOperationError(error);
      });
    }
  }

  String _formatOperationError(Object error) {
    return switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: 'Catalogue local des attaques',
      key: const Key('pokedex-moves-catalog-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cette surface 11B reste volontairement minimale : elle synchronise '
            'le catalogue local des moves, le rend consultable, puis laisse '
            'le learnset consommer cette source de vérité locale.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CupertinoButton.filled(
                key: const Key('pokedex-moves-catalog-preview-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: (_isPreviewing || _isSyncing) ? null : _runPreview,
                child: Text(
                  _isPreviewing ? 'Prévisualisation…' : 'Prévisualiser sync',
                ),
              ),
              CupertinoButton(
                key: const Key('pokedex-moves-catalog-sync-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: (_isPreviewing || _isSyncing) ? null : _runSync,
                child: Text(_isSyncing ? 'Synchronisation…' : 'Synchroniser'),
              ),
            ],
          ),
          if (_lastSyncReport != null) ...[
            const SizedBox(height: 12),
            _PokedexMoveCatalogSyncSummary(report: _lastSyncReport!),
          ],
          if (_operationError != null) ...[
            const SizedBox(height: 12),
            Text(
              _operationError!,
              key: const Key('pokedex-moves-catalog-error'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FutureBuilder<PokemonMovesCatalogView>(
            future: _catalogFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Text(
                    'Chargement du catalogue local des attaques…');
              }

              if (snapshot.hasError) {
                final message = _formatOperationError(
                  snapshot.error ?? 'Erreur inconnue',
                );
                return Text(
                  message,
                  key: const Key('pokedex-moves-catalog-load-error'),
                  style: const TextStyle(
                    color: EditorChrome.inspectorJoyCoral,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }

              final view = snapshot.data ??
                  const PokemonMovesCatalogView(
                    entries: <PokemonMoveCatalogEntryView>[],
                    isAvailable: false,
                    description: 'Catalogue local indisponible.',
                  );
              final filteredEntries = _filterEntries(view.entries);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.description,
                    key: const Key('pokedex-moves-catalog-description'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    view.isAvailable
                        ? 'Attaques locales : ${view.entries.length}'
                        : 'Catalogue indisponible',
                    key: const Key('pokedex-moves-catalog-count'),
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (view.message != null) ...[
                    const SizedBox(height: 6),
                    Text(view.message!),
                  ],
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    key: const Key('pokedex-moves-catalog-search-field'),
                    controller: _searchController,
                    placeholder: 'Rechercher une attaque locale',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (view.entries.isEmpty)
                    const Text(
                      'Aucune attaque locale importée pour le moment. '
                      'Utilisez la synchronisation externe pour alimenter le catalogue.',
                    )
                  else if (filteredEntries.isEmpty)
                    const Text(
                      'Aucune attaque ne correspond à la recherche actuelle.',
                    )
                  else
                    Container(
                      key: const Key('pokedex-moves-catalog-list'),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return _PokedexMoveCatalogRow(entry: entry);
                        },
                      ),
                    ),
                  if (view.entries.length > filteredEntries.length &&
                      filteredEntries.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Affichage limité à ${filteredEntries.length} résultats pour garder l’onglet lisible.',
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<PokemonMoveCatalogEntryView> _filterEntries(
    List<PokemonMoveCatalogEntryView> entries,
  ) {
    return _catalogLookupService.search(
      entries,
      _searchController.text,
      limit: 12,
    );
  }
}

class _PokedexMoveCatalogSyncSummary extends StatelessWidget {
  const _PokedexMoveCatalogSyncSummary({
    required this.report,
  });

  final PokemonMovesCatalogSyncResult report;

  @override
  Widget build(BuildContext context) {
    final label =
        report.dryRun ? 'Prévisualisation' : 'Dernière synchronisation';
    final lines = <String>[
      '$label : ${report.externalEntryCount} moves externes analysés.',
      'Créées : ${report.createdCount}.',
      'Mises à jour : ${report.updatedCount}.',
      'Inchangées : ${report.unchangedCount}.',
      'Locales conservées : ${report.preservedLocalOnlyCount}.',
      'Catalogue résultant : ${report.resultingEntryCount}.',
      if (report.createdIds.isNotEmpty)
        'Exemples créés : ${report.createdIds.take(5).join(', ')}.',
      if (report.updatedIds.isNotEmpty)
        'Exemples mis à jour : ${report.updatedIds.take(5).join(', ')}.',
      ...report.warnings,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          lines.join('\n'),
          key: const Key('pokedex-moves-catalog-preview-summary'),
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _PokedexMoveCatalogRow extends StatelessWidget {
  const _PokedexMoveCatalogRow({
    required this.entry,
  });

  final PokemonMoveCatalogEntryView entry;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.name} • ${entry.id}',
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (entry.type != null) entry.type!,
                if (entry.category != null) entry.category!,
                if (entry.pp != null) 'PP ${entry.pp}',
                if (entry.power != null) 'Puissance ${entry.power}',
                'Précision ${entry.accuracyLabel}',
              ].join(' • '),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (entry.shortDesc != null && entry.shortDesc!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.shortDesc!,
                style: TextStyle(
                  color: subtle,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
