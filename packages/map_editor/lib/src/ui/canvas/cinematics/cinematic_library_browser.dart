import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/narrative_document_route.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

enum CinematicLibraryViewMode { list, grid }

enum CinematicLibraryBrowserLoadState { content, loading, error }

typedef OpenPresentationCinematicCallback =
    void Function({
      required String cinematicId,
      required NarrativeLibrarySourceContext source,
    });

final class CinematicLibraryFamilyNavigation {
  const CinematicLibraryFamilyNavigation({
    required this.family,
    this.folderId,
    this.searchQuery = '',
    this.sort = NarrativeLibrarySort.manual,
    this.visibility = NarrativeLibraryVisibility.active,
    this.selectedAssetId,
    this.scrollOffset = 0,
    this.viewMode = CinematicLibraryViewMode.list,
  });

  final CinematicLibraryFamily family;
  final String? folderId;
  final String searchQuery;
  final NarrativeLibrarySort sort;
  final NarrativeLibraryVisibility visibility;
  final String? selectedAssetId;
  final double scrollOffset;
  final CinematicLibraryViewMode viewMode;

  CinematicLibraryFamilyNavigation copyWith({
    Object? folderId = _unset,
    String? searchQuery,
    NarrativeLibrarySort? sort,
    NarrativeLibraryVisibility? visibility,
    Object? selectedAssetId = _unset,
    double? scrollOffset,
    CinematicLibraryViewMode? viewMode,
  }) => CinematicLibraryFamilyNavigation(
    family: family,
    folderId: identical(folderId, _unset) ? this.folderId : folderId as String?,
    searchQuery: searchQuery ?? this.searchQuery,
    sort: sort ?? this.sort,
    visibility: visibility ?? this.visibility,
    selectedAssetId: identical(selectedAssetId, _unset)
        ? this.selectedAssetId
        : selectedAssetId as String?,
    scrollOffset: scrollOffset ?? this.scrollOffset,
    viewMode: viewMode ?? this.viewMode,
  );

  NarrativeLibrarySourceContext toSourceContext() =>
      NarrativeLibrarySourceContext(
        library: NarrativeLibraryKind.cinematics,
        cinematicFamily: family,
        folderId: folderId,
        searchQuery: searchQuery,
        sort: sort,
        visibility: visibility,
        selectedAssetId: selectedAssetId,
        scrollOffset: scrollOffset,
      );
}

final class CinematicLibraryNavigationState {
  const CinematicLibraryNavigationState({
    required this.activeFamily,
    required this.inGame,
    required this.presentation,
    this.folderWasInaccessible = false,
  });

  factory CinematicLibraryNavigationState.initial({
    NarrativeLibrarySourceContext? restoredPresentation,
  }) => CinematicLibraryNavigationState(
    activeFamily: restoredPresentation == null
        ? CinematicLibraryFamily.world
        : CinematicLibraryFamily.presentation,
    inGame: const CinematicLibraryFamilyNavigation(
      family: CinematicLibraryFamily.world,
    ),
    presentation: restoredPresentation == null
        ? const CinematicLibraryFamilyNavigation(
            family: CinematicLibraryFamily.presentation,
          )
        : CinematicLibraryFamilyNavigation(
            family: CinematicLibraryFamily.presentation,
            folderId: restoredPresentation.folderId,
            searchQuery: restoredPresentation.searchQuery,
            sort: restoredPresentation.sort,
            visibility: restoredPresentation.visibility,
            selectedAssetId: restoredPresentation.selectedAssetId,
            scrollOffset: restoredPresentation.scrollOffset,
          ),
  );

  final CinematicLibraryFamily activeFamily;
  final CinematicLibraryFamilyNavigation inGame;
  final CinematicLibraryFamilyNavigation presentation;
  final bool folderWasInaccessible;

  CinematicLibraryFamilyNavigation get active =>
      activeFamily == CinematicLibraryFamily.world ? inGame : presentation;

