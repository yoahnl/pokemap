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
      expect(document.wangSets, hasLength(2));
      expect(document.wangSets.first.type, TiledWangSetType.corner);
      expect(document.wangSets.first.colors.first.colorArgb, 0xff35a853);
      expect(document.tiles[0]!.probability, 0.25);
      expect(document.tiles[0]!.animation, hasLength(2));
      expect(document.tiles[0]!.animation.last.durationMs, 200);
    });

    test('rejects collection-of-images TSX explicitly', () {
      expect(
        () => parseTiledWangTileset('''
<tileset name="Collection" tilewidth="32" tileheight="32" tilecount="1" columns="0">
  <tile id="0"><image source="tile.png" width="32" height="32"/></tile>
</tileset>
'''),
        throwsA(
          isA<TiledWangImportException>().having(
            (error) => error.code,
            'code',
            'smart_tile.tiled.image_collection_unsupported',
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
