part of 'map_exterior_decoration_authoring.dart';

extension _ExteriorDecorationReferenceAdmission
    on LocalMapExteriorDecorationAuthoring {
  Future<Future<void> Function()> _admitVisualReferences(
      _DecorationContext context,
      Map<String, Map<String, dynamic>?> images) async {
    final roots = <CatalogDefinitionKey>{};
    final sectors = <ExteriorDecorationSector>[];
    for (final entry in images.entries) {
      if (entry.key.startsWith('$exteriorReferenceNamespace/') || entry.key == context.storageKey || entry.value == null) continue;
      if (entry.key.startsWith('maps/${context.map.id}.decoration/borders/')) {
        final border = ExteriorDecorationBorder.fromJson(entry.value!);
        roots.add(CatalogDefinitionKey(
            CatalogDefinitionKind.borderRecord, border.feature.blueprintId));
        for (final model in border.instances) {
          roots.add(CatalogDefinitionKey(
              CatalogDefinitionKind.model3d, model.modelId));
        }
      } else {
        final sector = ExteriorDecorationSector.fromJson(entry.value!);
        sectors.add(sector);
        for (final model in sector.scene.instances) {
          roots.add(CatalogDefinitionKey(
              CatalogDefinitionKind.model3d, model.modelId));
        }
        if (sector.scene.cliffFrame case final frame?) {
          roots.add(CatalogDefinitionKey(
              CatalogDefinitionKind.smartTileAtlas, frame.atlasId));
        }
        for (final layer in sector.layers) {
          switch (layer) {
            case SmartTileLayer():
              roots.add(CatalogDefinitionKey(
                  CatalogDefinitionKind.smartTilePreset, layer.presetId));
              for (final id in layer.materialPalette.skip(1)) {
                roots.add(CatalogDefinitionKey(
                    CatalogDefinitionKind.smartTileMaterial, id));
              }
              for (final stroke in layer.patternStrokes) {
                roots.add(CatalogDefinitionKey(
                    CatalogDefinitionKind.smartTilePattern, stroke.patternId));
              }
            case EnvironmentLayer():
              for (final area in layer.content.areas) {
                roots.add(CatalogDefinitionKey(
                    CatalogDefinitionKind.environmentPreset, area.presetId));
              }
            case BorderLayer():
              for (final feature in layer.content.features) {
                roots.add(CatalogDefinitionKey(
                    CatalogDefinitionKind.borderRecord, feature.blueprintId));
              }
            default:
              break;
          }
        }
      }
    }
    if (roots.isEmpty) return () async {};
    final catalog = await _nativeCatalog(context);
    final selection = await catalog.reader.read((source) async {
      final owner = await CatalogMetadataDocuments.readDocuments(
          snapshot: source.snapshot,
          project: source.projectMetadata,
          ids: {
            'maps': {context.map.id}
          });
      final entry =
          owner.project.maps.where((v) => v.id == context.map.id).firstOrNull;
      if (entry == null || entry.relativePath != context.mapPath) {
        throw const FormatException(
            'Exterior visual references require their registered owner map.');
      }
      return (await ProjectCatalogSelection(source).resolve(roots))
          .copyWith(maps: [entry]);
    });
    final resources = <(String, String)>[
      for (final value in selection.models3d) ('model3d', value.id),
      for (final value in selection.tilesets) ('tileset', value.id),
      for (final value in selection.environmentPresets)
        ('environmentPreset', value.id),
      for (final value in selection.smartTileCatalog.presets)
        ('smartTilePreset', value.id),
      for (final value in selection.smartTileCatalog.materials)
        ('smartTileMaterial', value.id),
      for (final value in selection.smartTileCatalog.atlases)
        ('smartTileAtlas', value.id),
      for (final value in selection.smartTileCatalog.patterns)
        ('smartTilePattern', value.id),
      for (final value in selection.smartTileCatalog.animations)
        ('smartTileAnimation', value.id),
      for (final value in selection.borderCatalog.records)
        ('borderBlueprint', value.id),
    ];
    for (final resource in resources) {
      if (!selection.resourceLibraryCatalog
          .availableForMap(resource.$1, resource.$2, context.map.id)) {
        throw const FormatException(
            'An exterior visual resource is reserved for another map.');
      }
    }
    for (final sector in sectors) {
      MapValidator.validate(sector.asVisualMap().copyWith(id: context.map.id),
          projectDialogueContext: selection);
    }
    return () async {
      if ('sha256:${(await catalog.store.readHead())?.sha256}' !=
              catalog.revision ||
          await context.gateway.readResourceRevision('project.json') !=
              catalog.descriptorRevision) {
        throw const FormatException(
            'Exterior visual definitions changed before commit.');
      }
    };
  }
}
