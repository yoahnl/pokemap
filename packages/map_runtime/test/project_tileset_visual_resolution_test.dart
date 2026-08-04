import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('runtime consumes shared collection animation and culling geometry', () {
    final visual = resolveRuntimeProjectTilesetVisual(
      source: _collection,
      selection: const ProjectTilesetVisualSelection.imageCollection(
        tileId: 7,
      ),
      cellWidth: 16,
      cellHeight: 16,
    );

    expect(visual.totalDurationMs, 300);
    expect(visual.frameAt(99).tileId, 8);
    expect(visual.frameAt(100).tileId, 9);
    expect(
      visual.animationBounds,
      const ProjectTilesetPixelRect(x: -2, y: -8, width: 26, height: 26),
    );
    expect(
      visual.cullingRectAt(
        100,
        originX: 32,
        originY: 48,
        conservativeAnimationBounds: true,
      ),
      const ProjectTilesetPixelRect(x: 30, y: 40, width: 26, height: 26),
    );
  });

  test('tile layers render typed atlas margins and spacing exactly', () async {
    const atlas = ProjectRegularAtlasTilesetSource(
      assetId: 'base-asset',
      pixelWidth: 7,
      pixelHeight: 4,
      tileWidth: 2,
      tileHeight: 2,
      marginX: 1,
      marginY: 1,
      spacingX: 1,
    );
    final component = MapLayersComponent(
      bundle: surfaceTestBundle(
        map: const MapData(
          id: 'spaced-atlas-runtime',
          name: 'Spaced atlas runtime',
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            TileLayer(
              id: 'ground',
              name: 'Ground',
              palette: <TileLayerPaletteEntry>[
                TileLayerPaletteEntry(tilesetId: 'base', localTileId: 1),
              ],
              cells: <int>[1],
            ),
          ],
        ),
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'base',
            name: 'Base',
            relativePath: 'tilesets/base.png',
            source: atlas,
          ),
        ],
      ),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{
        'base': await _spacedAtlasImage(),
      },
    );

    final rendered = await renderSurfaceTestComponent(component);

    expect(await pixelAt(rendered, 16, 16), rgba(20, 80, 220, 255));
    expect(await pixelAt(rendered, 1, 1), rgba(20, 80, 220, 255));
  });

  test('typed atlas culling keeps visuals whose owner is four cells away',
      () async {
    const tileSize = surfaceTestTileSize;
    const atlas = ProjectRegularAtlasTilesetSource(
      assetId: 'offset-asset',
      pixelWidth: tileSize,
      pixelHeight: tileSize,
      tileWidth: tileSize,
      tileHeight: tileSize,
      pixelOffsetX: tileSize * 4,
    );
    final component = MapLayersComponent(
      bundle: surfaceTestBundle(
        map: const MapData(
          id: 'offset-culling-runtime',
          name: 'Offset culling runtime',
          size: GridSize(width: 5, height: 1),
          layers: <MapLayer>[
            TileLayer(
              id: 'ground',
              name: 'Ground',
              palette: <TileLayerPaletteEntry>[
                TileLayerPaletteEntry(tilesetId: 'base', localTileId: 0),
              ],
              cells: <int>[1, 0, 0, 0, 0],
            ),
          ],
        ),
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'base',
            name: 'Base',
            relativePath: 'tilesets/base.png',
            source: atlas,
          ),
        ],
      ),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{
        'base': await runtimeTilesetImage(
          const <Color>[Color(0xFF1450DC)],
        ),
      },
    )..setVisibleLocalRect(
        const Rect.fromLTWH(
          tileSize * 4.0,
          0,
          tileSize * 1.0,
          tileSize * 1.0,
        ),
      );

    final recorder = ui.PictureRecorder();
    component.render(Canvas(recorder));
    final rendered = await recorder.endRecording().toImage(
          tileSize * 5,
          tileSize,
        );

    expect(
        await pixelAt(rendered, tileSize * 4 + 16, 16), rgba(20, 80, 220, 255));
  });

  test('tile layers render multiple tilesets and D4 transforms per cell',
      () async {
    const source = ProjectRegularAtlasTilesetSource(
      assetId: 'tile',
      pixelWidth: 2,
      pixelHeight: 2,
      tileWidth: 2,
      tileHeight: 2,
    );
    final component = MapLayersComponent(
      bundle: surfaceTestBundle(
        map: const MapData(
          id: 'multi-tileset-d4',
          name: 'Multi tileset D4',
          size: GridSize(width: 3, height: 1),
          layers: <MapLayer>[
            TileLayer(
              id: 'ground',
              name: 'Ground',
              palette: <TileLayerPaletteEntry>[
                TileLayerPaletteEntry(tilesetId: 'base', localTileId: 0),
                TileLayerPaletteEntry(
                  tilesetId: 'detail',
                  localTileId: 0,
                  transform: SmartTileSpriteTransform(quarterTurns: 1),
                ),
                TileLayerPaletteEntry(
                  tilesetId: 'detail',
                  localTileId: 0,
                  transform: SmartTileSpriteTransform(
                    quarterTurns: 1,
                    flipX: true,
                  ),
                ),
              ],
              cells: <int>[1, 2, 3],
            ),
          ],
        ),
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'base',
            name: 'Base',
            relativePath: 'tilesets/base.png',
            source: source,
          ),
          ProjectTilesetEntry(
            id: 'detail',
            name: 'Detail',
            relativePath: 'tilesets/detail.png',
            source: source,
          ),
        ],
      ),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{
        'base': await _quadrantImage(const <Color>[
          Color(0xFFCC1010),
          Color(0xFFCC1010),
          Color(0xFFCC1010),
          Color(0xFFCC1010),
        ]),
        'detail': await _quadrantImage(const <Color>[
          Color(0xFF10CC10),
          Color(0xFF1010CC),
          Color(0xFFCCCC10),
          Color(0xFFFFFFFF),
        ]),
      },
    );

    final recorder = ui.PictureRecorder();
    component.render(Canvas(recorder));
    final rendered = await recorder.endRecording().toImage(
          surfaceTestTileSize * 3,
          surfaceTestTileSize,
        );

    expect(await pixelAt(rendered, 4, 4), rgba(204, 16, 16, 255));
    expect(await pixelAt(rendered, 36, 4), rgba(204, 204, 16, 255));
    expect(await pixelAt(rendered, 68, 4), rgba(255, 255, 255, 255));
  });

  test('object layers render fractional visual-only tile objects', () async {
    const source = ProjectRegularAtlasTilesetSource(
      assetId: 'object-asset',
      pixelWidth: surfaceTestTileSize,
      pixelHeight: surfaceTestTileSize,
      tileWidth: surfaceTestTileSize,
      tileHeight: surfaceTestTileSize,
    );
    final component = MapLayersComponent(
      bundle: surfaceTestBundle(
        map: const MapData(
          id: 'fractional-object-runtime',
          name: 'Fractional object runtime',
          version: ProjectVersion.v6,
          visualStack: MapVisualStackConfig.canonicalV1,
          size: GridSize(width: 1, height: 1),
          layers: <MapLayer>[
            ObjectLayer(
              id: 'objects',
              name: 'Objects',
              tileObjects: <MapPlacedTile>[
                MapPlacedTile(
                  id: 'fractional-prop',
                  tile: TileLayerPaletteEntry(
                    tilesetId: 'props',
                    localTileId: 0,
                  ),
                  anchorX: 0.25,
                  anchorY: 0.75,
                  width: 0.5,
                  height: 0.5,
                ),
              ],
            ),
          ],
        ),
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'props',
            name: 'Props',
            relativePath: 'tilesets/props.png',
            source: source,
          ),
        ],
      ),
      tileImagesByTilesetId: <String, RuntimeTilesetImage>{
        'object-asset': await runtimeTilesetImage(
          const <Color>[Color(0xFF1450DC)],
        ),
      },
    );

    final rendered = await renderSurfaceTestComponent(component);

    expect(await pixelAt(rendered, 10, 10), rgba(20, 80, 220, 255));
    expect(await pixelAt(rendered, 4, 4), rgba(0, 0, 0, 0));
  });
}

