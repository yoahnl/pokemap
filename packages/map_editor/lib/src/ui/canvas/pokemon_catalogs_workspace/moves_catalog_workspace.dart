import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../../features/editor/state/editor_selectors.dart';
import '../../shared/cupertino_editor_widgets.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPageHeader(context, projectRootPath),
        const SizedBox(height: 14),
        Expanded(
          child: FutureBuilder<PokemonMovesCatalogView>(
            future: catalogFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Text('Chargement du catalogue local des Moves…'),
                );
              }
              if (snapshot.hasError) {
                return _MovesWorkspaceNotice(
                  title: 'Catalogue illisible',
                  message: snapshot.error.toString(),
                );
              }
              return _buildCatalogContentBody(
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
      ],
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

  Widget _buildCatalogContentBody(
    BuildContext context,
    PokemonMovesCatalogView view,
    String? projectRootPath,
  ) {
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
      return _MovesWorkspaceNotice(
        title: 'Moves',
        message:
            'Aucun move local pour le moment.\nAjoute des entrées dans ${view.catalogRelativePath}. L’import externe sera traité dans un lot suivant.',
      );
    }

    if (view.loadState == PokemonMovesCatalogLoadState.loadError) {
      return _MovesWorkspaceNotice(
        title: 'Moves',
        message:
            view.message ?? 'Le catalogue local des moves est illisible.',
      );
    }

    if (view.entries.isEmpty) {
      final String msg = view.diagnostics.isNotEmpty
          ? 'Le catalogue local des moves contient uniquement des entrées invalides.\n${_diagnosticsSummary(view.diagnostics.length)}\nChemin lu : ${view.catalogRelativePath}'
          : 'Le catalogue local des moves existe, mais il ne contient aucune entrée.\nChemin lu : ${view.catalogRelativePath}';
      return _MovesWorkspaceNotice(
        title: 'Moves',
        message: msg,
      );
    }

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: listPanel,
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 480,
          child: detailPanel,
        ),
      ],
    );
  }

  Widget _buildPageHeader(BuildContext context, String? projectRootPath) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final hasProject = projectRootPath != null && projectRootPath.trim().isNotEmpty;
    final statusText = _buildSyncStatusText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: EditorChrome.accentLilac.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EditorChrome.accentLilac.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.bolt_fill,
                size: 18,
                color: EditorChrome.accentLilac,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moves',
                    style: TextStyle(
                      color: label,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catalogue local des capacités du projet.',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            if (hasProject) ...[
              const SizedBox(width: 12),
              CupertinoButton(
                key: const Key('moves-catalog-preview-sync-button'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                color: EditorChrome.islandFillElevated(context),
                borderRadius: BorderRadius.circular(14),
                onPressed: _isSyncing
                    ? null
                    : () => _runSync(
                          projectRootPath,
                          dryRun: true,
                        ),
                child: const Text('Prévisualiser la synchro'),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                key: const Key('moves-catalog-run-sync-button'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                color: EditorChrome.accentLilac.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(14),
                onPressed: _isSyncing
                    ? null
                    : () => _runSync(
                          projectRootPath,
                          dryRun: false,
                        ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSyncing ? 'Sync en cours…' : 'Sync depuis Showdown',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isSyncing) ...[
                      const SizedBox(width: 8),
                      const CupertinoActivityIndicator(radius: 6),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        if (statusText != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: EditorChrome.accentLilac.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              statusText,
              key: const Key('moves-catalog-sync-status'),
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
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

class _MovesWorkspaceNotice extends StatelessWidget {
  const _MovesWorkspaceNotice({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentLilac.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: 1),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: label,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovesSearchField extends StatefulWidget {
  const _MovesSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  State<_MovesSearchField> createState() => _MovesSearchFieldState();
}

class _MovesSearchFieldState extends State<_MovesSearchField> {
  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.search,
              color: subtle,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CupertinoTextField.borderless(
                key: const Key('moves-catalog-search-field'),
                controller: widget.controller,
                onChanged: (_) => widget.onChanged(),
                clearButtonMode: OverlayVisibilityMode.editing,
                placeholder: 'Recherche par nom, id, type ou catégorie',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovesListHeader extends StatelessWidget {
  const _MovesListHeader();

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'NOM / ID',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'TYPE',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'CATÉGORIE',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              'POWER',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              'ACC',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 50,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'PP',
                style: _headerStyle(subtle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle(Color color) {
    return TextStyle(
      color: color,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
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
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MovesSearchField(
          controller: searchController,
          onChanged: () {},
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
        if (entries.isNotEmpty) ...[
          const _MovesListHeader(),
          const SizedBox(height: 8),
        ],
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
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final surface = selected
        ? Color.lerp(
            EditorChrome.islandFillElevated(context),
            EditorChrome.accentLilac,
            0.12,
          )!
        : EditorChrome.islandFillElevated(context);
    final border = selected
        ? EditorChrome.accentLilac.withValues(alpha: 0.65)
        : EditorChrome.accentWarm.withValues(alpha: 0.35);

    return CupertinoButton(
      key: Key('moves-catalog-entry-${entry.id}'),
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: selected ? 1.4 : 1),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: TextStyle(
                        color: label,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.id,
                      style: TextStyle(
                        color: subtle,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _MovesTypeChip(label: _labelOrDash(entry.type)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  _labelOrDash(entry.category),
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 70,
                child: Text(
                  _intOrDash(entry.power),
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 70,
                child: Text(
                  entry.accuracyLabel == '-' ? '—' : entry.accuracyLabel,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 50,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _intOrDash(entry.pp),
                    style: TextStyle(
                      color: label,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovesTypeChip extends StatelessWidget {
  const _MovesTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentLilac,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentLilac.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
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
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentLilac.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    if (entry == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border, width: 1),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              hasSearchQuery
                  ? 'Aucun move ne correspond à cette recherche.'
                  : 'Sélectionne un move pour afficher ses détails.',
              style: TextStyle(
                color: subtle,
                height: 1.45,
              ),
            ),
          ),
        ),
      );
    }

    return DecoratedBox(
      key: Key('moves-catalog-detail-${entry!.id}'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry!.name,
                style: TextStyle(
                  color: label,
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
    final subtle = EditorChrome.subtleLabel(context);
    final labelColor = EditorChrome.primaryLabel(context);

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
            style: TextStyle(
              color: labelColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
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
