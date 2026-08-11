import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('tileset.tiled.import', () {
    test('packs and reopens one sparse image collection atomically', () async {
      final setup = await _ImageCollectionImportSetup.create();
      addTearDown(setup.dispose);

      final snapshot = await setup.snapshots.load(setup.projectHandle);
      final request = AuthoringRequest(
        requestId: 'request-image-collection',
        actionId: 'tileset.tiled.import',
        actionVersion: 1,
        workspaceHandle: setup.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'image-collection-import',
        parameters: <String, Object?>{
          'assetId': 'props',
          'logicalPath': 'assets/tilesets/props',
          'tilesetId': 'props',
          'displayName': 'Props',
          'importId': 'props',
          'tsx': _imageCollectionTsx,
          'imageArtifacts': <Object?>[
            <String, Object?>{
              'source': 'props/flower.png',
              'artifactHandle': setup.artifact.handle,
            },
            <String, Object?>{
              'source': 'props/water.png',
              'artifactHandle': setup.artifact.handle,
            },
          ],
          'selections': const <Object?>[],
          'tags': const <String>['tiled', 'prop'],
          'usages': const <String>['smart-tiles-studio'],
        },
      );

      final planned = await setup.mutations.plan(setup.projectHandle, request);
      final plan = Map<String, Object?>.from(planned['plan']! as Map);
      final preview = Map<String, Object?>.from(plan['preview']! as Map);
      expect(preview['sourceKind'], 'image_collection');
      expect(preview['sourceImageCount'], 2);
      expect(preview['generatedPageCount'], 1);
      expect(preview['tileCount'], 2);

      await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-image-collection',
      );

      final reopened = await setup.snapshots.load(setup.projectHandle);
      final tileset = reopened.manifest.tilesets.single;
      final source = tileset.source as ProjectImageCollectionTilesetSource;
      expect(source.pages, hasLength(1));
      expect(source.tileDefinitions.map((tile) => tile.tileId), <int>[5, 9]);
      expect(source.tileDefinitions.first.offsetX, 2);
      expect(source.tileDefinitions.first.offsetY, -3);
      expect(source.tileDefinitions.first.properties.single.name, 'name');
      expect(source.tileDefinitions.first.collisionObjects.single.name, 'hit');
      expect(
        source.tileDefinitions.last.animation.single,
        const ProjectImageCollectionAnimationFrame(
          tileId: 5,
          durationMs: 120,
        ),
      );

      final catalogBytes = reopened.findResourceBytes(
        assetCatalogResourceIdentity,
      );
      final catalog = AssetCatalog.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(utf8.decode(catalogBytes!)) as Map,
        ),
      );
      expect(catalog.records, hasLength(1));
      expect(catalog.records.single.id, 'props-page-0000');
      expect(
        reopened.findResourceBytes(
          assetBlobResourceIdentity(catalog.records.single.artifact.digest),
        ),
        isNotNull,
      );
    });

    test('plans, applies and replays one composite receipt', () async {
      final setup = await _TiledImportSetup.create();
      addTearDown(setup.dispose);

      final actions = (setup.mutations.describeMutations()['actions']! as List)
          .cast<Map<String, Object?>>();
      expect(
        actions.map((action) => action['id']),
        contains('tileset.tiled.import'),
      );
      expect(
        actions.map((action) => action['id']),
        contains('tileset.tiled.wang_bundle.delete'),
      );

      final request = await setup.request();
      final planned = await setup.mutations.plan(setup.projectHandle, request);
      final plan = Map<String, Object?>.from(planned['plan']! as Map);
      final changeSet = Map<String, Object?>.from(plan['changeSet']! as Map);
      expect(changeSet['changes'], hasLength(3));
      expect(
        Map<String, Object?>.from(plan['preview']! as Map)['operation'],
        'tileset.tiled.import',
      );

      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-tiled-road',
      );
      final replayed = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-tiled-road-retry',
      );

      expect(replayed['receipt'], applied['receipt']);
      await setup.expectComplete();

      final conflicting = await setup.request(
        idempotencyKey: 'tiled-road-conflict',
      );
      await expectLater(
        () => setup.mutations.plan(setup.projectHandle, conflicting),
        throwsA(
          isA<AssetActionException>().having(
            (error) => error.code,
            'code',
            'asset.id_conflict',
          ),
        ),
      );

      await expectLater(
        () async => setup.mutations.plan(
          setup.projectHandle,
          await setup.request(
            idempotencyKey: 'tiled-road-path-conflict',
            assetId: 'road-image-2',
          ),
        ),
        throwsA(
          isA<AssetActionException>().having(
            (error) => error.code,
            'code',
            'asset.path_conflict',
          ),
        ),
      );
      await expectLater(
        () async => setup.mutations.plan(
          setup.projectHandle,
          await setup.request(
            idempotencyKey: 'tiled-road-tileset-conflict',
            assetId: 'road-image-2',
            logicalPath: 'assets/road-2.png',
            importId: 'road-2',
          ),
        ),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset.id_conflict',
          ),
        ),
      );
      await expectLater(
        () async => setup.mutations.plan(
          setup.projectHandle,
          await setup.request(
            idempotencyKey: 'tiled-road-wang-conflict',
            assetId: 'road-image-2',
            logicalPath: 'assets/road-2.png',
            tilesetId: 'road-2',
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.tiled_wang.id_conflict',
          ),
        ),
      );
    });

    test('deletes one imported Wang bundle atomically', () async {
      final setup = await _TiledImportSetup.create();
      addTearDown(setup.dispose);

      final importRequest = await setup.request();
      final imported = await setup.mutations.plan(
        setup.projectHandle,
        importRequest,
      );
      await setup.mutations.apply(
        setup.projectHandle,
        planId: imported['planId']! as String,
        operationId: 'operation-import-before-delete',
      );

      final snapshot = await setup.snapshots.load(setup.projectHandle);
      final projectBeforeDelete =
          await File('${setup.root.path}/project.json').readAsBytes();
      final assetCatalogBeforeDelete =
          await File('${setup.root.path}/$assetCatalogStorageKey')
              .readAsBytes();
      final blobPath =
          '${setup.root.path}/${assetBlobStorageKey(setup.artifact)}';
      final blobBeforeDelete = await File(blobPath).readAsBytes();
      final deleteRequest = AuthoringRequest(
        requestId: 'request-delete-wang-bundle',
        actionId: 'tileset.tiled.wang_bundle.delete',
        actionVersion: 1,
        workspaceHandle: setup.workspaceHandle.value,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'delete-wang-bundle',
        parameters: const <String, Object?>{'importId': 'road'},
      );
      final planned = await setup.mutations.plan(
        setup.projectHandle,
        deleteRequest,
      );
      final preview = Map<String, Object?>.from(
        Map<String, Object?>.from(planned['plan']! as Map)['preview']! as Map,
      );
      expect(preview['operation'], 'tileset.tiled.wang_bundle.delete');
      expect(preview['presetCount'], 1);
      expect(preview['materialCount'], 1);
      expect(preview['animationCount'], 1);
      expect(preview['blobDeleted'], isTrue);

      final confirmation = await setup.mutations.confirm(
        setup.projectHandle,
        planId: planned['planId']! as String,
      );
      final deleted = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation-delete-wang-bundle',
        confirmationToken: confirmation['confirmationToken']! as String,
      );

      final reopened = await setup.snapshots.load(setup.projectHandle);
      expect(reopened.manifest.tilesets, isEmpty);
      expect(reopened.manifest.smartTileCatalog.atlases, isEmpty);
      expect(reopened.manifest.smartTileCatalog.materials, isEmpty);
      expect(reopened.manifest.smartTileCatalog.animations, isEmpty);
      expect(reopened.manifest.smartTileCatalog.presets, isEmpty);
      final catalog = AssetCatalog.fromJson(
        jsonDecode(
          await File('${setup.root.path}/$assetCatalogStorageKey')
              .readAsString(),
        ) as Map<String, dynamic>,
      );
      expect(catalog.records, isEmpty);
      expect(
        await File(blobPath).exists(),
        isFalse,
      );

      final receipt = Map<String, Object?>.from(
          deleted['receipt']! as Map<String, Object?>);
      await setup.mutations.undo(
        setup.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'undo-delete-wang-bundle',
      );
      expect(
        await File('${setup.root.path}/project.json').readAsBytes(),
        projectBeforeDelete,
      );
      expect(
        await File('${setup.root.path}/$assetCatalogStorageKey').readAsBytes(),
        assetCatalogBeforeDelete,
      );
      expect(await File(blobPath).readAsBytes(), blobBeforeDelete);
    });

    test('refuses to delete a Wang bundle referenced by a map layer', () async {
      final setup = await _TiledImportSetup.create();
      addTearDown(setup.dispose);

      final imported = await setup.mutations.plan(
        setup.projectHandle,
        await setup.request(),
      );
      await setup.mutations.apply(
        setup.projectHandle,
        planId: imported['planId']! as String,
        operationId: 'operation-import-before-referenced-delete',
      );
      final importedSnapshot = await setup.snapshots.load(setup.projectHandle);
      final manifest = importedSnapshot.manifest.copyWith(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'fixture',
            name: 'Fixture',
            relativePath: 'maps/fixture.json',
          ),
        ],
      );
      const map = MapData(
        id: 'fixture',
        name: 'Fixture',
        version: ProjectVersion.v6,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          SmartTileLayer(
            id: 'road-layer',
            name: 'Road',
            presetId: 'road-w0-preset',
            usage: SmartTileUsage.path,
            materialPalette: <String>['', 'road-w0-material'],
            field: SmartTileField.cell(semanticCells: <int>[1]),
          ),
        ],
      );
      await File('${setup.root.path}/project.json').writeAsBytes(
        _encode(manifest.toJson()),
        flush: true,
      );
      await Directory('${setup.root.path}/maps').create();
      await File('${setup.root.path}/maps/fixture.json').writeAsBytes(
        _encode(map.toJson()),
        flush: true,
      );
      final referencedSnapshot =
          await setup.snapshots.load(setup.projectHandle);
      final request = AuthoringRequest(
        requestId: 'request-delete-referenced-wang-bundle',
        actionId: 'tileset.tiled.wang_bundle.delete',
        actionVersion: 1,
        workspaceHandle: setup.workspaceHandle.value,
        expectedRevision: referencedSnapshot.revision,
        idempotencyKey: 'delete-referenced-wang-bundle',
        parameters: const <String, Object?>{'importId': 'road'},
      );

      await expectLater(
        () => setup.mutations.plan(setup.projectHandle, request),
        throwsA(
          isA<VisualLibraryException>().having(
            (error) => error.code,
            'code',
            'tileset.tiled.bundle_references_blocking',
          ),
        ),
      );

      final reopened = await setup.snapshots.load(setup.projectHandle);
      expect(reopened.manifest.tilesets.single.id, 'road');
      expect(
          reopened.manifest.smartTileCatalog.atlases.single.id, 'road-atlas');
      expect(
        reopened.manifest.smartTileCatalog.presets.single.id,
        'road-w0-preset',
      );
    });

    for (final recoveryCase in _recoveryCases) {
      test('recovers ${recoveryCase.label} without orphaned resources',
          () async {
        var crashed = false;
        final setup = await _TiledImportSetup.create(
          faultInjector: (context) {
            if (!crashed && recoveryCase.matches(context)) {
              crashed = true;
              throw const AuthoringTransactionSimulatedCrash();
            }
          },
        );
        addTearDown(setup.dispose);
        final request = await setup.request(
          idempotencyKey: 'tiled-recovery-${recoveryCase.slug}',
        );
        final planned = await setup.mutations.plan(
          setup.projectHandle,
          request,
        );

        await expectLater(
          () => setup.mutations.apply(
            setup.projectHandle,
            planId: planned['planId']! as String,
            operationId: 'operation-${recoveryCase.slug}',
          ),
          throwsA(isA<AuthoringTransactionSimulatedCrash>()),
        );

        if (recoveryCase.unreserved) {
          await setup.expectInitial();
          return;
        }

        final recovered = await setup.mutations.recover(
          setup.projectHandle,
          operationId: 'operation-${recoveryCase.slug}',
        );
        expect(
          Map<String, Object?>.from(recovered['receipt']! as Map)['status'],
          'recovered',
        );
        final replayed = await setup.mutations.recover(
          setup.projectHandle,
          operationId: 'operation-${recoveryCase.slug}',
        );
        expect(replayed['receipt'], recovered['receipt']);
        await setup.expectComplete();
      });
    }
  });
}

