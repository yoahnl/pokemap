import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_placed_element_rotation_planner.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/canvas/map_canvas/editor_canvas_repaint_clock.dart';

void main() {
  group('MapGridPainter foreground split helpers', () {
    test('keeps painting maps that contain a Smart Tile layer', () {
      const map = MapData(
        id: 'smart-tile-map',
        name: 'Smart Tile map',
        version: ProjectVersion.v6,
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          SmartTileLayer(
            id: 'smart-terrain',
            name: 'Smart terrain',
            presetId: 'grass',
            usage: SmartTileUsage.terrain,
            field: SmartTileField.cell(
              semanticCells: <int>[0, 0, 0, 0],
            ),
          ),
        ],
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final painter = MapGridPainter(
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
      );

      expect(
        () => painter.paint(canvas, const ui.Size(64, 64)),
        returnsNormally,
      );
      recorder.endRecording().dispose();
    });

    test('can hide the editor grid for clean visual QA captures', () async {
      const map = MapData(
        id: 'grid-qa',
        name: 'Grid QA',
        size: GridSize(width: 2, height: 2),
      );

      Future<int> alphaAtGridLine({required bool showGrid}) async {
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
          showGrid: showGrid,
        ).paint(canvas, const ui.Size(64, 64));
        final picture = recorder.endRecording();
        final image = await picture.toImage(64, 64);
        final pixels =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final pixelOffset = ((16 * image.width) + 32) * 4;
        final alpha = pixels!.getUint8(pixelOffset + 3);
        picture.dispose();
        image.dispose();
        return alpha;
      }

      expect(await alphaAtGridLine(showGrid: true), greaterThan(0));
      expect(await alphaAtGridLine(showGrid: false), 0);
    });

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

      const project = ProjectManifest(
        name: 'editor',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        elements: <ProjectElementEntry>[
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

    test('rotates source collision cells into destination foreground bounds',
        () {
      final map = MapData(
        id: 'rotated-foreground',
        name: 'Rotated foreground',
        size: const GridSize(width: 4, height: 4),
        layers: <MapLayer>[
          TileLayer(
            id: 'ground',
            name: 'Ground',
            tiles: List<int>.filled(16, 1, growable: false),
          ),
        ],
        placedElements: const <MapPlacedElement>[
          MapPlacedElement(
            id: 'rotated-table',
            layerId: 'ground',
            elementId: 'table-3x2',
            pos: GridPos(x: 1, y: 0),
            quarterTurns: 1,
          ),
        ],
      );
      const project = ProjectManifest(
        name: 'editor',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'table-3x2',
            name: 'Table 3x2',
            tilesetId: 'interior',
            categoryId: 'decor',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 3, height: 2),
              ),
            ],
            collisionProfile: ElementCollisionProfile(
              cells: <GridPos>[GridPos(x: 0, y: 0)],
            ),
          ),
        ],
      );

      final result = buildEditorForegroundTileCellIndicesByLayerId(
        map: map,
        project: project,
      );

      expect(result['ground'], equals(<int>{1, 5, 6, 9, 10}));
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
      const project = ProjectManifest(
        name: 'editor',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'element-tileset',
            name: 'Element Tileset',
            relativePath: 'tilesets/elements.png',
          ),
        ],
        elements: <ProjectElementEntry>[
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

    test('rotates non-square placed-element cells and rectangular pixels',
        () async {
      final tilesetImage = await _rectangularAsymmetricTilesetImage();

      Future<ByteData> render(
        int quarterTurns, {
        int animationMs = 0,
      }) async {
        final map = MapData(
          id: 'rotated-pixels-$quarterTurns',
          name: 'Rotated pixels',
          size: const GridSize(width: 2, height: 2),
          layers: const <MapLayer>[
            TileLayer(
              id: 'decor',
              name: 'Decor',
              tilesetId: 'rectangular',
              tiles: <int>[0, 0, 0, 0],
            ),
          ],
          placedElements: <MapPlacedElement>[
            MapPlacedElement(
              id: 'asymmetric',
              layerId: 'decor',
              elementId: 'two-cells',
              pos: const GridPos(x: 0, y: 0),
              quarterTurns: quarterTurns,
            ),
          ],
        );
        const project = ProjectManifest(
          name: 'Rotated painter',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[
            ProjectTilesetEntry(
              id: 'rectangular',
              name: 'Rectangular',
              relativePath: 'rectangular.png',
            ),
          ],
          elements: <ProjectElementEntry>[
            ProjectElementEntry(
              id: 'two-cells',
              name: 'Two cells',
              tilesetId: 'rectangular',
              categoryId: 'decor',
              frames: <TilesetVisualFrame>[
                TilesetVisualFrame(
                  source: TilesetSourceRect(
                    x: 0,
                    y: 0,
                    width: 2,
                    height: 1,
                  ),
                  durationMs: 100,
                ),
                TilesetVisualFrame(
                  source: TilesetSourceRect(
                    x: 0,
                    y: 1,
                    width: 2,
                    height: 1,
                  ),
                  durationMs: 100,
                ),
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
          tileWidth: 12,
          tileHeight: 8,
          tilesetImagesById: <String, ui.Image?>{
            'rectangular': tilesetImage,
          },
          sourceTileWidth: 8,
          sourceTileHeight: 4,
          tilesPerRowById: const <String, int>{'rectangular': 2},
          warps: const <MapWarp>[],
          gameplayZones: const <MapGameplayZone>[],
          connectionLabelsByDirection: const <MapConnectionDirection, String>{},
          project: project,
          editorEntityAnimationMs: animationMs,
          showGrid: false,
          showEditorOverlays: false,
        ).paint(canvas, const ui.Size(24, 16));
        final picture = recorder.endRecording();
        final image = await picture.toImage(24, 16);
        final pixels =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        picture.dispose();
        image.dispose();
        return pixels!;
      }

      void expectRgb(
        ByteData pixels,
        int x,
        int y,
        int red,
        int green,
        int blue,
      ) {
        final offset = ((y * 24) + x) * 4;
        expect(pixels.getUint8(offset), red);
        expect(pixels.getUint8(offset + 1), green);
        expect(pixels.getUint8(offset + 2), blue);
      }

      final q1 = await render(1);
      expectRgb(q1, 6, 2, 255, 0, 0);
      expectRgb(q1, 6, 6, 0, 255, 0);
      expectRgb(q1, 6, 10, 0, 0, 255);
      expectRgb(q1, 6, 14, 255, 255, 0);

      final q3 = await render(3);
      expectRgb(q3, 6, 2, 255, 255, 0);
      expectRgb(q3, 6, 6, 0, 0, 255);
      expectRgb(q3, 6, 10, 0, 255, 0);
      expectRgb(q3, 6, 14, 255, 0, 0);

      final q1SecondFrame = await render(1, animationMs: 120);
      expectRgb(q1SecondFrame, 6, 2, 255, 0, 255);
      expectRgb(q1SecondFrame, 6, 6, 0, 255, 255);
      tilesetImage.dispose();
    });

    test('selection and rotation ghost use preview destination bounds',
        () async {
      const map = MapData(
        id: 'rotation-preview',
        name: 'Rotation preview',
        size: GridSize(width: 4, height: 4),
        layers: <MapLayer>[
          TileLayer(
            id: 'decor',
            name: 'Decor',
            tilesetId: 'tiles',
            tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
        placedElements: <MapPlacedElement>[
          MapPlacedElement(
            id: 'selected',
            layerId: 'decor',
            elementId: 'wide',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      const project = ProjectManifest(
        name: 'Rotation preview',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        elements: <ProjectElementEntry>[
          ProjectElementEntry(
            id: 'wide',
            name: 'Wide',
            tilesetId: 'tiles',
            categoryId: 'decor',
            frames: <TilesetVisualFrame>[
              TilesetVisualFrame(
                source: TilesetSourceRect(
                  x: 0,
                  y: 0,
                  width: 3,
                  height: 2,
                ),
              ),
            ],
          ),
        ],
      );
      final preview = planMapPlacedElementRotation(
        map: map,
        project: project,
        instanceId: 'selected',
        targetQuarterTurns: 1,
      );
      expect(preview.canCommit, isTrue);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      MapGridPainter(
        map: map,
        zoom: 1,
        offset: ui.Offset.zero,
        tileWidth: 8,
        tileHeight: 8,
        tilesetImagesById: const <String, ui.Image?>{},
        sourceTileWidth: 8,
        sourceTileHeight: 8,
        tilesPerRowById: const <String, int>{},
        warps: const <MapWarp>[],
        gameplayZones: const <MapGameplayZone>[],
        connectionLabelsByDirection: const <MapConnectionDirection, String>{},
        project: project,
        selectedPlacedElementInstanceId: 'selected',
        placedElementRotationPreview: preview,
        rotationPreviewAcceptedColor: const ui.Color(0xFF00FFFF),
        showGrid: false,
      ).paint(canvas, const ui.Size(32, 32));
      final picture = recorder.endRecording();
      final image = await picture.toImage(32, 32);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;

      int alphaAt(int x, int y) =>
          pixels.getUint8((((y * image.width) + x) * 4) + 3);

      // q1 swaps 3x2 into 2x3. Both selection and ghost include row 3,
      // while the obsolete third column stays untouched.
      expect(alphaAt(4, 20), greaterThan(0));
      expect(alphaAt(20, 20), 0);
      picture.dispose();
      image.dispose();
    });

    test('map with Border keeps static shadow preview below placed elements',
        () async {
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
          BorderLayer(id: 'border-sentinel', name: 'Border sentinel'),
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

    test(
        'map with Border keeps projected building shadow preview below placed elements',
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
          BorderLayer(id: 'border-sentinel', name: 'Border sentinel'),
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
      final shadowStepStart = source.indexOf(
        'case MapVisualCompositionStepKind.shadows:',
      );
      final nextStepStart = source.indexOf(
        'case MapVisualCompositionStepKind.placedElements:',
        shadowStepStart,
      );
      expect(shadowStepStart, isNonNegative);
      expect(nextStepStart, isNonNegative);
      final shadowStepSource = source.substring(shadowStepStart, nextStepStart);
      final projectedPaintIndex = shadowStepSource.indexOf(
        'projectedBuildingShadowPreviewInstructions',
      );
      final staticPaintIndex = shadowStepSource.indexOf(
        'staticShadowPreviewInstructions',
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
      const project = ProjectManifest(
        name: 'editor',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'element-tileset',
            name: 'Element Tileset',
            relativePath: 'tilesets/elements.png',
          ),
        ],
        elements: <ProjectElementEntry>[
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
      const project = ProjectManifest(
        name: 'editor',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'element-tileset',
            name: 'Element Tileset',
            relativePath: 'tilesets/elements.png',
          ),
        ],
        elements: <ProjectElementEntry>[
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
      const project = ProjectManifest(
        name: 'editor',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'element-tileset',
            name: 'Element Tileset',
            relativePath: 'tilesets/elements.png',
          ),
        ],
        elements: <ProjectElementEntry>[
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
  });

  group('EditorCanvasRepaintClock', () {
    test('notifies once per crossed 110 ms bucket and ignores duplicates', () {
      final clock = EditorCanvasRepaintClock();
      var notifications = 0;
      clock.addListener(() => notifications += 1);

      clock.update(const Duration(milliseconds: 109));
      expect((clock.elapsedMs, notifications), (0, 0));

      clock.update(const Duration(milliseconds: 110));
      expect((clock.elapsedMs, notifications), (110, 1));

      clock.update(const Duration(milliseconds: 219));
      expect((clock.elapsedMs, notifications), (110, 1));

      clock.update(const Duration(milliseconds: 220));
      expect((clock.elapsedMs, notifications), (220, 2));

      clock.dispose();
    });

    test('a jump emits once and reset notifies only from a nonzero value', () {
      final clock = EditorCanvasRepaintClock();
      var notifications = 0;
      clock.addListener(() => notifications += 1);

      clock.update(const Duration(milliseconds: 330));
      expect((clock.elapsedMs, notifications), (330, 1));

      clock.reset();
      expect((clock.elapsedMs, notifications), (0, 2));

      clock.reset();
      expect((clock.elapsedMs, notifications), (0, 2));

      clock.dispose();
    });

    test('painter observes paints and prefers the injected clock value', () {
      final clock = EditorCanvasRepaintClock()
        ..update(const Duration(milliseconds: 330));
      var paints = 0;
      final painter = MapGridPainter(
        map: const MapData(
          id: 'clock',
          name: 'Clock',
          size: GridSize(width: 1, height: 1),
        ),
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
        animationClock: clock,
        editorEntityAnimationMs: 110,
        debugOnPaint: () => paints += 1,
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      painter.paint(canvas, const ui.Size(32, 32));

      expect(painter.effectiveAnimationMs, 330);
      expect(paints, 1);
      recorder.endRecording().dispose();
      clock.dispose();
    });

    test('painter without a clock keeps its static animation value', () {
      final painter = MapGridPainter(
        map: const MapData(
          id: 'static-clock',
          name: 'Static clock',
          size: GridSize(width: 1, height: 1),
        ),
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
        editorEntityAnimationMs: 220,
      );

      expect(painter.effectiveAnimationMs, 220);
    });
  });
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

Future<ui.Image> _rectangularAsymmetricTilesetImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFFF0000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(4, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFF00FF00),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(8, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFF0000FF),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(12, 0, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFFFFF00),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 4, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFFF00FF),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(4, 4, 4, 4),
    ui.Paint()..color = const ui.Color(0xFF00FFFF),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(8, 4, 4, 4),
    ui.Paint()..color = const ui.Color(0xFF000000),
  );
  canvas.drawRect(
    const ui.Rect.fromLTWH(12, 4, 4, 4),
    ui.Paint()..color = const ui.Color(0xFFFFFFFF),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(16, 8);
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