  CinematicLibraryNavigationState switchFamily(CinematicLibraryFamily family) =>
      CinematicLibraryNavigationState(
        activeFamily: family,
        inGame: inGame,
        presentation: presentation,
      );

  CinematicLibraryNavigationState updateActive({
    Object? folderId = _unset,
    String? searchQuery,
    NarrativeLibrarySort? sort,
    NarrativeLibraryVisibility? visibility,
    Object? selectedAssetId = _unset,
    double? scrollOffset,
    CinematicLibraryViewMode? viewMode,
  }) {
    final updated = active.copyWith(
      folderId: folderId,
      searchQuery: searchQuery,
      sort: sort,
      visibility: visibility,
      selectedAssetId: selectedAssetId,
      scrollOffset: scrollOffset,
      viewMode: viewMode,
    );
    return CinematicLibraryNavigationState(
      activeFamily: activeFamily,
      inGame: activeFamily == CinematicLibraryFamily.world ? updated : inGame,
      presentation: activeFamily == CinematicLibraryFamily.presentation
          ? updated
          : presentation,
    );
  }

  CinematicLibraryNavigationState normalize(CinematicLibraryCatalog catalog) {
    final folderId = active.folderId;
    if (folderId == null) {
      return this;
    }
    final available = catalog.folders.any(
      (folder) =>
          folder.id == folderId &&
          folder.family == activeFamily &&
          _matchesVisibility(folder.isArchived, active.visibility),
    );
    if (available) return this;
    final normalized = active.copyWith(
      folderId: null,
      selectedAssetId: null,
      scrollOffset: 0,
    );
    return CinematicLibraryNavigationState(
      activeFamily: activeFamily,
      inGame: activeFamily == CinematicLibraryFamily.world
          ? normalized
          : inGame,
      presentation: activeFamily == CinematicLibraryFamily.presentation
          ? normalized
          : presentation,
      folderWasInaccessible: true,
    );
  }
}

class CinematicLibraryBrowser extends StatefulWidget {
  const CinematicLibraryBrowser({
    super.key,
    required this.project,
    required this.navigation,
    required this.onNavigationChanged,
    required this.onOpenInGame,
    required this.onOpenPresentation,
    this.loadState = CinematicLibraryBrowserLoadState.content,
    this.errorMessage,
  });

  final ProjectManifest project;
  final CinematicLibraryNavigationState navigation;
  final ValueChanged<CinematicLibraryNavigationState> onNavigationChanged;
  final ValueChanged<String> onOpenInGame;
  final OpenPresentationCinematicCallback onOpenPresentation;
  final CinematicLibraryBrowserLoadState loadState;
  final String? errorMessage;

  @override
  State<CinematicLibraryBrowser> createState() =>
      _CinematicLibraryBrowserState();
}