Future<RuntimeTilesetImage> _quadrantImage(List<Color> colors) async {
  assert(colors.length == 4);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var index = 0; index < colors.length; index++) {
    canvas.drawRect(
      Rect.fromLTWH((index % 2).toDouble(), (index ~/ 2).toDouble(), 1, 1),
      Paint()..color = colors[index],
    );
  }
  final image = await recorder.endRecording().toImage(2, 2);
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: 2, width: 2),
    ],
    width: 2,
    height: 2,
  );
}

Future<RuntimeTilesetImage> _spacedAtlasImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 7, 4),
    Paint()..color = const Color(0xFFFF00FF),
  );
  canvas.drawRect(
    const Rect.fromLTWH(1, 1, 2, 2),
    Paint()..color = const Color(0xFF20C060),
  );
  canvas.drawRect(
    const Rect.fromLTWH(4, 1, 2, 2),
    Paint()..color = const Color(0xFF1450DC),
  );
  final image = await recorder.endRecording().toImage(7, 4);
  return RuntimeTilesetImage(
    images: <ui.Image>[image],
    chunks: const <RuntimeTilesetChunk>[
      RuntimeTilesetChunk(top: 0, height: 4, width: 7),
    ],
    width: 7,
    height: 4,
  );
}

const _collection = ProjectImageCollectionTilesetSource(
  pages: <ProjectImageCollectionPage>[
    ProjectImageCollectionPage(
      id: 'page',
      assetId: 'page-asset',
      pixelWidth: 64,
      pixelHeight: 64,
    ),
  ],
  tileDefinitions: <ProjectImageCollectionTileDefinition>[
    ProjectImageCollectionTileDefinition(
      tileId: 7,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 0,
        y: 0,
        width: 16,
        height: 16,
      ),
      animation: <ProjectImageCollectionAnimationFrame>[
        ProjectImageCollectionAnimationFrame(tileId: 8, durationMs: 100),
        ProjectImageCollectionAnimationFrame(tileId: 9, durationMs: 200),
      ],
    ),
    ProjectImageCollectionTileDefinition(
      tileId: 8,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 16,
        y: 0,
        width: 24,
        height: 24,
      ),
    ),
    ProjectImageCollectionTileDefinition(
      tileId: 9,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 40,
        y: 0,
        width: 16,
        height: 16,
      ),
      offsetX: -2,
      offsetY: 2,
    ),
  ],
);
