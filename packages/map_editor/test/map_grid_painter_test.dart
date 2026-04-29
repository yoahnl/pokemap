import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/path_autotile_set.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  group('MapGridPainter foreground split helpers', () {
    test(
        'marks only non-collision cells of multi-tile placed elements as foreground',
        () {
      const map = MapData(
        id: 'lab',
        name: 'lab',
        size: GridSize(width: 3, height: 2),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tiles: <int>[
              1,
              1,
              0,
              1,
              1,
              0,
            ],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'table_1',
            layerId: 'ground',
            elementId: 'table',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );

      final project = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
        name: 'editor',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        surfaceCatalog: ProjectSurfaceCatalog(),
        elements: const <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'table',
            name: 'Table',
            tilesetId: 'interior',
            categoryId: 'decor',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
              ),
            ],
            collisionProfile: ElementCollisionProfile(
              cells: <GridPos>[
                GridPos(x: 0, y: 0),
                GridPos(x: 1, y: 0),
              ],
            ),
          ),
        ],
      );

      final result = buildEditorForegroundTileCellIndicesByLayerId(
        map: map,
        project: project,
      );

      expect(result['ground'], equals(<int>{3, 4}));
    });

    test('routes split cells to the correct render pass deterministically', () {
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: false,
          isForegroundCell: false,
          foregroundPass: false,
        ),
        isTrue,
      );
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: false,
          isForegroundCell: true,
          foregroundPass: false,
        ),
        isFalse,
      );
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: false,
          isForegroundCell: true,
          foregroundPass: true,
        ),
        isTrue,
      );
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: true,
          isForegroundCell: false,
          foregroundPass: false,
        ),
        isFalse,
      );
      expect(
        shouldPaintEditorTileCellInRenderPass(
          explicitForeground: true,
          isForegroundCell: false,
          foregroundPass: true,
        ),
        isTrue,
      );
    });

    test('routes project-element entities to the requested render pass', () {
      const normalEntity = MapEntity(
        id: 'pokeball',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 0),
        editorVisual: MapEntityEditorVisual(elementId: 'pokeball'),
      );
      const foregroundEntity = MapEntity(
        id: 'pokeball_top',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 0),
        editorVisual: MapEntityEditorVisual(
          elementId: 'pokeball',
          renderInForeground: true,
        ),
      );

      expect(
        shouldPaintEditorEntityInForegroundPass(
          normalEntity,
          foregroundPass: false,
        ),
        isTrue,
      );
      expect(
        shouldPaintEditorEntityInForegroundPass(
          normalEntity,
          foregroundPass: true,
        ),
        isFalse,
      );
      expect(
        shouldPaintEditorEntityInForegroundPass(
          foregroundEntity,
          foregroundPass: false,
        ),
        isFalse,
      );
      expect(
        shouldPaintEditorEntityInForegroundPass(
          foregroundEntity,
          foregroundPass: true,
        ),
        isTrue,
      );
    });

    test('paints SurfaceLayer static preview without atlas tile images', () {
      const map = MapData(
        id: 'pond',
        name: 'Pond',
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          SurfaceLayer(
            id: 'surface-main',
            name: 'Surfaces',
            placements: <SurfaceCellPlacement>[
              SurfaceCellPlacement(x: 1, y: 1, surfacePresetId: 'water'),
            ],
          ),
        ],
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        tileWidth: 32,
        tileHeight: 32,
        tilesetImagesById: const <String, ui.Image?>{},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
      ).paint(canvas, const ui.Size(96, 96));

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('paints SurfaceLayer with resolved atlas tile image when available',
        () async {
      const map = MapData(
        id: 'pond',
        name: 'Pond',
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          SurfaceLayer(
            id: 'surface-main',
            name: 'Surfaces',
            placements: <SurfaceCellPlacement>[
              SurfaceCellPlacement(
                x: 1,
                y: 1,
                surfacePresetId: 'water-surface',
              ),
            ],
          ),
        ],
      );
      final project = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        surfaceCatalog: _surfaceCatalog(),
      );
      final tilesetImage = await _testTilesetImage();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        tileWidth: 32,
        tileHeight: 32,
        tilesetImagesById: {'water-tileset': tilesetImage},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: project,
      ).paint(canvas, const ui.Size(96, 96));

      final picture = recorder.endRecording();
      final image = await picture.toImage(96, 96);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final offset = ((48 * image.width) + 48) * 4;
      expect(pixels!.getUint8(offset), greaterThan(220));
      expect(pixels.getUint8(offset + 1), lessThan(40));
      expect(pixels.getUint8(offset + 2), lessThan(40));
      picture.dispose();
      image.dispose();
      tilesetImage.dispose();
    });

    test('paints SurfaceLayer atlas tile from current editor elapsed time',
        () async {
      const map = MapData(
        id: 'pond',
        name: 'Pond',
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          SurfaceLayer(
            id: 'surface-main',
            name: 'Surfaces',
            placements: <SurfaceCellPlacement>[
              SurfaceCellPlacement(
                x: 1,
                y: 1,
                surfacePresetId: 'water-surface',
              ),
            ],
          ),
        ],
      );
      final project = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        surfaceCatalog: _surfaceCatalog(),
      );
      final tilesetImage = await _testTilesetImage();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        tileWidth: 32,
        tileHeight: 32,
        tilesetImagesById: {'water-tileset': tilesetImage},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: project,
        editorEntityAnimationMs: 120,
      ).paint(canvas, const ui.Size(96, 96));

      final picture = recorder.endRecording();
      final image = await picture.toImage(96, 96);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final offset = ((48 * image.width) + 48) * 4;
      expect(pixels!.getUint8(offset), lessThan(40));
      expect(pixels.getUint8(offset + 1), lessThan(40));
      expect(pixels.getUint8(offset + 2), greaterThan(220));
      picture.dispose();
      image.dispose();
      tilesetImage.dispose();
    });
  });
}

ProjectSurfaceCatalog _surfaceCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      ProjectSurfaceAtlas(
        id: 'water-atlas',
        name: 'Water Atlas',
        tilesetId: 'water-tileset',
        geometry: SurfaceAtlasGeometry(
          tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
          gridSize: SurfaceAtlasGridSize(columns: 4, rows: 4),
          layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
        ),
      ),
    ],
    animations: [
      ProjectSurfaceAnimation(
        id: 'water-isolated-loop',
        name: 'Water Isolated',
        timeline: SurfaceAnimationTimeline(
          frames: [
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(
                atlasId: 'water-atlas',
                column: 2,
                row: 0,
              ),
              durationMs: 120,
            ),
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(
                atlasId: 'water-atlas',
                column: 3,
                row: 0,
              ),
              durationMs: 120,
            ),
          ],
        ),
      ),
    ],
    presets: [
      ProjectSurfacePreset(
        id: 'water-surface',
        name: 'Water',
        variantAnimations: SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: 'water-isolated-loop',
            ),
          ],
        ),
      ),
    ],
  );
}

Future<ui.Image> _testTilesetImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 128, 128),
    ui.Paint()..color = const ui.Color(0x00000000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(64, 0, 32, 32),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(96, 0, 32, 32),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(128, 128);
  picture.dispose();
  return image;
}