class _CinematicLibraryBrowserState extends State<CinematicLibraryBrowser> {
  late final TextEditingController _searchController;
  ScrollController? _scrollController;
  CinematicLibraryFamily? _scrollFamily;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.navigation.active.searchQuery,
    );
    _replaceScrollController();
  }

  @override
  void didUpdateWidget(covariant CinematicLibraryBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    final active = widget.navigation.active;
    if (_searchController.text != active.searchQuery) {
      _searchController.value = TextEditingValue(
        text: active.searchQuery,
        selection: TextSelection.collapsed(offset: active.searchQuery.length),
      );
    }
    if (_scrollFamily != widget.navigation.activeFamily) {
      _replaceScrollController();
      return;
    }
    final previous = oldWidget.navigation.active;
    if (previous.folderId != active.folderId ||
        previous.searchQuery != active.searchQuery ||
        previous.sort != active.sort ||
        previous.visibility != active.visibility ||
        previous.viewMode != active.viewMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = _scrollController;
        if (!mounted || controller == null || !controller.hasClients) return;
        controller.jumpTo(
          active.scrollOffset.clamp(0, controller.position.maxScrollExtent),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  void _replaceScrollController() {
    _scrollController?.dispose();
    _scrollFamily = widget.navigation.activeFamily;
    _scrollController = ScrollController(
      initialScrollOffset: widget.navigation.active.scrollOffset,
    )..addListener(_rememberScroll);
  }

  void _rememberScroll() {
    final controller = _scrollController;
    if (controller == null || !controller.hasClients) return;
    final offset = controller.offset;
    if ((offset - widget.navigation.active.scrollOffset).abs() < 0.5) return;
    widget.onNavigationChanged(
      widget.navigation.updateActive(scrollOffset: offset),
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalized = widget.navigation.normalize(
      widget.project.cinematicLibraryCatalog,
    );
    if (normalized != widget.navigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onNavigationChanged(normalized);
      });
    }
    final navigation = normalized;
    final snapshot = _CinematicLibrarySnapshot.build(
      widget.project,
      navigation.active,
    );
    final familyMode = navigation.activeFamily == CinematicLibraryFamily.world
        ? PokeMapCinematicLibraryMode.inGame
        : PokeMapCinematicLibraryMode.presentation;

    return PokeMapPanel(
      key: const ValueKey('cinematic-family-library'),
      expandChild: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapCinematicFamilyTabs(
            selected: familyMode,
            inGameLabel: 'Cinématiques in-game',
            presentationLabel: 'Cinématiques de présentation',
            onChanged: (mode) {
              final family = mode == PokeMapCinematicLibraryMode.inGame
                  ? CinematicLibraryFamily.world
                  : CinematicLibraryFamily.presentation;
              widget.onNavigationChanged(navigation.switchFamily(family));
            },
          ),
          const SizedBox(height: 14),
          _LibraryHeader(
            family: navigation.activeFamily,
            assetCount: snapshot.familyAssetCount,
            selectedAssetId: navigation.active.selectedAssetId,
            onOpen: navigation.active.selectedAssetId == null
                ? null
                : () => _openSelection(navigation.active),
          ),
          const SizedBox(height: 12),
          PokeMapCinematicBreadcrumb(
            semanticLabel: 'Chemin de la bibliothèque de cinématiques',
            items: snapshot.breadcrumbs
                .map(
                  (item) => PokeMapCinematicBreadcrumbItem(
                    label: item.name,
                    onPressed: item.isCurrent
                        ? null
                        : () => _openFolder(navigation, item.id),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          _LibraryControls(
            searchController: _searchController,
            navigation: navigation.active,
            onSearchChanged: (value) => widget.onNavigationChanged(
              navigation.updateActive(
                searchQuery: value,
                selectedAssetId: null,
                scrollOffset: 0,
              ),
            ),
            onSortChanged: (value) => widget.onNavigationChanged(
              navigation.updateActive(sort: value, scrollOffset: 0),
            ),
            onVisibilityChanged: (value) => widget.onNavigationChanged(
              navigation.updateActive(
                visibility: value,
                selectedAssetId: null,
                scrollOffset: 0,
              ),
            ),
            onViewModeChanged: (value) => widget.onNavigationChanged(
              navigation.updateActive(viewMode: value, scrollOffset: 0),
            ),
          ),
          const SizedBox(height: 12),
          if (navigation.folderWasInaccessible) ...[
            const PokeMapActionBanner(
              tone: PokeMapTone.warning,
              title: 'Dossier indisponible',
              message:
                  'Le dossier a été déplacé ou supprimé. La bibliothèque est revenue à sa racine sans modifier son contenu.',
            ),
            const SizedBox(height: 12),
          ],
          Expanded(child: _buildContent(navigation, snapshot)),
        ],
      ),
    );
  }

  Widget _buildContent(
    CinematicLibraryNavigationState navigation,
    _CinematicLibrarySnapshot snapshot,
  ) {
    if (widget.loadState == CinematicLibraryBrowserLoadState.loading) {
      return const Center(
        child: PokeMapCinematicLibraryStateSurface(
          state: PokeMapCinematicLibraryState.loading,
          title: 'Chargement des cinématiques…',
          description: 'Lecture du catalogue et de ses dossiers.',
        ),
      );
    }
    if (widget.loadState == CinematicLibraryBrowserLoadState.error) {
      return Center(
        child: PokeMapCinematicLibraryStateSurface(
          state: PokeMapCinematicLibraryState.error,
          title: 'Bibliothèque indisponible',
          description:
              widget.errorMessage ??
              'Le catalogue n’a pas pu être chargé. Le projet reste intact.',
        ),
      );
    }
    if (snapshot.items.isEmpty) {
      final searching = navigation.active.searchQuery.trim().isNotEmpty;
      return Center(
        child: PokeMapCinematicLibraryStateSurface(
          state: PokeMapCinematicLibraryState.empty,
          title: searching ? 'Aucun résultat' : 'Bibliothèque vide',
          description: searching
              ? 'Aucune cinématique ni aucun dossier ne correspond à la recherche.'
              : 'Cette famille ne contient encore aucune cinématique dans ce dossier.',
        ),
      );
    }
    if (navigation.active.viewMode == CinematicLibraryViewMode.grid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1040
              ? 4
              : constraints.maxWidth >= 760
              ? 3
              : constraints.maxWidth >= 480
              ? 2
              : 1;
          return GridView.builder(
            key: navigation.activeFamily == CinematicLibraryFamily.world
                ? const ValueKey('cinematics-library-list')
                : const ValueKey('cinematic-grid-presentation'),
            controller: _scrollController,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.7,
            ),
            itemCount: snapshot.items.length,
            itemBuilder: (context, index) =>
                _buildItem(navigation, snapshot.items[index]),
          );
        },
      );
    }
    return ListView.separated(
      key: navigation.activeFamily == CinematicLibraryFamily.world
          ? const ValueKey('cinematics-library-list')
          : const ValueKey('cinematic-list-presentation'),
      controller: _scrollController,
      itemCount: snapshot.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) =>
          _buildItem(navigation, snapshot.items[index]),
    );
  }

  Widget _buildItem(
    CinematicLibraryNavigationState navigation,
    _CinematicLibraryItem item,
  ) => switch (item) {
    _CinematicLibraryFolderItem(:final folder) => PokeMapAssetCard(
      key: ValueKey('cinematic-folder-${folder.id}'),
      thumbnail: const Icon(Icons.folder_outlined),
      label: folder.name,
      description: 'Dossier',
      onPressed: () => _openFolder(navigation, folder.id),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
    _CinematicLibraryAssetItem(:final asset) => PokeMapAssetCard(
      key: ValueKey(
        navigation.activeFamily == CinematicLibraryFamily.world
            ? 'cinematic-entry-${asset.id}'
            : 'cinematic-asset-${asset.id}',
      ),
      thumbnail: Icon(
        navigation.activeFamily == CinematicLibraryFamily.world
            ? Icons.videogame_asset_outlined
            : Icons.movie_creation_outlined,
      ),
      label: asset.title,
      description: asset.description,
      selected: navigation.active.selectedAssetId == asset.id,
      onPressed: () => widget.onNavigationChanged(
        navigation.updateActive(selectedAssetId: asset.id),
      ),
      trailing: Icon(
        navigation.active.selectedAssetId == asset.id
            ? Icons.check_circle_outline
            : Icons.chevron_right_rounded,
      ),
    ),
  };

  void _openFolder(
    CinematicLibraryNavigationState navigation,
    String? folderId,
  ) {
    widget.onNavigationChanged(
      navigation.updateActive(
        folderId: folderId,
        searchQuery: '',
        selectedAssetId: null,
        scrollOffset: 0,
      ),
    );
  }

  void _openSelection(CinematicLibraryFamilyNavigation navigation) {
    final selected = navigation.selectedAssetId;
    if (selected == null) return;
    if (navigation.family == CinematicLibraryFamily.world) {
      widget.onOpenInGame(selected);
      return;
    }
    widget.onOpenPresentation(
      cinematicId: selected,
      source: navigation.toSourceContext(),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.family,
    required this.assetCount,
    required this.selectedAssetId,
    required this.onOpen,
  });

  final CinematicLibraryFamily family;
  final int assetCount;
  final String? selectedAssetId;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                family == CinematicLibraryFamily.world
                    ? 'Bibliothèque in-game'
                    : 'Bibliothèque de présentation',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$assetCount cinématique${assetCount > 1 ? 's' : ''}',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
        PokeMapButton(
          key: ValueKey(
            family == CinematicLibraryFamily.world
                ? 'cinematics-library-open-builder-button'
                : 'cinematic-open-selection',
          ),
          onPressed: onOpen,
          disabledReason: selectedAssetId == null
              ? 'Sélectionnez une cinématique à ouvrir.'
              : null,
          leading: const Icon(Icons.open_in_new_rounded),
          child: const Text('Ouvrir'),
        ),
      ],
    );
  }
}

