import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../../../app/providers/use_case_providers.dart';
import '../../../../../application/models/map_palette_asset_browser.dart';
import '../../../../../application/services/map_palette_asset_browser_projector.dart';
import '../../../../../features/editor/state/editor_notifier.dart';
import '../../../../../features/editor/state/editor_selectors.dart';
import '../../../../../features/editor/state/editor_state.dart';
import '../../../../design_system/design_system.dart';
import '../../../../../theme/theme.dart';

abstract final class MapPaletteAssetBrowserKeys {
  static const openButton = ValueKey<String>('world-map-asset-browser-open');
  static const sheet = ValueKey<String>('world-map-asset-browser-sheet');
  static const search = ValueKey<String>('world-map-asset-browser-search');
  static const collectionAll =
      ValueKey<String>('world-map-asset-browser-collection-all');
  static const collectionRecent =
      ValueKey<String>('world-map-asset-browser-collection-recent');
  static const collectionFavorites =
      ValueKey<String>('world-map-asset-browser-collection-favorites');
  static const folderRail = ValueKey<String>('world-map-asset-browser-folders');
  static const folderPicker =
      ValueKey<String>('world-map-asset-browser-folder-picker');
  static const categoryFilter =
      ValueKey<String>('world-map-asset-browser-category-filter');
  static const showIncompatible =
      ValueKey<String>('world-map-asset-browser-show-incompatible');
  static const resultCount =
      ValueKey<String>('world-map-asset-browser-result-count');
  static const results = ValueKey<String>('world-map-asset-browser-results');
  static const empty = ValueKey<String>('world-map-asset-browser-empty');
  static const folderAll =
      ValueKey<String>('world-map-asset-browser-folder-all');
  static const folderUnclassified =
      ValueKey<String>('world-map-asset-browser-folder-unclassified');

  static ValueKey<String> folder(String id) =>
      ValueKey<String>('world-map-asset-browser-folder-$id');

  static ValueKey<String> tilesetRow(String id) =>
      ValueKey<String>('world-map-asset-browser-tileset-$id');

  static ValueKey<String> tilesetSemantics(String id) =>
      ValueKey<String>('world-map-asset-browser-tileset-semantics-$id');

  static ValueKey<String> favoriteButton(String id) =>
      ValueKey<String>('world-map-asset-browser-favorite-$id');

  static ValueKey<String> assignButton(String id) =>
      ValueKey<String>('world-map-asset-browser-assign-$id');
}

class MapPaletteAssetBrowserLauncher extends ConsumerStatefulWidget {
  const MapPaletteAssetBrowserLauncher({super.key});

  @override
  ConsumerState<MapPaletteAssetBrowserLauncher> createState() =>
      _MapPaletteAssetBrowserLauncherState();
}

