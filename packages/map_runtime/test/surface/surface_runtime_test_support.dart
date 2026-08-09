import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

const int surfaceTestTileSize = 32;

RuntimeMapBundle surfaceTestBundle({
  required MapData map,
  List<ProjectTilesetEntry> tilesets = const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'surface-water',
      name: 'Surface Water',
      relativePath: 'tilesets/surface-water.png',
      source: ProjectRegularAtlasTilesetSource(
        assetId: 'surface-water',
        pixelWidth: surfaceTestTileSize,
        pixelHeight: surfaceTestTileSize,
        tileWidth: surfaceTestTileSize,
        tileHeight: surfaceTestTileSize,
      ),
    ),
    ProjectTilesetEntry(
      id: 'surface-path',
      name: 'Surface Path',
      relativePath: 'tilesets/surface-path.png',
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
      smartTileCatalog: runtimeTestSmartTileCatalog,
      elements: elements,
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
    version: ProjectVersion.v6,
    size: const GridSize(width: 1, height: 1),
    layers: layers,
    entities: entities,
  );
}

SmartTileLayer runtimeTestBaseLayer({
  bool isVisible = true,
  double opacity = 1,
}) {
  return SmartTileLayer(
    id: 'base-layer',
    name: 'Base',
    isVisible: isVisible,
    opacity: opacity,
    presetId: 'runtime-base',
    usage: SmartTileUsage.terrain,
    materialPalette: const <String>['', 'runtime-base-material'],
    field: const SmartTileField.cell(semanticCells: <int>[1]),
  );
}

SmartTileLayer runtimeTestPathLayer({
  bool isVisible = true,
  double opacity = 1,
}) {
  return SmartTileLayer(
    id: 'path-layer',
    name: 'Path',
    isVisible: isVisible,
    opacity: opacity,
    presetId: 'runtime-path',
    usage: SmartTileUsage.path,
    materialPalette: const <String>['', 'runtime-path-material'],
    field: const SmartTileField.cell(semanticCells: <int>[1]),
  );
}

final ProjectSmartTileCatalog runtimeTestSmartTileCatalog =
    ProjectSmartTileCatalog(
  atlases: const <ProjectSmartTileAtlas>[
    ProjectSmartTileAtlas(
      id: 'runtime-base-atlas',
      name: 'Base atlas',
      tilesetId: 'surface-water',
      columns: 1,
      rows: 1,
    ),
    ProjectSmartTileAtlas(
      id: 'runtime-path-atlas',
      name: 'Path atlas',
      tilesetId: 'surface-path',
      columns: 1,
      rows: 1,
    ),
  ],
  materials: const <ProjectSmartTileMaterial>[
    ProjectSmartTileMaterial(
      id: 'runtime-base-material',
      name: 'Base material',
      connectionGroupId: 'runtime-base-material',
    ),
    ProjectSmartTileMaterial(
      id: 'runtime-path-material',
      name: 'Path material',
      connectionGroupId: 'runtime-path-material',
    ),
  ],
  presets: const <ProjectSmartTilePreset>[
    ProjectSmartTilePreset(
      id: 'runtime-base',
      name: 'Base',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.cardinal4,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'runtime-base-material',
      allowedMaterialIds: <String>['runtime-base-material'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'any',
          centerMatch: SmartTileSlotMatch.any(),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'base',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'runtime-base-atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.ground,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    ProjectSmartTilePreset(
      id: 'runtime-path',
      name: 'Path',
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.cardinal4,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'runtime-path-material',
      allowedMaterialIds: <String>['runtime-path-material'],
      rules: <SmartTileRule>[
        SmartTileRule(
          id: 'any',
          centerMatch: SmartTileSlotMatch.any(),
          candidates: <SmartTileCandidate>[
            SmartTileCandidate(
              id: 'path',
              parts: <SmartTileVisualPart>[
                SmartTileVisualPart(
                  source: SmartTileVisualSource.frame(
                    frame: SmartTileFrameRef(
                      atlasId: 'runtime-path-atlas',
                      column: 0,
                      row: 0,
                    ),
                  ),
                  channel: SmartTileRenderChannel.ground,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

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
