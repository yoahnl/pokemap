import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseTiledMap', () {
    test('parses one finite orthogonal map and preserves dependencies', () {
      final document = parseTiledMap(_tmx(data: _csvData));

      expect(document.version, '1.10');
      expect(document.tiledVersion, '1.11.0');
      expect(document.orientation, TiledMapOrientation.orthogonal);
      expect(document.renderOrder, TiledMapRenderOrder.rightDown);
      expect((document.width, document.height), (2, 2));
      expect((document.tileWidth, document.tileHeight), (32, 32));
      expect(document.className, 'Overworld');
      expect(document.backgroundColor, '#80402010');
      expect(
        document.dependencyClosure.tilesets.map((entry) => entry.source),
        <String>['../tiles/base.tsx', 'props.tsx'],
      );
      expect(document.properties, hasLength(8));
      expect(document.properties[1].value, 3);
      expect(document.properties[2].value, 1.5);
      expect(document.properties[3].value, isTrue);
      expect(document.properties[5].value, 'music/theme.ogg');
      expect(document.properties[7].members.single.value, 0.75);

      final tileLayer = document.layers.whereType<TiledMapTileLayer>().single;
      expect(tileLayer.id, 1);
      expect(tileLayer.name, 'Ground');
      expect(tileLayer.className, 'Literal');
      expect(tileLayer.visible, isFalse);
      expect(tileLayer.opacity, 0.5);
      expect((tileLayer.offsetX, tileLayer.offsetY), (4.0, -2.0));
      expect((tileLayer.parallaxX, tileLayer.parallaxY), (0.75, 1.25));
      expect(tileLayer.tintColor, '#80ffffff');
      expect(tileLayer.blendMode, TiledMapBlendMode.multiply);
      expect(tileLayer.cells, hasLength(4));
      expect(tileLayer.cells[1], isNull);

      final transformed = tileLayer.cells[2]!;
      expect(transformed.rawGid, 0xe0000002);
      expect(transformed.globalTileId, 2);
      expect(transformed.localTileId, 1);
      expect(transformed.tileset.source, '../tiles/base.tsx');
      expect(transformed.flipHorizontally, isTrue);
      expect(transformed.flipVertically, isTrue);
      expect(transformed.flipDiagonally, isTrue);
      expect(transformed.hexagonal120Flag, isFalse);

      final propsTile = tileLayer.cells[3]!;
      expect(propsTile.globalTileId, 101);
      expect(propsTile.localTileId, 1);
      expect(propsTile.tileset.source, 'props.tsx');

      final objectLayer =
          document.layers.whereType<TiledMapObjectLayer>().single;
      expect(objectLayer.id, 2);
      expect(objectLayer.drawOrder, TiledMapObjectDrawOrder.indexOrder);
      expect(objectLayer.objects, hasLength(3));
      final tileObject = objectLayer.objects.first;
      expect(tileObject.id, 7);
      expect(tileObject.shape, TiledMapObjectShape.tile);
      expect(tileObject.tile!.localTileId, 0);
      expect(tileObject.tile!.flipHorizontally, isTrue);
      expect(tileObject.properties.single.value, 'spawn');
      expect(
        objectLayer.objects[1].shape,
        TiledMapObjectShape.ellipse,
      );
      expect(
        objectLayer.objects[2].points,
        const <TiledPoint>[
          TiledPoint(x: 0, y: 0),
          TiledPoint(x: 8, y: 0),
          TiledPoint(x: 8, y: 8),
        ],
      );
    });

    test('decodes XML, CSV and base64 layer representations identically', () {
      final variants = <String>[
        _tmx(data: _xmlData, encoding: null),
        _tmx(data: _csvData),
        _tmx(data: _rawBase64, encoding: 'base64'),
        _tmx(data: _gzipBase64, encoding: 'base64', compression: 'gzip'),
        _tmx(data: _zlibBase64, encoding: 'base64', compression: 'zlib'),
      ];

      for (final source in variants) {
        final cells = parseTiledMap(source)
            .layers
            .whereType<TiledMapTileLayer>()
            .single
            .cells;
        expect(
          cells.map((cell) => cell?.rawGid ?? 0),
          <int>[1, 0, 0xe0000002, 101],
        );
      }
    });

    test('exposes and clears all four high GID flags', () {
      final document = parseTiledMap(
        _tmx(data: '4026531841,0,0,0'),
      );
      final tile =
          document.layers.whereType<TiledMapTileLayer>().single.cells[0]!;

      expect(tile.rawGid, 0xf0000001);
      expect(tile.globalTileId, 1);
      expect(tile.localTileId, 0);
      expect(tile.flipHorizontally, isTrue);
      expect(tile.flipVertically, isTrue);
      expect(tile.flipDiagonally, isTrue);
      expect(tile.hexagonal120Flag, isTrue);
    });

    test('rejects unsupported map structures with stable diagnostics', () {
      final cases = <(String, String)>[
        ('<tileset/>', 'map.tiled.root_invalid'),
        (
          _tmx(data: _csvData).replaceFirst(
            'orientation="orthogonal"',
            'orientation="isometric"',
          ),
          'map.tiled.orientation_unsupported',
        ),
        (
          _tmx(data: _csvData).replaceFirst('infinite="0"', 'infinite="1"'),
          'map.tiled.infinite_unsupported',
        ),
        (
          _tmx(data: _csvData).replaceFirst(
            '<tileset firstgid="1" source="../tiles/base.tsx"/>',
            '<tileset firstgid="1" name="Inline" tilewidth="32" '
                'tileheight="32"/>',
          ),
          'map.tiled.inline_tileset_unsupported',
        ),
        (
          _tmx(data: _csvData).replaceFirst(
            '../tiles/base.tsx',
            ':/automap-tiles.tsx',
          ),
          'map.tiled.internal_dependency_unsupported',
        ),
        (
          _tmx(data: _csvData).replaceFirst(
            '<objectgroup',
            '<imagelayer id="9" name="Backdrop"><image source="x.png"/>'
                '</imagelayer><objectgroup',
          ),
          'map.tiled.image_layer_unsupported',
        ),
        (
          _tmx(data: _csvData).replaceFirst(
            '<object id="7"',
            '<object id="7" template="actor.tx"',
          ),
          'map.tiled.object_template_unsupported',
        ),
      ];

      for (final (source, code) in cases) {
        _expectTiledMapCode(source, code);
      }
    });

    test('preserves nested group hierarchy and empty group markers', () {
      final source = _tmx(data: _csvData)
          .replaceFirst(
            '<layer id="1"',
            '<group id="3" name="Elevation" opacity="0.75">'
                '<layer id="1"',
          )
          .replaceFirst(
            '</layer>\n  <objectgroup',
            '</layer></group>\n  <objectgroup',
          )
          .replaceFirst(
            '</objectgroup>\n</map>',
            '</objectgroup><group id="4" name="Empty"/>\n</map>',
          );

      final document = parseTiledMap(source);
      final group = document.layers.first as TiledMapGroupLayer;

      expect(group.name, 'Elevation');
      expect(group.opacity, 0.75);
      expect(group.layers.single, isA<TiledMapTileLayer>());
      expect((document.layers.last as TiledMapGroupLayer).layers, isEmpty);
    });

    test('rejects malformed layer encodings and compressed payloads', () {
      final cases = <(String, String)>[
        (
          _tmx(data: '1,nope,2,3'),
          'map.tiled.gid_invalid',
        ),
        (
          _tmx(data: '1,2,3'),
          'map.tiled.layer_data_size_invalid',
        ),
        (
          _tmx(data: '4294967296,0,0,0'),
          'map.tiled.gid_invalid',
        ),
        (
          _tmx(data: '2147483648,0,0,0'),
          'map.tiled.gid_empty_flags_invalid',
        ),
        (
          _tmx(data: _rawBase64, encoding: 'base64', compression: 'zstd'),
          'map.tiled.compression_unsupported',
        ),
        (
          _tmx(data: _csvData, encoding: 'csv', compression: 'gzip'),
          'map.tiled.compression_invalid',
        ),
        (
          _tmx(data: 'not base64', encoding: 'base64'),
          'map.tiled.layer_data_invalid',
        ),
        (
          _tmx(data: _rawBase64, encoding: 'base64', compression: 'gzip'),
          'map.tiled.layer_data_invalid',
        ),
        (
          _tmx(
            data: _gzipBase64,
            encoding: 'base64',
            compression: 'gzip',
          ).replaceAll('width="2" height="2"', 'width="1" height="1"'),
          'map.tiled.layer_data_size_invalid',
        ),
      ];

      for (final (source, code) in cases) {
        _expectTiledMapCode(source, code);
      }
    });

    test('rejects ambiguous IDs, dimensions and properties', () {
      final base = _tmx(data: _csvData);
      final cases = <(String, String)>[
        (
          base.replaceFirst('firstgid="1"', 'firstgid="2"'),
          'map.tiled.tileset_first_gid_invalid',
        ),
        (
          base.replaceFirst('firstgid="100"', 'firstgid="1"'),
          'map.tiled.tileset_first_gid_invalid',
        ),
        (
          base.replaceFirst(
            '<objectgroup id="2"',
            '<objectgroup id="1"',
          ),
          'map.tiled.layer_id_duplicate',
        ),
        (
          base.replaceFirst('<object id="8"', '<object id="7"'),
          'map.tiled.object_id_duplicate',
        ),
        (
          base.replaceFirst(
            '<layer id="1" name="Ground" class="Literal" width="2"',
            '<layer id="1" name="Ground" class="Literal" width="3"',
          ),
          'map.tiled.layer_dimensions_invalid',
        ),
        (
          base.replaceFirst('name="difficulty"', 'name="weather"'),
          'map.tiled.property_duplicate',
        ),
        (
          base.replaceFirst('type="int" value="3"', 'type="int" value="x"'),
          'map.tiled.property_value_invalid',
        ),
      ];

      for (final (source, code) in cases) {
        _expectTiledMapCode(source, code);
      }
    });

    test('enforces source, XML, map and decoded-layer budgets', () {
      expect(
        () => parseTiledMap(
          _tmx(data: _csvData),
          limits: const TiledMapParserLimits(maxSourceCharacters: 32),
        ),
        throwsA(
          isA<TiledMapImportException>().having(
            (error) => error.code,
            'code',
            'map.tiled.source_limit_exceeded',
          ),
        ),
      );
      expect(
        () => parseTiledMap(
          _tmx(data: _csvData),
          limits: const TiledMapParserLimits(maxXmlNodes: 8),
        ),
        throwsA(
          isA<TiledMapImportException>().having(
            (error) => error.code,
            'code',
            'map.tiled.xml_limit_exceeded',
          ),
        ),
      );
      expect(
        () => parseTiledMap(
          _tmx(data: _csvData),
          limits: const TiledMapParserLimits(maxMapCells: 3),
        ),
        throwsA(
          isA<TiledMapImportException>().having(
            (error) => error.code,
            'code',
            'map.tiled.map_size_limit_exceeded',
          ),
        ),
      );
      expect(
        () => parseTiledMap(
          _tmx(data: _gzipBase64, encoding: 'base64', compression: 'gzip'),
          limits: const TiledMapParserLimits(maxLayerDataBytes: 8),
        ),
        throwsA(
          isA<TiledMapImportException>().having(
            (error) => error.code,
            'code',
            'map.tiled.layer_data_limit_exceeded',
          ),
        ),
      );
      expect(
        () => parseTiledMap(
          _tmx(data: _csvData),
          limits: const TiledMapParserLimits(maxTotalLayerCells: 3),
        ),
        throwsA(
          isA<TiledMapImportException>().having(
            (error) => error.code,
            'code',
            'map.tiled.total_layer_data_limit_exceeded',
          ),
        ),
      );
    });

    test('enforces cumulative layer, object, property and point budgets', () {
      final base = _tmx(data: _csvData);
      final nestedGroups = base
          .replaceFirst(
            '<layer id="1"',
            '<group id="3" name="Outer"><group id="4" name="Inner">'
                '<layer id="1"',
          )
          .replaceFirst(
            '</layer>\n  <objectgroup',
            '</layer></group></group>\n  <objectgroup',
          );
      final cases = <({
        String source,
        TiledMapParserLimits limits,
        String code,
      })>[
        (
          source: base,
          limits: const TiledMapParserLimits(maxTilesets: 1),
          code: 'map.tiled.tileset_limit_exceeded',
        ),
        (
          source: base,
          limits: const TiledMapParserLimits(maxLayers: 1),
          code: 'map.tiled.layer_limit_exceeded',
        ),
        (
          source: base,
          limits: const TiledMapParserLimits(maxObjects: 2),
          code: 'map.tiled.object_limit_exceeded',
        ),
        (
          source: base,
          limits: const TiledMapParserLimits(maxProperties: 1),
          code: 'map.tiled.property_limit_exceeded',
        ),
        (
          source: base,
          limits: const TiledMapParserLimits(maxPropertyDepth: 1),
          code: 'map.tiled.property_depth_limit_exceeded',
        ),
        (
          source: base,
          limits: const TiledMapParserLimits(maxPoints: 2),
          code: 'map.tiled.point_limit_exceeded',
        ),
        (
          source: nestedGroups,
          limits: const TiledMapParserLimits(maxGroupDepth: 1),
          code: 'map.tiled.group_depth_limit_exceeded',
        ),
      ];

      for (final entry in cases) {
        expect(
          () => parseTiledMap(entry.source, limits: entry.limits),
          throwsA(
            isA<TiledMapImportException>().having(
              (error) => error.code,
              'code',
              entry.code,
            ),
          ),
          reason: entry.code,
        );
      }
    });

    test('normalizes deterministic malformed XML mutations fail-closed', () {
      final source = _tmx(data: _csvData);
      final mutations = <String>[
        for (var cut = 1; cut < source.length; cut += 131)
          source.substring(0, cut),
        for (var offset = 0; offset < source.length; offset += 173)
          source.replaceRange(offset, offset + 1, '\u0000'),
      ];
      var rejected = 0;
      for (final mutation in mutations) {
        try {
          parseTiledMap(mutation);
          expect(mutation, isNot(contains('\u0000')));
          expect(mutation.trimRight(), endsWith('</map>'));
        } on TiledMapImportException {
          rejected += 1;
        } on Object catch (error, stackTrace) {
          fail('Non-normalized parser failure: $error\n$stackTrace');
        }
      }

      expect(rejected, greaterThanOrEqualTo(mutations.length - 1));
    });

    test('rejects document type declarations before XML expansion', () {
      _expectTiledMapCode(
        '<!DOCTYPE map [<!ENTITY x "boom">]>'
            '${_tmx(data: _csvData)}',
        'map.tiled.doctype_unsupported',
      );
    });
  });
}