class _LibraryControls extends StatelessWidget {
  const _LibraryControls({
    required this.searchController,
    required this.navigation,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onVisibilityChanged,
    required this.onViewModeChanged,
  });

  final TextEditingController searchController;
  final CinematicLibraryFamilyNavigation navigation;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<NarrativeLibrarySort> onSortChanged;
  final ValueChanged<NarrativeLibraryVisibility> onVisibilityChanged;
  final ValueChanged<CinematicLibraryViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = PokeMapSearchField(
          key: const ValueKey('cinematic-family-search'),
          controller: searchController,
          hintText: 'Rechercher une cinématique ou un dossier…',
          semanticLabel: 'Rechercher dans la famille active',
          onChanged: onSearchChanged,
        );
        final sort = SizedBox(
          width: 180,
          child: PokeMapDropdownField<NarrativeLibrarySort>(
            key: const ValueKey('cinematic-family-sort'),
            label: 'Trier',
            value: navigation.sort,
            compact: true,
            items: const [
              PokeMapDropdownItem(
                value: NarrativeLibrarySort.manual,
                label: 'Ordre manuel',
              ),
              PokeMapDropdownItem(
                value: NarrativeLibrarySort.nameAscending,
                label: 'Nom A–Z',
              ),
              PokeMapDropdownItem(
                value: NarrativeLibrarySort.nameDescending,
                label: 'Nom Z–A',
              ),
              PokeMapDropdownItem(
                value: NarrativeLibrarySort.updatedDescending,
                label: 'Modifiées récemment',
              ),
            ],
            onChanged: onSortChanged,
          ),
        );
        final visibility = SizedBox(
          width: 150,
          child: PokeMapDropdownField<NarrativeLibraryVisibility>(
            key: const ValueKey('cinematic-family-visibility'),
            label: 'Afficher',
            value: navigation.visibility,
            compact: true,
            items: const [
              PokeMapDropdownItem(
                value: NarrativeLibraryVisibility.active,
                label: 'Actives',
              ),
              PokeMapDropdownItem(
                value: NarrativeLibraryVisibility.archived,
                label: 'Archivées',
              ),
              PokeMapDropdownItem(
                value: NarrativeLibraryVisibility.all,
                label: 'Toutes',
              ),
            ],
            onChanged: onVisibilityChanged,
          ),
        );
        final modes = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PokeMapIconButton(
              key: const ValueKey('cinematic-view-list'),
              onPressed: () => onViewModeChanged(CinematicLibraryViewMode.list),
              tooltip: 'Vue en liste',
              semanticLabel: 'Afficher en liste',
              isSelected: navigation.viewMode == CinematicLibraryViewMode.list,
              variant: PokeMapIconButtonVariant.soft,
              icon: const Icon(Icons.view_list_outlined),
            ),
            const SizedBox(width: 6),
            PokeMapIconButton(
              key: const ValueKey('cinematic-view-grid'),
              onPressed: () => onViewModeChanged(CinematicLibraryViewMode.grid),
              tooltip: 'Vue en grille',
              semanticLabel: 'Afficher en grille',
              isSelected: navigation.viewMode == CinematicLibraryViewMode.grid,
              variant: PokeMapIconButtonVariant.soft,
              icon: const Icon(Icons.grid_view_outlined),
            ),
          ],
        );
        if (constraints.maxWidth < 700) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: sort),
                  const SizedBox(width: 8),
                  Expanded(child: visibility),
                  const SizedBox(width: 8),
                  modes,
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 10),
            sort,
            const SizedBox(width: 10),
            visibility,
            const SizedBox(width: 10),
            modes,
          ],
        );
      },
    );
  }
}

