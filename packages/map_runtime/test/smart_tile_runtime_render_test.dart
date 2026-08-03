import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_manifest_tilesets.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
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

  test('runtime render is byte-identical after reopening v6 project data',
      () async {
    final tileset = await runtimeTilesetImage(
      const <Color>[Color(0xFFFF0000), Color(0xFF0000FF)],
    );
    addTearDown(tileset.dispose);
    final reopenedManifest = ProjectManifest.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(jsonEncode(_manifest.toJson())) as Map,
      ),
    );
    final reopenedMap = MapData.fromJson(
      Map<String, dynamic>.from(jsonDecode(jsonEncode(_map.toJson())) as Map),
    );

    // The certification compares final pixels rather than model equality: a
    // codec or runtime regression can preserve JSON fields yet still change a
    // channel, transform or draw order after the project is reopened.
    for (final renderPass in MapLayerRenderPass.values) {
      final before = await _render(
        MapLayersComponent(
          bundle: RuntimeMapBundle(
            manifest: _manifest,
            map: _map,
            projectRootDirectory: '/tmp/smart-runtime-reopen-before',
            tilesetAbsolutePathsById: const <String, String>{},
          ),
          tileImagesByTilesetId: <String, RuntimeTilesetImage>{
            'smart': tileset,
          },
          renderPass: renderPass,
        ),
      );
      final after = await _render(
        MapLayersComponent(
          bundle: RuntimeMapBundle(
            manifest: reopenedManifest,
            map: reopenedMap,
            projectRootDirectory: '/tmp/smart-runtime-reopen-after',
            tilesetAbsolutePathsById: const <String, String>{},
          ),
          tileImagesByTilesetId: <String, RuntimeTilesetImage>{
            'smart': tileset,
          },
          renderPass: renderPass,
        ),
      );

      expect(
        await _rgbaBytes(after),
        orderedEquals(await _rgbaBytes(before)),
        reason: renderPass.name,
      );
      before.dispose();
      after.dispose();
    }
  });

  test('runtime applies flipX before clockwise rotation with nearest filtering',
      () async {
    final image = await _asymmetricRuntimeImage();
    addTearDown(image.dispose);
    final component = MapLayersComponent(
      bundle: RuntimeMapBundle(
        manifest: _manifest,
        map: _map,
        projectRootDirectory: '/tmp/smart-runtime-transform-test',
        tilesetAbsolutePathsById: const <String, String>{},
      ),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{'smart': image},
    );

    final rendered = await _render(component);

    expect(await pixelAt(rendered, 8, 8), rgba(255, 255, 0, 255));
    expect(await pixelAt(rendered, 24, 8), rgba(0, 255, 0, 255));
    expect(await pixelAt(rendered, 8, 24), rgba(0, 0, 255, 255));
    expect(await pixelAt(rendered, 24, 24), rgba(255, 0, 0, 255));
    rendered.dispose();
  });
}

Future<ui.Image> _render(MapLayersComponent component) {
  final recorder = ui.PictureRecorder();
  component.render(Canvas(recorder));
  return recorder.endRecording().toImage(32, 32);
}

Future<List<int>> _rgbaBytes(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

Future<RuntimeTilesetImage> _asymmetricRuntimeImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 16, 16),
    Paint()..color = const Color(0xFFFF0000),
  );
  canvas.drawRect(
    const Rect.fromLTWH(16, 0, 16, 16),
    Paint()..color = const Color(0xFF00FF00),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 16, 16, 16),
    Paint()..color = const Color(0xFF0000FF),
  );
  canvas.drawRect(
    const Rect.fromLTWH(16, 16, 16, 16),
    Paint()..color = const Color(0xFFFFFF00),
  );
  canvas.drawRect(
    const Rect.fromLTWH(32, 0, 32, 32),
    Paint()..color = const Color(0xFF0000FF),
  );
  final image = await recorder.endRecording().toImage(64, 32);
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: 32, width: 64),
    ],
    width: 64,
    height: 32,
  );
}

const _map = MapData(
  id: 'smart-map',
  name: 'Smart Map',
  version: ProjectVersion.v6,
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
        transformPolicy: SmartTileTransformPolicy(
          allowHFlip: true,
          allowQuarterTurns: true,
        ),
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
                    transform: SmartTileSpriteTransform(
                      quarterTurns: 1,
                      flipX: true,
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
