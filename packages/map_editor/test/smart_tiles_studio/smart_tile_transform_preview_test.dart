import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('editor preview consumes the shared flip-then-rotate visual plan',
      () async {
    final atlas = await _asymmetricAtlas();
    addTearDown(atlas.dispose);
    final recorder = ui.PictureRecorder();
    MapGridPainter(
      map: _map,
      zoom: 1,
      offset: ui.Offset.zero,
      tileWidth: 32,
      tileHeight: 32,
      tilesetImagesById: <String, ui.Image?>{'smart': atlas},
      sourceTileWidth: 32,
      sourceTileHeight: 32,
      tilesPerRowById: const <String, int>{'smart': 1},
      warps: const <MapWarp>[],
      gameplayZones: const <MapGameplayZone>[],
      connectionLabelsByDirection: const <MapConnectionDirection, String>{},
      pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
      terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
      project: _manifest,
      showGrid: false,
      showEntityEditorChrome: false,
      showEditorOverlays: false,
    ).paint(ui.Canvas(recorder), const ui.Size(32, 32));
    final rendered = await recorder.endRecording().toImage(32, 32);

    expect(await _pixelAt(rendered, 8, 8), <int>[255, 255, 0, 255]);
    expect(await _pixelAt(rendered, 24, 8), <int>[0, 255, 0, 255]);
    expect(await _pixelAt(rendered, 8, 24), <int>[0, 0, 255, 255]);
    expect(await _pixelAt(rendered, 24, 24), <int>[255, 0, 0, 255]);
    rendered.dispose();
  });
}

Future<ui.Image> _asymmetricAtlas() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 16, 16),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(16, 0, 16, 16),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 16, 16, 16),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(16, 16, 16, 16),
    ui.Paint()..color = const ui.Color(0xFFFFFF00),
  );
  return recorder.endRecording().toImage(32, 32);
}

Future<List<int>> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return <int>[
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

const _map = MapData(
  id: 'smart-transform-preview',
  name: 'Smart transform preview',
  version: ProjectVersion.v5,
  size: GridSize(width: 1, height: 1),
  layers: <MapLayer>[
    SmartTileLayer(
      id: 'terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(semanticCells: <int>[1]),
    ),
  ],
);

final _manifest = ProjectManifest(
  name: 'Smart transform preview',
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
        id: 'terrain',
        name: 'Terrain',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
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
            id: 'grass',
            centerMatch: SmartTileSlotMatch.material('grass'),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(
                id: 'grass',
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
