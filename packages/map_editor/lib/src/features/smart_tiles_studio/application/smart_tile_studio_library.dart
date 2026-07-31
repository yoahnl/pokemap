import 'package:map_core/map_core.dart';

enum SmartTileLibraryOrigin {
  native,
  legacyTerrain,
  legacyPath,
  legacySurface,
}

final class SmartTileLibraryItem {
  const SmartTileLibraryItem({
    required this.key,
    required this.id,
    required this.name,
    required this.origin,
    required this.statusLabel,
    required this.sortOrder,
    this.usage,
    this.categoryId,
    this.nativePreset,
  });

  final String key;
  final String id;
  final String name;
  final SmartTileLibraryOrigin origin;
  final SmartTileUsage? usage;
  final String? categoryId;
  final String statusLabel;
  final int sortOrder;
  final ProjectSmartTilePreset? nativePreset;

  bool get isLegacy => origin != SmartTileLibraryOrigin.native;

  String get usageLabel => switch (usage) {
        SmartTileUsage.terrain => 'Terrain',
        SmartTileUsage.path => 'Chemin',
        SmartTileUsage.forestSurface => 'Forêt',
        null => 'Usage non classé',
      };
}

List<SmartTileLibraryItem> buildSmartTileStudioLibrary(
  ProjectManifest manifest,
) {
  final items = <SmartTileLibraryItem>[
    for (final preset in manifest.smartTileCatalog.presets)
      SmartTileLibraryItem(
        key: 'native:${preset.id}',
        id: preset.id,
        name: preset.name,
        origin: SmartTileLibraryOrigin.native,
        usage: preset.usage,
        categoryId: preset.categoryId.isEmpty ? null : preset.categoryId,
        statusLabel: switch (preset.status) {
          SmartTilePresetStatus.draft => 'Brouillon',
          SmartTilePresetStatus.published => 'Publié',
        },
        sortOrder: preset.sortOrder,
        nativePreset: preset,
      ),
    for (final preset in manifest.terrainPresets)
      SmartTileLibraryItem(
        key: 'legacy-terrain:${preset.id}',
        id: preset.id,
        name: preset.name,
        origin: SmartTileLibraryOrigin.legacyTerrain,
        usage: SmartTileUsage.terrain,
        categoryId: preset.categoryId,
        statusLabel: 'Historique',
        sortOrder: preset.sortOrder,
      ),
    for (final preset in manifest.pathPresets)
      SmartTileLibraryItem(
        key: 'legacy-path:${preset.id}',
        id: preset.id,
        name: preset.name,
        origin: SmartTileLibraryOrigin.legacyPath,
        usage: SmartTileUsage.path,
        categoryId: preset.categoryId,
        statusLabel: 'Historique',
        sortOrder: preset.sortOrder,
      ),
    for (final preset in manifest.pathPatternPresets)
      SmartTileLibraryItem(
        key: 'legacy-path-pattern:${preset.id}',
        id: preset.id,
        name: preset.name,
        origin: SmartTileLibraryOrigin.legacyPath,
        usage: SmartTileUsage.path,
        categoryId: preset.categoryId,
        statusLabel: 'Historique — PathPattern',
        sortOrder: preset.sortOrder,
      ),
    for (final preset in manifest.surfaceCatalog.presets)
      SmartTileLibraryItem(
        key: 'legacy-surface:${preset.id}',
        id: preset.id,
        name: preset.name,
        origin: SmartTileLibraryOrigin.legacySurface,
        categoryId: preset.categoryId,
        statusLabel: 'Historique — usage non classé',
        sortOrder: preset.sortOrder,
      ),
  ];
  items.sort((left, right) {
    final order = left.sortOrder.compareTo(right.sortOrder);
    if (order != 0) {
      return order;
    }
    final name = left.name.toLowerCase().compareTo(right.name.toLowerCase());
    if (name != 0) {
      return name;
    }
    return left.key.compareTo(right.key);
  });
  return List<SmartTileLibraryItem>.unmodifiable(items);
}
