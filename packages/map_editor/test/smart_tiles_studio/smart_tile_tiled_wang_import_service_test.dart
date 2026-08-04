import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_atlas_image_loader.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_source_asset_import_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_tiled_wang_import_service.dart';
import 'package:path/path.dart' as p;

void main() {
  test('loads a TSX preview and resolves its relative atlas image', () async {
    final root = await Directory.systemTemp.createTemp('pokemap_tsx_preview_');
    addTearDown(() async => root.delete(recursive: true));
    final image = File(p.join(root.path, 'images', 'road.png'));
    await image.parent.create(recursive: true);
    await image.writeAsBytes(const <int>[1, 2, 3]);
    final tsx = File(p.join(root.path, 'tsx', 'road.tsx'));
    await tsx.parent.create(recursive: true);
    await tsx.writeAsString(
      _tsx.replaceFirst('road.png', '../images/road.png'),
    );

    final source = await loadSmartTileTiledWangSource(tsx.path);

    expect(source.displayName, 'road.tsx');
    expect(source.document.wangSets.single.name, 'Road');
    expect(source.imagePath, p.normalize(image.path));
    expect(source.importId, startsWith('road-'));
    expect(source.importId, hasLength('road-'.length + 12));
  });

  test('imports the image then applies one canonical Wang action', () async {
    final source = SmartTileTiledWangSource(
      tsxPath: '/outside/road.tsx',
      imagePath: '/outside/road.png',
      displayName: 'road.tsx',
      tsx: _tsx,
      importId: 'road-123456789abc',
      document: parseTiledWangTileset(_tsx),
    );
    final gateway = _Gateway();
    final service = SmartTileTiledWangImportService(
      gateway: gateway,
      importImage: ({
        required String projectRootPath,
        required String sourcePath,
        required String displayName,
      }) async {
        expect(sourcePath, source.imagePath);
        return SmartTileSourceImportResult(
          manifest: gateway.manifest,
          tileset: _tileset,
          image: _image,
          assetId: 'asset',
        );
      },
    );

    final result = await service.import(
      projectRootPath: '/project',
      source: source,
      selections: const <TiledWangSetSelection>[
        TiledWangSetSelection(
          wangSetIndex: 0,
          usage: SmartTileUsage.path,
        ),
      ],
    );

    expect(gateway.actionId, 'smart_tile.tiled_wang.import');
    expect(gateway.parameters?['tsx'], _tsx);
    expect(gateway.parameters?['importId'], source.importId);
    expect(gateway.parameters?['tilesetId'], _tileset.id);
    expect(gateway.parameters?['selections'], <Object?>[
      <String, Object?>{'wangSetIndex': 0, 'usage': 'path'},
    ]);
    expect(gateway.expectedRevision, 'revision-1');
    expect(result.presetIds, <String>['road-123456789abc-w0-preset']);
    expect(result.manifest.smartTileCatalog.presets.single.usage,
        SmartTileUsage.path);
  });

  test('rejects a stale snapshot after canonical Wang apply', () async {
    final source = SmartTileTiledWangSource(
      tsxPath: '/outside/road.tsx',
      imagePath: '/outside/road.png',
      displayName: 'road.tsx',
      tsx: _tsx,
      importId: 'road-123456789abc',
      document: parseTiledWangTileset(_tsx),
    );
    final gateway = _Gateway(staleAfterApply: true);
    final service = SmartTileTiledWangImportService(
      gateway: gateway,
      importImage: ({
        required String projectRootPath,
        required String sourcePath,
        required String displayName,
      }) async =>
          SmartTileSourceImportResult(
        manifest: gateway.manifest,
        tileset: _tileset,
        image: _image,
        assetId: 'asset',
      ),
    );

    expect(
      () => service.import(
        projectRootPath: '/project',
        source: source,
        selections: const <TiledWangSetSelection>[
          TiledWangSetSelection(
            wangSetIndex: 0,
            usage: SmartTileUsage.path,
          ),
        ],
      ),
      throwsA(
        isA<SmartTileTiledWangImportServiceException>().having(
          (error) => error.code,
          'code',
          'smart_tile.tiled_wang.snapshot_stale',
        ),
      ),
    );
  });
}

final class _Gateway implements SmartTileSourceAssetGateway {
  _Gateway({this.staleAfterApply = false});

  final bool staleAfterApply;
  var applied = false;
  String? actionId;
  Map<String, Object?>? parameters;
  String? expectedRevision;
  final ProjectManifest manifest = const ProjectManifest(
    name: 'Project',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[_tileset],
  );

  @override
  Future<String> apply({
    required String projectRootPath,
    required String actionId,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    this.actionId = actionId;
    this.parameters = parameters;
    this.expectedRevision = expectedRevision;
    applied = true;
    return 'revision-2';
  }

  @override
  Future<SmartTileSourceCanonicalSnapshot> load({
    required String projectRootPath,
  }) async {
    if (!applied || staleAfterApply) {
      return SmartTileSourceCanonicalSnapshot(
        revision: 'revision-1',
        manifest: manifest,
      );
    }
    final selections = (parameters!['selections']! as List)
        .cast<Map<String, Object?>>()
        .map(
          (selection) => TiledWangSetSelection(
            wangSetIndex: selection['wangSetIndex']! as int,
            usage: SmartTileUsage.values.byName(selection['usage']! as String),
          ),
        );
    final bundle = compileTiledWangImport(
      document: parseTiledWangTileset(parameters!['tsx']! as String),
      importId: parameters!['importId']! as String,
      tilesetId: parameters!['tilesetId']! as String,
      selections: selections,
    );
    return SmartTileSourceCanonicalSnapshot(
      revision: 'revision-2',
      manifest: manifest.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          atlases: <ProjectSmartTileAtlas>[bundle.atlas],
          materials: bundle.materials,
          animations: bundle.animations,
          presets: bundle.presets,
        ),
      ),
    );
  }

  @override
  Future<ContentArtifactRef> stageExactFile({
    required String projectRootPath,
    required String sourcePath,
  }) =>
      throw UnimplementedError();
}

const _tileset = ProjectTilesetEntry(
  id: 'tileset-road',
  name: 'Road',
  relativePath: 'assets/road.png',
);

final _image = SmartTileAtlasImage(
  absolutePath: '/project/assets/road.png',
  bytes: Uint8List(0),
  width: 1,
  height: 1,
  columnAlphaCoverage: const <double>[1],
  rowAlphaCoverage: const <double>[1],
);

const _tsx = '''
<tileset name="Road" tilewidth="1" tileheight="1" tilecount="1" columns="1">
  <image source="road.png" width="1" height="1"/>
  <wangsets>
    <wangset name="Road" type="edge" tile="-1">
      <wangcolor name="Road" color="#c8a162" tile="0" probability="1"/>
      <wangtile tileid="0" wangid="1,0,1,0,1,0,1,0"/>
    </wangset>
  </wangsets>
</tileset>
''';
