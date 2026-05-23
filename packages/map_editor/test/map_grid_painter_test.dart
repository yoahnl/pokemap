import 'dart:io';
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

      final project = ProjectManifest(
        name: 'editor',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
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
      final project = ProjectManifest(
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

    test('paints placed elements even when their TileLayer has no tiles',
        () async {
      const map = MapData(
        id: 'forest',
        name: 'Forest',
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          TileLayer(
            id: 'environment',
            name: 'Environment',
            tilesetId: 'element-tileset',
            tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'generated_tree_1',
            layerId: 'environment',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'element-tileset',
            name: 'Element Tileset',
            relativePath: 'tilesets/elements.png',
          ),
        ],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        elements: const <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'element-tileset',
            categoryId: 'nature',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 2, y: 0),
              ),
            ],
          ),
        ],
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
        tilesetImagesById: {'element-tileset': tilesetImage},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{'element-tileset': 4},
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

    test('paints static shadow preview below placed elements', () async {
      const map = MapData(
        id: 'market',
        name: 'Market',
        size: GridSize(width: 5, height: 5),
        layers: <MapLayer>[
          TileLayer(
            id: 'environment',
            name: 'Environment',
            tilesetId: 'element-tileset',
            tiles: <int>[
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
            ],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'stand_1',
            layerId: 'environment',
            elementId: 'stand',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        shadowCatalog: ProjectShadowCatalog(
          profiles: [
            ProjectShadowProfile(
              id: 'stand_shadow',
              name: 'Stand shadow',
              mode: ShadowCasterMode.ellipse,
              renderPass: ShadowRenderPass.groundStatic,
              offsetX: 3,
              offsetY: 5,
              opacity: 0.5,
            ),
          ],
        ),
        elements: [
          ProjectElementEntry(
            id: 'stand',
            name: 'Stand',
            tilesetId: 'element-tileset',
            categoryId: 'market',
            frames: const <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
              ),
            ],
            shadow: ProjectElementShadowConfig(
              castsShadow: true,
              shadowProfileId: 'stand_shadow',
            ),
          ),
        ],
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        tileWidth: 16,
        tileHeight: 16,
        tilesetImagesById: const <String, ui.Image?>{},
        sourceTileWidth: 16,
        sourceTileHeight: 16,
        tilesPerRowById: const <String, int>{},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: project,
      ).paint(canvas, const ui.Size(80, 80));

      final picture = recorder.endRecording();
      final image = await picture.toImage(80, 80);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final offset = ((53 * image.width) + 35) * 4;
      expect(pixels!.getUint8(offset + 3), greaterThan(0));
      picture.dispose();
      image.dispose();
    });

    test('paints projected building shadow preview below placed elements',
        () async {
      const map = MapData(
        id: 'market',
        name: 'Market',
        size: GridSize(width: 5, height: 7),
        layers: <MapLayer>[
          TileLayer(
            id: 'environment',
            name: 'Environment',
            tilesetId: 'element-tileset',
            tiles: <int>[
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
              0,
            ],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'building_1',
            layerId: 'environment',
            elementId: 'building',
            pos: GridPos(x: 1, y: 2),
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'element-tileset',
            name: 'Element Tileset',
            relativePath: 'tilesets/elements.png',
          ),
        ],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        projectedBuildingShadowCatalog: ProjectBuildingShadowPresetCatalog(
          presets: [_projectedBuildingShadowPreset()],
        ),
        elements: [
          ProjectElementEntry(
            id: 'building',
            name: 'Building',
            tilesetId: 'element-tileset',
            categoryId: 'market',
            frames: const <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
              ),
            ],
            projectedBuildingShadow: _projectedBuildingShadowConfig(),
          ),
        ],
      );
      final tilesetImage = await _solidColorImage(
        width: 64,
        height: 96,
        color: const ui.Color(0xFFFF0000),
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        tileWidth: 32,
        tileHeight: 32,
        tilesetImagesById: {'element-tileset': tilesetImage},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{'element-tileset': 2},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: project,
      ).paint(canvas, const ui.Size(160, 224));

      final picture = recorder.endRecording();
      final image = await picture.toImage(160, 224);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final shadowOnlyOffset = _rgbaOffset(image, x: 104, y: 150);
      expect(pixels!.getUint8(shadowOnlyOffset + 3), greaterThan(0));
      final spriteOverShadowOffset = _rgbaOffset(image, x: 80, y: 150);
      expect(pixels.getUint8(spriteOverShadowOffset), greaterThan(220));
      expect(pixels.getUint8(spriteOverShadowOffset + 1), lessThan(40));
      expect(pixels.getUint8(spriteOverShadowOffset + 2), lessThan(40));
      expect(pixels.getUint8(spriteOverShadowOffset + 3), greaterThan(240));
      picture.dispose();
      image.dispose();
      tilesetImage.dispose();
    });

    test(
        'paints projected building shadow preview before static shadow preview',
        () {
      final source = File(
        'lib/src/ui/canvas/map_canvas/map_grid_painter.dart',
      ).readAsStringSync();
      final projectedPaintIndex = source.indexOf(
        'paintEditorStaticShadowPreviewInstructions(\n'
        '      canvas,\n'
        '      projectedBuildingShadowPreviewInstructions,\n'
        '    );',
      );
      final staticPaintIndex = source.indexOf(
        'paintEditorStaticShadowPreviewInstructions(\n'
        '      canvas,\n'
        '      staticShadowPreviewInstructions,\n'
        '    );',
      );

      expect(projectedPaintIndex, isNonNegative);
      expect(staticPaintIndex, isNonNegative);
      expect(projectedPaintIndex, lessThan(staticPaintIndex));
    });

    test(
        'does not double-paint matching baked tiles under translucent elements',
        () async {
      const map = MapData(
        id: 'forest',
        name: 'Forest',
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          TileLayer(
            id: 'environment',
            name: 'Environment',
            tilesetId: 'element-tileset',
            tiles: <int>[3],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'tree_1',
            layerId: 'environment',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
            opacity: 0.5,
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'element-tileset',
            name: 'Element Tileset',
            relativePath: 'tilesets/elements.png',
          ),
        ],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        elements: const <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'element-tileset',
            categoryId: 'nature',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 2, y: 0),
              ),
            ],
          ),
        ],
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
        tilesetImagesById: {'element-tileset': tilesetImage},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{'element-tileset': 4},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: project,
      ).paint(canvas, const ui.Size(32, 32));

      final picture = recorder.endRecording();
      final image = await picture.toImage(32, 32);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final offset = ((16 * image.width) + 16) * 4;
      expect(pixels!.getUint8(offset), inInclusiveRange(110, 150));
      expect(pixels.getUint8(offset + 1), lessThan(40));
      expect(pixels.getUint8(offset + 2), lessThan(40));
      expect(pixels.getUint8(offset + 3), inInclusiveRange(110, 150));
      picture.dispose();
      image.dispose();
      tilesetImage.dispose();
    });

    test('keeps non-matching base tiles visible under translucent elements',
        () async {
      const map = MapData(
        id: 'forest',
        name: 'Forest',
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          TileLayer(
            id: 'environment',
            name: 'Environment',
            tilesetId: 'element-tileset',
            tiles: <int>[4],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'tree_1',
            layerId: 'environment',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
            opacity: 0.5,
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'element-tileset',
            name: 'Element Tileset',
            relativePath: 'tilesets/elements.png',
          ),
        ],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        elements: const <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'element-tileset',
            categoryId: 'nature',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 2, y: 0),
              ),
            ],
          ),
        ],
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
        tilesetImagesById: {'element-tileset': tilesetImage},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{'element-tileset': 4},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: project,
      ).paint(canvas, const ui.Size(32, 32));

      final picture = recorder.endRecording();
      final image = await picture.toImage(32, 32);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final offset = ((16 * image.width) + 16) * 4;
      expect(pixels!.getUint8(offset), inInclusiveRange(110, 150));
      expect(pixels.getUint8(offset + 1), lessThan(40));
      expect(pixels.getUint8(offset + 2), inInclusiveRange(110, 150));
      expect(pixels.getUint8(offset + 3), greaterThan(240));
      picture.dispose();
      image.dispose();
      tilesetImage.dispose();
    });

    test('delete preview highlights sprite without footprint rectangle',
        () async {
      const map = MapData(
        id: 'forest',
        name: 'Forest',
        size: GridSize(width: 3, height: 3),
        layers: <MapLayer>[
          TileLayer(
            id: 'environment',
            name: 'Environment',
            tilesetId: 'element-tileset',
            tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'generated_tree_1',
            layerId: 'environment',
            elementId: 'tree_large',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'element-tileset',
            name: 'Element Tileset',
            relativePath: 'tilesets/elements.png',
          ),
        ],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
        elements: const <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'tree_large',
            name: 'Large Tree',
            tilesetId: 'element-tileset',
            categoryId: 'nature',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 2, y: 0, width: 2, height: 2),
              ),
            ],
          ),
        ],
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
        tilesetImagesById: {'element-tileset': tilesetImage},
        sourceTileWidth: 32,
        sourceTileHeight: 32,
        tilesPerRowById: const <String, int>{'element-tileset': 4},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: project,
        environmentGeneratedDeletePreviewId: 'generated_tree_1',
      ).paint(canvas, const ui.Size(96, 96));

      final picture = recorder.endRecording();
      final image = await picture.toImage(96, 96);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final spriteOffset = ((48 * image.width) + 48) * 4;
      expect(pixels!.getUint8(spriteOffset), greaterThan(220));
      expect(pixels.getUint8(spriteOffset + 1), greaterThan(60));
      expect(pixels.getUint8(spriteOffset + 2), greaterThan(60));
      expect(pixels.getUint8(spriteOffset + 3), greaterThan(240));
      final transparentFootprintOffset = ((80 * image.width) + 48) * 4;
      expect(pixels.getUint8(transparentFootprintOffset + 3), lessThan(5));
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
      final project = ProjectManifest(
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

    test('paints path layer with center-only 2x2 PathPattern in canvas',
        () async {
      const map = MapData(
        id: 'water_map',
        name: 'Water Map',
        size: GridSize(width: 4, height: 2),
        layers: <MapLayer>[
          PathLayer(
            id: 'path_main',
            name: 'Path',
            presetId: 'water-base',
            cells: <bool>[
              true,
              true,
              true,
              true,
              true,
              true,
              true,
              true,
            ],
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'editor',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'water-tileset',
            name: 'Water',
            relativePath: 'tilesets/water.png',
          ),
        ],
        pathPresets: const <ProjectPathPreset>[
          ProjectPathPreset(
            id: 'water-base',
            name: 'Water Base',
            tilesetId: 'water-tileset',
            variants: <PathPresetVariantMapping>[],
          ),
        ],
        pathPatternPresets: [
          ProjectPathPatternPreset(
            id: 'water-pattern',
            name: 'Water Pattern',
            basePathPresetId: 'water-base',
            centerPattern: PathCenterPattern(
              size: PathCenterPatternSize(width: 2, height: 2),
              cells: [
                PathCenterPatternCell(
                  localX: 0,
                  localY: 0,
                  frames: const [
                    TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 0)),
                  ],
                ),
                PathCenterPatternCell(
                  localX: 1,
                  localY: 0,
                  frames: const [
                    TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 0)),
                  ],
                ),
                PathCenterPatternCell(
                  localX: 0,
                  localY: 1,
                  frames: const [
                    TilesetVisualFrame(source: TilesetSourceRect(x: 5, y: 1)),
                  ],
                ),
                PathCenterPatternCell(
                  localX: 1,
                  localY: 1,
                  frames: const [
                    TilesetVisualFrame(source: TilesetSourceRect(x: 6, y: 1)),
                  ],
                ),
              ],
            ),
          ),
        ],
        surfaceCatalog: const ProjectSurfaceCatalog.empty(),
      );
      final tilesetImage = await _testPathPatternTilesetImage();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        tileWidth: 16,
        tileHeight: 16,
        tilesetImagesById: {'water-tileset': tilesetImage},
        sourceTileWidth: 16,
        sourceTileHeight: 16,
        tilesPerRowById: const <String, int>{'water-tileset': 12},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        pathAutotileSetsByPresetId: {
          'water-base': PathAutotileSet.defaultForTileset('water-tileset'),
        },
        terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
        project: project,
      ).paint(canvas, const ui.Size(64, 32));

      final picture = recorder.endRecording();
      final image = await picture.toImage(64, 32);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      void expectPixelColor(
        int x,
        int y, {
        required bool Function(int value) red,
        required bool Function(int value) green,
        required bool Function(int value) blue,
      }) {
        final offset = ((y * image.width) + x) * 4;
        expect(red(pixels!.getUint8(offset)), isTrue);
        expect(green(pixels.getUint8(offset + 1)), isTrue);
        expect(blue(pixels.getUint8(offset + 2)), isTrue);
      }

      expectPixelColor(
        8,
        8,
        red: (value) => value > 220,
        green: (value) => value < 20,
        blue: (value) => value < 20,
      );
      expectPixelColor(
        24,
        8,
        red: (value) => value < 20,
        green: (value) => value > 220,
        blue: (value) => value < 20,
      );
      expectPixelColor(
        8,
        24,
        red: (value) => value < 20,
        green: (value) => value < 20,
        blue: (value) => value > 220,
      );
      expectPixelColor(
        24,
        24,
        red: (value) => value > 220,
        green: (value) => value > 220,
        blue: (value) => value < 20,
      );
      expectPixelColor(
        40,
        8,
        red: (value) => value > 220,
        green: (value) => value < 20,
        blue: (value) => value < 20,
      );

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

Future<ui.Image> _solidColorImage({
  required int width,
  required int height,
  required ui.Color color,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = color,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

Future<ui.Image> _testPathPatternTilesetImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 192, 32),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(80, 0, 16, 16),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(96, 0, 16, 16),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(80, 16, 16, 16),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(96, 16, 16, 16),
    ui.Paint()..color = const ui.Color(0xFFFFFF00),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(192, 32);
  picture.dispose();
  return image;
}

ProjectBuildingShadowPreset _projectedBuildingShadowPreset() {
  return ProjectBuildingShadowPreset(
    id: 'shadow-a',
    name: 'Shadow A',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.18,
      colorHexRgb: '123ABC',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _projectedBuildingShadowConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'shadow-a',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

int _rgbaOffset(ui.Image image, {required int x, required int y}) {
  return ((y * image.width) + x) * 4;
}
