import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapPlacedTile', () {
    test('round-trips fractional visual geometry without gameplay collision',
        () {
      const layer = ObjectLayer(
        id: 'objects',
        name: 'Objects',
        opacity: 0.8,
        tileObjects: <MapPlacedTile>[
          MapPlacedTile(
            id: 'tree',
            name: 'Tree',
            className: 'Decoration',
            tile: TileLayerPaletteEntry(
              tilesetId: 'props',
              localTileId: 5,
              transform: SmartTileSpriteTransform(flipX: true),
            ),
            anchorX: 1.5,
            anchorY: 2.25,
            width: 2,
            height: 1,
            quarterTurns: 1,
            opacity: 0.5,
            importMetadata: <String, Object?>{'sourceObjectId': 42},
          ),
        ],
      );

      final json = layer.toJson();
      final decoded = MapLayer.fromJson(json) as ObjectLayer;
      expect(decoded, layer);
      expect(decoded.tileObjects.single.anchorX, 1.5);
      expect(decoded.tileObjects.single.anchorY, 2.25);
      expect(json, isNot(contains('collisions')));
      expect(
        () => MapValidator.validate(
          const MapData(
            id: 'map',
            name: 'Map',
            version: ProjectVersion.v6,
            size: GridSize(width: 4, height: 4),
            layers: <MapLayer>[layer],
          ),
        ),
        returnsNormally,
      );
    });

    test('validation rejects duplicate IDs and invalid visual geometry', () {
      const invalidObject = MapPlacedTile(
        id: 'duplicate',
        tile: TileLayerPaletteEntry(tilesetId: 'props', localTileId: 0),
        anchorX: 0,
        anchorY: 0,
        width: 0,
        height: 1,
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          ObjectLayer(
            id: 'objects',
            name: 'Objects',
            tileObjects: <MapPlacedTile>[invalidObject, invalidObject],
          ),
        ],
      );

      expect(
        () => MapValidator.validate(map),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resolveMapPlacedTileVisuals', () {
    test('resolves fractional anchors, quarter turns and D4 composition', () {
      const layer = ObjectLayer(
        id: 'objects',
        name: 'Objects',
        opacity: 0.8,
        tileObjects: <MapPlacedTile>[
          MapPlacedTile(
            id: 'tree',
            tile: TileLayerPaletteEntry(
              tilesetId: 'props',
              localTileId: 5,
              transform: SmartTileSpriteTransform(flipX: true),
            ),
            anchorX: 1.5,
            anchorY: 2.25,
            width: 2,
            height: 1,
            quarterTurns: 1,
            opacity: 0.5,
          ),
        ],
      );

      final visuals = resolveMapPlacedTileVisuals(
        layer: layer,
        tilesetsById: const <String, ProjectTilesetSource>{
          'props': ProjectRegularAtlasTilesetSource(
            assetId: 'props-atlas',
            pixelWidth: 64,
            pixelHeight: 64,
            tileWidth: 16,
            tileHeight: 16,
          ),
        },
        sourceCellWidth: 16,
        sourceCellHeight: 16,
        destinationCellWidth: 16,
        destinationCellHeight: 16,
        elapsedMs: 0,
      );

      expect(visuals, hasLength(1));
      final visual = visuals.single;
      expect(visual.objectId, 'tree');
      expect(visual.tilesetId, 'props');
      expect(visual.assetId, 'props-atlas');
      expect(
        visual.sourceRect,
        const ProjectTilesetPixelRect(x: 16, y: 16, width: 16, height: 16),
      );
      expect(
        visual.destinationRect,
        const SmartTileGeometryRect(
          left: 24,
          top: 36,
          width: 16,
          height: 32,
        ),
      );
      expect(
        visual.transform,
        const SmartTileSpriteTransform(quarterTurns: 1, flipX: true),
      );
      expect(visual.opacity, closeTo(0.4, 0.000001));
    });

    test('shares image-collection animation and viewport culling semantics',
        () {
      const layer = ObjectLayer(
        id: 'objects',
        name: 'Objects',
        tileObjects: <MapPlacedTile>[
          MapPlacedTile(
            id: 'animated-prop',
            tile: TileLayerPaletteEntry(
              tilesetId: 'collection',
              localTileId: 10,
            ),
            anchorX: 3,
            anchorY: 4,
            width: 1,
            height: 2,
          ),
        ],
      );

      final hidden = resolveMapPlacedTileVisuals(
        layer: layer,
        tilesetsById: <String, ProjectTilesetSource>{
          'collection': _collection,
        },
        sourceCellWidth: 16,
        sourceCellHeight: 16,
        destinationCellWidth: 16,
        destinationCellHeight: 16,
        elapsedMs: 150,
        viewport: const SmartTileGeometryRect(
          left: 0,
          top: 0,
          width: 16,
          height: 16,
        ),
      );
      expect(hidden, isEmpty);

      final visible = resolveMapPlacedTileVisuals(
        layer: layer,
        tilesetsById: <String, ProjectTilesetSource>{
          'collection': _collection,
        },
        sourceCellWidth: 16,
        sourceCellHeight: 16,
        destinationCellWidth: 16,
        destinationCellHeight: 16,
        elapsedMs: 150,
        viewport: const SmartTileGeometryRect(
          left: 40,
          top: 20,
          width: 40,
          height: 60,
        ),
      );
      expect(visible, hasLength(1));
      expect(visible.single.assetId, 'props-page');
      expect(
        visible.single.sourceRect,
        const ProjectTilesetPixelRect(x: 20, y: 2, width: 16, height: 24),
      );
      expect(
        visible.single.destinationRect,
        const SmartTileGeometryRect(
          left: 50,
          top: 36,
          width: 16,
          height: 32,
        ),
      );
    });

    test('fails closed on invalid geometry and missing tilesets', () {
      const invalid = ObjectLayer(
        id: 'objects',
        name: 'Objects',
        tileObjects: <MapPlacedTile>[
          MapPlacedTile(
            id: 'bad',
            tile: TileLayerPaletteEntry(
              tilesetId: 'missing',
              localTileId: 0,
            ),
            anchorX: 0,
            anchorY: 0,
            width: 0,
            height: 1,
          ),
        ],
      );

      expect(
        () => resolveMapPlacedTileVisuals(
          layer: invalid,
          tilesetsById: const <String, ProjectTilesetSource>{},
          sourceCellWidth: 16,
          sourceCellHeight: 16,
          destinationCellWidth: 16,
          destinationCellHeight: 16,
          elapsedMs: 0,
        ),
        throwsA(
          isA<MapPlacedTileVisualResolutionException>().having(
            (error) => error.code,
            'code',
            'map.placed_tile.geometry_invalid',
          ),
        ),
      );
    });
  });
}

final ProjectImageCollectionTilesetSource _collection =
    ProjectImageCollectionTilesetSource(
  pages: const <ProjectImageCollectionPage>[
    ProjectImageCollectionPage(
      id: 'page',
      assetId: 'props-page',
      pixelWidth: 64,
      pixelHeight: 64,
    ),
  ],
  tileDefinitions: const <ProjectImageCollectionTileDefinition>[
    ProjectImageCollectionTileDefinition(
      tileId: 10,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 1,
        y: 2,
        width: 16,
        height: 24,
      ),
      offsetX: 2,
      offsetY: 3,
      animation: <ProjectImageCollectionAnimationFrame>[
        ProjectImageCollectionAnimationFrame(tileId: 10, durationMs: 100),
        ProjectImageCollectionAnimationFrame(tileId: 11, durationMs: 200),
      ],
    ),
    ProjectImageCollectionTileDefinition(
      tileId: 11,
      pageId: 'page',
      sourceRect: ProjectTilesetPixelRect(
        x: 20,
        y: 2,
        width: 16,
        height: 24,
      ),
      offsetX: 2,
      offsetY: 3,
    ),
  ],
);
