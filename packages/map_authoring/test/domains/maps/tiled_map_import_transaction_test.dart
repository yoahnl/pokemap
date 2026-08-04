import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('map.tiled.import', () {
    test('plans and applies map, tilesets and assets in one receipt', () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);

      final actions = (setup.mutations.describeMutations()['actions']! as List)
          .cast<Map<String, Object?>>();
      expect(
        actions.map((action) => action['id']),
        contains('map.tiled.import'),
      );

      final planned = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(),
      );
      final plan = Map<String, Object?>.from(planned['plan']! as Map);
      final preview = Map<String, Object?>.from(plan['preview']! as Map);
      final changeSet = Map<String, Object?>.from(plan['changeSet']! as Map);
      expect(preview['operation'], 'map.tiled.import');
      expect(preview['mapId'], 'imported-road');
      expect(preview['tilesetCount'], 1);
      expect(preview['assetCount'], 1);
      expect(preview['tileLayerCount'], 1);
      expect(changeSet['changes'], hasLength(4));

      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-map-tiled-import',
      );
      final receipt = AuthoringReceipt.fromJson(
        Map<String, dynamic>.from(applied['receipt']! as Map),
      );
      expect(receipt.actionId, 'map.tiled.import');
      expect(
        receipt.diff.entries.map((entry) => entry.resource.kind).toSet(),
        containsAll(<String>['assetCatalog', 'assetBlob', 'project', 'map']),
      );

      await setup.expectComplete();
    });

    test('recovers a partial promotion without orphaned resources', () async {
      var crashed = false;
      final setup = await _TiledMapImportSetup.create(
        faultInjector: (context) {
          if (!crashed &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted &&
              context.promotionIndex == 1) {
            crashed = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      addTearDown(setup.dispose);
      final planned = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(idempotencyKey: 'recover-map-tiled-import'),
      );

      await expectLater(
        () => setup.mutations.apply(
          setup.projectHandle,
          planId: planned['planId']! as String,
          operationId: 'operation-recover-map-tiled-import',
        ),
        throwsA(isA<AuthoringTransactionSimulatedCrash>()),
      );

      final recovered = await setup.mutations.recover(
        setup.projectHandle,
        operationId: 'operation-recover-map-tiled-import',
      );
      expect(
        Map<String, Object?>.from(recovered['receipt']! as Map)['status'],
        'recovered',
      );
      await setup.expectComplete();
    });

    test('packs a sparse TSX image collection inside the same transaction',
        () async {
      final setup = await _TiledMapImportSetup.create(imageCollection: true);
      addTearDown(setup.dispose);
      final planned = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(idempotencyKey: 'image-collection-map-import'),
      );

      await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-image-collection-map-import',
      );

      await setup.expectComplete();
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      expect(
        snapshot.manifest.tilesets.single.source,
        isA<ProjectImageCollectionTilesetSource>(),
      );
      final layer =
          snapshot.mapById('imported-road')!.layers.single as TileLayer;
      expect(layer.palette.single.localTileId, 5);
    });

    test('deduplicates one image artifact shared by multiple TSX files',
        () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);

      final planned = await setup.mutations.plan(
        setup.projectHandle,
        await setup.sharedArtifactRequest(),
      );

      final receipt = AuthoringReceipt.fromJson(
        Map<String, dynamic>.from(planned['receipt']! as Map),
      );
      expect(receipt.artifacts, hasLength(1));
      expect(receipt.artifacts.single.id, setup.artifact.digest);
    });
  });
}

final class _TiledMapImportSetup {
  const _TiledMapImportSetup._({
    required this.root,
    required this.mutations,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.snapshots,
    required this.artifact,
    required this.imageCollection,
  });

