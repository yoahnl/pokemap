import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../../features/editor/state/editor_selectors.dart';

class PokemonMovesCatalogWorkspace extends ConsumerStatefulWidget {
  const PokemonMovesCatalogWorkspace({super.key});

  @override
  ConsumerState<PokemonMovesCatalogWorkspace> createState() =>
      _PokemonMovesCatalogWorkspaceState();
}

class _PokemonMovesCatalogWorkspaceState
    extends ConsumerState<PokemonMovesCatalogWorkspace> {
  late final TextEditingController _searchController;
  String? _selectedMoveId;
  String? _loadedProjectRootPath;
  Future<PokemonMovesCatalogView>? _catalogFuture;
  bool _isSyncing = false;
  PokemonMovesCatalogSyncResult? _lastSyncResult;
  String? _lastSyncError;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectRootPath = ref.watch(editorProjectRootPathProvider);
    final catalogFuture = _catalogFutureFor(projectRootPath);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: _MovesWorkspaceScaffold(
        child: FutureBuilder<PokemonMovesCatalogView>(
          future: catalogFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Text('Chargement du catalogue local des moves…'),
              );
            }
            if (snapshot.hasError) {
              return _MovesWorkspaceNotice(
                title: 'Catalogue illisible',
                message: snapshot.error.toString(),
              );
            }
            return _buildCatalogContent(
              context,
              snapshot.data ??
                  const PokemonMovesCatalogView(
                    entries: <PokemonMoveCatalogEntryView>[],
                    isAvailable: false,
                    description: 'Catalogue local des attaques indisponible.',
                    loadState: PokemonMovesCatalogLoadState.loadError,
                  ),
              projectRootPath,
            );
          },
        ),
      ),
    );
  }

  Future<PokemonMovesCatalogView> _loadCatalog(String? projectRootPath) async {
    final loader = ref.read(pokemonMovesCatalogWorkspaceLoaderProvider);
    return loader(projectRootPath);
  }

  Future<PokemonMovesCatalogView> _catalogFutureFor(String? projectRootPath) {
    if (_catalogFuture == null || _loadedProjectRootPath != projectRootPath) {
      _loadedProjectRootPath = projectRootPath;
      _catalogFuture = _loadCatalog(projectRootPath);
    }
    return _catalogFuture!;
  }

  Widget _buildCatalogContent(
    BuildContext context,
    PokemonMovesCatalogView view,
    String? projectRootPath,
  ) {
    final syncToolbar = _buildSyncToolbar(
      context,
      projectRootPath: projectRootPath,
    );
    final query = _searchController.text.trim();
    final filteredEntries = _filterEntries(view.entries, query);
    final selectedEntry = _resolveSelectedEntry(filteredEntries);

    if (view.loadState == PokemonMovesCatalogLoadState.noProject) {
      return const _MovesWorkspaceNotice(
        title: 'Moves',
        message: 'Ouvre un projet pour afficher le catalogue des moves.',
      );
    }

    if (view.loadState == PokemonMovesCatalogLoadState.missingCatalog) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (syncToolbar != null) ...[
            syncToolbar,
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _MovesWorkspaceNotice(
              title: 'Moves',
              message:
                  'Aucun move local pour le moment.\nAjoute des entrées dans ${view.catalogRelativePath}. L’import externe sera traité dans un lot suivant.',
            ),
          ),
        ],
      );
    }

    if (view.loadState == PokemonMovesCatalogLoadState.loadError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (syncToolbar != null) ...[
            syncToolbar,
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _MovesWorkspaceNotice(
              title: 'Moves',
              message:
                  view.message ?? 'Le catalogue local des moves est illisible.',
            ),
          ),
        ],
      );
    }

    if (view.entries.isEmpty) {
      if (view.diagnostics.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (syncToolbar != null) ...[
              syncToolbar,
              const SizedBox(height: 16),
            ],
            Expanded(
              child: _MovesWorkspaceNotice(
                title: 'Moves',
                message:
                    'Le catalogue local des moves contient uniquement des entrées invalides.\n${_diagnosticsSummary(view.diagnostics.length)}\nChemin lu : ${view.catalogRelativePath}',
              ),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (syncToolbar != null) ...[
            syncToolbar,
            const SizedBox(height: 16),
          ],
          Expanded(
            child: _MovesWorkspaceNotice(
              title: 'Moves',
              message:
                  'Le catalogue local des moves existe, mais il ne contient aucune entrée.\nChemin lu : ${view.catalogRelativePath}',
            ),
          ),
        ],
      );
    }

    final isCompact = MediaQuery.sizeOf(context).width < 1040;

    final listPanel = _MovesCatalogListPanel(
      searchController: _searchController,
      entries: filteredEntries,
      selectedEntryId: selectedEntry?.id,
      diagnostics: view.diagnostics,
      onEntrySelected: (entry) {
        setState(() {
          _selectedMoveId = entry.id;
        });
      },
    );

    final detailPanel = _MovesCatalogDetailPanel(
      entry: selectedEntry,
      hasSearchQuery: query.isNotEmpty,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (syncToolbar != null) ...[
            syncToolbar,
            const SizedBox(height: 16),
          ],
          Expanded(
            flex: 5,
            child: listPanel,
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 4,
            child: detailPanel,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (syncToolbar != null) ...[
          syncToolbar,
          const SizedBox(height: 16),
        ],
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: listPanel,
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: detailPanel,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildSyncToolbar(
    BuildContext context, {
    required String? projectRootPath,
  }) {
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return null;
    }

    final border = CupertinoColors.separator.resolveFrom(context);
    final fill = CupertinoColors.systemGrey6.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final statusText = _buildSyncStatusText();

    return Container(
      key: const Key('moves-catalog-sync-toolbar'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CupertinoButton(
                key: const Key('moves-catalog-preview-sync-button'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                onPressed: _isSyncing
                    ? null
                    : () => _runSync(
                          projectRootPath,
                          dryRun: true,
                        ),
                child: const Text('Preview sync'),
              ),
              CupertinoButton.filled(
                key: const Key('moves-catalog-run-sync-button'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                onPressed: _isSyncing
                    ? null
                    : () => _runSync(
                          projectRootPath,
                          dryRun: false,
                        ),
                child: Text(
                  _isSyncing ? 'Sync en cours…' : 'Sync depuis Showdown',
                ),
              ),
              if (_isSyncing) const CupertinoActivityIndicator(),
            ],
          ),
          if (statusText != null) ...[
            const SizedBox(height: 10),
            Text(
              statusText,
              key: const Key('moves-catalog-sync-status'),
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _buildSyncStatusText() {
    if (_lastSyncError != null && _lastSyncError!.trim().isNotEmpty) {
      return _lastSyncError;
    }
    final result = _lastSyncResult;
    if (result == null) {
      return null;
    }

    final prefix = result.dryRun ? 'Prévisualisation' : 'Synchronisation';
    final summary =
        '$prefix: ${result.createdIds.length} créé(s), ${result.updatedIds.length} mis à jour, ${result.unchangedIds.length} inchangé(s), ${result.preservedLocalOnlyIds.length} local(aux) conservé(s).';

    if (result.warnings.isEmpty) {
      return summary;
    }
    return '$summary\n${result.warnings.join('\n')}';
  }

  Future<void> _runSync(
    String projectRootPath, {
    required bool dryRun,
  }) async {
    setState(() {
      _isSyncing = true;
      _lastSyncError = null;
    });

    try {
      final syncer = ref.read(pokemonMovesCatalogWorkspaceSyncerProvider);
      final result = await syncer(
        projectRootPath,
        dryRun: dryRun,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSyncing = false;
        _lastSyncResult = result;
        _lastSyncError = null;
        if (!dryRun) {
          _loadedProjectRootPath = null;
          _catalogFuture = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSyncing = false;
        _lastSyncError = 'Échec de la sync moves: $error';
      });
    }
  }

  List<PokemonMoveCatalogEntryView> _filterEntries(
    List<PokemonMoveCatalogEntryView> entries,
    String query,
  ) {
    if (query.isEmpty) {
      return entries;
    }
    final normalizedQuery = query.toLowerCase();
    return entries.where((entry) {
      return entry.name.toLowerCase().contains(normalizedQuery) ||
          entry.id.toLowerCase().contains(normalizedQuery) ||
          (entry.type?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (entry.category?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList(growable: false);
  }

  PokemonMoveCatalogEntryView? _resolveSelectedEntry(
    List<PokemonMoveCatalogEntryView> entries,
  ) {
    for (final entry in entries) {
      if (entry.id == _selectedMoveId) {
        return entry;
      }
    }
    if (entries.isEmpty) {
      return null;
    }
    return entries.first;
  }
}

class _MovesWorkspaceScaffold extends StatelessWidget {
  const _MovesWorkspaceScaffold({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemBackground.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: panelFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Moves',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Catalogue local des capacités du projet.',
            style: TextStyle(
              color: subtle,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MovesWorkspaceNotice extends StatelessWidget {
  const _MovesWorkspaceNotice({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemGrey6.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: subtle,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovesCatalogListPanel extends StatelessWidget {
  const _MovesCatalogListPanel({
    required this.searchController,
    required this.entries,
    required this.selectedEntryId,
    required this.diagnostics,
    required this.onEntrySelected,
  });

  final TextEditingController searchController;
  final List<PokemonMoveCatalogEntryView> entries;
  final String? selectedEntryId;
  final List<PokemonMovesCatalogDiagnostic> diagnostics;
  final ValueChanged<PokemonMoveCatalogEntryView> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemGrey6.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoSearchTextField(
            key: const Key('moves-catalog-search-field'),
            controller: searchController,
            placeholder: 'Recherche par nom, id, type ou catégorie',
          ),
          if (diagnostics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              diagnostics.length == 1
                  ? '1 entrée ignorée dans le catalogue.'
                  : '${diagnostics.length} entrées ignorées dans le catalogue.',
              key: const Key('moves-catalog-diagnostics-summary'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Aucun move ne correspond à cette recherche.',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    key: const Key('moves-catalog-list'),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _MovesCatalogListTile(
                        entry: entry,
                        selected: entry.id == selectedEntryId,
                        onTap: () => onEntrySelected(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MovesCatalogListTile extends StatelessWidget {
  const _MovesCatalogListTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final PokemonMoveCatalogEntryView entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final selectedFill = CupertinoColors.systemBlue.withValues(alpha: 0.12);
    final background = selected
        ? selectedFill
        : CupertinoColors.systemBackground.resolveFrom(context);

    return GestureDetector(
      key: Key('moves-catalog-entry-${entry.id}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.id} · ${_labelOrDash(entry.type)} · ${_labelOrDash(entry.category)}',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Power ${_intOrDash(entry.power)} · Accuracy ${entry.accuracyLabel} · PP ${_intOrDash(entry.pp)}',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovesCatalogDetailPanel extends StatelessWidget {
  const _MovesCatalogDetailPanel({
    required this.entry,
    required this.hasSearchQuery,
  });

  final PokemonMoveCatalogEntryView? entry;
  final bool hasSearchQuery;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemGrey6.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    if (entry == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: panelFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Text(
          hasSearchQuery
              ? 'Aucun move ne correspond à cette recherche.'
              : 'Sélectionne un move pour afficher ses détails.',
          style: TextStyle(
            color: subtle,
            height: 1.45,
          ),
        ),
      );
    }

    return Container(
      key: Key('moves-catalog-detail-${entry!.id}'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry!.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry!.id,
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _MovesCatalogDetailRow(label: 'Type', value: _labelOrDash(entry!.type)),
            _MovesCatalogDetailRow(
              label: 'Damage class',
              value: _labelOrDash(entry!.category),
            ),
            _MovesCatalogDetailRow(label: 'Power', value: _intOrDash(entry!.power)),
            _MovesCatalogDetailRow(
              label: 'Accuracy',
              value: entry!.accuracyLabel == '-' ? '—' : entry!.accuracyLabel,
            ),
            _MovesCatalogDetailRow(label: 'PP', value: _intOrDash(entry!.pp)),
            _MovesCatalogDetailRow(
              label: 'Priority',
              value: _intOrDash(entry!.priority),
            ),
            _MovesCatalogDetailRow(
              label: 'Target',
              value: _labelOrDash(entry!.target),
            ),
            _MovesCatalogDetailRow(
              label: 'Generation',
              value: _generationLabel(entry!),
            ),
            _MovesCatalogDetailRow(
              label: 'Short effect',
              value: _labelOrDash(entry!.shortEffectText ?? entry!.shortDesc),
            ),
            _MovesCatalogDetailRow(
              label: 'Effect text',
              value: _labelOrDash(entry!.effectText),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovesCatalogDetailRow extends StatelessWidget {
  const _MovesCatalogDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _labelOrDash(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '—' : trimmed;
}

String _intOrDash(int? value) {
  return value == null ? '—' : value.toString();
}

String _generationLabel(PokemonMoveCatalogEntryView entry) {
  if (entry.generationId != null && entry.generationId!.trim().isNotEmpty) {
    return entry.generationId!;
  }
  if (entry.generation != null) {
    return 'Gen ${entry.generation}';
  }
  return '—';
}

String _diagnosticsSummary(int count) {
  return count == 1
      ? '1 entrée ignorée dans le catalogue.'
      : '$count entrées ignorées dans le catalogue.';
}