final class _CinematicLibrarySnapshot {
  const _CinematicLibrarySnapshot({
    required this.familyAssetCount,
    required this.breadcrumbs,
    required this.items,
  });

  factory _CinematicLibrarySnapshot.build(
    ProjectManifest project,
    CinematicLibraryFamilyNavigation navigation,
  ) {
    final catalog = project.cinematicLibraryCatalog;
    final folders = catalog.folders
        .where(
          (folder) =>
              folder.family == navigation.family &&
              _matchesVisibility(folder.isArchived, navigation.visibility),
        )
        .toList(growable: false);
    final foldersById = {for (final folder in folders) folder.id: folder};
    final assets = navigation.family == CinematicLibraryFamily.world
        ? <_CinematicAssetSummary>[
            for (final asset in project.cinematics)
              _CinematicAssetSummary(
                id: asset.id,
                title: asset.title,
                description: asset.description?.trim().isNotEmpty == true
                    ? asset.description!
                    : 'Cinématique in-game',
                isArchived: isCinematicArchived(asset),
              ),
          ]
        : <_CinematicAssetSummary>[
            for (final asset in project.presentationCinematics)
              _CinematicAssetSummary(
                id: asset.id,
                title: asset.title,
                description: asset.description?.trim().isNotEmpty == true
                    ? asset.description!
                    : _formatDuration(asset.durationUs),
                isArchived: false,
              ),
          ];
    final assetById = {for (final asset in assets) asset.id: asset};
    final placements = <String, CinematicLibraryEntry>{
      for (final entry in catalog.entries)
        if (entry.family == navigation.family &&
            assetById.containsKey(entry.cinematicId))
          entry.cinematicId: entry,
    };
    final query = navigation.searchQuery.trim().toLowerCase();
    final visibleFolders = folders
        .where((folder) {
          if (query.isNotEmpty) {
            return folder.name.toLowerCase().contains(query);
          }
          return folder.parentFolderId == navigation.folderId;
        })
        .toList(growable: false);
    final visibleAssets = assets
        .where((asset) {
          final placement = placements[asset.id];
          final archived = placement?.isArchived ?? asset.isArchived;
          if (!_matchesVisibility(archived, navigation.visibility)) {
            return false;
          }
          if (query.isNotEmpty) {
            return asset.title.toLowerCase().contains(query) ||
                asset.description.toLowerCase().contains(query);
          }
          return placement?.folderId == navigation.folderId;
        })
        .toList(growable: false);
    _sortFolders(visibleFolders, navigation.sort);
    _sortAssets(visibleAssets, navigation.sort, placements);
    final breadcrumbs = <_CinematicBreadcrumb>[
      _CinematicBreadcrumb(
        id: null,
        name: navigation.family == CinematicLibraryFamily.world
            ? 'In-game'
            : 'Présentation',
        isCurrent: navigation.folderId == null,
      ),
    ];
    final ancestors = <CinematicLibraryFolder>[];
    var cursor = navigation.folderId == null
        ? null
        : foldersById[navigation.folderId];
    while (cursor != null) {
      ancestors.add(cursor);
      cursor = cursor.parentFolderId == null
          ? null
          : foldersById[cursor.parentFolderId];
    }
    for (final folder in ancestors.reversed) {
      breadcrumbs.add(
        _CinematicBreadcrumb(
          id: folder.id,
          name: folder.name,
          isCurrent: folder.id == navigation.folderId,
        ),
      );
    }
    return _CinematicLibrarySnapshot(
      familyAssetCount: assets
          .where(
            (asset) => _matchesVisibility(
              placements[asset.id]?.isArchived ?? asset.isArchived,
              navigation.visibility,
            ),
          )
          .length,
      breadcrumbs: breadcrumbs,
      items: [
        for (final folder in visibleFolders)
          _CinematicLibraryFolderItem(folder),
        for (final asset in visibleAssets) _CinematicLibraryAssetItem(asset),
      ],
    );
  }

