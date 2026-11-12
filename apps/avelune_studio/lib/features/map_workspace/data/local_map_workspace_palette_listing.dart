part of 'local_map_workspace_adapter.dart';

final class _PaletteListing {
  _PaletteListing(this.catalog, this.resourceKind);

  final PortableProjectCatalog catalog;
  final String resourceKind;
  final _units = <CatalogDefinitionKey, CatalogDefinitionUnit>{};

  Future<ProjectManifest> read(Iterable<CatalogDefinitionKey> roots) async {
    for (final root in roots) {
      final classification = await _lookup(
        CatalogDefinitionKey(
          CatalogDefinitionKind.resourceLibraryEntry,
          '$resourceKind:${root.id}',
        ),
      );
      final entry = classification == null
          ? null
          : catalog.definitionValue(classification) as ResourceLibraryEntry;
      if (entry?.role == ResourceLibraryRole.component) continue;
      final unit = await catalog.lookup(root);
      if (unit == null) {
        throw FormatException('catalog.selection: missing definition $root');
      }
      _units[root] = unit;
      if (classification != null) _units[classification.key] = classification;
      await _family(entry?.familyId);
      switch (catalog.definitionValue(unit)) {
        case final ProjectSmartTilePreset preset:
          await _terrain(preset);
        case final BorderBlueprintRecord record:
          await _relief(record);
      }
    }
    return catalog.projectWithDefinitions(_units.values);
  }

  Future<CatalogDefinitionUnit?> _lookup(CatalogDefinitionKey key) async =>
      _units[key] ?? await catalog.lookup(key);

  Future<CatalogDefinitionUnit?> _add(CatalogDefinitionKey key) async {
    final unit = await _lookup(key);
    if (unit != null) _units[key] = unit;
    return unit;
  }

  Future<void> _family(String? id) async {
    var familyId = id;
    while (familyId != null &&
        !ResourceLibraryCatalog.predefinedFamilies.any(
          (family) => family.id == familyId,
        )) {
      final key = CatalogDefinitionKey(
        CatalogDefinitionKind.resourceFamily,
        familyId,
      );
      if (_units.containsKey(key)) return;
      final unit = await _add(key);
      if (unit == null) return;
      familyId = (catalog.definitionValue(unit) as ResourceFamily).parentId;
    }
  }

  Future<void> _terrain(ProjectSmartTilePreset preset) async {
    if (preset.categoryId.isNotEmpty) {
      await _add(
        CatalogDefinitionKey(
          CatalogDefinitionKind.smartTileCategory,
          preset.categoryId,
        ),
      );
    }
    if (preset.usage == SmartTileUsage.path &&
        preset.defaultMaterialId.isNotEmpty) {
      await _add(
        CatalogDefinitionKey(
          CatalogDefinitionKind.smartTileMaterial,
          preset.defaultMaterialId,
        ),
      );
    }
    for (final rule in preset.rules) {
      for (final candidate in rule.candidates) {
        for (final part in candidate.parts) {
          if (await _preview(part.source)) return;
        }
      }
    }
  }

  Future<void> _relief(BorderBlueprintRecord record) async {
    final primitive = record.draft.definition.primitives.firstOrNull;
    if (primitive == null) return;
    if (primitive.sourceModelId case final modelId?) {
      await _add(CatalogDefinitionKey(CatalogDefinitionKind.model3d, modelId));
      return;
    }
    final elementId = primitive.sourceElementId;
    if (elementId == null) return;
    final element = await _add(
      CatalogDefinitionKey(CatalogDefinitionKind.element, elementId),
    );
    if (element == null) return;
    final value = catalog.definitionValue(element) as ProjectElementEntry;
    for (final tilesetId in {
      value.tilesetId,
      for (final frame in value.frames) frame.tilesetId,
    }) {
      if (tilesetId.isEmpty) continue;
      await _add(
        CatalogDefinitionKey(CatalogDefinitionKind.tileset, tilesetId),
      );
    }
  }

  Future<bool> _preview(SmartTileVisualSource source) async {
    switch (source) {
      case SmartTileModel3dSource(:final modelId):
        return await _add(
              CatalogDefinitionKey(CatalogDefinitionKind.model3d, modelId),
            ) !=
            null;
      case SmartTileFrameSource(:final frame):
        final atlas = await _add(
          CatalogDefinitionKey(
            CatalogDefinitionKind.smartTileAtlas,
            frame.atlasId,
          ),
        );
        if (atlas == null) return false;
        final tilesetId =
            (catalog.definitionValue(atlas) as ProjectSmartTileAtlas).tilesetId;
        final tileset = await _add(
          CatalogDefinitionKey(CatalogDefinitionKind.tileset, tilesetId),
        );
        return tileset != null &&
            (catalog.definitionValue(tileset) as ProjectTilesetEntry).source
                is ProjectRegularAtlasTilesetSource;
      case SmartTileAnimationSource():
        return false;
    }
  }
}