  static Future<_TiledMapImportSetup> create({
    AuthoringTransactionFaultInjector? faultInjector,
    bool imageCollection = false,
  }) async {
    final root = await Directory.systemTemp.createTemp('tiled-map-import-');
    final manifest = ProjectManifest(
      name: 'Tiled map import fixture',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
    );
    await File('${root.path}/project.json').writeAsBytes(
      _encode(manifest.toJson()),
      flush: true,
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      tokenFactory: (prefix) => '${prefix}tiled-map-import',
    );
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final artifacts = MemoryArtifactStore(maximumArtifactBytes: 1024);
    final stored = await artifacts.put(
      _pngBytes,
      declaredMediaType: 'image/png',
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
      artifactStore: artifacts,
      tiledImageCollectionRasterCodec: const _OnePixelRasterCodec(),
      faultInjector: faultInjector,
      clock: () => DateTime.utc(2026, 8, 4, 14),
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _TiledMapImportSetup._(
      root: root,
      mutations: mutations,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
      snapshots: snapshots,
      artifact: stored.reference,
      imageCollection: imageCollection,
    );
  }

  final Directory root;
  final LocalMapAuthoringMutationApi mutations;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader snapshots;
  final ContentArtifactRef artifact;
  final bool imageCollection;

  Future<AuthoringRequest> request({
    String idempotencyKey = 'map-tiled-import',
  }) async {
    final snapshot = await snapshots.load(projectHandle);
    return AuthoringRequest(
      requestId: 'request-$idempotencyKey',
      actionId: 'map.tiled.import',
      actionVersion: 1,
      workspaceHandle: workspaceHandle.value,
      expectedRevision: snapshot.revision,
      idempotencyKey: idempotencyKey,
      parameters: <String, Object?>{
        'mapId': 'imported-road',
        'displayName': 'Imported road',
        'role': 'exterior',
        'tmx': imageCollection ? _imageCollectionTmx : _tmx,
        'tilesets': <Object?>[
          <String, Object?>{
            'source': 'road.tsx',
            'tsx': imageCollection ? _imageCollectionTsx : _tsx,
            'tilesetId': 'road',
            'assetId': 'road-image',
            'logicalPath': 'assets/tilesets/road.png',
            'imageArtifacts': <Object?>[
              <String, Object?>{
                'source': imageCollection ? 'road-sparse.png' : 'road.png',
                'artifactHandle': artifact.handle,
              },
            ],
          },
        ],
      },
    );
  }

  Future<AuthoringRequest> sharedArtifactRequest() async {
    final snapshot = await snapshots.load(projectHandle);
    Map<String, Object?> tileset(String source, String suffix) =>
        <String, Object?>{
          'source': source,
          'tsx': _tsx,
          'tilesetId': 'road-$suffix',
          'assetId': 'road-image-$suffix',
          'logicalPath': 'assets/tilesets/road-$suffix.png',
          'imageArtifacts': <Object?>[
            <String, Object?>{
              'source': 'road.png',
              'artifactHandle': artifact.handle,
            },
          ],
        };
    return AuthoringRequest(
      requestId: 'request-shared-map-artifact',
      actionId: 'map.tiled.import',
      actionVersion: 1,
      workspaceHandle: workspaceHandle.value,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'shared-map-artifact',
      parameters: <String, Object?>{
        'mapId': 'shared-road',
        'displayName': 'Shared road',
        'role': 'exterior',
        'tmx': _sharedArtifactTmx,
        'tilesets': <Object?>[
          tileset('road-a.tsx', 'a'),
          tileset('road-b.tsx', 'b'),
        ],
      },
    );
  }

  Future<void> expectComplete() async {
    final snapshot = await snapshots.load(projectHandle);
    expect(snapshot.manifest.maps.single.id, 'imported-road');
    expect(snapshot.manifest.tilesets.single.id, 'road');
    final map = snapshot.mapById('imported-road')!;
    expect(map.layers, hasLength(1));
    final layer = map.layers.single as TileLayer;
    expect(layer.palette.single.tilesetId, 'road');
    expect(layer.palette.single.localTileId, imageCollection ? 5 : 0);
    expect(layer.cells, <int>[1]);

    final catalog = AssetCatalog.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          utf8.decode(snapshot.resourceBytes(assetCatalogResourceIdentity)),
        ) as Map,
      ),
    );
    if (imageCollection) {
      final packedAsset = catalog.records.single;
      expect(packedAsset.id, startsWith('road-image-'));
      expect(packedAsset.logicalPath, endsWith('.png'));
      expect(
        snapshot.findResourceBytes(
          assetBlobResourceIdentity(packedAsset.artifact.digest),
        ),
        isNotNull,
      );
    } else {
      expect(
        catalog.require('road-image').logicalPath,
        'assets/tilesets/road.png',
      );
      expect(
        snapshot.findResourceBytes(assetBlobResourceIdentity(artifact.digest)),
        _pngBytes,
      );
    }
  }

  Future<void> dispose() => root.delete(recursive: true);
}

