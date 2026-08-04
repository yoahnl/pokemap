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
    this.canonicalDraft,
    this.pattern,
  });

  final String key;
  final String id;
  final String name;
  final SmartTileUsage? usage;
  final String? categoryId;
  final String statusLabel;
  final int sortOrder;
  final ProjectSmartTilePreset? nativePreset;
  final ProjectSmartTileAuthoringDraft? canonicalDraft;
  final ProjectSmartTilePattern? pattern;

  bool get isResumableDraft => canonicalDraft != null;
  bool get isPattern => pattern != null;

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
    for (final draft in manifest.smartTileCatalog.drafts)
      SmartTileLibraryItem(
        key: 'draft:${draft.id}',
        id: draft.targetPresetId,
        name: draft.name,
        usage: draft.usage,
        categoryId: draft.categoryId.isEmpty ? null : draft.categoryId,
        statusLabel: 'Brouillon à reprendre',
        sortOrder: draft.sortOrder,
        canonicalDraft: draft,
      ),
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
    for (final pattern in manifest.smartTileCatalog.patterns)
      SmartTileLibraryItem(
        key: 'pattern:${pattern.id}',
        id: pattern.id,
        name: pattern.name,
        usage: pattern.usage,
        categoryId: pattern.categoryId.isEmpty ? null : pattern.categoryId,
        statusLabel: 'Motif réutilisable',
        sortOrder: pattern.sortOrder,
        pattern: pattern,
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
