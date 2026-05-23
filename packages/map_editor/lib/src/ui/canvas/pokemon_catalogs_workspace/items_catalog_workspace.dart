import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../theme/theme.dart';
import '../../../app/providers/pokemon_items/pokemon_items_workspace_providers.dart';
import '../../../application/use_cases/load_pokemon_items_catalog_use_case.dart';
import '../../../application/use_cases/sync_pokemon_items_catalog_use_case.dart';
import '../../../features/editor/state/editor_selectors.dart';
import '../../shared/cupertino_editor_widgets.dart';

class PokemonItemsCatalogWorkspace extends ConsumerStatefulWidget {
  const PokemonItemsCatalogWorkspace({super.key});

  @override
  ConsumerState<PokemonItemsCatalogWorkspace> createState() =>
      _PokemonItemsCatalogWorkspaceState();
}

class _PokemonItemsCatalogWorkspaceState
    extends ConsumerState<PokemonItemsCatalogWorkspace> {
  late final TextEditingController _searchController;
  String? _selectedItemId;
  String? _loadedProjectRootPath;
  Future<PokemonItemsCatalogView>? _catalogFuture;
  bool _isSyncing = false;
  PokemonItemsCatalogSyncResult? _lastSyncResult;
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
          child: FutureBuilder<PokemonItemsCatalogView>(
            future: catalogFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: Text('Chargement du catalogue local des Items…'),
                );
              }
              if (snapshot.hasError) {
                return _ItemsWorkspaceNotice(
                  title: 'Catalogue illisible',
                  message: snapshot.error.toString(),
                );
              }
              return _buildCatalogContentBody(
                context,
                snapshot.data ??
                    const PokemonItemsCatalogView(
                      entries: <PokemonItemCatalogEntryView>[],
                      isAvailable: false,
                      description: 'Catalogue local des objets indisponible.',
                      loadState: PokemonItemsCatalogLoadState.loadError,
                    ),
                projectRootPath,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<PokemonItemsCatalogView> _loadCatalog(String? projectRootPath) async {
    final loader = ref.read(pokemonItemsCatalogWorkspaceLoaderProvider);
    return loader(projectRootPath);
  }

  Future<PokemonItemsCatalogView> _catalogFutureFor(String? projectRootPath) {
    if (_catalogFuture == null || _loadedProjectRootPath != projectRootPath) {
      _loadedProjectRootPath = projectRootPath;
      _catalogFuture = _loadCatalog(projectRootPath);
    }
    return _catalogFuture!;
  }

  Widget _buildCatalogContentBody(
    BuildContext context,
    PokemonItemsCatalogView view,
    String? projectRootPath,
  ) {
    final query = _searchController.text.trim();
    final filteredEntries = _filterEntries(view.entries, query);
    final selectedEntry = _resolveSelectedEntry(filteredEntries);

    if (view.loadState == PokemonItemsCatalogLoadState.noProject) {
      return const _ItemsWorkspaceNotice(
        title: 'Items',
        message: 'Ouvre un projet pour afficher le catalogue des items.',
      );
    }

    if (view.loadState == PokemonItemsCatalogLoadState.missingCatalog) {
      return _ItemsWorkspaceNotice(
        title: 'Items',
        message:
            'Aucun item local pour le moment.\nAjoute des entrées dans ${view.catalogRelativePath}. L’import PokeAPI sera traité dans un lot suivant.',
      );
    }

    if (view.loadState == PokemonItemsCatalogLoadState.loadError) {
      return _ItemsWorkspaceNotice(
        title: 'Items',
        message: view.message ?? 'Le catalogue local des items est illisible.',
      );
    }

    if (view.entries.isEmpty) {
      final String msg = view.diagnostics.isNotEmpty
          ? 'Le catalogue local des items contient uniquement des entrées invalides.\n${_diagnosticsSummary(view.diagnostics.length)}\nChemin lu : ${view.catalogRelativePath}'
          : 'Le catalogue local des items existe, mais il ne contient aucune entrée.\nChemin lu : ${view.catalogRelativePath}';
      return _ItemsWorkspaceNotice(
        title: 'Items',
        message: msg,
      );
    }

    final listPanel = _ItemsCatalogListPanel(
      searchController: _searchController,
      entries: filteredEntries,
      selectedEntryId: selectedEntry?.id,
      diagnostics: view.diagnostics,
      onEntrySelected: (entry) {
        setState(() {
          _selectedItemId = entry.id;
        });
      },
    );

    final detailPanel = _ItemsCatalogDetailPanel(
      entry: selectedEntry,
      hasSearchQuery: query.isNotEmpty,
      projectRootPath: projectRootPath,
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
                color: EditorChrome.accentWarm.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: EditorChrome.accentWarm.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.bag_fill,
                size: 18,
                color: EditorChrome.accentWarm,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: TextStyle(
                      color: label,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Catalogue local des objets du projet.',
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
                key: const Key('items-catalog-preview-sync-button'),
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
                          downloadSprites: false,
                        ),
                child: const Text('Preview sync'),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                key: const Key('items-catalog-run-sync-button'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                color: EditorChrome.accentWarm.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(14),
                onPressed: _isSyncing
                    ? null
                    : () => _runSync(
                          projectRootPath,
                          dryRun: false,
                          downloadSprites: true,
                        ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isSyncing ? 'Sync en cours…' : 'Sync depuis PokéAPI',
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
                color: EditorChrome.accentWarm.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              statusText,
              key: const Key('items-catalog-sync-status'),
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
    return '$prefix: ${result.createdIds.length} créé(s), ${result.updatedIds.length} mis à jour, ${result.unchangedIds.length} inchangé(s), ${result.downloadedSpriteIds.length} sprite(s) téléchargé(s).';
  }

  Future<void> _runSync(
    String projectRootPath, {
    required bool dryRun,
    required bool downloadSprites,
  }) async {
    setState(() {
      _isSyncing = true;
      _lastSyncError = null;
    });

    try {
      final syncer = ref.read(pokemonItemsCatalogWorkspaceSyncerProvider);
      final result = await syncer(
        projectRootPath,
        dryRun: dryRun,
        downloadSprites: downloadSprites,
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
        _lastSyncError = 'Échec de la sync items: $error';
      });
    }
  }

  List<PokemonItemCatalogEntryView> _filterEntries(
    List<PokemonItemCatalogEntryView> entries,
    String query,
  ) {
    if (query.isEmpty) {
      return entries;
    }
    final normalizedQuery = query.toLowerCase();
    return entries.where((entry) {
      return entry.name.toLowerCase().contains(normalizedQuery) ||
          entry.id.toLowerCase().contains(normalizedQuery) ||
          (entry.categoryId?.toLowerCase().contains(normalizedQuery) ??
              false) ||
          (entry.pocketId?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (entry.shortEffectText?.toLowerCase().contains(normalizedQuery) ??
              false) ||
          (entry.effectText?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (entry.flavorText?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (entry.shortDesc?.toLowerCase().contains(normalizedQuery) ?? false) ||
          entry.aliases.any(
            (alias) => alias.toLowerCase().contains(normalizedQuery),
          );
    }).toList(growable: false);
  }

  PokemonItemCatalogEntryView? _resolveSelectedEntry(
    List<PokemonItemCatalogEntryView> entries,
  ) {
    for (final entry in entries) {
      if (entry.id == _selectedItemId) {
        return entry;
      }
    }
    if (entries.isEmpty) {
      return null;
    }
    return entries.first;
  }
}

class _ItemsWorkspaceNotice extends StatelessWidget {
  const _ItemsWorkspaceNotice({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.35);
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

class _ItemsSearchField extends StatefulWidget {
  const _ItemsSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  State<_ItemsSearchField> createState() => _ItemsSearchFieldState();
}

class _ItemsSearchFieldState extends State<_ItemsSearchField> {
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
                key: const Key('items-catalog-search-field'),
                controller: widget.controller,
                onChanged: (_) => widget.onChanged(),
                clearButtonMode: OverlayVisibilityMode.editing,
                placeholder: 'Recherche un item',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsListHeader extends StatelessWidget {
  const _ItemsListHeader();

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
              'CATÉGORIE',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              'POCHE',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              'COÛT',
              style: _headerStyle(subtle),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'SPRITE STATUS',
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

class _ItemsCatalogListPanel extends StatelessWidget {
  const _ItemsCatalogListPanel({
    required this.searchController,
    required this.entries,
    required this.selectedEntryId,
    required this.diagnostics,
    required this.onEntrySelected,
  });

  final TextEditingController searchController;
  final List<PokemonItemCatalogEntryView> entries;
  final String? selectedEntryId;
  final List<PokemonItemsCatalogDiagnostic> diagnostics;
  final ValueChanged<PokemonItemCatalogEntryView> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ItemsSearchField(
          controller: searchController,
          onChanged: () {},
        ),
        if (diagnostics.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            diagnostics.length == 1
                ? '1 entrée ignorée dans le catalogue.'
                : '${diagnostics.length} entrées ignorées dans le catalogue.',
            key: const Key('items-catalog-diagnostics-summary'),
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (entries.isNotEmpty) ...[
          const _ItemsListHeader(),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Text(
                    'Aucun item ne correspond à cette recherche.',
                    style: TextStyle(
                      color: subtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  key: const Key('items-catalog-list'),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _ItemsCatalogListEntry(
                      entry: entry,
                      isSelected: entry.id == selectedEntryId,
                      onTap: () => onEntrySelected(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ItemsCatalogListEntry extends StatelessWidget {
  const _ItemsCatalogListEntry({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  final PokemonItemCatalogEntryView entry;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    final surface = isSelected
        ? Color.lerp(
            EditorChrome.islandFillElevated(context),
            EditorChrome.accentWarm,
            0.12,
          )!
        : EditorChrome.islandFillElevated(context);
    final border = isSelected
        ? EditorChrome.accentWarm.withValues(alpha: 0.65)
        : EditorChrome.accentWarm.withValues(alpha: 0.35);

    return CupertinoButton(
      key: Key('items-catalog-entry-${entry.id}'),
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: isSelected ? 1.4 : 1),
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
                child: Text(
                  _labelOrDash(entry.categoryId),
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  _labelOrDash(entry.pocketId),
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
                  _labelOrDash(entry.cost),
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _ItemsSpriteStatusChip(
                    hasSprite: entry.hasSpriteMetadata,
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

class _ItemsSpriteStatusChip extends StatelessWidget {
  const _ItemsSpriteStatusChip({required this.hasSprite});

  final bool hasSprite;

  @override
  Widget build(BuildContext context) {
    final accent = hasSprite ? EditorChrome.accentJade : EditorChrome.accentWarm;
    final text = EditorChrome.primaryLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          hasSprite ? 'Sprite' : 'No Sprite',
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

class _ItemsCatalogDetailPanel extends StatelessWidget {
  const _ItemsCatalogDetailPanel({
    required this.entry,
    required this.hasSearchQuery,
    required this.projectRootPath,
  });

  final PokemonItemCatalogEntryView? entry;
  final bool hasSearchQuery;
  final String? projectRootPath;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.35);
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
                  ? 'Aucun item ne correspond à cette recherche.'
                  : 'Sélectionne un item pour afficher ses détails.',
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
      key: Key('items-catalog-detail-${entry!.id}'),
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
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                entry!.id,
                style: TextStyle(
                  color: subtle,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _ItemsDetailField(label: 'ID', value: entry!.id),
              _ItemsDetailField(label: 'Category', value: _labelOrDash(entry!.categoryId)),
              _ItemsDetailField(label: 'Pocket', value: _labelOrDash(entry!.pocketId)),
              _ItemsDetailField(label: 'Cost', value: _labelOrDash(entry!.cost)),
              _ItemsDetailField(
                label: 'Fling power',
                value: _labelOrDash(entry!.flingPower),
              ),
              _ItemsDetailField(
                label: 'Fling effect',
                value: _labelOrDash(entry!.flingEffectId),
              ),
              _ItemsDetailField(
                label: 'Short effect',
                value: _labelOrDash(entry!.shortEffectText ?? entry!.shortDesc),
              ),
              _ItemsDetailField(
                label: 'Effect text',
                value: _labelOrDash(entry!.effectText),
                multiLine: true,
              ),
              _ItemsDetailField(
                label: 'Flavor text',
                value: _labelOrDash(entry!.flavorText),
                multiLine: true,
              ),
              const SizedBox(height: 12),
              Text(
                entry!.hasSpriteMetadata
                    ? 'Sprite metadata available'
                    : 'No sprite metadata',
                style: TextStyle(
                  color: label,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              PokemonItemsCatalogSpritePreview(
                projectRootPath: projectRootPath,
                localSpritePath: entry!.localSpritePath,
                spriteUrl: entry!.spriteUrl,
              ),
              const SizedBox(height: 12),
              _ItemsDetailField(
                label: 'Sprite URL',
                value: _labelOrDash(entry!.spriteUrl),
                multiLine: true,
              ),
              _ItemsDetailField(
                label: 'Local sprite path',
                value: _labelOrDash(entry!.localSpritePath),
                multiLine: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PokemonItemsCatalogSpritePreview extends StatelessWidget {
  const PokemonItemsCatalogSpritePreview({
    super.key,
    required this.projectRootPath,
    required this.localSpritePath,
    required this.spriteUrl,
  });

  final String? projectRootPath;
  final String? localSpritePath;
  final String? spriteUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final border = colors.borderSubtle;
    final mutedFill = colors.surfaceSubtle;
    final subtle = colors.textMuted;
    final hasLocalSprite = hasPokemonItemsLocalSpriteAsset(
      projectRootPath: projectRootPath,
      localSpritePath: localSpritePath,
    );

    if (hasLocalSprite) {
      return Container(
        key: const Key('items-catalog-local-sprite-preview'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: mutedFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceHover,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              alignment: Alignment.center,
              child: const Text(
                'PNG',
                key: Key('items-catalog-local-sprite-indicator'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Sprite local chargé depuis ${_labelOrDash(localSpritePath)}',
                style: TextStyle(
                  color: subtle,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final hasLocalPath = localSpritePath != null && localSpritePath!.trim().isNotEmpty;
    final hasRemoteMetadata = spriteUrl != null && spriteUrl!.trim().isNotEmpty;
    final message = hasLocalPath
        ? 'Le sprite local indiqué est introuvable pour le moment.'
        : hasRemoteMetadata
            ? 'Sprite disponible après sync assets.'
            : 'No sprite metadata';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: mutedFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: subtle,
          height: 1.4,
        ),
      ),
    );
  }
}

class _ItemsDetailField extends StatelessWidget {
  const _ItemsDetailField({
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  final String label;
  final String value;
  final bool multiLine;

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
            maxLines: multiLine ? null : 2,
            overflow: multiLine ? null : TextOverflow.ellipsis,
            style: TextStyle(
              color: labelColor,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _labelOrDash(Object? value) {
  if (value == null) {
    return '—';
  }
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }
  return value.toString();
}

String _diagnosticsSummary(int count) {
  return count == 1
      ? '1 entrée ignorée dans le catalogue.'
      : '$count entrées ignorées dans le catalogue.';
}

bool hasPokemonItemsLocalSpriteAsset({
  required String? projectRootPath,
  required String? localSpritePath,
}) {
  final normalizedProjectRoot = projectRootPath?.trim();
  final normalizedLocalSpritePath = localSpritePath?.trim();
  if (normalizedProjectRoot == null ||
      normalizedProjectRoot.isEmpty ||
      normalizedLocalSpritePath == null ||
      normalizedLocalSpritePath.isEmpty) {
    return false;
  }

  final absolutePath = p.normalize(
    p.join(normalizedProjectRoot, normalizedLocalSpritePath),
  );
  final file = File(absolutePath);
  try {
    return file.existsSync() && file.lengthSync() > 0;
  } on FileSystemException {
    return false;
  }
}
