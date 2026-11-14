import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:map_core/map_core.dart';

import '../application/spatial_terrain_draft_test.dart'
    show spatialPathDraft, spatialPathModel;
import '../terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

({
  ProjectManifest project,
  MapData map,
  ProjectSmartTilePreset preset,
  ProjectSmartTilePattern pattern,
})
patternFixture({bool spatial = true, bool followTerrain = true}) {
  final draft = spatialPathDraft();
  final imageDraft = terrainDraft();
  assignAll(imageDraft);
  final base = spatial ? draft.manifest : publishFixture(imageDraft);
  final preset = spatial
      ? draft.previewPreset
      : base.smartTileCatalog.presets.single;
  final pattern = ProjectSmartTilePattern(
    id: 'water',
    name: 'Eau animée',
    usage: preset.usage,
    width: 2,
    height: 1,
    cells: [
      for (var x = 0; x < 2; x++)
        SmartTilePatternCell(
          x: x,
          y: 0,
          parts: [
            SmartTileVisualPart(
              source: spatial
                  ? SmartTileVisualSource.model3d(
                      modelId: 'oak',
                      scale: 1 + x.toDouble(),
                      followTerrain: followTerrain,
                    )
                  : preset.rules.first.candidates.first.parts.first.source,
            ),
          ],
        ),
    ],
  );
  final project = base.copyWith(
    settings: spatial
        ? base.settings.copyWith(spatialCamera: SpatialCameraProfile())
        : base.settings,
    elements: spatial ? const [] : base.elements,
    tilesets: spatial ? const [] : base.tilesets,
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: base.smartTileCatalog.atlases,
      materials: spatial
          ? draft.draft.materials
          : base.smartTileCatalog.materials,
      presets: [preset],
      patterns: [pattern],
    ),
  );
  final map = MapData(
    id: 'a',
    name: 'Eau native',
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    size: const GridSize(width: 8, height: 8),
    spatialScene: spatial ? MapSpatialScene(width: 8, depth: 8) : null,
    layers: [
      MapLayer.smartTile(
        id: 'water-layer',
        name: 'Eau',
        presetId: preset.id,
        usage: preset.usage,
        materialPalette: ['', preset.defaultMaterialId],
        field: SmartTileField.cell(semanticCells: List.filled(64, 0)),
        patternStrokes: [
          SmartTilePatternStroke(
            id: 'source-water',
            patternId: pattern.id,
            phaseX: 1,
            cells: [for (var x = 2; x < 6; x++) GridPos(x: x, y: 2)],
          ),
        ],
      ),
    ],
  );
  return (project: project, map: map, preset: preset, pattern: pattern);
}

({
  ProjectManifest project,
  MapData map,
  ProjectSmartTilePreset preset,
  ProjectSmartTilePattern pattern,
})
adaptiveBridgeFixture() {
  final base = patternFixture(spatial: false);
  final preset = base.preset.copyWith(
    categoryId: 'bridge-style',
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    status: SmartTilePresetStatus.published,
    rules: [],
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.explicit,
    ),
  );
  final part = base.pattern.cells.first.parts.first;
  final pattern = ProjectSmartTilePattern(
    id: 'bridge',
    name: 'Pont natif',
    categoryId: preset.categoryId,
    usage: preset.usage,
    width: 5,
    height: 4,
    construction: SmartTilePatternConstruction(
      y: SmartTilePatternRepeatAxis(repeatStart: 1, repeatLength: 2),
    ),
    cells: [
      for (var y = 0; y < 4; y++)
        for (var x = 0; x < 5; x++)
          SmartTilePatternCell(x: x, y: y, parts: [part]),
    ],
  );
  final catalog = base.project.smartTileCatalog;
  final project = base.project.copyWith(
    smartTileCatalog: ProjectSmartTileCatalog(
      categories: [
        ...catalog.categories,
        const ProjectSmartTileCategory(id: 'bridge-style', name: 'Pont'),
      ],
      atlases: catalog.atlases,
      materials: catalog.materials,
      animations: catalog.animations,
      presets: [preset],
      patterns: [pattern],
    ),
  );
  final source = base.map.layers.whereType<SmartTileLayer>().single;
  final map = base.map.copyWith(layers: [source.copyWith(patternStrokes: [])]);
  return (project: project, map: map, preset: preset, pattern: pattern);
}

({
  ProjectManifest project,
  MapData map,
  ProjectSmartTilePreset preset,
  ProjectSmartTilePattern pattern,
})
atomicStampFixture({GridPos origin = const GridPos(x: 2, y: 2)}) {
  final fixture = patternFixture();
  final pattern = fixture.pattern.copyWith(
    id: 'ground-unit',
    width: 3,
    height: 3,
    repeatMode: SmartTilePatternRepeatMode.stamp,
    cells: [
      const SmartTilePatternCell(
        x: 0,
        y: 0,
        parts: [
          SmartTileVisualPart(
            source: SmartTileVisualSource.model3d(
              modelId: 'ground-detail',
              offsetX: 1,
              offsetY: .001,
              offsetZ: 1,
            ),
          ),
        ],
      ),
    ],
  );
  final project = withStampPatterns(
    fixture.project.copyWith(
      models3d: [
        ...fixture.project.models3d,
        spatialPathModel('ground-detail'),
      ],
    ),
    [pattern],
  );
  final layer = fixture.map.layers.whereType<SmartTileLayer>().single.copyWith(
    field: SmartTileField.cell(semanticCells: List.filled(64, 1)),
    patternStrokes: [],
  );
  final applied = applySmartTilePatternGesture(
    layer,
    pattern: pattern,
    mapSize: fixture.map.size,
    selection: SmartTilePatternSelection.stamp(anchor: origin),
    strokeId: 'unit',
  );
  final map = fixture.map.copyWith(
    layers: [applied.layer],
    spatialScene: MapSpatialScene(
      width: 8,
      depth: 8,
      heightLevels: List.generate(64, (index) => index == 27 ? 4 : 2),
    ),
  );
  return (project: project, map: map, preset: fixture.preset, pattern: pattern);
}

ProjectManifest withStampPatterns(
  ProjectManifest project,
  List<ProjectSmartTilePattern> patterns,
) => project.copyWith(
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: project.smartTileCatalog.atlases,
    materials: project.smartTileCatalog.materials,
    presets: project.smartTileCatalog.presets,
    animations: project.smartTileCatalog.animations,
    patterns: patterns,
  ),
);

MapEditingViewportSession selectedStampEraseView(
  ProjectSmartTilePreset preset,
  ProjectSmartTilePattern pattern,
) => MapEditingViewportSession()
  ..prepareTerrainPainting(preset)
  ..selectTerrainPattern(pattern)
  ..tool = StudioMapTool.erase;
