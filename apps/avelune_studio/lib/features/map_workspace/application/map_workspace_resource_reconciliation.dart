part of 'map_workspace_editing_state.dart';

extension MapWorkspaceResourceReconciliation on MapWorkspaceEditingState {
  void reconcileResources(
    ProjectManifest project, {
    String? mapId,
    MapData? map,
  }) {
    resourceFilters.usage = ResourceCatalogUsage.all;
    final activeMapId = mapId ?? _resourceMapId;
    final catalog = resourceCatalog(project);
    final available = filterResourceCatalog(
      project,
      catalog,
      ResourceCatalogFilterState(showComponents: true),
      activeMapId: activeMapId,
      forMapPicker: true,
    ).map((item) => item.identity).toSet();
    bool has(String kind, String id) => available.contains('$kind:$id');
    bool usableBorder(String id) =>
        has('borderBlueprint', id) &&
        catalog.any(
          (item) =>
              item.identity == 'borderBlueprint:$id' &&
              item.usableIn(project, activeMapId: activeMapId),
        );
    final mapIds = project.maps.map((entry) => entry.id).toSet();
    _retainedBorderDrafts.removeWhere(
      (id, draft) => !mapIds.contains(id) || !usableBorder(draft.blueprintId),
    );
    if (mapId != null && _resourceMapId != null && _resourceMapId != mapId) {
      environment = null;
      exteriorEnvironmentPresetId = null;
      focusBorderDraftOn(mapId);
      borderFeature = null;
      spatialSurfaceId = null;
      terrainSurfacePreview = null;
      spatialSurfaceSelect = false;
    }
    _resourceMapId = activeMapId;
    if (model3d != null) {
      model3d = project.models3d
          .where((item) => item.id == model3d!.id && has('model3d', item.id))
          .firstOrNull;
      if (model3d == null && tool == StudioMapTool.place) {
        tool = StudioMapTool.select;
      }
    }
    if (brush != null) {
      brush = project.elements
          .where((item) => item.id == brush!.id && has('element', item.id))
          .firstOrNull;
      if (brush == null &&
          (tool == StudioMapTool.place || tool == StudioMapTool.paint)) {
        tool = StudioMapTool.select;
      }
    }
    if (terrain != null) {
      terrain = project.smartTileCatalog.presets
          .where(
            (item) => item.id == terrain!.id && has('smartTilePreset', item.id),
          )
          .firstOrNull;
      if (terrain == null && tool == StudioMapTool.terrain) {
        tool = StudioMapTool.select;
      }
      if (terrain == null) {
        _selectInitialTerrainConstruction = false;
        terrainMaterialId = null;
        terrainPatternId = null;
      } else if (!terrain!.allowedMaterialIds.contains(terrainMaterialId)) {
        terrainMaterialId = terrain!.defaultMaterialId;
      }
      if (terrainPatternId != null) {
        final pattern = map == null
            ? project.smartTileCatalog.patterns
                  .where((pattern) => pattern.id == terrainPatternId)
                  .firstOrNull
            : terrainPatternFor(project, map);
        if (pattern == null) {
          terrainPatternId = null;
        } else if (pattern.repeatMode == SmartTilePatternRepeatMode.stamp) {
          terrainPatternMode = SmartTilePatternSelectionKind.stamp;
        } else if (pattern.construction?.x != null &&
            pattern.construction?.y != null &&
            terrainPatternMode == SmartTilePatternSelectionKind.line) {
          terrainPatternMode = SmartTilePatternSelectionKind.rectangle;
        }
      }
      if (_selectInitialTerrainConstruction && map != null && terrain != null) {
        _selectInitialTerrainConstruction = false;
        if (terrainPatternId == null &&
            terrain!.categoryId.isNotEmpty &&
            terrain!.status == SmartTilePresetStatus.published &&
            terrain!.coveragePolicy == SmartTileCoveragePolicy.sparse &&
            terrain!.rules.isEmpty &&
            terrain!.coverageProfile.mode == SmartTileCoverageMode.explicit &&
            terrain!.coverageProfile.requiredScenarios.isEmpty &&
            !terrain!.coverageProfile.allowFallback) {
          final constructions =
              availableTerrainPatterns(
                    project: project,
                    map: map,
                    preset: terrain!,
                  )
                  .where(
                    (pattern) =>
                        pattern.construction != null &&
                        pattern.categoryId == terrain!.categoryId,
                  )
                  .toList();
          if (constructions.length == 1) {
            selectTerrainPattern(constructions.single);
          }
        }
      }
    }
    if (character != null) {
      character = project.characters
          .where(
            (item) => item.id == character!.id && has('character', item.id),
          )
          .firstOrNull;
      if (character == null && tool == StudioMapTool.character) {
        tool = StudioMapTool.select;
      }
    }
    if (tile != null && !has('tileset', tile!.tilesetId)) {
      tile = null;
      if (tool == StudioMapTool.paint) tool = StudioMapTool.select;
    }
    if (paletteAtlasId != null && !has('tileset', paletteAtlasId!)) {
      paletteAtlasId = null;
    }
    if (borderBlueprintId != null && !usableBorder(borderBlueprintId!)) {
      borderBlueprintId = null;
      borderDraft = null;
      borderDraftFailure = null;
      if (tool == StudioMapTool.border) tool = StudioMapTool.select;
    }
    if (environment != null && map != null) {
      final session = environment!;
      final area = map.layers
          .whereType<EnvironmentLayer>()
          .where((layer) => layer.id == session.layerId)
          .expand((layer) => layer.content.areas)
          .where((area) => area.id == session.areaId)
          .firstOrNull;
      if (area == null || !has('environmentPreset', area.presetId)) {
        environment = null;
      }
    }
    if (exteriorEnvironmentPresetId != null &&
        !has('environmentPreset', exteriorEnvironmentPresetId!)) {
      exteriorEnvironmentPresetId = null;
    }
    if (environment == null &&
        exteriorEnvironmentPresetId == null &&
        tool == StudioMapTool.environment) {
      tool = StudioMapTool.select;
    }
  }

  List<ResourceItem> paletteResourcesFor(
    ProjectManifest project,
    String mapId,
    String paletteTab, {
    bool applyFilters = true,
  }) {
    final kinds = switch (paletteTab) {
      'Décors' => const {'element', 'model3d'},
      'Terrains' => const {'smartTilePreset'},
      'Tuiles' => const {'tileset'},
      'Personnages' => const {'character'},
      'Bordures' => const {'borderBlueprint'},
      'Environnements' => const {'environmentPreset'},
      _ => const <String>{},
    };
    final filters = applyFilters
        ? resourceFilters.copy()
        : ResourceCatalogFilterState(showComponents: true);
    filters.usage = ResourceCatalogUsage.all;
    final borderPieces = paletteTab == 'Décors'
        ? mapBorderPieceIdentities(project)
        : const <String>{};
    return filterResourceCatalog(
      project,
      resourceCatalog(project)
          .where(
            (item) =>
                kinds.contains(item.canonicalKind) &&
                !borderPieces.contains('${item.canonicalKind}:${item.id}'),
          )
          .toList(),
      filters,
      activeMapId: mapId,
      forMapPicker: true,
    );
  }
}
