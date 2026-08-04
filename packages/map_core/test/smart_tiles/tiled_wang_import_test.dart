import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseTiledWangTileset', () {
    test('reads one-image TSX Wang metadata without Tiled at runtime', () {
      final document = parseTiledWangTileset(_tsx);

      expect(document.name, 'Synthetic terrain');
      expect(document.imageSource, '../images/terrain.png');
      expect(document.tileWidth, 32);
      expect(document.tileHeight, 32);
      expect(document.columns, 2);
      expect(document.rows, 2);
      expect(document.margin, 1);
      expect(document.spacing, 2);
      expect(document.tileOffsetX, -3);
      expect(document.tileOffsetY, 5);
      expect(document.wangSets, hasLength(2));
      expect(document.wangSets.first.type, TiledWangSetType.corner);
      expect(document.wangSets.first.colors.first.colorArgb, 0xff35a853);
      expect(document.tiles[0]!.probability, 0.25);
      expect(document.tiles[0]!.animation, hasLength(2));
      expect(document.tiles[0]!.animation.last.durationMs, 200);

      final bundle = compileTiledWangImport(
        document: document,
        importId: 'synthetic',
        tilesetId: 'synthetic-tileset',
        selections: const <TiledWangSetSelection>[
          TiledWangSetSelection(
            wangSetIndex: 0,
            usage: SmartTileUsage.terrain,
          ),
        ],
      );
      expect(bundle.atlas.sourceRectFor(column: 1, row: 1).toJson(),
          <String, Object?>{'x': 35, 'y': 35, 'width': 32, 'height': 32});
      expect((bundle.atlas.pixelOffsetX, bundle.atlas.pixelOffsetY), (-3, 5));
    });

    test('reads sparse collection-of-images dependencies without I/O', () {
      final document = parseTiledTileset(_imageCollectionTsx);

      expect(document.name, 'Synthetic props');
      expect(document.layout, isA<TiledImageCollectionLayout>());
      expect(document.tileWidth, 96);
      expect(document.tileHeight, 128);
      expect(document.tileCount, 2);
      expect(document.tileOffsetX, -8);
      expect(document.tileOffsetY, 4);
      expect(document.tiles.keys, <int>[2, 9]);
      expect(document.tiles[2]!.image!.pixelWidth, 32);
      expect(document.tiles[9]!.image!.pixelHeight, 128);
      expect(document.tiles[9]!.animation, hasLength(2));
      expect(document.properties, hasLength(2));
      expect(
        document.properties.last.type,
        TiledPropertyValueType.structured,
      );
      expect(document.properties.last.members.single.value, 0.75);
      expect(document.tiles[2]!.properties.single.value, false);
      expect(document.tiles[2]!.collisionObjects, hasLength(1));
      expect(
        document.tiles[2]!.collisionObjects.single.shape,
        TiledCollisionShape.rectangle,
      );
      expect(
        document.tiles[2]!.collisionObjects.single.properties.single.value,
        'trunk',
      );
      expect(
        document.dependencyClosure.images.map((image) => image.source),
        <String>['images/small.png', 'images/tree.png'],
      );
      expect(document.dependencyClosure.images.first.tileIds, <int>[2]);
      expect(document.wangSets, isEmpty);
    });

    test('keeps the Wang-only compiler regular-atlas specific', () {
      expect(
        () => parseTiledWangTileset(_imageCollectionTsx),
        throwsA(
          isA<TiledWangImportException>().having(
            (error) => error.code,
            'code',
            'smart_tile.tiled.image_collection_unsupported',
          ),
        ),
      );
    });

    test('diagnoses missing, duplicate and invalid collection images', () {
      final cases = <(String, String)>[
        (
          _imageCollectionTsx.replaceFirst(
            '<image source="./images/small.png" width="32" height="48"/>',
            '',
          ),
          'smart_tile.tiled.tile_image_required',
        ),
        (
          _imageCollectionTsx.replaceFirst(
            '<image source="./images/small.png" width="32" height="48"/>',
            '<image source="./images/small.png" width="32" height="48"/>'
                '<image source="other.png" width="32" height="48"/>',
          ),
          'smart_tile.tiled.tile_image_duplicate',
        ),
        (
          _imageCollectionTsx.replaceFirst('width="32"', 'width="0"'),
          'smart_tile.tiled.image_dimensions_invalid',
        ),
        (
          _imageCollectionTsx.replaceFirst('width="32" ', ''),
          'smart_tile.tiled.image_dimensions_invalid',
        ),
        (
          _imageCollectionTsx.replaceFirst(
            './images/small.png',
            'file:/outside/small.png',
          ),
          'smart_tile.tiled.image_reference_invalid',
        ),
        (
          _imageCollectionTsx.replaceFirst('id="9"', 'id="2"'),
          'smart_tile.tiled.tile_duplicate',
        ),
        (
          _imageCollectionTsx.replaceFirst('tileid="2"', 'tileid="8"'),
          'smart_tile.tiled.image_reference_invalid',
        ),
      ];

      for (final (tsx, code) in cases) {
        expect(
          () => parseTiledTileset(tsx),
          throwsA(
            isA<TiledWangImportException>().having(
              (error) => error.code,
              'code',
              code,
            ),
          ),
          reason: code,
        );
      }
    });

    test('deduplicates normalized image dependencies and detects conflicts',
        () {
      final shared = _imageCollectionTsx
          .replaceFirst('images/tree.png', 'folder/../images/small.png')
          .replaceFirst('width="96" height="128"', 'width="32" height="48"');
      final document = parseTiledTileset(shared);

      expect(document.dependencyClosure.images, hasLength(1));
      expect(
        document.dependencyClosure.images.single.tileIds,
        <int>[2, 9],
      );
      expect(
        () => parseTiledTileset(
          shared.replaceFirst(
            'folder/../images/small.png" width="32"',
            'folder/../images/small.png" width="64"',
          ),
        ),
        throwsA(
          isA<TiledWangImportException>().having(
            (error) => error.code,
            'code',
            'smart_tile.tiled.image_dimensions_conflict',
          ),
        ),
      );
    });

    test('rejects malformed Wang ids instead of importing partial rules', () {
      expect(
        () => parseTiledWangTileset(
          _tsx.replaceFirst(
            '0,1,0,1,0,1,0,1',
            '0,1,0',
          ),
        ),
        throwsA(
          isA<TiledWangImportException>().having(
            (error) => error.code,
            'code',
            'smart_tile.tiled.wang_id_invalid',
          ),
        ),
      );
    });
  });

  group('compileTiledWangImport', () {
    test('compiles selected Wang sets to validated native draft presets', () {
      final document = parseTiledWangTileset(_tsx);
      final bundle = compileTiledWangImport(
        document: document,
        importId: 'synthetic-terrain',
        tilesetId: 'tileset-terrain',
        selections: const <TiledWangSetSelection>[
          TiledWangSetSelection(
            wangSetIndex: 0,
            usage: SmartTileUsage.terrain,
          ),
          TiledWangSetSelection(
            wangSetIndex: 1,
            usage: SmartTileUsage.path,
          ),
        ],
      );

      expect(bundle.atlas.id, 'synthetic-terrain-atlas');
      expect(bundle.atlas.tilesetId, 'tileset-terrain');
      expect(bundle.atlas.columns, 2);
      expect(bundle.atlas.rows, 2);
      expect(bundle.materials, hasLength(3));
      expect(bundle.animations, hasLength(1));
      expect(bundle.presets, hasLength(2));

      final corner = bundle.presets.first;
      expect(corner.usage, SmartTileUsage.terrain);
      expect(corner.topology, SmartTileTopology.wangCorner4);
      expect(corner.templateHint, SmartTileTemplateHint.corner16);
      expect(corner.status, SmartTilePresetStatus.draft);
      expect(corner.coveragePolicy, SmartTileCoveragePolicy.sparse);
      expect(corner.rules, hasLength(1));
      expect(corner.rules.single.candidates, hasLength(2));
      expect(
        corner.rules.single.candidates.map((candidate) => candidate.weight),
        <int>[250, 750],
      );
      expect(
        corner.rules.single.candidates.first.parts.single.source,
        isA<SmartTileAnimationSource>(),
      );
      expect(
        corner.rules.single.signature.northWestCorner.materialId,
        'synthetic-terrain-w0-material-1',
      );
      expect(
        corner.rules.single.signature.northEdge.kind,
        SmartTileMatchKind.any,
      );

      final edge = bundle.presets.last;
      expect(edge.topology, SmartTileTopology.wangEdge4);
      expect(edge.templateHint, SmartTileTemplateHint.edge16);
      expect(edge.rules.single.signature.northEdge.materialId,
          'synthetic-terrain-w1-material-1');
      expect(edge.rules.single.signature.northWestCorner.kind,
          SmartTileMatchKind.any);

      final diagnostics = validateProjectSmartTileCatalog(
        catalog: ProjectSmartTileCatalog(
          atlases: <ProjectSmartTileAtlas>[bundle.atlas],
          materials: bundle.materials,
          animations: bundle.animations,
          presets: bundle.presets,
        ),
        projectTilesetIds: const <String>['tileset-terrain'],
      );
      expect(
        diagnostics.where((diagnostic) => diagnostic.isError),
        isEmpty,
      );
    });

    test('requires an explicit usage for every selected Wang set', () {
      final document = parseTiledWangTileset(_tsx);
      expect(
        () => compileTiledWangImport(
          document: document,
          importId: 'synthetic-terrain',
          tilesetId: 'tileset-terrain',
          selections: const <TiledWangSetSelection>[],
        ),
        throwsA(
          isA<TiledWangImportException>().having(
            (error) => error.code,
            'code',
            'smart_tile.tiled.selection_required',
          ),
        ),
      );
    });
  });
}

