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

    test('flattens groups, applies tile offsets and reports deferred objects',
        () {
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
    <object id="1" gid="1" x="12" y="24"/>
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

      final layer = result.map.layers.single as TileLayer;
      expect(layer.name, 'Village / Ground');
      expect(layer.opacity, 0.5);
      expect(layer.cells, <int>[0, 1, 0]);
      expect(
        result.report.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'map.tiled.group_flattened',
          'map.tiled.object_layer_deferred',
        ]),
      );
      expect(result.report.deferredObjectCount, 2);
      expect(result.report.deferredTileObjectCount, 1);
      expect(result.report.hasVisualLoss, isFalse);
      expect(result.report.fidelity, TiledMapFidelity.deferredContent);
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
