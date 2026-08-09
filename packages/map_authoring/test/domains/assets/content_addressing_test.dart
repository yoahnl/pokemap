import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('content-addressed artifact store', () {
    test('deduplicates identical bytes and round-trips the public reference',
        () async {
      final store = MemoryArtifactStore(maximumArtifactBytes: 1024);

      final first = await store.put(
        utf8.encode('same payload'),
        declaredMediaType: 'text/plain',
      );
      final second = await store.put(
        utf8.encode('same payload'),
        declaredMediaType: 'text/plain',
      );

      expect(second.reference, first.reference);
      expect(second.deduplicated, isTrue);
      expect(store.list(), hasLength(1));
      expect(
        ContentArtifactRef.fromJson(first.reference.toJson()),
        first.reference,
      );
    });

    test('canonical plan/apply/delete/undo restores the exact blob', () async {
      final directory = await Directory.systemTemp.createTemp(
        'pokemap_asset_transaction_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final manifest = ProjectManifest(
        name: 'Asset transaction fixture',
        maps: const [],
        tilesets: const [],
      );
      await File('${directory.path}/project.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
      );
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final openService = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      );
      final snapshotLoader = ProjectSnapshotLoader(handles: handles);
      final opened = await openService.openProject(directory.path);
      final artifacts = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final staged = await artifacts.put(
        utf8.encode('transactional asset bytes'),
        declaredMediaType: 'text/plain',
      );
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshotLoader,
        artifactStore: artifacts,
        clock: () => DateTime.utc(2026, 7, 31, 12),
      );
      await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );

      final importPlan = await api.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'req-asset-import',
          actionId: 'asset.import',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: {
            'artifactHandle': staged.reference.handle,
            'assetId': 'dialogue-portrait',
            'logicalPath': 'images/dialogue/portrait.txt',
          },
          expectedRevision: opened.fingerprint,
          idempotencyKey: 'idem-asset-import',
        ),
      );
      final importResult = await api.apply(
        opened.projectHandle,
        planId: importPlan['planId']! as String,
        operationId: 'op-asset-import',
      );
      final importedRevision = importResult['snapshotRevision']! as String;
      final blob = File(
        '${directory.path}/${assetBlobStorageKey(staged.reference)}',
      );
      expect(
          await blob.readAsBytes(), utf8.encode('transactional asset bytes'));
      final assetPage = const ProjectQueryService().query(
        await snapshotLoader.load(opened.projectHandle),
        AuthoringQueryRequest(
          resourceKind: 'asset',
          operation: AuthoringQueryOperation.search,
          view: AuthoringQueryView.detail,
          searchTerm: 'portrait',
        ),
      );
      expect(assetPage.totalAvailable, 1);
      expect(assetPage.items.single['id'], 'dialogue-portrait');
      expect(
        (assetPage.items.single['preview']! as Map)['artifactHandle'],
        staged.reference.handle,
      );

      final deletePlan = await api.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'req-asset-delete',
          actionId: 'asset.delete',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const {'assetId': 'dialogue-portrait'},
          expectedRevision: importedRevision,
          idempotencyKey: 'idem-asset-delete',
        ),
      );
      final confirmation = await api.confirm(
        opened.projectHandle,
        planId: deletePlan['planId']! as String,
      );
      final deleteResult = await api.apply(
        opened.projectHandle,
        planId: deletePlan['planId']! as String,
        operationId: 'op-asset-delete',
        confirmationToken: confirmation['confirmationToken']! as String,
      );
      expect(await blob.exists(), isFalse);
      final receipt = Map<String, Object?>.from(
        deleteResult['receipt']! as Map,
      );

      await api.undo(
        opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem-asset-delete-undo',
      );
      expect(
          await blob.readAsBytes(), utf8.encode('transactional asset bytes'));
    });

    test('canonical raw replacement is revision-safe and undoable', () async {
      final directory = await Directory.systemTemp.createTemp(
        'pokemap_raw_asset_transaction_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final manifest = ProjectManifest(
        name: 'Raw asset transaction fixture',
        maps: const [],
        tilesets: const [],
      );
      await File('${directory.path}/project.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(manifest.toJson())}\n',
      );
      final rawAsset = File('${directory.path}/assets/audio/pikachu.ogg');
      await rawAsset.parent.create(recursive: true);
      final beforeBytes = <int>[0x4f, 0x67, 0x67, 0x53, 0x00, 0x01];
      final afterBytes = <int>[0x4f, 0x67, 0x67, 0x53, 0x00, 0x02];
      await rawAsset.writeAsBytes(beforeBytes);

      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore();
      final snapshots = ProjectSnapshotLoader(handles: handles);
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject(directory.path);
      final artifacts = MemoryArtifactStore(maximumArtifactBytes: 1024);
      final expected = await artifacts.put(
        beforeBytes,
        declaredMediaType: 'audio/ogg',
      );
      final replacement = await artifacts.put(
        afterBytes,
        declaredMediaType: 'audio/ogg',
      );
      final api = LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: snapshots,
        artifactStore: artifacts,
        clock: () => DateTime.utc(2026, 8, 5, 12),
      );
      await api.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: opened.projectHandle,
      );

      final plan = await api.plan(
        opened.projectHandle,
        AuthoringRequest(
          requestId: 'req-raw-asset-replace',
          actionId: 'asset.raw.replace',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: {
            'logicalPath': 'assets/audio/pikachu.ogg',
            'expectedArtifactHandle': expected.reference.handle,
            'replacementArtifactHandle': replacement.reference.handle,
          },
          expectedRevision: opened.fingerprint,
          idempotencyKey: 'idem-raw-asset-replace',
        ),
      );
      final applied = await api.apply(
        opened.projectHandle,
        planId: plan['planId']! as String,
        operationId: 'op-raw-asset-replace',
      );
      expect(await rawAsset.readAsBytes(), afterBytes);

      final receipt = Map<String, Object?>.from(applied['receipt']! as Map);
      await api.undo(
        opened.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem-raw-asset-replace-undo',
      );
      expect(await rawAsset.readAsBytes(), beforeBytes);
    });

    test('catalog search is deterministic and reports unused assets', () {
      final used = _record('used', 'images/used.png', usages: ['map:town']);
      final unused = _record('unused', 'images/unused.png');
      final catalog = AssetCatalog(records: [unused, used]);

      expect(
        catalog.search('IMAGE').map((record) => record.id),
        ['unused', 'used'],
      );
      expect(catalog.unused().map((record) => record.id), ['unused']);
      expect(
        AssetCatalog.fromJson(catalog.toJson()).toJson(),
        catalog.toJson(),
      );
    });

    test('catalog resolves an exact canonical logical path', () {
      final expected = _record('hero', 'images/hero.png');
      final catalog = AssetCatalog(
        records: [expected, _record('portrait', 'images/portrait.png')],
      );

      expect(catalog.findByLogicalPath('images/hero.png'), same(expected));
      expect(catalog.findByLogicalPath('images/HERO.png'), isNull);
      expect(catalog.findByLogicalPath('images/missing.png'), isNull);
    });

    test('delete planning refuses references and exposes their impact', () {
      final catalog = AssetCatalog(
        records: [
          _record('hero', 'characters/hero.png', usages: ['map:town']),
        ],
      );

      expect(
        () => const AssetActions().delete(
          catalog,
          assetId: 'hero',
        ),
        throwsA(
          isA<AssetActionException>()
              .having(
            (error) => error.code,
            'code',
            'asset.references_blocking',
          )
              .having(
            (error) => error.details['usages'],
            'usages',
            ['map:town'],
          ),
        ),
      );
    });

    test('delete plan retains exact bytes needed by undo', () {
      final bytes = utf8.encode('exact blob');
      final record = AssetRecord(
        id: 'unused',
        logicalPath: 'images/unused.bin',
        artifact: ContentArtifactRef.fromBytes(
          bytes,
          mediaType: 'application/octet-stream',
        ),
      );
      final result = const AssetActions().delete(
        AssetCatalog(records: [record]),
        assetId: 'unused',
        blobBytes: bytes,
      );

      expect(result.catalog.records, isEmpty);
      expect(result.rollbackBlobBytes, bytes);
      expect(result.deletedBlob, isTrue);
    });
  });
}

AssetRecord _record(
  String id,
  String logicalPath, {
  List<String> usages = const [],
}) {
  return AssetRecord(
    id: id,
    logicalPath: logicalPath,
    artifact: ContentArtifactRef.fromBytes(
      utf8.encode(id),
      mediaType: 'application/octet-stream',
    ),
    usages: usages,
  );
}