final class _ImageCollectionImportSetup {
  const _ImageCollectionImportSetup({
    required this.root,
    required this.mutations,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.snapshots,
    required this.artifact,
  });

  static Future<_ImageCollectionImportSetup> create() async {
    final root = await Directory.systemTemp.createTemp('tiled-collection-');
    final manifest = ProjectManifest(
      name: 'Tiled collection fixture',
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
      tokenFactory: (prefix) => '${prefix}tiled-collection',
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
      clock: () => DateTime.utc(2026, 8, 4, 12),
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _ImageCollectionImportSetup(
      root: root,
      mutations: mutations,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
      snapshots: snapshots,
      artifact: stored.reference,
    );
  }

  final Directory root;
  final LocalMapAuthoringMutationApi mutations;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader snapshots;
  final ContentArtifactRef artifact;

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
        rgbaBytes: const <int>[12, 34, 56, 255],
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

final class _RecoveryCase {
  const _RecoveryCase(
    this.checkpoint, {
    this.promotionIndex,
    this.unreserved = false,
  });

  final AuthoringTransactionCheckpoint checkpoint;
  final int? promotionIndex;
  final bool unreserved;

  String get slug => <String>[
        checkpoint.name,
        if (promotionIndex != null) '$promotionIndex',
      ].join('-');

  String get label => promotionIndex == null
      ? checkpoint.name
      : '${checkpoint.name}[$promotionIndex]';

  bool matches(AuthoringTransactionCheckpointContext context) =>
      context.checkpoint == checkpoint &&
      (promotionIndex == null || context.promotionIndex == promotionIndex);
}

const _recoveryCases = <_RecoveryCase>[
  _RecoveryCase(
    AuthoringTransactionCheckpoint.afterJournalPreparing,
    unreserved: true,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.afterPayloadsStaged,
    unreserved: true,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.afterJournalStaged,
    unreserved: true,
  ),
  _RecoveryCase(AuthoringTransactionCheckpoint.afterReservation),
  _RecoveryCase(AuthoringTransactionCheckpoint.afterJournalPrepared),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.beforeResourcePromotion,
    promotionIndex: 0,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.beforeResourcePromotion,
    promotionIndex: 1,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.beforeResourcePromotion,
    promotionIndex: 2,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.afterResourcePromoted,
    promotionIndex: 0,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.afterResourcePromoted,
    promotionIndex: 1,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.afterResourcePromoted,
    promotionIndex: 2,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.afterResourceJournaled,
    promotionIndex: 0,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.afterResourceJournaled,
    promotionIndex: 1,
  ),
  _RecoveryCase(
    AuthoringTransactionCheckpoint.afterResourceJournaled,
    promotionIndex: 2,
  ),
  _RecoveryCase(AuthoringTransactionCheckpoint.afterJournalCommitted),
];

final class _TiledImportSetup {
  _TiledImportSetup._({
    required this.root,
    required this.mutations,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.snapshots,
    required this.artifact,
  });