final class _OnePixelRasterCodec implements TiledImageCollectionRasterCodec {
  const _OnePixelRasterCodec();

  @override
  TiledImageCollectionRasterMetadata inspect(List<int> encodedBytes) =>
      TiledImageCollectionRasterMetadata(
        pixelWidth: _pngDimension(encodedBytes, 16),
        pixelHeight: _pngDimension(encodedBytes, 20),
      );

  @override
  TiledImageCollectionRgbaImage decode(List<int> encodedBytes) =>
      TiledImageCollectionRgbaImage(
        pixelWidth: 1,
        pixelHeight: 1,
        rgbaBytes: <int>[12, 34, 56, 255],
      );

  @override
  List<int> encodePng(TiledImageCollectionRgbaImage image) =>
      _fakePng(image.pixelWidth, image.pixelHeight);
}

int _pngDimension(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];

List<int> _fakePng(int width, int height) {
  final bytes = List<int>.from(_pngBytes);
  for (var index = 0; index < 4; index += 1) {
    final shift = (3 - index) * 8;
    bytes[16 + index] = (width >> shift) & 0xff;
    bytes[20 + index] = (height >> shift) & 0xff;
  }
  return bytes;
}

List<int> _encode(Map<String, Object?> json) => utf8.encode(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );

final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
  'A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

const _tsx = '''
<tileset name="Road" tilewidth="1" tileheight="1" tilecount="1" columns="1">
  <image source="road.png" width="1" height="1"/>
</tileset>
''';

const _tmx = '''
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal"
  renderorder="right-down" width="1" height="1" tilewidth="1" tileheight="1"
  infinite="0" nextlayerid="2" nextobjectid="1">
  <tileset firstgid="1" source="road.tsx"/>
  <layer id="1" name="Ground" width="1" height="1">
    <data encoding="csv">1</data>
  </layer>
</map>
''';

const _imageCollectionTsx = '''
<tileset name="Sparse road" tilewidth="1" tileheight="1" tilecount="1" columns="0">
  <tile id="5">
    <image source="road-sparse.png" width="1" height="1"/>
  </tile>
</tileset>
''';

const _imageCollectionTmx = '''
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal"
  renderorder="right-down" width="1" height="1" tilewidth="1" tileheight="1"
  infinite="0" nextlayerid="2" nextobjectid="1">
  <tileset firstgid="1" source="road.tsx"/>
  <layer id="1" name="Ground" width="1" height="1">
    <data encoding="csv">6</data>
  </layer>
</map>
''';

const _sharedArtifactTmx = '''
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal"
  renderorder="right-down" width="2" height="1" tilewidth="1" tileheight="1"
  infinite="0" nextlayerid="2" nextobjectid="1">
  <tileset firstgid="1" source="road-a.tsx"/>
  <tileset firstgid="2" source="road-b.tsx"/>
  <layer id="1" name="Ground" width="2" height="1">
    <data encoding="csv">1,2</data>
  </layer>
</map>
''';
