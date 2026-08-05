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

    test('applies explicit no-code layer modes transactionally', () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);

      final planned = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(
          idempotencyKey: 'map-tiled-layer-mode',
          layerModes: const <String, String>{'1': 'data'},
        ),
      );
      final preview = Map<String, Object?>.from(
        Map<String, Object?>.from(planned['plan']! as Map)['preview']! as Map,
      );
      expect(preview['dataLayerCount'], 1);
      expect(preview['hiddenLayerCount'], 0);
      expect(preview['ignoredLayerCount'], 0);

      await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-map-tiled-layer-mode',
      );
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      final layer =
          snapshot.mapById('imported-road')!.layers.single as TileLayer;
      expect(layer.purpose, MapLayerPurpose.data);
      expect(layer.isVisible, isFalse);
    });

    test('plans and applies from a staged TMX artifact handle', () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);

      final planned = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(
          idempotencyKey: 'map-tiled-staged-tmx',
          stageTmx: true,
          includeInlineTmx: false,
        ),
      );
      expect(jsonEncode(planned), isNot(contains('<map')));

      await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-map-tiled-staged-tmx',
      );
      await setup.expectComplete();
    });

    test('rejects missing or ambiguous TMX source parameters', () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);

      for (final request in <AuthoringRequest>[
        await setup.request(
          idempotencyKey: 'map-tiled-missing-tmx',
          includeInlineTmx: false,
        ),
        await setup.request(
          idempotencyKey: 'map-tiled-ambiguous-tmx',
          stageTmx: true,
        ),
      ]) {
        await expectLater(
          () => setup.mutations.plan(setup.projectHandle, request),
          throwsA(
            isA<MapAuthoringException>().having(
              (error) => error.code,
              'code',
              'map.tiled.source_invalid',
            ),
          ),
        );
      }
    });

    test('propagates the TSX atlas transparent color to the project tileset',
        () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);
      final planned = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(idempotencyKey: 'map-tiled-transparent-color'),
      );

      await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-map-tiled-transparent-color',
      );

      final snapshot = await setup.snapshots.load(setup.projectHandle);
      expect(
        snapshot.manifest.tilesets.single.transparentColor?.toHexRgb(),
        'f05ba1',
      );
    });

    test('reuses one canonical tileset when another map imports the same TSX',
        () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);

      final first = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(idempotencyKey: 'map-tiled-reuse-first'),
      );
      await setup.mutations.apply(
        setup.projectHandle,
        planId: first['planId']! as String,
        operationId: 'operation-map-tiled-reuse-first',
      );

      final second = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(
          idempotencyKey: 'map-tiled-reuse-second',
          mapId: 'imported-road-2',
          tilesetId: 'road-2',
          assetId: 'road-image-2',
          logicalPath: 'assets/tilesets/road-2.png',
        ),
      );
      final secondPlan = Map<String, Object?>.from(second['plan']! as Map);
      final preview = Map<String, Object?>.from(secondPlan['preview']! as Map);
      expect(preview['tilesetCount'], 0);
      expect(preview['assetCount'], 0);
      final impact = Map<String, Object?>.from(
        secondPlan['referenceImpact']! as Map,
      );
      expect(impact['tilesetIds'], <String>['road']);
      expect(impact['assetIds'], <String>['road-image']);

      await setup.mutations.apply(
        setup.projectHandle,
        planId: second['planId']! as String,
        operationId: 'operation-map-tiled-reuse-second',
      );

      final snapshot = await setup.snapshots.load(setup.projectHandle);
      expect(snapshot.manifest.maps, hasLength(2));
      expect(snapshot.manifest.tilesets, hasLength(1));
      final secondMap = snapshot.mapById('imported-road-2')!;
      final secondLayer = secondMap.layers.single as TileLayer;
      expect(secondLayer.palette.single.tilesetId, 'road');
      final catalog = AssetCatalog.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            utf8.decode(
              snapshot.resourceBytes(assetCatalogResourceIdentity),
            ),
          ) as Map,
        ),
      );
      expect(catalog.records, hasLength(1));
    });

    test('reuses one packed image collection across sequential map imports',
        () async {
      final setup = await _TiledMapImportSetup.create(imageCollection: true);
      addTearDown(setup.dispose);

      final first = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(idempotencyKey: 'collection-reuse-first'),
      );
      await setup.mutations.apply(
        setup.projectHandle,
        planId: first['planId']! as String,
        operationId: 'operation-collection-reuse-first',
      );

      final second = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(
          idempotencyKey: 'collection-reuse-second',
          mapId: 'imported-road-2',
          tilesetId: 'road-2',
          assetId: 'road-image-2',
          logicalPath: 'assets/tilesets/road-2',
        ),
      );
      final secondPlan = Map<String, Object?>.from(second['plan']! as Map);
      final preview = Map<String, Object?>.from(secondPlan['preview']! as Map);
      expect(preview['tilesetCount'], 0);
      expect(preview['assetCount'], 0);

      await setup.mutations.apply(
        setup.projectHandle,
        planId: second['planId']! as String,
        operationId: 'operation-collection-reuse-second',
      );

      final snapshot = await setup.snapshots.load(setup.projectHandle);
      expect(snapshot.manifest.tilesets, hasLength(1));
      final secondMap = snapshot.mapById('imported-road-2')!;
      final secondLayer = secondMap.layers.single as TileLayer;
      expect(secondLayer.palette.single.tilesetId, 'road');
      final catalog = AssetCatalog.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(
            utf8.decode(
              snapshot.resourceBytes(assetCatalogResourceIdentity),
            ),
          ) as Map,
        ),
      );
      expect(catalog.records, hasLength(1));
    });

    test('reuses an imported tileset after presentation metadata changes',
        () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);

      final first = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(idempotencyKey: 'metadata-reuse-first'),
      );
      await setup.mutations.apply(
        setup.projectHandle,
        planId: first['planId']! as String,
        operationId: 'operation-metadata-reuse-first',
      );

      final afterFirst = await setup.snapshots.load(setup.projectHandle);
      final organized = afterFirst.manifest.tilesets.single.copyWith(
        name: 'My organized road',
        sortOrder: 42,
      );
      final organizePlan = await setup.mutations.plan(
        setup.projectHandle,
        AuthoringRequest(
          requestId: 'request-organize-road',
          actionId: 'tileset.upsert',
          actionVersion: 1,
          workspaceHandle: setup.workspaceHandle.value,
          expectedRevision: afterFirst.revision,
          idempotencyKey: 'organize-road',
          parameters: <String, Object?>{'tileset': organized.toJson()},
        ),
      );
      await setup.mutations.apply(
        setup.projectHandle,
        planId: organizePlan['planId']! as String,
        operationId: 'operation-organize-road',
      );

      final second = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(
          idempotencyKey: 'metadata-reuse-second',
          mapId: 'imported-road-2',
          tilesetId: 'road-2',
          assetId: 'road-image-2',
          logicalPath: 'assets/tilesets/road-2.png',
        ),
      );
      final secondPlan = Map<String, Object?>.from(second['plan']! as Map);
      final preview = Map<String, Object?>.from(secondPlan['preview']! as Map);
      expect(preview['tilesetCount'], 0);
      expect(preview['assetCount'], 0);

      await setup.mutations.apply(
        setup.projectHandle,
        planId: second['planId']! as String,
        operationId: 'operation-metadata-reuse-second',
      );
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      expect(snapshot.manifest.tilesets, hasLength(1));
      expect(snapshot.manifest.tilesets.single.name, 'My organized road');
      expect(snapshot.manifest.tilesets.single.sortOrder, 42);
      final secondMap = snapshot.mapById('imported-road-2')!;
      expect(
        (secondMap.layers.single as TileLayer).palette.single.tilesetId,
        'road',
      );
    });

    test('reuses a canonical tileset imported standalone from the same TSX',
        () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);
      final before = await setup.snapshots.load(setup.projectHandle);
      final standalone = await setup.mutations.plan(
        setup.projectHandle,
        AuthoringRequest(
          requestId: 'request-standalone-road',
          actionId: 'tileset.tiled.import',
          actionVersion: 1,
          workspaceHandle: setup.workspaceHandle.value,
          expectedRevision: before.revision,
          idempotencyKey: 'standalone-road',
          parameters: <String, Object?>{
            'artifactHandle': setup.artifact.handle,
            'assetId': 'road-image',
            'logicalPath': 'assets/tilesets/road.png',
            'tilesetId': 'road',
            'displayName': 'Road',
            'importId': 'road',
            'tsx': _wangTsx,
            'selections': const <Object?>[
              <String, Object?>{'wangSetIndex': 0, 'usage': 'terrain'},
            ],
            'tags': const <String>['tiled'],
            'usages': const <String>['smart-tiles-studio'],
          },
        ),
      );
      await setup.mutations.apply(
        setup.projectHandle,
        planId: standalone['planId']! as String,
        operationId: 'operation-standalone-road',
      );

      final mapImport = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(
          idempotencyKey: 'standalone-road-map',
          tilesetId: 'road-2',
          assetId: 'road-image-2',
          logicalPath: 'assets/tilesets/road-2.png',
        ),
      );
      final mapPlan = Map<String, Object?>.from(mapImport['plan']! as Map);
      final preview = Map<String, Object?>.from(mapPlan['preview']! as Map);
      expect(preview['tilesetCount'], 0);
      expect(preview['assetCount'], 0);

      await setup.mutations.apply(
        setup.projectHandle,
        planId: mapImport['planId']! as String,
        operationId: 'operation-standalone-road-map',
      );
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      expect(snapshot.manifest.tilesets, hasLength(1));
      final map = snapshot.mapById('imported-road')!;
      expect((map.layers.single as TileLayer).palette.single.tilesetId, 'road');
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

    test('deduplicates equivalent animated TSX files in one transaction',
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
      final preview = Map<String, Object?>.from(
        Map<String, Object?>.from(planned['plan']! as Map)['preview']! as Map,
      );
      expect(preview['tilesetCount'], 1);
      expect(preview['assetCount'], 1);

      await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-shared-map-artifact',
      );
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      expect(snapshot.manifest.tilesets, hasLength(1));
      final layer = snapshot.mapById('shared-road')!.layers.single as TileLayer;
      expect(layer.palette, hasLength(1));
      expect(layer.cells, const <int>[1, 1]);
      final source = snapshot.manifest.tilesets.single.source!
          as ProjectRegularAtlasTilesetSource;
      expect(source.tileAnimations, hasLength(1));
    });

    test('keeps TSX files with different animation timing independent',
        () async {
      final setup = await _TiledMapImportSetup.create();
      addTearDown(setup.dispose);

      final planned = await setup.mutations.plan(
        setup.projectHandle,
        await setup.sharedArtifactRequest(
          secondTsx: _tsx.replaceFirst('duration="120"', 'duration="240"'),
        ),
      );
      final preview = Map<String, Object?>.from(
        Map<String, Object?>.from(planned['plan']! as Map)['preview']! as Map,
      );
      expect(preview['tilesetCount'], 2);

      await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-distinct-map-artifact',
      );
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      expect(snapshot.manifest.tilesets, hasLength(2));
      final durations = snapshot.manifest.tilesets
          .map(
            (tileset) => (tileset.source! as ProjectRegularAtlasTilesetSource)
                .tileAnimations
                .single
                .frames
                .single
                .durationMs,
          )
          .toSet();
      expect(durations, const <int>{120, 240});
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
    required this.tmxArtifact,
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
    final storedTmx = await artifacts.put(
      utf8.encode(imageCollection ? _imageCollectionTmx : _tmx),
      declaredMediaType: 'text/plain',
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
      tmxArtifact: storedTmx.reference,
      imageCollection: imageCollection,
    );
  }

  final Directory root;
  final LocalMapAuthoringMutationApi mutations;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader snapshots;
  final ContentArtifactRef artifact;
  final ContentArtifactRef tmxArtifact;
  final bool imageCollection;

  Future<AuthoringRequest> request({
    String idempotencyKey = 'map-tiled-import',
    String mapId = 'imported-road',
    String tilesetId = 'road',
    String assetId = 'road-image',
    String logicalPath = 'assets/tilesets/road.png',
    Map<String, String>? layerModes,
    bool stageTmx = false,
    bool includeInlineTmx = true,
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
        'mapId': mapId,
        'displayName':
            mapId == 'imported-road' ? 'Imported road' : 'Imported road 2',
        'role': 'exterior',
        if (stageTmx) 'tmxArtifactHandle': tmxArtifact.handle,
        if (includeInlineTmx)
          'tmx': imageCollection ? _imageCollectionTmx : _tmx,
        if (layerModes != null) 'layerModes': layerModes,
        'tilesets': <Object?>[
          <String, Object?>{
            'source': 'road.tsx',
            'tsx': imageCollection ? _imageCollectionTsx : _tsx,
            'tilesetId': tilesetId,
            'assetId': assetId,
            'logicalPath': logicalPath,
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

  Future<AuthoringRequest> sharedArtifactRequest(
      {String secondTsx = _tsx}) async {
    final snapshot = await snapshots.load(projectHandle);
    Map<String, Object?> tileset(
      String source,
      String suffix, {
      String tsx = _tsx,
    }) =>
        <String, Object?>{
          'source': source,
          'tsx': tsx,
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
          tileset('road-b.tsx', 'b', tsx: secondTsx),
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
      final source = snapshot.manifest.tilesets.single.source!
          as ProjectRegularAtlasTilesetSource;
      expect(source.tileAnimations, hasLength(1));
      expect(source.tileAnimations.single.frames.single.durationMs, 120);
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
  <image source="road.png" trans="f05ba1" width="1" height="1"/>
  <tile id="0"><animation><frame tileid="0" duration="120"/></animation></tile>
</tileset>
''';

const _wangTsx = '''
<tileset name="Road" tilewidth="1" tileheight="1" tilecount="1" columns="1">
  <image source="road.png" trans="f05ba1" width="1" height="1"/>
  <tile id="0"><animation><frame tileid="0" duration="120"/></animation></tile>
  <wangsets>
    <wangset name="Road" type="corner" tile="-1">
      <wangcolor name="Road" color="#c8a162" tile="0" probability="1"/>
      <wangtile tileid="0" wangid="1,0,1,0,1,0,1,0"/>
    </wangset>
  </wangsets>
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
    <image source="road-sparse.png" trans="0c2238" width="1" height="1"/>
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
