import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('shared native cache binds lazy reads to the current handle store',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('snapshot-cross-store-');
    addTearDown(() => directory.delete(recursive: true));
    final bytes = List<int>.generate(128 * 1024 + 9, (index) => index % 251);
    final artifact = ContentArtifactRef.fromBytes(bytes,
        mediaType: 'application/octet-stream');
    final files = {
      'project.json': utf8.encode(jsonEncode(ProjectManifest(
          name: 'Shared',
          version: ProjectVersion.v8,
          maps: const [
            ProjectMapEntry(
                id: 'map', name: 'Map', relativePath: 'maps/map.json')
          ],
          tilesets: const []).toJson())),
      'maps/map.json': utf8.encode(jsonEncode(const MapData(
              id: 'map',
              name: 'Map',
              version: ProjectVersion.v8,
              size: GridSize(width: 2, height: 2))
          .toJson())),
      assetCatalogStorageKey: utf8.encode(jsonEncode(AssetCatalog(records: [
        AssetRecord(
            id: 'source', logicalPath: 'assets/source.bin', artifact: artifact)
      ]).toJson())),
      assetBlobStorageKey(artifact): bytes,
      'assets/source.bin': bytes,
    };
    for (final entry in files.entries) {
      final file = File('${directory.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.path],
        fileReader: const LocalProjectFileReader());
    final cache = ProjectSnapshotCache();
    final firstHandles = WorkspaceHandleStore();
    final firstOpener = ProjectOpenService(
        policy: policy,
        handles: firstHandles,
        fileReader: const LocalProjectFileReader());
    final first = await firstOpener.openProject(directory.path);
    final firstSnapshot =
        await ProjectSnapshotLoader(handles: firstHandles, snapshotCache: cache)
            .load(first.projectHandle);
    firstOpener.closeWorkspace(first.workspaceHandle);
    final secondHandles = WorkspaceHandleStore();
    final secondOpener = ProjectOpenService(
        policy: policy,
        handles: secondHandles,
        fileReader: const LocalProjectFileReader());
    final second = await secondOpener.openProject(directory.path);
    addTearDown(() => secondOpener.closeWorkspace(second.workspaceHandle));
    final detached = await cache.lookup(
        secondHandles.resolveProject(second.projectHandle),
        second.projectHandle);
    expect(detached!.resourcePayloadReader, isNull);
    expect(detached.payloadOwner, isNull);
    expect(detached.payloadResources, isEmpty);
    final secondLoader =
        ProjectSnapshotLoader(handles: secondHandles, snapshotCache: cache);
    final rebound = await secondLoader.load(second.projectHandle);
    expect(rebound.revision, firstSnapshot.revision);
    expect(cache.canonicalHits, 2);
    expect(
        await rebound
            .readResourceBytes(assetBlobResourceIdentity(artifact.digest)),
        bytes);
    final captured = await rebound.captureResourcePayload('asset:source');
    addTearDown(captured.release);
    expect(await captured.readBytes(), bytes);
    final mutations = LocalMapAuthoringMutationApi(
        policy: policy, snapshotLoader: secondLoader);
    await mutations.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: second.workspaceHandle,
        projectHandle: second.projectHandle);
    final plan = await mutations.planMutation(
        second.projectHandle,
        AuthoringRequest(
            requestId: 'cross-store-map',
            actionId: 'map.save',
            actionVersion: 1,
            workspaceHandle: second.workspaceHandle.value,
            expectedRevision: rebound.revision,
            idempotencyKey: 'cross-store-map',
            parameters: {
              'map': rebound.maps.single.copyWith(name: 'Updated').toJson()
            }));
    final applied = await mutations.applyMutation(second.projectHandle,
        planId: plan.planId, operationId: 'cross-store-map');
    expect(applied.diagnostic, isNull);
    expect(plan.plan.appliedPayloadReleased, isTrue);
    expect(cache.adoptions, 1);
    final adopted = await secondLoader.load(second.projectHandle,
        cacheValidation: ProjectSnapshotCacheValidation.session);
    expect(adopted.maps.single.name, 'Updated');
    expect(
        await adopted
            .readResourceBytes(assetBlobResourceIdentity(artifact.digest)),
        bytes);
    await mutations.detachWorkspace(second.workspaceHandle);
    await expectLater(
        firstSnapshot
            .readResourceBytes(assetBlobResourceIdentity(artifact.digest)),
        throwsA(isA<WorkspaceHandleException>()));
  });
  test(
      'native snapshots retain descriptors and renew the reading handle on cache hit',
      () async {
    final directory = await Directory.systemTemp.createTemp('snapshot-lazy-');
    addTearDown(() => directory.delete(recursive: true));
    final bytes =
        List<int>.generate(2 * 1024 * 1024 + 7, (index) => index % 251);
    final artifact = ContentArtifactRef.fromBytes(bytes,
        mediaType: 'application/octet-stream');
    final files = {
      'project.json': utf8.encode(jsonEncode(ProjectManifest(
          name: 'Lazy',
          version: ProjectVersion.v8,
          maps: const [],
          tilesets: const []).toJson())),
      assetCatalogStorageKey: utf8.encode(jsonEncode(AssetCatalog(records: [
        AssetRecord(
            id: 'source', logicalPath: 'assets/source.bin', artifact: artifact),
      ]).toJson())),
      assetBlobStorageKey(artifact): bytes,
      'assets/source.bin': bytes,
    };
    for (final entry in files.entries) {
      final file = File('${directory.path}/${entry.key}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [directory.parent.path],
        fileReader: const LocalProjectFileReader());
    final opener = ProjectOpenService(
        policy: policy,
        handles: handles,
        fileReader: const LocalProjectFileReader());
    final cache = ProjectSnapshotCache();
    final loader =
        ProjectSnapshotLoader(handles: handles, snapshotCache: cache);
    final firstOpen = await opener.openProject(directory.path);
    final first = await loader.load(firstOpen.projectHandle);
    final identity = assetBlobResourceIdentity(artifact.digest);
    expect(first.hasResource(identity), isTrue);
    expect(first.resourceByteLength, lessThan(bytes.length));
    expect(first.storedResources[identity]!.byteLength, bytes.length);
    expect(() => first.findResourceBytes(identity),
        throwsA(isA<ProjectSnapshotException>()));
    const reader = LocalProjectFileReader();
    final inlineHandles = WorkspaceHandleStore();
    final root = await directory.resolveSymbolicLinks();
    final inlineRegistration = inlineHandles.registerProject(
        projectName: 'Inline',
        initialFingerprint: 'inline',
        readBytes: (path) =>
            reader.readBytes(projectRoot: root, relativePath: path));
    addTearDown(
        () => inlineHandles.closeWorkspace(inlineRegistration.workspaceHandle));
    final inline = await ProjectSnapshotLoader(handles: inlineHandles)
        .load(inlineRegistration.projectHandle);
    expect(inline.revision, first.revision);
    expect(inline.resourceFingerprints, first.resourceFingerprints);
    final frozen = await first.captureResourcePayload(identity);
    addTearDown(frozen.release);
    opener.closeWorkspace(firstOpen.workspaceHandle);
    final secondOpen = await opener.openProject(directory.path);
    addTearDown(() => opener.closeWorkspace(secondOpen.workspaceHandle));
    final second = await loader.load(secondOpen.projectHandle);
    expect(second.revision, first.revision);
    expect(cache.canonicalHits, 1);
    expect(await second.readResourceBytes(identity), bytes);
    await expectLater(first.readResourceBytes(identity),
        throwsA(isA<WorkspaceHandleException>()));
    final mutations =
        LocalMapAuthoringMutationApi(policy: policy, snapshotLoader: loader);
    await mutations.attachProject(
        projectRootPath: directory.path,
        workspaceHandle: secondOpen.workspaceHandle,
        projectHandle: secondOpen.projectHandle);
    final removal = await mutations.planMutation(
        secondOpen.projectHandle,
        AuthoringRequest(
            requestId: 'remove-source',
            actionId: 'asset.delete',
            actionVersion: 1,
            workspaceHandle: secondOpen.workspaceHandle.value,
            expectedRevision: second.revision,
            idempotencyKey: 'remove-source',
            parameters: const {'assetId': 'source'}));
    expect(
        removal.plan.changeSet.changes
            .where((change) => change.storageKey.endsWith('.bin'))
            .every((change) => change.beforePayload?.isInline == false),
        isTrue);
    await expectLater(
        mutations.applyMutation(secondOpen.projectHandle,
            planId: removal.planId, operationId: 'remove-source'),
        throwsA(isA<AuthoringAuthorizationException>()));
    final confirmation = await mutations
        .confirmMutation(secondOpen.projectHandle, planId: removal.planId);
    final removed = await mutations.applyMutation(secondOpen.projectHandle,
        planId: removal.planId,
        operationId: 'remove-source',
        confirmationToken: confirmation.confirmationToken);
    expect(removed.snapshotRevision, isNotNull);
    expect(await File('${directory.path}/assets/source.bin').exists(), isFalse);
    final undone = await mutations.undoMutation(secondOpen.projectHandle,
        entryId: removed.receipt.receiptId, idempotencyKey: 'restore-source');
    expect(undone.snapshotRevision, isNotNull);
    final restored = await loader.load(secondOpen.projectHandle);
    expect(restored.revision, first.revision);
    expect(restored.resourceByteLength, lessThan(bytes.length));
    expect(restored.storedResources[identity]!.byteLength, bytes.length);
    expect(await restored.readResourceBytes(identity), bytes);
    expect(
        await File('${directory.path}/assets/source.bin').readAsBytes(), bytes);
    await mutations.detachWorkspace(secondOpen.workspaceHandle);
    await File('${directory.path}/${assetBlobStorageKey(artifact)}')
        .writeAsBytes([...bytes]..[bytes.length - 1] ^= 1);
    expect(await frozen.readBytes(), bytes);
    await expectLater(loader.load(secondOpen.projectHandle),
        throwsA(isA<ProjectSnapshotException>()));
  });
}