class _MapPaletteAssetBrowserLauncherState
    extends ConsumerState<MapPaletteAssetBrowserLauncher> {
  final FocusNode _launcherFocusNode = FocusNode(
    debugLabel: 'world map asset browser launcher',
  );

  @override
  void dispose() {
    _launcherFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openBrowser() async {
    final searchFocusNode = FocusNode(
      debugLabel: 'world map asset browser search',
    );
    final container = ProviderScope.containerOf(context);
    try {
      await showPokeMapDesktopSideSheet<void>(
        context: context,
        title: 'Sources de tuiles & éléments',
        semanticLabel: 'Bibliothèque de sources pour le calque actif',
        width: 560,
        initialFocusNode: searchFocusNode,
        builder: (_) => UncontrolledProviderScope(
          container: container,
          child: _MapPaletteAssetBrowserSheet(
            searchFocusNode: searchFocusNode,
          ),
        ),
      );
    } finally {
      searchFocusNode.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(editorMapPaletteAssetBrowserSnapshotProvider);
    final selectedId = snapshot.context.selectedTilesetId;
    String? selectedName;
    var assignedSourceMissing = snapshot.assignedTilesetId != null;
    for (final tileset
        in snapshot.project?.tilesets ?? const <ProjectTilesetEntry>[]) {
      if (tileset.id == selectedId) {
        selectedName = tileset.name;
      }
      if (tileset.id == snapshot.assignedTilesetId) {
        assignedSourceMissing = false;
      }
    }
    return PokeMapButton(
      key: MapPaletteAssetBrowserKeys.openButton,
      focusNode: _launcherFocusNode,
      onPressed: snapshot.project == null ? null : _openBrowser,
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      leading: const Icon(Icons.grid_view_rounded),
      trailing: const Icon(Icons.chevron_right_rounded),
      child: Text(
        assignedSourceMissing
            ? 'Source introuvable : ${snapshot.assignedTilesetId}'
            : selectedName == null
                ? 'Choisir une source'
                : 'Source : $selectedName',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MapPaletteAssetBrowserSheet extends ConsumerStatefulWidget {
  const _MapPaletteAssetBrowserSheet({
    required this.searchFocusNode,
  });

  final FocusNode searchFocusNode;

  @override
  ConsumerState<_MapPaletteAssetBrowserSheet> createState() =>
      _MapPaletteAssetBrowserSheetState();
}

class _MapPaletteAssetBrowserSheetState
    extends ConsumerState<_MapPaletteAssetBrowserSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final query = ref
        .read(editorMapPaletteAssetBrowserSnapshotProvider)
        .context
        .browserQuery;
    _searchController = TextEditingController(text: query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final snapshot = ref.watch(editorMapPaletteAssetBrowserSnapshotProvider);
    final browserContext = snapshot.context;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final projector = MapPaletteAssetBrowserProjector(
      ref.watch(resolveAssignableTilesetsForMapUseCaseProvider),
      ref.watch(resolveVisibleProjectElementsUseCaseProvider),
    );
    final projection = projector.project(
      project: snapshot.project,
      map: snapshot.activeMap,
      activeLayerId: snapshot.activeLayerId,
      selectedTilesetId: browserContext.selectedTilesetId,
      query: browserContext.browserQuery,
      folderId: browserContext.browserFolderId,
      elementCategoryId: browserContext.projectElementCategoryId,
      collection: browserContext.browserCollection,
      showIncompatible: browserContext.showIncompatible,
      recentTilesetIds: snapshot.recentTilesetIds,
      favoriteTilesetIds: snapshot.favoriteTilesetIds,
    );
    final assignedName = _tilesetName(
      snapshot.project,
      projection.assignedTilesetId,
    );
    final assignedSourceMissing =
        projection.assignedTilesetId != null && assignedName == null;

    return KeyedSubtree(
      key: MapPaletteAssetBrowserKeys.sheet,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PokeMapBadge(
                  label: 'Calque : ${projection.activeLayerName ?? 'aucun'}',
                  variant: PokeMapBadgeVariant.mapAccent,
                ),
                PokeMapBadge(
                  label: assignedSourceMissing
                      ? 'Assignée introuvable : ${projection.assignedTilesetId}'
                      : assignedName == null
                          ? 'Aucune source assignée'
                          : 'Assigné : $assignedName',
                  variant: assignedName == null
                      ? PokeMapBadgeVariant.warning
                      : PokeMapBadgeVariant.success,
                ),
              ],
            ),
            if (projection.diagnostic case final diagnostic?) ...[
              const SizedBox(height: 10),
              PokeMapDiagnosticCallout(
                severity: switch (projection.status) {
                  MapPaletteAssetBrowserStatus.invalidMapScope =>
                    PokeMapDiagnosticSeverity.error,
                  MapPaletteAssetBrowserStatus.assignedSourceMissing =>
                    PokeMapDiagnosticSeverity.warning,
                  _ => PokeMapDiagnosticSeverity.info,
                },
                message: diagnostic,
              ),
            ],
            const SizedBox(height: 12),
            KeyedSubtree(
              key: MapPaletteAssetBrowserKeys.search,
              child: PokeMapSearchField(
                controller: _searchController,
                focusNode: widget.searchFocusNode,
                semanticLabel: 'Rechercher une source déclarée',
                hintText: 'Nom, dossier, élément ou catégorie…',
                onChanged: notifier.setPaletteBrowserQuery,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _collectionButton(
                  key: MapPaletteAssetBrowserKeys.collectionAll,
                  label: 'Toutes',
                  value: EditorPaletteAssetCollection.all,
                  selected: browserContext.browserCollection,
                  onSelected: notifier.setPaletteBrowserCollection,
                ),
                _collectionButton(
                  key: MapPaletteAssetBrowserKeys.collectionRecent,
                  label: 'Récentes · session',
                  value: EditorPaletteAssetCollection.recent,
                  selected: browserContext.browserCollection,
                  onSelected: notifier.setPaletteBrowserCollection,
                ),
                _collectionButton(
                  key: MapPaletteAssetBrowserKeys.collectionFavorites,
                  label: 'Favoris · session',
                  value: EditorPaletteAssetCollection.favorites,
                  selected: browserContext.browserCollection,
                  onSelected: notifier.setPaletteBrowserCollection,
                ),
              ],
            ),
            const SizedBox(height: 10),
            PokeMapDropdownField<String>(
              key: MapPaletteAssetBrowserKeys.categoryFilter,
              label: 'Contient des éléments de…',
              value: browserContext.projectElementCategoryId ?? '',
              compact: true,
              items: <PokeMapDropdownItem<String>>[
                const PokeMapDropdownItem<String>(
                  value: '',
                  label: 'Toutes les catégories déclarées',
                ),
                for (final category in projection.categories)
                  PokeMapDropdownItem<String>(
                    value: category.id,
                    label: category.path,
                  ),
              ],
              onChanged: (value) => notifier.setPaletteBrowserElementCategory(
                value.isEmpty ? null : value,
              ),
            ),
            const SizedBox(height: 10),
            KeyedSubtree(
              key: MapPaletteAssetBrowserKeys.showIncompatible,
              child: PokeMapToggleTile(
                label: 'Voir les sources non disponibles',
                description: projection.hiddenIncompatibleCount == 0
                    ? 'Aucune source masquée par le contexte actif.'
                    : '${projection.hiddenIncompatibleCount} source(s) '
                        'masquée(s) avec leur raison.',
                value: browserContext.showIncompatible,
                onChanged: notifier.setPaletteBrowserShowIncompatible,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              label: '${projection.items.length} source(s) affichée(s)',
              child: Text(
                '${projection.items.length} source(s)',
                key: MapPaletteAssetBrowserKeys.resultCount,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final results = _AssetBrowserResults(
                    projection: projection,
                    onSelect: notifier.selectTilesetEditorContext,
                    onToggleFavorite: notifier.togglePaletteTilesetFavorite,
                  );
                  if (constraints.maxWidth < 480) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _FolderPicker(
                          projection: projection,
                          selectedFolderId: browserContext.browserFolderId,
                          onSelected: notifier.setPaletteBrowserFolder,
                        ),
                        const SizedBox(height: 8),
                        Expanded(child: results),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 176,
                        child: _FolderRail(
                          projection: projection,
                          selectedFolderId: browserContext.browserFolderId,
                          onSelected: notifier.setPaletteBrowserFolder,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: results),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _AssignmentFooter(
              projection: projection,
              onAssign: (tilesetId) => unawaited(
                notifier.assignTilesetToActiveLayer(tilesetId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collectionButton({
    required Key key,
    required String label,
    required EditorPaletteAssetCollection value,
    required EditorPaletteAssetCollection selected,
    required ValueChanged<EditorPaletteAssetCollection> onSelected,
  }) {
    return PokeMapButton(
      key: key,
      onPressed: () => onSelected(value),
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      isSelected: value == selected,
      child: Text(label),
    );
  }
}

class _FolderRail extends StatelessWidget {
  const _FolderRail({
    required this.projection,
    required this.selectedFolderId,
    required this.onSelected,
  });

  final MapPaletteAssetBrowserProjection projection;
  final String? selectedFolderId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: MapPaletteAssetBrowserKeys.folderRail,
      children: [
        PokeMapSidebarItem(
          key: MapPaletteAssetBrowserKeys.folderAll,
          label: 'Tous les dossiers',
          compact: true,
          selected: selectedFolderId == null,
          onTap: () => onSelected(null),
        ),
        for (final folder in projection.folders)
          PokeMapSidebarItem(
            key: MapPaletteAssetBrowserKeys.folder(folder.id),
            label: folder.path,
            compact: true,
            selected: selectedFolderId == folder.id,
            onTap: () => onSelected(folder.id),
          ),
        if (projection.hasUnclassifiedSources)
          PokeMapSidebarItem(
            key: MapPaletteAssetBrowserKeys.folderUnclassified,
            label: 'Non classé',
            compact: true,
            selected: selectedFolderId == kEditorPaletteUnclassifiedFolderId,
            onTap: () => onSelected(kEditorPaletteUnclassifiedFolderId),
          ),
      ],
    );
  }
}

class _FolderPicker extends StatelessWidget {
  const _FolderPicker({
    required this.projection,
    required this.selectedFolderId,
    required this.onSelected,
  });

  final MapPaletteAssetBrowserProjection projection;
  final String? selectedFolderId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PokeMapDropdownField<String>(
      key: MapPaletteAssetBrowserKeys.folderPicker,
      label: 'Dossier',
      value: selectedFolderId ?? '',
      compact: true,
      items: <PokeMapDropdownItem<String>>[
        const PokeMapDropdownItem<String>(
          value: '',
          label: 'Tous les dossiers',
        ),
        for (final folder in projection.folders)
          PokeMapDropdownItem<String>(
            value: folder.id,
            label: folder.path,
          ),
        if (projection.hasUnclassifiedSources)
          const PokeMapDropdownItem<String>(
            value: kEditorPaletteUnclassifiedFolderId,
            label: 'Non classé',
          ),
      ],
      onChanged: (value) => onSelected(value.isEmpty ? null : value),
    );
  }
}

class _AssetBrowserResults extends StatelessWidget {
  const _AssetBrowserResults({
    required this.projection,
    required this.onSelect,
    required this.onToggleFavorite,
  });

  final MapPaletteAssetBrowserProjection projection;
  final ValueChanged<String?> onSelect;
  final ValueChanged<String> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    if (projection.items.isEmpty) {
      return const PokeMapEmptyState(
        key: MapPaletteAssetBrowserKeys.empty,
        icon: Icon(Icons.search_off_rounded),
        title: 'Aucune source trouvée',
        description:
            'Modifiez la recherche, le dossier ou la collection de session.',
      );
    }
    return ListView.separated(
      key: MapPaletteAssetBrowserKeys.results,
      itemCount: projection.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = projection.items[index];
        final stateLabel = item.isAssigned
            ? 'Assigné'
            : item.isCompatible
                ? 'Disponible'
                : 'Non disponible';
        final subtitle = <String>[
          if (item.disabledReason case final reason?) reason,
          item.folderPath,
          item.scopeLabel,
          stateLabel,
        ].join(' · ');
        final semanticLabel = <String>[
          item.tileset.name,
          if (item.isSelected) 'Sélectionnée dans le navigateur',
          if (item.isAssigned) 'Assignée au calque actif',
          if (item.isFavorite) 'Favori de cette session',
          if (!item.isCompatible) 'Désactivée',
          if (item.disabledReason case final reason?) reason,
          item.folderPath,
          item.scopeLabel,
        ].join('. ');
        return Semantics(
          key: MapPaletteAssetBrowserKeys.tilesetSemantics(item.tileset.id),
          container: true,
          label: semanticLabel,
          selected: item.isSelected,
          enabled: item.isCompatible,
          child: PokeMapSidebarItem(
            key: MapPaletteAssetBrowserKeys.tilesetRow(item.tileset.id),
            label: item.tileset.name,
            subtitle: subtitle,
            compact: true,
            growForTextScale: true,
            subtitleMaxLines: item.disabledReason == null ? 1 : 2,
            selected: item.isSelected,
            disabled: !item.isCompatible,
            icon: const Icon(Icons.grid_view_rounded),
            onTap: item.isCompatible ? () => onSelect(item.tileset.id) : null,
            trailing: PokeMapIconButton(
              key: MapPaletteAssetBrowserKeys.favoriteButton(item.tileset.id),
              onPressed: () => onToggleFavorite(item.tileset.id),
              icon: Icon(
                item.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
              ),
              tooltip: item.isFavorite
                  ? 'Retirer des favoris de cette session'
                  : 'Ajouter aux favoris de cette session',
              isSelected: item.isFavorite,
              size: 28,
            ),
          ),
        );
      },
    );
  }
}

class _AssignmentFooter extends StatelessWidget {
  const _AssignmentFooter({
    required this.projection,
    required this.onAssign,
  });

  final MapPaletteAssetBrowserProjection projection;
  final ValueChanged<String> onAssign;

  @override
  Widget build(BuildContext context) {
    MapPaletteAssetBrowserItem? selected;
    for (final item in projection.items) {
      if (item.isSelected) {
        selected = item;
        break;
      }
    }
    final selectedItem = selected;
    if (selectedItem == null) {
      return const PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Parcourir sans modifier',
        message: 'Sélectionnez une source disponible. La carte ne changera que '
            'lorsque vous utiliserez explicitement le bouton Assigner.',
      );
    }
    if (selectedItem.isAssigned) {
      return PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.info,
        title: 'Source assignée',
        message:
            '« ${selectedItem.tileset.name} » est déjà la source de ce calque.',
      );
    }
    if (!selectedItem.canAssign) {
      return PokeMapDiagnosticCallout(
        severity: PokeMapDiagnosticSeverity.warning,
        title: 'Assignation indisponible',
        message: selectedItem.disabledReason ??
            'Cette source ne peut pas être assignée au calque actif.',
      );
    }
    return PokeMapButton(
      key: MapPaletteAssetBrowserKeys.assignButton(selectedItem.tileset.id),
      onPressed: () => onAssign(selectedItem.tileset.id),
      variant: PokeMapButtonVariant.primary,
      leading: const Icon(Icons.link_rounded),
      child: Text(
        'Assigner à « ${projection.activeLayerName ?? 'ce calque'} »',
      ),
    );
  }
}

String? _tilesetName(ProjectManifest? project, String? tilesetId) {
  if (project == null || tilesetId == null) return null;
  for (final tileset in project.tilesets) {
    if (tileset.id == tilesetId) return tileset.name;
  }
  return null;
}
