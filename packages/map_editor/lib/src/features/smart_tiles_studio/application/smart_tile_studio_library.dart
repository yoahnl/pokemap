import 'package:map_core/map_core.dart';

final class SmartTileLibraryItem {
  const SmartTileLibraryItem({
    required this.key,
    required this.id,
    required this.name,
    required this.statusLabel,
    required this.sortOrder,
    this.usage,
    this.categoryId,
    this.nativePreset,
  });

  final String key;
  final String id;
  final String name;
  final SmartTileUsage? usage;
  final String? categoryId;
  final String statusLabel;
  final int sortOrder;
  final ProjectSmartTilePreset? nativePreset;

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
        usage: preset.usage,
        categoryId: preset.categoryId.isEmpty ? null : preset.categoryId,
        statusLabel: switch (preset.status) {
          SmartTilePresetStatus.draft => 'Brouillon',
          SmartTilePresetStatus.published => 'Publié',
        },
        sortOrder: preset.sortOrder,
        nativePreset: preset,
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
