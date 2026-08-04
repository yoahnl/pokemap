import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/assets/tiled_tileset_import_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'projects asset, regular tileset and Wang resources in one change set',
    () {
      final imageBytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
        'A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final artifact = ContentArtifactRef.fromBytes(
        imageBytes,
        mediaType: 'image/png',
      );
      final asset = AssetRecord(
        id: 'road-image',
        logicalPath: 'assets/road.png',
        artifact: artifact,
      );
      const tileset = ProjectTilesetEntry(
        id: 'road',
        name: 'Road',
        relativePath: 'assets/road.png',
        source: ProjectRegularAtlasTilesetSource(
          assetId: 'road-image',
          pixelWidth: 1,
          pixelHeight: 1,
          tileWidth: 1,
          tileHeight: 1,
        ),
      );
      final wangBundle = compileTiledWangImport(
        document: parseTiledWangTileset(_tsx),
        importId: 'road',
        tilesetId: tileset.id,
        selections: const <TiledWangSetSelection>[
          TiledWangSetSelection(
            wangSetIndex: 0,
            usage: SmartTileUsage.path,
          ),
        ],
      );
      final manifest = ProjectManifest(
        name: 'Composite import fixture',
        version: ProjectVersion.v6,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
      );
      final projectBytes = _encode(manifest.toJson());
      final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('project_tiled_projection'),
        revision: _fingerprint('snapshot', utf8.encode('snapshot')),
        manifest: manifest,
        maps: const <MapData>[],
        resourceFingerprints: <String, String>{
          'project': _fingerprint('project.json', projectBytes),
        },
        resourceBytes: <String, List<int>>{'project': projectBytes},
        resourceStorageKeys: const <String, String>{
          'project': 'project.json',
        },
      );

      final draft = const TiledTilesetImportProjector().project(
        snapshot: snapshot,
        asset: asset,
        imageBytes: imageBytes,
        tileset: tileset,
        wangBundle: wangBundle,
        importId: 'road',
      );

      expect(
        draft.changeSet.changes.map((change) => change.storageKey).toSet(),
        <String>{
          assetCatalogStorageKey,
          assetBlobStorageKey(artifact),
          'project.json',
        },
      );
      expect(
        draft.changeSet.changes
            .where((change) => change.resource.kind == 'project'),
        hasLength(1),
      );

      final projectedCatalog = AssetCatalog.fromJson(
        _decode(
          draft.changeSet.changes
              .singleWhere(
                (change) => change.storageKey == assetCatalogStorageKey,
              )
              .afterBytes!,
        ),
      );
      expect(projectedCatalog.require(asset.id).toJson(), asset.toJson());

      final projectedManifest = ProjectManifest.fromJson(
        _decode(
          draft.changeSet.changes
              .singleWhere((change) => change.resource.kind == 'project')
              .afterBytes!,
        ),
      );
      expect(projectedManifest.tilesets.single, tileset);
      expect(
        projectedManifest.smartTileCatalog.atlases.map((atlas) => atlas.id),
        contains('road-atlas'),
      );
      expect(
        projectedManifest.smartTileCatalog.presets.map((preset) => preset.id),
        contains('road-w0-preset'),
      );
      expect(draft.preview['operation'], 'tileset.tiled.import');
      expect(draft.preview['changeCount'], 3);
    },
  );
}

String _fingerprint(String logicalName, List<int> bytes) =>
    computeAuthoringBytesFingerprint(bytes, logicalName: logicalName);

List<int> _encode(Map<String, Object?> json) => utf8.encode(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );

Map<String, dynamic> _decode(List<int> bytes) =>
    Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);

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
