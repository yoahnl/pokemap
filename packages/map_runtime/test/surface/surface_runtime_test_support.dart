import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

const int surfaceTestTileSize = 32;

RuntimeMapBundle surfaceTestBundle({
  required MapData map,
  ProjectSurfaceCatalog? surfaceCatalog,
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'surface-water',
      name: 'Surface Water',
      relativePath: 'tilesets/surface-water.png',
    ),
    ProjectTilesetEntry(
      id: 'base',
      name: 'Base',
      relativePath: 'tilesets/base.png',
    ),
    ProjectTilesetEntry(
      id: 'entity',
      name: 'Entity',
      relativePath: 'tilesets/entity.png',
    ),
  ],
  List<ProjectTerrainPreset> terrainPresets = const <ProjectTerrainPreset>[],
  List<ProjectPathPreset> pathPresets = const <ProjectPathPreset>[],
  List<ProjectElementEntry> elements = const <ProjectElementEntry>[],
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Surface Runtime Test',
      maps: const <ProjectMapEntry>[],
      tilesets: tilesets,
      settings: const ProjectSettings(
        tileWidth: surfaceTestTileSize,
        tileHeight: surfaceTestTileSize,
        displayScale: 1,
      ),
      terrainPresets: terrainPresets,
      pathPresets: pathPresets,
      elements: elements,
      surfaceCatalog: surfaceCatalog ?? surfaceTestCatalog(),
    ),
    map: map,
    projectRootDirectory: '/tmp/surface-runtime-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData surfaceTestMap({
  required List<MapLayer> layers,
  List<MapEntity> entities = const <MapEntity>[],
}) {
  return MapData(
    id: 'surface-test',
    name: 'Surface Test',
    size: const GridSize(width: 1, height: 1),
    layers: layers,
    entities: entities,
  );
}

SurfaceLayer surfaceTestLayer({
  bool isVisible = true,
  double opacity = 1,
  String surfacePresetId = 'water',
}) {
  return SurfaceLayer(
    id: 'surfaces',
    name: 'Surfaces',
    isVisible: isVisible,
    opacity: opacity,
    placements: [
      SurfaceCellPlacement(
        x: 0,
        y: 0,
        surfacePresetId: surfacePresetId,
      ),
    ],
  );
}

ProjectSurfaceCatalog surfaceTestCatalog({
  bool includeAtlas = true,
  bool includeAnimation = true,
  bool includePreset = true,
  int atlasColumns = 1,
  int sourceColumn = 0,
  String atlasTilesetId = 'surface-water',
  String animationId = 'water-loop',
}) {
  return ProjectSurfaceCatalog(
    atlases: [
      if (includeAtlas)
        ProjectSurfaceAtlas(
          id: 'water-atlas',
          name: 'Water Atlas',
          tilesetId: atlasTilesetId,
          geometry: SurfaceAtlasGeometry(
            tileSize: SurfaceAtlasTileSize(
              width: surfaceTestTileSize,
              height: surfaceTestTileSize,
            ),
            gridSize: SurfaceAtlasGridSize(columns: atlasColumns, rows: 1),
          ),
        ),
    ],
    animations: [
      if (includeAnimation)
        ProjectSurfaceAnimation(
          id: animationId,
          name: 'Water Loop',
          timeline: SurfaceAnimationTimeline(
            frames: [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: 'water-atlas',
                  column: sourceColumn,
                  row: 0,
                ),
                durationMs: 100,
              ),
            ],
          ),
        ),
    ],
    presets: [
      if (includePreset)
        ProjectSurfacePreset(
          id: 'water',
          name: 'Water',
          variantAnimations: SurfaceVariantAnimationRefSet(
            refs: [
              SurfaceVariantAnimationRef(
                role: SurfaceVariantRole.isolated,
                animationId: animationId,
              ),
            ],
          ),
        ),
    ],
  );
}

ProjectElementEntry surfaceTestElement({
  String id = 'entity-prop',
  String tilesetId = 'entity',
}) {
  return ProjectElementEntry(
    id: id,
    name: id,
    tilesetId: tilesetId,
    categoryId: '',
    frames: const [
      TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
    ],
  );
}

Future<RuntimeTilesetImage> runtimeTilesetImage(List<Color> colors) async {
  final image = await uiImageFromTileColors(colors);
  return RuntimeTilesetImage(
    images: [image],
    chunks: [
      RuntimeTilesetChunk(
        top: 0,
        height: surfaceTestTileSize,
        width: colors.length * surfaceTestTileSize,
      ),
    ],
    width: colors.length * surfaceTestTileSize,
    height: surfaceTestTileSize,
  );
}

Future<ui.Image> uiImageFromTileColors(List<Color> colors) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var i = 0; i < colors.length; i++) {
    canvas.drawRect(
      Rect.fromLTWH(
        (i * surfaceTestTileSize).toDouble(),
        0,
        surfaceTestTileSize.toDouble(),
        surfaceTestTileSize.toDouble(),
      ),
      Paint()..color = colors[i],
    );
  }
  return recorder.endRecording().toImage(
        colors.length * surfaceTestTileSize,
        surfaceTestTileSize,
      );
}

Future<ui.Image> renderSurfaceTestComponent(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(
        surfaceTestTileSize,
        surfaceTestTileSize,
      );
}

Future<List<int>> pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return [
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

List<int> rgba(int red, int green, int blue, int alpha) {
  return [red, green, blue, alpha];
}