  final int familyAssetCount;
  final List<_CinematicBreadcrumb> breadcrumbs;
  final List<_CinematicLibraryItem> items;
}

sealed class _CinematicLibraryItem {
  const _CinematicLibraryItem();
}

final class _CinematicLibraryFolderItem extends _CinematicLibraryItem {
  const _CinematicLibraryFolderItem(this.folder);
  final CinematicLibraryFolder folder;
}

final class _CinematicLibraryAssetItem extends _CinematicLibraryItem {
  const _CinematicLibraryAssetItem(this.asset);
  final _CinematicAssetSummary asset;
}

final class _CinematicAssetSummary {
  const _CinematicAssetSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.isArchived,
  });

  final String id;
  final String title;
  final String description;
  final bool isArchived;
}

final class _CinematicBreadcrumb {
  const _CinematicBreadcrumb({
    required this.id,
    required this.name,
    required this.isCurrent,
  });

  final String? id;
  final String name;
  final bool isCurrent;
}

void _sortFolders(
  List<CinematicLibraryFolder> folders,
  NarrativeLibrarySort sort,
) {
  switch (sort) {
    case NarrativeLibrarySort.nameAscending:
      folders.sort((left, right) => left.name.compareTo(right.name));
    case NarrativeLibrarySort.nameDescending:
      folders.sort((left, right) => right.name.compareTo(left.name));
    case NarrativeLibrarySort.manual || NarrativeLibrarySort.updatedDescending:
      folders.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
  }
}

