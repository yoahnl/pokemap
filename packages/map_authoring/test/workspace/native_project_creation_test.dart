import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:map_authoring/map_authoring.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_authoring/src/transactions/authoring_payload.dart';
import 'package:map_authoring/src/workspace/project_creation_transaction.dart';
import 'package:map_core/map_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/src/workspace/project_creation_kit.dart';
import 'package:test/test.dart';

void main() {
  late Directory parent;
  setUp(() async {
    parent = await Directory.systemTemp.createTemp('native-creation-');
  });
  tearDown(() async {
    if (await parent.exists()) await parent.delete(recursive: true);
  });

  NativeProjectCreationInput input() {
    final kit = buildProjectCreationKit(ProjectCreationRequest(
        name: 'Native',
        folderName: 'native',
        parentPath: parent.path,
        template: ProjectCreationTemplate.empty));
    return NativeProjectCreationInput(
        manifest: kit.manifest,
        maps: const [],
        assetCatalog: AssetCatalog(records: const []));
  }

  test('STD08 native creation preserves the presentation catalog on reopen',
      () async {
    final base = input();
    final source = NativeProjectCreationInput(
      manifest: base.manifest,
      maps: base.maps,
      assetCatalog: base.assetCatalog,
      presentationMediaCatalog: ProjectMediaCatalog(),
    );
    final decoded = NativeProjectCreationInput.fromJson(
      Map<String, dynamic>.from(source.toJson()),
    );
    expect(decoded.presentationMediaCatalog?.toJson(),
        source.presentationMediaCatalog!.toJson());
    const service = NativeProjectCreationService();
    final prepared = await service.prepare(decoded);
    final plan = await service.plan(
        prepared: prepared,
        parentPath: parent.path,
        folderName: 'presentation');
    final receipt = await service.publish(plan);
    final saved = jsonDecode(await File(
      '${receipt.projectPath}/$projectMediaCatalogStorageKey',
    ).readAsString());
    expect(saved, source.presentationMediaCatalog!.toJson());
  });

  test('STD08 native creation rejects a dangling presentation source',
      () async {
    final base = input();
    await expectLater(
        const NativeProjectCreationService().prepare(
          NativeProjectCreationInput(
            manifest: base.manifest,
            maps: base.maps,
            assetCatalog: base.assetCatalog,
            presentationMediaCatalog: ProjectMediaCatalog(entries: [
              ProjectMediaAsset(
                  id: 'picture',
                  label: 'Picture',
                  kind: ProjectMediaKind.image,
                  sourceAssetId: 'missing'),
            ]),
          ),
        ),
        throwsFormatException);
    expect(await parent.list().toList(), isEmpty);
  });

  test('default native byte budget reports exact attempted bytes and path',
      () async {
    final bytes = Uint8List(16 * 1024 * 1024).asUnmodifiableView();
    final reference = ContentArtifactRef.fromBytes(bytes,
        mediaType: 'application/octet-stream');
    final source = NativeProjectCreationInput(
        manifest: input().manifest,
        maps: const [],
        assetCatalog: AssetCatalog(records: [
          for (var index = 0; index < 31; index++)
            AssetRecord(
                id: 'resource_$index',
                logicalPath: 'assets/data/$index.bin',
                artifact: reference)
        ]),
        artifacts: [
          NativeProjectCreationArtifact(reference: reference, bytes: bytes)
        ]);
    final attempted = utf8.encode(jsonEncode(source.manifest.toJson())).length +
        utf8.encode(jsonEncode(source.assetCatalog.toJson())).length +
        bytes.length * 32;
    await expectLater(
        const NativeProjectCreationService().prepare(source),
        throwsA(isA<FormatException>().having(
            (error) => error.message,
            'message',
            'native.creation.quota.bytes: attempted=$attempted, '
                'limit=$nativeProjectCreationMaxBytes, '
                'path=${source.assetCatalog.records.last.logicalPath}')));
    expect(await parent.list().toList(), isEmpty);
  });

  test('native resource budget reports exact attempted count and path',
      () async {
    final bytes = Uint8List.fromList([1, 2]).asUnmodifiableView();
    final reference = ContentArtifactRef.fromBytes(bytes,
        mediaType: 'application/octet-stream');
    final source = NativeProjectCreationInput(
        manifest: input().manifest,
        maps: const [],
        assetCatalog: AssetCatalog(records: [
          for (var index = 0;
              index < nativeProjectCreationMaxResources - 2;
              index++)
            AssetRecord(
                id: 'resource_$index',
                logicalPath: 'assets/data/$index.bin',
                artifact: reference)
        ]),
        artifacts: [
          NativeProjectCreationArtifact(reference: reference, bytes: bytes)
        ]);
    await expectLater(
        const NativeProjectCreationService().prepare(source),
        throwsA(isA<FormatException>().having(
            (error) => error.message,
            'message',
            'native.creation.quota.resources: '
                'attempted=${nativeProjectCreationMaxResources + 1}, '
                'limit=$nativeProjectCreationMaxResources, '
                'path=${source.assetCatalog.records.last.logicalPath}')));
    expect(await parent.list().toList(), isEmpty);
  });

  test(
      'explicit native byte budget accepts its exact boundary and binds receipt',
      () async {
    final source = input();
    final reference =
        await const NativeProjectCreationService().prepare(source);
    final service =
        NativeProjectCreationService(maxInventoryBytes: reference.byteLength);
    final prepared = await service.prepare(source);
    expect(const NativeProjectCreationService().maxInventoryBytes,
        nativeProjectCreationMaxBytes);
    expect(nativeProjectCreationMaxBytes, 500 * 1024 * 1024);
    expect(nativeProjectCreationHardMaxBytes, 1280 * 1024 * 1024);
    expect(prepared.byteLength, reference.byteLength);
    expect(prepared.inventoryFingerprint, reference.inventoryFingerprint);
    final plan = await service.plan(
        prepared: prepared, parentPath: parent.path, folderName: 'boundary');
    final receipt = await service.publish(plan);
    expect(receipt.inventoryFingerprint, prepared.inventoryFingerprint);
    expect(receipt.transactionReceipt.extensions['inventoryFingerprint'],
        prepared.inventoryFingerprint);
    expect(receipt.transactionReceipt.afterRevision, plan.afterRevision);
    expect(receipt.transactionReceipt.diff.toJson(), plan.diff.toJson());
    await expectLater(
        NativeProjectCreationService(
                maxInventoryBytes: reference.byteLength - 1)
            .prepare(source),
        throwsA(isA<FormatException>().having(
            (error) => error.message,
            'message',
            'native.creation.quota.bytes: '
                'attempted=${reference.byteLength}, '
                'limit=${reference.byteLength - 1}, '
                'path=assets/.pokemap-assets.json')));
  });

  test('minimum valid native byte budget fails closed on its first resource',
      () async {
    final source = input();
    final attempted = utf8.encode(jsonEncode(source.manifest.toJson())).length;
    await expectLater(
        const NativeProjectCreationService(maxInventoryBytes: 1)
            .prepare(source),
        throwsA(isA<FormatException>().having(
            (error) => error.message,
            'message',
            'native.creation.quota.bytes: attempted=$attempted, '
                'limit=1, path=project.json')));
    expect(await parent.list().toList(), isEmpty);
  });

  for (final limit in [-1, 0, nativeProjectCreationHardMaxBytes + 1]) {
    test('native byte budget refuses invalid limit $limit before creation',
        () async {
      await expectLater(
          NativeProjectCreationService(maxInventoryBytes: limit)
              .prepare(input()),
          throwsA(isA<FormatException>().having(
              (error) => error.message,
              'message',
              'native.creation.quota.invalid_limit: '
                  'attempted=$limit, minimum=1, '
                  'limit=$nativeProjectCreationHardMaxBytes')));
      expect(await parent.list().toList(), isEmpty);
    });
  }

  test(
      'explicit large native budget binds canonical shared aliases without I/O',
      () async {
    final bytes = Uint8List(16 * 1024 * 1024).asUnmodifiableView();
    final reference = ContentArtifactRef.fromBytes(bytes,
        mediaType: 'application/octet-stream');
    final artifact =
        NativeProjectCreationArtifact(reference: reference, bytes: bytes);
    final source = NativeProjectCreationInput(
        manifest: input().manifest,
        maps: const [],
        assetCatalog: AssetCatalog(records: [
          for (var index = 0; index < 31; index++)
            AssetRecord(
                id: 'resource_$index',
                logicalPath: 'assets/data/$index.bin',
                artifact: reference)
        ]),
        artifacts: [artifact]);
    final service = NativeProjectCreationService(
        maxInventoryBytes: nativeProjectCreationHardMaxBytes);
    final prepared = await service.prepare(source);
    expect(prepared.byteLength, greaterThan(nativeProjectCreationMaxBytes));
    expect(
        prepared.byteLength,
        utf8.encode(jsonEncode(source.manifest.toJson())).length +
            utf8.encode(jsonEncode(source.assetCatalog.toJson())).length +
            bytes.length * 32);
    expect(prepared.resourceCount, 34);
    final nativePlan = await service.plan(
        prepared: prepared,
        parentPath: parent.path,
        folderName: 'shared-aliases');
    final files = <String, List<int>>{
      'project.json': utf8.encode(jsonEncode(prepared.manifest.toJson())),
      assetCatalogStorageKey:
          utf8.encode(jsonEncode(source.assetCatalog.toJson())),
      for (final record in source.assetCatalog.records)
        record.logicalPath: artifact.bytes,
      assetBlobStorageKey(reference): artifact.bytes,
    };
    final changes = <AuthoringResourceChange>[];
    final artifactSha = crypto.sha256.convert(artifact.bytes).toString();
    for (final entry in files.entries) {
      final payload = await AuthoringPayload.verifiedSource(
          storageKey: entry.key,
          byteLength: entry.value.length,
          rawSha256: identical(entry.value, artifact.bytes)
              ? artifactSha
              : crypto.sha256.convert(entry.value).toString(),
          openRead: () => Stream.value(entry.value));
      changes.add(AuthoringResourceChange.withPayloads(
          resource: projectCreationResourceRef(entry.key, nativePlan.projectId),
          storageKey: entry.key,
          beforePayload: null,
          afterPayload: payload));
    }
    final plan = AuthoringPlan(
        planId: nativePlan.planId,
        receiptId: 'receipt-native-budget',
        request: AuthoringRequest(
            requestId: nativePlan.operationId,
            actionId: nativeProjectCreationActionId,
            actionVersion: 1,
            workspaceHandle: 'workspace-native-budget',
            expectedRevision: nativePlan.beforeRevision,
            idempotencyKey: nativePlan.operationId),
        baseRevision: nativePlan.beforeRevision,
        seed: 0,
        createdAt: nativePlan.createdAt,
        expiresAt: nativePlan.expiresAt,
        changeSet: AuthoringChangeSet(changes: changes, diff: nativePlan.diff));
    addTearDown(plan.releasePayloads);
    final capability = NativeProjectCreationCapability.forPreparedPlan(
        prepared: prepared,
        plan: plan,
        actorId: 'native-budget',
        projectId: nativePlan.projectId,
        operationId: nativePlan.operationId);
    plan.bindNativeCreationCapability(capability);
    expect(capability.byteLength, prepared.byteLength);
    expect(capability.inventoryFingerprint, prepared.inventoryFingerprint);
    final recovered = NativeProjectCreationCapability.fromJournalJson(
        Map<String, dynamic>.from(capability.toJson()));
    expect(recovered.byteLength, capability.byteLength);
    expect(recovered.toJson(), capability.toJson());
    expect(
        () => recovered.requirePlan(plan,
            actorId: capability.actorId,
            projectId: capability.projectId,
            operationId: capability.operationId),
        throwsStateError);
    expect(
        () => capability.requirePlan(plan,
            actorId: capability.actorId,
            projectId: 'foreign-project',
            operationId: capability.operationId),
        throwsFormatException);
    final altered = Map<String, dynamic>.from(capability.toJson())
      ..['byteLength'] = prepared.byteLength + 1;
    expect(() => NativeProjectCreationCapability.fromJournalJson(altered),
        throwsFormatException);
    final oversizedInventory = [
      for (final item in capability.toJson()['inventory'] as List)
        Map<String, Object?>.from(item as Map)
    ];
    oversizedInventory.first['byteLength'] =
        (oversizedInventory.first['byteLength'] as int) +
            nativeProjectCreationHardMaxBytes +
            1 -
            capability.byteLength;
    final oversized = Map<String, dynamic>.from(capability.toJson())
      ..['inventory'] = oversizedInventory
      ..['inventoryFingerprint'] = computeAuthoringJsonFingerprint(
          oversizedInventory,
          logicalName: 'native-project-creation-inventory.json')
      ..['byteLength'] = nativeProjectCreationHardMaxBytes + 1;
    expect(() => NativeProjectCreationCapability.fromJournalJson(oversized),
        throwsFormatException);
    expect(await parent.list().toList(), isEmpty);
  },
      timeout: const Timeout(Duration(minutes: 2)),
      skip:
          Platform.environment['AVELUNE_NATIVE_CREATION_LARGE_BUDGET'] != '1');

  test(
      'prepared native creation publishes exact inventory with a canonical receipt',
      () async {
    final service = NativeProjectCreationService();
    final prepared = await service.prepare(input());
    final transferred = await Isolate.run(() => prepared);
    final plan = await service.plan(
        prepared: transferred, parentPath: parent.path, folderName: 'native');
    final receipt = await service.publish(plan);
    expect(receipt.inventoryFingerprint, prepared.inventoryFingerprint);
    expect(receipt.transactionReceipt.status, AuthoringReceiptStatus.applied);
    expect(
        receipt.transactionReceipt.actionId, 'project.create_prepared_native');
    expect(File('${receipt.projectPath}/project.json').existsSync(), isTrue);
    expect(receipt.transactionReceipt.extensions['inventoryFingerprint'],
        prepared.inventoryFingerprint);
  });

  test('prepared creation rejects an existing destination', () async {
    final service = NativeProjectCreationService();
    final prepared = await service.prepare(input());
    await Directory('${parent.path}/native').create();
    await expectLater(
        service.plan(
            prepared: prepared, parentPath: parent.path, folderName: 'native'),
        throwsA(isA<ProjectCreationException>()));
  });
  test('the same prepared plan replays the durable receipt without rewriting',
      () async {
    final service = NativeProjectCreationService();
    final prepared = await service.prepare(input());
    final plan = await service.plan(
        prepared: prepared, parentPath: parent.path, folderName: 'replay');
    final first = await service.publish(plan);
    final second = await service.publish(plan);
    expect(
        second.transactionReceipt.toJson(), first.transactionReceipt.toJson());
    await File('${first.projectPath}/project.json').writeAsString('{}');
    await expectLater(
        service.publish(plan), throwsA(isA<ProjectCreationException>()));
  });

  test('prepared plans expire without creating a destination', () async {
    var now = DateTime.utc(2026, 10, 20);
    final service = NativeProjectCreationService(clock: () => now);
    final plan = await service.plan(
        prepared: await service.prepare(input()),
        parentPath: parent.path,
        folderName: 'expired');
    now = now.add(const Duration(minutes: 11));
    await expectLater(
        service.publish(plan),
        throwsA(isA<ProjectCreationException>()
            .having((error) => error.code, 'code', 'project.plan_expired')));
    expect(Directory(plan.projectPath).existsSync(), isFalse);
  });

  test('a mid-promotion interruption compensates every owned file', () async {
    final service = NativeProjectCreationService(faultInjector: (point) {
      if (point.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          point.promotionIndex == 0) {
        throw const AuthoringTransactionSimulatedCrash();
      }
    });
    final plan = await service.plan(
        prepared: await service.prepare(input()),
        parentPath: parent.path,
        folderName: 'rollback');
    await expectLater(
        service.publish(plan), throwsA(isA<ProjectCreationException>()));
    expect(File('${plan.projectPath}/project.json').existsSync(), isFalse);
    expect(File('${plan.projectPath}/assets/.pokemap-assets.json').existsSync(),
        isFalse);
  });

  test('cancellation after promotion compensates the creation before commit',
      () async {
    var cancelled = false;
    final service =
        NativeProjectCreationService(checkpoint: (point, path) async {
      if (point == ProjectCreationCheckpoint.afterApply) cancelled = true;
    });
    final plan = await service.plan(
        prepared: await service.prepare(input()),
        parentPath: parent.path,
        folderName: 'cancelled');
    await expectLater(service.publish(plan, isCancelled: () => cancelled),
        throwsA(isA<ProjectCreationException>()));
    expect(File('${plan.projectPath}/project.json').existsSync(), isFalse);
  });

  test(
      'an injected foreign file refuses delivery and is preserved during compensation',
      () async {
    final service =
        NativeProjectCreationService(checkpoint: (point, path) async {
      if (point == ProjectCreationCheckpoint.afterApply) {
        await File('$path/foreign').writeAsString('keep');
      }
    });
    final plan = await service.plan(
        prepared: await service.prepare(input()),
        parentPath: parent.path,
        folderName: 'foreign');
    await expectLater(
        service.publish(plan), throwsA(isA<ProjectCreationException>()));
    expect(File('${plan.projectPath}/project.json').existsSync(), isFalse);
    expect(await File('${plan.projectPath}/foreign').readAsString(), 'keep');
  });
  test('more than 500 closed resources use phase-only creation checkpoints',
      () async {
    final bytes = Uint8List.fromList(utf8.encode('{}'));
    final reference =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'application/json');
    String? checkpointProfile;
    late NativeProjectCreationPlan plan;
    final service = NativeProjectCreationService(faultInjector: (point) async {
      if (point.checkpoint ==
          AuthoringTransactionCheckpoint.afterJournalPrepared) {
        final json = jsonDecode(await File(
                '${plan.projectPath}/.pokemap/authoring/transactions/${point.operationId}/journal.json')
            .readAsString()) as Map;
        checkpointProfile = json['checkpointProfile'] as String;
        expect(json['bulkCapability'], isNull);
        expect(json['nativeCreationCapability'], isNotNull);
      }
    });
    final prepared = await service.prepare(NativeProjectCreationInput(
        manifest: input().manifest,
        maps: const [],
        assetCatalog: AssetCatalog(records: [
          for (var i = 0; i < 501; i++)
            AssetRecord(
                id: 'resource_$i',
                logicalPath: 'assets/data/$i.json',
                artifact: reference)
        ]),
        artifacts: [
          NativeProjectCreationArtifact(reference: reference, bytes: bytes)
        ]));
    plan = await service.plan(
        prepared: prepared, parentPath: parent.path, folderName: 'large');
    final receipt = await service.publish(plan);
    expect(prepared.resourceCount, 504);
    expect(receipt.transactionReceipt.affectedResources.length, 504);
    expect(checkpointProfile, 'phaseOnly');
  });

  test('mutable inputs cannot change a prepared native creation', () async {
    final bytes = Uint8List.fromList(utf8.encode('{}'));
    final reference =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'application/json');
    final entries = <ProjectMapEntry>[];
    final source = NativeProjectCreationInput(
        manifest: input().manifest.copyWith(maps: entries),
        maps: const [],
        assetCatalog: AssetCatalog(records: [
          AssetRecord(
              id: 'data', logicalPath: 'assets/data.json', artifact: reference)
        ]),
        artifacts: [
          NativeProjectCreationArtifact(reference: reference, bytes: bytes)
        ]);
    final service = NativeProjectCreationService();
    final prepared = await service.prepare(source);
    bytes[0] = 0;
    entries.add(const ProjectMapEntry(
        id: 'changed', name: 'Changed', relativePath: 'maps/changed.json'));
    expect(prepared.manifest.maps, isEmpty);
    final plan = await service.plan(
        prepared: prepared, parentPath: parent.path, folderName: 'immutable');
    final receipt = await service.publish(plan);
    expect(await File('${receipt.projectPath}/assets/data.json').readAsString(),
        '{}');
    expect(receipt.manifest.maps, isEmpty);
  });

  test('unknown administrative logical paths cannot enter the closed inventory',
      () async {
    final bytes = utf8.encode('{}');
    final reference =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'application/json');
    for (final path in [
      '.git/hooks/post-checkout',
      'assets/.git/config',
      'audio/.DS_Store'
    ]) {
      await expectLater(
          const NativeProjectCreationService().prepare(
              NativeProjectCreationInput(
                  manifest: input().manifest,
                  maps: const [],
                  assetCatalog: AssetCatalog(records: [
                    AssetRecord(
                        id: 'data', logicalPath: path, artifact: reference)
                  ]),
                  artifacts: [
                    NativeProjectCreationArtifact(
                        reference: reference, bytes: bytes)
                  ])),
          throwsFormatException);
    }
  });

  test('a symlink replacing the confirmed parent is refused', () async {
    final chosen = await Directory('${parent.path}/chosen').create();
    final other = await Directory('${parent.path}/other').create();
    final service = NativeProjectCreationService();
    final plan = await service.plan(
        prepared: await service.prepare(input()),
        parentPath: chosen.path,
        folderName: 'native');
    await chosen.delete();
    await Link(chosen.path).create(other.path);
    await expectLater(
        service.publish(plan), throwsA(isA<ProjectCreationException>()));
    expect(await other.list().toList(), isEmpty);
  });

  test('duplicate aliases of an artifact identity are refused', () async {
    final bytes = utf8.encode('{}');
    final reference =
        ContentArtifactRef.fromBytes(bytes, mediaType: 'application/json');
    final artifact =
        NativeProjectCreationArtifact(reference: reference, bytes: bytes);
    await expectLater(
        const NativeProjectCreationService().prepare(NativeProjectCreationInput(
            manifest: input().manifest,
            maps: const [],
            assetCatalog: AssetCatalog(records: [
              AssetRecord(
                  id: 'data',
                  logicalPath: 'assets/data.json',
                  artifact: reference)
            ]),
            artifacts: [artifact, artifact])),
        throwsFormatException);
  });
  test(
      'a reserved destination replaced by a symlink never writes into its target',
      () async {
    final other = await Directory('${parent.path}/external').create();
    final service =
        NativeProjectCreationService(checkpoint: (point, path) async {
      if (point == ProjectCreationCheckpoint.afterReservation) {
        await Directory(path).delete();
        await Link(path).create(other.path);
      }
    });
    final plan = await service.plan(
        prepared: await service.prepare(input()),
        parentPath: parent.path,
        folderName: 'reserved');
    await expectLater(
        service.publish(plan), throwsA(isA<ProjectCreationException>()));
    expect(await other.list().toList(), isEmpty);
  });
  test(
      'border frames must reproduce the canonical snapshot content fingerprint',
      () async {
    List<int> png(int red) => image.encodePng(
        image.Image(width: 2, height: 2)..setPixelRgba(0, 0, red, 0, 0, 255));
    final compiled = const CanonicalBorderSnapshotCompiler()
        .prepare(sourceElementId: 'test', frames: [
      CanonicalBorderSourceFrame(
          sourceProjectRelativePath: 'assets/original.png',
          encodedImageBytes: png(255))
    ]);
    NativeProjectCreationInput source(List<int> bytes) =>
        NativeProjectCreationInput(
            manifest: input().manifest.copyWith(
                borderCatalog:
                    ProjectBorderCatalog(visualSnapshots: [compiled.snapshot])),
            maps: const [],
            assetCatalog: AssetCatalog(),
            borderFrames: [
              NativeProjectCreationBorderFrame(
                  snapshotId: compiled.snapshot.id,
                  frameIndex: 0,
                  artifact: NativeProjectCreationArtifact(
                      reference: ContentArtifactRef.fromBytes(bytes,
                          mediaType: 'image/png'),
                      bytes: bytes))
            ]);
    final service = NativeProjectCreationService();
    final prepared = await service.prepare(source(compiled.files.single.bytes));
    expect(prepared.resourceCount, 3);
    await expectLater(service.prepare(source(png(128))), throwsFormatException);
  });
  test(
      'mutating exposed nested metadata cannot alter preparation or its receipt',
      () async {
    final base = input();
    final service = NativeProjectCreationService();
    final prepared = await service.prepare(NativeProjectCreationInput(
        manifest: base.manifest.copyWith(globalProperties: {
          'nested': {'name': 'sealed'}
        }),
        maps: base.maps,
        assetCatalog: base.assetCatalog));
    final exposed = prepared.manifest;
    (exposed.globalProperties['nested'] as Map)['name'] = 'tampered';
    expect((prepared.manifest.globalProperties['nested'] as Map)['name'],
        'sealed');
    final plan = await service.plan(
        prepared: prepared, parentPath: parent.path, folderName: 'metadata');
    final receipt = await service.publish(plan);
    expect(
        (receipt.manifest.globalProperties['nested'] as Map)['name'], 'sealed');
    final persisted = jsonDecode(
            await File('${receipt.projectPath}/project.json').readAsString())
        as Map;
    expect(
        (persisted['globalProperties'] as Map)['nested'], {'name': 'sealed'});
  });
}
