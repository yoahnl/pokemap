import 'package:map_core/map_core_domain.dart';

({MapData map, ProjectManifest project}) terrainSpatialPreviewMap({
  required ProjectManifest project,
  required ProjectSmartTilePreset preset,
  required int size,
  required Set<GridPos> cells,
  List<ProjectSmartTileMaterial>? materials,
}) {
  final catalog = ProjectSmartTileCatalog(
    categories: project.smartTileCatalog.categories,
    atlases: project.smartTileCatalog.atlases,
    animations: project.smartTileCatalog.animations,
    patterns: project.smartTileCatalog.patterns,
    drafts: project.smartTileCatalog.drafts,
    presets: [
      for (final existing in project.smartTileCatalog.presets)
        if (existing.id != preset.id) existing,
      preset,
    ],
    materials: materials == null
        ? project.smartTileCatalog.materials
        : [
            for (final existing in project.smartTileCatalog.materials)
              if (!materials.any((material) => material.id == existing.id))
                existing,
            ...materials,
          ],
  );
  final map = MapData(
    id:
        project.resourceLibraryCatalog
            .entryFor('smartTilePreset', preset.id)
            ?.mapId ??
        'terrain-preview',
    name: 'Terrain d’essai',
    version: ProjectVersion.v9,
    size: GridSize(width: size, height: size),
    spatialScene: MapSpatialScene(width: size, depth: size),
    layers: [
      MapLayer.smartTile(
        id: 'preview-path',
        name: preset.name,
        presetId: preset.id,
        usage: preset.usage,
        materialPalette: ['', preset.defaultMaterialId],
        field: SmartTileField.cell(
          semanticCells: [
            for (var index = 0; index < size * size; index++)
              cells.contains(GridPos(x: index % size, y: index ~/ size))
                  ? 1
                  : 0,
          ],
        ),
      ),
    ],
  );
  return (
    map: projectSpatialSmartTileModels(
      map: map,
      catalog: catalog,
      sourceCellWidth: project.settings.tileWidth,
      sourceCellHeight: project.settings.tileHeight,
    ),
    project: project.copyWith(smartTileCatalog: catalog),
  );
}