  static Future<_TiledImportSetup> create({
    AuthoringTransactionFaultInjector? faultInjector,
  }) async {
    final root = await Directory.systemTemp.createTemp('tiled-import-');
    final manifest = ProjectManifest(
      name: 'Tiled import fixture',
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
      tokenFactory: (prefix) => '${prefix}tiled-import',
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
      faultInjector: faultInjector,
      clock: () => DateTime.utc(2026, 8, 4, 12),
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _TiledImportSetup._(
      root: root,
      mutations: mutations,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
      snapshots: snapshots,
      artifact: stored.reference,
    );
  }

  final Directory root;
  final LocalMapAuthoringMutationApi mutations;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader snapshots;
  final ContentArtifactRef artifact;

  Future<AuthoringRequest> request({
    String idempotencyKey = 'tiled-road-import',
    String assetId = 'road-image',
    String logicalPath = 'assets/road.png',
    String tilesetId = 'road',
    String importId = 'road',
  }) async {
    final snapshot = await snapshots.load(projectHandle);
    return AuthoringRequest(
      requestId: 'request-$idempotencyKey',
      actionId: 'tileset.tiled.import',
      actionVersion: 1,
      workspaceHandle: workspaceHandle.value,
      expectedRevision: snapshot.revision,
      idempotencyKey: idempotencyKey,
      parameters: <String, Object?>{
        'artifactHandle': artifact.handle,
        'assetId': assetId,
        'logicalPath': logicalPath,
        'tilesetId': tilesetId,
        'displayName': 'Road',
        'importId': importId,
        'tsx': _tsx,
        'selections': const <Object?>[
          <String, Object?>{'wangSetIndex': 0, 'usage': 'path'},
        ],
        'tags': const <String>['tiled'],
        'usages': const <String>['smart-tiles-studio'],
      },
    );
  }

  Future<void> expectComplete() async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(
        await File('${root.path}/project.json').readAsString(),
      ) as Map<String, dynamic>,
    );
    expect(manifest.tilesets.single.id, 'road');
    expect(
      manifest.tilesets.single.transparentColor?.toHexRgb(),
      'f05ba1',
    );
    final source =
        manifest.tilesets.single.source! as ProjectRegularAtlasTilesetSource;
    expect(source.tileAnimations, hasLength(1));
    expect(source.tileAnimations.single.frames.single.durationMs, 120);
    expect(manifest.smartTileCatalog.atlases.single.id, 'road-atlas');
    expect(manifest.smartTileCatalog.presets.single.id, 'road-w0-preset');

