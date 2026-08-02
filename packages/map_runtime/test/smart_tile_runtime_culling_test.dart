import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('renders an overhang whose owner is more than three cells offscreen',
      () async {
    final image = await runtimeTilesetImage(
      const <Color>[Color(0xFFFF0000)],
    );
    addTearDown(image.dispose);
    final component = MapLayersComponent(
      bundle: RuntimeMapBundle(
        manifest: _manifest,
        map: _map,
        projectRootDirectory: '/tmp/smart-runtime-culling-test',
        tilesetAbsolutePathsById: const <String, String>{},
      ),
      tileImagesByTilesetId: {'smart': image},
    )..setVisibleLocalRect(const Rect.fromLTWH(160, 0, 32, 32));

    final recorder = ui.PictureRecorder();
    component.render(Canvas(recorder));
    final rendered = await recorder.endRecording().toImage(256, 32);

    expect(await pixelAt(rendered, 176, 16), rgba(255, 0, 0, 255));
    rendered.dispose();
  });
}

const _map = MapData(
  id: 'overhang-map',
  name: 'Overhang map',
  version: ProjectVersion.v5,
  size: GridSize(width: 8, height: 1),
  layers: <MapLayer>[
    SmartTileLayer(
      id: 'overhang',
      name: 'Overhang',
      presetId: 'overhang',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(
        semanticCells: <int>[1, 0, 0, 0, 0, 0, 0, 0],
      ),
    ),
  ],
);

final _manifest = ProjectManifest(
  name: 'Smart runtime culling',
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
        columns: 1,
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
        id: 'overhang',
        name: 'Overhang',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'ground',
            centerMatch: SmartTileSlotMatch.material('grass'),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'wide',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.frame(
                      frame: SmartTileFrameRef(
                        atlasId: 'atlas',
                        column: 0,
                        row: 0,
                      ),
                    ),
                    footprintWidth: 6,
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
