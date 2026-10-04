part of 'resource_information_actions.dart';

ProjectManifest upsertSmartCategory(
    ProjectManifest manifest, ProjectSmartTileCategory category) {
  final normalized =
      category.copyWith(name: resourceInformationName(category.name));
  final categories = [
    for (final existing in manifest.smartTileCatalog.categories)
      if (existing.id == category.id) normalized else existing,
    if (!manifest.smartTileCatalog.categories
        .any((entry) => entry.id == category.id))
      normalized,
  ];
  return manifest.copyWith(
      smartTileCatalog: _organizedSmartCatalog(manifest.smartTileCatalog,
          categories: categories));
}

ProjectManifest deleteSmartCategory(
    ProjectManifest manifest, String categoryId) {
  final catalog = manifest.smartTileCatalog;
  if (!catalog.categories.any((entry) => entry.id == categoryId)) {
    throw VisualLibraryException('smart_tile.category.unknown',
        'The terrain category identity is unknown.');
  }
  final references = <String>[
    for (final preset in catalog.presets)
      if (preset.categoryId == categoryId) 'smartTilePreset:${preset.id}',
    for (final draft in catalog.drafts)
      if (draft.categoryId == categoryId) 'smartTileDraft:${draft.id}',
    for (final draft in catalog.drafts)
      for (final material in draft.materials)
        if (material.categoryId == categoryId)
          'smartTileDraft:${draft.id}:material:${material.id}',
    for (final pattern in catalog.patterns)
      if (pattern.categoryId == categoryId) 'smartTilePattern:${pattern.id}',
    for (final material in catalog.materials)
      if (material.categoryId == categoryId) 'smartTileMaterial:${material.id}',
  ];
  if (references.isNotEmpty) {
    throw VisualLibraryException('smart_tile.category.references_blocking',
        'The terrain category still contains resources or authoring drafts.',
        details: {
          'categoryId': categoryId,
          'references': references,
          'resourceCount': references.length
        });
  }
  return manifest.copyWith(
      smartTileCatalog: _organizedSmartCatalog(catalog,
          categories: catalog.categories
              .where((entry) => entry.id != categoryId)
              .toList()));
}

ProjectManifest assignSmartCategory(
    ProjectManifest manifest, String presetId, String categoryId) {
  final catalog = manifest.smartTileCatalog;
  if (!catalog.presets.any((entry) => entry.id == presetId)) {
    throw VisualLibraryException(
        'smart_tile.preset.unknown', 'The terrain preset identity is unknown.');
  }
  if (categoryId.isNotEmpty &&
      !catalog.categories.any((entry) => entry.id == categoryId)) {
    throw VisualLibraryException('smart_tile.category.unknown',
        'The terrain destination category no longer exists.');
  }
  return manifest.copyWith(
      smartTileCatalog: _organizedSmartCatalog(catalog, presets: [
    for (final preset in catalog.presets)
      if (preset.id == presetId)
        preset.copyWith(categoryId: categoryId)
      else
        preset,
  ]));
}

ProjectSmartTileCatalog _organizedSmartCatalog(
  ProjectSmartTileCatalog before, {
  List<ProjectSmartTileCategory>? categories,
  List<ProjectSmartTilePreset>? presets,
}) =>
    ProjectSmartTileCatalog(
      categories: categories ?? before.categories,
      atlases: before.atlases,
      materials: before.materials,
      animations: before.animations,
      presets: presets ?? before.presets,
      patterns: before.patterns,
      drafts: before.drafts,
    );
