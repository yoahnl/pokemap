import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_studio_library.dart';

enum SmartTileLibraryUsageFilter { all, terrain, path, forestSurface }

List<SmartTileLibraryItem> filterSmartTileLibraryItems({
  required List<SmartTileLibraryItem> items,
  required SmartTileLibraryUsageFilter usageFilter,
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return items.where((item) {
    final usageMatches = switch (usageFilter) {
      SmartTileLibraryUsageFilter.all => true,
      SmartTileLibraryUsageFilter.terrain =>
        item.usage == SmartTileUsage.terrain,
      SmartTileLibraryUsageFilter.path => item.usage == SmartTileUsage.path,
      SmartTileLibraryUsageFilter.forestSurface =>
        item.usage == SmartTileUsage.forestSurface,
    };
    return usageMatches &&
        (normalizedQuery.isEmpty ||
            item.name.toLowerCase().contains(normalizedQuery) ||
            item.id.toLowerCase().contains(normalizedQuery));
  }).toList(growable: false);
}

class SmartTilesStudioLibraryPane extends StatelessWidget {
  const SmartTilesStudioLibraryPane({
    super.key,
    required this.items,
    required this.searchController,
    required this.usageFilter,
    required this.isCreating,
    required this.selectedItemKey,
    required this.onQueryChanged,
    required this.onUsageFilterChanged,
    required this.onCreatePreset,
    required this.onResumeDraft,
    required this.onSelectItem,
    required this.thumbnailBuilder,
    this.onImportTiledWang,
    this.onReconstructLiteralLayer,
    this.onCreatePattern,
    this.tiledWangPickerError,
  });

  final List<SmartTileLibraryItem> items;
  final TextEditingController searchController;
  final SmartTileLibraryUsageFilter usageFilter;
  final bool isCreating;
  final String? selectedItemKey;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<SmartTileLibraryUsageFilter> onUsageFilterChanged;
  final VoidCallback onCreatePreset;
  final ValueChanged<ProjectSmartTileAuthoringDraft> onResumeDraft;
  final ValueChanged<SmartTileLibraryItem> onSelectItem;
  final Widget Function(SmartTileLibraryItem item) thumbnailBuilder;
  final VoidCallback? onImportTiledWang;
  final VoidCallback? onReconstructLiteralLayer;
  final VoidCallback? onCreatePattern;
  final String? tiledWangPickerError;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: PokeMapSectionHeader(
          title: 'Bibliothèque',
          description: 'Terrain, chemins et surfaces forestières',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: <Widget>[
              PokeMapIconButton(
                key: const Key('smart-tiles-import-tiled-wang'),
                onPressed: onImportTiledWang,
                tooltip: 'Importer un TSX / Wang Set',
                semanticLabel: 'Importer un TSX / Wang Set',
                variant: PokeMapIconButtonVariant.soft,
                icon: const Icon(CupertinoIcons.arrow_down_doc, size: 15),
              ),
              PokeMapIconButton(
                key: const Key('smart-tiles-reconstruct-literal-layer'),
                onPressed: onReconstructLiteralLayer,
                tooltip: 'Reconstruire une couche importée',
                semanticLabel: 'Reconstruire une couche importée',
                variant: PokeMapIconButtonVariant.soft,
                icon: const Icon(CupertinoIcons.wand_stars, size: 15),
              ),
              PokeMapIconButton(
                key: const Key('smart-tiles-new-pattern'),
                onPressed: onCreatePattern,
                tooltip: 'Nouveau motif réutilisable',
                semanticLabel: 'Nouveau motif réutilisable',
                variant: PokeMapIconButtonVariant.soft,
                icon: const Icon(CupertinoIcons.square_grid_2x2, size: 15),
              ),
              PokeMapIconButton(
                key: const Key('smart-tiles-new-preset'),
                onPressed: onCreatePreset,
                tooltip: 'Nouveau Smart Tile',
                semanticLabel: 'Nouveau Smart Tile',
                variant: PokeMapIconButtonVariant.soft,
                icon: const Icon(CupertinoIcons.add, size: 15),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSearchField(
            controller: searchController,
            hintText: 'Rechercher un preset…',
            onChanged: onQueryChanged,
          ),
          if (tiledWangPickerError case final error?) ...[
            const SizedBox(height: 10),
            PokeMapDiagnosticCallout(
              key: const Key('smart-tiles-tiled-wang-picker-error'),
              severity: PokeMapDiagnosticSeverity.error,
              message: error,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: SmartTileLibraryUsageFilter.values.map((filter) {
              return PokeMapButton(
                key: Key('smart-tiles-filter-${filter.name}'),
                onPressed: () => onUsageFilterChanged(filter),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: usageFilter == filter,
                child: Text(_usageFilterLabel(filter)),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: items.isEmpty
                ? const PokeMapEmptyState(
                    title: 'Aucun Smart Tile',
                    description:
                        'Créez un preset natif ou recherchez un preset historique.',
                    icon: Icon(CupertinoIcons.square_grid_3x2),
                    compact: true,
                  )
                : ListView.separated(
                    key: const Key('smart-tiles-library-list'),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return PokeMapAssetCard(
                        key: Key('smart-tiles-library-item-${item.key}'),
                        thumbnail: thumbnailBuilder(item),
                        label: item.name,
                        description: '${item.usageLabel} • ${item.statusLabel}',
                        onPressed: item.isResumableDraft
                            ? () => onResumeDraft(item.canonicalDraft!)
                            : () => onSelectItem(item),
                        selected: !isCreating && selectedItemKey == item.key,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _usageFilterLabel(SmartTileLibraryUsageFilter filter) =>
    switch (filter) {
      SmartTileLibraryUsageFilter.all => 'Tous',
      SmartTileLibraryUsageFilter.terrain => 'Terrain',
      SmartTileLibraryUsageFilter.path => 'Chemin',
      SmartTileLibraryUsageFilter.forestSurface => 'Forêt',
    };
