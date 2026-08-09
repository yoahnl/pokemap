import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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

  test('editor preview renders 2x1, 2x2, and tall multi-cell frames', () async {
    final scenarios = <({
      String label,
      SmartTileFrameRef frame,
      int footprintWidth,
      int footprintHeight,
      ui.Color color,
      List<ui.Offset> painted,
      List<ui.Offset> transparent,
    })>[
      (
        label: '2x1',
        frame: const SmartTileFrameRef(
          atlasId: 'atlas',
          column: 0,
          row: 0,
          columnSpan: 2,
        ),
        footprintWidth: 2,
        footprintHeight: 1,
        color: const ui.Color(0xFFFF0000),
        painted: const <ui.Offset>[ui.Offset(8, 8), ui.Offset(56, 24)],
        transparent: const <ui.Offset>[ui.Offset(8, 48)],
      ),
      (
        label: '2x2',
        frame: const SmartTileFrameRef(
          atlasId: 'atlas',
          column: 0,
          row: 0,
          columnSpan: 2,
          rowSpan: 2,
        ),
        footprintWidth: 2,
        footprintHeight: 2,
        color: const ui.Color(0xFF00FF00),
        painted: const <ui.Offset>[ui.Offset(8, 8), ui.Offset(56, 56)],
        transparent: const <ui.Offset>[],
      ),
      (
        label: 'tall',
        frame: const SmartTileFrameRef(
          atlasId: 'atlas',
          column: 0,
          row: 0,
          rowSpan: 2,
        ),
        footprintWidth: 1,
        footprintHeight: 2,
        color: const ui.Color(0xFF0000FF),
        painted: const <ui.Offset>[ui.Offset(8, 8), ui.Offset(24, 56)],
        transparent: const <ui.Offset>[ui.Offset(48, 8)],
      ),
    ];

    for (final scenario in scenarios) {
      final fixture = _geometryFixture(
        frame: scenario.frame,
        footprintWidth: scenario.footprintWidth,
        footprintHeight: scenario.footprintHeight,
      );
      final atlas = await _solidAtlas(
        width: scenario.frame.columnSpan * 32,
        height: scenario.frame.rowSpan * 32,
        color: scenario.color,
      );
      addTearDown(atlas.dispose);
      final recorder = ui.PictureRecorder();
      MapGridPainter(
        map: fixture.map,
        zoom: 1,
        offset: ui.Offset.zero,
        tileWidth: 32,
        tileHeight: 32,
        tilesetImagesById: <String, ui.Image?>{'smart': atlas},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{'smart': 2},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        project: fixture.manifest,
        showGrid: false,
        showEntityEditorChrome: false,
        showEditorOverlays: false,
      ).paint(ui.Canvas(recorder), const ui.Size(64, 64));
      final rendered = await recorder.endRecording().toImage(64, 64);
      addTearDown(rendered.dispose);
      final expected = <int>[
        (scenario.color.r * 255).round(),
        (scenario.color.g * 255).round(),
        (scenario.color.b * 255).round(),
        255,
      ];

      for (final point in scenario.painted) {
        expect(
          await _pixelAt(rendered, point.dx.toInt(), point.dy.toInt()),
          expected,
          reason: '${scenario.label} paints $point',
        );
      }
      for (final point in scenario.transparent) {
        expect(
          await _pixelAt(rendered, point.dx.toInt(), point.dy.toInt()),
          const <int>[0, 0, 0, 0],
          reason: '${scenario.label} leaves $point transparent',
        );
      }
    }
  });

  test('editor map preview paints actor occlusion Smart Tile parts', () async {
    final atlas = await _twoColorAtlas();
    addTearDown(atlas.dispose);
    final fixture = _actorOcclusionFixture();
    final recorder = ui.PictureRecorder();
    MapGridPainter(
      map: fixture.map,
      zoom: 1,
      offset: ui.Offset.zero,
      tileWidth: 32,
      tileHeight: 32,
      tilesetImagesById: <String, ui.Image?>{'smart': atlas},
      sourceTileWidth: 32,
      sourceTileHeight: 32,
      tilesPerRowById: const <String, int>{'smart': 2},
      warps: const <MapWarp>[],
      gameplayZones: const <MapGameplayZone>[],
      connectionLabelsByDirection: const <MapConnectionDirection, String>{},
      project: fixture.manifest,
      showGrid: false,
      showEntityEditorChrome: false,
      showEditorOverlays: false,
    ).paint(ui.Canvas(recorder), const ui.Size(32, 32));
    final rendered = await recorder.endRecording().toImage(32, 32);

    expect(await _pixelAt(rendered, 16, 16), <int>[0, 0, 255, 255]);
    rendered.dispose();
  });
}