void _sortAssets(
  List<_CinematicAssetSummary> assets,
  NarrativeLibrarySort sort,
  Map<String, CinematicLibraryEntry> placements,
) {
  switch (sort) {
    case NarrativeLibrarySort.nameAscending:
      assets.sort((left, right) => left.title.compareTo(right.title));
    case NarrativeLibrarySort.nameDescending:
      assets.sort((left, right) => right.title.compareTo(left.title));
    case NarrativeLibrarySort.manual || NarrativeLibrarySort.updatedDescending:
      assets.sort((left, right) {
        final leftOrder = placements[left.id]?.sortOrder ?? 1 << 30;
        final rightOrder = placements[right.id]?.sortOrder ?? 1 << 30;
        final order = leftOrder.compareTo(rightOrder);
        return order == 0 ? left.title.compareTo(right.title) : order;
      });
  }
}

String _formatDuration(int durationUs) {
  final totalSeconds = (durationUs / Duration.microsecondsPerSecond).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

bool _matchesVisibility(
  bool isArchived,
  NarrativeLibraryVisibility visibility,
) => switch (visibility) {
  NarrativeLibraryVisibility.active => !isArchived,
  NarrativeLibraryVisibility.archived => isArchived,
  NarrativeLibraryVisibility.all => true,
};

const Object _unset = Object();