    final catalog = AssetCatalog.fromJson(
      jsonDecode(
        await File('${root.path}/$assetCatalogStorageKey').readAsString(),
      ) as Map<String, dynamic>,
    );
    expect(catalog.require('road-image').logicalPath, 'assets/road.png');
    expect(
      await File('${root.path}/${assetBlobStorageKey(artifact)}').readAsBytes(),
      _pngBytes,
    );
  }

  Future<void> expectInitial() async {
    final manifest = ProjectManifest.fromJson(
      jsonDecode(
        await File('${root.path}/project.json').readAsString(),
      ) as Map<String, dynamic>,
    );
    expect(manifest.tilesets, isEmpty);
    expect(manifest.smartTileCatalog.atlases, isEmpty);
    expect(manifest.smartTileCatalog.presets, isEmpty);
    expect(
      await File('${root.path}/$assetCatalogStorageKey').exists(),
      isFalse,
    );
    expect(
      await File('${root.path}/${assetBlobStorageKey(artifact)}').exists(),
      isFalse,
    );
  }

  Future<void> dispose() => root.delete(recursive: true);
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
  <wangsets>
    <wangset name="Road" type="edge" tile="-1">
      <wangcolor name="Road" color="#c8a162" tile="0" probability="1"/>
      <wangtile tileid="0" wangid="1,0,1,0,1,0,1,0"/>
    </wangset>
  </wangsets>
</tileset>
''';

const _imageCollectionTsx = '''
<tileset name="Props" tilewidth="1" tileheight="1" tilecount="2" columns="0">
  <tileoffset x="2" y="-3"/>
  <tile id="5">
    <properties><property name="name" value="Flower"/></properties>
    <image source="props/flower.png" width="1" height="1"/>
    <objectgroup>
      <object id="1" name="hit" x="0" y="0" width="1" height="1"/>
    </objectgroup>
  </tile>
  <tile id="9">
    <image source="props/water.png" width="1" height="1"/>
    <animation><frame tileid="5" duration="120"/></animation>
  </tile>
</tileset>
''';