const _tsx = '''
<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.9" tiledversion="1.9.2" name="Synthetic terrain"
    tilewidth="32" tileheight="32" tilecount="4" columns="2"
    margin="1" spacing="2">
  <image source="../images/terrain.png" width="68" height="68"/>
  <tileoffset x="-3" y="5"/>
  <tile id="0" probability="0.25">
    <animation>
      <frame tileid="2" duration="100"/>
      <frame tileid="3" duration="200"/>
    </animation>
  </tile>
  <tile id="1" probability="0.75"/>
  <wangsets>
    <wangset name="Grass and dirt" type="corner" tile="-1">
      <wangcolor name="Grass" color="#ff35a853" tile="0" probability="1"/>
      <wangcolor name="Dirt" color="#ff9a6738" tile="1" probability="1"/>
      <wangtile tileid="0" wangid="0,1,0,1,0,1,0,1"/>
      <wangtile tileid="1" wangid="0,1,0,1,0,1,0,1"/>
    </wangset>
    <wangset name="Road" type="edge" tile="-1">
      <wangcolor name="Road" color="#c8a162" tile="2" probability="1"/>
      <wangtile tileid="2" wangid="1,0,1,0,1,0,1,0"/>
    </wangset>
  </wangsets>
</tileset>
''';

const _imageCollectionTsx = '''
<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.2" name="Synthetic props"
    tilewidth="96" tileheight="128" tilecount="2" columns="0">
  <properties>
    <property name="category" value="props"/>
    <property name="settings" type="class" propertytype="Vegetation">
      <properties>
        <property name="density" type="float" value="0.75"/>
      </properties>
    </property>
  </properties>
  <tileoffset x="-8" y="4"/>
  <tile id="2">
    <image source="./images/small.png" width="32" height="48"/>
    <properties>
      <property name="passable" type="bool" value="false"/>
    </properties>
    <objectgroup>
      <object id="1" class="collision" x="4" y="24" width="24" height="16">
        <properties>
          <property name="kind" value="trunk"/>
        </properties>
      </object>
    </objectgroup>
  </tile>
  <tile id="9">
    <image source="images/tree.png" width="96" height="128"/>
    <animation>
      <frame tileid="2" duration="120"/>
      <frame tileid="9" duration="80"/>
    </animation>
  </tile>
</tileset>
''';
