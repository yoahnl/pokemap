import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('tileset.tiled.import', () {
    test('plans, applies and replays one composite receipt', () async {
      final setup = await _TiledImportSetup.create();
      addTearDown(setup.dispose);

      final actions = (setup.mutations.describeMutations()['actions']! as List)
          .cast<Map<String, Object?>>();
      expect(
        actions.map((action) => action['id']),
        contains('tileset.tiled.import'),
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
  <image source="road.png" width="1" height="1"/>
  <wangsets>
    <wangset name="Road" type="edge" tile="-1">
      <wangcolor name="Road" color="#c8a162" tile="0" probability="1"/>
      <wangtile tileid="0" wangid="1,0,1,0,1,0,1,0"/>
    </wangset>
  </wangsets>
</tileset>
''';