void _expectTiledMapCode(String source, String code) {
  expect(
    () => parseTiledMap(source),
    throwsA(
      isA<TiledMapImportException>().having(
        (error) => error.code,
        'code',
        code,
      ),
    ),
    reason: code,
  );
}

String _tmx({
  required String data,
  String? encoding = 'csv',
  String? compression,
}) {
  final dataAttributes = <String>[
    if (encoding != null) 'encoding="$encoding"',
    if (compression != null) 'compression="$compression"',
  ].join(' ');
  final dataElement = encoding == null
      ? '<data>$data</data>'
      : '<data $dataAttributes>$data</data>';
  return '''
<map version="1.10" tiledversion="1.11.0" class="Overworld"
    orientation="orthogonal" renderorder="right-down" width="2" height="2"
    tilewidth="32" tileheight="32" infinite="0"
    backgroundcolor="#80402010" nextlayerid="3" nextobjectid="10">
  <properties>
    <property name="weather" value="rain"/>
    <property name="difficulty" type="int" value="3"/>
    <property name="ratio" type="float" value="1.5"/>
    <property name="enabled" type="bool" value="true"/>
    <property name="tint" type="color" value="#80ffffff"/>
    <property name="music" type="file" value="assets/../music/theme.ogg"/>
    <property name="focus" type="object" value="7"/>
    <property name="settings" type="class" propertytype="MapSettings">
      <properties>
        <property name="density" type="float" value="0.75"/>
      </properties>
    </property>
  </properties>
  <tileset firstgid="1" source="../tiles/base.tsx"/>
  <tileset firstgid="100" source="folder/../props.tsx"/>
  <layer id="1" name="Ground" class="Literal" width="2" height="2"
      opacity="0.5" visible="0" tintcolor="#80ffffff" offsetx="4"
      offsety="-2" parallaxx="0.75" parallaxy="1.25" mode="multiply">
    <properties><property name="kind" value="ground"/></properties>
    $dataElement
  </layer>
  <objectgroup id="2" name="Objects" draworder="index">
    <object id="7" name="Hero" class="Actor" gid="2147483649"
        x="16" y="32" width="32" height="32" rotation="90">
      <properties><property name="role" value="spawn"/></properties>
    </object>
    <object id="8" name="Pond" x="2" y="3" width="8" height="6">
      <ellipse/>
    </object>
    <object id="9" name="Fence" x="0" y="0">
      <polygon points="0,0 8,0 8,8"/>
    </object>
  </objectgroup>
</map>
''';
}

const _csvData = '1,0,3758096386,101';
const _xmlData = '<tile gid="1"/><tile gid="0"/>'
    '<tile gid="3758096386"/><tile gid="101"/>';
const _rawBase64 = 'AQAAAAAAAAACAADgZQAAAA==';
const _gzipBase64 = 'H4sIAAAAAAAC/2NkgAAmBoYHqUAaAFcd2iQQAAAA';
const _zlibBase64 = 'eJxjZIAAJgaGB6lAGgAGJAFJ';