Future<ui.Image> _twoColorAtlas() {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 32, 32),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(32, 0, 32, 32),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  return recorder.endRecording().toImage(64, 32);
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

Future<ui.Image> _solidAtlas({
  required int width,
  required int height,
  required ui.Color color,
}) {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = color,
  );
  return recorder.endRecording().toImage(width, height);
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
  version: ProjectVersion.v6,
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

({ProjectManifest manifest, MapData map}) _actorOcclusionFixture() {
  const map = MapData(
    id: 'actor-occlusion-preview',
    name: 'Actor occlusion preview',
    version: ProjectVersion.v6,
    size: GridSize(width: 1, height: 1),
    layers: <MapLayer>[
      SmartTileLayer(
        id: 'tall-grass',
        name: 'Tall grass',
        presetId: 'tall-grass',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'grass'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      ),
    ],
  );
  final preset = _manifest.smartTileCatalog.presets.single.copyWith(
    id: 'tall-grass',
    name: 'Tall grass',
    usage: SmartTileUsage.path,
    rules: const <SmartTileRule>[
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
              ),
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'atlas',
                    column: 1,
                    row: 0,
                  ),
                ),
                channel: SmartTileRenderChannel.actorOcclusion,
              ),
            ],
          ),
        ],
      ),
    ],
  );
  final sourceCatalog = _manifest.smartTileCatalog;
  final catalog = ProjectSmartTileCatalog(
    categories: sourceCatalog.categories,
    atlases: <ProjectSmartTileAtlas>[
      sourceCatalog.atlases.single.copyWith(columns: 2),
    ],
    materials: sourceCatalog.materials,
    animations: sourceCatalog.animations,
    presets: <ProjectSmartTilePreset>[preset],
    patterns: sourceCatalog.patterns,
    drafts: sourceCatalog.drafts,
  );
  return (
    manifest: _manifest.copyWith(smartTileCatalog: catalog),
    map: map,
  );
}

({ProjectManifest manifest, MapData map}) _geometryFixture({
  required SmartTileFrameRef frame,
  required int footprintWidth,
  required int footprintHeight,
}) {
  const layer = SmartTileLayer(
    id: 'geometry',
    name: 'Geometry',
    presetId: 'geometry',
    usage: SmartTileUsage.terrain,
    materialPalette: <String>['', 'material'],
    field: SmartTileField.cell(semanticCells: <int>[1]),
  );
  const map = MapData(
    id: 'geometry-map',
    name: 'Geometry map',
    version: ProjectVersion.v6,
    size: GridSize(width: 1, height: 1),
    layers: <MapLayer>[layer],
  );
  final manifest = ProjectManifest(
    name: 'Geometry editor',
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
      atlases: <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'smart',
          columns: frame.columnSpan,
          rows: frame.rowSpan,
        ),
      ],
      materials: const <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'material',
          name: 'Material',
          connectionGroupId: 'material',
        ),
      ],
      presets: <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: 'geometry',
          name: 'Geometry',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.uniform,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: const SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
          ),
          transformPolicy: const SmartTileTransformPolicy(),
          defaultMaterialId: 'material',
          allowedMaterialIds: const <String>['material'],
          rules: <SmartTileRule>[
            SmartTileRule(
              id: 'material',
              centerMatch: const SmartTileSlotMatch.material('material'),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'frame',
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(frame: frame),
                      footprintWidth: footprintWidth,
                      footprintHeight: footprintHeight,
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
  return (manifest: manifest, map: map);
}
