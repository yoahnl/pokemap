import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/smart_tile_animation_activation_controller.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('triggered Smart Tile layers stay idle then animate the entered cell',
      () async {
    final image = await runtimeTilesetImage(
      const <Color>[Color(0xFFFF0000), Color(0xFF0000FF)],
    );
    addTearDown(image.dispose);
    final controller = SmartTileAnimationActivationController(
      map: _map,
      catalog: _manifest.smartTileCatalog,
    );
    final component = MapLayersComponent(
      bundle: RuntimeMapBundle(
        manifest: _manifest,
        map: _map,
        projectRootDirectory: '/tmp/triggered-smart-tile-runtime',
        tilesetAbsolutePathsById: const <String, String>{},
      ),
      tileImagesByTilesetId: {'smart': image},
      smartTileAnimationController: controller,
    );

    final idle = await _render(component);
    expect(await pixelAt(idle, 16, 16), rgba(255, 0, 0, 255));
    idle.dispose();

    controller.onPlayerEnteredCell(const GridPos(x: 0, y: 0));
    controller.update(0.1);
    component.update(0.1);

    final active = await _render(component);
    expect(await pixelAt(active, 16, 16), rgba(0, 0, 255, 255));
    active.dispose();
  });
}

Future<ui.Image> _render(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  component.render(Canvas(recorder));
  return recorder.endRecording().toImage(32, 32);
}

const _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    SmartTileLayer(
      id: 'grass',
      name: 'Tall grass',
      presetId: 'grass-preset',
      usage: SmartTileUsage.path,
      materialPalette: <String>['', 'grass-material'],
      field: SmartTileField.cell(semanticCells: <int>[1]),
      animationActivation: SmartTileAnimationActivation.onEnter,
    ),
  ],
);

final _manifest = ProjectManifest(
  name: 'Triggered Smart Tile Runtime',
  version: ProjectVersion.v6,
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
        id: 'grass-material',
        name: 'Grass',
        connectionGroupId: 'grass',
      ),
    ],
    animations: const <ProjectSmartTileAnimation>[
      ProjectSmartTileAnimation(
        id: 'rustle',
        name: 'Rustle',
        frames: <ProjectSmartTileAnimationFrame>[
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(
              atlasId: 'atlas',
              column: 0,
              row: 0,
            ),
            durationMs: 100,
          ),
          ProjectSmartTileAnimationFrame(
            frame: SmartTileFrameRef(
              atlasId: 'atlas',
              column: 1,
              row: 0,
            ),
            durationMs: 100,
          ),
        ],
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'grass-preset',
        name: 'Tall grass',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass-material',
        allowedMaterialIds: <String>['grass-material'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'fill',
            centerMatch: SmartTileSlotMatch.material('grass-material'),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'animated',
                parts: <SmartTileVisualPart>[
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.animation(
                      animationId: 'rustle',
                    ),
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
