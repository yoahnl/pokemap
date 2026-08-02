import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runtime collects native Smart Tile atlas tilesets', () {
    expect(collectAllRuntimeTilesetIds(_map, _manifest), <String>{'smart'});
  });

  test(
      'runtime renders shared Core visuals in background and foreground passes',
      () async {
    final image = await runtimeTilesetImage(
      const <Color>[Color(0xFFFF0000), Color(0xFF0000FF)],
    );
    final bundle = RuntimeMapBundle(
      manifest: _manifest,
      map: _map,
      projectRootDirectory: '/tmp/smart-runtime-test',
      tilesetAbsolutePathsById: const <String, String>{},
    );
    final background = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: {'smart': image},
    );
    final foreground = MapLayersComponent(
      bundle: bundle,
      tileImagesByTilesetId: {'smart': image},
      renderPass: MapLayerRenderPass.foreground,
    );

    final backgroundImage = await _render(background);
    final foregroundImage = await _render(foreground);

    expect(await pixelAt(backgroundImage, 16, 16), rgba(255, 0, 0, 255));
    expect(await pixelAt(foregroundImage, 16, 16), rgba(0, 0, 255, 255));

    backgroundImage.dispose();
    foregroundImage.dispose();
  });
}

Future<ui.Image> _render(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  component.render(Canvas(recorder));
  return recorder.endRecording().toImage(32, 32);
}

const _map = MapData(
  id: 'smart-map',
  name: 'Smart Map',
  version: ProjectVersion.v5,
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    SmartTileLayer(
      id: 'forest',
      name: 'Forest',
      presetId: 'forest',
      usage: SmartTileUsage.forestSurface,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(semanticCells: <int>[1]),
    ),
  ],
);

final _manifest = ProjectManifest(
  name: 'Smart Runtime',
  version: ProjectVersion.v5,
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'smart',
      name: 'Smart',
      relativePath: 'tilesets/smart.png',
    ),
  ],
  settings: const ProjectSettings(
    tileWidth: 32,
    tileHeight: 32,
    displayScale: 1,
  ),
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'atlas',
        name: 'Atlas',
        tilesetId: 'smart',
        columns: 2,
        rows: 1,
      ),
    ],
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'forest',
        name: 'Forest',
        usage: SmartTileUsage.forestSurface,
        topology: SmartTileTopology.cardinal4,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'any',
            centerMatch: SmartTileSlotMatch.any(),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'forest',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                    channel: SmartTileRenderChannel.ground,
                  ),
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'atlas',
                        column: 1,
                        row: 0,
                      ),
                    ),
                    channel: SmartTileRenderChannel.canopy,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
