import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('compileTiledMapDocument', () {
    test('compiles literal layers, multi-tileset palettes and all D4 flags',
        () {
      final flags = <int>[
        0,
        0x80000000,
        0x40000000,
        0xc0000000,
        0x20000000,
        0xa0000000,
        0x60000000,
        0xe0000000,
      ];
      final document = parseTiledMap(
        _mapXml(
          width: 4,
          height: 2,
          tilesets: const <({int firstGid, String source})>[
            (firstGid: 1, source: 'terrain.tsx'),
            (firstGid: 100, source: 'props.tsx'),
          ],
          layers: <String>[
            _csvLayer(
              id: 1,
              name: 'Ground',
              width: 4,
              height: 2,
              gids: flags.map((flag) => flag | 1).toList(),
            ),
            _csvLayer(
              id: 2,
              name: 'Details',
              width: 4,
              height: 2,
              gids: const <int>[100, 0, 100, 0, 0, 100, 0, 100],
            ),
          ],
        ),
      );

      final result = compileTiledMapDocument(
        document,
        mapId: 'imported-map',
        mapName: 'Imported map',
        gridPolicy: const TiledMapGridPolicy.adoptSource(),
        tilesets: const <TiledMapTilesetBinding>[
          TiledMapTilesetBinding(
            source: 'terrain.tsx',
            tilesetId: 'terrain',
          ),
          TiledMapTilesetBinding(
            source: 'props.tsx',
            tilesetId: 'props',
          ),
        ],
      );

      expect(result.map.size, const GridSize(width: 4, height: 2));
      expect(result.map.visualStack, MapVisualStackConfig.canonicalV1);
      expect(
        result.map.layers.map((layer) => layer.id),
        <String>['tiled-layer-2', 'tiled-layer-1'],
        reason: 'PokeMap canonical layers are top-to-bottom.',
      );
      expect(
        buildMapVisualCompositionPlan(result.map)
            .plan!
            .visibleTileLayersInPaintOrder
            .map((layer) => layer.id),
        <String>['tiled-layer-1', 'tiled-layer-2'],
        reason: 'The shared renderer must recover Tiled bottom-to-top order.',
      );
      final ground = result.map.layers.last as TileLayer;
      expect(
        ground.palette.map((entry) => entry.tilesetId).toSet(),
        <String>{'terrain'},
      );
      expect(
        ground.palette.map((entry) => entry.transform),
        const <SmartTileSpriteTransform>[
          SmartTileSpriteTransform(),
          SmartTileSpriteTransform(flipX: true),
          SmartTileSpriteTransform(quarterTurns: 2, flipX: true),
          SmartTileSpriteTransform(quarterTurns: 2),
          SmartTileSpriteTransform(quarterTurns: 3, flipX: true),
          SmartTileSpriteTransform(quarterTurns: 1),
          SmartTileSpriteTransform(quarterTurns: 3),
          SmartTileSpriteTransform(quarterTurns: 1, flipX: true),
        ],
      );
      expect(ground.cells, <int>[1, 2, 3, 4, 5, 6, 7, 8]);
      expect(result.report.tileLayerCount, 2);
      expect(result.report.sourceTilesetCount, 2);
      expect(result.report.referencedTilesetIds, <String>['terrain', 'props']);
      expect(result.report.fidelity, TiledMapFidelity.exactLiteralTiles);
      expect(result.report.gridDecision.adoptedSourceGrid, isTrue);
      expect(result.report.gridDecision.tileWidth, 32);
      expect(result.report.gridDecision.tileHeight, 32);
      expect(
        result.map.properties[tiledMapImportMetadataKey],
        isA<Map<String, Object?>>(),
      );
      MapValidator.validate(result.map);
      expect(MapData.fromJson(result.map.toJson()), result.map);
    });

    test('requires an explicit compatible target grid', () {
      final document = parseTiledMap(
        _mapXml(
          width: 1,
          height: 1,
          tilesets: const <({int firstGid, String source})>[
            (firstGid: 1, source: 'terrain.tsx'),
          ],
          layers: <String>[
            _csvLayer(
              id: 1,
              name: 'Ground',
              width: 1,
              height: 1,
              gids: const <int>[1],
            ),
          ],
        ),
      );

      expect(
        () => compileTiledMapDocument(
          document,
          mapId: 'map',
          mapName: 'Map',
          gridPolicy: const TiledMapGridPolicy.requireExact(
            tileWidth: 16,
            tileHeight: 16,
          ),
          tilesets: const <TiledMapTilesetBinding>[
            TiledMapTilesetBinding(
              source: 'terrain.tsx',
              tilesetId: 'terrain',
            ),
          ],
        ),
        throwsA(
          isA<TiledMapCompilationException>().having(
            (error) => error.code,
            'code',
            'map.tiled.grid_mismatch',
          ),
        ),
      );

      final compatible = compileTiledMapDocument(
        document,
        mapId: 'map',
        mapName: 'Map',
        gridPolicy: const TiledMapGridPolicy.requireExact(
          tileWidth: 32,
          tileHeight: 32,
        ),
        tilesets: const <TiledMapTilesetBinding>[
          TiledMapTilesetBinding(
            source: 'terrain.tsx',
            tilesetId: 'terrain',
          ),
        ],
      );
      expect(compatible.report.gridDecision.adoptedSourceGrid, isFalse);
    });

    test('rejects incomplete, extra and ambiguous tileset bindings', () {
      final document = parseTiledMap(
        _mapXml(
          width: 1,
          height: 1,
          tilesets: const <({int firstGid, String source})>[
            (firstGid: 1, source: 'terrain.tsx'),
          ],
          layers: <String>[
            _csvLayer(
              id: 1,
              name: 'Ground',
              width: 1,
              height: 1,
              gids: const <int>[1],
            ),
          ],
        ),
      );

      void expectCode(
        List<TiledMapTilesetBinding> bindings,
        String code,
      ) {
        expect(
          () => compileTiledMapDocument(
            document,
            mapId: 'map',
            mapName: 'Map',
            gridPolicy: const TiledMapGridPolicy.adoptSource(),
            tilesets: bindings,
          ),
          throwsA(
            isA<TiledMapCompilationException>().having(
              (error) => error.code,
              'code',
              code,
            ),
          ),
        );
      }

      expectCode(const <TiledMapTilesetBinding>[], 'map.tiled.binding_missing');
      expectCode(
        const <TiledMapTilesetBinding>[
          TiledMapTilesetBinding(source: 'terrain.tsx', tilesetId: 'terrain'),
          TiledMapTilesetBinding(source: 'extra.tsx', tilesetId: 'extra'),
        ],
        'map.tiled.binding_extra',
      );
      expectCode(
        const <TiledMapTilesetBinding>[
          TiledMapTilesetBinding(source: 'terrain.tsx', tilesetId: 'terrain'),
          TiledMapTilesetBinding(source: 'terrain.tsx', tilesetId: 'other'),
        ],
        'map.tiled.binding_duplicate_source',
      );
    });

    test('flattens groups, compiles tile objects and defers only shapes', () {
      final document = parseTiledMap(
        _mapXml(
          width: 3,
          height: 1,
          tilesets: const <({int firstGid, String source})>[
            (firstGid: 1, source: 'terrain.tsx'),
          ],
          layers: <String>[
            '''
<group id="1" name="Village" x="1" opacity="0.5">
  <layer id="2" name="Ground" width="3" height="1">
    <data encoding="csv">1,0,0</data>
  </layer>
  <objectgroup id="3" name="Props">
    <object id="1" name="Bench" class="Decoration" gid="1"
        x="12" y="24" width="24" height="16" rotation="90"
        opacity="0.75">
      <properties><property name="note" value="visual only"/></properties>
    </object>
    <object id="2" x="4" y="8" width="10" height="12"/>
  </objectgroup>
</group>
''',
          ],
        ),
      );

      final result = compileTiledMapDocument(
        document,
        mapId: 'grouped',
        mapName: 'Grouped',
        gridPolicy: const TiledMapGridPolicy.adoptSource(),
        tilesets: const <TiledMapTilesetBinding>[
          TiledMapTilesetBinding(
            source: 'terrain.tsx',
            tilesetId: 'terrain',
          ),
        ],
      );

      expect(
        result.map.layers.map((layer) => layer.id),
        <String>['tiled-layer-3', 'tiled-layer-2'],
      );
      final tileLayer = result.map.layers.last as TileLayer;
      expect(tileLayer.name, 'Village / Ground');
      expect(tileLayer.opacity, 0.5);
      expect(tileLayer.cells, <int>[0, 1, 0]);
      final objectLayer = result.map.layers.first as ObjectLayer;
      expect(objectLayer.name, 'Village / Props');
      expect(objectLayer.opacity, 0.5);
      final object = objectLayer.tileObjects.single;
      expect(object.id, 'tiled-object-1');
      expect(object.name, 'Bench');
      expect(object.className, 'Decoration');
      expect(object.tile.tilesetId, 'terrain');
      expect(object.tile.localTileId, 0);
      expect(object.anchorX, 1.375);
      expect(object.anchorY, 0.75);
      expect(object.width, 0.75);
      expect(object.height, 0.5);
      expect(object.quarterTurns, 1);
      expect(object.opacity, 0.75);
      expect(object.importMetadata['sourceObjectId'], 1);
      expect(object.importMetadata['properties'], isA<List<Object?>>());
      expect(object.toJson(), isNot(contains('collisions')));
      final importMetadata =
          result.map.properties[tiledMapImportMetadataKey]! as Map;
      final sourceLayers = importMetadata['layers']! as List;
      final objectLayerMetadata = sourceLayers.cast<Map>().firstWhere(
            (metadata) => metadata['sourceLayerId'] == 3,
          );
      expect(objectLayerMetadata['drawOrder'], 'topdown');
      expect(objectLayerMetadata['deferredObjects'], hasLength(1));
      expect(
        (objectLayerMetadata['deferredObjects']! as List).single,
        containsPair('sourceObjectId', 2),
      );
      expect(
        result.report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'map.tiled.group_flattened',
          'map.tiled.tile_objects_compiled',
          'map.tiled.object_shapes_deferred',
        ]),
      );
      expect(result.report.compiledTileObjectCount, 1);
      expect(result.report.deferredObjectCount, 1);
      expect(result.report.deferredTileObjectCount, 0);
      expect(result.report.hasVisualLoss, isFalse);
      expect(result.report.fidelity, TiledMapFidelity.deferredContent);
    });

    test('preserves object draw order and defers arbitrary rotations', () {
      final document = parseTiledMap(
        _mapXml(
          width: 1,
          height: 1,
          tilesets: const <({int firstGid, String source})>[
            (firstGid: 1, source: 'terrain.tsx'),
          ],
          layers: const <String>[
            '''
<objectgroup id="1" name="Index" draworder="index">
  <object id="1" gid="1" x="0" y="20" width="32" height="32"/>
  <object id="2" gid="1" x="0" y="10" width="32" height="32"/>
</objectgroup>
<objectgroup id="2" name="Top down" draworder="topdown">
  <object id="3" gid="1" x="0" y="20" width="32" height="32"/>
  <object id="4" gid="1" x="0" y="10" width="32" height="32"/>
  <object id="5" gid="1" x="0" y="0" width="32" height="32" rotation="45"/>
  <object id="6" gid="1" x="0" y="0"/>
</objectgroup>
''',
          ],
        ),
      );

      final result = compileTiledMapDocument(
        document,
        mapId: 'object-order',
        mapName: 'Object order',
        gridPolicy: const TiledMapGridPolicy.adoptSource(),
        tilesets: const <TiledMapTilesetBinding>[
          TiledMapTilesetBinding(
            source: 'terrain.tsx',
            tilesetId: 'terrain',
          ),
        ],
      );

      final topDown = result.map.layers.first as ObjectLayer;
      final index = result.map.layers.last as ObjectLayer;
      expect(
        index.tileObjects.map((object) => object.id),
        <String>['tiled-object-1', 'tiled-object-2'],
      );
      expect(
        topDown.tileObjects.map((object) => object.id),
        <String>['tiled-object-4', 'tiled-object-3'],
      );
      expect(index.tileObjects.first.width, 1);
      expect(index.tileObjects.first.height, 1);
      expect(result.report.compiledTileObjectCount, 4);
      expect(result.report.deferredObjectCount, 2);
      expect(result.report.deferredTileObjectCount, 2);
      expect(
        result.report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'map.tiled.tile_object_rotation_deferred',
          'map.tiled.tile_object_size_deferred',
        ]),
      );
    });

    test('marks clipped shifted tiles as visual loss', () {
      final document = parseTiledMap(
        _mapXml(
          width: 2,
          height: 1,
          tilesets: const <({int firstGid, String source})>[
            (firstGid: 1, source: 'terrain.tsx'),
          ],
          layers: const <String>[
            '''
<group id="1" name="Shifted" x="1">
  <layer id="2" name="Ground" width="2" height="1">
    <data encoding="csv">0,1</data>
  </layer>
</group>
''',
          ],
        ),
      );

      final result = compileTiledMapDocument(
        document,
        mapId: 'clipped',
        mapName: 'Clipped',
        gridPolicy: const TiledMapGridPolicy.adoptSource(),
        tilesets: const <TiledMapTilesetBinding>[
          TiledMapTilesetBinding(
            source: 'terrain.tsx',
            tilesetId: 'terrain',
          ),
        ],
      );

      expect(result.report.hasVisualLoss, isTrue);
      expect(result.report.fidelity, TiledMapFidelity.lossy);
      expect(
        result.report.diagnostics.map((diagnostic) => diagnostic.code),
        contains('map.tiled.tile_clipped'),
      );
    });

    test('preserves typed map and layer properties in an inert namespace', () {
      final document = parseTiledMap(
        _mapXml(
          width: 1,
          height: 1,
          tilesets: const <({int firstGid, String source})>[
            (firstGid: 1, source: 'terrain.tsx'),
          ],
          mapProperties: '''
<properties>
  <property name="weather" value="rain"/>
  <property name="difficulty" type="int" value="3"/>
  <property name="rules" type="class" propertytype="Rules">
    <properties><property name="enabled" type="bool" value="true"/></properties>
  </property>
</properties>
''',
          layers: <String>[
            '''
<layer id="1" name="Ground" width="1" height="1" tintcolor="#80ffffff">
  <properties><property name="note" value="visual only"/></properties>
  <data encoding="csv">268435457</data>
</layer>
''',
          ],
        ),
      );

      final result = compileTiledMapDocument(
        document,
        mapId: 'metadata',
        mapName: 'Metadata',
        gridPolicy: const TiledMapGridPolicy.adoptSource(),
        tilesets: const <TiledMapTilesetBinding>[
          TiledMapTilesetBinding(
            source: 'terrain.tsx',
            tilesetId: 'terrain',
          ),
        ],
      );

      final metadata = result.map.properties[tiledMapImportMetadataKey]!
          as Map<String, Object?>;
      final properties = metadata['properties']! as List<Object?>;
      expect(
        properties,
        contains(
          allOf(
            isA<Map<String, Object?>>(),
            containsPair('name', 'difficulty'),
            containsPair('type', 'integer'),
            containsPair('value', 3),
          ),
        ),
      );
      expect(
        result.report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'map.tiled.layer_effect_metadata_only',
          'map.tiled.hexagonal_flag_ignored',
        ]),
      );
      expect(result.report.fidelity, TiledMapFidelity.metadataPreserved);
      expect(
        (result.map.layers.single as TileLayer).palette.single.transform,
        const SmartTileSpriteTransform(),
      );
    });

    test('classifies, hides and ignores source layers explicitly', () {
      final document = parseTiledMap(
        _mapXml(
          width: 1,
          height: 1,
          tilesets: const <({int firstGid, String source})>[
            (firstGid: 1, source: 'terrain.tsx'),
          ],
          layers: <String>[
            _csvLayer(id: 1, name: 'Ground', width: 1, height: 1, gids: [1]),
            _csvLayer(id: 2, name: 'Metadata', width: 1, height: 1, gids: [1]),
            _csvLayer(id: 3, name: 'Draft', width: 1, height: 1, gids: [1]),
            _csvLayer(id: 4, name: 'Discarded', width: 1, height: 1, gids: [1]),
          ],
        ),
      );

      final result = compileTiledMapDocument(
        document,
        mapId: 'classified',
        mapName: 'Classified',
        gridPolicy: const TiledMapGridPolicy.adoptSource(),
        tilesets: const <TiledMapTilesetBinding>[
          TiledMapTilesetBinding(
            source: 'terrain.tsx',
            tilesetId: 'terrain',
          ),
        ],
        layerModes: const <int, TiledMapLayerImportMode>{
          2: TiledMapLayerImportMode.data,
          3: TiledMapLayerImportMode.hidden,
          4: TiledMapLayerImportMode.ignore,
        },
      );

      expect(
        result.map.layers.map((layer) => layer.name),
        <String>['Draft', 'Metadata', 'Ground'],
      );
      final metadata = result.map.layers[1] as TileLayer;
      expect(metadata.purpose, MapLayerPurpose.data);
      expect(metadata.isVisible, isFalse);
      expect((result.map.layers.first as TileLayer).isVisible, isFalse);
      expect(result.report.dataLayerCount, 1);
      expect(result.report.hiddenLayerCount, 1);
      expect(result.report.ignoredLayerCount, 1);

      final inspectable = result.map.copyWith(
        layers: <MapLayer>[
          for (final layer in result.map.layers)
            if (layer.id == metadata.id)
              metadata.copyWith(isVisible: true)
            else
              layer,
        ],
      );
      expect(
        buildMapVisualCompositionPlan(inspectable)
            .plan!
            .steps
            .where((step) => step.layer?.id == metadata.id),
        isEmpty,
      );
      expect(
        buildMapVisualCompositionPlan(
          inspectable,
          includeDataLayers: true,
        ).plan!.steps.where((step) => step.layer?.id == metadata.id),
        isNotEmpty,
      );
    });
  });
}

String _mapXml({
  required int width,
  required int height,
  required List<({int firstGid, String source})> tilesets,
  required List<String> layers,
  String mapProperties = '',
}) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal"
    renderorder="right-down" width="$width" height="$height"
    tilewidth="32" tileheight="32" infinite="0">
  $mapProperties
  ${tilesets.map((entry) => '<tileset firstgid="${entry.firstGid}" source="${entry.source}"/>').join()}
  ${layers.join()}
</map>
'''
        .trim();

String _csvLayer({
  required int id,
  required String name,
  required int width,
  required int height,
  required List<int> gids,
}) =>
    '''
<layer id="$id" name="$name" width="$width" height="$height">
  <data encoding="csv">${gids.join(',')}</data>
</layer>
''';
