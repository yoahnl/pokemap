import 'package:map_core/map_core_domain.dart';

ProjectManifest mergeResourceSelection(
  ProjectManifest current,
  ProjectManifest loaded, {
  required ResourceLibraryCatalog library,
}) => current.copyWith(
  tilesets: loaded.tilesets,
  elements: loaded.elements,
  models3d: loaded.models3d,
  characters: loaded.characters,
  environmentPresets: loaded.environmentPresets,
  smartTileCatalog: loaded.smartTileCatalog,
  borderCatalog: loaded.borderCatalog,
  elementCategories: loaded.elementCategories,
  tilesetFolders: loaded.tilesetFolders,
  characterStudioCatalog: loaded.characterStudioCatalog,
  resourceLibraryCatalog: mergeResourceLibraryCatalogs(
    current.resourceLibraryCatalog,
    library,
  ),
);

ProjectManifest mergeBorderSelection(
  ProjectManifest current,
  ProjectManifest loaded,
) => mergeResourceSelection(
  current,
  combineResourceVisuals(current, loaded),
  library: loaded.resourceLibraryCatalog,
);

ProjectManifest replaceLoadedBorderProjection(
  ProjectManifest current,
  BorderBlueprintRecord replacement, {
  Iterable<BorderVisualSnapshot> snapshots = const [],
}) {
  final catalog = current.borderCatalog;
  final existing = catalog.recordById(replacement.id);
  if (existing == null || existing == replacement) return current;
  return current.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: catalog.formatVersion,
      records: [
        for (final record in catalog.records)
          record.id == replacement.id ? replacement : record,
      ],
      visualSnapshots: {
        for (final snapshot in catalog.visualSnapshots) snapshot.id: snapshot,
        for (final snapshot in snapshots) snapshot.id: snapshot,
      }.values.toList(),
    ),
  );
}

List<BorderVisualSnapshot> publishedBorderSnapshots(
  BorderBlueprintRecord record,
  ProjectBorderCatalog catalog,
) {
  final definition = record.latestPublished?.definition;
  if (definition == null || definition.isSpatial) return const [];
  final ids = {
    for (final primitive in definition.primitives) primitive.visualSnapshotId,
    ...?definition.ground?.visualSnapshotIdsByRole.values,
  };
  return [
    for (final snapshot in catalog.visualSnapshots)
      if (ids.contains(snapshot.id)) snapshot,
  ];
}

ProjectManifest replaceLoadedTerrainProjection(
  ProjectManifest current,
  ProjectSmartTilePreset replacement,
) {
  final catalog = current.smartTileCatalog;
  final index = catalog.presets.indexWhere(
    (entry) => entry.id == replacement.id,
  );
  if (index == -1 || catalog.presets[index] == replacement) return current;
  final presets = catalog.presets.toList();
  presets[index] = replacement;
  return current.copyWith(
    smartTileCatalog: ProjectSmartTileCatalog(
      formatVersion: catalog.formatVersion,
      categories: catalog.categories,
      atlases: catalog.atlases,
      materials: catalog.materials,
      animations: catalog.animations,
      presets: presets,
      patterns: catalog.patterns,
      drafts: catalog.drafts,
    ),
  );
}

ProjectManifest replaceLoadedEnvironmentProjection(
  ProjectManifest current,
  EnvironmentPreset replacement,
) {
  final existing = findProjectEnvironmentPresetById(current, replacement.id);
  return existing == null || existing == replacement
      ? current
      : upsertProjectEnvironmentPreset(current, replacement);
}

ProjectManifest upsertDecorProjection(
  ProjectManifest current,
  ProjectElementEntry replacement, {
  bool loadedOnly = false,
}) {
  final index = current.elements.indexWhere(
    (element) => element.id == replacement.id,
  );
  if (index == -1) {
    return loadedOnly
        ? current
        : current.copyWith(elements: [...current.elements, replacement]);
  }
  if (current.elements[index] == replacement) return current;
  final elements = current.elements.toList();
  elements[index] = replacement;
  return current.copyWith(elements: elements);
}

ResourceLibraryCatalog mergeResourceLibraryCatalogs(
  ResourceLibraryCatalog current,
  ResourceLibraryCatalog loaded,
) => ResourceLibraryCatalog(
  families: {
    for (final family in current.families) family.id: family,
    for (final family in loaded.families) family.id: family,
  }.values,
  entries: {
    for (final entry in current.entries) entry.identity: entry,
    for (final entry in loaded.entries) entry.identity: entry,
  }.values,
);

ProjectManifest combineResourceVisuals(
  ProjectManifest map,
  ProjectManifest family,
) {
  List<T> union<T>(List<T> before, List<T> after, String Function(T) key) => {
    for (final value in before) key(value): value,
    for (final value in after) key(value): value,
  }.values.toList();
  return map.copyWith(
    resourceLibraryCatalog: mergeResourceLibraryCatalogs(
      map.resourceLibraryCatalog,
      family.resourceLibraryCatalog,
    ),
    tilesets: union(map.tilesets, family.tilesets, (value) => value.id),
    elements: union(map.elements, family.elements, (value) => value.id),
    models3d: union(map.models3d, family.models3d, (value) => value.id),
    characters: union(map.characters, family.characters, (value) => value.id),
    environmentPresets: union(
      map.environmentPresets,
      family.environmentPresets,
      (value) => value.id,
    ),
    smartTileCatalog: ProjectSmartTileCatalog(
      categories: union(
        map.smartTileCatalog.categories,
        family.smartTileCatalog.categories,
        (value) => value.id,
      ),
      atlases: union(
        map.smartTileCatalog.atlases,
        family.smartTileCatalog.atlases,
        (value) => value.id,
      ),
      materials: union(
        map.smartTileCatalog.materials,
        family.smartTileCatalog.materials,
        (value) => value.id,
      ),
      animations: union(
        map.smartTileCatalog.animations,
        family.smartTileCatalog.animations,
        (value) => value.id,
      ),
      presets: union(
        map.smartTileCatalog.presets,
        family.smartTileCatalog.presets,
        (value) => value.id,
      ),
      patterns: union(
        map.smartTileCatalog.patterns,
        family.smartTileCatalog.patterns,
        (value) => value.id,
      ),
      drafts: union(
        map.smartTileCatalog.drafts,
        family.smartTileCatalog.drafts,
        (value) => value.id,
      ),
    ),
    borderCatalog: ProjectBorderCatalog(
      formatVersion:
          map.borderCatalog.formatVersion > family.borderCatalog.formatVersion
          ? map.borderCatalog.formatVersion
          : family.borderCatalog.formatVersion,
      records: union(
        map.borderCatalog.records,
        family.borderCatalog.records,
        (value) => value.id,
      ),
      visualSnapshots: union(
        map.borderCatalog.visualSnapshots,
        family.borderCatalog.visualSnapshots,
        (value) => value.id,
      ),
    ),
  );
}
